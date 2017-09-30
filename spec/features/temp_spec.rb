describe "home page", :type => :feature do
  before :each do

  end

  it "open home page" do
    visit '/'

    #within("#session") do
    #  fill_in 'Email', :with => 'user@example.com'
    #  fill_in 'Password', :with => 'password'
    #end
    #click_button 'Sign in'

    expect(page).to have_content 'See our Demo'
  end
end
