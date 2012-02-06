# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# If False then emails will silently fail.  Log will still show sample of email.
# If True you'll get an exception with the email error. 
config.action_mailer.raise_delivery_errors = true

# Options :smtp :sendmail :test - change to :test when you don't want to actually send the mail.
config.action_mailer.delivery_method = :smtp

# Using my gmail as an smtp server when testing.
#config.action_mailer.smtp_settings = {
#  :enable_starttls_auto => true,
#  :address    => "smtp.gmail.com",
#  :port       => "587",
#  :domain     => "localhost",
#  :authentication => "plain",
#  :user_name => "<your username>@gmail.com", 
#  :password => "<your pw here>"
#}

config.action_mailer.smtp_settings = {
  :enable_starttls_auto => false,
  :address    => "smtp.avadatum.com",
  :port       => "25",
  :domain     => "avadatum.com",
  :authentication => "plain",
  :user_name => "testing.avadatum", 
  :password => "password"
}

config.action_mailer.default_charset = "utf-8"

# Email templates use this. You can use it anywhere you need a url though.
# check the usermailer for its usage, but it basically just puts the link in the email so the user can get there easily.
SITE="http://localhost:3000"
