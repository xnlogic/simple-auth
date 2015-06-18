class Group
  class << self
    def all(api)
      groups = api.get('/is/group').map do |record|
        Group.new api, record
      end
      groups.sort_by! { |group| group.name }
    end

    def empty_user_group_hash
      res = Hash.new { |h, k| h[k] = [] }
    end

    def users_to_groups_map(api)
      res = empty_user_group_hash
      all(api).inject(res) do |memo, group|
        group.user_ids.each do |user_id|
          memo[user_id] << group
        end
        memo
      end
    end
  end

  attr_reader :id, :name, :api

  def initialize(api, record)
    @api = api
    @id = record['id']
    @name = record['name']
  end

  def user_ids
    api.get(group_users_url).map do |user|
      user[0]
    end
  end

  def users
    User.where(id: user_ids, client: api.client)
  end

  def ==(other)
    not other.nil? and other.is_a? Group and other.id == id and other.name == name
  end

  private

  def group_users_url
    "/model/user_account/filters/related_inherit_read/property/name?related_inherit_read=#{id}"
  end
end