module ContactsHelper

  def template_list_for_contact(contact)  
    contact.data_templates.collect{|t| t.name }.join(', <br/>')
  end
  
  def supplier_list_for_contact(contact)
    contact.suppliers.collect{|s| s.company_name }.join(', <br/>')
  end
  
  def event_not_opened_warning
    html=[]
    if !@selected_data_template.nil? && !@selected_data_template.event.status_open? 
      html << "<div id='warning-box'>Event is not open so you can't add or remove any contacts.</div>"
    end
    html
  end
  
  # The _contacts_list partial is shared for both current and available contacts.
  # The form needs to have the correct action set.
  def determine_form_action(contact_type)
    case contact_type
      when 'available' then return 'add_contacts_to_data_template' 
      when 'current'   then return 'remove_contacts_from_data_template'
    end
  end
  
  def determine_button_label(contact_type)
    case contact_type
      when 'available' then return 'Add to template' 
      when 'current'   then return 'Remove from template'
    end
  end
  
  def determine_confirm_message(contact_type)
    case contact_type
      when 'available' then @custom_message="Inviting contact(s) from a template will: <ul><li>Allow contact(s) to see this template, and add items using it.</li><li>Send an email to the contact(s) informing them they have been invited.</li></ul>" 
      when 'current'   then @custom_message="Removing contact(s) from a template will: <ul><li>Prevent contact from seeing this template</li></ul>"
    end
  end
  
  def create_submit_link(contact_type)

    link_text=""
    confirm_msg=determine_confirm_message(contact_type)
    case contact_type
      when 'available' then link_text="Add selected contact(s) to template"  
      when 'current'   then link_text="Remove selected contact(s) from template" 
    end
   
   link_to_function link_text, "confirmation_modal('#{contact_type}_form','#{confirm_msg}')", :class => "action-button" if @selected_data_template.event.status_open?
    
  end
  
end
