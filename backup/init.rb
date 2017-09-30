$app_env = ENV['RAILS_ENV'] || ENV['server_env'] || ENV['app_env'] || 'development'
$rails_app_env = $app_env



root = File.absolute_path(File.dirname(__FILE__))
current_dir = File.dirname(__FILE__)

#
#$backup_config  = YAML.load_file(File.join(current_dir, 'config', "#{$app_env}.yml"))
#$backup_config  = YAML.load_file(File.join(Rails.root, 'config', 'backup', "#{$app_env}.yml"))
$backup_config  = YAML.load_file(File.join(current_dir, '../config/backup', "#{$app_env}.yml"))
#$backup_config  = OptimacmsBackups.backups_config

puts "backup_config: #{$backup_config}"

# config - app
app_path = File.expand_path("../../", __FILE__)+'/'

$app_config = {
    path: app_path
}

puts "app config: #{$app_config}"

#
app_rails_secrets = YAML.load_file("#{$app_config[:path]}config/secrets.yml")[$rails_app_env]

# db
$db_config  = app_rails_secrets

#puts "db: #{$db_config}"


# smtp
$smtp_config = app_rails_secrets['smtp']




### helpers

def build_storage_local(local, options)
  b = options

  local.path       = "#{b['path']}"
  local.keep       = 7
  # local.keep       = Time.now - 2592000 # Remove all backups older than 1 month.
end

def build_storage_scp(server, opts)
  b = opts

  server.username = b['username']
  server.password = b['password']
  server.ip       = b['ip']
  server.port     = b['port']
  server.path     = b['path']

  # Use a number or a Time object to specify how many backups to keep.
  server.keep     = 30

  # Additional options for the SSH connection.
  # server.ssh_options = {}

end


def build_storage_s3(s3, opts)
  b = opts

  s3_config = $backup_config['s3']
  s3.access_key_id = b['access_key_id'] || s3_config['access_key_id']
  s3.secret_access_key = b['secret_access_key'] || s3_config['secret_access_key']
  s3.region = b['region'] || s3_config['region']
  s3.bucket = b['bucket'] || s3_config['bucket']
  s3.path = b['path'] || s3_config['path']

  s3.keep              = 30
end
