module Gexcore::Monitoring::Checks

  class DockerContainerRunning < ::Gexcore::Monitoring::Checks::Result

    def build_from_data(data, check_info, env={})
      if data.nil?
        set_failed
        return true
      end

      @value = self.class.get_value_from_data(data, env)

      #
      if @value.nil?
        set_failed
        return true
      end

      #
      @passed = @value > 0

      true
    end


    # get value from data

    def self.get_value_from_data(data, env={})
      container = env[:container]

      output = parse_output(data, env)

      return nil if output.nil? || output['containers'].nil? || output['containers'][container.docker_container_name].nil?

      v = output['containers'][container.docker_container_name]['memory_stats']['usage']

      v
    end


  end
end
