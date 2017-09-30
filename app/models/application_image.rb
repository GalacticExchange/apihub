class ApplicationImage < ActiveRecord::Base

  #mount_uploader :avatar, AvatarUploader
  belongs_to :library_application

  # paperclip
  has_attached_file :image, {
      # :attachment/
      url: "/images/applications/:app_name/:my_file_name.:style.:extension",
      hash_secret: "BlaBlaBla",
      :styles => {
          :thumb => ["150x172#",:jpg],
          :medium => ["300x300#",:jpg],
          :large => ["100%", :jpg]
      }
  }
  validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/

  def my_file_name
    "#{self.id}"
  end

end
