class ItemAuditCols < ActiveRecord::Migration
  
  def self.up
    add_column :items, :surrogate_creator_id, :integer
    add_column :items, :surrogate_updater_id, :integer
  end
  
  def self.down
    remove_column :items, :surrogate_creator_id
    remove_column :items, :surrogate_updater_id
  end
  
end
