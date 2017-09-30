module Gexcore::Clusters::Onprem
  class Service < Gexcore::BaseService
    def self.validate_create_cluster_data(user,options)
      begin

      rescue =>e
        return res.set_error("cluster_invalid", "Bad cluster options", "exception: #{e.message}")
      end

      Response.res_data
    end

  end
end

