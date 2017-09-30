class FixKeyTypeName < ActiveRecord::Migration[5.0]
  def change
    rename_column :keys, :type, :key_type
  end
end
