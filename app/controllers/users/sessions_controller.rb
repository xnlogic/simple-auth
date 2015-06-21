class Users::SessionsController < Devise::SessionsController
  prepend_before_filter :really_require_no_authentication, only: [:new]

  include Concerns::SignIn

  respond_to :json

  # GET /resource/sign_in
  # def new
  #   super
  # end

  def create
    self.resource = user = warden.authenticate!(auth_options)
    respond_with_token do |format|
      set_flash_message(:notice, :signed_in) if is_flashing_format?
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  private

  unless instance_method(:really_require_no_authentication)
    alias really_require_no_authentication require_no_authentication
  end

  def require_no_authentication
    # NO OP
  end
end
