module Gexcore
  class Common

    def self.random_string(n)
      (0...n).map { ('a'..'z').to_a[rand(26)] }.join
    end

    def self.random_string_digits(n)
      (0...n).map { ('0'..'9').to_a[rand(10)] }.join
    end



    def self.date_format(d)
      d.strftime("%Y-%m-%d %T")
    end

    def self.parse_date(s)
      require 'date'
      d = Date.parse(s) rescue nil

      d
    end

    def self.items_to_json(items, method_id, method_value)
      items.collect do |item|
        id = item.send(method_id)
        v = item.send(method_value)

        [id.to_s, v.to_s]
      end
    end

  end


end
