class Group
  class << self
    def all_with_users(api)
      groups = api.pull('/is/group',
                        [:id, :name,
                         {'traversal.read_users' => [:id]}])
      groups.sort_by { |record| record['name'] }.map do |record|
        [Group.new(api, record), record['traversal.read_users']]
      end
    end

    def all(api)
      groups = api.pull('/is/group',
                        [:id, :name])
      groups.sort_by { |record| record['name'] }.map do |record|
        Group.new(api, record)
      end
    end

    def empty_user_group_hash
      res = Hash.new { |h, k| h[k] = [] }
    end

    def users_to_groups_map(api)
      res = empty_user_group_hash
      all_with_users(api).inject(res) do |memo, (group, users)|
        if users
          users.each do |user|
            memo[user['id'].to_s] << group
          end
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
      user[0].to_s
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
