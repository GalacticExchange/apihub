RSpec.describe "Uninstall AWS node process", :type => :request do

  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_remove_node_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_aws

    #
    @instance_id = build_instance_id
  end


  describe 'uninstall process' do

    it 'uninstall active node' do
      # have active node
      node = create_node_active @cluster

      # uninstall
      Gexcore::Nodes::Service.uninstall_node(node)

      #
      node.reload
      expect(node.status).to eq 'uninstalling'

      expect(node.job_finished?('uninstall')).to eq false
      expect(node.job_task_not_finished?('uninstall', 'master')).to eq true
      expect(node.job_task_not_finished?('uninstall', 'client')).to eq true



      # run provision
      Gexcore::Nodes::Aws::Provision.uninstall_node(node.id)

      #
      node.reload
      expect(node.status).to eq 'removed'

      #
      Gexcore::NotificationService.notify('node_uninstalled', {node_id: node.id})

      node.reload

      expect(node.removed?).to eq true

    end



    it 'uninstall removed node' do
      # stub
      stub_node_remove_rabbitmq

      #
      node = create_node @cluster

      # remove node
      Gexcore::Nodes::Service.remove_node node
      node.reload

      #
      expect(node.removed?).to eq true

      # uninstall process
      Gexcore::NotificationService.notify('node_uninstalling', {node_id: node.id})
      node.reload

      expect(node.removed?).to eq true

      #
      Gexcore::NotificationService.notify('node_uninstalled', {node_id: node.id})
      node.reload

      expect(node.removed?).to eq true
    end

  end
end
