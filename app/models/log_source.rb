class LogSource < Gexcore::LogDatabase
  #has_many :log_system, class_name: "LogSystem"
  has_many :log_debug, class_name: "LogDebug"

  ### validations
  validates :name, presence: true, length: {minimum: 2, maximum: 50 }
  #validates :title, presence: true, length: {minimum: 2, maximum: 50 }

  ### search
  paginates_per 10

  ### search
  searchable_by_simple_filter

  def self.get_by_name(name)
    name = name.to_s.downcase

    # aliases
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
    LogSource.create(name: name, title: name)
  end

end
