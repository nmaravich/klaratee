class Contact < ActiveRecord::Base
  
  # Dynamo
  has_dynamic_attributes(true)
  
  # make sure you have an :int column named delete in your model
  is_soft_deletable

  user_stampable
  
  has_many :suppliers, :through => :supplier_contacts
  has_many :data_templates, :through => :data_template_contacts
  has_many :supplier_contacts, :dependent => :destroy
  has_many :data_template_contacts, :dependent => :destroy

  belongs_to :user, :class_name => "AuxUser"
  
  validates_presence_of :f_name, :l_name, :email
  # Since its possible a contact can become a user we want to make sure that each contact has a unique email assigned.
  validates_uniqueness_of :email
 
  named_scope :primary_contacts, :include=>:suppliers, :conditions => {'supplier_contacts.contact_type' => 'Primary'}
  named_scope :secondary_contacts, :include=>:suppliers, :conditions => {'supplier_contacts.contact_type' => 'Secondary'}
 
  GROUP_VERBS=[ ["add to", "add_to"], ["remove from", "remove_from"], ["invite to", "invite_to"] ].freeze
  
  #header_row config structure:
  # The col_name is what will appear in the sheet, while the attr_name is the name
  # of the getter for the object.  Its used to pull the value from the object in the loop.
  # Use col_width to ensure the cells are wide enough for the values so it looks nice on download\
  #
  # NOTE: the company_name is what we'll use to link the supplier to this contact because of
  #       the way the upload will work ( sheet 1: directions, sheet 2: suppliers, sheet 3: contacts
  #       that's why there is no attribute listed, just the heading.
  HEADER_ROW = [
  {:col_name => "First Name",       :attr_name => "f_name",       :col_width => 16 } ,
  {:col_name => "Last Name",        :attr_name => "l_name",       :col_width => 16 } ,
  {:col_name => "Email",            :attr_name => "email",        :col_width => 20 } ,
  {:col_name => "Title",            :attr_name => "title",        :col_width => 15 } ,
  {:col_name => "Phone",            :attr_name => "phone_number", :col_width => 12 } ,
  {:col_name => "Fax",              :attr_name => "fax",          :col_width => 12 } ,
  {:col_name => "Address 1",        :attr_name => "address1",     :col_width => 12 } ,
  {:col_name => "Address 2",        :attr_name => "address2",     :col_width => 12 } ,
  {:col_name => "City",             :attr_name => "city",         :col_width => 12 } ,
  {:col_name => "State",            :attr_name => "state",        :col_width => 10 } ,
  {:col_name => "Zip",              :attr_name => "zip",          :col_width => 10 } ,
  {:col_name => "Comments",         :attr_name => "comments",     :col_width => 10 } ,
  ].freeze
    
  def self.per_page
    10
  end
  
end
