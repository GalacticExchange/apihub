class LogUserActionType < Gexcore::LogDatabase
  self.table_name = "log_user_action_types"

  has_many :log_user_actions

  def self.get_by_name(name)
    # TODO: make cache

    where(name: name).first

  end

end
