describe "search", :type => :feature do
  describe 'search users' do
    it "list" do
      visit '/'

      within("form#search") do
        fill_in 'q', :with => 'm'
      end

      page.execute_script("$('form#search').submit()")

      expect(page).to have_content "Search user"
    end
  end


end
