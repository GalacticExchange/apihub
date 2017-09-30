class LogDebug < Gexcore::LogDatabase
  self.table_name = "log_debug"

  belongs_to :source, foreign_key: :source_id, class_name: 'LogSource'
  belongs_to :type, foreign_key: :type_id, class_name: 'LogType'
  belongs_to :subtype, foreign_key: :subtype_id, class_name: 'LogType'

  belongs_to :user
  belongs_to :cluster
  belongs_to :team
  belongs_to :node
  belongs_to :instance


  ### search elasticsearch
  #include LogDebugElasticsearchSearchable

  # add object, with fields absent in DB, to elasticsearch
  #after_save :es_update
  #after_destroy :es_update

  ### search
  #paginates_per 10

  searchable_by_simple_filter

  def self.w_visible_client
    where(visible_client: true)

  end

  #
  scope :of_source, lambda {  |source_name| where_source(source_name) }

  def self.where_source(v)
    if v.present?
      where(source_id: LogSource.select("id").where(:name => v))
    else
      where("1=1")
    end
  end

  #
  scope :of_source_id, lambda {  |source_id| where_source_id(source_id) }

  def self.where_source_id(id)
    v = (id.to_i rescue 0)
    if v>0
      where(source_id: LogSource.select("id").where(:id => id))
    else
      where("1=1")
    end
  end


  #
  scope :of_log_type, lambda {  |type_name| where_log_type(type_name) }

  def self.where_log_type(v)
    if v.present?
      where(type_id: LogType.select("id").where(:name => v))
    else
      where("1=1")
    end
  end

  #
  scope :of_log_type_id, lambda {  |type_id| where_log_type_id(type_id) }

  def self.where_log_type_id(id)
    v = (id.to_i rescue 0)
    if v>0
      where(type_id: LogType.select("id").where(:id => id))
    else
      where("1=1")
    end
  end

  #
  scope :of_user, lambda {  |username| where_user(username) }

  def self.where_user(v)
    if v.present?
      where(user_id: User.select("id").where(:username => v))
    else
      where("1=1")
    end
  end
=begin
  # properties
  def to_s
    name
  end
=end
  def level_title
    Gexcore::GexLogger::LEVELS_BY_ID[self.level]
  end

  def source_name
    return nil if source.nil?

    source.name
  end

  # for add custom fields to elasticsearch
  def node_name
    return node.name if node
    nil
  end

  def user_name
    return user.username if user
    nil
  end

  def team_name
    return team.name if team
    nil
  end

  def cluster_name
    return cluster.name if cluster
    nil
  end


  #
  def data_hash
    return @data_hash unless @data_hash.nil?

    @data_hash = JSON.parse(self.data) rescue {}

    @data_hash
  end

  def to_sys_hash
    {
        date: Gexcore::Common.date_format(self.created_at),
        source: source_name,
        level: level,
        level_title: level_title,
        message: message,
        type_id: type_id,
        type: type.present? ? type.title : '',
        user_id: user_id,
        data: data_hash
    }

  end


  def to_hash
    {
        date: Gexcore::Common.date_format(self.created_at),
        source: source_name,
        level: level_title,
        message: message,
        type: type.present? ? type.title : '',
        user: user.present? ? self.user.to_hash : nil,
        node: node.present? ? self.node.name : nil,
        data: data_hash
    }
  end



end
