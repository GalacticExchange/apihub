class AddHadoopCompatibleToAwsInstanceTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :aws_instance_types, :hadoop_compatible, :boolean
  end
end
