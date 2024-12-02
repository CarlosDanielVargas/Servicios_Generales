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
    user = (UserAccount.all).find_by(email: params[:user_account][:email].downcase)
    if user&.valid_password?(params[:user_account][:password])
      sign_in(user)
      flash[:notice] = "Bienvenido #{user.name}"
      redirect_to root_path
    else
      flash[:alert] = "Email o contraseña incorrectos"
      redirect_to new_user_account_session_path
    end
    #super
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
