RSpec.describe "DNS for Containers on Master", :type => :request do
  before :each do
    #
    @lib = Gexcore::DnsService

    stub_create_user_all
    stub_create_cluster_all


    # servers data
    @zone = Gexcore::Settings.domain_zone


  end

  describe 'Services on master' do
    before :each do
      # create user with cluster
      @admin, @cluster = create_user_and_cluster_onprem

      # stub can? => true
      stub_user_can_true

      #
      @test_data = {
          # cluster_id => ip_prefix
          123 => "0.123",
          255 => "0.255",
          256 => "1.0",
      }

    end

    describe 'calc IP' do
      it 'calc IP for master' do
        #
        @test_data.each do |id, ip_postfix|
          cluster = instance_double("Cluster", :id=>id)

          # hadoop
          ip_prefix = Gexcore::Settings.hadoop_master_ip_prefix
          ip = Gexcore::AppHadoop::MasterContainer.calc_ip('hadoop', cluster)
          expect(ip).to match /^#{ip_prefix}.#{ip_postfix}/

          # hue
          ip_prefix = Gexcore::Settings.hue_master_ip_prefix
          ip = Gexcore::AppHadoop::MasterContainer.calc_ip('hue', cluster)
          expect(ip).to match /^#{ip_prefix}.#{ip_postfix}/

        end

      end
    end

    describe 'calc Domain' do
      it 'calc domain for master' do

        @test_data.each do |id, ip_postfix|
          cluster = instance_double("Cluster", :id=>id)

          # hadoop
          domain = Gexcore::AppHadoop::MasterContainer.calc_domain('hadoop', cluster)
          expect(domain).to match /^hadoop-master-#{cluster.id}\.#{@zone}$/

          # hue
          domain = Gexcore::AppHadoop::MasterContainer.calc_domain('hue', cluster)
          expect(domain).to match /^hue-master-#{cluster.id}\.#{@zone}$/

        end
      end

    end

    describe 'IP by domain' do
      it 'hadoop master' do
        #allow(Gexcore::Settings).to receive(:hadoop_master_ip_prefix).and_return('51.55')
        #allow(Rails.configuration.gex_config).to receive(:hadoop_master_ip_prefix).and_return('51.55')

        expect(
            @lib.ip_by_domain "hadoop-master-#{@cluster.id}.#{@zone}"
        ).to match /^#{Gexcore::Settings.hadoop_master_ip_prefix}\./

      end

      it 'hue master' do
        expect(
            @lib.ip_by_domain "hue-master-#{@cluster.id}.#{@zone}"
        ).to match /^#{Gexcore::Settings.hue_master_ip_prefix}\./

      end
    end

    describe 'Domain by IP' do

      it 'hadoop master' do
        ip = Gexcore::AppHadoop::MasterContainer.calc_ip('hadoop', @cluster)
        domain = Gexcore::AppHadoop::MasterContainer.calc_domain('hadoop', @cluster)

        expect(
            @lib.domain_by_ip ip
        ).to eq domain
      end

      it 'hue master' do
        ip = Gexcore::AppHadoop::MasterContainer.calc_ip('hue', @cluster)
        domain = Gexcore::AppHadoop::MasterContainer.calc_domain('hue', @cluster)

        expect(
            @lib.domain_by_ip ip
        ).to eq domain
      end


    end


  end

end
