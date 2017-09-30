module Gexcore::Dashboards
  class Service < Gexcore::BaseService

    def self.load_dashboard(row)
      f = filename_dashboard(row.cluster, row.name)

      data =YAML.load_file(f)

      data
    end

    ###


    def self.base_dir_dashboards
      File.join(Rails.root, "data/dashboards")
    end

    def self.filename_dashboard(cluster, name)
      File.join(base_dir_dashboards, "#{cluster.id}", "#{name}.yml")
    end

    def self.filename(dashboard)
      File.join(base_dir_dashboards, "#{dashboard.cluster_id}", "#{dashboard.name}.yml")
    end
  end
end

