class AddNameToAwsInstanceTypes < ActiveRecord::Migration
  def change
    add_column :aws_instance_types, :name, :string
  end
end
