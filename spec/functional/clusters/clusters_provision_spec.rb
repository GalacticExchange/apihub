RSpec.describe "Provision Hadoop on master", :type => :request do
  before :each do

  end

  describe 'onprem cluster' do
    before :each do
      @cluster, @hadoop_app = double_cluster({hadooop_type: 'plain'})
    end

    it 'ok - response' do
      allow(Gexcore::Provision::Service).to receive(:run)
            .with('create_cluster', any_args)
            .and_return(Gexcore::Response.res_data)

      res = Gexcore::Clusters::Provision.provision_master_create_cluster(@hadoop_app)

      #
      expect(res.success?).to eq true

    end

    it 'calls rollback' do
      ### only for production env

      # stub
      allow(Gexcore::Provision::Service).to receive(:run)
                                                .with('create_cluster', any_args)
                                                .and_return(Gexcore::Response.res_error('', 'test error'))


      # check
      expect(Gexcore::Provision::Service).to receive(:run)
                                                 .with('remove_cluster', any_args)




      # work
      res = Gexcore::Clusters::Provision.provision_master_create_cluster(@hadoop_app)


      #
      expect(res.success?).to eq false
    end


    it 'provision script' do
      # stub
      allow(Gexcore::Provision::Service).to receive(:run) do |task_name, cmd|
        #expect(cmd).to match /ansible-playbook /
        expect(cmd).to match /provision:create_cluster/

        expect(cmd).to match /_cluster_data=/
        expect(cmd).to match /_cluster_id=/

      end.and_return(Gexcore::Response.res_data)

      # work
      res= Gexcore::Clusters::Provision.provision_master_create_cluster(@hadoop_app)
    end

  end



  describe 'onprem cluster with options' do

    before :each do
      @hadoop_type_name = 'cdh'
      @cluster_options = build_cluster_options_advanced({hadoopType: @hadoop_type_name})
      @cluster, @hadoop_app = double_cluster({hadoop_type: @hadoop_type_name}, @cluster_options)
    end

    it 'ok - response' do
      allow(Gexcore::Provision::Service).to receive(:run)
                                            .with('create_cluster', any_args)
                                            .and_return(Gexcore::Response.res_data)

      res = Gexcore::Clusters::Provision.provision_master_create_cluster(@hadoop_app)


      #
      expect(res.success?).to eq true

    end

    it 'ansible script' do
      enterprise_ansible_params = ['_proxy_ip', '_static_ips', '_gateway_ip', '_network_mask', '_network_ip_range_start', '_network_ip_range_end']

      # stub
      allow(Gexcore::Provision::Service).to receive(:run) do |task_name, cmd|
        #expect(cmd).to match /ansible-playbook /
        expect(cmd).to match /provision:create_cluster/

        #
        #expect(cmd).to match(/\"_hadoop_type\": *#{@opt_hadoop_type}/)

        #expect(cmd).to match(/\"_gex_env\":/i)


        # enterprise options
        #enterprise_ansible_params.each do |p_good|
        #  expect(cmd).to match(/\"#{p_good}\":/)
        #end

      end.and_return(Gexcore::Response.res_data)

      # work
      res = Gexcore::Clusters::Provision.provision_master_create_cluster(@hadoop_app)

    end

  end



  describe 'AWS cluster' do

    before :each do
      @cluster, @hadoop_app = double_cluster_aws
    end

    it 'ok - response' do
      allow(Gexcore::Provision::Service).to receive(:run)
                                              .with('create_cluster', any_args)
                                              .and_return(Gexcore::Response.res_data)

      res = Gexcore::Clusters::Provision.provision_master_create_cluster(@hadoop_app)


      #
      expect(res.success?).to eq true

    end

    it 'ansible script' do
      # ansible script params
      allow(Gexcore::Provision::Service).to receive(:run) do |task_name, cmd|
        #expect(cmd).to match /ansible-playbook /
        expect(cmd).to match /provision:create_cluster/

        #
        #expect(cmd_contains_param(cmd, "_hadoop_type", @opt_hadoop_type)).to eq true
        #expect(cmd_contains_param(cmd, "_cluster_type", @cluster.get_option('cluster_type'))).to eq true

        # TODO: options
        # aws options
        #expect(cmd_contains_param(cmd, "_aws_region", @cluster.get_option('aws_region'))).to eq true
        #expect(cmd_contains_param(cmd, "_aws_access_key_id", @cluster.get_option('aws_key_id'))).to eq true
        #expect(cmd_contains_param(cmd, "_aws_secret_key", @cluster.get_option('aws_secret_key'))).to eq true

        # enterprise options
        #enterprise_ansible_params.each do |p_good|
        #  expect(cmd).to match(/ #{p_good} *=/)
        #end

      end.and_return(Gexcore::Response.res_data)

      # run provision
      res = Gexcore::Clusters::Provision.provision_master_create_cluster(@hadoop_app)

    end

  end
end
