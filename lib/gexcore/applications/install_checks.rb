module Gexcore::Applications
  class InstallChecks


    def self.set_wrong_meta_res(res)
      res.set_error_forbidden('wrong metrics provided', 'Cannot check app requirements - config may be outdated.')
    end

    def self.set_wrong_depends_res(res, cont_name)
      res.set_error("App depends on the #{cont_name}.", "App depends on the <b>#{cont_name}</b> container which is not installed on this node.", '', 500)
    end

    def self.set_no_component_res(res, component_name)
      res.set_error("App depends on the #{component_name}.", "App depends on the <b>#{component_name}</b> compoent which is not enabled in the current cluster.", '', 500)
    end

    def self.set_no_space_res(res)
      # todo
      #res.set_error("Not enough #{name}", "Not enough #{name} to install #{lib_app.title}. Available on node: #{val} GB, estimated requirements: #{app_metric_val} GB.", '', 403)
    end


    # check permissions
    def self.check_requirements_by_user(lib_app_name, node_uid, user)

      res = Gexcore::Response.new

      app_library = LibraryApplication.get_by_name(lib_app_name)
      node = Node.get_by_uid(node_uid)


      # check permissions
      if !(user.can? :view_node_info, node)
        return res.set_error_forbidden("view_node_error", 'No permissions to view this node')
      end

      Gexcore::Applications::InstallChecks.can_install_app?(app_library, node, res)
    end


    def self.can_install_app?(lib_app, node, res)

      res ||= Response.new


      ### check container dependencies
      app_info = get_app_info(lib_app.name)
      dependencies_cont = app_info[:dependencies][:containers]

      if dependencies_cont.nil?
        return set_wrong_meta_res(res)
      end

      dependencies_cont.each do |cont_name|
        cont = node.get_container_by_name(cont_name)
        if cont.nil?
          return set_wrong_depends_res(res, cont_name)
        end
      end


      ### check components dependencies
      dependencies_comp = app_info[:dependencies][:components]

      # get enabled components for cluster
      res = Gexcore::Clusters::Components.get_enabled_cluster_components(node.cluster, res)

      if res.error?
        return res
      end

      cluster_components = res.data[:components]

      dependencies_comp.each do |component|
        if !cluster_components.include?(component.to_s)
          return set_no_component_res(res, component)
        end
      end


      ### check space requirements
      app_metrics = get_requirements_lib_app(lib_app)
      metrics_available = get_metrics_available_in_node(node)

      metrics_available.each do |name, val|
        app_metric_val = app_metrics[name]

        if app_metric_val.nil?
          return set_wrong_meta_res(res)
        end

        if (val - app_metric_val) < 0
          round_val = val.round(3)
          return res.set_error("Not enough #{name}", "Not enough #{name} to install #{lib_app.title}. Available on node: #{round_val} GB, estimated requirements: #{app_metric_val} GB.", '', 403)
        end

      end

      res.set_data
    end


    def self.get_metrics_available_in_node(node)

      containers = node.containers.w_not_deleted

      used = get_metrics_used(containers)
      node_metrics = Gexcore::Monitoring::NodesMonitoring.get_all_metrics_for_node(node)
      metrics_available = get_metrics_available(used, node_metrics)

      metrics_available
    end


    def self.get_app_info(app_name)
      app_metadata = Gexcore::Applications::Metadata.new(app_name)
      app_metadata.load #_new  # todo debug - load_new, use 'load'

      app_info = app_metadata.get_app_info
    end


    def self.app_get_metrics(app_name)
      app_info = get_app_info(app_name)
      app_info[:metrics]
    end


    def self.get_requirements_lib_app(lib_app)

      requirements = { }
      app_metrics = app_get_metrics(lib_app.name)

      return requirements if app_metrics.nil?

      app_metrics.each do |cont, metrics|
        requirements = add_to_used(metrics, requirements)
      end

      requirements
    end


    def self.get_metrics_used(containers)

      used = { }

      containers.each do |cont|
        app = cont.application
        lib_app = app.library_application

        # next if apphub app
        next unless lib_app

        app_metrics = app_get_metrics(lib_app.name)

        cont_metrics = app_metrics[cont.basename.to_sym]
        used = add_to_used(cont_metrics, used)
      end

      used
    end


    def self.add_to_used(cont_metrics, used)
      cont_metrics.each do |name, val|
        if used[name].nil?
          used[name] = 0
        end
        used[name] += val
      end
      used
    end


    def self.get_metrics_available(used, node_metrics)

      metrics_available = { }

      used.each do |name, val|
        total_name = "#{name}_total".to_sym
        node_metric = node_metrics[total_name]

        if node_metric.nil?
          metrics_available[name] = nil
          next
        end

        total_val = node_metric.value
        metrics_available[name] = total_val - val
      end

      metrics_available
    end


  end
end