# frozen_string_literal: true

# RequestsController is responsible for managing requests in the application.
# It provides actions to create, read, update, and delete requests.
class RequestsController < ApplicationController
  # Before actions are used to set up necessary data before performing certain actions.
  before_action :set_request, only: %i[show edit update change_status]
  before_action :set_campuses_list, only: %i[new create]
  before_action :set_dictionary, only: %i[new show edit update index create search]
  before_action :set_status, only: %i[show]

  # GET /requests or /requests.json
  # The index action retrieves all requests associated with the current user's campus.
  # It also handles search functionality.
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

  # The search action is used to render search results.
  def search
    index
    render :reports
  end

  # GET /requests/1 or /requests/1.json
  # The show action retrieves and displays a specific request.
  def show
    if @request.nil?
      return_to_root('No se encontró la solicitud')
      return
    end
    @reasons = RequestDenyReason.where(request_id: @request.id) if @request.status == 'denied'
    @feedback = Feedback.find_by(request_id: @request.id)
  end

  # GET /requests/new
  # The new action is used to instantiate a new request.
  def new
    @request = Request.new
  end

  # GET /requests/1/edit
  # The edit action is used to find and display the edit form for a specific request.
  def edit; end

  # POST /requests or /requests.json
  # The create action is used to create a new request.
  # If the request is saved successfully, it sends an email, redirects to the request URL, and displays a success message.
  # If the request is not saved successfully, it renders the new request form and displays an error message.
  def create
    request_location = RequestLocation.new
    last_request_id = Request.last.id
    @request = Request.new(request_params)
    campus = params[:request][:campus_id]
    @request.status = 'pending'
    @request.campus = Campus.find(campus)
    date = Time.now.strftime('%Y')
    @request.identifier = "SG-#{last_request_id + 1}-#{date}"
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
  # The update action is used to update a specific request.
  # If the request is updated successfully, it redirects to the requests URL and displays a success message.
  # If the request is not updated successfully, it renders the edit request form and displays an error message.
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

  # The change_status action is used to update the status of a specific request.
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

  # The ask_state action is used to ask for the state of a request.
  def ask_state; end

  # The search_state action is used to search for the state of a request.
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

  # The work_buildings action is used to fetch all work buildings and their associated work locations.
  def work_buildings
    work_buildings = WorkBuilding.all.order(name: :asc)
    render json: work_buildings.to_json(include: :work_locations)
  end

  # The set_request method is used to find a specific request before performing certain actions.
  def set_request
    @request = Request.find_by_hashid(params[:id])
  end

  # The request_params method is used to whitelist the permitted parameters.
  def request_params
    params.require(:request).permit(:identifier, :requester_name, :requester_extension, :requester_phone, :requester_id,
                                    :requester_mail, :requester_type, :student_id, :student_association, :campus_id,
                                    :work_building, :work_location, :work_type, :work_description, :status,
                                    :task_id, :change_to,
                                    request_deny_reasons: %i[_destroy reason request_id user_id],
                                    reopen_reasons: %i[_destroy reason request_id user_id])
  end

  private

  # The set_dictionary method is used to initialize the dictionary with default values.
  def set_dictionary
    @dictionary = Dictionary.new
  end

  # This method initializes the list of all campuses by querying the Campus model.
  # The result of this query is stored in the instance variable @campuses_list
  # which can be used in the views.
  def set_campuses_list
    @campuses_list = Campus.all
  end

  # This method initializes the status of a request by retrieving it from the request parameters.
  # The status is stored in the @status instance variable.
  def set_status
    @status = params[:status]
  end

  # This method sets the requests depending on the user role and the status of the request.
  # If the current user is a worker, it fetches the active requests of the employee and filters
  # them based on the status. If the current user is an admin, it fetches all requests associated
  # with the admin's campus and filters them based on the status.
  # The result is stored in the @requests instance variable.
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

    @requests = case @status
                when current_user_account.worker? ? 'in_process' : 'pending' 
                  @requests
                else
                  @requests.sort_by(&:created_at).reverse
                end
  end

  # This method fetches requests from a given set based on the status.
  # If the current user is a worker, it fetches requests based on the tasks status.
  # Otherwise, it fetches requests directly based on the status.
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

  # This method fetches a task either by task_id from the request parameters or
  # by finding the first task associated with the current user and request.
  # The result is stored in the @task instance variable.
  def set_task
    @task = if params[:task_id]
              Task.find(params[:task_id])
            else
              Task.where(request: @request, user_account: current_user_account).first
            end
  end

  # This method resets the status of all tasks associated with a request to 'pending'.
  def reset_tasks
    tasks = @request.tasks
    tasks.each do |task|
      task.update(status: 'pending')
    end
  end

  # This method fetches the reasons for denying or reopening a request from the request parameters.
  # It returns an array where the first element is the reasons and the second element is the type.
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

  # This method creates the deny reasons or reopen reasons of a request.
  # It iterates over the reasons, validates them, and creates the appropriate record in the database.
  # If the type is 'deny', it also updates the status of the request to 'denied', creates a log entry, and sends an email notification.
  # If the type is 'reopen', it updates the status of the request to 'in_process'.
  # The method returns an array of valid reasons.
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

  # This method analyzes the tasks of the current request.
  # It iterates over the tasks and returns false if it finds a task with the status 'pending'.
  # If no such task is found, it returns true, indicating that all tasks are completed.
  def analyse_tasks
    tasks = @request.tasks
    tasks.each do |task|
      return false if task.status == 'pending'
    end
    true
  end

  # This method reloads the requests listing view and displays a success message indicating that the request was successfully updated.
  # The redirect path depends on whether the current user is a worker or not.
  def reload_index
    redirect_to (current_user_account.worker? ? requests_path(:status => "in_process") : requests_path(:status => "pending")), notice: 'Se actualizó el estado de la solicitud'
  end

  # This method is an alias for the `search` method and is used for generating reports.
  def reports
    search
  end
end
