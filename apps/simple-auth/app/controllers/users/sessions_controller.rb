class Users::SessionsController < Devise::SessionsController
  attr_accessor :token, :token_error

  respond_to :json

  # GET /resource/sign_in
  # def new
  #   super
  # end
  #

  def create
    user, opts = warden.send :_perform_authentication, auth_options
    if user
      self.resource = user
      respond_to do |format|
        format.json do
          create_token(resource)
          # Perform additional authentication based on status.
          if token
            render json: token
          elsif token_error
            render json: { error: token_error.message }, status: token_error.status
          else
            render json: {}, status: :unauthorized
          end
        end
        format.html do
          sign_in resource_name, resource
          set_flash_message(:notice, :signed_in) if is_flashing_format?
          respond_with resource, location: after_sign_in_path_for(resource)
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {}, status: :unauthorized
        end
        format.html do
          flash[:error] = "Invalid email address or password"
          param = params['user'] || {}
          self.resource = User.new email: param['email']
          render :new
        end
      end
    end
  end

  # DELETE /resource/sign_out
  def destroy
    with_current_user_api do |api|
      User.log_out_api(api)
    end
    super
  end

  private

  def require_no_authentication
    # disable this devise before_filter
  end

  def after_sign_in_path_for(user)
    welcome_users_path
  end

  def create_token(user)
    begin
      self.token = user.create_api_token
    rescue XN::Error::ApiError => e
      self.token_error = {
        status: (e.status || 400),
        message: "Unable to generate token: #{ e.message }"
      }
    end
  end

  # Only call this when creating a user management session.
  def sign_in(resource_name, user, *args)
    create_token(user)
    session['api_token'] = token ? token['token'] : nil
    super
  end
end
