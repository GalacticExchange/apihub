namespace :logs do

  task :es_import do
    Gexcore::Maintenance::Maintenance.es_import_log

    puts "done"


  end

  # remove rows from ES which are deleted in DB
  # input: last_id => delete up to this id
  # RAILS_ENV=production rake logs:es_fix_deleted[100000,200000]
  task :es_fix_deleted, [:from_id, :to_id] do |t, args|
    from_id = args[:from_id].to_i
    to_id = args[:to_id].to_i

    n = Gexcore::Maintenance::Maintenance.es_log_fix_deleted(from_id, to_id)

    puts "deleted #{n} records"


  end

  # for add to elastic nodes, clusters, users, instances. for cli logs adaptation filter

  task :add_models_to_elactic do

    Gexcore::Maintenance::Maintenance.add_to_es_from_db

    puts "everything is ok"

  end
end


