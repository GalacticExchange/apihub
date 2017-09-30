RSpec.describe "Create cluster onprem with advanced options", :type => :request do
  before :each do
    @resp = Gexcore::Response

    # stub
    stub_create_cluster_all
  end

  describe "create_cluster advanced" do
    before :each do
      #
      #
      @user = create_user_active

      #
      @cluster_options_adv = build_cluster_options_advanced
      @cluster_options = {clusterType: "onprem",hadoopType: "cdh"}.merge(@cluster_options_adv)

      #
      @now = Time.now.utc
      Timecop.freeze(@now)

    end

    after :each do
      Timecop.return
    end


    it "OK response" do
      # work
      res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)


      #execute
      expect(res.success?).to be true
      expect(res.data[:cluster][:id]).not_to be_empty
      expect(res.data[:cluster][:name]).not_to be_empty
      expect(res.data[:cluster][:domainname]).not_to be_empty

    end


    it "cluster in DB" do
      #
      cluster_count = Cluster.count

      # do it
      res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

      # check rows in DB
      expect(Cluster.count).to eq(cluster_count+1)

      # check cluster in DB
      cluster_uid= res.data[:cluster][:id]
      cluster = Cluster.get_by_uid(cluster_uid)

      expect(cluster).not_to be_nil

      #
      expect(cluster.uid).to eq(cluster_uid)
      expect(cluster.name).not_to be_empty
      expect(cluster.last_node_number).to eq(0)

      # cluster status
      expect(cluster.installing?).to eq true

    end

    it 'calls async provision job to run ansible script' do


      # check
      expect(Gexcore::AppHadoop::Provision).to receive(:provision_master_create_cluster_run_script_enqueue)

      # work
      res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)
    end
  end


  describe 'Clusters::Service.create_cluster_run_script' do

    before :each do
      #
      @user = create_user_active

      # cluster
      @cluster_options_adv = build_cluster_options_advanced
      @cluster_options = {clusterType: "onprem",hadoopType: "cdh"}.merge(@cluster_options_adv)


      # create cluster
      res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

      @cluster = Cluster.get_by_uid(res.data[:cluster][:id])

    end


    it 'activate cluster' do
      # sidekiq performs the job
      Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(@cluster.hadoop_app_id)


      # check
      @cluster.reload
      expect(@cluster.active?).to eq true
    end

    it 'error in ansible script' do
      # stub ansible - ERROR
      allow(Gexcore::Provision::Service).to(
          receive(:run)
              .with('create_cluster', any_args)
              .and_return(Gexcore::Response.res_error('', 'test error'))
      )

      allow(Gexcore::Provision::Service).to(
          receive(:run)
              .with('rollback_create_cluster', any_args)
              .and_return(Gexcore::Response.res_data)
      )

      # sidekiq performs the job
      Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(@cluster.hadoop_app_id)

      # check
      @cluster.reload
      expect(@cluster.install_error?).to eq true
    end



  end
end
