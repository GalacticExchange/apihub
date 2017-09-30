module Gexcore::Monitoring::Sensu

  class CounterDataParser

    def self.get_ts_from_counter_data(counter_data)
      begin
        if counter_data['check']
          sd = counter_data['check']['executed']
        elsif counter_data['executed']
          sd = counter_data['executed']
        end

      rescue => e
        return nil
      end

      return nil if sd.nil?

      res = sd.to_i

      res
    end

    def self.get_date_from_counter_data(counter_data)
      d = nil
      begin
        sd = get_ts_from_counter_data(counter_data)

        d = Time.at(sd.to_i).utc.to_datetime
        return nil if d.nil?
      rescue => e
        return nil
      end

      d
    end


    def self.parse_hdd_line(output, name)
      v = nil
      #
      lines = output.split(/\n/)

      # disk_usage.root.used 64823 1474381222
      #name = 'disk_usage\.root\.used'
      ss = name.gsub /\./, '\\.'

      lines.each do |s|
        next unless s =~ /^#{ss} +.*$/

        s =~ /^#{name} +(\d+) +/
        v = $1

        break
      end

      (v.to_i rescue nil)
    end



  end
end

