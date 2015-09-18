class AddClient < ActiveRecord::Migration
  def change
    add_column :users, :client, :string
  end
end
