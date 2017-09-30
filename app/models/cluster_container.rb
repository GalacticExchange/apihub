class ClusterContainer < ActiveRecord::Base
  self.table_name = "cluster_containers"

  belongs_to :application, class_name: 'ClusterApplication', foreign_key: 'application_id'
  belongs_to :node
  belongs_to :cluster
  has_many :services, class_name: 'ClusterService', foreign_key: 'container_id'



  ### status
  include ContainerStatus


  ### callbacks
  before_validation :_before_validation

  ### scopes
  scope :master_containers, -> { where(node_id: nil) }
  scope :node_containers, -> { where("node_id IS NOT NULL") }

  scope :w_not_deleted, -> { where('status <> ?', ClusterContainer.statuses[:removed]) }
  scope :w_cluster, -> cluster { where(cluster: cluster)}



  ###
  def _before_validation
    self.cluster_id ||= self.node.cluster_id unless self.node_id.nil?
  end

  # paging
  paginates_per 10

  ### search
  searchable_by_simple_filter


  # for autocomplete
  def name_with_cluster_name
    self.name# + " - " + self.cluster.name
  end

  ##
  def domainname
    self.hostname
  end

  def docker_container_name
    self.basename
  end

  ###

  def self.get_by_name(name)
    self.where(name: name).first
  end

  def self.get_by_ip(ip)
    return nil if ip.nil?

    where(public_ip: ip).first
  end

  def self.get_by_id(id)
    where(id: id).first
  end

  def self.get_by_uid(uid)
    where(uid: uid).first
  end

  def self.get_master_for_cluster(container_basename, cluster)
    where(basename: container_basename, cluster_id: cluster.id, is_master: true).first
  end

  def self.get_for_cluster(container_basename, cluster)
    where(basename: container_basename, cluster_id: cluster.id).first
  end


  def self.get_by_node(container_basename, node)
    where(basename: container_basename, node_id: node.id).first
  end


  ### properties

  def is_master?
    self.node_id.nil?
  end




  def status_name(_status=nil)
    s = (_status || self.status).to_s
    #
    s
  end



  ### IPs
  def ip
    get_public_ip
  end

  #
  def local_ip
    return @local_ip unless @local_ip.nil?

    #
    @local_ip = get_local_ip
  end

  def get_public_ip
    get_local_ip
  end

  def get_local_ip
    Gexcore::Containers::Service.get_public_ip_of_container(self)
  end

  #
  def gex_ip
    return @gex_ip unless @gex_ip.nil?

    #
    @gex_ip = get_gex_ip
  end


  def get_gex_ip
    Gexcore::Containers::Service.get_private_ip_of_container(self)
  end

  def get_private_ip
    get_gex_ip
  end



  ###
  def to_hash(opts={})
    {
      name: self.name,
      basename: self.basename,
      nodeName: (self.node ? self.node.name : nil),
      nodeID: (self.node ? self.node.uid : nil),
      status: self.status,
      applicationName: (self.application ? self.application.name : nil),
      applicationID: (self.application ? self.application.uid : nil),
      masterContainer: is_master?,

      domainname: domainname,
      local_ip: local_ip,
      gex_ip: gex_ip,
      id: self.uid,
    }
  end


end
