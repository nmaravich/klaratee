require "digest"
require 'digest/sha1'

class DataTemplateColumn < ActiveRecord::Base
  
  validate_on_create :validate_unique_name_per_template
  
  named_scope :belongs_to_template, lambda { |dt_id| { :conditions => ["data_template_id = ?", dt_id]  }}
  named_scope :named, lambda { |col_name| { :conditions => ["name = ?", col_name]  }}
  
  named_scope :order_greater_or_equal, lambda { |order, dt_id| {:order=>'data_template_columns.order asc', :conditions => ["data_template_columns.order >= ? AND id != ? ", order, dt_id] } }
  named_scope :order_less_or_equal,    lambda { |order, dt_id| {:order=>'data_template_columns.order desc', :conditions => ["data_template_columns.order <= ? AND id != ? ", order, dt_id] } }
  
  TYPES =[ ["Text", "string_value"], ["Large Text", "text_value"], ["Numeric", "int_value"],
  ["Decimal", "decimal_value"],["Select One", "select_one"], ["Select Many", "select_many"] ].freeze
  
  GROUP_VERBS=[ ["add to", "add_to"], ["remove from", "remove_from"], ["invite to", "invite_to"] ].freeze
  
  has_many :items, :through => :item_values, :dependent => :destroy
  has_many  :data_template_column_possible_values, :dependent => :destroy
  has_many :item_values, :dependent => :destroy
  user_stampable
  
  belongs_to :data_template
  
  # We want to make sure that there is a unique column name for a particular template.
  # This isn't enforcable via db constraint because it is valid to have the same name but for different templates.
  # Example: a column named 'description' is likely to be in most templates.
  # NOTE: This is only done on create.  If you did it on update it would fail if you changed a column that wasn't the name 
  #       because it would think a column with the name given already exists ( because it does ... the column you are editing )
  def validate_unique_name_per_template
    # Making use of the named scopes declared above.                                                                                   
    if !DataTemplateColumn.named(self.name).belongs_to_template(self.data_template_id).empty?
      errors.add("Column '#{self.name}'", "already exists")  
    end
    
  end
  
  def required_as_text
   (required == false) ? 'Not required' : 'Required'
  end
 
  def sha1_name
    Digest::SHA1.hexdigest(self.name)
  end
  
end
