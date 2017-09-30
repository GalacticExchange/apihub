RSpec.describe "Create cluster with advanced options", :type => :request do
  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all

    #
    @user = create_user_active

    @cluster_opts = build_cluster_options_advanced
    @cluster_hash = build_cluster_hash_onprem_with_options(@cluster_opts)

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

    it 'cluster data in DB' do
      # work
      post_json '/clusters', @cluster_hash, {token: @token}

      # check
      resp = last_response
      resp_data = response_json

      # cluster
      cluster = Cluster.get_by_uid(resp_data['cluster']['id'])

      expect(cluster.installing?).to eq true

      # options
      opts = cluster.options_hash

      @cluster_opts.each do |k, v|
        expect(opts[k.to_s]).to eq v
      end


    end



    it 'process from installing to active' do
      # work
      post_json '/clusters', @cluster_hash, {token: @token}

      #
      resp_data = response_json
      cluster = Cluster.get_by_uid(resp_data['cluster']['id'])

      expect(cluster.installing?).to eq true

      # run provision - sidekiq performs the job
      Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(cluster.hadoop_app.id)

      cluster.reload

      # check
      expect(cluster.active?).to eq true

    end



  end



end
