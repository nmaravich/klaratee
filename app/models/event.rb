class Event < ActiveRecord::Base
  
  has_many :data_templates, :dependent => :destroy
  has_many :status_exceptions, :dependent => :destroy
  user_stampable  
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  
  # Used to see if a user is part of this event.
  # Called from authorization_rules.rb under the supplier role.
  # It ensures suppliers can only see the events that they have been invited to.  
  has_many :invited_users, :class_name => "AuxUser",
            :finder_sql => 'SELECT DISTINCT aux_users.* FROM `events` 
                            INNER JOIN `data_templates` ON data_templates.event_id = events.id 
                            INNER JOIN `data_template_contacts` ON (`data_templates`.`id` = `data_template_contacts`.`data_template_id`) 
                            INNER JOIN `contacts` ON (`contacts`.`id` = `data_template_contacts`.`contact_id`) 
                            INNER JOIN `aux_users` ON `aux_users`.`id` = `contacts`.`user_id` 
                            WHERE events.id=#{self.id}'
  
  # filters by those events to which the user is invited
  named_scope :with_invitee, lambda {|user| {:joins => {:data_templates => [:contacts]}, :conditions => ['contacts.user_id = ?', user.id],
                                             :group => "events.id"}}
                                             
  named_scope :non_archived, :conditions => ["status NOT in (?)", ["archived"]]
  named_scope :opened_or_closed, :conditions => ["status in (?)",["open", "closed"]]
  
  # documentation for use of enum_attr is at http://github.com/jeffp/enumerated_attribute
  enum_attr :status, %w(open closed archived), :nil => false, :init=>:open do
    # the following is redundant because the labels match the enum_attr, but this is how you would customize the labels:
    labels :open=>"Open", :closed=>"Closed", :archived=>"Archived"
  end
  
  # is the event open, or does a status Exception exist, which opens it to the user?
  def open_to_user? (user_id)
    self.status_open? or StatusException.exists?({:event_id=> self.id, :aux_user_id => user_id, :status=>"open"})
  end
  
  # returns all data templates under this event to which the given user is invited
  def templates_with_invitee (user)
    DataTemplate.with_event(self).with_invitee(user)
  end

  # called automatically during Event#update  --  Updates the status exceptions
  def status_exceptions_atts=(atts)    
    logger.info "__________" + atts.to_json
    evt_id = self.id
    atts.each do |status, uidarray|
       uidarray.delete ""
       uidarray.map!{|x| x.to_i}  # convert to int for comparison with ids returned from DB
       existing_se = StatusException.find(:all, :conditions => ["status = ? AND event_id = ? ", status, evt_id])
       existing_se_uids = existing_se.map {|s| s.aux_user_id}
       delete_se = existing_se_uids - uidarray   # these users' exceptions must be deleted
       add_se = uidarray - existing_se_uids      # these are newly added exceptions
       
#       logger.info status.to_s + ":___exist: " + existing_se_uids.to_json + " __ del:" + delete_se.to_json + "||| add: " + add_se.to_json
       
       # delete exceptions that existed, but were removed with this form submission
       existing_se.each do |s|
         s.delete if delete_se.include?(s.aux_user_id)
       end
     
       # add exceptions that did not yet exist.  All other exceptions remain untouched.
       add_se.each do |s|
          self.status_exceptions.build({:status=>status, :aux_user_id => s})
       end
       
    end
  end
  
  def inv_users_ids
    Contact.find(:all, :joins => {:data_templates => :event}, 
                       :conditions => ["events.id = ?", self.id],
                       :select => "contacts.user_id").map {|c| c.user_id}
  end
  
end
