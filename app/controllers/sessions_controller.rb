class SessionsController < Devise::SessionsController
  respond_to :json

  def create
    self.resource = user = warden.authenticate!(auth_options)
    token = nil
    error = nil
    begin
      token = user.create_api_token
      session['api_token'] = token['token']
      render json: token
    rescue XN::Error::ApiError => e
      session['api_token'] = nil
      error = {
        status: (e.status || 400),
        message: "Unable to generate token: #{ e.message }"
      }
    end
    sign_in resource_name, user
    respond_to do |format|
      format.json do
        # Perform additional authentication based on status.
        if token
          render json: token
        elsif error
          render json: { error: error.message }, status: error.status
        else
          respond_with({}, status: :unauthorized)
        end
      end
      format.html do
        set_flash_message(:notice, :signed_in) if is_flashing_format?
        yield resource if block_given?
        respond_with resource, location: after_sign_in_path_for(resource)
      end
    end
  end
end
