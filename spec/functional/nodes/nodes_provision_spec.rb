RSpec.describe "Provision Hadoop on node", :type => :request do

  describe 'params for create_node' do

    describe 'onprem cluster' do
      before :each do

      end

      it 'basic' do
        node = double_node

        base_params = [
            'cluster_id',
            #'cluster_uid', 'cluster_name',
            'uid', 'id', 'node_number', 'node_type', 'name',
            'interface', 'is_wifi'
        ]

        # check params
        args = Gexcore::Nodes::Service.consul_build_node_data(node)

        # check
        base_params.each do |p|
          expect(args[p]).not_to be_nil
        end


      end

      it 'interface is encoded' do
        #expect(p['interface']).to eq node.encode_option(node_options['selected_interface']['name'])
        #expect(p['is_wifi']).to eq node_options['selected_interface']['isWifi']

      end


      it 'enterprise options' do
        node_options = {
            proxyIP: '120.35.46.78',
            staticIPs: true,
            networkMask: '255.0.0.0',
            gatewayIP: '120.35.0.1',
        }
        node = double_node({}, node_options)

        correct_params = [
            'proxy_ip',
            'static_ips',
            'gateway_ip',
            'network_mask',
            'container_ips',
            'interface',
            'is_wifi',
            'container_ips'
        ]

        #containers_names = Gexcore::AppHadoop::CONTAINERS_BY_SERVICE_SLAVE.values.uniq

        args = Gexcore::Nodes::Service.consul_build_node_data(node)

        # check
        correct_params.each do |p|
          expect(args[p]).not_to be_nil
        end

      end

      it 'container ips' do
        node_options = {
            proxyIP: '120.35.46.78',
            staticIPs: true,
            networkMask: '255.0.0.0',
            gatewayIP: '120.35.0.1',
        }
        node = double_node({}, node_options)

        containers_names = Gexcore::AppHadoop::App::CONTAINERS_BY_SERVICE_SLAVE.values.uniq

        node_containers = []
        ind = 1
        containers_names.each do |cont_name|
          cont = double(ClusterContainer, {basename: cont_name, public_ip: "55.128.0.#{ind}"})
          node_containers << cont
          ind = ind +1
        end
        allow(node).to receive(:containers).and_return(node_containers)

        # work
        args = Gexcore::Nodes::Service.consul_build_node_data(node)

        # check
        correct_params = [
            'container_ips'
        ]

        expect(args['container_ips']).not_to be_nil

        ips = args['container_ips']

        containers_names.each do |cont_name|
          expect(ips[cont_name]).not_to be_nil
          expect(ips[cont_name]).to match /^55.128.0.\d+$/
        end

      end

    end


    describe 'aws cluster' do
      before :each do


      end

      it 'params' do
        node = double_node_aws()

        base_params = [
            'cluster_id',
            #'cluster_uid', 'cluster_name',
            'uid', 'id', 'node_number', 'node_type', 'name',
            'interface', 'is_wifi',

        ]

        params_services = [
            'port_ssh',
            'port_hue'
        ]

        # work
        args = Gexcore::Nodes::Service.consul_build_node_data(node)

        # check
        expect(args['node_type']).to eq 'aws'

        base_params.each do |p|
          expect(args[p]).not_to be_nil
        end

        params_services.each do |p|
          expect(args[p]).not_to be_nil
        end


      end
    end

  end

end
