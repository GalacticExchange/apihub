RSpec.describe "Create cluster", :type => :request do
  before :each do
    @resp = Gexcore::Response

    #
    @sysinfo = build_sysinfo

    stub_create_user_all

    stub_create_cluster_all

  end



  describe "Clusters::Service.create_cluster" do
    before :each do
      #
      @user = create_user_active

      #
      @cluster_options = {
          clusterType: "onprem",
          hadoopType: "cdh"
      }

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


      # check
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
      #expect(cluster.primary_admin_user_id).to eq user.id
      expect(cluster.last_node_number).to eq(0)

      # cluster status
      expect(cluster.installing?).to eq true

    end


    it 'cluster access' do
      # do it
      res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

      # check
      cluster = Cluster.get_by_uid(res.data[:cluster][:id])

      # access
      expect(@user.can?(:manage, cluster)).to eq true



    end



    context 'Hadoop application' do
      before :each do
        @apps = ['hadoop_cdh']
        @app_name = @apps[0]

        #
        @sysinfo = build_sysinfo
        @cluster_options = {
            clusterType: "onprem",
            hadoopType: "cdh"
        }
      end

      it 'clusters.app_hadoop' do
        # do it
        res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

        # check cluster in DB
        cluster_uid= res.data[:cluster][:id]
        cluster = Cluster.get_by_uid(cluster_uid)

        expect(cluster).not_to be_nil

        #
        expect(cluster.hadoop_app_id).to be >0

      end


      it 'DB cluster_applications' do
        # work
        res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

        # check
        cluster = Cluster.get_by_uid res.data[:cluster][:id]

        # check
        expect(cluster.applications.count).to eq @apps.length

        app = ClusterApplication.get_for_cluster(@app_name, cluster)
        expect(app.name).to eq @app_name
        expect(app.status).to eq 'installing'

      end


      context 'Provision master node' do

        it 'calls async job for provision' do
          expect(Gexcore::AppHadoop::Provision).to receive(:provision_master_create_cluster_run_script_enqueue)

          # work
          res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)
        end

      end

      context 'containers for hadoop' do

        it 'create containers' do
          container_names = Gexcore::AppHadoop::App::CONTAINERS_BY_SERVICE_MASTER.values.uniq

          # work
          res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

          # check
          cluster = Cluster.get_by_uid res.data[:cluster][:id]
          app = ClusterApplication.get_for_cluster(@app_name, cluster)

          # check
          expect(cluster.containers.count).to eq container_names.length

          container_names.each do |name|
            r = ClusterContainer.get_master_for_cluster(name, cluster)

            expect(r.uid).not_to be_nil
            expect(r.name).not_to be_nil
            expect(r.basename).not_to be_nil
            expect(container_names).to include r.basename
            expect(r.status).to eq 'installing'
            expect(r.cluster_id).to eq cluster.id
            expect(r.application_id).to eq app.id
            expect(r.node_id).to be_nil
            expect(r.is_master).to eq true
            expect(r.hostname).to be_truthy

            # ips
            expect(r.private_ip).to be_truthy
            expect(r.public_ip).to be_nil


          end
        end
      end

      context 'master container and services' do

        it 'master container for hadoop' do
          container_name = 'hadoop'

          #
          res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

          #
          cluster = Cluster.get_by_uid res.data[:cluster][:id]
          app = ClusterApplication.get_by_id(res.sysdata[:application_id])

          # check
          r = container = ClusterContainer.get_master_for_cluster(container_name, cluster)

          expect(r.cluster_id).to eq cluster.id
          expect(r.application_id).not_to be_nil
          expect(r.node_id).to be_nil
          expect(r.is_master).to eq true
          expect(r.status).to eq 'installing'
          #expect(r.host).to be_truthy

        end

        it 'services on master node' do
          services = ['ssh', 'hadoop_resource_manager', 'hue', 'hdfs', 'spark_master_webui', 'spark_history']

          # work
          res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

          # check
          cluster = Cluster.get_by_uid res.data[:cluster][:id]
          app = ClusterApplication.get_by_id(res.sysdata[:application_id])

          # check
          services.each do |s|
            r = ClusterService.get_by_name_and_cluster(s, cluster)

            expect(r).not_to be_nil

            expect(r.application_id).to eq app.id
            expect(r.cluster_id).not_to be_nil
            expect(r.node_id).to be_nil
            expect(r.port_in).to be_truthy
            expect(r.port_out).to be_truthy

          end

        end

      end

    end



  end



  describe 'Clusters::Service.create_cluster_run_script' do

    before :each do
      @appname = 'hadoop_cdh'

      @sysinfo = build_sysinfo
      @cluster_options = {
          clusterType: "onprem",
          hadoopType: "cdh"
      }

      #
      @user = create_user_active

      # create cluster
      res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

      @cluster = Cluster.get_by_uid(res.data[:cluster][:id])
      @app_hadoop = ClusterApplication.get_by_name_and_cluster(@appname, @cluster)

    end


    it 'activate cluster' do
      # sidekiq performs the job
      Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(@app_hadoop.id)

      # check
      @cluster.reload
      expect(@cluster.active?).to eq true


    end

    it 'error in ansible script' do
      # stub ansible - ERROR
      allow(Gexcore::Provision::Service).to(
          receive(:run)
              .with("create_cluster", any_args)
              .and_return(Gexcore::Response.res_error("test_error", "test error"))
      )

      # sidekiq performs the job
      Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(@app_hadoop.id)

      # check
      @cluster.reload
      expect(@cluster.install_error?).to eq true
    end


    context 'Hadoop application' do

      it 'app status' do
        # stub
        stub_create_cluster_all

        # stub ansible
        allow(Gexcore::Provision::Service).to(
            receive(:run).with('create_cluster', any_args).and_return(Gexcore::Response.res_data))

        # sidekiq performs the job
        Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(@app_hadoop.id)

        # check
        @cluster.reload

        # app
        app = @cluster.hadoop_app
        expect(app.active?).to eq true


      end

      it 'containers & services' do
        # stub
        stub_create_cluster_all

        # stub ansible
        allow(Gexcore::Provision::Service).to(
            receive(:run).with('create_cluster', any_args).and_return(Gexcore::Response.res_data))

        # sidekiq performs the job
        Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(@app_hadoop.id)

        # check
        @cluster.reload

        # containers
        containers = @cluster.containers.all
        containers.each do |container|
          expect(container.active?).to eq true
        end

        # services
        services = @cluster.hadoop_app.services
        services.each do |service|
          expect(service.active?).to eq true
        end


      end
    end


  end
end
