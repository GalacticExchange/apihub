module Gexcore
  class LibraryApplicationSearchService < BaseSearchService

    def self.search_prefix
      'library_application_search_'
    end

    def self.model
      LibraryApplication
    end

    def self.search_by_filter(filter)

      res_es = model.search(filter).page(filter.page)
      items = res_es.records
      total = res_es.results.total

      a = res_es.results

      return [items, total]
    end

    def self.to_hash(items)

      res_items = items.map{|r| r.to_hash}
      data = {result: res_items}

    end

  end
end

