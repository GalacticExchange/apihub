module ContainerFactoryHelpers
  ### create

  def create_master_container_status_stopped(cluster, basename='hadoop')
    # master container
    container = cluster.get_master_container basename

    Gexcore::Containers::Control.stop_container(container)
    container.reload
    Gexcore::Containers::Notification.notify_stopped(container)
    container.reload

    container
  end


  def create_slave_container_status_stopped(node, basename='hadoop')
    container = Gexcore::Containers::Service.get_slave_by_basename(node, basename)

    #
    Gexcore::Containers::Control.stop_container(container)
    container.reload
    Gexcore::Containers::Notification.notify_stopped(container)
    container.reload

    container
  end



  ### stub
  def stub_container_provision_all
    allow(Gexcore::Provision::Service).to receive(:run).and_return(Gexcore::Response.res_data)

  end

end
