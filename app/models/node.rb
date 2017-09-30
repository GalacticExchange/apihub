class Node < ActiveRecord::Base

  OPTIONS = {
      'aws_instance_type'=>{type: 'string', set_from_user: true},
      'server_host' => {type: 'string', set_from_user: true}
  }


  belongs_to :cluster
  belongs_to :host_type, class_name: 'NodeHostType', foreign_key: 'host_type_id'

  #
  belongs_to :instance

  has_many :containers, class_name: 'ClusterContainer'
  has_many :services, class_name: 'ClusterService'

  belongs_to :hadoop_app, class_name: 'ClusterApplication', foreign_key: 'hadoop_app_id'


  # status
  include NodeStatus

  # jobs state
  include NodeJobsState

  ### validations
  validates_uniqueness_of :name, :case_sensitive => false, conditions: -> { where.not(status: statuses[:removed]) }


  ### scopes
  scope :w_not_deleted, -> { where('status != ?', statuses[:removed]) }
  scope :w_joined, -> { where('status = ?', statuses[:active]) }


  ### callbacks
  #after_save :add_to_elastic


  ### search
  paginates_per 10

  ### search
  searchable_by_simple_filter

  ###
  def self.get_by_id(id)
    Node.where(id: id).first
  end

  def self.get_by_uid(uid)
    Node.where(uid: uid).first
  end

  def self.get_by_name(name)
    Node.where(name: name).first
  end

  def self.get_by_agent_token(agent_token)
    Node.where(:agent_token => agent_token).first
  end



  ### properties
  def domainname
    "#{name}.local"
  end


  ###

  def to_hash
    {
        name: name,
        id: uid,
        host: domainname,
        cluster: {
            id: cluster.uid
        },
        hostType: self.host_type.name,
        hadoopType: self.cluster.hadoop_type.name,
        hadoopAppId: self.hadoop_app_id,
        status: status_name,
        status_changed: status_changed,
        settings: options_hash_public,
        nodeNumber: node_number
    }
  end

  # hash return after creation
  def to_hash_created
        {
            clusterID: self.cluster.uid,
            clusterName: self.cluster.name,

            nodeID: self.uid,
            nodeName: self.name,
            nodeNumber: self.node_number,
            hostType: self.host_type.name,
            hadoopType: self.cluster.hadoop_type.name,
            nodeAgentToken: self.agent_token,
        }
  end


  def to_hash_agent
    {
        id: self.uid,
        name: self.name,
        ip: self.ip,
        port: self.agent_port,
    }
  end

  ### options


  def options_hash_public
    #
    a = options_hash

    res = {}
    return res if a.nil?

    OPTIONS.each do |opt, opt_info|
      next if a[opt].nil?

      res[opt]=a[opt]
    end

    res
  end


  def options_hash
    return @options_hash unless @options_hash.nil?
    return {} if self.options.nil?

    @options_hash = JSON.parse(self.options) rescue {}

    @options_hash ||= {}
    @options_hash
  end

  def get_option(option_name, v_def=nil)
    a = options_hash

    a[option_name] || v_def
  end

  def update_options(opts)
    upd_opts = JSON.parse(self.options) rescue {}
    new_opts = JSON.parse(opts) rescue {}
    upd_opts.merge new_opts
    self.options = upd_opts.to_json
  end


  def encode_option(v)
    require 'base64'

    Base64.encode64(v).gsub(/\n$/, '')
  end

  def self.encode_option(v)
    require 'base64'

    Base64.encode64(v).gsub(/\n$/, '')
  end

  def decode_option(v)
    Base64.decode64(v)
  end

  def self.decode_option(v)
    Base64.decode64(v)
  end

  def options_hash_enterprise
    return {} if self.cluster.options_hash.nil? || self.cluster.options_hash.empty?

    c = self.cluster

    res = {
      proxy_ip: c.get_option('proxyIP'),
      static_ips: c.option_static_ips?,
      gateway_ip: c.get_option('gatewayIP'),
      network_mask: c.get_option('networkMask'),
    }

    # container ips
    res[:container_ips] = {}
    self.containers.each do |container|
      res[:container_ips][container.name] = container.ip
    end


    res
  end

  ###

  def node_type_name
    self.cluster.cluster_type_name
  end

  def host_type_name
    self.host_type.name
  end

  ###
  def status_name(_status=nil)
    s = (_status || self.status).to_s
    #
    if s == "active"
      "joined"
    else
      s
    end
  end


  def self.for_filter_statuses
    d = Node.statuses
    a = [["all", -1]]
    d.to_a.each do |t|
      a << t
    end
    a
  end


  ###
  def prop_sensu_name
    "node_#{self.uid}"
  end
  def prop_sensu_id
    "#{self.uid}"
  end

  # set time for node status change
  def self.set_status_changed(node)
    node.status_changed = Time.now.utc.to_i
    node.save
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


  ### containers
  def get_container_by_name(container_basename)
    row = self.containers.where(basename: container_basename).first
    row
  end


  def get_container_hadoop
     get_container_by_name('hadoop')
  end


end
