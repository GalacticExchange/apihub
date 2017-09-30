namespace :install do
  desc "change admin user"
  task :change_admin_pwd => :environment do
    email = 'admin@example.com'
    row = Optimacms::CmsAdminUser.where(email: email).first || Optimacms::CmsAdminUser.new

    row.email = email
    row.password = ENV['pwd']
    row.password_confirmation = row.password
    #row.skip_confirmation!

    row.save!
  end


  desc "create support_user"
  task :create_support_user => :environment do
    Services::InstallService.create_support_user
  end

  desc 'init db. Import DB'
  task :init_db => :environment do
    #ActiveRecord::Base.connection.execute(IO.read("db-init/gex.sql"))

    # gex.sql
    script = Rails.root.join("db-init").join("gex.sql.gz").read

    # this needs to match the delimiter of your queries
    statements = script.split /;$/

    ActiveRecord::Base.transaction do
      statements.each do |stmt|
        s = stmt.strip
        #puts "s='#{s}'"

        next if stmt.blank?
        ActiveRecord::Base.connection.execute(stmt)
      end
    end



  end

  desc 'init db_logs. Import DB'
  task :init_db_logs => :environment do
    # gex_logs
    script = Rails.root.join("db-init").join("gex_logs.sql.gz").read

    # this needs to match the delimiter of your queries
    statements = script.split /;$/

    Gexcore::LogDatabase.transaction do
      statements.each do |stmt|
        s = stmt.strip
        puts "s='#{s}'"

        next if stmt.blank?
        Gexcore::LogDatabase.connection.execute(stmt)
      end
    end

  end

  desc 'init app. ES reindex, get data'
  task :init => :environment do
    # Update options
    Maintenance::Maintenance.set_options


    # ES reindex
    Maintenance::Maintenance.es_import_index
    Maintenance::Maintenance.es_import_library_apps

    Maintenance::Maintenance.es_import_log


    # prepare data
    Maintenance::Maintenance.update_ansible_dir

    # restart server
    system("touch tmp/restart.txt")


  end


end
