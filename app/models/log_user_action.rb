class LogUserAction < Gexcore::LogDatabase
  self.table_name = "log_user_actions"

  belongs_to :log_user_action_type
  belongs_to :user



end
