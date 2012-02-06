class Admin::UsersController < ApplicationController
  layout 'standard'
  
  before_filter :login_required, :dyna_connect
    # These are based on a 'context'.  Declaritive auth doesn't handle actual namespaces, but this seems to work.
  filter_access_to :all, :context => :admin_users
  
  def index
    @users = User.find(:all)
    respond_to do |format|
      format.html # index.html.erb
    end    
  end
  
  def new
    @roles = Role.all
    @user = User.new
  end
  
  def create
    cookies.delete :auth_token
    # Create a new user from the items passed in the form
    @user = User.new(params[:user])
    # The user needs associated with a company. It will be whatever company is in the db switcher at the moment.    
    @user.companies << session[:cur_company]
    # Now that the activation code is available do the save that gets the extra attrs in here.
    @user.save
    # Activate this user so they can log in.  
    @user.activate!
    # We need to populate the aux_users table for the specific customer with some of this user information
    if @user.errors.empty?
      au = AuxUser.new()
      au.populate_from_user_obj(@user)
      au.save!
    end
    
    if @user.errors.empty?
      flash[:notice] = "User successfully created and attached to company: '#{session[:cur_company].name}''."
      redirect_to :controller => "admin/users", :action => "index"
    else
      respond_to do |format|
        @roles = Role.all
        format.html { render :action => "new" }
      end
    end
  end
  
  #reset password
  def reset_password
  end  
  
  def update_password
    user = User.find_by_id(params[:id])
    if (params[:user][:password] == params[:user][:password_confirmation] && !params[:user][:password].empty? && !params[:user][:password_confirmation].empty?)
      user.password_confirmation = params[:user][:password_confirmation]
      user.password = params[:user][:password]
      flash[:notice] = user.save ? "Password reset success." : "Password reset failed."
      respond_to do |format|
        format.html { redirect_to :action => "index" }
      end
    else
      flash[:error] = "Password and confirm must match, and they cannot be blank."
      render :action => 'reset_password'
    end
    
  end
  
end