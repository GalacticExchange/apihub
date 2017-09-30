module Gexcore
  class FilesService < BaseService

    def self.base_path
      #config.storage_files_dir
      config.dir_clusters_data
    end

    def self.templates_dir
      return 'templates'
    end

    def self.templates_dir_path
      base_path + templates_dir
    end

    def self.list(cluster, for_name='', extra_args={})
      for_name = for_name.to_s

      if for_name=='nodeInstall'
        #node_number = extra_args[:nodeNumber] || extra_args['nodeNumber']
        node_uid = extra_args[:nodeID]
        node = Node.get_by_uid(node_uid)

        #
        res = list_node_install(node)
      else
        res = []
      end


      res
    end

    def self.list_node_install(node)
      cluster_id = node.cluster_id
      node_number = node.node_number

      data = []


      gex_logger.info 'debug_files', "files list", {cluster_id: cluster_id}

      # list all files for directory
      begin
        dirname = node_provision_dir_fullpath(cluster_id, node_number)
        gex_logger.info 'debug_files', "dir", {d: dirname}

        Dir.entries(dirname).each do |f|
          next if ['.','..'].include? f

          filename = node_provision_file_shortpath(f, node_number)
          fullpath = node_provision_file_fullpath(f, cluster_id, node_number)

          next unless File.exist?(fullpath)

          data << {filename: filename, size: File.size(fullpath)}
        end

        # old - from json
        #txt = File.read('data/files_node_install.json')
        #data = JSON.parse(txt, :quirks_mode => true)

        #data.each{|r| r['filename']='vagrant/'+node_number.to_s+'/'+r['filename']}

      rescue => e
        gex_logger.exception 'node_install_files: cannot get files', e, {cluster_id: cluster_id, node_number: node_number}
        return nil
      end

      return data
    end


    #### helper methods


    ### general - file/dir path

    def self.get_dir_fullpath(dir)
      base_path+dir
    end

    def self.make_file_fullpath(filename)
      base_path+filename
    end


    # file
    def self.file_fullpath(filename, cluster_id, p={})
      f = file_path(filename, cluster_id, p)
      make_file_fullpath(f)
    end


    def self.file_path(filename, cluster_id, p={})
      # file for app
      if p[:application_uid]
        app = ClusterApplication.get_by_uid(p[:application_uid])

        return "#{cluster_id}/applications/#{app.id}/config.json"
      end

      # node file
      if p[:node_uid]
        return node_file_path(filename,  p)
      end


      # cluster file
      return cluster_file_path(filename, cluster_id)
    end


    # for node
    def self.node_file_path(filename, p={})
      node = Node.get_by_uid(p[:node_uid])
      return "#{node.cluster_id}/nodes/#{node.node_number}/#{filename}"
    end

    # for cluster

    def self.cluster_file_path(filename, cluster_id, p={})
      return "#{cluster_id}/"+filename
    end

    def self.cluster_file_fullpath(filename, cluster_id, p={})
      f = cluster_file_path(filename, cluster_id)
      make_file_fullpath(f)
    end


    # file for app


    ### provision files for node

    def self.node_provision_dir_shortpath(node_number)
      #"vagrant/#{node_number}/"
      "node/"
    end
    def self.node_provision_dir_path(cluster_id, node_number)
      #"#{cluster_id}/vagrant/#{node_number}/"
      #"#{cluster_id}/nodes/#{node_number}/node/"
      "#{cluster_id}/nodes/#{node_number}/#{node_provision_dir_shortpath(node_number)}"
    end
    def self.node_provision_dir_fullpath(cluster_id, node_number)
      get_dir_fullpath(node_provision_dir_path(cluster_id, node_number))
    end


    def self.node_provision_file_shortpath(filename, node_number)
      node_provision_dir_shortpath(node_number)+filename
    end
    def self.node_provision_file_path(filename, cluster_id, node_number)
      node_provision_dir_path(cluster_id, node_number)+filename
    end

    def self.node_provision_file_fullpath(filename, cluster_id, node_number)
      make_file_fullpath(node_provision_file_path(filename, cluster_id, node_number))
    end


    ### methods to create, copy files, dirs

    def self.create_dir(dir_path)
      FileUtils.mkdir_p(get_dir_fullpath(dir_path))
    end

    def self.copy_file(filename_from, filename_to)
      require 'fileutils'

      path_from = make_file_fullpath(filename_from)

      #
      path_to = make_file_fullpath(filename_to)
      dest_folder = File.dirname(path_to)

      FileUtils.cp(path_from, dest_folder)
    end


  end
end

