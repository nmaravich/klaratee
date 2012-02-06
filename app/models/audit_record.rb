class AuditRecord < ActiveRecord::Base
  # Associations
  belongs_to :user, :class_name => "AuxUser"
  
  #header_row is used to map what to expect from uploading a supplier sheet
  # The col_name is what will appear in the sheet, while the attr_name is the name
  # of the getter for the object.  Its used to pull the value from the object in the loop.
  # Use col_width to ensure the cells are wide enough for the values so it looks nice on download
  HEADER_ROW = [
  {:col_name => "User",     :attr_name => "ar.user_id",    :col_width => 15 } ,
  {:col_name => "Surrogate", :attr_name => "ar.surrogate_parent_id", :col_width => 15 } ,
  {:col_name => "Supplier", :attr_name => "supplier_name", :col_width => 20 } ,
  {:col_name => "Action",   :attr_name => "ar.category",   :col_width => 20 } ,
  {:col_name => "Time",     :attr_name => "ar.time",       :col_width => 30 } ,
  {:col_name => "Event",    :attr_name => "event_name",    :col_width => 15 } ,
  {:col_name => "Template", :attr_name => "template_name", :col_width => 20 } ,
  ].freeze
  
  #These are all of the audit categories that we capture.  We are using this hash in leu of a DB
  # table for now ... it may make sense to create an audit_category table in the future to replace this.
  CATEGORIES = { :login => 0,
                 :logout => 1,
                 :activation => 2,
                 :invitation => 3,
                 :user_mod => 4,
                 :contact_mod => 5,
                 :supplier_mod => 6,
                 :event_mod => 7,
                 :template_mod => 8,
                 :template_column_mod => 9,
                 :item_mod => 10,
                 :item_sheet_download => 11,
                 :item_sheet_upload => 12,
                 :supplier_sheet_upload => 13,
                 :security_exception => 14,
               }.freeze
               
  # Text for the numeric categories, TODO - move these into DB table so we can sort on them properly             
  CATEGORY_TEXT = [
                   'User Login'.freeze,
                   'User Logout'.freeze,
                   'User Activation'.freeze,
                   'Template Contact Invitation'.freeze,
                   'User Modification'.freeze,
                   'Contact Modification'.freeze,
                   'Supplier Modification'.freeze,
                   'Event Modification'.freeze,
                   'Template Modification'.freeze,
                   'Template Column Modification'.freeze,
                   'Item Modification'.freeze,
                   'Template Items Download'.freeze,
                   'Template Items Upload'.freeze,
                   'Supplier Sheet Upload'.freeze,
                   'Security Exception'.freeze
                   ].freeze
 
  # Sort columns for global activity report, use numeric indexes in the view for security, not exposing DB column names
  SORT_COLS = ['ar.user_id',
               'supplier_name',
               'ar.category',
               'ar.time',
               'event_name',
               'template_name',
               'surrogate_parent_login'].freeze

  GLOBAL_ACTIVITY_SQL = "
      select ar.*, au.login as user_name, au2.login as surrogate_parent_login, ev.name as event_name,
             dt.name as template_name, sup.company_name as supplier_name
        from audit_records ar
        inner join aux_users au on ar.user_id = au.id        
        left outer join aux_users au2 on ar.surrogate_parent_id = au2.id
        left outer join events ev on ar.event_id = ev.id
        left outer join data_templates dt on ar.template_id = dt.id
        left outer join suppliers sup on ar.supplier_id = sup.id
        order by "
  
  # Validations
  #validates_presence_of :company_name  
  
  def self.create (user_id, session_hash, event_id, template_id, supplier, category, component, action, text)
    audit_entry = self.new
    surrogate_hash = session_hash[:surrogate_parent]
    audit_entry.time = Time.now    
    audit_entry.user_id = user_id
    audit_entry.surrogate_parent_id = surrogate_hash.nil? ? nil : surrogate_hash[:user_id]
    audit_entry.event_id = event_id unless event_id.nil?
    audit_entry.template_id = template_id unless template_id.nil?
    audit_entry.supplier_id = supplier.id unless supplier.nil?
    audit_entry.category = category unless category.nil?
    audit_entry.component = component unless component.nil?
    audit_entry.action = action unless action.nil?
    audit_entry.entry_text = text unless text.nil?
    audit_entry.save
  end
    
end