class DataTemplate < ActiveRecord::Base
  belongs_to :event
  has_many :contacts, :through => :data_template_contacts
  has_many :data_template_contacts, :dependent => :destroy
  has_many :data_template_columns, :order => 'data_template_columns.order', :dependent => :destroy
  has_many :items
  
  # filter templates by invited user:
  named_scope :with_invitee, lambda {|user| {:joins => :contacts, :conditions => ['contacts.user_id = ?', user.id]}}  
  
  # filter templates by event to which they are associated
  named_scope :with_event, lambda {|event| {:conditions => ['event_id = ?', event.id]}}
  named_scope :with_event_ids, lambda{|events| {:conditions=>["event_id IN (?)", events.map {|e| e.id }]   }}
  named_scope :with_open_or_closed_events, :joins=>:event, :conditions=>["events.status IN (?)", ['open','closed']]
  # Ensure a dataTemplate has an event associated with it!
  validates_associated :event, :message => ": None Selected"
  validates_uniqueness_of :name, :scope=>[:event_id], :message =>"must be unique for an event.", :case_sensitive => false
  
  user_stampable
  
  # Convert column names into a sha1 hash key for security.
  # Prevents database column names from appearing in the url
  def get_columns_as_sha1 
    self.data_template_columns.map{|col| col.sha1_name}    
  end
  
end
