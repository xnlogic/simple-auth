class Users::SessionsController < Devise::SessionsController
  include Concerns::SignIn

  respond_to :json

  # GET /resource/sign_in
  # def new
  #   super
  # end

  def create
    self.resource = user = warden.authenticate!(auth_options)
    sign_in resource_name, user
    respond_with_token do |format|
      format.html do
        set_flash_message(:notice, :signed_in) if is_flashing_format?
        respond_with resource, location: after_sign_in_path_for(resource)
      end
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

end
