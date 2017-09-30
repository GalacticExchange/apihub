module UserFactoryHelpers
  def generate_name
    #'test_'+Gexcore::Common.random_string_digits(12)
    Faker::Name.first_name
  end

  def generate_teamname
    'team'+Gexcore::Common.random_string_digits(8)
  end

  def generate_username
    'test'+Gexcore::Common.random_string_digits(8)
  end

  def generate_email
    'test_'+Gexcore::Common.random_string_digits(8)+'@gmail.com'
  end

  def generate_pwd
    'pwd'+Gexcore::Common.random_string(8)
  end


  def generate_phone
    #'+1'+Faker::PhoneNumber.cell_phone
    # us phone
    #"+1(#{Faker::PhoneNumber.area_code}) #{Gexcore::Common.random_string_digits(7)}"
    #Faker::Base.numerify('+1 (###) ###-####')
    n = Faker::Base.numerify('####')
    #"+1 (415) 3205702"
    "+1 (415) 320#{n}"
  end

  def generate_phone_bad
    n = Faker::Base.numerify('####')
    "+380 (50) 533#{n}"
  end


  def generate_text
    'text '+Gexcore::Common.random_string_digits(8)
  end

  def build_user_fields_common()
    fields = {firstname: generate_name, lastname: generate_name, about: generate_name}
  end

  def build_user_hash(fields={})
    teamname =  generate_teamname
    username =  generate_username
    email =  generate_email

    #phone_number = fields[:phone_number] || generate_phone
    phone_number = fields[:phone_number] || Gexcore::Settings.TEST_PHONE_NUMBER

    password = generate_pwd
    if phone_number==Gexcore::Settings.TEST_PHONE_NUMBER
      password = Gexcore::Settings.TEST_USER_PWD
    end


    data = { username: username, email: email,
             password: password,
            phone_number: phone_number,
            teamname: teamname,
            team: {name: teamname}}

    #
    common_fields = build_user_fields_common
    #fields ||= common_fields
    common_fields.each do |k,v|
      next if fields.has_key?(k)
      fields[k] = common_fields[k]
    end
    fields.each{ |f, v| data[f]=v}
    data[:fields] = fields

    #puts "user data: #{data}"

    p = phone_number.dup
    if !Phoner::Phone.valid?(p)
      puts "ERROR: invalid phone #{phone_number}"

    end

    #
    data
  end

  def build_sysinfo
    sysinfo = JSON.parse(File.read('spec/data/sysinfo.txt'))
  end


  def build_user_create_post(user_hash, extra_fields={})
    sysinfo = build_sysinfo

    user_hash ||= build_user_hash

    postdata = {}

    [:teamname, :username, :email, :password, :phone_number].each do |s|
      postdata[s] = user_hash[s]
    end
    #teamname: user_hash[:teamname], username: user_hash[:username], email: user_hash[:email], password: user_hash[:password]}
    postdata = postdata.merge({firstName: user_hash[:firstname], lastName: user_hash[:lastname], about: user_hash[:about]})
    postdata = postdata.merge(sysinfo)

    #
    extra_fields.each do |f,v|
      if v.is_a?(TrueClass) || v.is_a?(FalseClass)
        postdata[f] = v ? 1 : 0
      else
        postdata[f] = v
      end

    end
    #
    postdata
  end


  ### Stub


  def stub_create_user_all
    # stub mailer
    allow_any_instance_of(ActionMailer::MessageDelivery)
        .to receive(:deliver_later)
                .and_return true

    # stub provision
    allow(Gexcore::Provision::Service).to receive(:run).and_return(Gexcore::Response.res_data)


    # stub registration
    allow(Gexcore::UsersCreationService).to receive(:is_test_mode_registration).and_return(true)

    # stub SMS
    allow(Gexcore::UsersCreationService).to receive(:send_password_sms)

  end



  ### create user helpers

  def create_user_active(user_hash=nil, registration_options={}, stub=true)
    if stub
      stub_create_user_all
    end

    #
    sysinfo = build_sysinfo
    user_hash ||= build_user_hash()
    user = Gexcore::UsersCreationService.build_user_from_params(user_hash)

    #
    res = Gexcore::UsersCreationService.create_user_active(user, sysinfo, registration_options, false, true)

    User.get_by_username user_hash[:username]
  end


  def create_user_active_and_create_cluster(user_hash=nil, registration_options={}, stub=true)
    if stub
      stub_create_user_all
      stub_create_cluster_all
    end

    #
    sysinfo = build_sysinfo

    user_hash ||= build_user_hash()

    user = Gexcore::UsersCreationService.build_user_from_params(user_hash)

    res = Gexcore::UsersCreationService.create_user_active(user, sysinfo, registration_options, false, true)

    user0 = User.get_by_username user.username

    # cluster
    cluster_options = Gexcore::Clusters::Service.build_cluster_options_from_user(user0)
    res_cluster = Gexcore::Clusters::Service.create_cluster(user0, sysinfo, cluster_options)

    cluster = Cluster.get_by_uid(res_cluster.data[:cluster][:id])

    # provision cluster
    Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(cluster.hadoop_app.id)

    cluster.reload


    #
    user = User.get_by_username user_hash[:username]

    [user, cluster]
  end



  def create_user_active_in_team(team_id, user_hash=nil)
    #
    sysinfo = build_sysinfo

    user_hash ||= build_user_hash
    user = Gexcore::UsersCreationService.build_user_from_params(user_hash)

    Gexcore::UsersCreationService.create_user_active_in_team(user, team_id, sysinfo, false, true)

    User.get_by_username user_hash[:username]
  end

  ###

  def create_user_active_and_add_share(cluster_id, teamname, user_hash=nil)
    sysinfo = build_sysinfo

    user_hash ||= build_user_hash
    user = Gexcore::UsersCreationService.build_user_from_params(user_hash)

    Gexcore::UsersCreationService.create_user_active_and_add_share(user, cluster_id, sysinfo)

    User.get_by_username user_hash[:username]
  end


  ####

  def stub_user_can_true
    allow_any_instance_of(User).to receive(:can?).and_return true
  end

  def stub_user_can_false
    allow_any_instance_of(User).to receive(:can?).and_return false
  end


  ### mail content

  def mail_get_verification_token_from_email(mail)
    # get link from email
    token = nil
    begin
      html = mail['parts'][0]['body']
      token = (/\/verify\/([a-z\d]+)\s+/.match(html).captures rescue nil)
    rescue => e
    end


    if token.is_a? Array
      token = token[0]
    end

    token
  end

  # get link from email
  def mail_get_resetpwd_token_from_email(mail)
    token = nil
    begin
      html = mail['parts'][0]['body']
      token = (/\/resetpassword\/([a-z\d]+)\s+/.match(html).captures rescue nil)
    rescue => e
    end

    if token.is_a? Array
      token = token[0]
    end

    token
  end

end
