class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  #
  #protect_from_forgery with: :exception

  rescue_from XN::Error::ApiError, with: :render_api_exception

  protected

  def current_user_account_info
    @account_info ||= with_current_user_api do |api|
      User.get_account_info(api)
    end
  end

  def can_authorize?
    logged_in? and current_user_account_info
  end

  def logged_in?
    not api_token.blank?
  end

  def user_manager?
    can_authorize? && has_user_management_permissions?
  end

  def has_user_management_permissions?
    permissions = current_user_account_info['permissions']
    return has_permissions?(permissions, [:create, :read, :update, :delete], 'user') &&
           has_permissions?(permissions, [:update], 'permission')
  end

  def has_permissions?(permissions, types, model_name)
    if permissions
      types.all? do |type|
        permissions["#{ type }_access"].include? model_name
      end
    end
  end

  def render_unauthorized(reason = nil)
    respond_to do |format|
      format.html do
        if reason
          flash[:error] = "Unauthorized: #{ reason }"
        else
          flash[:error] = "Unauthorized."
        end
        redirect_to new_user_session_path
      end
      format.json do
        render json: {
          response: 'unauthorized',
          url: request.fullpath,
          message: 'The current user is not authorized to make this request'
        }, status: :unauthorized
      end
    end
  end

  def with_current_user_api
    if logged_in?
      yield XN::Api.new api_token
    end
  end

  private

  def api_token
    session['api_token']
  end

  def render_api_exception(exception)
    respond_to do |format|
      format.html { raise exception } # Trigger default exception page
      format.json { render json: exception.message, status: exception.status }
    end
  end

end
