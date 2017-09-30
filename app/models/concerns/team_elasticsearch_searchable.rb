module TeamElasticsearchSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    include Elasticsearch::Model::Callbacks

    index_name "#{Rails.configuration.gex_config[:elasticsearch_prefix]}teams"

    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'false' do
        #indexes :title, analyzer: 'english', index_options: 'offsets'
        indexes :id,   :index    => :not_analyzed
        indexes :name,        :analyzer => 'standard', :boost => 100
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
                              query: query+'*',
                              analyze_wildcard:true,
                              fields: ['name', 'about']
                          }
=begin
                          multi_match: {
                              query: query+'*',
                              fields: ['name^10', 'about']
                          },
=end

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

=begin
                highlight: {
                    pre_tags: ['<em>'],
                    post_tags: ['</em>'],
                    fields: {
                        name: {},
                        about: {}
                    }
                },
=end
    end

  end
end
