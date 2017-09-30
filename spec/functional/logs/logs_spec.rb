RSpec.describe "Logs", :type => :request do

  describe 'add log' do

  end

  describe "Aliases" do
    before :each do
    end

    it 'alias - fatal' do
      level = 'fatal'

      expect(Gexcore::GexLogger.level_base_name(level)).to eq 'critical'
    end
  end


end

