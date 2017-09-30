module Gexcore
  class LogTypeSearchService < BaseSearchService

    def self.search_prefix
      'log_type_search_'
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
      total, res_es = model.tsearch(filter)#.page(filter.page).per(per_page)

      return [total,res_es]
    end

    def self.to_hash(response_es, filter)

      records = response_es#.records
      items = records.map{|r| r.to_hash}

      data = {
          results: items,
          page: response_es.current_page,#response_es.results.current_page,
          itemsPerPage: filter.v('limit', 10).to_i,
          #total: response_es.results.total
      }

    end

    # for elsticsearch created_at range in log_debug_elasticsearch_searchable.rb
    def self.set_pagin_filter(filter, from_page = 0, id = nil)
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
      #filter.set '_id', id if id
    end

    def self.create_or_update_log_type_in_elasticsearch(_id, params_hash)
      #
      true_params_hash = change_from_string_to_true_or_false(params_hash)
      #
      client = Elasticsearch::Client.new host: Gexcore::Settings.logs_elasticsearch_host, port: Gexcore::Settings.logs_elasticsearch_port

      if _id
        # update
        client.index index: Gexcore::LogFromElasticsearch::INDEX_TYPE,
                     type: Gexcore::LogFromElasticsearch::TYPE_TYPE,
                     id: _id,
                     body: true_params_hash,
                     refresh: true
        # check
        hash_obj = Gexcore::LogFromElasticsearch.log_type_search_by_id_or_name(_id, nil)
        return true_params_hash == hash_obj.except('_id', 'id')

      else
        # create
        client.index index: Gexcore::LogFromElasticsearch::INDEX_TYPE,
                     type: Gexcore::LogFromElasticsearch::TYPE_TYPE,
                     body: true_params_hash,
                     refresh: true
        #check
        hash_obj = Gexcore::LogFromElasticsearch.log_type_search_by_id_or_name(nil, true_params_hash['name'])
        return true_params_hash == hash_obj.except('_id', 'id')
      end

    end

    def self.change_from_string_to_true_or_false(params_hash)
      if params_hash['enabled'] == "true"
        params_hash['enabled'] = 1#true
      else
        params_hash['enabled'] = 0#false
      end
      #
      if params_hash['visible_client'] == "true"
        params_hash['visible_client'] = 1#true
      else
        params_hash['visible_client'] = 0#false
      end
      #
      if params_hash['need_notify'] == "true"
        params_hash['need_notify'] = 1#true
      else
        params_hash['need_notify'] = 0#false
      end
      #
      params_hash
    end


  end
end

