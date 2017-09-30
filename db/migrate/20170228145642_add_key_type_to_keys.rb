class AddKeyTypeToKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :keys, :key_type_id, :integer
  end
end
