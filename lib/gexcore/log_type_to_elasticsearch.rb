##!/usr/bin/env ruby

#require 'multi_json'
#require 'faraday'
#require 'elasticsearch/api'
module Gexcore
  class LogTypeToElasticsearch

    require 'elasticsearch'
    #require 'elasticsearch/api'
    require 'elasticsearch/dsl'
    #
    #include Elasticsearch::API
    include Elasticsearch::DSL
    #
    INDEX = 'gex_models'

    def self.model_to_elasticsearch(row_hash)
      if row_hash.nil?
        raise 'no object'
      end

      #
      row_hash.symbolize_keys!

      #
      client = Elasticsearch::Client.new host: Gexcore::Settings.logs_elasticsearch_host, port: Gexcore::Settings.logs_elasticsearch_port

      # check existing index
      if !client.indices.exists(index: INDEX)
        create_index(client)
      end
      # check existing type in index
      if !client.indices.exists_type(index: INDEX, type: row_hash[:type_name])
        add_type_and_update_index(client, row_hash)
      end
      #
      elastic_row_id = get_id_for_row(client, row_hash)
      # create or update document in elasticsearch
      # create
      if elastic_row_id.to_s == ''
        client.index index: INDEX,
                     type: row_hash[:type_name],
                     body: get_body_fields(row_hash),
                     refresh: true
      # update
      else
        client.index index: INDEX,
                     type: row_hash[:type_name],
                     id: elastic_row_id,
                     body: get_body_fields(row_hash),
                     refresh: true
      end
    end

    def self.get_body_fields(row_hash)
      fields = {}
      row_hash.each do |k, v|
        fields[k.to_sym] = v if k != :type_name
      end
      fields
    end

    def self.create_index(client)
      # create index
      client.indices.create index: INDEX
    end

    def self.add_type_and_update_index(client, row_hash)

      # update index and add type
      if row_hash[:type_name] == 'users'
        client.indices.put_mapping index: INDEX, type: row_hash[:type_name], body: {
            "#{row_hash[:type_name]}": {
                dynamic: 'strict',
                properties: {
                    :id => { :type => 'string', :index => :not_analyzed },
                    :username => {:type => 'string', :analyzer => 'standard'},
                }
            }
        }
      elsif row_hash[:type_name] == 'instances'
        client.indices.put_mapping index: INDEX, type: row_hash[:type_name], body: {
            "#{row_hash[:type_name]}": {
                dynamic: 'strict',
                properties: {
                    :id => { :type => 'string', :index => :not_analyzed },
                    :uid => { :type => 'string', :index => :not_analyzed },
                }
            }
        }
      elsif row_hash[:type_name] == 'nodes' || row_hash[:type_name] == 'clusters'
        client.indices.put_mapping index: INDEX, type: row_hash[:type_name], body: {
            "#{row_hash[:type_name]}": {
                dynamic: 'strict',
                properties: {
                    :id => { :type => 'string', :index => :not_analyzed },
                    :name => {:type => 'string', :analyzer => 'standard'},
                    :title => {:type => 'string', :analyzer => 'standard'},
                    :uid => { :type => 'string', :index => :not_analyzed },
                }
            }
        }
      else # for LogType
        client.indices.put_mapping index: INDEX, type: row_hash[:type_name], body: {
            "#{row_hash[:type_name]}": {
                dynamic: 'strict',
                properties: {
                    :id => { :type => 'string', :index => :not_analyzed },
                    :name => {:type => 'string', :analyzer => 'standard'},
                    :title => {:type => 'string', :analyzer => 'standard'},
                    :decription => { :type => 'string', :analyzer => 'standard' },
                    :enabled => { :type => 'boolean', :index => :not_analyzed },
                    :visible_client => { :type => 'boolean', :index => :not_analyzed },
                    :need_notify => { :type => 'boolean', :index => :not_analyzed },
                }
            }
        }
      end

    end

    def self.get_id_for_row(client, row_hash)
      #
      fields_names = ['id']

      # search query
      definition = Elasticsearch::DSL::Search::Search.new do
        #min_score 0.5
        query do
          query_string do
            query row_hash[:id]
            fields fields_names
          end
        end
      end

      definition = definition.to_hash
      #
      a = client.search index: INDEX, type: row_hash[:type_name], body: definition
      #
      total = a['hits']['total']
      id = total == 0 ? nil : a['hits']['hits'][0]['_id']
      #
      id
    end

  end
end
