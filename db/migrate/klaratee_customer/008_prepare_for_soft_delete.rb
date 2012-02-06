class PrepareForSoftDelete < ActiveRecord::Migration

   def self.up
      add_column :suppliers,         :deleted, :integer, :limit=>1, :null=>false, :default=>0
      add_column :contacts,          :deleted, :integer, :limit=>1, :null=>false, :default=>0
      add_column :supplier_contacts, :deleted, :integer, :limit=>1, :null=>false, :default=>0

      add_column :dynamo_field_values, :deleted, :integer, :limit=>1, :null=>false, :default=>0, :after=>:val_float
      add_column :dynamo_fields, :deleted, :integer, :limit=>1, :null=>false, :default=>0, :after=>:field_type

      add_index :suppliers, :deleted
      add_index :contacts, :deleted
      add_index :supplier_contacts, :deleted

      add_index :dynamo_field_values, :deleted
      add_index :dynamo_fields, :deleted
   end

   def self.down
      remove_column :suppliers, :deleted
      remove_column :contacts , :deleted
      remove_column :supplier_contacts, :deleted
      remove_column :dynamo_fields, :deleted
      remove_column :dynamo_field_values, :deleted
   end

end



