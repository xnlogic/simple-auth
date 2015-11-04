class UsersController < ApplicationController
  respond_to :json
  include Concerns::SignIn
  before_action :log_in_if_token_valid, only: [:index, :create]
  before_action :authenticate_user!, except: [:welcome]
  before_action :authenticate_admin_or_current_user!, except: [:welcome]
  before_action :set_user_locals, except: [:welcome]

  def index
    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  def welcome
    render layout: 'signup'
  end

  def new
    @user = User.new({:client => current_user.client})
    with_current_user_api do |api|
      all_available_groups(api)
      load_user_groups(api)
    end
  end

  def new_ldap
    @user = User.new({:client => current_user.client})
    with_current_user_api do |api|
      all_available_groups(api)
      load_user_groups(api)
    end
  end

  def search_ldap
    if params[:search]
      c=Devise::LDAP::Connection.admin

      #TODO - PULL BASE FILTER OPTIONS FROM LDAP.YML
      #base_filter = Net::LDAP::Filter.construct("(&(objectClass=user)(sAMAccountType=805306368)(memberof:1.2.840.113556.1.4.1941:=CN=LM_ALL_USERS_01,OU=LightMesh,OU=Groups,DC=zd,DC=lightmesh,DC=com))")
      search = params[:search].to_s.strip
      if search =~ /\*/
        search_filter = Net::LDAP::Filter.eq("cn", search)
      else
        split = search.split(/[ ,]+/)
        if split.length >= 2
          search_filter = Net::LDAP::Filter.intersect(
            Net::LDAP::Filter.eq("cn", "*#{split.join('*')}*"),
            Net::LDAP::Filter.eq("cn", "*#{split.reverse.join('*')}*"))
        else
          search_filter = Net::LDAP::Filter.eq("cn", "*#{search}*")
        end
      end
      query_filter = search_filter #Net::LDAP::Filter.join(base_filter, search_filter)
      entries = c.
        search(filter: query_filter).
        select { |u|
          u and u.objectClass[1] == "person" and u.respond_to? :userprincipalname
        }.map { |u|
          cn = u.cn.first rescue nil
          name = u.userprincipalname.first rescue nil
          {cn: cn, userprincipalname: name}
        }
      respond_with entries
    end
  end

  def create
    @user = User.new(user_params)

    with_current_user_api do |api|
      if @user.save_with_api(api, group_ids)
        if @user.ldap?
          UserMailer.ldap_account_notification(@user, request.base_url).deliver_now!
        end
        redirect_to users_path
      else
        respond_to do |format|
          format.html {
              all_available_groups(api)
              load_user_groups(api)
            if @user.ldap?
              render :new_ldap
            else
              render :new
            end
          }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def create_user(client, password, tokens )
  end

  def get_db_name(api, company_name)
    unless company_name.blank?
      db_name = company_name.gsub(/[^a-zA-Z]/, "").downcase
      # TODO: always suffix customer names with something short and random to prevent client detection # SECURITY
      existing_dbs = api.get "/is/client/filter/name/properties/name?name[regex]=#{db_name}&limit=10000"
      100.times do |i|
        suffix = i.nonzero? ? i.to_s : ""
        n = db_name + suffix
        if existing_dbs.none? { |id, name| name == n }
          return n
        end
      end
    end
  end

  def disable
    @user = User.same_client_as(current_user).find(params[:id])

    with_current_user_api do |api|
      if @user.update_attributes_with_api(api, @user.attributes, [])
        redirect_to users_path
      end
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
      load_user_groups(api)
    end
  end

  def update
    @user = User.same_client_as(current_user).find(params[:id])
    params[:user].delete(:password) if params[:user][:password].blank? # Un-entered password remains unchanged
    with_current_user_api do |api|
      respond_to do |format|
        if @user.update_attributes_with_api(api, user_params, group_ids)
          if !@user.activated and group_ids and group_ids.length > 0
            UserMailer.activation_notification(@user, request.base_url).deliver_now!
            @user.activated = true
            @user.save
          end
          format.html { redirect_to users_path }
          format.json { head :no_content }
        else
          format.html {
            all_available_groups(api)
            load_user_groups(api)
            render action: 'edit'
          }
          format.json { render json: @user.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    @user = User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end

  private

  def set_user_locals
    @users = User.same_client_as(current_user).order(:name).all
    with_current_user_api do |api|
      User.lookup_user_details(api, @users)
      @users_to_groups = Group.users_to_groups_map(api)
    end
    @users_to_groups ||= Group.empty_user_group_hash
  end

  def group_ids
    params.require(:user).permit({group_ids: []})[:group_ids] if user_manager?
  end

  def user_params
    if user_manager?
      params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation, :remember_me, :status, :read_only, :client, :notify_of_signup, :account_type, :user_name, :service_account)
    else
      params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation, :remember_me, :read_only, :client, :account_type, :user_name)
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

  def new_user_groups
    with_current_user_api do |api|
      all_available_groups api
      @user_groups = []
    end
  end

  def all_available_groups(api)
    @groups = Group.all(api).reject { |g| g.name == 'Authenticators' }
  end

  def load_user_groups(api)
    @user_groups = @user.groups(api)
  end

  def log_in_if_token_valid
    header = request.headers['Cookie']
    if header
      cookies = header.split('; ').reduce({}) do |h, s|
        k, v = s.split('=') if s
        h[k.to_sym] = v if k and v
        h
      end
      if cookies[:XNClient] and cookies[:XNToken]
        api = XN::Api.new("#{cookies[:XNClient]} #{cookies[:XNToken]}")
        user = User.where(:email => api.get("/account").first["email"]).first rescue nil
        sign_in User, user if user
      end
    end
  end
end
