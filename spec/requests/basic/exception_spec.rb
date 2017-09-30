RSpec.describe "Exception", :type => :request do

  it 'return 404' do
    get_json '/badbadpage', {}

    resp = last_response
    resp_data= JSON.parse(resp.body)

    expect(resp.status).to eq 404

  end
end

