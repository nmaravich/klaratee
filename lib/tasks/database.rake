require "yaml"
require 'active_record'

#-----------------------#
#-      Initialize     -#
#-----------------------#
@database_yml ||= YAML.load_file('config/database.yml')
@valid_envs=['testing','development','staging','production']

# These will all be prepended with klaratee_environment_c - so klaratee_development_c_edmc, klaratee_development_c_sample
@valid_customers=['default','edmc','investors','demo','smithfield', 'westinghouse','p3']
#-----------------------#

# Get a connection to a given database
# db:      Name of the database you wish to 'USE'
# profile: matches a profile in database.yml.  
#          The default is deployer_profile ( see deployer_profile method ) 
#          which credentials for the local db.
def connect_via_config(db, profile=deployer_profile)
  # Add the passed in db to the given profile.
  customer_db_config = profile.merge('database' => db)
  puts "  Connecting to database: #{customer_db_config['database']} as user #{customer_db_config['username']}"
  # USE the given database.
  ActiveRecord::Base.establish_connection(customer_db_config)
end

# Choose which profile to load
# original_profile: The profile you want to loadd.
# ex: :development, :staging, :production, ( anything in database yml )
# The default is the RAILS_ENV which is likely development or production
def deployer_profile(original_profile = RAILS_ENV)
  # Basically changes the password to the original profile ( development or production ) to the deployer's uid / pw
  deployer_profile = @database_yml[original_profile].merge(@database_yml["deployer_#{RAILS_ENV}"])
  puts "  Using deployer profile: #{deployer_profile['database']}"
  deployer_profile
end

# Used in seeding tasks
def load_data_dir(dir)
  files = []
  # Be sure to prefix the db files with 3 digits.
  Dir.foreach(dir){ |entry| files << entry if entry.match(/^\d\d\d_.*\.rb$/) }
  files.sort.each do |f|
    f = dir + "/" + f
    puts "  Loading #{f}"
    load f
  end
end

# Used to dig up the latest version number of migration files
def find_max_version(dir)
  files = []
  Dir.entries(dir).sort.each { |entry| files << entry if entry.match(/^\d\d\d_.*\.rb$/) }
  files.last.gsub(/_.+/, '')
end

def create_db(db_name)
  raise ArgumentError, "A database name is required!" unless db_name
  raise ArgumentError, "\n*** Don't mess with the mysql db silly!!!  ***\n" if db_name.downcase == 'mysql'
  # We'll need to be the root user here if we expect to DROP / CREATE databases.
  connect_via_config('mysql')
  drop_db(db_name)
  ActiveRecord::Base.connection.execute("CREATE DATABASE #{db_name};")
  puts "  Created database: '#{db_name}'"
end

def drop_db(db_name)
  raise ArgumentError, "A database name is required!" unless db_name
  raise ArgumentError, "\n*** Don't mess with the mysql db silly!!!  ***\n" if db_name.downcase == 'mysql'
  # We'll need to be the root user here if we expect to DROP / CREATE databases.
  ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{db_name};")
  puts "  Dropped database: '#{db_name}'"
end

def common_deploy_tasks(env="development")
  Rake::Task['db:create:accounts'].invoke
  Rake::Task["db:create:by_name"].invoke(@database_yml[env]['database'])
  # The reenable is because you need to run this task more than one time. ( created the customer db and the master db )
  Rake::Task['db:create:by_name'].reenable
  Rake::Task['db:migrate:master_db'].invoke
  Rake::Task['db:seed:master'].invoke
  puts "  Creating the default customer database."
  
  Rake::Task['deploy:customer'].invoke('default',RAILS_ENV)
  
end

# -- Validation Helpers -- #
def validate_cust_name(cust_name)
  raise ArgumentError, "Invalid customer name.  Allowed: #{@valid_customers.join(',')} given: #{cust_name}" unless @valid_customers.include?(cust_name)
end

