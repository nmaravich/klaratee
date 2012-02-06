class ContactUsController < ApplicationController
  
  layout "standard"
  filter_access_to :all
  
  def index
    # render index.html.erb
  end
  
  def create
    # Add the current user to the params because we want to see who sent the email.
    # Currently only logged in users of Klaratee are able to use the contact us feature.
    params[:contact_us][:user] = User.find_by_id(session[:user])

    params[:contact_us][:company_id] = session[:cur_company].id
    
    if valid_message_length? && Notifications.deliver_contact_us(params[:contact_us])
      flash[:notice] = "Thanks for your message!"
      redirect_to contact_us_path 
    else
      flash.now[:error] || "An error occurred while sending this email."
      render :index
    end
  end
  
  private
  # Because the model extends ActionMailer we don't get the rails validations.  We're on our from what I've read.
  def valid_message_length?
    valid = params[:contact_us][:body].size.between?(1,400)
    flash.now[:error] = "Message body must be between 1 and 400 characters. Yours was " << params[:contact_us][:body].size.to_s unless valid
    valid
  end
  
end