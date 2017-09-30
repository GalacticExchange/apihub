class AddFieldsToKeyTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :key_types, :name, :string
    add_column :key_types, :fields, :text
  end
end
