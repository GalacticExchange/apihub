module NodeFactoryHelpers
  def build_node_sysinfo
    sysinfo = JSON.parse(File.read('spec/data/node_body.txt'))
  end


  def build_instance_id
    require 'securerandom'
    SecureRandom.uuid
  end

  def build_node_options
    {
        'selected_interface' => {
            'name'=>'eth0',
            'isWifi'=>false
        }
    }
  end

  ### double node

  def double_node(fields={}, node_options=nil)
    cluster, app = double_cluster({}, node_options)

    node = double(
        Node,
        id: 55,
        cluster_id: 99,
        cluster: cluster,

        uid: 'aaaXXX1111',
        node_number: 2,
        name: 'luna',
        port: '4888',
        ip: '11.22.13.14',

        node_type_name: 'onprem',
        host_type_name: 'virtualbox',

        options_hash: node_options,

        agent_token: "xxx111"
    )

    allow(node).to receive_message_chain(:cluster, :get_master_container, :public_ip).and_return('66.77.88.99')

    # options

    # hadoop
    allow(node).to receive(:hadoop_app).and_return(cluster.hadoop_app)
    allow(node).to receive(:hadoop_app_id).and_return(cluster.hadoop_app_id)

    # containers
    allow(node).to receive(:containers).and_return([])


    node
  end


  def double_node_aws(fields={}, node_options=nil)
    cluster, app = double_cluster_aws({})

    node = double(
        Node,
        id: 55,
        cluster_id: 99,
        cluster: cluster,

        uid: 'aaaXXX1111',
        node_number: 2,
        name: 'luna',
        port: '4888',
        ip: '11.22.13.14',

        node_type_name: 'aws',
        host_type_name: 'dedicated',

        options_hash: node_options,

        agent_token: "xxx1111"
    )

    allow(node).to receive_message_chain(:cluster, :get_master_container, :public_ip).and_return('66.77.88.99')

    # options


    # containers
    allow(node).to receive(:containers).and_return([])

    # services
    services = []

    ind = 1
    Gexcore::AppHadoop::App::SERVICES_SLAVE.each do |service_name, opts|
      next unless ['ssh', 'http'].include? opts[:protocol]

      services << double(ClusterService, {
          name: service_name,
          protocol: opts[:protocol],
          port_out: 50000+ind,
          :"need_proxy?" => true
      })
      ind = ind+1
    end


    allow(node).to receive_message_chain(:services, :all).and_return(services)


    node
  end



  ### node

  def create_node(cluster, instance_id=nil,custom_name=nil, extra_fields={})
    instance_id ||= build_instance_id

    extra_fields ||= {}
    extra_fields[:custom_name] = custom_name

    node_sysinfo = build_node_sysinfo
    res = Gexcore::Nodes::Service.create_node(instance_id, cluster, node_sysinfo,extra_fields)
    node = Node.get_by_id res.data[:node_id]

    return nil if node.nil?

    #
    node.reload

    node
  end



  def create_node_status_installed(cluster)
    node = create_node(cluster)

    # installed on client
    stub_node_install_rabbitmq
    Gexcore::NotificationService.notify('node_installed', {node_id: node.id})

    node.reload

    node
  end



  def create_node_hadoop_active(cluster)
    extra_fields={hadoop_app: true}
    return create_node_status_active(cluster, extra_fields)
  end


  def create_node_active(cluster, extra_fields={})
    return create_node_status_active(cluster, extra_fields)
  end

  def create_node_status_active(cluster, extra_fields={})
    node = create_node(cluster, nil, nil, extra_fields)
    node.finish_install!

    # started
    node.begin_start!
    node.finish_start!

    #Gexcore::NotificationService.notify('node_started', {node_id: node.id})

    node.reload

    node
  end



  def create_node_status_install_error(cluster)
    #
    node = create_node(cluster)

    # install_error
    node.set_install_error!

    #
    node.reload
    node
  end

  def create_node_status_starting(cluster)
    node = create_node(cluster)

    #
    node.finish_install!

    #node.begin_start!
    #stub_node_install_rabbitmq
    #Gexcore::NotificationService.notify('node_installed', {node_id: node.id})

    #
    node.reload
    node
  end


  def create_node_status_start_error(cluster)
    #
    node = create_node_status_stopped(cluster)

    # starting
    Gexcore::Nodes::Control.start_node(node)
    node.reload

    # start_error
    #Gexcore::Nodes::Notification.notify_start_error(node)
    node.set_start_error!

    node.reload

    node
  end


  def create_node_status_stopping(cluster)
    #
    node = create_node_active(cluster)

    # stopped
    Gexcore::Nodes::Control.stop_node(node)

    #
    node.reload
    node
  end


  def create_node_status_stopped(cluster)
    #
    node = create_node_status_active(cluster)

    Gexcore::Nodes::Control.stop_node(node)
    node.reload

    #Gexcore::Nodes::Notification.notify_stopped(node)
    node.finish_stop!

    #
    node.reload

    node
  end

  def create_node_status_stop_error(cluster)
    #
    node = create_node_status_active(cluster)

    Gexcore::Nodes::Control.stop_node(node)
    node.reload

    #Gexcore::Nodes::Notification.notify_stop_error(node)
    node.set_stop_error!
    node.reload

    #
    node
  end



  def create_node_status_removed(cluster)
    #
    node = create_node_active(cluster)

    # remove
    Gexcore::Nodes::Service.remove_node(node)
    node.reload

    node
  end

  def create_node_status_remove_error(cluster)
    #
    node = create_node_active(cluster)

    # remove
    node.begin_remove!
    node.set_remove_error!

    node.reload

    node
  end



  def create_node_status_uninstalling(cluster)
    node = create_node(cluster)

    # start uninstall
    #Gexcore::NotificationService.notify('node_uninstalling', {node_id: node.id})
    node.begin_uninstall!
    node.reload

    node
  end



  def create_node_status_restarting(cluster)
    #
    node = create_node_active(cluster)

    # restarting
    #stub_node_install_rabbitmq
    Gexcore::Nodes::Control.restart_node(node)

    node.reload

    node
  end

  def create_node_status_restart_error(cluster)
    #
    node = create_node_active(cluster)

    # restarting
    stub_node_install_rabbitmq
    Gexcore::Nodes::Control.restart_node(node)
    node.reload

    # restart_error
    #Gexcore::Nodes::Notification.notify_restart_error(node)
    node.set_restart_error!
    node.reload

    node
  end


  ### stub node

  def stub_create_node_all
    #
    stub_create_node_provision
    stub_create_node_provision_aws

    # stub commands
    stub_node_commands_all


  end

  def stub_remove_node_all
    stub_remove_node_provision
    stub_node_remove_rabbitmq
  end


  def stub_create_node_provision
    allow(Gexcore::Consul::Utils).to receive(:consul_set).and_return(true)

    allow(Gexcore::Provision::Service).to receive(:run).and_return(Gexcore::Response.res_data)

    #allow(Gexcore::Provision::Service).to receive(:run_script_ansible).with('create_node.yml', anything).and_return(Gexcore::Response.res_data)
    #allow(Gexcore::ProvisionService).to receive(:run_script_ansible).with('rollback_create_node.yml', anything).and_return(Gexcore::Response.res_data)


    #allow(Gexcore::AnsibleService).to receive(:create_node).and_return Gexcore::Response.res_data
    #allow(Gexcore::AnsibleService).to receive(:run_script).with('create_node.yml', any_args).and_return Gexcore::Response.res_data
    #allow_any_instance_of(Gexcore::AnsibleRequest).to receive(:run).and_return true



  end

  def stub_create_node_provision_aws
    allow(Gexcore::Provision::Service).to receive(:run).and_return(Gexcore::Response.res_data)

    #allow(Gexcore::ProvisionService).to receive(:run_script_ansible).with('create_aws_node.yml', anything).and_return(Gexcore::Response.res_data)
    #allow(Gexcore::ProvisionService).to receive(:run_script_ansible).with('create_node_aws_instance.yml', anything).and_return(Gexcore::Response.res_data)
  end

  def stub_remove_node_provision
    allow(Gexcore::Provision::Service).to receive(:run).and_return(Gexcore::Response.res_data)
    #allow(Gexcore::ProvisionService).to receive(:run_script_ansible).with('remove_node.yml', anything).and_return(Gexcore::Response.res_data)
  end

  ###

  def stub_node_commands_all
    # rabbitmq
    stub_node_rabbitmq_all

    # aws
    stub_node_commands_aws

  end

  def stub_node_commands_aws
    #allow(Gexcore::Nodes::Aws::Provision).to receive(:run_script_shell).and_return(Gexcore::Response.res_data)
  end

  def stub_node_send_command(cmd_name)
    allow(Gexcore::Nodes::Control)
        .to receive(:rabbitmq_add_command_to_queue)
                .with(kind_of(Node), cmd_name)
                .and_return(Gexcore::Response.res_data)

  end


  def stub_node_send_command_error(cmd_name, errmsg)
    allow(Gexcore::Nodes::Control)
        .to receive(:send_command)
                .with(kind_of(Node), 'start')
                .and_return(Gexcore::Response.res_error("error", errmsg, ""))

  end

  def stub_node_rabbitmq_all

    # install
    stub_node_install_rabbitmq

    # commands
    stub_node_rabbitmq_send_command('start')
    stub_node_rabbitmq_send_command('stop')
    stub_node_rabbitmq_send_command('restart')

    # remove
    stub_node_remove_rabbitmq
  end

  def stub_node_rabbitmq_send_command(cmd_name)
    allow(Gexcore::Nodes::Control).to receive(:rabbitmq_add_command_to_queue).and_return Gexcore::Response.res_data
  end

  def stub_node_install_rabbitmq
    allow(Gexcore::Nodes::Control).to receive(:rabbitmq_create_user_for_node).and_return Gexcore::Response.res_data
  end

  def stub_node_remove_rabbitmq
    allow(Gexcore::Nodes::Control).to receive(:rabbitmq_delete_all_for_node).and_return Gexcore::Response.res_data
  end


  ### stub node provision

  def stub_node_provision_error(task_name)
    allow(Gexcore::Provision::Service).to receive(:run)
                                              .with(task_name, anything)
                                              .and_return(Gexcore::Response.res_error("test_error", 'test error'))

  end


end
