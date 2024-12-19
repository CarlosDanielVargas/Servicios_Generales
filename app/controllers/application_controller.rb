class ApplicationController < ActionController::Base
  def return_to_root(message = nil, error = false)
    if error
      flash[:alert] = message if message
    else
      flash[:notice] = message if message
    end
    redirect_to root_path
  end
end
