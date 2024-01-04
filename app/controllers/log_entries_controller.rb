# LogEntriesController is responsible for handling the management of log entries in the application.
# It provides an action to list log entries.
class LogEntriesController < ApplicationController
  # GET /log_entries or /log_entries.json
  # The index action retrieves all log entries associated with a specific request.
  # It first finds the request using the request_id parameter from the URL.
  # It then fetches all log entries where the request_id matches the id of the found request.
  # Finally, it sorts the log entries in descending order by their creation date, so the most recent entries appear first.
  def index
    begin
      request = Request.find(params[:request_id])
      @log_entries = LogEntry.all.where(request_id: request.id)
      @log_entries = @log_entries.sort_by(&:created_at).reverse
    rescue StandardError => e
      if current_user_account
        ErrorLog.create(code: e.class.name, description: e.message, username: current_user_account.email)
      else
        ErrorLog.create(code: e.class.name, description: e.message, username:)
      end
      return_to_root('Hubo un error inesperado. Contacte al administrador del sistema.')
    end
  end
end
