module AuthenticatedSystem
  protected
  # Returns true or false if the user is logged in.
  # Preloads @current_user with the user model if they're logged in.
  def logged_in?
    !!current_user
  end
  
  # Accesses the current user from the session. 
  # Future calls avoid the database because nil is not equal to false.
  def current_user
    @current_user ||= (login_from_session || login_from_basic_auth || login_from_cookie) unless @current_user == false    
  end
  
  def current_aux_user
    @current_aux_user ||= AuxUser.find_by_id(current_user.id)
  end
  
  # CUSTOMIZED: Modified to put the company of this user into the session for easy access later
  def current_user=(new_user)
    session[:user] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : new_user.id
    @current_user = new_user
  end
  
  # Check if the user is authorized
  #
  # Override this method in your controllers if you want to restrict access
  # to only a few actions or if you want to check if the user
  # has the correct rights.
  #
  # Example:
  #
  #  # only allow nonbobs
  #  def authorized?
  #    current_user.login != "bob"
  #  end
  def authorized?
    logged_in?
  end
  
  # Filter method to enforce a login requirement.
  # To require logins for all actions, use this in your controllers:
  #
  #   before_filter :login_required
  #
  # To require logins for specific actions, use this in your controllers:
  #
  #   before_filter :login_required, :only => [ :edit, :update ]
  #
  # To skip this in a subclassed controller:
  #
  #   skip_before_filter :login_required
  #
  def login_required
    authorized? || access_denied
  end
  
  # Redirect as appropriate when an access request fails.
  #
  # The default action is to redirect to the login screen.
  #
  # Override this method in your controllers if you want to have special
  # behavior in case the user is not authorized
  # to access the requested action.  For example, a popup window might
  # simply close itself.
  def access_denied
    # Modified this to be on the lookout for session timeout's as well. - JGA
    flash[:error] = "You must login before accessing this page."
    flash[:error] = "For security reasons you have been timed out due to inactivity. Please log in again." if session[:current_user].nil?
    
    respond_to do |format|
      format.json { 
        render :json  => "For security reasons you have been timed out due to inactivity. <br/>Your changes were likely not saved.  Please login again.", :status => :failure  
      }
      format.html do
        store_location
        redirect_to new_session_path
      end
    end
  end
  
  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.request_uri
  end
  
  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
  
  # Inclusion hook to make #current_user and #logged_in?
  # available as ActionView helper methods.
  def self.included(base)
    base.send :helper_method, :current_user, :logged_in?
  end
  
  # Called from #current_user.  First attempt to login by the user id stored in the session.
  def login_from_session
    self.current_user = User.find_by_id(session[:user]) if session[:user]
    # NOTE: I changed this because you can't use the User.find_by_cur_user from here
    # Its an activerecord method, and calling here won't set the database correctly
    # See application_controller dyn_connect ( which is called in controllers :before_filter )
    #    self.current_user = User.find_cur_user(session[:user]) if session[:user]
  end
  
  # Called from #current_user.  Now, attempt to login by basic authentication information.
  def login_from_basic_auth
    authenticate_with_http_basic do |username, password|
      self.current_user = User.authenticate(username, password)
    end
  end
  
  # Called from #current_user.  Finaly, attempt to login by an expiring token in the cookie.
  def login_from_cookie    
    user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
    if user && user.remember_token?
      cookies[:auth_token] = { :value => user.remember_token, :expires => user.remember_token_expires_at }
      self.current_user = user
    end
  end
  
end
