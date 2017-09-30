class AddCredsToKeys < ActiveRecord::Migration[5.0]
  def change
    add_column :keys, :creds, :text
  end
end
