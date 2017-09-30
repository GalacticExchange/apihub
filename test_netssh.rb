require 'net/ssh'


host = '51.0.0.55'
ssh_user = 'root'
ssh_pass = 'PH_GEX_PASSWD1'


cmd = "touch /tmp/1.txt"
#cmd = 'ls -la'
#cmd = 'which ruby'


cmds = []
#cmds << %Q(source /etc/profile.d/rvm.sh)
cmds << %Q(rvm list)
#cmds << %Q(source /etc/profile.d/rvm.sh; bash -c 'rvm list')
#cmds << %Q(source /etc/profile.d/rvm.sh; which ruby)
#cmds << %Q(source /etc/profile.d/rvm.sh)
#cmds << %Q(cd /mount/ansible/provisioner && bundle exec cap -v)
#cmds << %Q(cd /mount/ansible/provisioner && bundle exec cap main provision:test_task)
cmd = cmds.join ";"


def ssh_exec!(ssh, command)
  stdout_data = ""
  stderr_data = ""
  exit_code = nil
  exit_signal = nil
  ssh.open_channel do |channel|
    channel.exec(command) do |ch, success|
      unless success
        abort "FAILED: couldn't execute command (ssh.channel.exec)"
      end
      channel.on_data do |ch,data|
        stdout_data+=data
      end

      channel.on_extended_data do |ch,type,data|
        stderr_data+=data
      end

      channel.on_request("exit-status") do |ch,data|
        exit_code = data.read_long
      end

      channel.on_request("exit-signal") do |ch, data|
        exit_signal = data.read_long
      end
    end
  end
  ssh.loop
  [stdout_data, stderr_data, exit_code, exit_signal]
end

res = 0
output = ''
stderr_data = ''
Net::SSH.start(host, ssh_user, :password => ssh_pass) do |ssh|
  #output, stderr_data, exit_code, exit_signal = ssh.exec!("#{cmd}")
  #res_cmd = ssh.exec!("#{cmd}")
  output, stderr_data, exit_code, exit_signal = ssh_exec!(ssh, cmd)

  if exit_code.to_i>0
    res = 0
  else
    res = 1
  end

end

res_res = {res: res, output: output+"; "+stderr_data}

puts "res: #{res_res}"


=begin
output = ""
status = nil

###
Net::SSH.start(host, ssh_user, :password => ssh_pass) do |ssh|
  output, stderr_data, exit_code, exit_signal = ssh.exec!("#{cmd}")

  output_lines = output.split /\n|\r\n/

  if exit_code.to_i>0 || output_lines.length==0
    status = 'error'
  else
    status = 'ok'
  end

end


puts "res: #{status}, output: #{output}"
=end
