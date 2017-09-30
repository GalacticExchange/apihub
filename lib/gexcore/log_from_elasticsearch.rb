##!/usr/bin/env ruby

module Gexcore
  class LogFromElasticsearch
    # install if absent gem install elasticsearch-dsl in your project
    require 'elasticsearch'
    require 'elasticsearch/dsl'
    include Elasticsearch::DSL

    #
    INDEX_DEBUG = 'gex_logs*'
    TYPE_DEBUG = 'logs'
    #
    INDEX_TYPE = 'gex_models'
    TYPE_TYPE = 'LogType'.underscore.pluralize

    def self.dsearch(filter)
      #
      fields_names = ['message^3', 'data^2', '_id^1']
      search_str = Gexcore::ElasticSearchHelpers.sanitize_string(filter.v('q'))
      if search_str.nil? || search_str.blank? || search_str.empty?
        search_str = "*"
      else
        search_str = ('*' + search_str + '*')
      end

      # search query
      definition = Elasticsearch::DSL::Search::Search.new do
        min_score 0.5
        # pagination
        from filter.v(:page_from)
        size filter.v(:page_size)
        query do
          filtered do
            query do
              query_string do
                query search_str
                fields fields_names
              end
            end
            filter do

              bool do
                elastic_fields = [:source_id, :team_id, :user_id, :subtype_id, :_score, :visible_client, :cluster_id, :node_id, :instance_id] #:instanceID, :nodeID, :clusterID, ]#, :cluster_id, :node_id, :instance_id, :type_id]
                #
                elastic_fields.each do |name|
                  v = filter.v(name)
                  if v && v>0
                    must do
                      term "#{name}": v
                    end
                  end
                end

                # level
                level = filter.v(:min_level)
                if level && level>0
                  must do
                    range "level" do
                      gte level
                    end
                  end
                end

                # ip
                ip = filter.v(:ip)
                if ip.present?
                  must do
                    term "ip": ip
                  end
                end

                # created_at range
                must do
                  range "created_at" do
                    gte filter.v(:date_f)
                    lte filter.v(:date_t)
                  end
                end

                # search by _id
                _id = filter.v(:_id)
                if _id
                  must do
                    term "_id": "#{_id}"
                  end
                end

                # search by type_name
                type_name = filter.v(:type_name)
                if type_name.present?
                  must do
                    term "type_name": type_name
                  end
                end


              end
            end
          end
        end
        highlight do
          pre_tags ['<em>']
          post_tags ['<em>']
          fields message: {}, data: {fragment_size: 80, number_of_fragments: 3}
        end
        sort do
          h = filter.order.to_h
          #
          h.map do |colname, dir|
            key = colname == "id" ? "created_at" : colname
            #by ""+key, order: dir
            by key, order: dir
          end
        end
      end

      definition = definition.to_hash
      client = Elasticsearch::Client.new trace: false, host: Gexcore::Settings.logs_elasticsearch_host, port: Gexcore::Settings.logs_elasticsearch_port

      #
      a = client.search index: INDEX_DEBUG, type: TYPE_DEBUG, body: definition
      #
      total = a['hits']['total']
      #
      hits = a['hits']['hits']
      #
      body_array = []
      #
      hits.each do |t|
        body = t["_source"]
        body['_id'] = t['_id']
        body_array << body
      end
      #
      gennadiy = adapt_array_for_api_logs(body_array)
      return [total, gennadiy]
    end

    def self.adapt_array_for_api_logs(array)
      adapt_array = []
      array.each do |t|
        t['adapt_created_at'] = t['created_at'].to_datetime.strftime("%Y-%m-%d %H:%M:%S"+" UTC")
        # user
        if t['user_id']
          t['user_name'] = User.find(t['user_id']).username rescue nil
        end
        # team
        t['team_name'] = Team.find(t['team_id']).name rescue nil
        # cluster
        if t['cluster_id']
          t['cluster_name'] = Cluster.find(t['cluster_id']).name rescue nil
        end
        # node
        if t['node_id']
          t['node_name'] = Node.find(t['node_id']).name rescue nil
        end
        # source
        if t['source_id']
          t['source_name'] = LogSource.find(t['source_id']).name rescue nil
        end
        #level
        t['level_name'] = Gexcore::GexLogger::LEVELS_BY_ID[t['level']] if t['level']
        # instance
        if t['instance_id']
          t['instance_uid'] = Instance.find(t['instance_id']).uid rescue nil
        end

        #
        adapt_array << t
      end
      adapt_array
    end

    def self.search_by_id(_id)
      # search query
      definition = Elasticsearch::DSL::Search::Search.new do
        min_score 0.5
        # pagination
        query do
          filtered do
            filter do
              bool do
                # search by _id
                if _id
                  must do
                    term "_id": "#{_id}"
                  end
                end
              end
            end
          end
        end
      end

      definition = definition.to_hash
      client = Elasticsearch::Client.new host: Gexcore::Settings.logs_elasticsearch_host, port: Gexcore::Settings.logs_elasticsearch_port
      #
      a = client.search index: INDEX_DEBUG, type: TYPE_DEBUG, body: definition
      #
      hits = a['hits']['hits']
      #
      body_array = []
      #
      hits.each do |t|
        body = t["_source"]
        body['_id'] = t['_id']
        body_array << body
      end
      #
      gennadiy = adapt_array_for_api_logs(body_array)
      vasilii = gennadiy[0]
      return vasilii
    end

    def self.tsearch(filter)
      #
      fields_names = ['name', 'title', '_id']
      search_str = Gexcore::ElasticSearchHelpers.sanitize_string(filter.v('name'))
      if search_str.nil? || search_str.blank? || search_str.empty?
        search_str = "*"
      else
        search_str = ('*' + search_str + '*')
      end

      # search query
      definition = Elasticsearch::DSL::Search::Search.new do
        min_score 0.5
        # pagination
        from filter.v(:page_from)
        size filter.v(:page_size)
        query do
          filtered do
            query do
              query_string do
                query search_str
                fields fields_names
              end
            end
            filter do

              bool do
                elastic_fields = [:need_notify, :enabled, :visible_client] #:instanceID, :nodeID, :clusterID, ]#, :cluster_id, :node_id, :instance_id]
                #
                elastic_fields.each do |name|
                  v = filter.v(name)
                  if v && v>=0
                    must do
                      term "#{name}": v
                    end
                  end
                end

                # search by _id
                _id = filter.v(:_id)
                if _id
                  must do
                    term "_id": "#{_id}"
                  end
                end

              end
            end
          end
        end
        highlight do
          pre_tags ['<em>']
          post_tags ['<em>']
          fields message: {}, data: {fragment_size: 80, number_of_fragments: 3}
        end
        sort do
          h = filter.order.to_h
          #
          h.map do |colname, dir|
            key = colname == "id" ? "name" : colname
            by key, order: dir
          end
        end
      end

      definition = definition.to_hash
      client = Elasticsearch::Client.new trace: false, host: Gexcore::Settings.logs_elasticsearch_host, port: Gexcore::Settings.logs_elasticsearch_port

      #
      a = client.search index: INDEX_TYPE, type: TYPE_TYPE, body: definition
      #
      total = a['hits']['total']
      #
      hits = a['hits']['hits']
      #
      body_array = []
      #
      hits.each do |t|
        body = t["_source"]
        body['_id'] = t['_id']
        body_array << body
      end
      #
      return [total, body_array]
    end


    def self.log_type_search_by_id_or_name(_id, name)
      # search query
      definition = Elasticsearch::DSL::Search::Search.new do
        min_score 0.5
        # pagination
        query do
          filtered do
            filter do
              bool do
                # search by _id
                if _id
                  must do
                    term "_id": "#{_id}"
                  end
                end
                # search by name
                if name
                  must do
                    term "name": "#{name}"
                  end
                end
              end
            end
          end
        end
        sort do
          by 'name', order: 'desc'
        end
      end

      definition = definition.to_hash
      client = Elasticsearch::Client.new host: Gexcore::Settings.logs_elasticsearch_host, port: Gexcore::Settings.logs_elasticsearch_port
      #
      a = client.search index: INDEX_TYPE, type: TYPE_TYPE, body: definition
      #
      hits = a['hits']['hits']
      #
      body_array = []
      #
      hits.each do |t|
        body = t["_source"]
        body['_id'] = t['_id']
        body_array << body
      end
      #
      vasilii = body_array[0]
      return vasilii
    end

    # serch for autocomplete
    def self.autocomplete_elastic_dsl(query_string, class_name, fields_names)
      search_str = Gexcore::ElasticSearchHelpers.sanitize_string(query_string)
      search_str = ('*' + search_str + '*')
      # search query
      definition = Elasticsearch::DSL::Search::Search.new do
        min_score 0.5
        # limit - max 10 row
        from 0
        size 10
        # pagination
        query do
          filtered do
            query do
              query_string do
                query search_str
                fields fields_names
              end
            end
          end
        end
        sort do
          by fields_names[0], order: 'asc'
        end
      end

      definition = definition.to_hash
      client = Elasticsearch::Client.new host: Gexcore::Settings.logs_elasticsearch_host, port: Gexcore::Settings.logs_elasticsearch_port
      #
      a = client.search index: INDEX_TYPE, type: class_name.underscore.pluralize, body: definition
      #
      hits = a['hits']['hits']
      #
      body_array = []
      #
      hits.each do |t|
        body = t["_source"]
        body['_id'] = t['_id']
        body_array << body
      end
      #
      return body_array
    end

  end
end

