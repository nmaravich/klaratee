class AuditRecordCols < ActiveRecord::Migration
  
  def self.up
    add_column :audit_records, :surrogate_parent_id, :integer
  end
  
  def self.down
    remove_column :audit_records, :surrogate_parent_id
  end
  
end