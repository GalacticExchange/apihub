RSpec.describe "Update node", :type => :request do

  describe 'Update by NodeAgent' do
    describe 'debug' do

      it 'debug' do
        data = {
            nodeID: '1701339045094217',
            instanceID: "1f806f94-f028-4123-a849-91320ac5be54",
            nodeAgentToken: "51701300546443291",
            hostType: "dedicated",
            options: "{\"selected_interface\":null}"
        }
        headers ={

        }
        put_json '/gexd/nodes', data, headers

        #
        resp = last_response
        data = JSON.parse(resp.body)

        expect(resp.status).to eq 200

      end
    end
  end

end

