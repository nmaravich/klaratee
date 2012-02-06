class UsersController < ApplicationController
  
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  include UsersHelper
  
  layout "standard"
  
  # Protect these actions behind an admin login
  before_filter :login_required, :except => [:forgot_password, :new, :activate, :reset_password, :create]
  
  # All actions not listed here can be accessed without needed a user logged in.  
  filter_access_to [:index, :new, :edit, :update, :create, :show, :surrogate_set, :surrogate_return] 
  
  def activate
    
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    
    if logged_in? && !current_user.active? 
      current_user.activate!
      #Initialize the current company session var
      session[:cur_company] = current_user.companies.first
      session[:activation_auto_login] = true
      flash[:notice] = "Registration Complete!"
      redirect_to :action => 'landing', :controller => 'login'
    else
    # Klaratee-315.  We were having trouble with users clicking the activation link to log in to the site 
    # even after they have already activated. Once activated the activation code in the db is wiped out and 
    # the user is then unable to login with the link (and was actually getting an error).  Now we warn them.
    flash[:warn] = "Activation has either been completed already, or the code given is invalid.<br />Use the forgot password link if you need to reset your password."
    redirect_to :action => 'new', :controller => 'sessions'
    end
    
  end
  
  def suspend
    @user.suspend! 
    redirect_to users_path
  end
  
  def unsuspend
    @user.unsuspend! 
    redirect_to users_path
  end
  
  def destroy
    @user.delete!
    redirect_to users_path
  end
  
  def purge
    @user.destroy
    redirect_to users_path
  end
  
  def change_password
    return unless request.post?
    if User.authenticate(current_user.login, params[:old_password])
      if ((params[:password] == params[:password_confirmation]) && 
        !params[:password_confirmation].blank?)
        current_user.password_confirmation = params[:password_confirmation]
        current_user.password = params[:password]
        
        if current_user.save
          flash[:notice] = "Password successfully updated" 
          redirect_to profile_url(current_user.login)
        else
          flash[:alert] = "Password not changed" 
        end
        
      else
        flash[:alert] = "New Password mismatch" 
        @old_password = params[:old_password]
      end
    else
      flash[:alert] = "Old password incorrect" 
    end
  end
  
  def surrogate_set
    surrogate_child_id = params[:child_id]
    surrogate_child = User.find_by_id(surrogate_child_id)
    
    if acting_as_surrogate?
      flash[:warn] = "You are already acting as a surrogate.  Leave that surrogate before attempting a new surrogation."
      redirect_back_or_default landing_path
    else
      if surrogate_child.nil?
        flash[:warn] = "Surrogate does not exist."
        redirect_back_or_default landing_path
      else       
        # Policy:        
        #          :Buyer can surrogate to any :Supplier in their customer db
        #          :Admin can surrogate to anyone
        #          :Supplier may not surrogate to anyone (this is protected by decl_auth) 
        if has_role?(:Buyer) && !has_role?(:Admin)  # (if is a pure Buyer, not Admin with Buyer)
          child_roles = surrogate_child.role_symbols
          if child_roles.include? :Supplier and
            ! ( child_roles.include? :Admin or child_roles.include? :Buyer ) and
            AuxUser.exists?(surrogate_child_id)
            
            # This is a pure buyer, surrogating to one of his pure suppliers. This is ok.
            activate_surrogate(surrogate_child_id, surrogate_child)             
            redirect_to landing_path
          else           
            flash[:warn] = "You are not permitted to surrogate to userid #{surrogate_child.id}."
            redirect_back_or_default(landing_path)
          end       
        elsif has_role?(:Admin)
          activate_surrogate(surrogate_child_id, surrogate_child)
          redirect_to landing_path
        else
          flash[:warn] = "Unable to surrogate to #{surrogate_child.login}."
          redirect_back_or_default(landing_path)
        end
      end
    end
  end
  
  def surrogate_return
    if ! acting_as_surrogate?
      flash[:warn] = "You are not currently acting as a surrogate."
      redirect_back_or_default(landing_path)
    else
      AuditRecord.create(current_user.id, session, nil, nil, session[:acting_as_supplier],
      AuditRecord::CATEGORIES[:logout], params[:controller], params[:action], nil)
      
      session[:user] = session[:surrogate_parent][:user_id]
      login_from_session
      return_path = session[:surrogate_parent][:return_path]
      # remove any surrogate session vars that would cause problems to leave around
      session.delete :surrogate_parent
      session.delete :acting_as_supplier
      session.delete :selected_event
      
      if return_path.nil?       
        redirect_to landing_path
      else
        redirect_to return_path 
      end 
    end
  end
  
  #gain email address
  #  layout "no_navs"
  def forgot_password
    return unless request.post?
    if @user = User.find_by_email(params[:user][:email])
      @user.forgot_password
      @user.save
      redirect_back_or_default('/')
      flash[:notice] = "A password reset link has been sent to your email address" 
    else
      flash[:alert] = "Could not find a user with that email address" 
    end
  end
  
  #reset password
  def reset_password
    @user = User.find_by_password_reset_code(params[:id])
    return if @user unless params[:user]
    
    if ((params[:user][:password] && params[:user][:password_confirmation]) && 
      !params[:user][:password_confirmation].blank?)
      self.current_user = @user #for the next two lines to work
      current_user.password_confirmation = params[:user][:password_confirmation]
      current_user.password = params[:user][:password]
      @user.reset_password
      flash[:notice] = current_user.save ? "Password reset success." : "Password reset failed." 
      redirect_back_or_default('/')
    else
      flash[:alert] = "Password mismatch" 
    end  
  end
  
  # switch_db/:id
  # This seemingly insignificant method is important, and perhaps dangerous so pay attention.
  # This is what is called when an admin use chooses to change to another database.
  # Dyna_connect reads this when you hit a controller and then knows which db to connect you to.
  def switch_db
    session[:cur_company] = Company.find_by_id(params[:company][:id]) unless params[:company].nil?
    redirect_to :action => 'landing', :controller => 'login'
  end
  
  protected
  def find_user
    @user = User.find(params[:id])
  end
  
  
end
