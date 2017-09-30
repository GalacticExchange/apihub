class AddCustomerInfoUpdatedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :customer_info_updated, :datetime
  end
end
