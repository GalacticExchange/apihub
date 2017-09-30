module Maintenance
  class Maintenance

    ### options
    def self.set_options
      f = File.join(Rails.root, 'config', 'gex', 'options.'+Rails.env+'.rb')
      filename = File.expand_path(f)

      require filename

      opt = GexInitOptions::OPTIONS

      #puts "o=#{opt}"

      #
      opt.each do |name, v|
        Option.set(name, v)
      end


    end

    ###
    def self.update_ansible_dir
      run_ansible_task("cd " + "#{Gexcore::Settings.storage_files_dir}" + " 2>&1" + " && git pull origin master" + " 2>&1")
    end

    def self.run_rake_task(task_name)
      %x(rake #{task_name})
      #`rake #{task_name}`
    end

    def self.run_ansible_task(task_name)
      #
      q = Gexcore::Provision::AnsibleRequest.new

      # do the job
      res_ansible = q.run(task_name)

      # for log
      exit_code = q.exit_code
      res_output = q.res_output

      if exit_code.to_i>0
        output = "exit_code = #{exit_code}; message: #{res_output}"
      else
        output = "exit_code = #{exit_code}; message: #{res_output}"
      end

      output

    end

    def self.es_import_index
      prefix = Rails.configuration.gex_config[:elasticsearch_prefix]

      #
      User.import(:force=>true, index: prefix+'users')
      User.__elasticsearch__.refresh_index!

      #
      Team.import(:force=>true, index: prefix+'teams')
      Team.__elasticsearch__.refresh_index!

      #
      Cluster.import(:force=>true, index: prefix+'clusters')
      Cluster.__elasticsearch__.refresh_index!
    end


    def self.es_import_log
      #
      prefix = Rails.configuration.gex_config[:elasticsearch_prefix]

      #
      model = LogDebug
      model.import(:force=>true, index: prefix+'log_debug')
      model.__elasticsearch__.refresh_index!
      #model.import

      # v2
      #model.__elasticsearch__.create_index! force: true
      #model.__elasticsearch__.refresh_index!
      #model.import(:force=>true, index: prefix+'log_debug')


    end

    # remove rows from ES which are deleted in DB
    # input: last_id => delete up to this id
    def self.es_log_fix_deleted(from_id, last_id)

      #
      client = Elasticsearch::Model.client
      index_name = "#{Rails.configuration.gex_config[:elasticsearch_prefix]}log_debug"
      index_type = 'log_debug'


      #
      min_id = LogDebug.order('id asc').first.id

      # remove deleted rows
      n_deleted = 0

      from_id.upto last_id do |ind|
        begin
          # check row exist
          exist = true
          if ind < min_id
            exist = false
          else
            exist = LogDebug.exists?(id: ind)
          end

          #
          if !exist
            client.delete index: index_name, type: index_type, id: ind
            n_deleted = n_deleted+1
          end

        rescue =>e
        end

      end

      return n_deleted
    end


    def self.es_import_library_apps
      #
      prefix = Rails.configuration.gex_config[:elasticsearch_prefix]
      #
      LibraryApplication.__elasticsearch__.create_index! force: true
      LibraryApplication.__elasticsearch__.refresh_index!
      LibraryApplication.import(:force=>true, index: prefix+'library_application')

    end

    def self.add_to_es_from_db

      User.w_not_deleted.each do |t|
        row_hash = {}
        row_hash[:username] = t.username
        row_hash[:id] = t.id
        row_hash[:type_name] = t.class.name.downcase.pluralize
        #
        Gexcore::LogModelToElasticsearch.model_to_elasticsearch(row_hash)
      end

      Cluster.w_not_deleted.each do |t|
        row_hash = {}
        row_hash[:name] = t.name
        row_hash[:title] = t.title
        row_hash[:uid] = t.uid
        row_hash[:id] = t.id
        row_hash[:type_name] = t.class.name.downcase.pluralize
        #
        Gexcore::LogModelToElasticsearch.model_to_elasticsearch(row_hash)
      end

      Node.w_not_deleted.each do |t|
        row_hash = {}
        row_hash[:name] = t.name
        row_hash[:title] = t.title
        row_hash[:uid] = t.uid
        row_hash[:id] = t.id
        row_hash[:type_name] = t.class.name.downcase.pluralize
        #
        Gexcore::LogModelToElasticsearch.model_to_elasticsearch(row_hash)
      end

      Instance.all.each do |t|
        row_hash = {}
        row_hash[:uid] = t.uid
        row_hash[:id] = t.id
        row_hash[:type_name] = t.class.name.downcase.pluralize
        #
        Gexcore::LogModelToElasticsearch.model_to_elasticsearch(row_hash)
      end

      LogType.all.each do |t|
        row_hash = {}
        row_hash[:name] = t.name
        row_hash[:title] = t.title
        row_hash[:description] = t.description
        row_hash[:id] = t.id
        row_hash[:enabled] = t.enabled
        row_hash[:visible_client] = t.visible_client
        row_hash[:need_notify] = t.need_notify
        # for elasticsearch type name in index
        row_hash[:type_name] = t.class.name.underscore.pluralize
        #
        Gexcore::LogModelToElasticsearch.model_to_elasticsearch(row_hash)
      end

    end


  end
end
