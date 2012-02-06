# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  
  before_filter :customer_db_switcher

  include ApplicationHelper # Make this helper available to the controllers.
  include AuthenticatedSystem
  
  helper :all          # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  filter_parameter_logging :password # Scrub sensitive parameters from your log
  
  user_stamp Contact, DataTemplate, DataTemplateColumn, Item, Event, Supplier, SupplierDoc,
  SupplierContact, SupplierNote, Company, Role, User  
  
  # Comment out the following line to enable access control
  Authorization.ignore_access_control(false) 
  
  def permission_denied
    flash.delete :warn if request.format != "html"
    respond_to do |format|
      format.html {   flash[:error] = 'Sorry, you are not allowed to access the requested page.' 
        redirect_back_or_default landing_path }
      format.xml  { head :unauthorized }
      format.js   { head :unauthorized }
    end
  end  
  
  # Will be called from a controllers before_filter, this method allows you to connect
  # to a different database based on the company the current user belongs to.
  # The :cur_company is set in the session when a user logs in
  # @see current_user method in /lib/authenticated_system.
  def dyna_connect
    # TODO Add some checking in here to make sure the given config even exists in the db.yml file.
    #      Also make sure its not nil, etc.  If validation fails forward to a common error page and
    #      throw error.
    if ! session[:cur_company].nil?
      logger.info "\n>** Connecting to customer db: #{session[:cur_company].db_config} **<\n\n"
      # for script_console copy this in there: ActiveRecord::Base.establish_connection('klaratee_development_default' )
      return ActiveRecord::Base.establish_connection( session[:cur_company].db_config )
    end
    
    false
  end  
  
  # This changes declarative_auth from using the User model to using the AuxUser model!
  def set_aux_user
    Authorization.current_user = current_aux_user
  end
  
  # This is called before any controller runs. This is because this selector is needed on every page so the user knows 
  # which customer he is currently connected to.  
  # Right now its just for the klaratee admin
  def customer_db_switcher
    # If the session has timed out cur_company won't be in here so don't 
    # mess with the auth stuff because it will give errors.
    return if session[:cur_company].nil?
    if has_role?(Role::ADMIN.to_sym)
      @companies = Company.all
      @company = session[:cur_company]
    else
      @company = session[:company_in_view]
    end
  end
  
end

##################
# SafeNil -- what it does:  (afuqua)
# Motivation:  if @user.creator.first_name  is called and creator is nil, this leads to an exception. bad.
#              if @user.creator._?.first_name is called and creator is nil, no exception is thrown. good.
# What it means:  in views, we don't have to check for nil before traversing an association that might be nil. clean views. yay.
# maybe we could throw this in a plugin to get it out of this controller.
class Object
  def _?()
    self
  end
end

class NilClass
  def _?
    SafeNil.instance
  end
end

class SafeNil < Object
  include Singleton
  def method_missing(method, *args, &b)
    #    return nil  unless nil.respond_to? method
    nil.send(method, *args, &b)  rescue nil
  end
end
####################### End SafeNil
