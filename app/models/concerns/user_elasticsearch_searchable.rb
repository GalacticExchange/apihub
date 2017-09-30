module UserElasticsearchSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    index_name "#{Rails.configuration.gex_config[:elasticsearch_prefix]}users"


    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'false' do
        indexes :id,   :index    => :not_analyzed
        indexes :username,        :analyzer => 'standard', :boost => 100
        indexes :firstname,        :analyzer => 'standard', :boost => 50
        indexes :lastname,        :analyzer => 'standard', :boost => 50
        indexes :about,        :analyzer => 'standard'
        indexes :status, :index    => :not_analyzed
      end
    end

    def self.search(query)
      __elasticsearch__.search(
          {
              query: {
                  filtered: {
                      query:{
                          query_string: {
                              query: query+"*",
                              analyze_wildcard:true,
                              fields: ["username", 'firstname', 'lastname', 'about']
                          }
                      },
                      filter: {
                          bool: {
                              should: [
                                  {
                                      term: {status: "1"}
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
