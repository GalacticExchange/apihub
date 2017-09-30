class LogSystem < Gexcore::LogDatabase
  self.table_name = "log_system"

  belongs_to :source, foreign_key: :source_id, class_name: 'LogSource'
  belongs_to :type, foreign_key: :type_id, class_name: 'LogType'
  belongs_to :user
  belongs_to :cluster
  belongs_to :team
  belongs_to :node

=begin
  def self.add(log_name, user_id, cluster_id, data={})
    log_type = LogType.get_by_name(log_name)
    r = LogAccess.new(log_type: log_type, user_id: user_id, cluster_id: cluster_id, data: data.to_json)
    r.save
    r
  end
=end


  ### properties

  def to_s
    name
  end


  ### search
  searchable_by_simple_filter



  ### scopes

  def self.w_visible_client
    where(visible_client: true)

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

  ###
  def level_title
    Gexcore::GexLogger::LEVELS_BY_ID[self.level]
  end

  def source_name
    return nil if source.nil?

    source.name
  end

  def data_hash
    return @data_hash unless @data_hash.nil?

    @data_hash = JSON.parse(self.data) rescue {}

    @data_hash
  end



  def to_hash
    {
        date: Gexcore::Common.date_format(self.created_at),
        source: source_name,
        level: level_title,
        type: type.present? ? type.title : '',
        user: user.present? ? self.user.to_hash : nil,
        message: message,
        data: data_hash,

    }
  end

end
