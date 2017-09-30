module Gexcore
  class BaseSearchService < BaseService

    def self.model
      Object
    end

    def self.init_filter_from_params(filter, params)

      # pg, skip, limit
      if params[:pg]
        # set limit, skip from pg
        pg = params[:pg].to_i rescue nil
        pg ||= 1
        limit = model.default_per_page
        skip = (pg-1)*limit
      else
        limit = params[:limit] || model.default_per_page
        skip = params[:skip] || 0
      end


      # q
      q = params['q']


      # set values
      filter.set 'skip', skip
      filter.set 'limit', limit

      filter.set 'q', q unless q.nil?

      #
      filter
    end
  end
end

