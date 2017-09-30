module Gexcore::Applications

  class Metadata

    def gex_config
      Gexcore::Settings.config
    end

    def initialize(_app_name)
      #@app = _app
      @app_name = _app_name
    end

    #todo tmp name
    def initialize_new(cred, external)
      @cred = cred
      @external = external
    end

    def get_binding
      return binding()
    end

    ### config

    def config_params(opts)
      @props_metadata = opts
    end

    #
    def get_config_params
      @props_metadata ||= {}

      @props_metadata
    end

    # containers
    def containers(opts)
      @containers = opts
    end

    def get_containers
      @containers ||= {}

      @containers
    end


    # application info

    def app_info(opts)
      @app_info = opts
    end

    def get_app_info
      @app_info ||= {}

      @app_info
    end


    def get_app_short_cred
      case @app_info[:source][:type]
        when 'apphub'
          cred = @app_info[:source][:github_user]+':'+@app_info[:source][:url_path]
        when 'gex'
          cred = @app_info[:name]
      end
      cred
    end






    # attributes
    def attributes(opts)
      @attributes = opts
    end

    def get_attributes
      @attributes ||= {}

      @attributes
    end


    # services

    def services(opts)
      @services = opts
    end

    def get_services
      @services ||= {}

      @services
    end

    def get_services_with_ssh
      @services ||= {}

      # add ssh
      @services['ssh'] ||={
          name: 'ssh', title: "SSH", protocol: 'ssh', port: 22
      }

      @services
    end

    ### operations


    ### main method to init metadata from repo

    def load_new
      text = metadata_text
      binding = get_binding
      eval(text, binding)
    end


    def  load
      # download config from app repo
      #download
      text = file_text_metadata

      # process config from metadata
      binding = get_binding
      eval(text, binding)
      #config.config_params({x: 1, y: 2})
      #eval('config_params {x: 1, y: 2}', binding)
      #y = eval("config", binding)
    end


    def load_external(id, settings)

      #
      @services = settings[:services]


      #

      launch_options = Gexcore::Apphub::Service.metadata_to_launch_options(settings)
      meta_json = Gexcore::Apphub::Service.get_container_metadata(id)


      c_params = {}
      c_params[:launch_options] = launch_options
      c_params[:metadata] = settings[:metadata]

      # todo: tmp fix here > remove this call
      c_params.merge!(meta_json.to_hash)

      config_params = {}
      c_params.each do |key, val|
        config_params[key.to_sym] = {default_value: val}
      end

      @props_metadata = config_params
    end

    def load_compose(id, settings)

      @services = settings[:services]

      meta_json = Gexcore::Apphub::Service.get_compose_metadata(id)


      c_params = {}
      c_params[:launch_options] = launch_options
      c_params[:metadata] = settings[:metadata]

      # todo: tmp fix here > remove this call
      c_params.merge!(meta_json.to_hash)

      config_params = {}
      c_params.each do |key, val|
        config_params[key.to_sym] = {default_value: val}
      end

      @props_metadata = config_params
    end


=begin

    ### helpers
    def download
      Gexcore::ApplicationsService.download_file_from_gex_files(url_metadata, filename_metadata)
    end
=end

    def url_metadata
      version = Gexcore::Applications::Service.app_current_version(@app_name)
      gex_config.server_app_repo+"/gex-#{@app_name}-#{version}.metadata.rb"
    end

    def file_text_metadata
      #filename = filename_metadata
      #File.open(filename).read

      # file from remote url
      require 'open-uri'
      text = open(url_metadata) { |f| f.read }
      text
    end


    def metadata_text
      #metafile_url = @external ? Gexcore::Apphub::Service.get_metadata_url(@cred) : get_app_meta_url
      #todo cred[:github_user], cred[:url_path]

      # debug
      metafile_url = @external ? "http://localhost:3000/apps_meta/metadata.rb" : "http://localhost:3000/apps_meta/#{@app_name}.rb"

      require 'open-uri'
      text = open(metafile_url) { |f| f.read }
      text
    end

    def get_app_meta_url
      # todo
    end



=begin
    def filename_metadata
      #
      dir = File.join(gex_config.dir_clusters_data, "")
      #dir = File.join(gex_config.dir_clusters_data, "#{container.cluster_id}/applications/#{app.id}")
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
      File.expand_path(File.join(dir, "metadata.rb"))
    end
=end


  end
end
