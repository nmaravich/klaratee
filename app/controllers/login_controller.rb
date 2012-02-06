class LoginController < ApplicationController
  layout "standard"
  before_filter :login_required, :dyna_connect

  # landing action for all users after login (or registration)
  def landing
       
    # clear session supplier if exists
    session[:acting_as_supplier] = nil
    
    # ensure we are processing one of the expected roles
    if ! has_role?(Role::ADMIN.to_sym) && ! has_role?(Role::SUPPLIER.to_sym) &&
       ! has_role?(Role::BUYER.to_sym)
       
        flash[:error] = "There seems to be a problem with your account.  Please contact the support team."
        redirect_to :controller => 'sessions', :action => 'new'      
    end
        
    if has_role?(Role::SUPPLIER.to_sym) && ! has_role?(Role::ADMIN.to_sym)
      
      # Before contact user redirected, store supplier in session
      # TODO - KLARATEE-222, multi-supplier contacts need to pick a supplier to act as
      
      first_supplier_of_user = Supplier.first_of_user(current_user).first #TODO temporary until we figure this out. afuqua
      if ! first_supplier_of_user.nil?
        logger.debug "Setting session supplier to #{first_supplier_of_user.company_name}"
        session[:acting_as_supplier] = first_supplier_of_user
      else  
        logger.error "WARNING: unable to determine acting supplier for user #{current_user.login}"
      end
      
    end
    
    # Audit the successful login or activation unless admin user
    if ! has_role?(Role::ADMIN.to_sym)
      category = ! session[:activation_auto_login].nil? ?
                    AuditRecord::CATEGORIES[:activation] : AuditRecord::CATEGORIES[:login]

      session.delete :activation_auto_login   # clear from session once recorded in audit log (to avoid multiple entries for activation)
      AuditRecord.create(current_user.id, session, nil, nil, session[:acting_as_supplier],
                     category, params[:controller], params[:action], nil)
                     
    end
                   
    # Forward to the appropriate page based on role
    if has_role?(Role::ADMIN.to_sym) || has_role?(Role::BUYER.to_sym)
        redirect_to :action => 'index', :controller => 'events' 
    elsif has_role?(Role::SUPPLIER.to_sym)
        redirect_to :action => 'as_supplier', :controller => 'supplier_view'             
    else
        flash[:error] = "There seems to be a problem with your account.  Please contact the support team."
        redirect_to :controller => 'sessions', :action => 'new'       
    end
    
  end  
  
end
