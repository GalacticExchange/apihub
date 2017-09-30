Elasticsearch::Model.client = Elasticsearch::Client.new({
  host: Rails.configuration.gex_config[:elasticsearch_host],
  port: (Rails.configuration.gex_config[:elasticsearch_port] || 9200)
})

