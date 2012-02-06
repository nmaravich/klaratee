module SupplierViewHelper

   def action_section(link_text, toggle_div_id)
      html=[]
      html << "<div class=\"actions\">"
      html <<  link_to_function(link_text, "$(\"\##{toggle_div_id}\").toggle()")
      html << "</div>"
   end

   def special_section_heading(heading)
      "<div class=\"suppliers-minor-color long-heading\"><h3>#{heading}</h3></div>"
   end

   def render_contact_area(supplier, type='primary')
      html=[]
      html << special_section_heading("#{type.capitalize} Contacts")
      html << action_section("Add New #{type} Contact", "add-#{type}-contact" )
      html << "<div id=\"msg-area-#{type}\"></div>"
      html << "<div id=\"add-#{type}-contact\" class=\"hide\">"
      html << render( :partial => "add_contact", :locals => { :c_type => type, :update_div => "#{type}_contact" } )
      html << "</div>"
      html << "<div id=\"#{type}_contact\">"
      if supplier.contacts.send("#{type}_contacts") != nil
         html << render( :partial => "contacts", :collection => supplier.contacts.send("#{type}_contacts"), :as => :contact )
      else
         html << "<div class=\"subtle_msg\">No Contacts</div>"
      end
      html << "</div>"
   end

   # xss safe output of a contact field value.
   # Note the field will be inline editable.
   def contact_field(contact, field_name, label=field_name)
      html=[]
      style="edit"
      html << "<label>#{label}</label>"
      val = html_escape(contact.send(field_name))
      if val.blank?
        val = 'Click to edit' 
        style << " subtle-text"
      end
      html << "<span id=\"#{field_name}\-#{contact.id}\" class=\"#{style}\">#{val}</span><br>"
   end

end
