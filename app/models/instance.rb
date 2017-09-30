class Instance < ActiveRecord::Base

  belongs_to :last_node, class_name: "Node", foreign_key: 'last_node_id'

  #after_save :add_to_elastic



  ### search
  paginates_per 10

  ### search
  searchable_by_simple_filter


  ### add
  def self.add_row_to_db(instance_id, version=nil, sysinfo=nil)
    r = Instance.new(uid: instance_id, data: version, sysinfo: sysinfo)
    res = r.save
    r
  end

  ###
  def self.get_by_id(id)
    Instance.where(id: id).first
  end

  def self.get_by_uid(uid)
    Instance.where(uid: uid).first
  end

  # for elasticsearch cluster index
  def add_to_elastic
    row_hash = self.build_model_hash
    #Gexcore::LogModelToElasticsearch.model_to_elasticsearch(row_hash)
    ModelWorker.perform_async(row_hash) if row_hash
  end

  def build_model_hash
    row_hash = {}
    row_hash[:uid] = self.uid
    row_hash[:id] = self.id
    row_hash[:type_name] = self.class.name.downcase.pluralize

    row_hash
  end

end
