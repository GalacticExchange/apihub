RSpec.describe "Create aws cluster", :type => :request do
  before :each do
    @resp = Gexcore::Response

    stub_create_user_all
    stub_create_cluster_all
    stub_create_cluster_aws

    #
    @sysinfo = build_sysinfo
  end

  describe "create_cluster" do
    before :each do
      @user = create_user_active

      #
      @aws_key = JSON.parse(File.read('spec/data/aws_keys.json'))
      @cluster_options = {
          cluster_type: 'aws',
          aws_region_id: 'us-west-2',
          aws_key_id: @aws_key['key_id'],
          aws_secret_key: @aws_key['secret_key'],
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


      #execute
      expect(res.success?).to be true
      expect(res.data[:cluster][:id]).not_to be_empty
      expect(res.data[:cluster][:name]).not_to be_empty
      expect(res.data[:cluster][:domainname]).not_to be_empty

    end

    it 'cluster db row' do
      #
      cluster_count = Cluster.count

      # do it
      res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

      # check rows in DB
      expect(Cluster.count).to eq(cluster_count+1)

      # check cluster in DB
      cluster = Cluster.get_by_uid(res.data[:cluster][:id])
      expect(cluster).not_to be_nil

      #
      expect(cluster.uid).to eq(res.data[:cluster][:id])
      expect(cluster.name).not_to be_empty
      expect(cluster.last_node_number).to eq(0)
      expect(cluster.cluster_type.name).to eq 'aws'

      # cluster status
      expect(cluster.installing?).to eq true

      # options
      opts = cluster.options_hash

      expect(opts['aws_region']).not_to be_empty
      expect(opts['aws_key_id']).not_to be_empty
      expect(opts['aws_secret_key']).not_to be_empty

    end

    it 'check AWS credentials' do
      allow(Gexcore::Clusters::Aws::Service).to receive(:aws_check_connection).and_call_original

      #
      @cluster_options[:aws_key_id]='badkey'
      @cluster_options[:aws_secret_key]='baaaadkey'

      #
      cluster_count = Cluster.count

      # do it
      res = Gexcore::Clusters::Service.create_cluster(@user, @sysinfo, @cluster_options)

      # no new row in DB
      expect(Cluster.count).to eq(cluster_count)

      #
      expect(res.error?).to eq true

    end
  end

end
