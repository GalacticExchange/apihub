RSpec.describe "cluster info", :type => :request do
  before :each do
    @lib = Gexcore::Clusters::Service

    stub_create_user_all
    stub_create_cluster_all
  end

  describe 'Clusters::Service.get_cluster_info' do
    before :each do
      @cluster_for_error = double(Cluster)
    end

    it 'to_hash_method' do
      # stub
      allow(@cluster_for_error).to receive(:options_hash_public).and_return("test2")

      # check
      expect(@cluster_for_error).to receive(:to_hash).and_return("test")


      res = @lib.get_cluster_info(@cluster_for_error)
    end

    it 'options_hash_public_method' do
      allow(@cluster_for_error).to receive(:to_hash).and_return("test")

      #
      expect(@cluster_for_error).to receive(:options_hash_public).and_return("test2")

      # work
      res = @lib.get_cluster_info(@cluster_for_error)
    end

    it 'get_cluster_info_method' do
      # stub
      allow(@cluster_for_error).to receive(:to_hash).and_return("test")
      allow(@cluster_for_error).to receive(:options_hash_public).and_return("test2")

      # work
      res = @lib.get_cluster_info(@cluster_for_error)
      expect(res.data[:cluster]).to eq("test")
      expect(res.data[:settings]).to eq("test2")
    end

  end
end
