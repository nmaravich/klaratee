module FaqsHelper
  def faqs_for_user(faq)
    # get the faqs that are siblings of faq and that the current_user should see
    # this is all of the siblings, except the ones that are private from another user
    if faq.nil?
      faqs = []
    else
      if (has_role?(Role::BUYER.to_sym) || has_role?(Role::ADMIN.to_sym))
        faqs = faq.parent.children
      else 
        faqs = faq.parent.children - Faq.find(:all, :conditions=>["parent_id = ? AND user_id != ? AND visibility='private'", faq.parent_id, current_user.id])
      end      
    end
    faqs
  end

  def filter_user_ids(faqs)     
     return faqs if (has_role?(Role::BUYER.to_sym) || has_role?(Role::ADMIN.to_sym))   # Buyers and Admin see all names
     faqs.each do |f|
        f.user_id = nil if f.user_id != current_user.id
     end
  end

  def insert_faq_edit_link(faq)     
     if (has_role?(Role::BUYER.to_sym) || has_role?(Role::ADMIN.to_sym))       
       return "| " + link_to_function('edit', "faq_modal(#{faq.id}, 'Edit', #{faq.parent_id})") + " " 
     end
  end
  
  def insert_faq_delete_link(faq)     
     if (has_role?(Role::BUYER.to_sym) || has_role?(Role::ADMIN.to_sym))       
        link_to_delete_modal(faq)
     end
  end
  
  
  def update_faq_table_and_replies(page)
    page << "$('#faq-list').replaceWith('" + escape_javascript(render(:partial => "faq_table", :locals => { :faqs => faqs_for_user(@faq), :table_id => "faq-list" })) +"');"
    page << "$('#faq-list_wrapper').after($('#faq-list'));"
    page << "$('#faq-list_wrapper').remove();"
    page << "$('#faq-list').dataTable({'bJQueryUI': true, 'bStateSave': true });"
    if @faq.parent.level == 0 
       page << "$('#faq-replies-#{@faq.id}').replaceWith('" + escape_javascript(render(:partial => "faq_replies", :locals => { :faq => @faq })) +"');"
    else
       page << "$('#faq-replies-#{@faq.parent_id}').replaceWith('" + escape_javascript(render(:partial => "faq_replies", :locals => { :faq => @faq.parent })) +"');"
    end

  end
end
