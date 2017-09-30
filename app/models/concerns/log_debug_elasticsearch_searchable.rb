module LogDebugElasticsearchSearchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    #include Elasticsearch::Model::Callbacks

    index_name "#{Rails.configuration.gex_config[:elasticsearch_prefix]}log_debug"


    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'true' do
        indexes :id,             :index    => :not_analyzed, :type => 'integer'
        indexes :source_id,      :index    => :not_analyzed
        indexes :type_id,        :index    => :not_analyzed
        indexes :user_id,        :index    => :not_analyzed
        indexes :team_id,        :index    => :not_analyzed
        indexes :cluster_id,     :index    => :not_analyzed
        indexes :node_id,        :index    => :not_analyzed
        indexes :subtype_id,     :index    => :not_analyzed
        indexes :instance_id,    :index    => :not_analyzed
        indexes :message,        :analyzer => 'standard', :boost => 100
        indexes :data,           :analyzer => 'standard', :boost => 50
        # add custom fieds to elastic
        indexes :node_name,      :index    => :not_analyzed
        indexes :user_name,      :index    => :not_analyzed
        indexes :team_name,      :index    => :not_analyzed
        indexes :cluster_name,      :index    => :not_analyzed
        #
        indexes :ip,             :index    => :not_analyzed
        indexes :level,          :index    => :not_analyzed, :type => 'integer'
        indexes :_score,         :index    => :not_analyzed, :type => 'integer'
        indexes :created_at,     :index    => :not_analyzed, :type => 'date'
        indexes :visible_client, :index    => :not_analyzed, :type => 'boolean'

        # for ES sorting by id
        indexes :sort_id,        :index    => :not_analyzed, :type => 'integer'
      end
    end
#=begin
    def as_indexed_json(options={})
      attrs = {
          #:id => self.id,
          :source_id => self.source_id,
          :type_id => self.type_id,
          :user_id => self.user_id,
          :team_id => self.team_id,
          :cluster_id => self.cluster_id,
          :node_id => self.node_id,
          :subtype_id => self.node_id,
          :instance_id => self.instance_id,
          :message => self.message,
          :data => self.data,
          :node_name => self.node_name,
          :user_name => self.user_name,
          :team_name => self.team_name,
          :cluster_name => self.cluster_name,
          :ip => self.ip,
          :level => self.level,
          #:_score => self._score,
          :created_at => self.created_at,
          :visible_client => self.visible_client,

          # for ES sorting by id
          :sort_id => self.id,
      }
      #
      attrs.as_json
    end
#=end
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
                              query: q + '*',
                              fields: ['message', 'data', 'node_name', 'user_name', 'team_name', 'cluster_name']
                          }
                      },
                      filter: {
                          bool: {
                              must: get_terms(filter),
                          },
                      },

                  },

              },
              highlight: {
                  pre_tags: ['<em>'],
                  post_tags: ['</em>'],
                  fields: {
                      message: {},
                      data: {fragment_size: 80, number_of_fragments: 3}
                  }
              },
              #size: 5,
              sort: get_order(filter)
          }
      )

    end

    def self.get_terms(filter)
      a = []

      elastic_fields = [:source_id, :type_id, :user_id, :team_id, :cluster_id, :node_id, :subtype_id, :instance_id, :_score, :visible_client]

      elastic_fields.each do |name|
        v = filter.v(name)
        a << {term: {name => v}} if v.present? && v>0
      end
=begin
      visible = filter.v(:visible_client)
      a << {term: {visible_client: visible}} if visible.present?
=end
      # level
      v = filter.v(:min_level)
      a << {  range: { level: { gte: v } } } if v.present? && v>0

      # ip
      ip = filter.v(:ip)
      a << {term: {ip: ip}} if ip.present?

      # created_at range
      a <<  {range:
               {
                   created_at: {
                       gte: filter.v(:date_f),
                       lte: filter.v(:date_t)
                   },
               }
            }

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



    def es_update
      self.__elasticsearch__.index_document
    end


  end
end
