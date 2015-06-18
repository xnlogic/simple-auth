class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

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
  end

  validates :name, presence: true
  validates :client, presence: true

  before_validation :scrub_fields

  before_create :replicate_to_api

  def groups(api)
    @groups ||= if new_record? or not api_user_id
      []
    else
      api.get(related_groups_url(api_user_id)).map { |record| Group.new api, record }
    end
  end

  def create_api_token
    XN::Api.authenticator_for(self) do |api|
      api.post token_action_url(api_user_id)
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

  private

  def replicate_to_api
    XN::Api.admin_for(self) do |api|
      create_api_user(api, [])
      true
    end
  end

  def api_properties(group_ids = nil)
    { name: name, email: email }.merge(permission_properties(group_ids))
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
        memo["inherit_#{perm}"] = { set: group_ids }
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
