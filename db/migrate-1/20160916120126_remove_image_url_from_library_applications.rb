class RemoveImageUrlFromLibraryApplications < ActiveRecord::Migration
  def change
    remove_column :library_applications, :image_url, :string
  end
end
