class AddNameToKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :keys, :name, :string
    add_column :keys, :desc, :text
  end
end
