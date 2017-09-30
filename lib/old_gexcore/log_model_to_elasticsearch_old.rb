##!/usr/bin/env ruby

#require 'multi_json'
#require 'faraday'
#require 'elasticsearch/api'
module Gexcore
  class LogModelToElasticsearchOld

    require 'elasticsearch'
    #require 'elasticsearch/api'
    require 'elasticsearch/dsl'
    #
    #include Elasticsearch::API
    include Elasticsearch::DSL
    #
    TYPE = "logs"

    def self.model_to_elasticsearch(row_hash)
      #
      row_hash = row_hash.symbolize_keys
      #
      client = Elasticsearch::Client.new trace: false
      #
      if !client.indices.exists(index: row_hash[:index_name])
        create_and_update_index(client, row_hash)
      end
      #
      elastic_row_id = get_id_for_row(client, row_hash)
      # create or update document in elasticsearch
      # create
      if elastic_row_id.to_s == ''
        client.index index: row_hash[:index_name],
                     type: TYPE,
                     body: get_body_fields(row_hash),
                     refresh: true
      # update
      else
        client.index index: row_hash[:index_name],
                     type: TYPE,
                     id: elastic_row_id,
                     body: get_body_fields(row_hash),
                     refresh: true
      end
    end

    def self.get_body_fields(row_hash)
      fields = {}
      row_hash.each do |k, v|
        fields[k.to_sym] = v if k != :index_name
      end
      fields
    end

    def self.create_and_update_index(client, row_hash)
      # create index
      client.indices.create index: row_hash[:index_name], type: TYPE

      # update index
      if row_hash[:index_name] == 'user'
        client.indices.put_mapping index: row_hash[:index_name], type: TYPE, body: {
            "#{TYPE}": {
                dynamic: 'strict',
                properties: {
                    :id => { :type => 'string', :index => :not_analyzed },
                    :username => {:type => 'string', :analyzer => 'standard'},
                }
            }
        }
      elsif row_hash[:index_name] == 'instance'
        client.indices.put_mapping index: row_hash[:index_name], type: TYPE, body: {
            "#{TYPE}": {
                dynamic: 'strict',
                properties: {
                    :id => { :type => 'string', :index => :not_analyzed },
                    :uid => { :type => 'string', :index => :not_analyzed },
                }
            }
        }
      else
        client.indices.put_mapping index: row_hash[:index_name], type: TYPE, body: {
            "#{TYPE}": {
                dynamic: 'strict',
                properties: {
                    :id => { :type => 'string', :index => :not_analyzed },
                    :name => {:type => 'string', :analyzer => 'standard'},
                    :title => {:type => 'string', :analyzer => 'standard'},
                    :uid => { :type => 'string', :index => :not_analyzed },
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
      a = client.search index: row_hash[:index_name], type: TYPE, body: definition
      #
      total = a['hits']['total']
      id = total == 0 ? nil : a['hits']['hits'][0]['_id']
      #
      id
    end

  end
end
