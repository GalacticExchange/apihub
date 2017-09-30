RSpec.describe "Remember", :type => :feature do
  describe "Cookies" do

    before :each do
      #
      stub_create_user_all
      stub_create_cluster_all

      @user_hash = build_user_hash
      #@user = create_user_active_and_create_cluster(@user_hash)

      # run test server before
      # run on existing server
      Capybara.app_host = 'http://localhost:3011'

    end




    after :each do

    end

    it 'token in cookies' do
      # debug
      @user = User.get_by_username('test000')
      @user_hash[:username] = 'test000'
      @user_hash[:password] = 'pwdienegvol'

      #
      expect(@user.active?).to eq true

      # visit link in browser
      visit '/signin'

      expect(page).to have_css 'form#new_user'

      # fill form
      puts "111111"
      #chk = find('input#user_remember_me', {wait: 1}) rescue nil
      #chk = find_by_id('user_remember_me', {wait: 1, unchecked: true}) rescue nil
      chk = find_field('user_remember_me', {wait: 1, visible: false}) rescue nil
      #chk = field_labeled("Remember me", {wait: 1}) rescue nil
      #chk = find_field('user_remember_me', {wait: 1}) rescue nil
      #chk = find_by_id('new_user', {wait: 1}) rescue nil
      if chk
        puts "chck: #{chk['name']}, #{chk['class']}"

        chk.click
      else
        raise 'cannot find checkbox'
      end



      puts "222"
      f = find('form#new_user')


      fields = f.all('input', {visible: false})
      fields.each do |ff|
        puts "chck: #{ff['name']}, id: #{ff['id']}, #{ff['class']}"
      end

      f.fill_in 'user_login', :with => @user_hash[:username]
      f.fill_in 'user_password', :with => @user_hash[:password]

      #page.check("Remember me", {wait: 1})

      f.find('input[type=submit]').click

      #
      #expect(current_path).to match /signin/
      expect(current_path).to match /statistics/

      # check
      token = page.driver.browser.manage.cookie_named('token')
      remember_token = page.driver.browser.manage.cookie_named('remember_user_token')

      if token
        puts "cookies token: #{token[:value]}"
      end

      if remember_token
        puts "cookies remember token: #{remember_token}"
      end

      expect(remember_token).to be_truthy
      expect(remember_token[:value]).to be_truthy



      x = 0
      # close browser
      Capybara.reset_sessions!


      # check
      puts "after close"

      #
      visit '/'

      # set remember cookie
      page.driver.browser.manage.add_cookie(remember_token)

      # Refresh the domain to activate the cookies
      visit('/')


      remember_token = page.driver.browser.manage.cookie_named('remember_user_token')

      if remember_token
        puts "cookies remember token: #{remember_token}"
      end

      expect(remember_token).to be_truthy


      # visit page
      visit('/statistics')

      # token should be set
      token = page.driver.browser.manage.cookie_named('token')
      if token
        puts "cookies token: #{token[:value]}"
      end

      expect(token).to be_truthy


    end

  end
end
