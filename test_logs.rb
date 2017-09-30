##!/usr/bin/env ruby


# install if absent gem install elasticsearch-dsl in your project
require 'elasticsearch'
require 'elasticsearch/dsl'
include Elasticsearch::DSL

#
HOST = '51.0.0.63'
PORT = 9200
INDEX = 'gex.logs*'
TYPE = 'logs'

#
#fields_names = ['message^3', 'data^2', 'type_name^1']
fields_names = ['message']
search_str = ''
_id = ''

def get_query_string(fields_names, search_str)
  query_string do
    query '*' + search_str + '*'
    fields fields_names
  end
end

#
filter = {type_name: nil, visible_client: nil, source_id: nil, type_id: nil, user_id: nil, team_id: nil, cluster_id: nil, node_id: nil, subtype_id: nil, instance_id: nil, min_level: 1, ip: "46.172.71.50", date_f: nil, date_t: nil}

def filter_fields(filter, _id = nil)
  elastic_fields = [:source_id, :user_id, :team_id, :cluster_id, :node_id, :subtype_id, :instance_id, :_score, :visible_client]

  elastic_fields.each do |name|
    v = filter[name]
    if v && v>0
      must do
        term "#{name}": v
      end
    end
  end

  # level
  level = filter[:min_level]
  if level && level>0
    must do
      range "level" do
        gte level
      end
    end
  end

  # ip
  ip = filter[:ip]
  if ip
    must do
      term "ip": ip
    end
  end

  # type_id
  type_name = filter[:type_name]
  if type_name
    must do
      term "type_name": type_name
    end
  end

  # created_at range
  must do
    range "created_at" do
      gte filter[:date_f]
      lte filter[:date_t]
    end
  end

  # search by _id
  if _id && !_id.empty?
    must do
      term "_id": "#{_id}"
    end
  end
end

### search query
=begin
definition = search do
  min_score 0.5
  from 0
  size 10
  query do
    filtered do
      query do
        get_query_string(fields_names, search_str)
      end
      filter do
        bool do
          filter_fields(filter, _id)
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
    by 'created_at', order: 'desc'
  end
end
=end


definition = search do
  min_score 0.5
  from 0
  size 10
  query do
    filtered do
      query do
        query_string do
          query 'POST AND request AND "nodes/add"'
          fields ['message']
        end
      end

      filter do
        bool do
          must do
            #term "message": "request GET /services"
            #term "message": "Adding node to cluster"
            term "type_name": "api_request_start"
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
    by 'created_at', order: 'desc'
  end
end


definition = definition.to_hash

client = Elasticsearch::Client.new trace: true, host: HOST, port: PORT
a = client.search index: INDEX, type: TYPE, body: definition

#
b = a['hits']['hits']
total = a['hits']['total']
#
body_array = []
#
b.each do |t|
  body = t["_source"]
  body['_id'] = t['_id']
  body_array << body
end
#
h = body_array
puts h
puts total

#puts h['user_id']
