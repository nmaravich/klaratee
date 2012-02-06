# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')


Rails::Initializer.run do |config|
  
  # I added this for the restful_auth / acts_as_state_machine stuff
  config.active_record.observers = :user_observer
  
  # This numbers migration versions rather than using a date stamp
  config.active_record.timestamped_migrations = false
  
  # Might be needed for prod ( klaratee.com )
  #RAILS_ENV = 'production'
  #ENV['RAILS_ENV'] ||= 'production'
  
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  
  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  
  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem 'enumerated_attribute'
  config.gem "declarative_authorization"
  config.gem "ar-extensions"
  config.gem 'will_paginate', :version => '~> 2.3.12', :source => 'http://gemcutter.org'
  config.gem 'redis', :version => "2.0.10"
  config.gem "redis-store" ,  :version => "1.0.0.beta3"
  
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
  
  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
  
  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
  
  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'Eastern Time (US & Canada)'
  
  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  SUPPORT_EMAIL='support@klaratee.com'
end
