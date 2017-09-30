def run_ssh_cmd(ssh_options, cmd, _interaction_handler=nil)
  require 'sshkit'

  pwd = ssh_options.delete(:pwd)

  # debug
  host = SSHKit::Host.new(ssh_options)
  host.password = pwd

  output = ''

  # debug
  cmd = %Q([[ $- == *i* ]] && echo 'Interactive' || echo 'Not interactive')
  cmd = %Q(shopt -q login_shell && echo 'Login shell' || echo 'Not login shell')
  #cmd = %Q(echo '111')
  #cmd = %Q(bash -c 'rvm list')
  #cmd = 'cd /mount/ansible/provisioner && bundle exec cap -v'
  #cmd = 'pwd'
  #cmd = %Q(cd /mount/ansible/provisioner && _gex_env=main _cluster_id=362 _cluster_data='{"port_ssh":10337,"port_hadoop_resource_manager":10338,"port_hdfs":10339,"port_hdfs_namenode_webui":10340,"port_hue":10341,"port_spark_master_webui":10342,"port_spark_history":10343,"port_elastic":10344,"id":362,"uid":"3171247274090674","cluster_type":"onprem","name":"red-caelum","id_hex":"16a","hadoop_type":"cdh"}' bundle exec cap main provision:create_cluster)
  #cmd = %Q(cd /mount/ansible/provisioner && _gex_env=main _cluster_id=362 _cluster_data='{"port_ssh":10337,"port_hadoop_resource_manager":10338,"port_hdfs":10339,"port_hdfs_namenode_webui":10340,"port_hue":10341,"port_spark_master_webui":10342,"port_spark_history":10343,"port_elastic":10344,"id":362,"uid":"3171247274090674","cluster_type":"onprem","name":"red-caelum","id_hex":"16a","hadoop_type":"cdh"}' bundle exec cap main provision:test_task)
  #cmd = %Q(bash -c 'cd /mount/ansible/provisioner && bundle exec cap main provision:test_task' )
  #cmd = %Q(cd /mount/ansible/provisioner && bundle exec cap main provision:test_task )
  #cmd = 'cd /mount/ansible/provisioner && bundle exec cap -v'

  if cmd.is_a? Array
    a_cmd = cmd
  else
    a_cmd = [cmd]
  end

  output = ""
  ih = _interaction_handler
  ih ||= interaction_handler_pwd(ssh_options[:user], pwd)

  SSHKit::Coordinator.new(host).each in: :sequence do
    #output = capture cmd
    a_cmd.each do |q|
      output << capture(q)
      #execute(q, interaction_handler: SSHKit::MappingInteractionHandler.new({}, :info))
      #execute(q, interaction_handler: ih)
    end
  end

  #
  return {res: 1, output: output}

rescue => e
  {
      res: 0,
      output: ". error: "+e.message,
  }
end




def interaction_handler_pwd(user, pwd, host='')
  {
      "#{user}@#{host}'s password:" => "#{pwd}\n",
      /#{user}@#{host}'s password: */ => "#{pwd}\n",
      "password: " => "#{pwd}\n",
      "password:" => "#{pwd}\n",
      "Password: " => "#{pwd}\n",
  }
end



ssh_user = 'root'
srv_ip = '51.0.0.55'
ssh_port = 22
ssh_pass = 'PH_GEX_PASSWD1'

cmd = 'cd /mount/ansible/provisioner && bundle exec cap -v'

ssh_options = {user: ssh_user, hostname: srv_ip, port: ssh_port, pwd: ssh_pass}

res = run_ssh_cmd(ssh_options, cmd)


puts "res: #{res}"
