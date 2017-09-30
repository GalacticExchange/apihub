class RemoveKeyTypeIdFromKeys < ActiveRecord::Migration[5.0]
  def change
    remove_column :keys, :key_type_id, :integer
    remove_column :keys, :desc, :text
    remove_column :keys, :user_id, :text
  end
end
