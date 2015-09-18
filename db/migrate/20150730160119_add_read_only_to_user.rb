class AddReadOnlyToUser < ActiveRecord::Migration
  def change
    add_column :users, :read_only, :boolean
  end
end
