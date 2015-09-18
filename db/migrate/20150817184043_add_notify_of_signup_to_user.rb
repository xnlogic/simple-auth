class AddNotifyOfSignupToUser < ActiveRecord::Migration
  def change
    add_column :users, :notify_of_signup, :boolean
  end
end
