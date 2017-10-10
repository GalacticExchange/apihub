source 'https://rubygems.org'

ruby "2.3.3"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.0.1'

# Use Puma as the app server
group :development, :test do
  gem 'puma', '3.7.1'
end


#
gem 'dotenv-rails', :require => 'dotenv/rails-now'


## for sidekiq UI
#gem 'sinatra', :require => nil


##
gem 'mysql2', '0.3.20'

# new 2017-may-03
gem 'net-ssh', '4.1.0'
gem 'sshkit', '1.11.1'
gem 'sshkit-sudo', '0.1.0'


# ok - 2017-may
=begin
gem 'net-ssh', '2.9.2'
gem 'httparty', '0.13.7'
gem 'sshkit', '1.11.1'
gem 'sshkit-sudo', '0.1.0'
=end

gem 'httparty', '0.13.7'
gem 'faraday', '0.9.2'


#gem 'globalize', '~>5.1.0', github: 'globalize/globalize'
gem 'globalize', '5.1.0.beta1'
gem 'activemodel-serializers-xml'
gem 'globalize-accessors'


# optimacms
gem 'optimacms', '0.3.8'
#gem 'optimacms', '0.3.8', path: "/projects/temp/optimacms"


gem 'simple_options', '0.0.4'
gem 'optimacms_options', '0.0.7'
gem 'optimacms_backups', '0.0.7'

# my gems
gem 'test_email_redis', '0.0.3'


#
gem 'devise', '4.2.0' #, '4.2.0' #, '3.5.6'
#gem 'devise-async', '0.10.2'
gem 'sidekiq', '4.2.10'

# for sidekiq web ui
gem 'sinatra', :require => nil

#
gem 'haml-rails', '0.9.0'
gem 'sass-rails', '5.0.6'
gem 'uglifier', '3.0.4'
#gem 'coffee-script-source', '1.8.0'
#gem 'coffee-rails', '4.1.1'
gem 'jquery-rails', '4.2.2' #,'4.0.5'
gem 'compass-rails' #, '3.0.2'
gem 'sprockets' #, '3.6.0'
gem 'sprockets-rails' #, '3.1.1'
gem 'font-awesome-rails', '~>4.7'

# bootstrap 3
gem 'bootstrap-sass', '3.3.7'

# for bootstrap 4
# Tooltips and popovers depend on tether for positioning. If you use them, add tether to the Gemfile:
source 'https://rails-assets.org' do
  gem 'rails-assets-tether', '>= 1.3.3'
end



#
gem 'kaminari' #, '0.17.0'
gem 'kaminari-bootstrap' #, '3.0.1'

gem 'simple_form', '~>3.3.1'

#gem 'simple_search_filter', '0.0.31'
gem 'simple_search_filter', '~>0.0.31', github: 'maxivak/simple_search_filter', branch: 'bootstrap4'
gem 'bootstrap3_autocomplete_input', '0.2.0'
#gem 'bootstrap_autocomplete_input', '0.2.0'

gem 'ancestry', '2.1.0'

gem 'gravtastic', '3.2.6'
gem 'paperclip', '4.3.6'

gem 'cancan', '1.6.10'


# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
#gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '2.5.0'


# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'


# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', '0.12.2', platforms: :ruby


#
#gem 'elasticsearch', '1.0.17'
gem 'elasticsearch', git: 'git://github.com/elasticsearch/elasticsearch-ruby.git'
gem 'elasticsearch-model', '0.1.9'
gem 'elasticsearch-rails', '0.1.9'
gem 'elasticsearch-dsl', git: 'git://github.com/elasticsearch/elasticsearch-ruby.git'


#
#gem 'poseidon'
#gem 'logstash-logger'

# for *.log
gem 'concise_logging'

#
gem 'jwt', '1.5.4'
gem "simple_events_redis", '1.0.1'

gem 'rack-cache' #, '1.6.1'
gem 'redis' #, '3.3.0'
gem 'redis-rails', '5.0.1' #, '4.0.0'
gem 'redis-namespace' #, '1.5.2'
gem 'rabbitmq_http_api_client' #, '1.6.0'
gem 'bunny', '2.2.2'

gem 'redlock'

#
gem 'aasm', '4.11.0'
# for sanitize URL
gem 'babosa', '1.0.2'
#gem 'stringex'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', '1.2016.6', platforms: [:mingw, :mswin, :x64_mingw]


#
gem 'tinymce-rails', '4.1.6'
gem 'el_finder', '1.1.12'

# for comparing versions
gem 'versionomy', '0.5.0'

#pic
gem 'carrierwave', '0.11.2'
gem 'dragonfly', '1.0.12'

gem 'jquery-fileupload-rails', '0.4.7'
gem 'autoprefixer-rails', '6.4.0'


gem 'rails_autolink' #, '1.1.6'
# for nested form
gem "cocoon", '1.2.9'


#gem 'ruby-kafka', '0.3.15'
gem 'ruby-kafka', '0.3.17'

gem 'whenever'


# recaptcha
gem 'recaptcha', '3.4.0', :require => 'recaptcha/rails'

#
gem 'aws-sdk', '2.6.43'
gem 'fog', '1.38.0'
gem 'fog-aws', '1.2.0'


#phone validation
gem 'phonelib', '0.6.8'
gem 'phone', '1.2.3'

gem 'svg-flags-rails', '>= 1.0.0-beta'


# tests - for prod
gem 'faker', '1.6.3'



#gem "java-properties", '0.2.0'
#gem "inifile", '3.0.0'
gem "iniparse", '1.4.2'


#
#gem 'youtrack', :git => "git://github.com/jesusinyourtown1/youtrack.git", :branch => "new-dev"
gem 'rutrack'

# slack gems
gem 'slack-ruby-client'
gem 'slop' # for real-time messaging
#gem 'slack-notifier'

gem 'inline_svg' , '0.11.1'

gem 'humanize', '1.3.0'

gem 'wannabe_bool', '~> 0.5.0'


gem 'diplomat', '1.3.0'

# storing secrets
gem "vault", "~> 0.1"

# profiling
group :development do
  gem 'rack-mini-profiler'
  gem "better_errors", '2.1.1'
end

# deployment
group :development do
  gem 'capistrano',  '3.7.1'
  #gem 'capistrano',  '3.4.0'
  gem 'capistrano-rails', '1.1.7'
  #gem 'capistrano-rails', '1.1.3'
  gem 'capistrano-bundler', '1.1.4'
  gem 'capistrano-rvm',   '0.1.2'

  #gem 'capistrano-locally'

  #gem 'capistrano-passenger'
  #gem 'capistrano-touch-linked-files'
  #gem 'capistrano-upload-config'

  gem 'slackistrano'

end



group :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  #gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  #gem 'web-console', '~> 2.0'
  #gem 'pry'

  gem 'rspec', '3.5.0'
  gem 'rspec-rails', '3.5.1'
  #gem 'rspec-expectations', '~> 3.4'

  gem 'rspec-activemodel-mocks', '1.0.2'
  gem 'factory_girl_rails', '4.7.0'
  #gem 'database_cleaner'
  gem 'faker', '1.6.3'
  #gem 'ffaker'
  gem 'timecop', '0.8.1'
  gem 'capybara', '2.7.1'
  #gem "capybara-webkit"
  gem 'selenium-webdriver', '2.53.4'
end
