# AppHub service for communication between our API and AppHub project API.
# This service should be used for all calls to AppHub API.
# AppHub API spec: http://git.gex/gex/apphub/wikis/home#api
module Gexcore::Apphub
  class Service

    ROUTES = {
        api_search: '/api/search',
        get_app: '/api/store_applications/get',
        get_random: ' /api/store_applications/random',

        # metadata
        metadata: '/api/app_meta/'
    }

    STATUSES = {good: 1, bad: 0}
    SOURCE_TYPES = [:github, :community, :official]

    TYPES = {
        container: 0,
        compose_application: 1
    }

    FIELDS = {
        id: {name: 'id', basic: true, meta: false},
        repo: {name: 'repo', basic: true, meta: false},
        name: {name: 'name', basic: true, meta: true},
        security_rating: {name: 'clair_rating', basic: true, meta: false},
        os_whole_name: {name: 'os_whole_name', basic: true, meta: false},
        source_type: {name: 'source_type', basic: true, meta: false},
        short_description: {name: 'short_description', basic: true, meta: false},

        application_type: {name: 'application_type', basic: true, meta: true},
        download_link: {name: 'download_link', basic: false, meta: true},

        github_link: {name: 'github_link', basic: false, meta: false, compose_meta: true},
        version_hash: {name: 'version_hash', basic: false, meta: false, compose_meta: true},
        github_user: {name: 'github_user', basic: false, meta: true, compose_meta: true},
        url_path: {name: 'url_path', basic: false, meta: true, compose_meta: true},

        size: {name: 'size', basic: false, meta: false},
        launch_options: {name: 'launch_options', basic: false, meta: false},
        metadata: {name: 'metadata', basic: false, meta: false, compose_meta: true},
        link_to_self: {name: 'link_to_self', basic: false, meta: false},
        services: {name: 'services', basic: false, meta: false, compose_meta: true},
    }


    def self.basic_fields
      FIELDS.select {|key, hash| hash[:basic]}.map {|key, hash| hash[:name]}
    end

    def self.metadata_fields
      FIELDS.select {|key, hash| hash[:meta]}.map {|key, hash| hash[:name]}
    end

    def self.compose_meta_fields
      FIELDS.select {|key, hash| hash[:compose_meta]}.map {|key, hash| hash[:name]}
    end

    def self.cred_fields
      %w(github_user url_path)
    end

    def self.all_fields
      FIELDS.map {|key, hash| hash[:name]}
    end

    def self.get_types_by_name(types)
      types.map {|type| TYPES[type]}.to_a
    end

    def self.get_all_types
      TYPES.map {|key, val| val}.to_a
    end


    def self.get_apphub_url(name)
      File.join(Gexcore::Settings.apphub_url, ROUTES[name.to_sym])
    end

    def self.get_metadata_url(cred)
      meta_base_url = get_apphub_url(:metadata)
      File.join(meta_base_url, cred[:github_user], cred[:url_path],'metadata')
    end

    def self.get_compose_url(cred)
      meta_base_url = get_apphub_url(:metadata)
      File.join(meta_base_url, cred[:github_user], cred[:url_path],'docker-compose')
    end

    def self.apphub_get(url, query)

      begin
        resp = HTTParty.get(url, query: query)
      rescue HTTParty::Error => e
        Gexcore::GexLogger.exception("HTTParty Error", e)
      rescue StandardError => e
        Gexcore::GexLogger.exception("StandardError", e)
      end

      if resp.nil? || resp.instance_of?(String)
        Gexcore::GexLogger.exception("No response from the AppHub", resp)
        return nil
      end

      unless resp.success?
        Gexcore::GexLogger.exception("Cannot connect to the AppHub", resp)
        return nil
      end

      resp
    end


    def self.search_list(search_query, page=1, per_page, types)

      app_types = get_types_by_name(types) || get_all_types

      url = get_apphub_url(:api_search)
      query = {
          fields: basic_fields,
          name: search_query,
          page: page,
          per_page: per_page,
          application_type: app_types
      }

      resp = apphub_get(url, query)
      return nil if resp.nil? || resp.body.nil?

      JSON.parse(resp.body) rescue {}
    end


    def self.get_by_id(id)
      url = get_apphub_url(:get_app)
      query = {
          id: id.to_i,
          fields: all_fields,
      }

      resp = apphub_get(url, query)
      return nil if resp.nil? || resp.body.nil?

      JSON.parse(resp.body) rescue {}
    end

    def self.get_cred_by_id(id)
      url = get_apphub_url(:get_app)
      query = {
          id: id.to_i,
          fields: cred_fields,
      }

      resp = apphub_get(url, query)
      return nil if resp.nil? || resp.body.nil?

      app = JSON.parse(resp.body) rescue {}

      return nil if app.nil? || app['github_user'].nil? || app['url_path'].nil?

      {github_user: app['github_user'], url_path: app['url_path']}
    end

    def self.get_by_github(github_user, url_path)
      url = get_apphub_url(:get_app)
      query = {
          github_user: github_user,
          url_path: url_path,
          fields: all_fields,
      }

      resp = apphub_get(url, query)
      return nil if resp.nil? || resp.body.nil?

      JSON.parse(resp.body) rescue {}
    end


    def self.get_container_metadata(id)
      url = get_apphub_url(:get_app)
      query = {
          id: id,
          fields: metadata_fields
      }

      res = apphub_get(url, query)
      return nil if res.nil?

      res
    end

    def self.get_compose_metadata(id)
      url = get_apphub_url(:get_app)
      query = {
          id: id,
          fields: compose_meta_fields
      }

      res = apphub_get(url, query)
      return nil if res.nil?

      res
    end


    def self.get_random
      url = get_apphub_url(:get_random)
      query = {fields: all_fields}

      resp = apphub_get(url, query)
      return nil if resp.nil? || resp.body.nil?

      JSON.parse(resp.body) rescue {}
    end




    ### advanced helpers


    # for single container apps

    def self.get_ports_from_meta(metadata)

      ports = {}

      return ports if metadata['metadata'].nil? || metadata['metadata']['expose'].nil?

      metadata['metadata']['expose'].each_with_index do |port, i|
        name = "#{metadata['name']}-#{i}"
        protocol = (port == '80' || port == 80 || port == 8080 || port == '8080') ? 'http' : ''
        ports[name] = {name: name, title: name.capitalize, protocol: protocol, port: port}
      end

      ports
    end


    def self.ports_to_services(ports,container_name)
      services = {}

      return services if ports.nil? || ports.empty?

      ports.each_with_index do |port, i|
        puts port
        name = "#{container_name}-#{i}"
        protocol = (port == '80' || port == 80 || port == 8080 || port == '8080') ? 'http' : ''
        services[name] = {name: name, title: name.capitalize, protocol: protocol, port: port}
      end

      services
    end


    def self.metadata_to_launch_options(settings)

      services = settings[:services] rescue nil
      metadata = settings[:metadata] rescue nil

      expose = services_to_expose(services)
      metadata[:expose] = expose

      make_code(metadata)
    end


    def self.services_to_expose(services)
      expose = []

      return expose if services.nil? || services.empty? || services == ''
      services.map {|service| expose << service[1][:port]}
      expose
    end

    def self.make_code(metadata)

      return nil if metadata.nil? || metadata == ''

      code = ''
      code << %Q(--change "WORKDIR #{metadata['workdir']}" ) unless metadata[:workdir].nil?
      code << %Q(--change "CMD #{metadata[:cmd]}" ) unless metadata[:cmd].nil?
      code << %Q(--change "ENTRYPOINT #{metadata[:entrypoint]}" ) unless metadata[:entrypoint].nil?
      unless metadata[:expose].nil? or metadata[:expose].empty?
        code << "--change \"EXPOSE "
        metadata[:expose].each do |entry|
          code << "#{entry} "
        end
        code << "\" "
      end
      unless metadata[:env].nil? or metadata[:env].empty?
        code << "--change \"ENV "
        metadata[:env].each do |entry|
          code << "#{entry} "
        end
        code << "\" "
      end
      code
    end

  end
end
