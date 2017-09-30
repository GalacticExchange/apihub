class AddStatusToLibraryApplications < ActiveRecord::Migration
  def change
    add_column :library_applications, :status, :integer
  end
end
