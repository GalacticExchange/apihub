class CreateAwsRegions < ActiveRecord::Migration
  def change
    create_table :aws_regions do |t|
      t.string :name
      t.string :title

      t.timestamps null: false
    end
  end
end
