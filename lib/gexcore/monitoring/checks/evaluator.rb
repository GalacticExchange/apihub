module Gexcore::Monitoring::Checks

  class Evaluator

    def self.parse_counter_line(output, name, skip_name=true)
      v = nil
      #
      lines = output.split(/\n/)

      reg_name = name.gsub /\./, '\\.'

      if skip_name
        reg = /^[^\.]+\.#{reg_name} +(.*)$/
      else
        reg = /^#{reg_name} +(.*)$/
      end

      lines.each do |s|
        next unless s =~ reg
        vv = $1
        vv =~ /^ *([\d\.]+) +/
        v = $1

        break
      end

      (v.to_i rescue nil)
    end


    def self.mb_to_gb(v)
      v = ((v.to_f / (1024)).round(3) rescue nil)

      v
    end
  end

end
