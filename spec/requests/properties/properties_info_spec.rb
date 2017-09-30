RSpec.describe "properties info", :type => :request do

  describe 'get properties info' do

    before :each do

      Option.destroy_all
      @name = "anyname"+Gexcore::Common.random_string(12)
      Gexcore::OptionService.cache_del_option(@name)

    end

    after :each do
      Option.destroy_all
    end

    it "OK" do

      v = "yamahal"

      # stub get from DB
      opt_row = double(Option, :option_type=>'string')
      allow(Option).to receive(:get).and_return v
      allow(Option).to receive(:get_by_name).and_return opt_row

      #
      get_json '/properties', {name: @name}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp_data[@name]).to eq v
    end


    it 'api_version' do

      #
      name = "api_version"

      # del all cache
      Gexcore::OptionService.cache_del_all

      #
      get_json '/properties', {name: name}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp_data[name]).to eq Gexcore::Settings::VERSION

    end

    it "not existing option" do

      #
      get_json '/properties', {name: @name}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      expect(resp.status).to eq 404

    end


    it 'adds to cache' do

      v = "yamahal"

      # stub for class method - stub get from DB
      allow(Option)
          .to receive(:get)
                  .and_return v

      #
      get_json '/properties', {name: @name}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      # check cache
      v_cache = Gexcore::OptionService.cache_get_option(@name)
      expect(v_cache).to eq v

    end

    it 'do not set to cache after creation in DB' do

      v = "yamahal_one"
      v1 = "yamahal_two"

      # set option like admin in cms
      obj = Option.new
      obj.name = @name
      obj.title = @name
      obj.value = v
      obj.save

      # set same option new value like admin in cms
      obj.value = v1
      obj.save

      # check cache
      v_cache = Gexcore::OptionService.cache_get_option(@name)
      expect(v_cache).to eq nil

      # clean after
      obj.destroy

    end


    it 'get new value after changes in DB' do

      v = "yamahal_one"
      v1 = "yamahal_two"

      # check callbacks for Class
      call = Option._save_callbacks.select {|cb| cb.kind == :after}

      # set option like admin in cms
      obj = Option.new
      obj.name = @name
      obj.title = @name
      obj.value = v
      obj.save

      #
      get_json '/properties', {name: @name}, {}

      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp_data[@name]).to eq v


      # set same option new value like admin in cms
      obj.value = v1
      obj.save

      #
      get_json '/properties', {name: @name}, {}
      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp_data[@name]).to eq v1

      # check cache
      #v_cache = Gexcore::OptionService.cache_get_option(name)
      #expect(v_cache).to eq v1
      obj.destroy

    end

  end
end
