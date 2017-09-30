require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'haml'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)




module Api
  class Application < Rails::Application
    config.secret_key_base = Rails.application.secrets.secret_key_base

    config.assets.paths << Rails.root.join('vendor', 'assets', 'components')
    config.assets.paths << Rails.root.join('app', 'assets', 'templates')
    config.assets.paths << Rails.root.join('app', 'assets', 'components')

    class HamlTemplate < Tilt::HamlTemplate
      def prepare
        @options = @options.merge :format => :html5
        super
      end
      def evaluate(scope, locals, &block)
        scope.class_eval do
          include Rails.application.routes.url_helpers
          include Rails.application.routes.mounted_helpers
          include ActionView::Helpers
          include InlineSvg::ActionView::Helpers
          include Rails.application.helpers
        end

        super
      end
    end

    config.before_initialize do
      Sprockets.register_mime_type 'text/haml', extensions: ['.html.haml']
      Sprockets.register_transformer 'text/haml', 'text/html', Sprockets::LegacyTiltProcessor.new(HamlTemplate)
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    #config.active_record.raise_in_transactional_callbacks = true


    # for Rails 5
    config.enable_dependency_loading = false
    config.eager_load_paths += %W( #{config.root}/lib )
    #config.eager_load_paths += %W( #{config.root}/lib/gexcore/ )
    #config.eager_load_paths += %W( #{config.root}/lib/nb_routes.rb)

    # old load libs
    #config.autoload_paths << Rails.root.join('lib')


    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    initializer 'setup_asset_pipeline', :group => :all  do |app|
      # We don't want the default of everything that isn't js or css, because it pulls too many things in
      app.config.assets.precompile.shift

      # Explicitly register the extensions we are interested in compiling
      app.config.assets.precompile << Proc.new { |path|
        if path.match('\.(css|js|html|erb|png|gif|jpg|jpeg|svg|eot|otf|svc|woff|woff2|ttf)\z')
          full_path = app.assets.resolve(path)
          app_assets_path = Rails.root.join('app', 'assets').to_path
          app_assets_components = File.join(app_assets_path, 'components')
          full_path.starts_with?(app_assets_path) && !(full_path.starts_with?(app_assets_components)) ? app_assets_path : false
        else
          false
        end
      }
    end


    ### mail




    # smtp
    # amazon
    config.action_mailer.smtp_settings = {
        :address        => Rails.application.secrets.smtp['address'],
        :port           => Rails.application.secrets.smtp['port'],
        :domain         => Rails.application.secrets.smtp['domain'],
        :authentication => Rails.application.secrets.smtp['authentication'],
        :user_name      => Rails.application.secrets.smtp['user_name'],
        :password       => Rails.application.secrets.smtp['password'],
        :enable_starttls_auto => Rails.application.secrets.smtp['enable_starttls_auto']
    }


    # gex_config
    f = File.join(File.dirname(__FILE__),"gex/gex_config.#{Rails.env}.yml")
    if !File.exists?(f)
      f = File.join(File.dirname(__FILE__),"gex/gex_config.yml")
    end
    h =YAML.load_file(f)
    config.gex_config = h.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

    # update gex_config from ENV
    gex_vars = %w[server_app_repo dir_clusters_data storage_files_dir chef_dir]
    gex_vars.each do |s|
      env_name = "gex.#{s}"
      if ENV[env_name]
        config.gex_config[s.to_sym] = ENV[env_name]
      end
    end


    # cache
    config.cache_store = :redis_store, {
        host: Rails.configuration.gex_config[:redis_host],
        port: 6379,
        namespace: Rails.configuration.gex_config[:redis_prefix]+":cache"
        #password: "mysecret",
        #namespace: "cache"
    }




    #
    config.SITE_NAME = 'gex'

    # gex_config
    config.gex_env = ENV['gex_env']



  end
end
