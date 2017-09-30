class FilesController < BaseController

  before_action :init_data


  def init_data
    # authorize request
    init_auth_data

    if @res_auth.error?
      return (return_json @res_auth)
    end


    # set cluster
    if !@res_auth.data[:agent_node_id].nil?
      @node = Node.get_by_id @res_auth.data[:agent_node_id]

      # by node
      @current_cluster = @node.cluster
    else
      init_current_cluster
    end



  end


  def list

    check_current_cluster || return

    # input
    for_name = params[:for] || ''

    #
    lib = Gexcore::FilesService

    #
    user = current_user

    #
    files = lib.list(@current_cluster, for_name, params)

    if files.nil?
      return_json(Gexcore::Response.res_error("", "Cannot get files list", "cannot get files list for #{for_name}, params: #{params.inspect}"))
      return
    end

    return_json_data({files: files})
  end

  def download
    # input
    filename = params[:filename] || ''

    if filename.empty?
      return_json Gexcore::Response.res_error_badinput("", "filename is empty", "") and return
    end

    # input
    p = {}
    p[:application_uid] = params[:applicationID]
    p[:node_uid] = params[:nodeID]

    #
    lib = Gexcore::FilesService

    # get file
    #user = current_user
    cluster = @current_cluster

    # node from agent token
    if @node
      p[:node_uid] = @node.uid
    end


    # req apphub
    # return json

    #
    path = lib.file_fullpath(filename, cluster.id, p)

    #
    if !File.exist?(path)
      gex_logger.debug("debug_files", "file not found #{path}")
      return_json Gexcore::Response.res_error("files_download_error", "File not found", "", 404) and return
    end

    # download
    #File.read(path)
    send_file path, :disposition => 'inline'

  end

end

