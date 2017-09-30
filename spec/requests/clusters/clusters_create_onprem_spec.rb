RSpec.describe "create cluster", :type => :request do
  before :each do
    @user = create_user_active

    @cluster_hash = build_cluster_hash_onprem

    # stub
    stub_create_cluster_all

    #
    @token = auth_token(@user)
  end


  describe 'create cluster' do
    before :each do


    end


    it 'ok response' do
      # work
      post_json '/clusters', @cluster_hash, {token: @token}

      # check
      resp = last_response

      # expectation
      expect(resp.status).to eq 200

    end

    it 'response data' do
      # work
      post_json '/clusters', @cluster_hash, {token: @token}

      # check
      resp = last_response
      resp_data = response_json

      cluster = resp_data['cluster']
      expect(cluster).not_to be_nil
      expect(cluster['id']).not_to be_nil
      expect(cluster['name']).not_to be_nil
      expect(cluster['domainname']).not_to be_nil

    end


    it 'cluster data in DB' do
      # work
      post_json '/clusters', @cluster_hash, {token: @token}

      # check
      resp = last_response
      resp_data = response_json

      # cluster
      cluster = Cluster.get_by_uid(resp_data['cluster']['id'])

      expect(cluster.installing?).to eq true




    end

    it 'add async job to provision' do
      # sidekiq performs the job
      expect(AppHadoopProvisionMasterCreateClusterWorker).to receive(:perform_async)


      # work
      post_json '/clusters', @cluster_hash, {token: @token}


      # check
    end



    it 'activate after provision' do
      # work
      post_json '/clusters', @cluster_hash, {token: @token}

      resp_data = response_json
      cluster = Cluster.get_by_uid(resp_data['cluster']['id'])

      # run provision - sidekiq performs the job
      Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(cluster.hadoop_app.id)

      cluster.reload

      # check
      expect(cluster.active?).to eq true

      # containers
      cluster.containers.each do |container|
        expect(container.status).to eq 'active'
      end

    end

    it 'send email after active' do
      # email
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      expect(UsersMailer).to receive(:cluster_info_email).and_return(message_delivery)
      expect(message_delivery).to receive(:deliver_later)


      # work
      post_json '/clusters', @cluster_hash, {token: @token}

      resp_data = response_json
      cluster = Cluster.get_by_uid(resp_data['cluster']['id'])

      # run provision - sidekiq performs the job
      Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(cluster.hadoop_app.id)

      cluster.reload

    end

    it 'error in provision' do
      # error in provision
      expect(Gexcore::Provision::Service).to(
          receive(:run)
              .with('rollback_create_cluster', anything)
              .and_return(Gexcore::Response.res_data)
      )

      allow(Gexcore::Provision::Service).to(
          receive(:run)
              .with('create_cluster', any_args)
              .and_return(Gexcore::Response.res_error('', 'test error ansible'))
      )


      # work
      post_json '/clusters', @cluster_hash, {token: @token}

      # check
      resp_data = response_json
      cluster = Cluster.get_by_uid(resp_data['cluster']['id'])

      # run provision - sidekiq performs the job
      Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(cluster.hadoop_app.id)

      cluster.reload

      # check
      expect(cluster.install_error?).to eq true

    end


  end


  describe 'hadoop type' do
    before :each do
      @cluster_hash[:hadoopType] = random_hadoop_type_name
    end


    it 'cluster.hadoop_type' do
      post_json '/clusters', @cluster_hash, {token: @token}

      # check
      resp = last_response
      resp_data = response_json

      expect(resp.status).to eq 200

      #
      cluster = Cluster.get_by_uid(resp_data['cluster']['id'])

      # check
      expect(cluster.hadoop_type.name).to eq @cluster_hash[:hadoopType]

    end

  end

end
