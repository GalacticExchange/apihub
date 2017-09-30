module Gexcore
  class LogDatabase < ActiveRecord::Base
    self.abstract_class = true
    establish_connection :"logs_#{Rails.env}"
  end
end
