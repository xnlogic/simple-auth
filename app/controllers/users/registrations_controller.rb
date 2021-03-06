class Users::RegistrationsController < Devise::RegistrationsController
  include Concerns::SignIn
  before_action :set_user_locals, only: [:edit, :update]
  layout 'signup', only: [:new, :create]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        UserMailer.sign_up_confirmation(resource, request.base_url).deliver_now!
        UserMailer.sign_up_notification(resource, request.base_url).deliver_now!
        respond_with resource, location: welcome_users_path
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: welcome_users_path
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end


  # GET /resource/edit
   def edit
     super
   end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  protected

  # Override to allow users who have admin group
  def require_no_authentication
    user = current_user
  end

  def sign_up_params
    params.require(:user).permit(:name, :client, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:name, :client, :email, :password, :password_confirmation, :current_password)
  end

  # The path used after sign up.
  def after_sign_up_path_for(resource)
    welcome_users_path
  end

  # The path used after sign up for inactive accounts.
  def after_inactive_sign_up_path_for(resource)
    welcome_users_path
  end

  def after_update_path_for(resource)
    users_path
  end

  private

  def set_user_locals
    @users = User.same_client_as(current_user).order(:name).all
    @users_to_groups = with_current_user_api do |api|
      Group.users_to_groups_map(api)
    end
    @users_to_groups ||= Group.empty_user_group_hash
  end
end
