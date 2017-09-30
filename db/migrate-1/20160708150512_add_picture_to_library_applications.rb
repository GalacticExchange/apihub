class AddPictureToLibraryApplications < ActiveRecord::Migration
  def self.up
    change_table :library_applications do |t|
      t.attachment :picture
    end
  end

  def self.down
    drop_attached_file :library_applications, :picture
  end
end
