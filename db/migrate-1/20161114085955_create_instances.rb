class CreateInstances < ActiveRecord::Migration
  def change
    create_table :instances do |t|
      t.string :uid
      t.text :admin_notes
      t.text :sysinfo

      t.timestamps null: false
    end
  end
end
