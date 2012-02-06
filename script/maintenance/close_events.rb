# This is a runner script that closes all open events that have an end date on or before the current day 
# It is run with script/runner
# config/schedule.rb sets up the interval at which this script is run
companies = Company.all

companies.each do |c|
  ActiveRecord::Base.establish_connection(c.db_config)
  events_to_close = Event.find(:all, :conditions => ["status = 'open' AND end_date <= ? ", Date.today])
  events_to_close.each do |e|
     e.status = :closed
     e.save
     puts "closed #{e.name} - #{c.name}" 
  end
end
