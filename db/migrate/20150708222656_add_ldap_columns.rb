class AddLdapColumns < ActiveRecord::Migration
  def change
    add_column :users, :ldap_user_name, :string
    add_column :users, :ldap_user_dn, :string
    add_column :users, :account_type, :string, default: "LOCAL"
  end
end
