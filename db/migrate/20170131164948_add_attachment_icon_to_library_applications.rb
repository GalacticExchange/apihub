class AddAttachmentIconToLibraryApplications < ActiveRecord::Migration
  def self.up
    change_table :library_applications do |t|
      t.attachment :icon
    end
  end

  def self.down
    remove_attachment :library_applications, :icon
  end
end
