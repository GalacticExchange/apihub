class AddLibraryApplicationTypeToLibraryApplications < ActiveRecord::Migration[5.0]
  def change
    add_reference :library_applications, :library_application_type, foreign_key: true
  end
end
