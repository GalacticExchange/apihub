RSpec.describe "DNS for Services on Node", :type => :request do
  before :each do
    #
    @lib = Gexcore::DnsService

    stub_create_user_all
    stub_create_cluster_all


    # servers data
    @zone = Gexcore::Settings.domain_zone

    # stub ansible
    #allow(Gexcore::AnsibleService).to receive(:update_container_route).and_return(Gexcore::Response.res_data)

  end

=begin
  describe 'our servers' do
    before :each do

      @our_servers = {
          'master.local' => @config_servers['master']['ip'],
          'api.local' => @config_servers['api']['ip'],
          'notexist.local' => nil

      }


    end

    it 'IP for our servers' do
      # check
      @our_servers.each do |domain, ip_right|
        ip = @lib.ip_by_domain(domain)

        if ip_right.nil?
          expect(ip).to be_nil
        else
          expect(ip).to eq ip_right
        end

      end

    end

    it 'Reverse DNS for our servers' do
      # check
      @our_servers.each do |domain, ip|
        next if ip.nil?

        res_domain = @lib.domain_by_ip(ip)

        expect(res_domain).to eq domain
      end
    end


  end
=end

end
