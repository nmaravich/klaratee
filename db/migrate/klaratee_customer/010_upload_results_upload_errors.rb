class UploadResultsUploadErrors < ActiveRecord::Migration
  def self.up
    
    create_table :item_upload_results do |t|
      t.column :creator_id    , :integer
      t.column :created_at    , :timestamp
      t.column :event_id      , :integer
      t.column :data_template_id , :integer
      t.column :filename      , :string
      t.column :new_count     , :integer
      t.column :mod_count     , :integer
      t.column :deleted_count , :integer
      t.column :error_count   , :integer
    end
    
    create_table :item_upload_errors do |t|
      t.column :item_upload_result_id   , :integer
      t.column :excel_sheet             , :string
      t.column :excel_line              , :integer
      t.column :item_id                 , :integer
      t.column :data_template_column_id , :integer
      t.column :entered_value           , :string
      t.column :error_message           , :string
    end
    
    add_index :item_upload_results, :creator_id
    
    add_index :item_upload_errors, :item_upload_result_id
    
  end
  
  def self.down
    drop_table :item_upload_results
    drop_table :item_upload_errors
  end
end