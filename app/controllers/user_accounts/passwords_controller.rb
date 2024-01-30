# frozen_string_literal: true

class UserAccounts::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  def new
    begin
      super
    rescue StandardError => e
      if current_user_account
        ErrorLog.create(code: e.class.name, description: e.message, username: current_user_account.email)
      else
        ErrorLog.create(code: e.class.name, description: e.message)
      end
      return_to_root('Hubo un error inesperado. Contacte al administrador del sistema.', true)
    end
  end

  # POST /resource/password
  def create
    begin
      super
    rescue StandardError => e
      if current_user_account
        ErrorLog.create(code: e.class.name, description: e.message, username: current_user_account.email)
      else
        ErrorLog.create(code: e.class.name, description: e.message)
      end
      return_to_root('Hubo un error inesperado. Contacte al administrador del sistema.', true)
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    begin
      super
    rescue StandardError => e
      if current_user_account
        ErrorLog.create(code: e.class.name, description: e.message, username: current_user_account.email)
      else
        ErrorLog.create(code: e.class.name, description: e.message)
      end
      return_to_root('Hubo un error inesperado. Contacte al administrador del sistema.', true)
    end
  end

  # PUT /resource/password
  def update
    begin
      super
    rescue StandardError => e
      if current_user_account
        ErrorLog.create(code: e.class.name, description: e.message, username: current_user_account.email)
      else
        ErrorLog.create(code: e.class.name, description: e.message)
      end
      return_to_root('Hubo un error inesperado. Contacte al administrador del sistema.', true)
    end
  end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
