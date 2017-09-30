class AddRegistrationIpToUsers < ActiveRecord::Migration
  def change
    add_column :users, :registration_ip, :string
  end
end