def validate_environment(env)
  raise ArgumentError, "Invalid environment.  Allowed: #{@valid_envs.join(',')}" unless @valid_envs.include?(env) 
end

def validate_name_env_parameters(cust_name, env)
  raise ArgumentError, "Customer name and environment param needed.  ex: sample:task['default','development']" if cust_name.nil? || env.nil?
  validate_cust_name(cust_name)
  validate_environment(env)
end

#----------------------------#

#----------------------------#
#---     BEGIN TASKS     --- #
#----------------------------#
desc "List possible customers"
task :cust_list => :environment do
  puts "Available customers: #{@valid_customers.join(', ')}"
end

namespace :deploy do
  
  # deploy:dev
  desc "Create and migrate ( for development ) the master table, and the sample customer table."
  task :dev => :environment do
    ENV['RAILS_ENV'] = "development"
    RAILS_ENV.replace('development') if defined?(RAILS_ENV)
    puts "** START Dev Deploy **"
    common_deploy_tasks(RAILS_ENV)
    puts "** END Dev Deploy **"
  end
  
  # deploy:staging
  desc "Creates and migrates the db's for the current RAILS_ENV.  Does not populate data except for users and permissions needed."
  task :staging => :environment do
    ENV['RAILS_ENV'] = "staging"
    RAILS_ENV.replace('staging') if defined?(RAILS_ENV)
    
    puts "** START Staging Deploy **"
    common_deploy_tasks(RAILS_ENV)
    puts "** END Staging Deploy **"
  end
  
  # deploy:prod
  desc "Creates and migrates the db's for the current RAILS_ENV.  Does not populate data except for users and permissions needed."
  task :prod => :environment do
    RAILS_ENV="production"
    ENV['RAILS_ENV'] = "production"
    puts "** START Production Deploy **"
    common_deploy_tasks(RAILS_ENV)
    puts "** END Production Deploy **"
  end  
  
  # Doesn't assume that the master db has been created, or that accounts to access it have been created either.
  # You'll need to call deploy:dev ( or deploy:staging, deploy:prod ) first.
  # deploy:customer['name','environment'] RAILS_ENV=<development, staging, production>
  desc "Create, migrate, and seed a customer database for the given environment."
  task :customer, :cust_name, :env, :needs=> :environment do |t, args|
    validate_name_env_parameters(args[:cust_name], args[:env])
    
    # Set the environment
    ENV['RAILS_ENV'] = args[:env]
    RAILS_ENV.replace(args[:env]) if defined?(RAILS_ENV)
    
    # Drop then create the requested database. Prepend the customer name with klaratee_environment.
    db_name = "klaratee_" << args[:env] << "_" << args[:cust_name]
    Rake::Task['db:create:by_name'].invoke(db_name)
    Rake::Task['db:migrate:customer_db'].invoke(args[:cust_name])
    Rake::Task['db:seed:customer'].invoke(args[:cust_name])
    
    # Need an entry for this company in the master db in the given environment
    # Make sure the entry isn't already there. ( this might be a redeploy in which case it would have been created already )
    company = Company.find_by_name(args[:cust_name])
    if company.nil?
      puts "Initial deploy of customer: '#{args[:cust_name]}'. Necessary master db records are being created."
      company = Company.create!(:name => "#{args[:cust_name]}", :db_config => "klaratee_#{args[:env]}_#{args[:cust_name]}" )
      
      # IMPORTANT!  Because the User model is a master level table inside the model we do:
      # establish_connection RAILS_ENV ( inside users.rb )
      # When we call the rake task from a different RAILS_ENV ( like staging or production ) it won't obey what we
      # want and will default to development.  
      # This line will ensure we connect the User model to the RAILS_ENV we want
      User.establish_connection(RAILS_ENV)
      klaratee_user = User.find_by_login("klaratee")
      cu = CompanyUser.new
      cu.company_id=company.id
      cu.user_id=klaratee_user.id
      cu.save!
      
    else
      puts "Company: '#{args[:cust_name]}' has been deployed previously. Tables cleared and aux_users table recreated for the redeploy"
      # Need to recreate the aux_users table by looking at the master table.  
      ActiveRecord::Base.connection().execute("
                  INSERT INTO `#{ActiveRecord::Base.configurations['klaratee_' << RAILS_ENV << '_' << args[:cust_name]]['database']}`.aux_users(login, email, first_name, last_name)
                  SELECT u.login, u.email, u.first_name, u.last_name
                  FROM `#{ActiveRecord::Base.configurations[RAILS_ENV]['database']}`.company_users cu
                  INNER JOIN `#{ActiveRecord::Base.configurations[RAILS_ENV]['database']}`.users u on u.id = cu.user_id
                  INNER JOIN `#{ActiveRecord::Base.configurations[RAILS_ENV]['database']}`.companies c on c.id = cu.company_id
                  WHERE c.name = 'default'
                  AND u.login != 'klaratee'") # the klaratee user is created by the seed data.
    end
    
  end  
  
end

namespace :db do
  
  namespace :create do
    
    # db:create:accounts  
    desc "Create klaratee mysql accounts.  This is db user that will have permission to the database when the app is running."
    task :accounts => :environment do
      
      # At this point the only db we can count on being there is 'mysql'
      connect_via_config('mysql')
      
      users_created = []
      @database_yml.keys.each do |connection|
        if connection =~ /^#{RAILS_ENV}/ && !users_created.include?( @database_yml[connection]['username'] )
          begin
            puts "  Dropping current user #{@database_yml[connection]['username']}'@'localhost (if already exists) "
            ActiveRecord::Base.connection.execute("DROP USER '#{@database_yml[connection]['username']}'@'localhost';")
          rescue Exception => e
            puts "  Can't drop user ( probably doesn't exist to drop ): #{e}"
          end
          begin
            puts "  Dropping current user #{@database_yml[connection]['username']}'@'%' (if already exists) "
            ActiveRecord::Base.connection.execute("DROP USER '#{@database_yml[connection]['username']}'@'%';")
          rescue Exception => e
            puts "  Can't drop user ( probably doesn't exist to drop ): #{e}"
          end
          
          ActiveRecord::Base.connection.execute("CREATE USER '#{@database_yml[connection]['username']}'@'localhost' IDENTIFIED BY '#{@database_yml[connection]['password']}';")
          # Because of the db naming standard this grant will allow the same user to have permissions to customer databases created after this is run.
          ActiveRecord::Base.connection.execute("GRANT SELECT,INSERT,UPDATE,LOCK TABLES,DELETE,CREATE TEMPORARY TABLES ON `klaratee_#{RAILS_ENV}%`.* TO '#{@database_yml[connection]['username']}'@'localhost';")

          # Now create the user again but this allows us to connect remotely.  
          # NOTE: Its still necessary to create the localhost account above. http://dev.mysql.com/doc/refman/5.1/en/adding-users.html
          ActiveRecord::Base.connection.execute("CREATE USER '#{@database_yml[connection]['username']}'@'%' IDENTIFIED BY '#{@database_yml[connection]['password']}';")
          ActiveRecord::Base.connection.execute("GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,CREATE TEMPORARY TABLES ON `klaratee_#{RAILS_ENV}%`.* TO '#{@database_yml[connection]['username']}'@'%';")
          ActiveRecord::Base.connection.execute("FLUSH PRIVILEGES;")

          users_created << @database_yml[connection]['username']
        end
      end
      puts "  Users Created: #{users_created.inspect}"
    end
    
    # db:create:by_name
    desc "Create specific klaratee database"
    task :by_name, :db_name, :needs => :environment do |t, args|
      raise ArgumentError, "Database name required. Call like this: db:ceate:by_name['some_database']" if args[:db_name].nil?
      create_db(args[:db_name])
    end
    
  end # namespace create
  
  namespace :drop do
    
    # db:drop:by_name
    desc "Drop specific klaratee database"
    task :by_name, :db_name, :needs => :environment do |t, args|
      raise ArgumentError, "Database name required. Call like this: db:drop:by_name['some_database']" if args[:db_name].nil? 
      drop_db(args[:db_name])
    end
    
  end # drop
  
  namespace :migrate do    
    # db:migrate:master_db['version_num'] RAILS_ENV=<development, staging, production>
    desc "Migrate the klaratee database through scripts in db/migrate/klaratee_master."
    task :master_db, :version, :needs => :environment do |t, args|
      # grab latest version if none is given
      v =  args[:version].nil? ? find_max_version('db/migrate/klaratee_master') : args[:version]
      connect_via_config( @database_yml[RAILS_ENV]['database'] )
      ActiveRecord::Migrator.migrate('db/migrate/klaratee_master', v.to_i )
    end
    
    # db:migrate:customer_db['db_name','version_num'] RAILS_ENV=<development, staging, production>
    desc "Migrate the klaratee database through scripts in db/migrate/klaratee_customer."
    task :customer_db, :name, :version, :needs => :environment do |t, args|
      validate_cust_name(args[:name])
      # grab latest version if none is given
      v =  args[:version].nil? ? find_max_version('db/migrate/klaratee_customer') : args[:version]
      # Customer db's don't have a profile in db.yml so you have to tac on that prefix to get the full db name.
      connect_via_config("klaratee_" << RAILS_ENV << "_" << args[:name])
  	  ActiveRecord::Migrator.migrate('db/migrate/klaratee_customer', v.to_i)
    end
    
    # db:migrate:all_customers['version_num'] RAILS_ENV=<development, staging, production>
    desc "Migrate all customers contained in @valid_customers"
    task :all_customers, :version, :needs => :environment do |t, args|
      @valid_customers.each do |db|
        connect_via_config("klaratee_" << RAILS_ENV << "_" << db)
        ActiveRecord::Migrator.migrate('db/migrate/klaratee_customer', args[:version].to_i)
      end
    end
    
  end # migrate
  
  # Seed data is mandatory data that the app needs. This includes the klaratee account, roles, etc
  namespace :seed do
    
    # db:seed:master
    desc "Insert some default data into the master database."
    task :master => :environment do
      # Lookup the db config for the passed in db.
      connect_via_config( @database_yml[RAILS_ENV]['database'])
      load_data_dir( 'db/seed/seed_master' )
    end
    
    # db:seed:customer
    desc "Insert some default data into the given customer database."
    task :customer, :name, :needs => :environment do |t, args|
      validate_cust_name(args[:name])
      # Customer db's don't have a profile in db.yml so you have to tac on that prefix to get the full db name.
      connect_via_config("klaratee_" << RAILS_ENV << "_" << args[:name])
      load_data_dir( 'db/seed/seed_customer' )
    end
    
  end # seed
  
  # Default data is different. Default data are sample events, templates, etc so you can have some stuff to work with.
  namespace :sample_data do
    
    # db:sample_data:master
    desc "Sample data is for testing. Loads some sample users, roles, etc"
    task :master => :environment do
      # Lookup the db config for the passed in db.
      connect_via_config( @database_yml[RAILS_ENV]['database'])
      load_data_dir( 'db/sample_data/sample_data_master' )
    end
    
    # db:sample_data:customer
    desc "Sample data is for testing. Loads some sample events, templates, suppliers, etc"
    task :customer, :name, :needs => :environment do |t, args|
      validate_cust_name(args[:name])
      # Customer db's don't have a profile in db.yml so you have to tac on that prefix to get the full db name.
      connect_via_config("klaratee_" << RAILS_ENV << "_" << args[:name])
      load_data_dir( 'db/sample_data/sample_data_customer' )
    end
    
  end # seed
end # db