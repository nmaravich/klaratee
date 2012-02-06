class AuxUser < ActiveRecord::Base
  user_stampable
  has_many :contacts, :foreign_key => :user_id
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  # AuxUsers are a company level model so you can't easily fetch their roles
  # This method finds the master user and returns you their roles.
  def roles    
    
    # Stash away the db the user is currently connected to ( aka which company )
    connection_spec = self.connection.instance_variable_get "@config"
    # Connect to the master db so you can get the user's roles.
    ActiveRecord::Base.establish_connection(ENV["RAILS_ENV"])
    @myroles = User.find(self.id).roles    
    # Switch back to original company db
    ActiveRecord::Base.establish_connection( connection_spec )

    return @myroles
  end
  
  # returns the supplier_ids of all suppliers this user is associated
  # @see authorization_rules
  # @see user.supplier_ids ( which just calls this method )
  def supplier_ids
    Supplier.find(:all, :joins => [:supplier_contacts => [:contact => :user]], 
                        :conditions => ['aux_users.id= ? ', self.id ],
                        :select => 'suppliers.id').map {|s| s.id}
  end

  # finds all suppliers this user is associated with
  def suppliers
    Supplier.find(:all, :joins => [:supplier_contacts => [:contact => :user]], 
                        :conditions => ['aux_users.id= ? ', self.id ])
  end

  def invited_data_template_ids
    DataTemplate.find(:all, 
                      :joins => [:data_template_contacts => [:contact => :user]],
                      :conditions => ['aux_users.id=?', self.id],
                      :select => 'data_templates.id').map {|dt| dt.id}
  end
  
  def role_symbols
   (roles || []).map {|r| r.name.to_sym}
  end
  
  def invited_to_event?(event_id) 
    # with_invitee - call to a named scope in Event model
    Event.with_invitee(self).count(:all, :conditions => ['events.id = ?', event_id]) > 0                                  
  end

  def invited_to_template?(template_id)
    # with_invitee - call to a named scope in DataTemplate model
    DataTemplate.with_invitee(self).count(:all, :conditions => ['data_templates.id = ?', template_id]) > 0
  end
  
  def invited_event_ids
    # with_invitee - call to a named scope in Event model
    Event.with_invitee(self).find(:all, :select => "events.id").collect {|c| c.id}
  end
  
  # given a data_template, find the supplier that this user should act under
  def find_supplier_from_dt(dt)
    # TODO - Implement me, or delete me
  end
  
  # You usually create AuxUsers based of an existing user. This is a shortcut for that.
  def populate_from_user_obj(user_obj)
    self.id = user_obj.id
    self.login = user_obj.login
    self.email = user_obj.email
    self.first_name = user_obj.first_name
    self.last_name = user_obj.last_name
    self.creator_id = user_obj.id
    self.updater_id = user_obj.id
  end
  

end