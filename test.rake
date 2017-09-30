namespace :test do
  task :me do

    p Rails.env
    p Rails.configuration.database_configuration[Rails.env]

  end
end