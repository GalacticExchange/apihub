class AddImagesToApplicationImages < ActiveRecord::Migration
  def self.up
    change_table :application_images do |t|
      t.attachment :image
    end
  end

  def self.down
    drop_attached_file :application_images, :image
  end
end
