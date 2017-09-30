class AddDeprecatedToAwsInstanceTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :aws_instance_types, :deprecated, :boolean
  end
end
