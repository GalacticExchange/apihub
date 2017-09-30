RSpec.describe "Node uninstall process", :type => :request do

  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_remove_node_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_onprem

    #
    @instance_id = build_instance_id
  end


  describe 'uninstall active node' do
    before :each do
      # active node
      @node = create_node_active @cluster

    end

    it 'process OK' do
      node = @node

      # notify uninstalling
      Gexcore::NotificationService.notify('node_uninstalling', {node_id: node.id})

      # check
      node.reload
      expect(node.uninstalling?).to eq true
      expect(node.job_finished?('uninstall')).to eq false
      expect(node.job_task_not_finished?('uninstall', 'master')).to eq true
      expect(node.job_task_not_finished?('uninstall', 'client')).to eq true


      # notify client uninstalled
      Gexcore::NotificationService.notify('node_uninstalled', {node_id: node.id})

      # check
      node.reload
      expect(node.uninstalling?).to eq true
      expect(node.job_finished?('uninstall')).to eq false
      expect(node.job_task_finished?('uninstall', 'master')).to eq false
      expect(node.job_task_finished?('uninstall', 'client')).to eq true



      # provision remove_node
      Gexcore::Nodes::Provision.provision_master_uninstall_node(node)

      # check
      node.reload
      expect(node.removed?).to eq true
      expect(node.job_finished?('uninstall')).to eq true

    end

    it 'if error uninstalling on client' do
      node = @node

      # notify uninstalling
      Gexcore::NotificationService.notify('node_uninstalling', {node_id: node.id})

      # check
      node.reload
      expect(node.uninstalling?).to eq true
      expect(node.job_finished?('uninstall')).to eq false


      # notify client uninstall_error
      Gexcore::NotificationService.notify('node_uninstall_error', {node_id: node.id})

      # check
      node.reload
      expect(node.status).to eq 'uninstall_error'
      expect(node.job_errors?('uninstall')).to eq true
      expect(node.job_task_error?('uninstall', 'client')).to eq true



      # provision remove_node.yml
      Gexcore::Nodes::Provision.provision_master_uninstall_node(node)

      # check
      node.reload
      expect(node.status).to eq 'uninstall_error'
      expect(node.job_errors?('uninstall')).to eq true


    end


    it 'if error in provision remove_node.yml' do
      node = @node

      # notify uninstalling
      Gexcore::NotificationService.notify('node_uninstalling', {node_id: node.id})

      # check
      node.reload
      expect(node.uninstalling?).to eq true
      expect(node.job_finished?('uninstall')).to eq false


      # notify client uninstalled
      Gexcore::NotificationService.notify('node_uninstalled', {node_id: node.id})

      # check
      node.reload


      # error in provision remove_node.yml
      stub_node_provision_error('remove_node')

      Gexcore::Nodes::Provision.provision_master_uninstall_node(node)

      # check
      node.reload
      expect(node.status).to eq 'uninstall_error'
      expect(node.job_errors?('uninstall')).to eq true
      expect(node.job_task_error?('uninstall', 'master')).to eq true

    end


  end



  describe 'uninstall install_error node' do
    before :each do
      # have install_error node
      @node = create_node_status_install_error @cluster
    end

    it 'process to removed' do
      node = @node


      # notify uninstalling
      Gexcore::NotificationService.notify('node_uninstalling', {node_id: node.id})

      # check
      node.reload

      # notify client uninstalled
      Gexcore::NotificationService.notify('node_uninstalled', {node_id: node.id})

      # check
      node.reload

      # provision remove_node.yml
      Gexcore::Nodes::Provision.provision_master_uninstall_node(node)

      # check
      node.reload
      expect(node.status).to eq 'removed'

    end
  end


  describe 'uninstall removed node' do
    before :each do
      # have removed node
      @node = create_node @cluster
      Gexcore::Nodes::Service.remove_node @node

      @node.reload
    end
    it 'uninstall removed node' do
      node = @node

      # precheck
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
