class AddEtaToLibraryApplications < ActiveRecord::Migration
  def change
    add_column :library_applications, :ETA, :datetime
  end
end
