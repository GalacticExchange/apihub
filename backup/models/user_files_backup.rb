# encoding: utf-8

###


Model.new(:user_files_backup, 'App files') do

  archive :files do |archive|
    # follow symlinks
    #https://github.com/backup/backup/issues/169

    archive.tar_options '-h'

    #
    dir_app = $app_config[:path]


    #archive.add "#{dir_app}"

    in_dirs = ($backup_config['backup']['user_files']['include'] rescue []) || []

    ignore_dirs = %w[.idea .git .vagrant .ansible .chef]
    ex_dirs_base = %w[tmp log  ]
    ex_dirs = ($backup_config['backup']['user_files']['exclude'] rescue []) || []

    (in_dirs).each do |d|
      dpath = (d=~ /^\//) ? d : "#{dir_app}#{d}"
      archive.add dpath
    end

    (ignore_dirs+ex_dirs_base+ex_dirs).each do |d|
      dpath = (d=~ /^\//) ? d : "#{dir_app}#{d}"
      archive.exclude dpath
    end

  end





  #### Storages

  #setup_storages


  $backup_config['storages'].each do |b|
    if b['type']=='scp'
      store_with SCP do |server|
        build_storage_scp(server, b)
      end

    elsif b['type']=='s3'
      ##
      # Store on Amazon S3
      #
      store_with S3 do |s3|
        build_storage_s3(s3, b)
      end

    elsif b['type']=='local'
      ##
      # Local (Copy)
      #
      store_with Local do |local|
        build_storage_local(local, b)
      end
    end
  end



  ##
  # Gzip [Compressor]
  #
  compress_with Gzip



  ### notify

  notify_by Mail do |mail|
    c = $smtp_config


  end

end
