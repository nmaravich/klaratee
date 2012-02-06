# Load the redis properties for the current environment ( development, staging or production)
REDIS_CONFIG = YAML::load(File.open(Rails.root + "config/redis.yml"))[Rails.env]
# REDIS can now be used anywhere in the app for redis operations
REDIS = Redis.new(:host=>REDIS_CONFIG['host'], :port=>REDIS_CONFIG['port'])