module Gexcore
  class InstancesService < BaseService

    #### send invitation

    def self.add_instances(instance_id, version=nil, sysinfo=nil)
      res = Response.new
      res.sysdata[:instance_uid] = instance_id

      # input
      #return res.set_error_badinput("", 'version is empty', "") if version.nil? || version.blank?
      #return res.set_error_badinput("", 'sysinfo is empty', "") if sysinfo.nil? || sysinfo.blank?

      # add instance
      instance = Instance.add_row_to_db(instance_id, version, sysinfo)

      #
      res.set_data
    end

  end
end

