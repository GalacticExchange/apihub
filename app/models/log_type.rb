class LogType < Gexcore::LogDatabase
  has_many :log_system, class_name: "LogSystem"
  has_many :log_debug, class_name: "LogDebug"

  belongs_to :parent, class_name: "LogType", foreign_key: 'parent_id'

  ### validations
  validates :name, presence: true, length: {minimum: 2, maximum: 250 }
  validates :title, presence: true, length: {minimum: 2, maximum: 250 }

  ### search
  paginates_per 10

  ### search
  searchable_by_simple_filter

  def self.get_by_name(name)
    name = name.to_s.downcase

    #name = Gexcore::GexLogger::LEVEL_ALIASES[name] unless Gexcore::GexLogger::LEVEL_ALIASES[name].nil?

    # TODO: make cache

    where(name: name).first

  end

  def self.get_by_name_or_create(name)
    return nil if name.nil? || name.blank?

    #
    row = get_by_name name

    return row unless row.nil?

    # add
    LogType.create(name: name, title: name)
  end

  def self.make_visible_client(id)
    where(id: id).update_all "visible_client=1"
  end

  def self.make_invisible_client(id)
    where(id: id).update_all "visible_client=0"
  end


end
