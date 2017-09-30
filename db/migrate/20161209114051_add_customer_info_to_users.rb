class AddCustomerInfoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :customer_info, :text
  end
end
