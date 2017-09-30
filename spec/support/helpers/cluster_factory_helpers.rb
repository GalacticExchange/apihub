module ClusterFactoryHelpers

  def double_cluster(fields={}, cluster_options={})
    # cluster_type
    cluster_type_name = 'onprem'
    cluster_type = ClusterType.get_by_name cluster_type_name

    #hadoop_type_name = random_hadoop_type_name
    hadoop_type_name = fields[:hadoop_type] || random_hadoop_type_name
    hadoop_type = ClusterHadoopType.get_by_name hadoop_type_name
    library_app = LibraryApplication.get_by_name("hadoop_#{hadoop_type_name}")

    #
    #cluster_options = build_user_options_enterprise({hadoopType: @hadoop_type_name})


    #
    cluster = double(Cluster,
                     :id=>1,
                     :uid=> 'aaaXXX1111',
                     :name=>'cluster-name', :domainname=>'mycluster',
                     :cluster_type_name=>cluster_type_name,
                     :hadoop_type=>hadoop_type,
                     :options_hash=>cluster_options
    )

    hadoop_app = double(ClusterApplication,
                        :id =>199,
                        :library_application=>library_app,
                        :cluster=>cluster)



    #
    allow(cluster).to receive(:hadoop_app).and_return(hadoop_app)
    allow(cluster).to receive(:hadoop_app_id).and_return(hadoop_app.id)


    # stub service ports
    #allow(Gexcore::ClusterServices::Service).to receive(:get_service_ports).and_return([])
    #@services = double(:all=>[])
    #allow(@hadoop_app).to receive(:services).and_return(@services)

    allow(hadoop_app).to receive_message_chain(:services, :w_master, :all).and_return([])

    # options
    if cluster_options
      allow(cluster).to receive(:get_option) do |opt_name|
        cluster_options[opt_name.to_sym]
      end
      allow(cluster).to receive(:option_static_ips?).and_return(cluster_options['staticIPs'] || false)
    end




    [cluster, hadoop_app]
  end


  def double_cluster_aws(opts={}, cluster_options={})
    # cluster_type
    cluster_type_name = 'aws'
    cluster_type = ClusterType.get_by_name cluster_type_name

    # hadoop_type
    hadoop_type_name = random_hadoop_type_name
    hadoop_type = ClusterHadoopType.get_by_name hadoop_type_name

    #
    cluster_options = build_cluster_options_advanced({hadoopType: hadoop_type_name})

    # aws options
    cluster_options['cluster_type'] = 'aws'
    cluster_options['aws_region'] = 'us-west-2'
    cluster_options['aws_key_id'] = 'key12'
    cluster_options['aws_secrete_key'] = 'secretkey12'

    cluster = double(Cluster, :id=>10,
                      :name=>'cluster-name', :domainname=>'mycluster',
                      :uid=> 'aaaXXX1111',
                      :cluster_type_name=>cluster_type_name,
                      :hadoop_type=>hadoop_type,
                      :options_hash=>cluster_options)

    library_app = LibraryApplication.get_by_name("hadoop_#{hadoop_type_name}")
    hadoop_app = double(ClusterApplication,
                        :id=>199,
                        :library_application=>library_app,
                        :cluster=>cluster)


    #
    allow(cluster).to receive(:hadoop_app).and_return(hadoop_app)
    allow(cluster).to receive(:hadoop_app_id).and_return(hadoop_app.id)


    # stub cluster data
    allow(hadoop_app).to receive_message_chain(:services, :w_master, :all).and_return([])


    # options
    if cluster_options
      allow(cluster).to receive(:get_option) do |opt_name|
        cluster_options[opt_name.to_sym]
      end
      allow(cluster).to receive(:option_static_ips?).and_return(cluster_options['staticIPs'] || false)
    end



    [cluster, hadoop_app]
  end



  ### create cluster

  def create_user_and_cluster_onprem(cluster_options={}, user_hash=nil)

    user = create_user_active user_hash
    cluster = cluster_create_onprem(user, cluster_options)


    [user, cluster]
  end

  def cluster_create_onprem(user, opts={})
    sysinfo = build_sysinfo

    #cluster_options = build_cluster_options_onprem(opts)
    cluster_options = {}

    res = Gexcore::Clusters::Service.create_cluster(user, sysinfo, cluster_options)
    cluster = Cluster.get_by_uid(res.data[:cluster][:id])

    # provision cluster
    Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(cluster.hadoop_app.id)

    cluster.reload

    #
    cluster
  end


  ### create cluster with advanced options

  def create_user_and_cluster_onprem_advanced(cluster_options={})
    user = create_user_active
    cluster = cluster_create_onprem_advanced(user, cluster_options)
    [user, cluster]
  end

  def cluster_create_onprem_advanced(user, opts={})
    sysinfo = build_sysinfo

    cluster_options = build_cluster_options_advanced(opts)

    res = Gexcore::Clusters::Service.create_cluster(user, sysinfo, cluster_options)
    cluster = Cluster.get_by_uid(res.data[:cluster][:id])


    cluster
  end


  ### create cluster - aws


  def cluster_create_aws(user, opts={})
    sysinfo = build_sysinfo

    cluster_options = build_cluster_options_aws(opts)

    res = Gexcore::Clusters::Service.create_cluster(user, sysinfo, cluster_options)
    cluster = Cluster.get_by_uid(res.data[:cluster][:id])


    cluster
  end


  def create_user_and_cluster_aws(cluster_options={})

    user = create_user_active
    cluster = cluster_create_aws(user, cluster_options)


    [user, cluster]
  end


  ### build hash

  def build_cluster_hash_onprem
    {
        clusterType: "onprem",
        systemInfo: build_sysinfo,
        hadoopType: 'cdh'
    }

  end

  def build_cluster_hash_onprem_with_options(opts=nil)
    res = build_cluster_hash_onprem

    if opts
      res.merge! opts
    else
      opts = build_cluster_options_advanced
    end

    res
  end

  def build_cluster_options_advanced(opts={})
    res = {
        hadoopType: random_hadoop_type_name,
        proxyIP: '51.0.0.1',
        proxyUser:  "max",
        proxyPassword:  "rubyforever",
        staticIPs: true,
        gatewayIP: "51.0.0.1",
        networkMask: '255.0.0.0',
        networkIPRangeStart: '51.0.0.10',
        networkIPRangeEnd: '51.0.0.99',
    }

    res.merge!(opts)

    res
  end

  def build_cluster_options_aws(opts={})
    aws_key = JSON.parse(File.read('spec/data/aws_keys.json'))

    res = {
        cluster_type: 'aws',
        aws_region_id: 'us-west-2',
        aws_key_id: aws_key['key_id'],
        aws_secret_key: aws_key['secret_key'],
    }

    res.merge!(opts)

    res
  end




  def random_hadoop_type_name
    row = ClusterHadoopType.w_enabled.where("name <> '#{ClusterHadoopType::DEFAULT_NAME}'").order("RAND()").first

    row.name
  end

  ### Stub

  def stub_create_cluster_all
    stub_create_cluster_permissions
    stub_create_cluster_provision
  end

  def stub_create_cluster_permissions

  end

  def stub_create_cluster_provision
    allow(Gexcore::Consul::Utils).to receive(:consul_set).and_return(true)

    allow(Gexcore::Provision::Service).to receive(:run).and_return(Gexcore::Response.res_data)
    #allow(Gexcore::AnsibleService).to receive(:run_script).with('create_cluster.yml', any_args).and_return Gexcore::Response.res_data
    #allow(Gexcore::AnsibleService).to receive(:create_cluster).and_return Gexcore::Response.res_data
  end


  def stub_create_cluster_aws
    allow(Gexcore::Clusters::Aws::Service).to receive(:aws_check_connection).and_return(true)
    allow(Gexcore::Clusters::Aws::Service).to receive(:aws_check_vpc_limit).and_return(true)
  end
end
