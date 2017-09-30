module ClusterElasticsearchSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    index_name "#{Rails.configuration.gex_config[:elasticsearch_prefix]}clusters"

    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'false' do
        indexes :id,   :index    => :not_analyzed
        indexes :name,        :analyzer => 'standard', :boost => 100
        indexes :title,        :analyzer => 'standard', :boost => 100
        #indexes :about,        :analyzer => 'standard'
        indexes :status,  index: :not_analyzed
      end
    end


    def self.search(query)
      __elasticsearch__.search(
          {
              query: {
                  filtered: {
                      query:{
                          query_string: {
                              query: query+'*',
                              analyze_wildcard:true,
                              fields: ['name', 'title']
                          }
                      },
                      filter: {
                          bool: {
                              should: [
                                  {
                                      term: {status: "active"}
                                  },
                              ]
                          }
                      }
                  }
              }
          }
      )

    end

  end
end
