class SystemSetting < ActiveRecord::Base  

  # Connect to the master db  
  establish_connection RAILS_ENV

  FIND_SQL = "
    select ss.*, 
        (select ss2.id from system_settings ss2 where ss.key = ss2.key and ss2.company_id = ?) as cs_id,
        (select ss3.value from system_settings ss3 where ss.key = ss3.key and ss3.company_id = ?) as cs_value 
        from system_settings ss
        where ss.company_id = 0"

  FIND_GLOBAL_SQL = "
    select ss.* 
        from system_settings ss
        where ss.company_id = 0"

end
