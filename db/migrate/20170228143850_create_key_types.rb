class CreateKeyTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :key_types do |t|

      t.timestamps
    end
  end
end
