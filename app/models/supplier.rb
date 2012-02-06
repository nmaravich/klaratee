class Supplier < ActiveRecord::Base
  
  # dynamo
  has_dynamic_attributes(true)
  
  # make sure you have an :int column named delete in your model
  is_soft_deletable
  
  # Associations
  has_many :contacts, :through => :supplier_contacts, :dependent => :destroy
  has_many :supplier_contacts, :dependent => :destroy  
  has_many :items, :dependent => :destroy
    
  has_many :supplier_docs
  has_many :supplier_notes
  user_stampable
  
  # Validations
  validates_presence_of :company_name
  validates_uniqueness_of :company_name
  
  #returns supplier_id of given user's first supplier
  named_scope :first_of_user, lambda {|user| {:joins=>[:contacts => :user],
                :conditions => ['aux_users.id=?', user.id], :select=>'suppliers.*', :limit=>1, :order=>'suppliers.id'}}

  #header_row is used to map what to expect from uploading a supplier sheet
  # The col_name is what will appear in the sheet, while the attr_name is the name
  # of the getter for the object.  Its used to pull the value from the object in the loop.
  # Use col_width to ensure the cells are wide enough for the values so it looks nice on download
  HEADER_ROW = [
  {:col_name => "Company Name",   :attr_name => "company_name",   :col_width => 30 } ,
  {:col_name => "Phone",          :attr_name => "phone_number",   :col_width => 15 } ,
  {:col_name => "Fax",            :attr_name => "fax",            :col_width => 15 } ,
  {:col_name => "Address 1",      :attr_name => "address1",       :col_width => 20 } ,
  {:col_name => "City",           :attr_name => "city",           :col_width => 20 } ,
  {:col_name => "State",          :attr_name => "state",          :col_width => 10 } ,
  {:col_name => "Zip",            :attr_name => "zip",            :col_width => 10 } ,
  ].freeze
  
  # Sort columns for global activity report, use numeric indexes for security, not exposing DB column names
  SORT_COLS = ['company_name',
               'company_url',
               'address1',
               'phone_number',
               ].freeze
  
  def to_s
    "Supplier-> ID:#{id} COMPANY_NAME: #company_name"
  end
  
  def self.per_page
    20
  end
  
end