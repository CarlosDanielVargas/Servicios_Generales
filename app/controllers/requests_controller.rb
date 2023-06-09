# frozen_string_literal: true

class RequestsController < ApplicationController
  before_action :set_request, only: %i[show edit update change_status]
  before_action :set_campuses_list, only: %i[new create]
  before_action :set_dictionary, only: %i[new show edit update index create search]
  before_action :set_status, only: %i[show]

  # GET /requests or /requests.json
  def index
    if current_user_account
      @requests = Request.where(campus: current_user_account.campus)
      @queries = @requests.ransack(params[:q])
      @requests = @queries.result
      @status = params[:status] if params[:status]
      @commit = params[:commit] # Para diferenciar la vista de la lista de solicitudes de reportes.
      return if params[:q].present?

      set_status
      set_requests
    else
      return_to_root('No se poseen permisos para acceder a esta página')
    end
  end

  def search
    index
    render :reports
  end

  # GET /requests/1 or /requests/1.json
  def show
    if @request.nil?
      return_to_root('No se encontró la solicitud')
      return
    end
    @reasons = RequestDenyReason.where(request_id: @request.id) if @request.status == 'denied'
    @feedback = Feedback.find_by(request_id: @request.id)
  end

  # GET /requests/new
  def new
    @request = Request.new
  end

  # GET /requests/1/edit
  def edit; end

  # POST /requests or /requests.json
  def create
    request_location = RequestLocation.new
    @request = Request.new(request_params)
    campus = params[:request][:campus_id]
    @request.status = 'pending'
    @request.campus = Campus.find(campus)
    date = Time.now.strftime('%d%m%Y')
    @request.identifier = "#{@request.campus.campus_id}-#{date}-#{rand.to_s[2..6]}"
    unless params[:request][:work_location_id] == '0'
      work_location = params[:request][:work_location].to_i
      request_location.work_building = WorkBuilding.find(params[:request][:work_building])
      if work_location.zero?
        request_location.name = params[:request][:work_location]
      else
        work_location = WorkLocation.find(work_location)
        request_location.work_location = work_location
        request_location.name = work_location.name
      end
    end
    respond_to do |format|
      if @request.save
        request_location.request = @request
        request_location.save
        RequestMailer.new_request(@request).deliver_later
        admins = UserAccount.where(role: 'admin')
        admins.each do |admin|
          UserMailer.new_request_admin(@request, admin).deliver_later
        end
        format.html { redirect_to request_url(@request), notice: 'La solicitud fue creada correctamente.' }
        format.json { render :show, status: :created, location: @request }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /requests/1 or /requests/1.json
  # @return [Object]
  def update
    respond_to do |format|
      reasons, type = get_reasons
      if reasons.empty? || type.nil?
        format.html { render :edit }
        format.json { render json: @request.errors }
      else
        reasons = create_reasons(reasons, type)
        workers = @request.employees_currently_working
        workers.each do |worker|
          task = Task.where(request: @request, user_account: worker).first
          if task && type != 'deny'
            task.update(status: 'pending')
            task.save
          end
          UserMailer.request_reopened(@request, worker, reasons).deliver_later if type != 'deny'
        end
        format.html { redirect_to (current_user_account.worker? ? requests_url(:status => "in_process") : requests_url(:status => "pending")), notice: 'Se actualizó el estado de la solicitud' }
        format.json { head :no_content }
      end
    end
  end

  # In charge of updating the status of a request depending on the status obtained from the params
  # @param [Object] request
  # @param [nil] task
  def change_status
    if @task.nil?
      user_account_id = current_user_account.id
      @task = Task.where(request: @request, user_account_id:).first
    end
    status = @request.status
    case status
    when 'in_process'
      set_task
      @task&.update(status: 'completed', finished_at: Time.now)
      if analyse_tasks
        @request.update(status: 'completed')
        @log_entry = LogEntry.create(user_account: current_user_account, request: @request,
                                     entry_message: 'Cambió el estado de la solicitud a completada')
      end
      reload_index
    when 'completed'
      if params[:change_to] == 'close'
        @request.update(status: 'closed')
        @log_entry = LogEntry.create(user_account: current_user_account, request: @request,
                                     entry_message: 'Cambió el estado de la solicitud a cerrada')
        RequestMailer.request_completed(@request).deliver_now
      else
        reset_tasks
        @request.update(status: 'in_process')
        @log_entry = LogEntry.create(user_account: current_user_account, request: @request,
                                     entry_message: 'Cambió el estado de la solicitud a en proceso')
      end
      reload_index
    else
      redirect_to new_task_path(request: @request)
    end
  end

  # Falta documentación
  def ask_state; end

  # Falta documentación
  def search_state
    # byebug
    if params[:session][:identifier] && params[:session][:requester_mail]
      identifier = params[:session][:identifier]
      requester_mail = params[:session][:requester_mail]
      @request = Request.where(identifier:, requester_mail:).first
    end
    if !@request.nil?
      session[:request_id] = @request.id
      redirect_to request_url(@request)
    else
      render 'ask_state', notice: 'No se encontró la solicitud'
    end
  end

  def work_buildings
    work_buildings = WorkBuilding.all.order(name: :asc)
    render json: work_buildings.to_json(include: :work_locations)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_request
    @request = Request.find_by_hashid(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def request_params
    params.require(:request).permit(:identifier, :requester_name, :requester_extension, :requester_phone, :requester_id,
                                    :requester_mail, :requester_type, :student_id, :student_association, :campus_id,
                                    :work_building, :work_location, :work_type, :work_description, :status,
                                    :task_id, :change_to,
                                    request_deny_reasons: %i[_destroy reason request_id user_id],
                                    reopen_reasons: %i[_destroy reason request_id user_id])
  end

  private

  # Initializes the dictionary with the default values
  def set_dictionary
    @dictionary = Dictionary.new
  end

  # Initializes the list of campuses
  def set_campuses_list
    @campuses_list = Campus.all
  end

  # Initializes the status of a request
  def set_status
    @status = params[:status]
  end

  # Set the requests depending the user role and the status of the request
  # @return [Object]
  def set_requests
    # Case for the employee
    if current_user_account.role == 'worker'
      employee = current_user_account
      employee_requests = employee.active_requests
      @requests = case @status
                  when 'completed'
                    find_requests(employee_requests, 'completed')
                  when 'closed'
                    find_requests(employee_requests, 'closed')
                  else
                    find_requests(employee_requests, 'in_process')
                  end

      # Case for the admin
    else
      requests = Request.where(campus: current_user_account.campus)
      @requests = case @status
                  when 'in_process'
                    find_requests(requests, 'in_process')
                  when 'completed'
                    find_requests(requests, 'completed')
                  when 'closed'
                    find_requests(requests, 'closed')
                  when 'denied'
                    find_requests(requests, 'denied')
                  else
                    find_requests(requests, 'pending')
                  end
    end
  end

  # Take the requests from given set: <b>set</b> depending the status: <b>status</b> of the request
  def find_requests(set, status)
    if current_user_account.role == 'worker'
      case status
      when 'in_process'
        current_user_account.requests_by_tasks_status('pending')
      when 'completed'
        current_user_account.requests_by_tasks_status('completed', 'closed')
      else
        set.where(status:)
      end
    else
      set.where(status:)
    end
  end

  # Takes the tasks from table <b>Task</b>
  def set_task
    @task = if params[:task_id]
              Task.find(params[:task_id])
            else
              Task.where(request: @request, user_account: current_user_account).first
            end
  end

  # Sets the completed? attribute of the tasks of the request to false
  def reset_tasks
    tasks = @request.tasks
    tasks.each do |task|
      task.update(status: 'pending')
    end
  end

  # Return the deny reasons of a request
  def get_reasons
    reasons = []
    type = ''
    if params[:request] && params[:request][:request_deny_reasons_attributes]
      reasons = params[:request][:request_deny_reasons_attributes].values
      type = 'deny'
    elsif params[:request] && params[:request][:reopen_reasons_attributes]
      reasons = params[:request][:reopen_reasons_attributes].values
      type = 'reopen'
    end
    [reasons, type]
  end

  # Creates the deny reasons or reopen reasons of a request
  # @param [Object] reasons
  # @param [Object] type
  # @return [Array]
  def create_reasons(reasons, type)
    valid_reasons = []
    reasons.each do |reason|
      if reason[:_destroy] == "false"
        if type == 'deny'
          RequestDenyReason.create(reason: reason[:reason], request: @request,
                                   user_account: current_user_account)
        else
          ReopenReason.create(reason: reason[:reason], request: @request,
                              user_account: current_user_account)
          valid_reasons << reason[:reason]
          LogEntry.create(user_account: current_user_account, request: @request,
                          entry_message: "Reabrió la solicitud, razón: #{reason[:reason]}")
        end
      end
    end
    if type == 'deny'
      @request.update(status: 'denied')
      @log_entry = LogEntry.create(user_account: current_user_account, request: @request,
                                   entry_message: 'Denegó la solicitud')
      RequestMailer.request_denied(@request).deliver_later
    else
      @request.update(status: 'in_process')
    end
    valid_reasons
  end

  # Depending the value of the completed? attribute of the tasks of the current request,
  # will return true if all the tasks are completed, or false if at least one task is not completed
  def analyse_tasks
    tasks = @request.tasks
    tasks.each do |task|
      return false if task.status == 'pending'
    end
    true
  end

  # Reload the requests listing view, and informs the user that the request was successfully updated
  def reload_index
    redirect_to (current_user_account.worker? ? requests_path(:status => "in_process") : requests_path(:status => "pending")), notice: 'Se actualizó el estado de la solicitud'
  end

  def reports
    search
  end
end
