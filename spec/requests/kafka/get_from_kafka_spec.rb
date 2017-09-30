### SEE project tests/ spec/features/logs - tests here

RSpec.describe "kafka", :type => :request do
  describe "kafka get/post" do
    before :all do
      @msg_type = Gexcore::Common.random_string(20)
      @time_in_seconds = 4

      @kafka_server = "51.0.0.62"
      @kafka_port = "9092"
    end

    it "get custom message from kafka" do
      # post to kafka
      get "/debug/log_to_kafka", {msg_type: @msg_type}

      x = wait_log_event(@msg_type, @time_in_seconds)

      #
      expect(x).not_to be_nil

    end

  end
end
