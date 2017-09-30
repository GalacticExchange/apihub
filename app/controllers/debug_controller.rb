class DebugController < BaseController
  before_action :_before_action

  def _before_action


    #raise 'Forbidden' if ['production'].include? Rails.env
  end


  def ping
    return_json_data({:ping=>'ok'})
  end


  def addcmsuser_prod
    email = 'webmaster@galacticexchange.io'
    row = Optimacms::CmsAdminUser.where(email: email).first || Optimacms::CmsAdminUser.new

    row.email = email
    row.password = 'HubbPH_GEX_PASSWD1'
    row.password_confirmation = row.password
    #row.skip_confirmation!

    row.save!

    raise 'Changed'

  end


###
  def addcmsuser
    row = Optimacms::CmsAdminUser.where(email: 'admin@example.com').first || Optimacms::CmsAdminUser.new

    row.email = 'admin@example.com'
    row.password = 'PH_GEX_PASSWD1'
    row.password_confirmation = row.password
    #row.skip_confirmation!

    row.save

  end


  #
  def env
    x = ENV['gex_env']
    y = ENV['myvar']
    z = Gexcore::Settings.myvar

    data = {x: x, y: y, z: z}
    return_json_data data
  end


# config
  def myconfig
    c = Rails.configuration.gex_config

    #return_json_data(c)
    render :html=> JSON.pretty_generate(c)
  end


  def create_support_user
    Services::InstallService.create_support_user
    return_json_ok
  end

  def create_system_user
    Services::InstallService.create_system_user

    return_json_ok
  end


  def normalize_friendly_id(input)
    input.to_s.to_slug.normalize(transliterations: :russian).to_s
  end

  def trans

    y = x.to_slug.normalize.transliterate(:russian).to_s
    #y = x.to_url

    z=0

  end

  ### token
  def token
    username = params[:username]
    pwd = params[:pwd]

    res_auth = Gexcore::AuthService.auth(username, pwd)

    return_json res_auth
  end

  def parse_token

    token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6ImtoMCIsInVzZXJfaWQiOjQ1MCwiZXhwIjoxNDkwODgxMDk4fQ.qgNazPpmJK_IBHtlYEFhxTSR6eDjMt1aDD0gBgTpVnM'
    token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6ImtoMCIsInVzZXJfaWQiOjQ1MCwiZXhwIjoxNDkwODgyMDg4fQ.x6VVMAc02Z-uKCzFIPSnkCEPOSMlTBllQdaWGd0qERY'


    res = Gexcore::AuthService.validate_token(token)

    x = 0
  end


  def add_user
    team = Team.find(1)

    u_old = User.where(username: 'mmx').first
    u_old.destroy!

    u = User.new(
        username: 'mmx', email: 'mmx@gex.io', password: 'PH_GEX_PASSWD1', password_confirmation: 'PH_GEX_PASSWD1',
        team_id: 1, teamname: team.name, group_id: 1, main_cluster_id: 1,
        firstname: 'Buba', lastname: 'Bebe'
    )
    u.password = 'PH_GEX_PASSWD1'
    u.save!

    render text: 'ok'
  end


  def share_create
    #
    username = "m16"

    admin1 = User.get_by_username("m11")
    cluster1 = admin1.home_cluster

    admin2 = User.get_by_username("m10")
    cluster2 = admin2.home_cluster

    # work
    res1 = Gexcore::Shares::Service.create_share_by_admin(admin1, cluster1, username)
    res2 = Gexcore::Shares::Service.create_share_by_admin(admin2, cluster2, username)

  end

  def es_import
    prefix = Rails.configuration.gex_config[:elasticsearch_prefix]

    Team.import(:force=>true, index: prefix+'teams')
    User.import(:force=>true, index: prefix+'users')

    Cluster.__elasticsearch__.create_index! force: true
    Cluster.import(:force=>true, index: prefix+'clusters')
    Cluster.__elasticsearch__.refresh_index!

    render json: {:ok=>1}
  end

  def es_reindex

    User.__elasticsearch__.refresh_index!
    Team.__elasticsearch__.refresh_index!
    Cluster.__elasticsearch__.refresh_index!

    render json: {:ok=>1}
  end

  def js
    render layout: false
  end



  def property
    obj = Option.new
    #v = obj.myget

    v = Option.get('opt1')
    x=0

  end


  def user_form
    @user = User.new

  end


  def cluster_access
    format = 'json'
    @username = 'ta10'
    pwd = 'PH_GEX_PASSWD1'
    @hostname = 'hadoop-master-10020'

    res_auth = Gexcore::AuthService.auth(@username, pwd)
    @token = res_auth.data[:token]



    #
    data = {access: "0"}

    begin
      # parse jwt token
      res_validate = Gexcore::AuthService.validate_token @token

      raise 'Invalid token' if res_validate.error?

      token_data = res_validate.data
      if token_data[:username]!=@username
        raise 'Username and token mismatch'
      end


      # get cluster from hostname
      res_parse_cluster = Gexcore::ClusterServices::Service.parse_master_hostname(@hostname)
      if res_parse_cluster
        @cluster = Cluster.get_by_id(res_parse_cluster[1].to_i)
      elsif res_parse_node = Gexcore::ClusterServices::Service.parse_node_hostname(@hostname)
        node = Node.get_by_name(res_parse_node[1])
        raise 'Node not found' if node.nil?
        @cluster = node.cluster
      end

      raise 'Cluster not found' if @cluster.nil?


      #
      @user = User.get_by_username @username


      res_access = Gexcore::ClustersAccessService.has_access?(@user, @cluster)

      if res_access
        data[:access] = "1"
        data[:username] = @username
        data[:teamName] = @user.team.name
      end

    rescue => e
      gex_logger.exception("Exception in auth_access_cluster", e)
    end


    #
    if format=='json'
      return_json_data(data)
    elsif format=='string'
      s_res = ""
      if data[:access]=="1"
        s_res = "#{data[:teamName]}"
      else
        s_res = ""
      end

      render plain: s_res
    end

  rescue


  end

  ### cookies
  def setcookie
    domain = 'localhost' if Rails.env.development?
    domain = 'api.gex' if Rails.env.main?

    cookies[:myname] = {
        value: 'a yummy cookie '+Time.now.utc.to_s,
        expires: 1.year.from_now,
        domain: domain
    }


    #token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InN1NyIsInVzZXJfaWQiOjM4LCJleHAiOjE0NTMwNDE2Nzd9.ypLa3aXlkXyri66i2Ts39grAg071hLJKsLpOqzuAwsI;
    # Expires=Thu, 21-Jan-2016 15:50:54 GMT; Path=/; Domain=.webproxy.local; HttpOnly

    render json: {ok: 'ok'}
  end

  def cookie

    data = cookies[:myname]
    token = cookies[:token]



    render json: {data: data, token: token}
  end

  def mydebug
    x = Rails.configuration.SITE_NAME
    y=0
  end


  def exception
    raise 'Hey buddy'

  end

  def notfound
    raise ActionController::RoutingError.new('Not Found 2')
  end

  def hello
    render json: {hello: 'me'}
  end

  def log_add
    gex_logger.debug 'debug_debug', "api log #{Time.now.utc}", {data: 'mydata'}
    gex_logger.debug 'debug1', "api log #{Time.now.utc}", {data: 'mydata'}

    return_json_data({res: 'ok'})
  end

  def log_view
    p = { limit: "21", skip: "20",
        dateTo: "2016-02-22+21:59:59",
        dateFrom:"2016-01-21+22:00:00"}

    user = User.get_by_username 'su7'
    rows = Gexcore::LogService.search_by_user(user, p, session)

    x = 0

  end

  def set_passwords
    rows = User.all

    rows.each do |u|
      u.password = 'PH_GEX_PASSWD1'
      u.password_confirmation = 'PH_GEX_PASSWD1'
      u.skip_confirmation!
      u.save
    end
  end




  def login
    username = 'm3'
    email = 'm1@gex.io'
    pwd = 'PH_GEX_PASSWD1'
    #pwd = 'PH_GEX_PASSWD1aa'

    # work
    res = Gexcore::AuthService.auth(username, pwd)

    return_json res
  end


  def session2
    # auth
    username = 'testmmx3'
    pwd = 'PH_GEX_PASSWD1'

    res = Apiservice::AuthService.auth(username, pwd)

    token = res.data[:tokenId]


    #
    u = 'json/sessions/'

    #
    q = Apiservice::OpenamRequest.new

    body = {
        #'_action' => 'getMaxTime',
        #'tokenId' => token,
    }

    action = 'getMaxTime'
    #action = 'getIdle'
    #action = 'isActive'
    u = u + "?_action=#{action}&tokenId=#{token}"


    headers ||= {}
    headers['iplanetDirectoryPro'] = token
    headers['Content-Type'] = "application/json"

    #res = Apiservice::OpenamRequest.process_request(:post, u, body, headers)
    res = q.process_request_by_admin(:post, u, body, headers)


    return_json res
  end

  def session3
    u = User.find(442)
    sign_in(:user, u)

    redirect_to '/profile/edit'
  end


  def users
    @users = User.all

    "found #{@users.count} users"
  end

  def email_redis
    uid = "#{Time.now.utc.to_f*1000*to_i.to_s}_#{Gexcore::Common.random_string_digits(2)}"

    x=0
  end


  def create_user
    gex_logger.debug_msg "create user"

    # new
    #email = 'u'+Gexcore::Common.random_string_digits(3)+'@gmail.com'
    #email = 'u2@gmail.com'
    #pwd = 'pwd'+Apiservice::ApiCommon.random_string(8)
    r = Gexcore::Common.random_string_digits(3)
    data = {teamname: 't3012'+r, username: 'u3012'+r, email: 'm3012'+r+'@gex.io', password: 'PH_GEX_PASSWD1',
            firstname: "fifi-"+r, lastname: "last{r}"}

    data2 = {teamname: 'mmxteam', username: 'mmx', email: 'mmx@gex.io', password: 'PH_GEX_PASSWD1',
            firstname: "Max", lastname: "Bax"}

    user = Gexcore::UsersCreationService.build_user_from_params data
    user.password_confirmation = user.password

    res = Gexcore::UsersCreationService.create_user_not_verified(user)

    gex_logger.log_response(res, 'user_created', "User was created. Username: :username", 'user_create_error')


    return_json(res)
  end

  def invite
    user = User.get_by_username('mmx')

    email = 'v2@gex.io'

    res = Gexcore::InvitationsService.send_invitation(user.team_id, email, user)

    return_json(res)
  end

  def verify

    username = 'testmmx3'
    user = User.get_by_username username

    token = user.verification_token
    res = Apiservice::UsersCreationLib.verify_user(token)

    return_json(res)
  end

  def create_cluster
    r = Gexcore::Common.random_string_digits(3)
    data = {teamname: 'team'+r, username: 'g'+r, email: 'g'+r+'@gex.io', password: 'PH_GEX_PASSWD1',
            firstname: "fifi-"+r, lastname: "last{r}"}

    user = Gexcore::UsersCreationService.build_user_from_params data
    user.password_confirmation = user.password

    res = Gexcore::UsersCreationService.create_user_not_verified(user)
    token = res.sysdata[:token]

    # verify user
    Gexcore::UsersCreationService.verify_user(token)


    return_json_ok

  end


  def user_get
    #
    email = 'u2222@gmail.com'
    #email = 'myuser_uniy@gmail.com'
    #email = 'u132@gmail.com'
    res = Apiservice::Service.get_user(email)

    return_json(res)
  end

  def user_del
    email = 'u1@gmail.com'

    # del
    res = Apiservice::Service.del_user(email)

    return_json(res)
  end




  def email
    user = User.get_by_username 'mmx'

    #
    UsersMailer.welcome_email(user.email).deliver_later

    render json: {ok: 'ok'}
  end

  def validate_token
    # login
    username = "demo@gmail.com"
    pwd = "PH_GEX_PASSWD1"

    res_auth = Apiservice::Service.auth(username, pwd)



    # validate
    token = res_auth.data[:tokenId]
    #token = params['token']
    #token = ''
    res = Apiservice::Service.validate_token(token)

    return_json(res)
  end

  def permissions
    user = User.first
    cluster = Cluster.first

    if user.can? :manager, cluster
      raise 'BAD permissions'
    end
  end

  def permissions2
    user = User.get_by_email 'demo@gmail.com'    #$logger.error "create user"


    cluster = Apiservice::UsersService.get_main_cluster(user)

    cluster2 = Cluster.find(1)

    #
    perm = user.can? :manage, cluster
    perm2 = user.can? :manage, cluster2

    "perm = #{perm}, perm in another cluster: #{perm2}"
  end


  def files
    lib = Gexcore::FilesService

    node = Node.find(655)
    files = lib.list_node_install(node)

    #
    return_json_data files
  end

  def file_download
    # file
    filename = params[:filename]
    #filename = 'Vagrantfile'
    filename ||= 'node/provision.rb'

    cluster_id = 385

    # input
    p = {}
    #p[:application_uid] = params[:applicationID]
    #p[:node_uid] = params[:nodeID]
    p[:node_uid] = '1703456224794474'

    #
    lib = Gexcore::FilesService

    # get file
    #user = current_user
    cluster = Cluster.get_by_id(cluster_id)


    #
    path = lib.file_fullpath(filename, cluster.id, p)


    x =0
    # download
    File.read(path)
  end

  def provision_create_node
    node = Node.find(651)

    res = Gexcore::Nodes::Provision.provision_master_create_node(node)
    #cmd = %Q(ansible-playbook -i /mount/ansible/inventory /mount/ansible/create_node.yml -e \"{\"_cluster_id\":486,\"_cluster_uid\":\"1704407357091745\",\"_cluster_name\":\"eager-leo\",\"_node_uid\":\"1704438505531776\",\"_node_id\":651,\"_node_number\":5,\"_node_type\":\"onprem\",\"_host_type\":\"virtualbox\",\"_hadoop_type\":\"cdh\",\"_hadoop_master_ipv4\":\"51.77.1.230\",\"_node_name\":\"black-altair\",\"_node_port\":1675,\"_node_ip6_address\":null,\"_interface\":\"ZW5wMnMw\",\"_is_wifi\":false,\"_proxy_ip\":null,\"_static_ips\":false,\"_gateway_ip\":null,\"_network_mask\":null,\"_container_ips\":{\"hadoop\":null,\"hue\":null}})
    #res1 = req.run(cmd)

    #res = {res1: res1}

    return_json(res)
    #return_json_data(res)
  end


  def rabbitmq_createuser
    node = Node.find(7)

    #
    res = Gexcore::Nodes::Control.rabbitmq_create_user_for_node(node)


  end

  def rabbitmq_connect
    # send command to node

    gex_logger.debug "", "DEBUG - bunny connect"

    node = Node.find(303)

    config = Gexcore::Settings

    conn = Bunny.new(:host => config.rabbit_url_private,
                     :port=>5672, :vhost=>'/',
                     :user => config.rabbit_root_username, :password => config.rabbit_root_password,
                     :continuation_timeout => 30000,
                     :heartbeat => 30,
                     :automatically_recover => true,
                     :network_recovery_interval => 3,
                     :recover_from_connection_close => true,
    )
    conn.start

    ch = conn.create_channel

    # exchange
    exchange = ch.topic(rabbit_exchange_nodes(node))

    gex_logger.debug "", "bunny connected"

  end

  def rabbitmq_queue_add
    require "bunny"


    # user
    node_id = 22

    #
    conn = Bunny.new(:hostname => "rabbit.local", :user => "admin", :password => "PH_GEX_PASSWD1")
    #conn = Bunny.new(:hostname => "rabbit.local", :user => "node#{node_id}", :password => "PH_GEX_PASSWD1")
    conn.start

    ch   = conn.create_channel

    # debug
    #q    = ch.queue("debug")
    #ch.default_exchange.publish("Hello World!", :routing_key => q.name)

    # topic
    exchange = ch.topic("gex.nodes.#{node_id}.exchange")

    # direct
    #exchange    = ch.direct("gex.nodes")

    #
    #exchange.publish("for node 1", :routing_key => 'node1')
    #exchange.publish("for node 2", :routing_key => 'node2')
    #exchange.publish("for node 3", :routing_key => 'node3')
    #exchange.publish("for node 3 second", :routing_key => 'node3')


    # queue
    key = "gex.nodes.#{node_id}.commands"
    q1 = ch.queue("gex.nodes.#{node_id}.commands").bind(exchange, :routing_key => key)
    #, :auto_delete => true

    # push
    cmd = {command: 'restart'}
    exchange.publish(cmd.to_json, :routing_key => key)


    conn.close

    "SENT"
  end

  def rabbitmq_queue_subscribe
    require "bunny"

    #
    node_id=22

    #
    #conn = Bunny.new(:hostname => "devrabbit.local", :user => "admin", :password => "PH_GEX_PASSWD1")
    conn = Bunny.new(:hostname => "rabbit.local", :user => "node#{node_id}", :password => "PH_GEX_PASSWD1")
    conn.start

    ch   = conn.create_channel

    #
    exchange = ch.topic("gex.nodes.#{node_id}.exchange")

    # subscribe
    key = "gex.nodes.#{node_id}.commands"
    q1 = ch.queue("gex.nodes.#{node_id}.commands").bind(exchange, :routing_key => key)
    # , :auto_delete => true

    # get messages
    puts "read commands"

    while 1==1 do
      q1.subscribe do |delivery_info, metadata, body|
        puts "COMMAND for node #1: #{body}, routing key is #{delivery_info.routing_key}"
      end

      break
    end

    #ch.queue("nodes").bind(exchange, :routing_key => "node.2").subscribe do |delivery_info, metadata, payload|
    #  puts "msg for node #2: #{payload}, routing key is #{delivery_info.routing_key}"
    #end

    "OK"
  end



  def user_info
    # username
    username = 'testmmx'

    # work
    res = Gexcore::UsersService.get_user_info(username)


    return_json(res)
  end

  def sendinvitation
    # auth
    username = 'testmmx@galacticexchange.io'
    pwd = 'PH_GEX_PASSWD1'

    user = User.get_by_email username

    #
    to_email = 'v8@galacticexchange.io'
    res = Apiservice::InvitationService.send_invitation(user.team_id, to_email, user)

    return_json res
  end

  def messages_send
    # work
    @user = User.find(15)
    to_user = User.find(14)

    msg = 'hello 14: '+Time.now.utc.to_s

    res = Apiservice::MessagesService.add_message(@user.id, to_user.id, msg)

  end


  def messages
    # work
    @user = User.find(14)

    rows = Apiservice::MessagesService.get_list({username: @user.username})

    # set messages read
    Apiservice::MessagesService.set_all_messages_read @user.id

    #
    return_json_data rows
  end

  def messages_unread_count
    # work
    @user = User.find(14)

    n = Apiservice::MessagesService.get_unread_count_user(@user.id)

    data = {n: n}

    return_json_data data
  end


  def nodes_list
    @username = 'testmmx'

    #
    user = User.get_by_username(@username)
    @cluster_id = user.main_cluster_id


    # create node
    res = Apiservice::Nodes::Service.list_nodes_with_state(@cluster_id)

    return_json(res)
  end


  def create_log
    #
    username = 'testmmx'
    user = User.get_by_username username

    # work
    #params['username'] = 'testmmx'
    #params['minLevel'] = 'debug'
    #params['dateFrom'] = Apiservice::ApiCommon.date_format(Time.now.utc - 1.day)
    #params['dateTo'] = Apiservice::ApiCommon.date_format(Time.now.utc - 1.day)


    #
    res = Apiservice::LogService.search_by_user(user, params, session)

    return_json(res)
  end

  def search_teams
    # input
    q = params['q'] || ''

    if q.nil? || q.blank?
      res = Gexcore::Response.res_error_badinput('', 'No input')
      return return_json(res)
    end

    # work
    res = Gexcore::TeamsSearchService.search(params, session)

    return_json(res)
  end

  def search_users
    # input
    q = params['q'] || ''

    if q.nil? || q.blank?
      res = Gexcore::Response.res_error_badinput('', 'No input')
      return return_json(res)
    end

    # work
    res = Gexcore::UsersSearchService.search(params, session)

    return_json(res)
  end

  def search_clusters
    # debug - delete cluster
    cluster = Cluster.find(2)
    #cluster.delete!
    #cluster.activate!

    #Cluster.es_reindex

    # input
    q = params['q'] || ''

    if q.nil? || q.blank?
      res = Gexcore::Response.res_error_badinput('', 'No input')
      return return_json(res)
    end

    # work
    res = Gexcore::ClustersSearchService.search(params, session)

    return_json(res)
  end


  def add_event
    now = Time.now.utc
    res = Gexcore::Response.res_error("debug_cluster_install_error", "Error installing cluster", "", 500, {user_id: 1, cluster_id: 12, t: now})
    Gexcore::SensuEventsService.send_message_from_response(res)

    return_json_ok
  end


  def read_events
    conn = Bunny.new(:hostname => "devrabbit.local", :user => "sensu", :password => "PH_GEX_PASSWD1", :vhost=>'/sensu',
                     :continuation_timeout => 15000,
                     #:heartbeat => 30,
                     :automatically_recover => true,
                     :network_recovery_interval => 3,
                     :recover_from_connection_close => false,
    )
    conn.start

    #
    ch = conn.create_channel

    # exchange
    x = ch.topic('gex.api_events')
    q = ch.queue('gex.api_events', :auto_delete => false, :exclusive => false, :durable=>false)
    q.bind(x, :routing_key => '#')
    #ch.queue_declare(queue='gex.api_events')


    #
    msg = nil
    messages = []
    res = false

    #
    begin
      Timeout.timeout 10 do
        begin
          ret = q.subscribe(:block => true, :timeout=>10) do |delivery_info, metadata, body|
            msg = JSON.parse(body)

            # check msg
            if msg['type']

              # skip
            end

            messages << msg

            #
            #cancel_ok = consumer.cancel
            #ch.consumers[delivery_info.consumer_tag].cancel

          end  # / subscribe

          #q.unsubscribe
        rescue => e
          res = false
        end

      end # / timeout

    rescue Timeout::Error
      res = false

    rescue => e
      res = false

    end

    begin
      #
      #q.unsubscribe
      ch.close
      conn.close
    rescue => e
      x = 0
    end


    #
    resp = []

    if messages.empty?
      # do nothing
      resp = []
    else
      #raise "msg OK - #{msg}"
      #s_data = messages.map{|r| r.to_json}.join(",")
      resp = messages
      #raise "msg OK - #{s_data}"
    end

    return_json_data resp
  end



  def node_delete
    # delete rabbitmq user
    node = Node.first

    res = Gexcore::Nodes::Control.rabbitmq_delete_all_for_node(node)

  end

  def node_status

    @username = 'mmx'

    #
    user = User.get_by_username(@username)
    @cluster = user.home_cluster


    # create node
    #res = Gexcore::NodesService.create_node(@cluster, {})
    #@node = Node.get_by_uid res.data[:nodeID]

    #
    @node = Node.last


    x = @node.status

    d1 = @node.updated_at

    y=0

    @node.begin_uninstall!

    d2 = @node.updated_at

    y=0




  end


  def index_users
    #
    filter_options = {}

    filter = SimpleSearchFilter::Filter.new(session, 'debug_users_', filter_options)

    # define filter
    filter.set_default_order 'id', 'desc'
    #filter.field :category_id, :int, :text, {default_value: 0, condition: :equal}
    #filter.field :enabled, :int, :checkbox, {default_value: 1, ignore_value: -1, condition: :equal}

    @filter = filter


    #
    @pg = params[:pg] || 1
    @filter.page = @pg

    #
    @items = User.by_filter(@filter)

  end


  def tags
    s = "<b>aaa</b>"

    x = ActionView::Base.full_sanitizer.sanitize(s)

    y=0
  end

  def long
    sleep 180


    return_json_data({:ok=>'ok'})
  end

  def cols

  end

  def chef

    cmd_knife = 'chef exec knife zero bootstrap 51.77.39.123 --node-name master-10107  --overwrite --ssh-user root --ssh-password vagrant '
    #cmd_knife = 'BUNDLE_GEMFILE=Gemfile-empty bundle exec chef exec knife zero bootstrap 51.77.39.123 --node-name master-10107  --overwrite --ssh-user root --ssh-password vagrant '
    cmd_knife = 'BUNDLE_GEMFILE=Gemfile-empty bundle exec chef exec ruby -v '
    output = `bash -c '#{cmd_knife}' 2>&1 `

    return return_json_data({data: output})
    raise '1'

    #cmd = %Q(bash -c 'chef exec knife zero bootstrap 51.77.39.117 --node-name master-10101  --overwrite --ssh-user root --ssh-password vagrant' 2>&1 )
    #cmd = %Q(bash -c 'ruby -v' 2>&1 )

    cmd = %Q(chef exec knife zero bootstrap 51.77.39.117 --node-name master-10101  --overwrite --ssh-user root --ssh-password vagrant  )
    #output = %x[/bin/bash -c "#{cmd}"]
    #cmd = "ruby -v"
    # /bin/bash -c
    #output = %x[eval "$(chef shell-init bash)"; #{cmd} 2>&1"]

    #cmd = 'ruby -v'
    cmd = "chef exec ruby -v"
    #  output =`bash -c "eval \"\$(chef shell-init bash)\"; #{cmd} 2>&1" `
    #output = `pwd; whoami; which ruby; cd /tmp && #{cmd} 2>&1`
    #output = `which ruby; cd /tmp; pwd; #{cmd} 2>&1`
    #output = `cd /tmp; pwd; bash -c "#{cmd} 2>&1" `
    #output = `#{cmd} `

    #cmd = 'cd /tmp; /bin/bash -lc "cd /tmp; pwd; chef exec ruby -v 2>&1 " > /tmp/debug.txt'
    #cmd = 'cd /tmp; /bin/bash -lc "cd /tmp; rvm use 2.1.8; chef exec ruby -v 2>&1  " > /tmp/debug.txt'
    #cmd = 'cd /tmp; /bin/bash -lc "cd /tmp; rvm use 2.1.8; knife zero bootstrap 2>&1  " > /tmp/debug.txt'
    #cmd = 'cd /tmp; /bin/bash -lc "cd /tmp;  sh myexec.sh 2>&1 " > /tmp/debug.txt'
    #cmd = %Q(cd /tmp; /bin/bash -lc "[[ $- == *i* ]] && echo 'Interactive' || echo 'Not interactive'; cd /tmp;  chef exec gem list 2>&1 " > /tmp/debug.txt)

    #cmd = %Q([[ $- == *i* ]] && echo 'Interactive' > /tmp/debug.txt || echo 'Not interactive' > /tmp/debug.txt)
    #cmd = %Q(/bin/bash -lc "shopt -q login_shell && echo 'Login shell' > /tmp/debug.txt  || echo 'Not login shell' > /tmp/debug.txt ")

    #
    #cmd = 'cd /tmp; /bin/bash -lc "cd /tmp; ruby -v 2>&1; knife zero bootstrap 2>&1;  " > /tmp/debug.txt'
    cmd = 'cd /tmp; /bin/bash -lc "cd /tmp; ruby -v 2>&1; chef exec ruby -v 2>&1;  " > /tmp/debug.txt'


    pid = Process.fork do
      logger.debug "child, pid #{Process.pid} "
      #sleep 5

      exec(cmd)
      #system(cmd)


      logger.debug "child exiting"
    end

    logger.debug "parent, pid #{Process.pid}, waiting on child pid #{pid}"
    Process.waitpid(pid)
    logger.debug "parent exiting"

    #output = File.read('/tmp/debug.txt')


    # sshkit
    require 'sshkit'
    require 'sshkit/dsl'

    ssh_user ='mmx'
    srv = 'mmx@localhost'
    all_servers = [srv]

    output = ''

    #cmd = 'cd /tmp; /bin/bash -lc "cd /tmp; ruby -v 2>&1; chef exec ruby -v 2>&1;  " > /tmp/debug.txt'
    #cmd = 'cd /tmp; /bin/bash -lc "cd /tmp; ruby -v 2>&1;  " > /tmp/debug.txt'

    dir_chef = Gexcore::Settings.config.chef_dir
    #cmd = %Q(cd /tmp; /bin/bash -lc "cd /tmp; ruby -v 2>&1; chef exec ruby -v 2>&1; cd #{dir_chef} && #{cmd_knife}" )
    cmd = %Q(/bin/bash -lc "cd #{dir_chef} && #{cmd_knife}" )

    #Gexcore::ProvisionService.sshkit_run_locally
    #on all_servers do |srv|
    Gexcore::ProvisionService.sshkit_on all_servers do |srv|
      as(user: ssh_user) do
        #execute(cmd)
        output = capture(cmd)
      end
    end

    return_json_data({output: output})
  end

  def chef2
    base_dir = '/var/www/chef/config-knife/master_node'
    cmd_bootstrap = %Q(cd /var/www/chef/config-knife/master_node && chef exec knife zero bootstrap 51.77.39.139 --yes --verbose --host-key-verify   --node-name master-10123 --overwrite --ssh-user root --ssh-password vagrant 2>&1)

    local_ssh_user = 'uadmin'

    srv = "#{local_ssh_user}@localhost"

    #srv = 'root@51.77.39.139'
    all_servers = [srv]

    gex_logger.debug "debug_provision_chef", "chef provision server", {srv: srv}


    #output = `ssh uadmin@localhost 'whoami' `
    output = `ssh uadmin@localhost '#{cmd_bootstrap}' `


    gex_logger.debug "debug_provision_chef", "out provision server", {output: output}

    return_json_data({output: output}) and return


    a_output = []
    begin
      Gexcore::ProvisionService.sshkit_on all_servers do |s|
        #as(user: local_ssh_user) do
        #execute(cmd)
        #a_output << capture('whoami')
        a_output << capture(cmd_bootstrap)
        #end
      end

    rescue => e
      exception = e
      exit_code = 1

      gex_logger.error "app_install_error", "Cannot provision master node", {exception: e.message}
      gex_logger.exception "chef provision error", e

      return_json_data({exit_code: exit_code}) and return
    end

    res_output = a_output.join("; ")
    gex_logger.debug "debug_provision_chef", "chef provision output", {output: res_output}


    exit_code=0

    return_json_data({exit_code: exit_code})
  end



  def sms
    phone = '380505336999'
    #phone = '380980921316'
    phone = '+380665310992'

    begin
      sns = Aws::SNS::Client.new(
          region: 'us-west-2',
          access_key_id: Rails.application.secrets.aws_access_key_id,
          secret_access_key: Rails.application.secrets.aws_secret_access_key
      )

      res = sns.publish(phone_number: phone,
                  message: "Welcome to Galactic Exchange! "
      )

      y=0


    rescue Exception => e
      gex_logger.exception("Cannot send SMS", e, {username: user.username})

      return false
    end


    return_json_data({ok: 1})
  end


  def ini
    text= %Q(
v=1.0.3
q=1231asdafas
[sec1]
qq=2
    )

    doc = IniParse.parse( text )

    v = doc['__anonymous__']['v']

    data = {v: v, q2: doc['sec1']['qq']}
    return_json_data(data)
  end

  def maintenance

  end


  # for kafka test
  def log_to_kafka
    #

    #
    require 'csv'
    require 'json'
    require "kafka"

    # input
    msg_type = params[:msg_type] || "no message"
    delay = (params[:delay] || 3).to_i

    # sleep
    #sleep delay

    #
    kafka_topic = Gexcore::Settings.log_kafka_topic

    #
    dnow = Time.now
    n = rand(10000)
    #
    v = {
        type_name: msg_type,
        created_at: dnow,
        data: {n: n}
    }

    # post to kafka
    kafka = Kafka.new(
        seed_brokers: ["#{Gexcore::Settings.log_kafka_server_url}"],
        #client_id: "jul_id"
    )
    # asynchronous sent??? - nop
    kafka.deliver_message("#{v.to_json}", topic: kafka_topic)


    res = {res: 1}
    return_json_data(res)
  end


  def get_from_kafka
    render layout: false
    #
    require 'csv'
    require 'json'
    require "kafka"
    require 'timeout'

    #
    kafka_topic = Gexcore::Settings.log_kafka_topic

    # get from kafka
    kafka = Kafka.new(
        seed_brokers: ["#{Gexcore::Settings.log_kafka_server_url}"],
    )
    consumer = kafka.consumer(group_id: "my-consumer")
    #
    consumer.subscribe(kafka_topic, start_from_beginning: true)
    #
    msg_type = params[:msg_type] || "some_txt"

    time_in_seconds = params[:time_in_seconds] || 5


    ret_msg = ""

    begin
      timeout time_in_seconds.to_i do
        consumer.each_message do |message|
          if JSON.parse(message.value)["type"] == msg
            ret_msg << message.value
            break
          end
        end
      end
    rescue Timeout::Error
      ret_msg = "kafka -- timed out"
    end

    #
    ret_msg
  end

  def get_kafka2
    kafka = Kafka.new(
        seed_brokers: ["#{Gexcore::Settings.log_kafka_server_url}"],
    )


    kafka_topic = Gexcore::Settings.log_kafka_topic

    ofs = 0

    # find first message
    begin
      Timeout.timeout 10 do
        kafka.each_message(topic: kafka_topic, start_from_beginning: true, max_wait_time: 3.0) do |message|
          ofs = message.offset
          break
        end
      end
    rescue Timeout::Error
      ofs = 0
    end

    res = {offset: ofs}
    return_json_data(res)
  end

  def task_async
    LongWorker.perform_async


    res = {res: 1}
    return_json_data(res)
  end


  def log_build

    node = Node.find(246)

    type_name = "debug_node_status_change_error"
    msg = "Node debug"
    data = {
        node_id: node.id,
        node_uid: node.uid,
        from: 'running',
        to: 'done',
        #event: node.aasm.current_event}
    }

    #
    version = '1.0'
    source = 'server'
    level = 'debug'

    row = Gexcore::GexLogger.build_log_hash(version, source, level,
                                            msg, type_name, data)


    x=0
  end

  def elastic_add_log_type_from_log_debug

    log_type_name = "test_shmest"

    log_type_hash = {name: "#{log_type_name}", title: "#{log_type_name}", description: nil, enabled: true, visible_client: true, need_notify: false}
    # check log_type if exist in elastic
    hash_obj = Gexcore::LogFromElasticsearch.log_type_search_by_id_or_name(nil, log_type_name)
    unless hash_obj
      Gexcore::LogTypeSearchService.create_or_update_log_type_in_elasticsearch(nil, log_type_hash)
    end

    hash_obj_2 = Gexcore::LogFromElasticsearch.log_type_search_by_id_or_name(nil, log_type_name)
    return log_type_hash == hash_obj_2.except('_id', 'id')

  end

  def es_update
    client = Elasticsearch::Model.client

    # remove deleted rows
    index_name = "#{Rails.configuration.gex_config[:elasticsearch_prefix]}log_debug"


    last_id = 100
    n_deleted = 0

    1.upto last_id do |ind|
      begin
        client.delete index: index_name, type: 'log_debug',id: ind
        n_deleted = n_deleted+1
      rescue =>e
      end

    end



    res = {res: 1, n: n_deleted}
    return_json_data(res)
  end

  def node_jobs_state
    node = Node.first

    node.start_job_task('job1', 'task1')

    #node.reload

    x = node.jobs_state

    y = 0
  end

  def provision_create_cluster
    cluster = Cluster.get_by_id(496)

    app = cluster.hadoop_app
    res = Gexcore::ProvisionService.provision_master_create_cluster(app)

    res = {res: 1}
    return_json_data(res)
  end

  def provision_ssh
    s_cmd = "ls -la"
    cmd_ssh  = %Q(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gex@51.1.0.50 -t "bash -lc '#{s_cmd}' 2>&1")

    res_output = %x[#{cmd_ssh}]
    exit_code = $?.exitstatus

    x =0

  end


  def app_name
    s = 'adminer'
    base_app_name = s.gsub /-/, '_'
    base_app_name.gsub! /[^a-z\d_]+/, ''


    x = base_app_name

    y=0

  end


  def app_version
    app = 'zoomdata'
    res = Gexcore::Applications::Service.app_current_version(app)

    x=0
  end

  def app_version2
    url = 'http://applications.galacticexchange.io/zoomdata-version.txt'

    x = ''
    open(url){|f| x=f.meta  }

    headers = {}
    #headers["If-Modified-Since"] = last_modified if last_modified
    headers["If-None-Match"] = ''

    contents = open(url, headers).read

    gex_logger.debug("debug_app_version", "meta: #{x}")
    gex_logger.debug("debug_app_version", "contents: #{contents}")


    return_json_data({data: contents})
  end

  def rabbit_user
    node = Node.find(14)
    Gexcore::Nodes::Control.rabbitmq_create_user_for_node(node)

    return_json_data({x: 1})
  end



  def dashboard
    user = User.find(505)
    name = "d1"

    cluster = user.team.clusters[0]

    d = Gexcore::Dashboards::Service.load_dashboard(cluster, name)


    return_json_data({x: 1, d:d})
  end


  def closed_page
    if !current_user
      #redirect_to new_session_path(:user, :url_from=>'http://localhost:3000/debug/closed_page') and return
      redirect_to new_user_session_url(:from_url=>'http://localhost:3000/debug/closed_page') and return
    end
  end


  def provision1
    cluster = Cluster.find(405)
    application_id = cluster.hadoop_app.id

    res_provision = Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(application_id)

    if res_provision.error?
      raise res_provision
    else
      raise 'ok'
    end

    x =0

  end


  def app_provision

    cmd = [
'source /etc/profile.d/rvm.sh',
    'cd /mount/chef-repo/config-knife/master_node',
'chef exec knife zero bootstrap 51.77.1.196 --node-name master-452 --overwrite --ssh-user root --ssh-password vagrant',
'chef exec knife zero converge "name:master-452" --json-attributes /mount/ansibledata/452/applications/891/config.json  --ssh-user root --ssh-password vagrant  --override-runlist rocana::master --ssh-user root --ssh-password vagrant'
    ]
    res_provision = Gexcore::Provision::Service.run("app_install_master_app", cmd)


  end

  def app_provision2

    app_id = 891
    cluster_id = 452

    script = Gexcore::Provision::Service.build_cmd_cap(
        'provision:app_install_master',
        "_cluster_id=#{cluster_id} _app_id=#{app_id} "
    )
    res_provision = Gexcore::Provision::Service.run('app_install_master', script)


    x=0
  end


  def provision_job
    node_id = 940
    node = Node.get_by_id(node_id)


    # push job
    Sidekiq::Client.push('queue' => 'provision', 'retry' => 20,
                         'class' => 'ProvisionCreateNodeWorker',
                         'args' => [node.cluster_id, node_id]
    )

    #Sidekiq::Client.push('queue' => 'provision', 'retry' => 2, 'class' => 'Example::Workers::Trace', 'args' => ['hello!'])

  end


  def node_info_2
    node = Node.find(1013)

    # es service
    container_hadoop = node.containers.where(basename: 'hadoop').first
    service_es = container_hadoop.services.where(name: 'elastic').first

    x=0

  end


  def provision_long
    # run long provision
=begin
    script = Gexcore::Provision::Service.build_cmd_cap(
        'test:long',
        "_cluster_id=0 "
    )

    res_provision = Gexcore::Provision::Service.run('test_long', script)

    return_json(res_provision)
=end

    LongWorker.perform_async

  end

  def consul_node
    node = Node.find(1031)

    container_hadoop_master = node.cluster.get_master_container('hadoop')
    hadoop_master_ipv4 = container_hadoop_master.gex_ip

    Gexcore::Nodes::Service.consul_update_node_data(node)

    x=0
  end



  def consul_container
    container = ClusterContainer.find(3310)

    x = container.gex_ip

    y = Gexcore::Containers::Service.get_private_ip_of_container(container)

    data = {gex_ip: x}

    return_json_data data
  end


  def consul_lock
    lock_names = %w(openvpn provisioner provisioner_first master proxy webproxy)

    cluster_id = 468
    res = {}
    lock_names.each do |name|
      #['master'].each do |name|
      res[name] = Gexcore::Consul::Utils.consul_get_val(cluster_id, "/lock/#{name}", "0")
    end

    return_json_data({res: res})
  end




  def mon_node
    user = User.get_by_username('su1')
    node = Node.find(1139)

    #
    res = {}

    data = Gexcore::Monitoring::NodesMonitoring.get_checks_for_node(node)
    res['data'] = data


    return_json_data res
  end

  def mon_metrics_node
    user = User.get_by_username('su1')
    node = Node.find(1139)

    #
    res = {}

    data = Gexcore::Monitoring::NodesMonitoring.get_all_metrics_for_node(node)
    res['data'] = data


    return_json_data res
  end

  def mon_container
    user = User.get_by_username('kennedi-abernathy')

    node = Node.find(1208)

    container_ids = [4023, 4022]
    container_uids = []
    container_ids.each do |id|
      c = ClusterContainer.find(id)
      container_uids << c.uid
    end

    #
    res = {}

    data_all = Gexcore::Monitoring::ContainersMonitoring.get_for_containers_by_user(user, container_uids)
    res['data_all'] = data_all


    #container = ClusterContainer.find(3795)
    #data = Gexcore::Monitoring::ContainersMonitoring.get_for_container(container)
    #res['data'] = data



    return_json_data res
  end


  def mon_service
    user = User.get_by_username('su1')

    node = Node.find(1107)

    service_ids = [9870, 9871]

    #
    res = {}

    res['data_all'] = Gexcore::Monitoring::ServicesMonitoring.get_for_services_by_user(user, service_ids)

    # es
    #service = ClusterService.find(8658)
    # kibana
    #service = ClusterService.find(8657)

    #service = node.services.where(name: "hue").first

    #data = Gexcore::Monitoring::ServicesMonitoring.get_for_service(service)
    #res['data'] = data



    return_json_data res
  end

  def mon_service_app
    user = User.get_by_username('su1')

    node = Node.find(1107)


    service_id = 9893

    service = ClusterService.find(service_id)

    service_ids = [service_id]

    #
    res = {}

    data = Gexcore::Monitoring::ServicesMonitoring.get_for_service(service)
    res['data'] = data



    return_json_data res
  end


  def node_kafka_history

    counter_name = 'memory'
    counter_info = Gexcore::Monitoring::NodesMonitoring::COUNTERS[counter_name.to_sym]
    topic = 'gex.1715202361264395.checks.metrics_memory'

    redis_key = Gexcore::Monitoring::MetricsHistory::Service.redis_key_offsets(topic)

    tnow = Time.now.utc.to_i

    # debug
    #a_last = $redis.zrange redis_key, -1, -1

    #v = Gexcore::Monitoring::MetricsHistory::Service.get_offset_for_time(topic, 1496392059-10)
    #puts "offset = #{v}"

    #raise 1


    # clean
    #Gexcore::Monitoring::MetricsHistory::Service.clean_offsets(topic)


    # first call
    d_from = (Time.now.utc - 2.hours)
    d_to = (Time.now.utc - 10.seconds)

    puts "from #{d_from} to #{d_to}"
    time_from = d_from.to_i
    time_to = d_to.to_i

    rows0_kafka = Gexcore::Monitoring::MetricsHistory::Service.get_messages_window(topic, time_from, time_to)

    # parse
    rows0 = Gexcore::Monitoring::MetricsHistory::Service.parse_kafka_messages_to_result(rows0_kafka, counter_name, counter_info)

    #
    #puts "rows#0: #{rows0}"
    puts "rows#0"
    print_metrics_results(rows0)


    puts "sleep 40"
    sleep 40

    #offsets = $redis.zrangebyscore redis_key, 0, tnow

    # call 1
    d_from = (Time.now.utc - 2.minutes)
    d_to = (Time.now.utc - 2.seconds)

    puts "call 2 - from #{d_from} to #{d_to}"
    time_from = d_from.to_i
    time_to = d_to.to_i

    rows1_kafka = Gexcore::Monitoring::MetricsHistory::Service.get_messages_window(topic, time_from, time_to)
    rows1 = Gexcore::Monitoring::MetricsHistory::Service.parse_kafka_messages_to_result(rows1_kafka, counter_name, counter_info)

    #puts "rows#1: #{rows1}"
    puts "rows#1"
    print_metrics_results(rows1)


    # call 3
    puts "sleep 50"
    sleep 50
    puts "done sleep 50"

    d_from = (Time.now.utc - 1.minutes)
    d_to = (Time.now.utc - 2.seconds)

    puts "call 3 - from #{d_from} to #{d_to}"
    time_from = d_from.to_i
    time_to = d_to.to_i

    rows2_kafka = Gexcore::Monitoring::MetricsHistory::Service.get_messages_window(topic, time_from, time_to)
    rows2 = Gexcore::Monitoring::MetricsHistory::Service.parse_kafka_messages_to_result(rows2_kafka, counter_name, counter_info)

    #puts "rows#2: #{rows2}"
    puts "rows#2"
    print_metrics_results(rows2)




    return_json_data({ok: 1})
  end

  def print_metrics_results(res_messages)
    puts "RESULTS:"
    res_messages.each do |res|
      puts "#{res.to_s}"
    end
  end

  def es_remove_log_type
    # remove duplicate
    id = 'AVw_mPx4wWB037T2RZrf'

    index_type = 'gex_models'
    type_type = 'LogType'.underscore.pluralize

    client = Elasticsearch::Client.new(
        trace: false,
        host: Gexcore::Settings.logs_elasticsearch_host,
        port: Gexcore::Settings.logs_elasticsearch_port)

    client.delete index: index_type, type: type_type, id: id

  end
end
