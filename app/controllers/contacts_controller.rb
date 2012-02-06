class ContactsController < ApplicationController
  layout "standard"
  before_filter :login_required, :dyna_connect
  
  include EventAware 
  before_filter :event_aware, :only => [ :index, :edit, :create, :add_contacts_to_data_template, :remove_contacts_from_data_template]
  
  #  after_filter :print_test_emails  # uncomment to enable printing of emails to the log when in smtp :test mode
  
  filter_resource_access :additional_collection => [:remove_contacts_from_data_template, :add_contacts_to_data_template]
  
  # GET /contacts
  # GET /contacts.xml
  def index
    
    # If no template is selected then show all available contacts, otherwise show contact that haven't already been added to the selected template 
    if !@selected_data_template.nil? && !@selected_data_template.contacts.empty? 
      @available_contacts = Contact.paginate(:all, :page => params[:page], :conditions => ["id NOT IN (?)", @selected_data_template.contacts.map(&:id)  ] )
    else
      @available_contacts = Contact.paginate :page => params[:page]
    end
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  # GET /contacts/1
  # GET /contacts/1.xml
  def show
    @contact = Contact.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
    end
  end
    
  # GET /contacts/1/edit
  def edit
    @contact = Contact.find(params[:id])
  end
  
  # GET /contacts/data_template/1
  def remove_contacts_from_data_template
    @selected_data_template.contacts.delete( Contact.find_all_by_id(params[:current_contacts]) )
    
    # Need to make sure any items associated with this contact on this template are removed.
    respond_to do |format|
      format.js
    end
  end
  
  # GET /contacts/data_template/1/add
  def add_contacts_to_data_template
    
    #    TODO event_aware saves doing this query. We can remove the need for the parameter later if everything works well ( route change would be needed ) - jga 
    #    @dt = DataTemplate.find_by_id(params[:data_template_id])
    @dt = @selected_data_template

    contacts_to_add = Contact.find_all_by_id(params[:available_contacts])
    user_created_ok = true
    contacts_to_add.each do |contact| 
      
      # Look for a User that has the same email as this contact.
      # NOTE: You can't check for username too.  Here's why:
      #  user1: Joe Acklin ( generated username jacklin )
      #  user2: Jeff Acklin ( generated username jacklin345 )
      # Now when you go to invite Jeff Acklin to another event its going to look for jacklin + given email.
      # its not going to find it because jeff acklin is jacklin345 so its going to create a new user, and then
      # give you a validation error because you are trying to save a user that already has that email.
      user = User.with_email(contact.email).first
      
      if user.nil?
        # This contact will be created as a user of the system now so they may login and participate in this template.
        user = create_new_user_from_contact(contact)
        # Create an aux user ( object that ties together a user ( master db level ) to a particular customer database.
        aux_user = create_aux_user_from_user(user)
        # We need the user, aux_user, and contact all to be saved without error.  If one fails then rollback everything.
        user_created_ok = user_creation_transaction?(user, aux_user, contact)
        
        if user_created_ok
          # Send email to the user welcoming them to Klaratee and telling them they've been invited to an event.
          UserMailer.deliver_invited_and_create_notification(user, @dt, session[:cur_company])
          # Add audit table entry for this contact/supplier template invitation
          AuditRecord.create(user.id, session, @dt.event_id, @dt.id, nil, AuditRecord::CATEGORIES[:invitation], params[:controller], params[:action], "Invited by:#{current_user.id}|#{current_user.login}")
        end
        
      else
        # This contact already has a user account.  Just send them an invite, not the new user created invite
        UserMailer.deliver_invited_notification(user,@dt, session[:cur_company])
      end
      
      # This will save to the data_template_contacts table
      @dt.contacts << contact 
    end
    
    respond_to do |format|
      if user_created_ok
        format.js
      else
        # Gather up all the errors ( from validations ) and then put those in the errors string so 
        # the ajax :errors is triggered and it will display the errors on screen.
        all_errors = []
        user.errors.each_full{ |msg| all_errors.push(msg) } rescue nil
        format.json { render :json=> all_errors.join('<br>'), :status => 400  }
      end
    end
    
  end
  
  # POST /contacts
  # POST /contacts.xml
  def create
    @new_contact = Contact.new(params[:contact])
    
    # Used to make sure the message box has the correct format.  This coresponds to a css style.
    @msg_type = 'notice-box'
    
    if @new_contact.save
      @supplier_contact = SupplierContact.new(:contact_type => params[:contact_type], :supplier_id => params[:supplier_id])
      @supplier_contact.contact = @new_contact
      @supplier_contact.save!
      
      @supplier = @supplier_contact.supplier
      
      if @supplier_contact.contact_type == 'primary'
        @replace_div = "primary_contact"
        @contact_list = @supplier.contacts.primary_contacts 
      elsif @supplier_contact.contact_type == 'secondary'
        @replace_div = "secondary_contact"
        @contact_list = @supplier.contacts.secondary_contacts
      else
        logger.error "Invalid Contact Type!"
      end
      
      # This is for circumstances where the same contact exists for more than one company.
      # If you find a user with this email then the user exists already for another company.
      # In this case populate the user.id field to 'link' this contact with the user in the master database
      user = User.find(:first, :conditions => ["email = ?", @new_contact.email ] )
      unless user.nil?
        @new_contact.update_attributes(:user_id => user.id)
        # Need the aux_user table to be populated also.  This links a company user to the master users table
        au = AuxUser.new()
        au.populate_from_user_obj(user)
        au.creator_id = session[:user]
        au.updater_id = session[:user]
        au.save!
      end
      
      respond_to do |format|
        # The creation of contacts is AJAX format.js means call a file named create.js.rjs and do what it says.
        contact= @supplier_contact
        @msg = "Contact saved successfully"
        format.js
      end
      
    else
      @replace_div = "msg-area-#{params[:contact_type]}"
      respond_to do |format|
        @msg_type = 'error-box'
        format.js
      end
    end
    
  end
  
  # PUT /contacts/1
  # PUT /contacts/1.xml
  def update
    
    @contact = Contact.find(params[:id])
    
    if params[:value] == nil
      # traditional edit
      @contact.update_attributes(params[:contact])      
      flash.now[:notice] = "Contact successfully updated."
    else
      # Inline edit.
      @contact.send("#{params[:attr]}=", params[:value].strip )
      has_error = @contact.save
    end
    
    respond_to do |format|
      format.html { render :action => "edit" }
      format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
      unless has_error 
        format.json { render :json=>@contact.errors.full_messages().collect{|err_msg| "<li>" << err_msg << "</li>"}.to_s, :status => :unprocessable_entity } 
      else
        format.json { render :json=>params[:value] } 
      end
    end
    
  end
  
  # DELETE /contacts/1
  # DELETE /contacts/1.xml
  def destroy
    @contact = Contact.find(params[:id])
    @contact.destroy
    
    respond_to do |format|
      format.html { redirect_to(contacts_url) }
      format.xml  { head :ok }
    end
  end
  
  ######################################################  
  private
  ######################################################  
  def print_test_emails
    ActionMailer::Base.deliveries.each do |msg|
      logger.info msg.to_s
    end
    ActionMailer::Base.deliveries.clear
  end
  
  def create_new_user_from_contact(contact)
    # No master User account exists for this contact.  Create one, and then send them the invite_and_create email. 
    # @see views/user_mailer for the email templates.
    user = User.new()
    # create a username in the format of: bsmith ( when contact's name is bob smith )
    user.create_unique_login("#{contact.f_name.first.downcase}#{contact.l_name.downcase}") 
    user.email = contact.email
    user.first_name = contact.f_name
    user.last_name = contact.l_name
    user.creator_id = current_user
    
    # A user needs to be associated with a company so we can determine which customer database they will be connected to.
    user.companies << session[:cur_company] unless user.companies.include?(session[:cur_company])
    
    user.roles << Role.find_by_name(Role::SUPPLIER)
    
    # Sets this virtual attribute so you can see the unencrypted version in the email.
    user.password = user.random_password
    user.password_confirmation = user.password
    
    # Put the user in a pending state.  They'll need to be activated.
    user.register!
    
    return user
  end
  
  # Need to populate the local customer aux_users table for this newly created user.
  def create_aux_user_from_user(user)
    au = AuxUser.new()
    au.populate_from_user_obj(user)
    au.creator_id = current_user
    au.updater_id = current_user
    au
  end
  
  def user_creation_transaction?(user, aux_user, contact)
    # If saving the user or the contact fails we want to rollback
    ActiveRecord::Base.transaction do
      begin
        user.save!
        aux_user.save!
        contact.user_id = user.id # Link contact to a user account ( triggers things like surrogate ability on a contact )
        contact.save!
      rescue Exception=> e
        logger.error "Problem adding contact to template: #{e}"
        return false 
      end
    end 
    true
  end
  
end