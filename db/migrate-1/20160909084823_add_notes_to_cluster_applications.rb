class AddNotesToClusterApplications < ActiveRecord::Migration
  def change
    add_column :cluster_applications, :notes, :string
  end
end
