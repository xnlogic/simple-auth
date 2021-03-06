class Users::SessionsController < Devise::SessionsController
  include Concerns::SignIn
  layout 'signup', only: [:new, :create]

  respond_to :json

  # GET /resource/sign_in
  # def new
  #   super
  # end
  #

  def create
    warden.logout if current_user
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
            render json: { error: token_error[:message] }, status: token_error[:status]
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
          flash[:error] = "Invalid login or password"
          param = params['user'] || {}
          self.resource = User.new user_name: param['user_name']
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
    users_path
  end
end
