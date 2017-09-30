class ClusterApplication < ActiveRecord::Base
  self.table_name = "cluster_applications"

  store :settings, coder: JSON

  attr_accessor :node_uid, :application_name

  belongs_to :library_application
  belongs_to :cluster

  has_many :containers, class_name: 'ClusterContainer', foreign_key: 'application_id'
  has_many :services, class_name: 'ClusterService', foreign_key: 'application_id'


  ### status
  include ApplicationStatus

  #validates :name, uniqueness: {scope: :cluster_id}
  validates :name, uniqueness: {scope: :cluster_id, conditions: -> { where('status <> ?', ClusterApplication.statuses[:removed]) } }
  validates_length_of :title, :minimum => 3, :maximum => 255, :allow_blank => true
  validates_length_of :notes, :minimum => 3, :maximum => 255, :allow_blank => true


  # paging
  paginates_per 10

  ### search
  searchable_by_simple_filter

  ### scope
  scope :w_active, -> { active }
  #scope :w_active, -> { where('status = ?', 1) }
  scope :w_not_deleted, -> { where('status <> ?', ClusterApplication.statuses[:removed]) }

  scope :w_internal, -> { where(external: false) }
  scope :w_external, -> { where(external: true) }

  scope :w_user_apps, -> { where("name not like 'hadoop%'") }
  scope :w_node, -> node { where(node: node)}






  ### get
  def self.get_by_id(id)
    where(id: id).first
  end

  def self.get_by_uid(uid)
    where(uid: uid).first
  end


  def self.get_for_cluster(app_name, cluster)
    library_app = LibraryApplication.get_by_name(app_name)
    return nil if library_app.nil?

    if cluster.is_a?(Integer)
      cluster = Cluster.find(cluster)
    end

    where(library_application_id: library_app.id, cluster_id: cluster.id).first
  end

  def self.get_by_name_and_cluster(app_name, cluster)
    if cluster.is_a?(Integer)
      cluster = Cluster.find(cluster)
    end

    where(name: app_name, cluster_id: cluster.id).first
  end


  ### hash

  def to_hash_created
    {
        applicationID: uid,
        name: name
    }
  end

  def to_hash
    {
        id: uid,
        name: name,
        clusterID: cluster.uid,
        status: status,
        title: title,
        notes: notes,
        external: external,
        apphub_id: external ? library_application_id : ''
    }
  end

  def to_hash_with_images
    image_url = library_application ? library_application.picture.url(:medium) : ''
    app_hash  = to_hash.merge(image_url: image_url)
    icon_url = library_application ? library_application.icon.url(:medium) : ''
    app_hash.merge(icon_url: icon_url)
  end

  def to_hash_with_library_application
    lib_app = library_application ? library_application.to_hash : ''
    to_hash_with_images.merge(library_application: lib_app)
  end


  ### settings

  def default_settings_hash
    {
        'base' => {
            'c1' => 'v1',
            'c2' => 'v2',
        },
        'nginx' => {
            'sitename' => 'mysite.com'
        }
    }
  end

  def default_settings
    {
        'base.c1' => 'v1',
        'base.c2' => 'v2',
        'nginx.sitename' => 'mysite.com'
    }

    {}
  end

  def set_default_settings
    a = default_settings

    Gexcore::Applications::Service.generate_install_config(self)

    a.each do |k,v|
      self.write_store_attribute(:settings, k,v)
      #self.settings[k]=v
    end
  end


end

