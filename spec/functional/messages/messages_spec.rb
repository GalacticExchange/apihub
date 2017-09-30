RSpec.describe "Messages", :type => :request do

  before :each do
    @lib = Gexcore::MessagesService

    # users
    stub_create_user_all

  end

  describe 'send message' do
    before :each do
      #
      stub_create_user_all

      #
      @user1 = create_user_active
      @user2 = create_user_active

      @msg = Gexcore::Common.random_string_digits(120)
    end

    after :each do
      Timecop.return
    end

    it 'ok' do
      res = @lib.add_message(@user1.id, @user2.id, @msg)

      #
      expect(res.success?).to eq true
    end

    it 'add row to messages' do

      expect {
        @lib.add_message(@user1.id, @user2.id, @msg)
      }.to change{Message.count}.by(1)

    end

    it 'row in DB' do

      @lib.add_message(@user1.id, @user2.id, @msg)

      #
      row = Message.where(from_user_id: @user1.id).first

      expect(row.to_user_id).to eq @user2.id
      expect(row.message).to eq @msg
      expect(row.dialog_id).to be >0
      expect(row.status).to eq Message::STATUS_ACTIVE

    end

    it 'creates dialog in DB' do
      expect {
        @lib.add_message(@user1.id, @user2.id, @msg)
      }.to change{MessageDialog.count}.by(1)

      # data - dialog
      dialog = MessageDialog.where(from_user_id: @user1.id).first

      expect(dialog.to_user_id).to eq @user2.id


    end

    it 'do not create dialog if dialog exists' do
      #
      @lib.add_message(@user1.id, @user2.id, @msg)
      @lib.add_message(@user2.id, @user1.id, @msg+'2')

      expect {
        @lib.add_message(@user1.id, @user2.id, @msg)
      }.to change{MessageDialog.count}.by(0)

    end

    it 'set dialog_id' do
      #
      @lib.add_message(@user1.id, @user2.id, @msg)
      @lib.add_message(@user2.id, @user1.id, @msg+'2')

      # work
      @lib.add_message(@user1.id, @user2.id, @msg)

      #
      msg = Message.where(from_user_id: @user1.id).order('id desc').first
      dialog = MessageDialog.get_by_users(@user1.id, @user2.id)

      expect(msg.dialog_id).to eq dialog.id


    end

    it 'update dialog' do
      #
      now1 = Time.now.utc
      Timecop.freeze(now1)

      #
      @lib.add_message(@user1.id, @user2.id, @msg)

      dialog = MessageDialog.get_by_users @user1.id, @user2.id
      #updated1 = dialog.updated_at

      #
      t2 = (5.minutes).since(now1)
      Timecop.freeze(t2)

      # work
      @lib.add_message(@user2.id, @user1.id, @msg)

      # check
      #Timecop.return
      #sleep(5)

      #
      dialog.reload

      # check
      #expect(dialog.updated_at.to_f - Time.now.utc.to_f).to be < 1
      expect(dialog.updated_at.to_f).to be > t2.to_f-1


    end

    it 'set dialog.last_message_id' do
      # work
      res = @lib.add_message(@user1.id, @user2.id, @msg)

      # data
      msg = Message.find(res.sysdata[:message_id])
      dialog = MessageDialog.get_by_users @user1.id, @user2.id

      # check
      expect(dialog.last_message_id).to eql msg.id

      # add new message
      res = @lib.add_message(@user2.id, @user1.id, @msg+'1')

      #
      msg2 = Message.find(res.sysdata[:message_id])
      dialog.reload

      # check
      expect(dialog.last_message_id).to eql msg2.id

    end

    it 'update counters' do
      # current state
      n_user1_0 = @lib.get_unread_count_user(@user1.id)
      n_user1_dialog_0 = 0

      n_user2_0 = @lib.get_unread_count_user(@user2.id)
      n_user2_dialog_0 = 0

      # work
      @lib.add_message(@user1.id, @user2.id, @msg)

      #
      dialog = @lib.get_dialog_by_users @user1.id, @user2.id

      # counters for user1
      expect(@lib.get_unread_count_user(@user1.id)).to eq n_user1_0
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog.id)).to eq n_user1_dialog_0

      # counters for user2
      expect(@lib.get_unread_count_user(@user2.id)).to eq n_user2_0+1
      expect(@lib.get_unread_count_in_dialog(@user2.id, dialog.id)).to eq n_user2_dialog_0+1
    end

    it 'update counters' do
      #
      @lib.add_message(@user1.id, @user2.id, @msg)
      @lib.add_message(@user2.id, @user1.id, @msg+'2')

      dialog = MessageDialog.get_by_users @user1.id, @user2.id

      # current state
      n_user1_0 = @lib.get_unread_count_user(@user1.id)
      n_user1_dialog_0 = @lib.get_unread_count_in_dialog(@user1.id, dialog.id)

      n_user2_0 = @lib.get_unread_count_user(@user2.id)
      n_user2_dialog_0 = @lib.get_unread_count_in_dialog(@user2.id, dialog.id)

      # work
      @lib.add_message(@user2.id, @user1.id, @msg)

      # counters for user1
      expect(@lib.get_unread_count_user(@user1.id)).to eq n_user1_0+1
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog.id)).to eq n_user1_dialog_0+1

      # counters for user2
      expect(@lib.get_unread_count_user(@user2.id)).to eq n_user2_0
      expect(@lib.get_unread_count_in_dialog(@user2.id, dialog.id)).to eq n_user2_dialog_0

    end

    it 'update counters in dialog after add message' do
      #
      @lib.add_message(@user2.id, @user1.id, @msg)
      #@lib.add_message(@user2.id, @user1.id, @msg+'2')

      #
      dialog = MessageDialog.get_by_users @user1.id, @user2.id

      #
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog.id)).to eq 1
      expect(@lib.get_unread_count_in_dialog(@user2.id, dialog.id)).to eq 0

    end

    it 'update counters in dialog after add message - v2' do
      #
      @lib.add_message(@user1.id, @user2.id, @msg)

      #
      dialog = MessageDialog.get_by_users @user1.id, @user2.id

      #
      expect(@lib.get_unread_count_in_dialog(@user2.id, dialog.id)).to eq 1
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog.id)).to eq 0

    end

    it 'update counters in dialog after read messages in dialog' do
      #
      @lib.add_message(@user2.id, @user1.id, @msg)
      #@lib.add_message(@user1.id, @user2.id, @msg+'2')

      dialog = MessageDialog.get_by_users @user1.id, @user2.id

      # before
      user2_n0 = @lib.get_unread_count_in_dialog(@user2.id, dialog.id)

      # user1 read dialog
      messages = @lib.get_messages_in_dialog(@user1.id, dialog.id)


      # checks

      # check. no new messages for user1
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog.id)).to eq 0

      # check. do not change unread messages for user2
      expect(@lib.get_unread_count_in_dialog(@user2.id, dialog.id)).to eq user2_n0

    end

  end


  describe 'list messages in dialog' do
    before :each do
      #
      stub_create_user_all

      # users
      @user1 = create_user_active
      @user2 = create_user_active
      @user3 = create_user_active

      #
      @msg = Gexcore::Common.random_string_digits(120)



      # dialog1
      @lib.add_message(@user1.id, @user2.id, @msg+'1')
      @lib.add_message(@user2.id, @user1.id, @msg+'2')
      @lib.add_message(@user1.id, @user2.id, @msg+'3')

      @dialog1 = MessageDialog.get_by_users @user1.id, @user2.id

      # dialog2
      @lib.add_message(@user3.id, @user1.id, @msg+'311')
      @lib.add_message(@user1.id, @user3.id, @msg+'32')
      @lib.add_message(@user3.id, @user1.id, @msg+'333')
      @lib.add_message(@user3.id, @user1.id, @msg+'333')

      @dialog2 = MessageDialog.get_by_users @user1.id, @user3.id

    end

    it 'list messages in the dialog' do
      rows = @lib.get_messages_in_dialog(@user1.id, @dialog1.id)

      # check
      rows.each do |msg|
        expect(msg.dialog_id).to eq @dialog1.id
      end

      expect(rows.count).to eq 3


    end

    describe 'update counters' do
      it 'counters' do
        # current state
        n_user1_0 = @lib.get_unread_count_user(@user1.id)
        n_user1_dialog1_0 = @lib.get_unread_count_in_dialog(@user1.id, @dialog1.id)

        n_user2_0 = @lib.get_unread_count_user(@user2.id)
        n_user2_dialog1_0 = @lib.get_unread_count_in_dialog(@user2.id, @dialog1.id)


        # work
        rows = @lib.get_messages_in_dialog(@user1.id, @dialog1.id)


        # counters for user1
        expect(@lib.get_unread_count_in_dialog(@user1.id, @dialog1.id)).to eq 0
        expect(@lib.get_unread_count_user(@user1.id)).to eq (n_user1_0 - n_user1_dialog1_0)

        # counters for user2
        expect(@lib.get_unread_count_user(@user2.id)).to eq n_user2_0
        expect(@lib.get_unread_count_in_dialog(@user2.id, @dialog1.id)).to eq n_user2_dialog1_0

      end
    end


  end

  describe 'list messages for user' do
    before :each do
      # users
      stub_create_user_all

      #
      @user1 = create_user_active
      @user2 = create_user_active
      @user3 = create_user_active

      #
      @msg = Gexcore::Common.random_string_digits(120)
    end

    it 'read messages' do
      # add more messages
      @lib.add_message(@user1.id, @user2.id, @msg+'21')
      @lib.add_message(@user2.id, @user1.id, @msg+'22')
      @lib.add_message(@user2.id, @user1.id, @msg+'22')

      @lib.add_message(@user3.id, @user1.id, @msg+'22')

      # read messages for user1
      rows = @lib.get_messages_for_user(@user1.id)

      rows.each do |msg|
        expect((msg.to_user_id==@user1.id || msg.from_user_id==@user1.id)).to eq true
      end

      # add another message for user1
      @lib.add_message(@user3.id, @user1.id, @msg+'31')
      rows = @lib.get_messages_for_user(@user1.id)

      msg = rows[0]
      expect((msg.to_user_id==@user3.id || msg.from_user_id==@user3.id)).to eq true

    end
  end

  describe 'list dialogs' do

    before :each do
      #
      @user1 = create_user_active
      @user2 = create_user_active
      @user3 = create_user_active

      #411
      @msg = Gexcore::Common.random_string_digits(120)



      # dialog1
      @lib.add_message(@user1.id, @user2.id, @msg+'1')
      @lib.add_message(@user2.id, @user1.id, @msg+'2')
      @lib.add_message(@user1.id, @user2.id, @msg+'3')

      @dialog1 = MessageDialog.get_by_users @user1.id, @user2.id

      # dialog2
      @lib.add_message(@user3.id, @user1.id, @msg+'311')
      @lib.add_message(@user1.id, @user3.id, @msg+'32')
      @lib.add_message(@user3.id, @user1.id, @msg+'333')
      @lib.add_message(@user3.id, @user1.id, @msg+'333')

      @dialog2 = MessageDialog.get_by_users @user1.id, @user3.id


    end


    it 'for user' do
      #
      rows = @lib.list_dialogs_for_user @user1.id

      #
      good_ids = [@dialog1.id, @dialog2.id]

      rows.each do |row|
        expect(good_ids).to include row.id
      end


    end

    it '2 for user' do
      #
      rows = @lib.list_dialogs_for_user @user2.id

      #
      good_ids = [@dialog1.id]

      rows.each do |row|
        expect(good_ids).to include row.id
      end
    end

    it '3 for user' do
      #
      rows = @lib.list_dialogs_for_user @user3.id

      #
      good_ids = [@dialog2.id]

      rows.each do |row|
        expect(good_ids).to include row.id
      end
    end

    it 'order dialogs' do
      # user2 sends message
      @lib.add_message(@user2.id, @user1.id, @msg+'1')

      # dialog 1 should be on top
      rows = @lib.list_dialogs_for_user @user1.id

      expect(rows[0].id).to eq @dialog1.id

      # wait a little
      Timecop.travel(Time.now + 5.seconds)



      # user3 sends message
      @lib.add_message(@user3.id, @user1.id, @msg+'3')

      # dialog 1 should be on top
      rows = @lib.list_dialogs_for_user @user1.id

      expect(rows[0].id).to eq @dialog2.id

    end

  end

  describe 'dialog info' do

    before :each do
      #
      @user1 = create_user_active
      @user2 = create_user_active

      #
      @msg = Gexcore::Common.random_string_digits(120)


      # dialog1
      @lib.add_message(@user1.id, @user2.id, @msg+'1')
      @lib.add_message(@user2.id, @user1.id, @msg+'2')

      @dialog1 = MessageDialog.get_by_users @user1.id, @user2.id

    end


    it 'for user' do
      #
      res = @lib.get_dialog_info_for_user @user1, @user2

      data = res.data

      #
      row = data[:dialog]

      expect(row[:user][:username]).to eq @user2.username
      expect(row[:lastMessageDate]).to be_truthy

    end

  end


  describe 'big test' do
    before :each do
      # users
      stub_create_user_all

      #
      @user1 = create_user_active
      @user2 = create_user_active
      @user3 = create_user_active
      @user4 = create_user_active

      #
      @msg = Gexcore::Common.random_string_digits(120)
    end




    it 'dialogs - counters' do

      # dialog1
      expect(@lib.get_unread_count_user(@user1.id)).to eq 0

      # 1->2
      @lib.add_message(@user1.id, @user2.id, @msg+'1')

      dialog1 = @lib.get_dialog_by_users @user1.id, @user2.id

      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog1.id)).to eq 0
      expect(@lib.get_unread_count_in_dialog(@user2.id, dialog1.id)).to eq 1

      # 2 -> 1
      @lib.add_message(@user2.id, @user1.id, @msg+'2')

      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog1.id)).to eq 1
      expect(@lib.get_unread_count_in_dialog(@user2.id, dialog1.id)).to eq 1

      # user 2 read dialog
      @lib.get_messages_in_dialog @user2.id, dialog1.id

      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog1.id)).to eq 1
      expect(@lib.get_unread_count_in_dialog(@user2.id, dialog1.id)).to eq 0



    end


    it 'big test - messages to the user from multiple users' do
      # dialog1
      expect(@lib.get_unread_count_user(@user1.id)).to eq 0

      # 2->1
      @lib.add_message(@user2.id, @user1.id, @msg+'2')

      # 3->1
      @lib.add_message(@user3.id, @user1.id, @msg+'3')
      @lib.add_message(@user3.id, @user1.id, @msg+'3b')

      # 4->1
      @lib.add_message(@user4.id, @user1.id, @msg+'1')

      # dialogs
      dialog2 = @lib.get_dialog_by_users @user1.id, @user2.id
      dialog3 = @lib.get_dialog_by_users @user1.id, @user3.id
      dialog4 = @lib.get_dialog_by_users @user1.id, @user4.id

      # check from user1
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog2.id)).to eq 1
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog3.id)).to eq 2
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog4.id)).to eq 1


      # user1 read messages from dialog2
      @lib.get_messages_in_dialog @user1.id, dialog2.id

      # check
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog2.id)).to eq 0
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog3.id)).to eq 2
      expect(@lib.get_unread_count_in_dialog(@user1.id, dialog4.id)).to eq 1


    end
  end


end
