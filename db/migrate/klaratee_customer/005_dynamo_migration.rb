# This is the migration file for dynamo.  To generate this file in your app run:
# ./script/generate dynamo <option> and it will create the migration for you, and move it to your app's migrate directory
class DynamoMigration < ActiveRecord::Migration
  def self.up
    
    create_table :dynamo_fields do |t|
      t.column :model     , :string
      t.column :field_name, :string
      t.column :field_type, :string
      t.timestamps
    end
    
    create_table :dynamo_field_values do |t|
      t.column :dynamo_field_id  , :integer
      t.column :model_id         , :integer
      t.column :val_string       , :string
      t.column :val_int          , :integer
      t.column :val_float        , :float
      t.timestamps
    end 
    
    add_index :dynamo_field_values, :dynamo_field_id
    #------------------------
    # Commenting out because we don't actually want this to happen for each supplier, just edmc, and in prod that has been done already.
    # So when we create new cusomters this will run and add the edmc specific fields to those dbs which is not right.
    # -----------------------
    # remove_column :suppliers, :company_url
    # remove_column :suppliers, :title
    # remove_column :suppliers, :employees
    # remove_column :suppliers, :address2
    
    # # Create the DynamoFields that EDMC wanted
    # ['Contract on File', 'Proc Level', 'Company', 'Vendor', 'APPAYVENMAST.VENDOR-SNAME'].each do |field_name|
    #   DynamoField.create!(:model=>'Supplier', :field_name=>field_name, :field_type=>'val_string')
    # end
    # 
    # # The field names in the supplier table won't exactly match the cell name in the fieldValue table.
    # supplier_to_dynamo_map = {:contract_on_file=>'Contract on File', :proc_level=>'Proc Level', :company=>'Company Name', 
    #                           :vendor=>'Vendor', :appayvenmast_vendor_sname=>'APPAYVENMAST.VENDOR-SNAME'}
    # 
    # Take the values from the supplier table and move them to the dynamo tables.
    # Supplier.find(:all).each do |s|
    #   supplier_to_dynamo_map.keys.each do |db_col|
    #     val = s.send(db_col)
    #     if db_col == :contract_on_file
    #       val = db_col ? 'yes' : 'no'
    #     end
    #     df=DynamoField.find(:all, :conditions=>{:field_name=>supplier_to_dynamo_map[db_col.to_sym]}, :limit=>1)
    #     # DynamoFieldValue.create!(:dynamo_field_id=>df.id, :val_string=>val, :model_id=>s.id)
    #     DynamoFieldValue.create!(:dynamo_field_id=>df[0].id, :val_string=>val, :model_id=>s.id)
    #     
    #   end
    # end
    
    # Now remove the attributes being replaced by dynamic ones:
    # remove_column :suppliers, :contract_on_file
    # remove_column :suppliers, :proc_level
    # remove_column :suppliers, :company
    # remove_column :suppliers, :vendor
    # remove_column :suppliers, :appayvenmast_vendor_sname  

  end
  
  def self.down
    drop_table :dynamo_fields
    drop_table :dynamo_field_values
    # Read the supplier columns but note that the data will be gone!
    # add_column :suppliers, :contract_on_file, :boolean, :default => 0
    # add_column :suppliers, :proc_level, :string
    # add_column :suppliers, :company, :string
    # add_column :suppliers, :vendor, :string
    # add_column :suppliers, :appayvenmast_vendor_sname, :string
    # add_column :suppliers, :company_url, :string, :limit => 100, :null=>true
    # add_column :suppliers, :title      , :string, :limit => 100, :null=>true
    # add_column :suppliers, :employees, :string
    # add_column :suppliers, :address2, :string   , :limit => 100, :null=>true
  end
end