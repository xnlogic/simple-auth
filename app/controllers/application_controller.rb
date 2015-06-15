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

  def has_permissions?(permissions, types, model_name)
    types.all? do |type|
      permissions["#{ type }_access"].include? model_name
    end
  end

  def render_unauthorized
    respond_to do |format|
      format.html { redirect_to '/login' }
      format.json { render json: {
          response: 'unauthorized',
          url: request.fullpath,
          message: 'The current user is not authorized to make this request'
        }, status: :unauthorized
      }
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
