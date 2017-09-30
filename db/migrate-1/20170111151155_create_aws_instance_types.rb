class CreateAwsInstanceTypes < ActiveRecord::Migration
  def change
    create_table :aws_instance_types do |t|

      t.timestamps null: false
    end
  end
end
