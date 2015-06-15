class AddXnProperties < ActiveRecord::Migration
  def change
    add_column :users, :api_user_id, :integer
    add_column :users, :client, :string
    add_column :users, :phone, :string
  end
end
