module Gexcore
  class LogDebugSearchService < BaseSearchService

    def self.search_prefix
      'log_debug_search_'
    end

    def self.model
      #LogDebug
      Gexcore::LogFromElasticsearch
    end

=begin
    # old with Elasticsearch::Model
    def self.search_by_filter(filter)
      #
      per_page = (filter.v('limit', 10).to_i rescue 10)
      res_es = model.search(filter).page(filter.page).per(per_page)

      #a = res_es.results
      # total = res_es.results.total

      return [res_es, res_es.records]
    end
=end

    def self.search_by_filter(filter)
      total, res_es = model.dsearch(filter)#.page(filter.page).per(per_page)

      return [total,res_es]
    end

    def self.to_hash(arr_of_hashes, total)#, filter)

      # add user_name if exists to arr_of hashes for client

      hashes_for_client = []
      arr_of_hashes.each do |t|
        if t['user_id']
          user = User.w_active.find(t['user_id'])rescue nil
          t['userName'] = user.username if user
          hashes_for_client << t
        else
          t['userName'] = nil
          hashes_for_client << t
        end
      end

      data = {
          results: hashes_for_client,
          #page: response_es.results.current_page,
          #itemsPerPage: filter.v('limit', 10).to_i,
          total: total
      }

    end

    # for elsticsearch created_at range in log_debug_elasticsearch_searchable.rb
    def self.set_date_and_pagin_filter(filter, from_page = 0, id = nil)
      # for date
      df = filter.v(:date_from)
      dt = filter.v(:date_to)
      #
      timestr_from = Time.parse(df) rescue nil
      timestr_to = Time.parse(dt) rescue nil
      #
      elstr_from = timestr_from.strftime("%Y-%m-%dT%H:%M:%SZ") if timestr_from
      elstr_to = timestr_to.strftime("%Y-%m-%dT%H:%M:%SZ") if timestr_to
      #
      filter.set 'date_f', elstr_from
      filter.set 'date_t', elstr_to

      # for pagination
      size = 10
      if from_page == 0 || from_page == 1
        page_from = size * 0
      else
        page_from = size * (from_page - 1)
      end
      #
      filter.set 'page_from', page_from
      filter.set 'page_size', size

      # for search by _id
      filter.set '_id', id if id # obsolete, maybe

      # for search by type_name
      if filter.v(:type).present? && filter.v(:type_id) == 0
        filter.set 'type_name', filter.v(:type)
        #@log_type = Gexcore::LogFromElasticsearch.log_type_search_by_id_or_name(nil, filter.v(:type))
        #filter.set 'type_id', @log_type['_id'] if @log_type
      end

    end

  end
end

