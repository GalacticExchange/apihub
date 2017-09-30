module Gexcore
  class SearchServiceBase < BaseService

    def self.split_string_by_words(q)
      words = q.scan(/\S+/)

      words.reject{|s| s.blank?}
    end

  end
end
