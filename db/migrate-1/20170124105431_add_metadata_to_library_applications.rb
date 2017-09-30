class AddMetadataToLibraryApplications < ActiveRecord::Migration
  def change
    add_column :library_applications, :metadata, :text
  end
end
