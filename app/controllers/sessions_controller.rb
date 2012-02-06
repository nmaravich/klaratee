# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  
  layout "login"
  # If a timeout occurs and attempts to redirect back to here you'll get an authorization token error.
  protect_from_forgery :except => :create
  
  # render new.rhtml
  def new
    company_name = params[:company]
    company_name = 'default' if company_name.blank?
    @company = Company.find_by_name(company_name)
    if @company.nil? 
      flash[:warn] = "That ('#{company_name}') 'is an invalid path."
      redirect_back_or_default (landing_path)
    end
    session[:company_in_view] = @company
    session.delete :surrogate_parent
  end
  
  def create
    self.current_user = User.authenticate(params[:login], params[:password])
    @company_in_view = session[:company_in_view]
    if logged_in?
      if params[:remember_me] == "1"
        current_user.remember_me unless current_user.remember_token?
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      
      # If a user is associated with > 1 companies they must choose which one they want to use.
      # Otherwise we wouldn't know which db to connect them to.
      if !params[:company_id].nil?
        session[:cur_company] = (current_user.companies.detect {|c| c.id = params[:company_id] })
      else
        if @company_in_view.nil? || ! current_user.companies.include?(@company_in_view)
          session[:cur_company] = current_user.companies.first
          # commented out next line as I do not see the need to confuse the user with this message
          #flash[:warn] = "You are not associated with #{@company_in_view._?.name}.  You are being logged in through #{session[:cur_company].name} instead."
          @company_in_view = session[:company_in_view] = session[:cur_company] 
        else
          session[:cur_company] = @company_in_view
        end
      end
      
      flash.now[:notice] = "Logged in successfully"
      
      # redirect to landing action, which dynamically determines a user's landing page
      redirect_back_or_default('/landing')
    else
      flash.now[:notice] = "Invalid username / password combination."
      render :action => 'new'
    end
  end
  
  def destroy
    if !has_role?(Role::ADMIN.to_sym) && !session[:cur_company].nil?
      # Manually connect to the customer DB and write the logout to the audit log
      ActiveRecord::Base.establish_connection(session[:cur_company].db_config)
      AuditRecord.create(current_user.id, session, nil, nil, session[:acting_as_supplier],AuditRecord::CATEGORIES[:logout], params[:controller], params[:action], nil)
    end
        
    company_name = @company.nil? ? '' : @company.name
    company_name = '' if company_name == 'default'
    
    # Clear the session and cookies
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    
    # reset_session
    request.session_options[:renew] = true
    request.session_options[:drop] = true
    reset_session

        
    flash[:notice] = "You have been logged out."
    #render :template => 'sessions/new'
    redirect_to "/#{company_name}"  # redirect to the company's login page. byproduct of this is that the flash msg is not displayed
                                    # but that is the trade-off we have to make to have the /companyname in the url.
  end
end
