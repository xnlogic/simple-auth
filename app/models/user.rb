class User < ActiveRecord::Base
  #Only enable :ldap_authenticatable if the config file is present and enabled. See 0_settings.rb under initializers.
  if Auth.ldap_enabled?
    devise :database_authenticatable, :ldap_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :timeoutable
    before_save :clean_password_for_ldap
  else
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :timeoutable
  end
  scope :same_client_as, lambda { |user| where client: user.client }

  class << self
    # Generate user records
    # +api+ should be an Api instantiated with the authenticator token for the client
    def create_users_from_api(api)
      api.get '/is/user' do |records|
        created = records.flat_map do |record|
          user = User.where(email: record['email']).first
          if user
            if user.client != api.client or user.api_user_id != record['id']
              user.client = api.client
              user.api_user_id = record['id']
              user.save
              puts "  Updating user: #{ api.client } #{ record['name'].inspect } / #{ record['email'] } : (password unchanged)"
              [{client: api.client, name: record['name'], email: record['email']}]
            else
              []
            end
          else
            if XN::Api.sample_password?(record['name'])
              password = record['name']
            else
              password = SecureRandom.random_number(36**12).to_s(36).rjust(12, "0")
            end
            user = User.where(email: record['email']).first_or_initialize(
              name: record['name'],
              user_name: record['email'],
              password: password,
            )
            user.client = api.client
            user.api_user_id = record['id']
            if user.save
              puts "  Creating user: #{ api.client } #{ record['name'].inspect } / #{ record['email'] } : #{ password }"
              [{client: api.client, name: record['name'], email: record['email'], password: password }]
            else
              []
            end
          end
        end
      end
    end

    def get_account_info(api)
      api.get('/account').first
    end

    def log_out_api(api)
      api.delete('/account').first
    end

    def token_timeout
      secs = ENV['TOKEN_EXTEND_SECONDS']
      secs ||= Devise.timeout_in if Devise.respond_to? :timeout_in
      secs || 30.minutes
    end

    def lookup_user_details(api, users)
      ids = users.map { |user| user.api_user_id }.join(',')
      details = api.pull("/is/user/ids/#{ids}", [:id, :service_account])
      details = details.group_by { |u| u['id'].to_s }
      users.each do |user|
        user.service_account = details[user.api_user_id].first['service_account']
      end
    end
  end
  validates_presence_of   :email
  validates_format_of     :email, with: /\A[^@]+@[^@]+\z/, allow_blank: true
  validate :unique_email_per_client

  validates_presence_of     :password, :on => :create
  validates_confirmation_of :password, :on => :create
  validates_length_of       :password, within: 6..72, allow_blank: true
  validates :name, presence: true
  validates :client, presence: true

  before_validation :scrub_fields

  before_create :replicate_to_api

  attr_accessor :service_account

  def unique_email_per_client
    if User.where(:email => email, :client => client).where.not(:id => id).count > 0
      errors.add(:email, "must be unique per client")
    end
  end

  def api_user_details(api)
    @details ||= if new_record? or not api_user_id
                   {}
                 else
                   api.pull(model_url(api_user_id), [:service_account, {inherit_read: [:id, :name]}]).first
                 end
    @service_account = @details['service_account']
    @details
  end

  def service_account
    if @service_account == '0'
      false
    else
      @service_account
    end
  end

  def groups(api)
    if new_record? or not api_user_id
      []
    else
      api_user_details(api)['inherit_read'].map do |record|
        Group.new api, record
      end
    end
  end

  def create_api_token
    XN::Api.authenticator_for(self) do |api|
      api.post token_action_url(api_user_id), soft_timeout: User.token_timeout.to_i
    end
  end

  def update_attributes_with_api(api, params, group_ids)
    if update_attributes(params)
      save_api_user(api, group_ids)
      true
    end
  end

  def save_with_api(api, group_ids)
    if save
      save_api_user(api, group_ids)
      true
    end
  end

  # Called by the devise_ldap_authenticatable gem when creating a user for the first time.
  # Assumed as Confirmed since passed LDAP Verification.
  # LM Client (e.g. sample001 is set from the ldap_config Proc (Currently loading from YAML under /opt/xn_apps/))
  def ldap_before_save(group_ids = nil)
    self.account_type = 'LDAP'
    self.client = Auth.ldap_config['xn_client']
    if name.blank?
      begin
        self.name = Devise::LDAP::Adapter.get_ldap_param(self.user_name,"cn").first.to_s
      rescue
        self.name = self.email
      end
    end
  end

  # For Security purposes do not persist LDAP Passwords to the DB when using both Strategies.
  def clean_password_for_ldap
    self.encrypted_password = '' if ldap?
  end

  def ldap?
    account_type == 'LDAP'
  end

  def local?
    account_type.blank? or account_type == 'LOCAL'
  end


  private

  def replicate_to_api
    XN::Api.admin_for(self) do |api|
      create_api_user(api, [])
      true
    end
  end

  def api_properties(group_ids = nil)
    {
      name: name,
      email: email,
      service_account: service_account
    }.merge(permission_properties(group_ids))
  end

  def save_api_user(api, group_ids = nil)
    api.patch model_url(api_user_id), api_properties(group_ids)
    save
  end

  def create_api_user(api, group_ids = nil)
    unless api_user_id
      self.api_user_id = api.put('/model/user_account', api_properties(group_ids)).first
    end
  end

  def scrub_fields
    self.phone = phone.blank? ? nil : phone.strip
  end

  def related_groups_url(id)
    "#{ model_url(id) }/rel/inherit_read"
  end

  def permission_properties(group_ids)
    if group_ids
      [:create, :read, :update, :delete, :action].each_with_object({}) do |perm, memo|
        if perm != :read and self.read_only
          memo["inherit_#{perm}"] = { set: nil }
        else
          memo["inherit_#{perm}"] = { set: group_ids }
        end

      end
    else
      {}
    end
  end

  def token_action_url(id)
    "#{ model_url(id) }/action/new_token?return_result"
  end

  def model_url(id)
    if id
      "/model/user_account/id/#{ api_user_id }"
    else
      fail XN::Error::BadRequestError, "Missing API user ID creating request"
    end
  end
end
