RSpec.describe "Delete cluster", :type => :request do

  describe 'uninstall' do

    before :each do
      #
      stub_create_user_all
      stub_create_cluster_all

      # create user
      @user, @cluster = create_user_active_and_create_cluster
      @team = @user.team


    end

    after :each do

    end

    describe 'Clusters::Service.delete_cluster' do

      before :each do
      end


      it 'ok - response' do
        # work
        res = Gexcore::Clusters::Service.delete_cluster(@cluster)

        # check
        expect(res.success?).to eq true
      end


      it 'status' do
        # work
        res = Gexcore::Clusters::Service.delete_cluster(@cluster)

        # check
        @cluster.reload
        expect(@cluster.status).to eq 'removed'
      end

      it 'uninstall applications' do
        # work
        res = Gexcore::Clusters::Service.delete_cluster(@cluster)

        # check
        cluster = Cluster.get_by_uid(@cluster.uid)

        cluster.applications.each do |app|
          expect(app.status).to eq 'removed'

          app.containers.each do |cont|
            expect(cont.status).to eq 'removed'
          end
        end


      end



      context 'Hadoop' do

        it 'uninstall Hadoop app' do
          expect(Gexcore::AppHadoop::App).to receive(:uninstall)

          # work
          res = Gexcore::Clusters::Service.delete_cluster(@cluster)


        end

        it 'uninstall Hadoop app params' do
          allow(Gexcore::AppHadoop::App).to receive(:uninstall) do |obj, res, app|
            expect(app.name).to eq 'hadoop_cdh'

          end

          # work
          res = Gexcore::Clusters::Service.delete_cluster(@cluster)


        end


        it 'calls provision remove_cluster' do
          # stub
          allow(Gexcore::Provision::Service).to receive(:run) do |task_name, cmd|
            puts "cmd: #{cmd}"
            expect(task_name).to eq 'remove_cluster'

            #
            expect(cmd).to match /provision:remove_cluster/

            #
            expect(cmd_contains_param(cmd, '_cluster_id', @cluster.id)).to eq true
            expect(cmd_contains_param(cmd, '_cluster_type', @cluster.cluster_type_name)).to eq true

          end.and_return(Gexcore::Response.res_data)


          # work
          res = Gexcore::Clusters::Service.delete_cluster(@cluster)


        end
      end



    end



  end
end


