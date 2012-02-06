# This isn't exactly the normal rails way of doing things.  Since we need to connect to 
# different databases we can't use normal rails migrations.  Instead this schema is build up
# by tasks in the lib/tasks/database.rake file
# also @see db/migrate/sureSource_master

class Schema < ActiveRecord::Migration     
  
  def self.up
    create_table :users, :force => true do |t|
      t.string :login, :email, :remember_token, :first_name, :last_name
      t.string :crypted_password,          :limit => 40
      t.string :password_reset_code,       :limit => 40
      t.string :salt,                      :limit => 40      
      t.string :activation_code,           :limit => 40
      t.datetime :remember_token_expires_at, :activated_at, :deleted_at
      t.string :state, :null => :no, :default => 'passive'
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end
    
    create_table :companies do |t|
      t.string :name
      t.string :db_config
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end
    
    create_table :company_users, :id => false do |t|
      t.string :company_id
      t.string :user_id
      t.timestamps
    end
    
######  New stuff ########
    create_table :roles do |t|
      t.string :name
      t.string :description
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end
    
    create_table "roles_users", :id => false, :force => true do |t|
      t.integer "role_id"
      t.integer "user_id"
    end

    add_index "roles_users", ["role_id", "user_id"], :name => "index_roles_users_on_role_id_and_user_id", :unique => true
    add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"
      
  end
  
  def self.down
    drop_table :companies
    drop_table :company_users
    drop_table :roles
    drop_table :roles_users
    drop_table :users
  end    
end