# in config/initializers/locale.rb

Rails.application.config.time_zone = 'Europe/Kiev'

#Rails.application.config.i18n.enforce_available_locales = false
I18n.enforce_available_locales = false

#config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}').to_s]
#I18n.load_path += Dir[Rails.root.join('lib', 'locale', '*.{rb,yml}')]

I18n.default_locale = :en