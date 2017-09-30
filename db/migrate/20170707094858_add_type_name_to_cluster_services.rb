class AddTypeNameToClusterServices < ActiveRecord::Migration[5.0]
  def change
    add_column :cluster_services, :type_name, :string
  end
end
