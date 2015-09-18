class ChangeApiUserIdToString < ActiveRecord::Migration
  def up
    change_column :users, :api_user_id, :string
  end

  def down
    change_column :users, :api_user_id, :integer
  end
end
