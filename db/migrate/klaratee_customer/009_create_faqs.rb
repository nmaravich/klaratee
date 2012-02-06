class CreateFaqs < ActiveRecord::Migration
  def self.up
    create_table :faqs do |t|
      t.integer :parent_id
      t.string  :id_path
      t.integer :children_count
      t.integer :level
      t.integer :family_id
      t.integer :user_id
      t.string  :status
      t.string  :visibility
      t.string  :text

      t.timestamps
    end
    add_index :faqs, :parent_id
    add_index :faqs, :id_path, :unique => true
    add_index :faqs, :family_id
    
  end

  def self.down
    drop_table :faqs
  end
end
