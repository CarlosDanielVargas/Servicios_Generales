# frozen_string_literal: true

class UserAccounts::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
   @user = UserAccount.new
   super
  end

  # POST /resource/sign_in
  def create
    #byebug
    @user = (UserAccount.all).find_by(email: params[:user_account][:email].downcase)
    super
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
