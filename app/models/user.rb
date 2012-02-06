require "digest"
require 'digest/sha1'

class User < ActiveRecord::Base
  
  # Connect to the master db  
  establish_connection RAILS_ENV
  
  # :password - Virtual attribute for the unencrypted password
  # :standard_create - virtual attr to help determine which method was used to create this user.
  #                    if true then the user was created via the user create form.
  #                    At this point if its false then it was created because a contact was invited to a template.
  #                    In the future is there are other ways a user gets created that we need to track we'll need to
  #                    handle this a different way. 
  attr_accessor :password, :standard_create
  
  # Associations
  has_many :user_groups
  has_many :groups, :through => :user_groups
  has_many :user_products
  has_many :products, :through => :user_products
  user_stampable :stamper_class_name => :user
  
  # the join_table has to be specified here. obviously we want to set this from a yaml variable or ENV
  # before going to production.  This is one of the quirks of using multiple DB's.  The habtm join table
  # somehow is expected to be in the customer DB, no matter that the user and role tables are in the master.
  # so here, we specify it explicitly.  maybe there's a better workaround. -Andrew
  has_and_belongs_to_many :roles, :order => "roles.description ASC", :join_table => "#{self.connection.current_database}.roles_users"
  has_many :company_users
  has_many :companies, :through => :company_users
  
  # Now these can be used easily in other places when you need to know the lengths ( like generating a login )
  PW_RULES =    {'min_size'=>6, 'max_size'=>40}.freeze
  LOGIN_RULES = {'min_size'=>5, 'max_size'=>20}.freeze
  EMAIL_RULES = {'min_size'=>6, 'max_size'=>60}.freeze
  
  # scopes
  named_scope :with_email, lambda { |email| {:conditions=>["email=?", email]}}
  
  # Validations
  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => PW_RULES['min_size']..PW_RULES['max_size'], :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => LOGIN_RULES['min_size']..LOGIN_RULES['max_size']
  validates_length_of       :email,    :within => EMAIL_RULES['min_size']..EMAIL_RULES['max_size']
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  
  # Callbacks
  before_save :encrypt_password
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :first_name, :last_name, :role_ids
  
  acts_as_state_machine :initial => :pending
  
  state :passive
  state :pending, :enter => :make_activation_code
  state :active,  :enter => :do_activate
  state :suspended
  state :deleted, :enter => :do_delete
  
  event :register do     
    transitions :from => :passive, :to => :pending, :guard => Proc.new {|u| !(u.crypted_password.blank? && u.password.blank?) }
  end
  
  event :activate do
    transitions :from => :pending, :to => :active 
  end
  
  event :suspend do
    transitions :from => [:passive, :pending, :active], :to => :suspended
  end
  
  event :delete do
    transitions :from => [:passive, :pending, :active, :suspended], :to => :deleted
  end
  
  event :unsuspend do
    transitions :from => :suspended, :to => :active,  :guard => Proc.new {|u| !u.activated_at.blank? }
    transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| !u.activation_code.blank? }
    transitions :from => :suspended, :to => :passive
  end
  
  # Default the standard_create to false.
  # This is set to true when a user is created via the new user form.
  # We need to tell if a user was created via the form, or some system process like when a contact
  # is invited to a template.
  def standard_create 
    @standard_create ||= false
  end
  
  # This will find the supplier_ids this user is associated within the 
  # database this user is currently connected to.  
  # its used in authorization_rules to figure out which items this particular user is able to see.
  # They should only be able to see those items that they have uploaded themselves and not the items uploaded
  # by some other supplier for this company.
  def supplier_ids
    AuxUser.find(self.id).supplier_ids
  end
  
  # some ruby sweetness here. If the method is not found in User, look for it in AuxUser.
  # what does this buy you? This is mainly useful from authorization_rules.rb where we only have access to
  # 'user' which is current_user.  But we need an AuxUser to :join with all of the customer table objects.
  # so just call, for example, <User>.invited_event_ids and even though the method doesn't exist in User, the call gets
  # transferred down to an AuxUser object.
  #  def method_missing(method, *args, &b)
  ##    return nil  unless nil.respond_to? method
  #    au = AuxUser.find(self.id)
  #    au.send(method, *args, &b)  rescue nil
  #  end
  #  
  # CUSTOMIZED: This is called from the authenticated_system login_from_session method.
  # Had to change from calling there because we need to make sure you're connected
  # to the current database.
  def self.find_cur_user(user_id)
    # This ensures you connect to the correct main database ( :development, :production )
    # In most cases db calls are made from the controller, and they handle the connection via
    # the dyn_connect method of the application_controller.
    # ActiveRecord::Base.establish_connection( ENV["RAILS_ENV"] )
    User.find_by_id( user_id )  if user_id
  end
  
  # needed by declarative_authorization
  def role_symbols
   (roles || []).map {|r| r.name.to_sym}
  end
  
  # CUSTOMIZED: Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    
    # ActiveRecord::Base.establish_connection( ENV["RAILS_ENV"] ) # Original code.
    u = User.find(  :first, :conditions => [ "login = ? AND state = 'active'", login ]  )    
    !u.nil? && u.authenticated?(password) ? u : nil
  end
  
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end
  
  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end
  
  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end
  
  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end
  
  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end
  
  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end
  
  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  
  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
  
  def forgot_password
    @forgotten_password = true
    self.make_password_reset_code
  end
  
  def reset_password
    # First update the password_reset_code before setting the 
    # reset_password flag to avoid duplicate email notifications.
    update_attributes(:password_reset_code => nil)
    @reset_password = true
  end  
  
  #used in user_observer
  def recently_forgot_password?
    @forgotten_password
  end
  
  def recently_reset_password?
    @reset_password
  end
  
  def recently_activated?
    @recent_active
  end
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def random_password(size=10)
    alphanumerics = [('0'..'9'),('A'..'Z'),('a'..'z')].map {|range| range.to_a}.flatten
     (0...size).map { alphanumerics[Kernel.rand(alphanumerics.size)] }.join
  end
  
  # We have to insure a unique login
  # The validation will give an error if login isn't unique when the system creates a user
  # like in the case of a contact being invited to a template, we can use this method to generate
  # something unique that we can use.
  def create_unique_login(potential_login)
    
    # If potential_login isn't of the proper length then pad it until it is.
    while potential_login.size < LOGIN_RULES['min_size']
      potential_login = "#{potential_login}#{rand(9)}"
    end
    
    # If the potential login is taken then add a 3 digit number to the end. Do this until a unique login is found
    while !User.find(:first, :conditions => ["login = ?", potential_login ] ).nil? do
      potential_login = "#{potential_login}#{rand(999)}"
    end
    
    self.login = potential_login
  end 
  
  #########################################
  
  protected
  
  def make_password_reset_code
    self.password_reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end
  
  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  # def make_activation_code
  def make_activation_code 
    return if activation_code    
    # CUSTOMIZED: There was a bug in the plugin where if you don't return if activation_code exists
    # then it'll generate the code again and send that new code in the email.  At this point the 
    # user will have a code in email that doesn't match the code in the datbase.
    self.deleted_at = nil
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
  
  def do_delete
    self.deleted_at = Time.now.utc
  end
  
  def do_activate
    @activated = true
    self.activated_at = Time.now.utc
    self.deleted_at = self.activation_code = nil
  end
  
end

##########################################

private 
def generate_code
  Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
end
