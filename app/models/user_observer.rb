class UserObserver < ActiveRecord::Observer
  def after_create(user)
#    NOTE:  These are sent manually now.
#    # Sent if the user was created through the new user form.
#    UserMailer.deliver_signup_notification(user) if user.standard_create
#    # Sent if user was created because a contact was added to a template
#    UserMailer.deliver_invited_and_create_notification(user) if !user.standard_create
  end
  
  def after_save(user)
#    UserMailer.deliver_activation(user)      if user.recently_activated?
    UserMailer.deliver_forgot_password(user) if user.recently_forgot_password?
    UserMailer.deliver_reset_password(user)  if user.recently_reset_password?
  end
end
