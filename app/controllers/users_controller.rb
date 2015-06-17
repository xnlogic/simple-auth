class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin_or_current_user!, except: [:welcome]

  def index
    @users = User.same_client_as(current_user).order(:name).all
    @users_to_groups = with_current_user_api do |api|
      Group.users_to_groups_map(api)
    end
    @users_to_groups ||= Group.empty_user_group_hash
    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def show
    @user = User.same_client_as(current_user).find(params[:id])
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end

  def edit
    @user = User.same_client_as(current_user).find(params[:id])
    with_current_user_api do |api|
      all_available_groups(api)
      set_user_groups(api)
    end
  end

  def update
    @user = User.same_client_as(current_user).find(params[:id])
    params[:user].delete(:password) if params[:user][:password].blank? # Un-entered password remains unchanged
    with_current_user_api do |api|
      respond_to do |format|
        if @user.update_attributes_with_api(api, user_params, group_ids)
          format.html { redirect_to users_path }
          format.json { head :no_content }
        else
          format.html {
            all_available_groups(api)
            set_user_groups(api)
            render action: 'edit'
          }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  private

  def group_ids
    params.require(:user).permit({group_ids: []})[:group_ids] if user_manager?
  end

  def user_params
    if user_manager?
      params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation, :remember_me, :status)
    else
      params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation, :remember_me)
    end
  end

  def authenticate_admin_or_current_user!
    if not action_on_current_user?
      authenticate_user_manager!
    end
  end

  def action_on_current_user?
    params.has_key?(:id) && params[:id] == current_user.id
  end

  def authenticate_user_manager!
    if not user_manager?
      render_unauthorized 'You must have update access on API Permissions.'
    end
  end

  def has_user_management_permissions?
    permissions = current_user_account_info['permissions']
    return has_permissions?(permissions, [:create, :read, :update, :delete], 'user') &&
           has_permissions?(permissions, [:update], 'permission')
  end

  def user_manager?
    can_authorize? && has_user_management_permissions?
  end

  def new_user_groups
    with_current_user_api do |api|
      all_available_groups api
      @user_groups = []
    end
  end

  def all_available_groups(api)
    @groups = Group.all(api).reject { |g| g.name == 'Authenticators' }
  end

  def set_user_groups(api)
    @user_groups = @user.groups(api)
  end
end
