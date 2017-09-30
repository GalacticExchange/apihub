class AddExternalToClusterApplications < ActiveRecord::Migration[5.0]
  def change
    add_column :cluster_applications, :external, :boolean, default: true
  end
end
