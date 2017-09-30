class Cluster < ActiveRecord::Base

  OPTIONS = {
      'proxyIP'=>{type: 'string', set_from_user: true},
      'proxyUser'=>{type: 'string', set_from_user: true},
      'proxyPassword'=>{type: 'string', set_from_user: true},

      'hadoopType'=>{type: 'string', set_from_user: true},
      'staticIPs'=>{type: 'bool', set_from_user: true},
      'gatewayIP'=>{type: 'string', set_from_user: true},
      'networkMask'=>{type: 'string', set_from_user: true},
      'networkIPRangeStart'=>{type: 'string', set_from_user: true},
      'networkIPRangeEnd'=>{type: 'string', set_from_user: true},

      # for AWS clusters
      'aws_region'=>{type: 'string', set_from_user: true},
  }


  #
  belongs_to :team
  belongs_to :primary_admin, class_name: "User", foreign_key: 'primary_admin_user_id'
  belongs_to :cluster_type, class_name: 'ClusterType', foreign_key: 'cluster_type_id'
  belongs_to :hadoop_type, class_name: 'ClusterHadoopType', foreign_key: 'hadoop_type_id'
  belongs_to :hadoop_app, class_name: 'ClusterApplication', foreign_key: 'hadoop_app_id'


  belongs_to :aws_region

  has_many :nodes
  has_many :applications, class_name: 'ClusterApplication'
  has_many :containers, class_name: 'ClusterContainer'
  has_many :services, class_name: 'ClusterService'

  #
  has_many :invitations

  has_many :log_systems


  #
  has_many :dashboards


  ### status, state
  include AASM
  include ClusterStatus


  ### callbacks
  after_create :_after_create
  after_save :_after_save


  ### search
  paginates_per 10

  ### search
  searchable_by_simple_filter

  def status_id
    read_attribute(:status)
  end

  ### scopes
  #scope :w_not_deleted, -> { where.not(status: :deleted) }
  scope :w_not_deleted, -> { where('status != ?', statuses[:removed]) }
  #scope :w_active, -> { where('status = ?', STATUS_ACTIVE) }
  scope :w_active, -> { active }


  scope :w_aws, -> { where(cluster_type: ClusterType.get_by_name('aws').id) }
  scope :w_onprem, -> { where(cluster_type: ClusterType.get_by_name('onprem').id) }

  scope :of_q, lambda {  |q| where_q(q) }

  def self.where_q(q)

    #w_active.where("name LIKE ?", "#{q}%")
    if q.nil? || q.blank?
      w_active
    else
      # split by words
      words = Gexcore::SearchServiceBase.split_string_by_words(q)

      w_s = []
      w_p = {}
      ind = 1
      words.each do |s|
        p = "q#{ind}"
        w_s << " name LIKE :#{p} "
        w_p[:"#{p}"] = "#{s}%"
        ind += 1
      end

      if w_s.count > 0
        w_active.where(w_s.join(" OR "), w_p)
      else
        w_active
      end
    end

  end

  ### search elasticsearch
  include ClusterElasticsearchSearchable

  def self.es_reindex
    prefix = Rails.configuration.gex_config[:elasticsearch_prefix]

    Cluster.__elasticsearch__.create_index! force: true
    Cluster.import(:force=>true, index: prefix+'clusters')
    Cluster.__elasticsearch__.refresh_index!
  end


  ### callbacks

  before_create :_before_create

  def _before_create

    self.is_public ||= true
  end


  ###
  def self.get_by_id(id)
    Cluster.where(id: id).first
  end


  def self.get_by_uid(uid)
    Cluster.where(uid: uid).first
  end

  ###
  def self.get_by_name(name)
    Cluster.where(name: name).first
  end

  # array of IDs of admins
  def admin_ids()
    self.user_groups.w_admin.pluck(:user_id)
  end


  ###
  def options_hash
    return @options_hash unless @options_hash.nil?
    return {} if self.options.nil?

    @options_hash = JSON.parse(self.options) rescue {}

    @options_hash ||= {}
    @options_hash
  end

  def get_option(option_name)
    options_hash[option_name]
  end

  def option_static_ips?()
    v = get_option('staticIPs')

    return false if v.nil? || v.to_s=="0"

    v
  end



  ### properties

  def cluster_type_name
    cluster_type.name rescue ClusterType::DEFAULT_NAME
  end

  def hadoop_app_uid
    return self.hadoop_app.uid if self.hadoop_app
    nil
  end

  ### return info

  def to_hash
    {
        id: self.uid,
        name: self.name,
        domainname: self.domainname,
        status: self.status,
        hadoopApplicationID: self.hadoop_app.uid,
        clusterType: cluster_type_name,
        numberOfNodes: nodes.w_not_deleted.count,
        numberOfJoined: nodes.w_joined.count,
        team: {
            name: team.name
        },
        settings: options_hash_public
    }
  end

  def to_hash_w_region
    to_hash.merge(get_aws_region_hash)
  end

  def get_aws_region_hash
    aws_region_name = get_option('aws_region')
    return {} if aws_region_name.nil?

    aws_region = AwsRegion.get_by_id_or_name(aws_region_name)
    return {} if aws_region.nil?

    {aws_region: aws_region.to_hash}
  end

  def options_hash_public
    #
    a = options_hash

    res = {}
    return res if a.nil?

    res[:hadoopType] = self.hadoop_type.name

    OPTIONS.each do |opt, opt_info|
      next if a[opt].nil?

      res[opt]=a[opt]
    end

    res
  end


  # for ShareService.get_clusters_share_list_for_user
  def to_hash_share_cluster
    #
    data = {name: self.name, id: self.uid, status: self.status}

    data

  end

  def self.for_filter_statuses
    d = Cluster.statuses
    a = [["all", -1]]
    d.to_a.each do |t|
      a << t
    end
    a
  end


  ### apps

  #def app_hadoop
  #  return Gexcore::ApplicationsService.get_hadoop_app_for_cluster(self)
  #end


  ### containers
  def get_master_container(container_basename)
    row = self.containers.where(basename: container_basename).first
    row
  end

  def get_master_container_hadoop
    return get_master_container('hadoop')
  end
  def get_master_container_hue
    return get_master_container('hue')
  end

  ### callbacks
  def _after_save
    # elastic for logs
    #add_to_elastic
  end

  def _after_create
    # update clusters access in cache
    Gexcore::ClustersAccessService.cache_update_cluster_access_after_create_cluster(self.id)


  end




  # for elasticsearch cluster index
  def add_to_elastic
    row_hash = self.build_model_hash
    #Gexcore::LogModelToElasticsearch.model_to_elasticsearch(row_hash)
    ModelWorker.perform_async(row_hash) if row_hash
  end

  def build_model_hash
    array_of_change_fields = self.changed
    change_fields = ['title', 'name']
    if !(array_of_change_fields & change_fields).empty?
      row_hash = {}
      row_hash[:name] = self.name
      row_hash[:title] = self.title
      row_hash[:uid] = self.uid
      row_hash[:id] = self.id
      row_hash[:type_name] = self.class.name.downcase.pluralize

      return row_hash
    end

    nil
  end

end
