class CreateAwsRegionInstanceTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :aws_region_instance_types do |t|
      t.references :aws_region, foreign_key: true
      t.references :aws_instance_type, foreign_key: true

      t.timestamps
    end
  end
end
