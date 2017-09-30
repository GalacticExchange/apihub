module Gexcore
  class ClustersSearchService < BaseSearchService

    def self.search_prefix
      'clusters_search_'
    end

    def self.model
      Cluster
    end

    def self.create_filter_from_params(params, _session)
      #
      filter_options = {}

      filter = SimpleSearchFilter::Filter.new(_session, search_prefix, filter_options)

      # define filter
      filter.set_default_order 'id', 'desc'
      filter.field 'q', :string, :text, {label: 'Title', default_value: '', ignore_value: '', condition: :custom, condition_scope: :of_q}


      #
      init_filter_from_params filter, params

    end


    def self.search(params, _session)
      #
      filter = create_filter_from_params(params, _session)

      items, total = search_by_filter(filter)

      #
      res_items = items.map{|r| r.to_hash}
      data = {result: res_items, total: total}

      Response.res_data data
    end

    def self.search_by_filter(filter)
      # simple_search_filter
      #items = User.by_filter(filter, {:paging=>false}).limit(filter.v('limit')).offset(filter.v('skip'))

      # elasticsearch
      q = filter.v('q')
      if q.nil? || q.blank?
        items = []
        total = 0
      else
        qq = Gexcore::ElasticSearchHelpers.sanitize_string(q).rstrip
        res_es = model.search(qq).limit(filter.v('limit')).offset(filter.v('skip'))
        items = res_es.records
        total = res_es.results.total
      end

      return [items, total]
    end


    def self.search_total_by_filter(filter)
      q = filter.v('q')
      if q.nil? || q.blank?
        total = 0
      else
        qq = q.rstrip
        total = model.search(qq).results.total
      end

      total
    end

  end
end

