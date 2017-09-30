class ModelWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :model_to_elasticsearch

  def perform(row_hash)
    raise 'not used'

    Gexcore::LogModelToElasticsearch.model_to_elasticsearch(row_hash)

    return true
  end
end
