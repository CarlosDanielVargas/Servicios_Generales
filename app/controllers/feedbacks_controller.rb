# frozen_string_literal: true

# FeedbacksController is responsible for managing feedbacks in the application.
# It provides actions to create, read, update, and delete feedbacks.
class FeedbacksController < ApplicationController
  # Before actions are used to find a specific feedback or request before performing certain actions.
  before_action :set_feedback, only: %i[show edit update destroy]
  before_action :set_request, only: %i[new show create edit update destroy]

  # GET /feedbacks or /feedbacks.json
  # The index action is used to retrieve all feedbacks.
  # If the current user is an admin, it retrieves all feedbacks.
  # If the current user is not an admin, it only retrieves feedbacks related to the current user's requests.
  def index
    begin
      @feedbacks = Feedback.all if current_user_account.admin?
      @feedbacks = Feedback.where(request_id: current_user_account.requests.ids) unless current_user_account.admin?
    rescue StandardError => e
      if current_user_account
        ErrorLog.create(code: e.class.name, description: e.message, username: current_user_account.email)
      else
        ErrorLog.create(code: e.class.name, description: e.message, username: '')
      end
      return_to_root('Hubo un error inesperado. Contacte al administrador del sistema.')
    end
  end

  # GET /feedbacks/1 or /feedbacks/1.json
  # The show action is used to retrieve and display a specific feedback.
  def show; end

  # GET /feedbacks/new
  # The new action is used to instantiate a new feedback.
  def new
    @feedback = Feedback.new
  end

  # GET /feedbacks/1/edit
  # The edit action is used to find and display the edit form for a specific feedback.
  def edit; end

  # POST /feedbacks or /feedbacks.json
  # The create action is used to create a new feedback.
  # If the feedback is saved successfully, it sends an email, redirects to the root path, and displays a success message.
  # If the feedback is not saved successfully, it renders the new feedback form and displays an error message.
  def create
    begin
      @feedback = Feedback.new(observations: feedback_params.values[0], satisfaction: params[:satisfaction],
                               request_id: feedback_params.values[1])
      @request = @feedback.request
      respond_to do |format|
        if @feedback.save
          RequestMailer.feedback_sent(@request).deliver_later
          format.html { redirect_to root_path, notice: 'Feedback enviado.' }
          format.json { render :show, status: :created, location: @feedback }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @feedback.errors, status: :unprocessable_entity }
        end
      end
    rescue StandardError => e
      if current_user_account
        ErrorLog.create(code: e.class.name, description: e.message, username: current_user_account.email)
      else
        ErrorLog.create(code: e.class.name, description: e.message, username:)
      end
      return_to_root('Hubo un error inesperado. Contacte al administrador del sistema.')
    end
  end

  # PATCH/PUT /feedbacks/1 or /feedbacks/1.json
  # The update action is used to update a specific feedback.
  # If the feedback is updated successfully, it redirects to the feedback and displays a success message.
  # If the feedback is not updated successfully, it renders the edit feedback form and displays an error message.
  def update
    begin
      newfeedback = ActionController::Parameters.new(observations: feedback_params.values[0], satisfaction: params[:satisfaction]).permit(
        :observations, :satisfaction
      )
      respond_to do |format|
        if @feedback.update(newfeedback)
          format.html { redirect_to feedback_url(@feedback), notice: 'Feedback actualizado.' }
          format.json { render :show, status: :ok, location: @feedback }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @feedback.errors, status: :unprocessable_entity }
        end
      end
    rescue StandardError => e
      if current_user_account
        ErrorLog.create(code: e.class.name, description: e.message, username: current_user_account.email)
      else
        ErrorLog.create(code: e.class.name, description: e.message, username:)
      end
      return_to_root('Hubo un error inesperado. Contacte al administrador del sistema.')
    end
  end

  # DELETE /feedbacks/1 or /feedbacks/1.json
  # The destroy action is used to delete a specific feedback.
  # After the feedback is deleted, it redirects to the feedbacks URL and displays a success message.
  def destroy
    begin
      @feedback.destroy
      respond_to do |format|
        format.html { redirect_to feedbacks_url, notice: 'Feedback eliminado.' }
        format.json { head :no_content }
      end
    rescue StandardError => e
      if current_user_account
        ErrorLog.create(code: e.class.name, description: e.message, username: current_user_account.email)
      else
        ErrorLog.create(code: e.class.name, description: e.message, username:)
      end
      return_to_root('Hubo un error inesperado. Contacte al administrador del sistema.')
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # The set_feedback method is used to find a specific feedback before performing certain actions.
  def set_feedback
    @feedback = params[:request_id] ? Feedback.where(request_id: params[:request_id]) : Feedback.find(params[:id])
  end

  # The set_request method is used to find a specific request before performing certain actions.
  def set_request
    @request ||= Request.find(params[:request_id]) if params[:request_id]
  end

  # The feedback_params method is used to whitelist the permitted parameters.
  def feedback_params
    params.require(:feedback).permit(:observations, :satisfaction, :request_id)
  end
end
