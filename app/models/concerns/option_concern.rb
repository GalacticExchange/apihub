module OptionConcern
  extend ActiveSupport::Concern

  included do
    after_save :cache_del
  end

  def cache_del
    Gexcore::OptionService.cache_del_option(self.name)
  end

  module ClassMethods

    def get_by_name(name)
      row = where("name = ?",  name).first
      row
    end
  end

end
