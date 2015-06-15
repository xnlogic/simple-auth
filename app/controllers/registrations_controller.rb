class RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_in_path_for(resource)
    welcome_user_path(resource)
  end

  def after_sign_up_path_for(resource)
    welcome_user_path(resource)
  end

  def sign_up_params
    params.require(:user).permit(:name, :client, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.require(:user).permit(:name, :client, :email, :password, :password_confirmation, :current_password)
  end
end
