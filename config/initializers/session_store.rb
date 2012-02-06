# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_klaratee_session',
  :secret      => 'b3ed6981c9060c0dac843d3f9fc366c1fd25fda2286c5f60ef804dd6434b4e78431869e463d8asd97e39bb63afa8f163232209b6272b77a43b533',
  :expire_after => 3.hours,
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

# We are using redis for the session store through the use of  the redis-store gem 
# http://github.com/jodosha/redis-store
ActionController::Base.session_store = :redis_session_store