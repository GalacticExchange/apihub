module Gexcore
  class SystemTestService < BaseService

    def self.env_test
      env = Rails.env
      env = 'prod' if env=='production'

      env
    end

    def self.test_cluster_master(cluster)
      req = Gexcore::Provision::ShellRequest.new
      d = ENV['gex.tests_dir']

      cmd = %Q(cd #{d} && gex_env=#{env_test} cluster_id=#{cluster.id} gex_user=#{cluster.primary_admin.username} server=cluster_master server_user=#{ENV['GEX_SERVER_MASTER_USER']} server_pwd=#{ENV['GEX_SERVER_MASTER_PWD']} rake serverspec:cluster_master 2>&1)
      res_shell = req.run(cmd)

      res = Gexcore::Response.new

      # parse result
      res_shell[:total_examples] = 0
      res_shell[:total_failures] = 0

      #lines = res_shell[:output].lines
      res_shell[:output].each_line do |line|
        if line =~ /(\d*) examples?, (\d*) failures?/
          res_shell[:total_examples] = $1
          res_shell[:total_failures] = $2
        end
      end


      res.set_data(res_shell)
      res
    end
  end
end
