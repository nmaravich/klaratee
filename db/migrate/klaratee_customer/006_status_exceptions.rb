class StatusExceptions < ActiveRecord::Migration
  
  def self.up
   create_table "status_exceptions", :force => true do |t|
        t.integer "event_id"
        t.integer "aux_user_id"
        t.string  "status"
    end

    add_index :status_exceptions, [:event_id, :aux_user_id], :unique => false
    add_index :status_exceptions, :event_id, :unique => false
    
  end
  
  def self.down
     drop_table :status_exceptions
  end
  
end
