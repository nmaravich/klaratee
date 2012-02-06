class DynamoIndex < ActiveRecord::Migration
  
  def self.up
    add_index :dynamo_fields, :model
    add_index :suppliers, :company_name
  end
  
  def self.down
      remove_index :dynamo_fields, :model
      remove_index :suppliers, :company_name
  end
  
end
