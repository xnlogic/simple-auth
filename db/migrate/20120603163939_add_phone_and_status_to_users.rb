class AddPhoneAndStatusToUsers < ActiveRecord::Migration
  def change
    add_column :users, :api_user_id, :integer
    add_column :users, :phone, :string
    #add_column :users, :status, :string, :default => 'unconfirmed'
    #execute "update users set status='confirmed'"
  end
end
