class AddTypeToKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :keys, :type, :string
  end
end
