class RemoveUsersIndexFromUser < ActiveRecord::Migration
  def change
    remove_index(:users, :name => 'index_users_on_email')
    add_index(:users, [:email, :client], unique: true, name: 'by_client_email')
  end
end
