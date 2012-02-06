class Schema < ActiveRecord::Migration
  
  # LOOK AT ME!!!  YOU'LL BE SORRY!!
  # If you add another column to this aux_users table you'll need to modify the rake task if you want it populated
  # upon redploy. 
  # task name: deploy:customer['name','environment']
  def self.up
     create_table :aux_users, :force => true do |t|
      t.string  :login, :email, :first_name, :last_name
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end
    
    create_table :events do |t|
      t.string :name,      :limit => 100, :null => false
      t.date   :start_date
      t.string :status
      t.date   :end_date      
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end
    
    # Don't allow creation of multiple events with the same exact name.
    add_index :events, :name, :unique => true
    
    create_table :suppliers do |t|
      t.string  :company_name,                                        :limit => 45,  :null=>false
      t.string  :address1, :city,                                     :limit => 100, :null=>true
      t.string  :state,                                               :limit => 2
      t.string  :zip, :phone_number, :fax,                            :limit => 20
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end

    create_table :supplier_docs do |t|
      t.integer :supplier_id,  :null => false
      # below attrs are for attachment_fu
      t.integer :parent_id # used when doing thumbnails
      t.string :content_type, :filename, :thumbnail
      t.integer :size, :width, :height
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end

    add_index :supplier_docs, :supplier_id, :name => 'FK_supplier_id'

    create_table :supplier_notes do |t|
      t.integer :supplier_id, :null => false
      t.string  :note,        :null => false
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end

    add_index :supplier_notes, :supplier_id, :name => 'FK_supplier_id'

    create_table :contacts do |t|
      t.string :f_name, :l_name,                            :limit => 45, :null=>false
      t.string :email,                                       :limit => 100, :null=>false
      t.string :phone_number, :fax,                         :limit => 45
      t.string :title, :address1, :address2, :city, :limit => 100
      t.string :state,                                      :limit => 2
      t.string :zip,                                        :limit => 20
      t.string :comments
      t.integer :creator_id
      t.integer :updater_id
      t.integer :user_id, :null=>true # Link the contact to a user account.
      t.timestamps
    end
    
    create_table :data_templates do |t|
      t.string :name,        :limit => 100, :null => false
      t.string :description, :limit => 100, :null => true
      t.integer :event_id                 , :null => false
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end

    add_index :data_templates, :event_id, :name => 'FK_event_id'
    add_index :data_templates, [:event_id, :name], :unique => true

    create_table :supplier_contacts do |t|
      t.integer :supplier_id
      t.integer :contact_id
      t.string  :contact_type
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end

    create_table :data_template_contacts do |t|
      t.integer :data_template_id   , :null => false
      t.integer :contact_id, :null => false
      t.timestamps
    end

    add_index :data_template_contacts, :data_template_id, :name => 'FK_data_template_id'
    add_index :data_template_contacts, :contact_id, :name => 'FK_contact_id'
    
    create_table :data_template_columns do |t|
      t.integer :data_template_id
      t.string :name,     :null => false
      t.string :col_type, :null => false
      t.string :mask,     :null => true # change to false later
      t.boolean :required,:null => false, :default => 0
      t.string :col_alias,:null => true # used by app to generate queries correctly.  On screen should output :name
      t.integer :order, :null => false, :default => 0
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end

    add_index :data_template_columns, :data_template_id, :name => 'FK_data_template_id'
    
    # Used for template columns that are multi select types.  All possible values
    # are stored here.
    create_table :data_template_column_possible_values do |t|
      t.integer :data_template_column_id,   :null=> false      
      t.string :possible_value,             :null=> false
      t.timestamps
    end

    add_index :data_template_column_possible_values, :data_template_column_id, :name => 'FK_data_template_id'

    create_table :items do |t|
      t.boolean :is_dirty,   :null=> false, :default => 0      
      t.boolean :is_valid,   :null=> false, :default => 0
      t.boolean :is_approved,:null=> false, :default => 0
      t.integer :supplier_id
      t.integer :data_template_id
      t.integer :creator_id
      t.integer :updater_id
      t.timestamps
    end
    
    add_index :items, :supplier_id, :name => 'FK_supplier_id'    
    add_index :items, :data_template_id, :name => 'FK_data_template_id'    

    create_table :item_values do |t|
      t.string  :string_value  , :null => true
      t.integer :int_value     , :null => true
      t.float   :decimal_value , :null => true
      t.text    :text_value    , :null => true
      t.boolean :binary_value  , :null => true
      t.integer :item_id       , :null => false
      t.integer :data_template_column_id , :null => false
      t.timestamps
    end
    
    # Multi column index needed to help with the master item retrieval query.
    # It improved performance from 44ms to 2.5ms
    add_index :item_values, [:item_id, :data_template_column_id], :name => 'FK_item_and_data_template_cols'
    
    # Tag columns are for plugin act_as_taggable_on_steriods    
    create_table :tags do |t|
      t.column :name, :string
    end
    
    create_table :taggings do |t|
      t.column :tag_id, :integer
      t.column :taggable_id, :integer
      # You should make sure that the column created is
      # long enough to store the required class names.
      t.column :taggable_type, :string
      t.column :created_at, :datetime
    end
    
    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type], :name => 'FK_taggable_id_taggable_type'
    
    create_table :audit_records do |t|
      t.integer  :user_id,                    :null => false
      t.integer  :severity,                   :null => false, :default => 0
      t.integer  :event_id
      t.integer  :template_id
      t.integer  :supplier_id
      t.datetime :time,                       :null => false
      t.integer  :category,                   :null => false
      t.string   :component,    :limit => 45
      t.string   :action,       :limit => 45
      t.string   :entry_text,   :limit => 512
    end

    add_index :audit_records, :user_id
    add_index :audit_records, :event_id
    add_index :audit_records, :template_id
    add_index :audit_records, :supplier_id    
    add_index :audit_records, :category
    
  end
  
  def self.down
    drop_table :aux_users
    drop_table :contacts
    drop_table :data_template_column_possible_values
    drop_table :data_template_columns
    drop_table :data_template_contacts
    drop_table :data_templates
    drop_table :events
    drop_table :item_values
    drop_table :items
    drop_table :supplier_contacts
    drop_table :supplier_docs
    drop_table :supplier_notes
    drop_table :suppliers
    drop_table :taggings
    drop_table :tags
    drop_table :audit_records
  end
  
end
