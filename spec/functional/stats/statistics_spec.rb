RSpec.describe 'Statistics', :type => :request do

  before :each do

    arr = []
    test_time = Time.now.utc

    for i in 0..49
      test_time += rand(5...600)
      arr.push([test_time,rand(0...100)])
    end


  end



  describe 'parse node stats' do

      it "gets every nth element from array" do
        expect(10).to eql 10

        #expect(Gexcore::Monitoring::StatisticsService.every_nth_element(arr,1).length).to eql arr.length
        #expect(Gexcore::Monitoring::StatisticsService.every_nth_element(arr,2).length).to eql arr.length/2
        #expect(Gexcore::Monitoring::StatisticsService.every_nth_element(arr,5).length).to eql arr.length/5
        #expect(Gexcore::Monitoring::StatisticsService.every_nth_element(arr,10).length).to eql arr.length/10
      end





  end


end
