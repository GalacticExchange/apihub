module Gexcore::Monitoring

  class StatisticsService < ::Gexcore::BaseService

    # array example: [[utc_time_in_seconds,value],[utc_time_in_seconds,value],........]
    # all time variables is seconds


    #helpers
    def self.every_nth_element(arr,n)
      (0... arr.length).select{ |x| x%n == n-1 }.map { |y| arr[y] }
    end

    def self.period_filter(arr,period)

      newest_time = arr.last[0]
      time_point = newest_time - period

      arr.each.select{|i|  i[0] >= time_point}

    end



    def self.normalize_points(stats_arr,time_from,period,interval)

      return [false,nil] if stats_arr.nil?

      kafka_points = every_nth_element(stats_arr,1)
      timestamp = (time_from - (time_from % 60) -90) - period
      last_checked = 0
      res = []

      for i in 0..(period/interval)

        sum = 0
        number_of_points = 0

        for j in last_checked..kafka_points.length-1

          if kafka_points[j][0] >= timestamp && kafka_points[j][0] < timestamp+interval
            sum += kafka_points[j][1]
            number_of_points += 1
          end

          if kafka_points[j][0] > timestamp+interval
            last_checked = j
            break
          end


        end

        result_time = timestamp+interval/2

        if number_of_points != 0
          result_val = sum/number_of_points
          result_point  = [result_time,result_val.round(3)]
        else
          result_point = [result_time,nil]
        end

        timestamp += interval
        res.push(result_point)

      end

      res
    end


    def self.find_last_point(stats_arr, last_added_time, interval,all_metric)

      from_time = Integer(last_added_time)  + interval/2
      to_time = from_time + interval
      res_time = Integer(last_added_time) + interval
      sum = 0
      number_of_points = 0

      stats_arr.each do |point|
        if point[0] >= from_time && point[0] < to_time
          sum += point[1]
          number_of_points += 1
        end
      end

      [true,[all_metric,number_of_points != 0 ? sum/number_of_points : nil,Time.at(res_time)]]
    end




    ##### other
    def self.normalize_test

      # todo: write tests with sample data

      arr = []
      test_results = []
      test_time = Time.now.utc

      for i in 0..49
        test_time += rand(5...600)
        arr.push([test_time,rand(0...100)])
      end

      test_nth_arr1 = every_nth_element(arr,1)
      test_nth_arr2 = every_nth_element(arr,2)
      test_nth_arr3 = every_nth_element(arr,5)

      test_results.push(arr.length == test_nth_arr1.length && test_nth_arr2.length == arr.length/2 && test_nth_arr3.length == arr.length/5)

      #return [nth_ok]
    end



    def validate_result(arr)

      # todo: all data checks here

    end



  end
end
