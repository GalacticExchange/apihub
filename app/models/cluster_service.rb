class ClusterService < ActiveRecord::Base

  belongs_to :library_service, class_name: 'LibraryService', foreign_key: 'library_service_id'

  belongs_to :application, class_name: 'ClusterApplication', foreign_key: 'application_id'
  belongs_to :container, class_name: 'ClusterContainer', foreign_key: 'container_id'
  belongs_to :node
  belongs_to :cluster


  ### status
  include ClusterServiceStatus

  # scopes
  scope :w_active, -> { where( status: :active ) }
  scope :w_not_deleted, -> { where('status <> ?', statuses[:removed] ) }

  scope :w_http, -> { where( protocol: :http) }

  scope :w_master, -> { where('node_id IS NULL') }


  # callbacks
  before_validation :_before_validation
  after_create :_after_create

  ### search
  paginates_per 10

  ### search
  searchable_by_simple_filter

  ###
  #def self.all_names
  #  w_active.all.pluck(:name)
  #end



  ### operations

  def _before_validation
    self.status ||= "active"

    self.cluster_id ||= self.container.cluster_id
    self.node_id ||= self.container.node_id

  end


  def _after_create
    if self.port_out==0
      set_port_out_from_id
      res_save = save

      return res_save
    end

    true
  end

  def set_port_out_from_id
    self.port_out = 5000+self.id
  end


  ## properties



  def proxy_host
    Gexcore::AppHadoop::MasterContainer.calc_domain_proxy(self.container.name, self)
  end

  def get_public_ip
    self.container.local_ip
  end


  def need_proxy?(service_info={})
    # protocol
    protocol=self.protocol || service_info[:protocol]
    return false unless ['ssh', 'http', 'https', 'bolt', 'tcp'].include? protocol

    # onprem cluster
    if self.cluster.cluster_type_name==ClusterType::ONPREM
      if self.container.is_master?
        return true
      end

      return false
    end


    # for aws
    if self.cluster.cluster_type_name==ClusterType::AWS
      return true
    end

    false
  end


  ### get

  def self.get_by_id(id)
    where(id: id).first
  end

  def self.get_by_name_and_cluster(name, cluster)
    where(name: name, cluster_id: cluster.id).first
  end

  def self.get_by_name_and_node(name, node)
    where(name: name, node_id: node.id).first
  end


  def self.for_filter_statuses
    d = ClusterService.statuses
    a = [["all", -1]]
    d.to_a.each do |t|
      a << t
    end
    a
  end



  ###

  def to_hash_webproxy
    {
        app_name: self.name,
        source_port: self.port_out,
        dest_port: self.port_in
    }
  end


  def to_hash(opts={})
    res = {
        id: self.id,
        name: self.name,
        title: self.title,

        nodeName: (self.node ? self.node.name : nil),
        nodeID: (self.node ? self.node.uid : nil),
        status: self.status,
        containerName: self.container.name,
        masterContainer: self.container.is_master?,

        port: port_out,
        host: hostname,
        url: url,
        public_ip: get_public_ip,
        protocol: protocol,

    }

    # proxy
    if self.need_proxy?
      if self.protocol=='ssh'
        socks_proxy_ip = self.cluster.get_option('proxyIP')
        if socks_proxy_ip
          #socks_proxy_host: self.cluster.get_option('proxyIP')
          res[:socksProxy] = {
              "host": socks_proxy_ip,
              "user": self.cluster.get_option('proxyUser'),
              "password": self.cluster.get_option('proxyPassword'),
          }

        end
      elsif self.protocol == "http" ||  self.protocol == "https"
        res[:webProxy] = Gexcore::Settings.webproxy_host
      end
    end

    res
  end
end
