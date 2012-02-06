class SystemSettings < ActiveRecord::Migration
  def self.up
    
    create_table :system_settings do |t|
      t.column :company_id  , :integer
      t.column :key      , :string
      t.column :value      , :string
    end
    
    SystemSetting.create!(:company_id=>0, :key=>'email_safety.enabled', :value=>'no')
    SystemSetting.create!(:company_id=>0, :key=>'email_safety.forward_to_email', :value=>'')
  end
  
  def self.down
    drop_table :system_settings
  end
end