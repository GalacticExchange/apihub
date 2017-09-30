# TODO: NOT WORKING

RSpec.describe "Files", :type => :request do

  describe "Files for node_install" do
    before :each do
      @for = :node_install
      @lib = Gexcore::FilesService
    end

    it 'list files for node' do
      files = @lib.list(@cluster, @for, {:node_number=>1})

      expect(files.size).to be > 0
    end

  end
end

