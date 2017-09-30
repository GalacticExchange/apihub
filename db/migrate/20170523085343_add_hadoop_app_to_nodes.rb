class AddHadoopAppToNodes < ActiveRecord::Migration[5.0]
  def change
    add_column :nodes, :hadoop_app_id, :integer, :default => nil, :null => true
  end
end
