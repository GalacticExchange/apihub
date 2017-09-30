class LibraryApplication < ActiveRecord::Base

  METADATA = {
      'clusterMode'=>{type: 'bool'}
  }


  has_many :applications, class_name: 'ClusterApplication'
  belongs_to :library_application_type

  has_many :images, class_name: "ApplicationImage"
  accepts_nested_attributes_for :images, reject_if: :all_blank, allow_destroy: true

  has_attached_file :picture, {
      #:attachment/
      #url: "/applications/main/:id/:style.:extension",
      url: "/images/applications/:app_name/main.:style.:extension",
      hash_secret: "BlaBlaBla",
      :styles => {
          :thumb => ["150x172#",:jpg],
          :medium => ["400x400#",:png],
          :large => ["100%", :jpg]
      }
  }
  validates_attachment_content_type :picture, :content_type => /\Aimage\/.*\Z/


  has_attached_file :icon, {
      #:attachment/
      #url: "/applications/main/:id/:style.:extension",
      url: "/images/applications/:app_name/icon.:style.:extension",
      hash_secret: "sdfhjsdghrghf",
      :styles => {
          :thumb => ["40x40#",:png],
          :medium => ["100x100#",:png]
      }
  }
  validates_attachment_content_type :icon, :content_type => /\Aimage\/.*\Z/



  ### search elasticsearch
  include LibraryApplicationElasticsearchSearchable

  # paging
  paginates_per 10

  ### search
  searchable_by_simple_filter

  ### scopes
  scope :w_enabled, -> { where(enabled: true) }


  #scope :w_dev, -> {where(library_application_type_id: LibraryApplicationType.id_development) }
  #scope :w_handpicked, -> {where(library_application_type_id:  LibraryApplicationType.id_handpicked) }

  scope :w_dev, -> {where(library_application_type_id: LibraryApplicationType.get_id_by_name('development')) }
  scope :w_handpicked, -> {where(library_application_type_id:  LibraryApplicationType.get_id_by_name('handpicked')) }





  # add object, with filds who absent in DB, to elasticsearch
  after_save :es_update
  after_destroy :es_update


  ### get by name
  def self.get_by_name(name)
    where(name: name).first
  end

  # get by id
  def self.get_by_id(id)
    LibraryApplication.where(id: id).first
  end

  def es_update
    self.__elasticsearch__.index_document
  end

  def to_hash
    {
        id: id,
        name: name,
        title: title,
        categoryTitle: category_title,
        companyName: company_name,
        color: color,
        releaseDate: release_date,
        status: status
    }
  end

  def to_hash_with_images
    to_hash.merge(imageUrl: picture.url(:medium))
  end

  def metadata_hash_public

    meta = metadata_hash
    res = {}
    return res if meta.nil?

    METADATA.each do |opt, opt_info|
      next if meta[opt].nil?

      res[opt]=meta[opt]
    end
    res
  end


  def metadata_hash
    return @metadata_hash unless @metadata_hash.nil?

    return nil if self.metadata.nil?

    @metadata_hash = JSON.parse(self.metadata) rescue {}

    @metadata_hash ||= {}
    @metadata_hash
  end

  def get_metadata_field(field_name)
    metadata_hash[field_name]
  end




end
