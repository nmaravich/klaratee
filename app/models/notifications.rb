class Notifications < ActionMailer::Base

  def contact_us(email_params)

    subject "[Klaratee Contact Us] " << email_params[:subject]
    
    email_safety_val = SystemSettingService.get_value_for_key('email_safety.enabled', email_params[:company_id])
    
    if email_safety_val != 'no'
      safety_address_val = SystemSettingService.get_value_for_key('email_safety.forward_to_email', email_params[:company_id])
      recipients safety_address_val
      safety_dance = "** EMAIL SAFETY TURNED ON.  Intended recipient: #{SUPPORT_EMAIL} **"
    else  
      recipients "#{SUPPORT_EMAIL}"
    end
        
    from SUPPORT_EMAIL
    sent_on Time.now.utc
    
    body :safety_dance => safety_dance, :message => email_params[:body], :login => email_params[:user]['login'], :user_email => email_params[:user]['email']
  end
  
end