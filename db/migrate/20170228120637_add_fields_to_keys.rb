class AddFieldsToKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :keys, :user_id, :integer
    add_column :keys, :uid, :integer
  end
end
