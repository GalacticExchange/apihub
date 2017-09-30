module LibraryApplicationElasticsearchSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    #include Elasticsearch::Model::Callbacks

    index_name "#{Rails.configuration.gex_config[:elasticsearch_prefix]}library_application"


    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'true' do
        indexes :id,             :index    => :not_analyzed, :type => 'integer'
        indexes :name,           :analyzer => 'standard', :boost => 90
        indexes :title,          :analyzer => 'standard', :boost => 80
        indexes :git_repo,       :analyzer => 'standard', :boost => 60
        indexes :description,    :analyzer => 'standard', :boost => 70
        indexes :enabled,        :index    => :not_analyzed, :type => 'boolean'
        indexes :pos,            :index    => :not_analyzed, :type => 'integer'
        # for ES sorting by id
        indexes :sort_id,        :index    => :not_analyzed, :type => 'integer'
      end
    end

    def as_indexed_json(options={})
      attrs = {
          :name => self.name,
          :title => self.title,
          :git_repo => self.git_repo,
          :description => self.description,
          :enabled => self.enabled,
          :pos => self.pos,
          # for ES sorting by id
          :sort_id => self.id,
      }
      attrs.as_json
    end

    def self.search(filter)
      #
      q = Gexcore::ElasticSearchHelpers.sanitize_string(filter.v('q')) || ""

      #
      __elasticsearch__.search(
          {
              min_score: 0.5,
              query: {
                  filtered: {

                      query:{

                          query_string: {
                              query: "*" + q + '*',
                              fields: ['name', 'title', 'git_repo', 'description']
                          }
                      },
                      filter: {
                          bool: {
                              must: get_terms(filter),
                          }
                      }

                  }
              },
              highlight: lib_highlight(filter),
              #size: 5,
              sort: get_order(filter)
          }
      )

    end

    def self.get_terms(filter)
      a = []
      # name
      name = filter.v(:name)
      a << {match_phrase_prefix: {name:name}} if name.present?

      # title
      title = filter.v(:title)
      a << {match_phrase_prefix: {title: title}} if title.present?
      a

      # enabled
      enabled = filter.v(:enabled)
      a << {term: {enabled: enabled}} if enabled == 0 || enabled == 1
      a
    end

    def self.get_order(filter)
      h = filter.order.to_h

      # score
      return [ '_score' ] if h['score'].present?

      #
      h.map do |colname, dir|
        key = colname == "id" ? "sort_id" : colname
        {key => {:order => dir}}
      end
    end

    def self.lib_highlight(filter)
      if filter.v('q').present?
        {
            pre_tags: ['<em>'],
            post_tags: ['</em>'],
            fields: {
                name: {},
                title: {},
                image_url: {fragment_size: 80, number_of_fragments: 3},
                git_repo: {fragment_size: 80, number_of_fragments: 3},
                description: {fragment_size: 80, number_of_fragments: 3}
            }
        }
      else
        {}
      end
    end

  end

end
