    class UserMailer < ActionMailer::Base
      
      def signup_notification(user, company)
        setup_email(user, company.id)
        @subject    += 'Activate Account'
        @body[:url]  = "#{SITE}/activate/#{user.activation_code}"
      end
      
      # This is for when a contact is invited to a template and they don't already have a user account.
      def invited_and_create_notification(user, data_template, company)
        setup_email(user, company.id)
        @subject    += 'Event Invitiation'
        @body[:url]  = "#{SITE}/activate/#{user.activation_code}"
        @body[:loginurl]  = "#{SITE}/#{company.name}"
        @support_email = "#{SUPPORT_EMAIL}"
        @invited_to_event = "#{data_template.event.name}"
        @invited_to_template = "#{data_template.name}"
      end
      
      # This is for when the contact is invited to a template and they already have a user account 
      def invited_notification(user, data_template, company)
        setup_email(user, company.id)
        @subject    += 'Event Invitiation'
        @body[:url]  = "#{SITE}/#{company.name}"
        @support_email = "#{SUPPORT_EMAIL}"
        @invited_to_event = "#{data_template.event.name}"
        @invited_to_template = "#{data_template.name}"
      end
      
      def activation(user)
        setup_email(user, 0)
        @subject    += 'Your account has been activated!'
        @body[:url]  = "#{SITE}/"
      end
      
      def forgot_password(user)
        setup_email(user, 0)
        @subject    += 'You have requested to change your password'
        @body[:url]  = "#{SITE}/reset_password/#{user.password_reset_code}" 
      end
      
      def reset_password(user)
        setup_email(user, 0)
        @subject    += 'Your password has been reset.'
      end
      
      protected
      
      # Make sure everyone calls setup_email because the EMAIL_SAFETY is handled here!
      # If you create your own setup_email be sure to account for the EMAIL_SAFETY switch!
      def setup_email(user, company_id)
        # Check the environment files for each environment for these settings.
        # EMAIL_SAFETY will make sure email messages don't go out to real people in dev and staging environments.
        
        email_safety_val = SystemSettingService.get_value_for_key('email_safety.enabled', company_id)
        
        if email_safety_val != 'no'
          safety_address_val = SystemSettingService.get_value_for_key('email_safety.forward_to_email', company_id)
          
          recipients safety_address_val
          safety_dance = "** EMAIL SAFETY TURNED ON.  Intended recipient: #{user.email} **"
        else  
          recipients "#{user.email}"
        end
        #bcc        "support@klaratee.com"
        from       "support@klaratee.com"
        subject    "Klaratee: "
        body       :user => user, :safety_text => safety_dance
        sent_on    Time.now
      end
      
    end  
    
