authorization do
  
  role :Admin do
    has_permission_on :users, :to => :manage
    has_permission_on :roles, :to => :manage     
    has_permission_on :authorization_rules, :to => :read
    has_permission_on :authorization_usages, :to => :read
    has_permission_on :companies, :to => :manage
    has_permission_on [:supplier_view], :to => [:as_supplier]
    has_permission_on [:contact_us], :to => [:index, :create]
    # These are based on a 'context'.  Declaritive auth doesn't handle actual namespaces, but this seems to work.
    # @see admin/users_controller
    has_permission_on :admin, :to => :index
    has_permission_on :admin_users, :to => [:index, :new, :create, :reset_password, :update_password]
    has_permission_on :admin_fields, :to => :manage
    has_permission_on :admin_settings, :to => :manage
    has_permission_on :faqs, :to => :manage

    # Admin can do anything a buyer can do, but a buyer doesn't do everything a Supplier does!
    includes :Buyer
    
  end
  
  role :Buyer do
    
    has_permission_on [:contact_us], :to => [:index, :create]
    has_permission_on [:events, :items, :item_values,
                       :contacts,
                       :data_templates, :data_template_columns, :data_template_column_possible_values,
                       :supplier_contacts, :suppliers,
                       :supplier_notes, :supplier_docs], :to => :manage
    has_permission_on [:master_items], :to => [:index]
    has_permission_on [:suppliers], :to => [:add_document, :download_document, :remove_contact_from_supplier]
    has_permission_on [:download], :to => [:download_supplier_xls, :master_items_xls, :template_items_xls, :global_activity_xls]
    has_permission_on [:upload], :to =>  [:index, :errors, :supplier_xls, :template_item_upload]
    
    has_permission_on [:data_templates], :to => [:remove_template_column, :remove_contact_from_template]
    has_permission_on [:data_template_columns], :to => [:update_possible_values, :quick_create, :update_order]
    has_permission_on [:contacts], :to => [:remove_contacts_from_data_template, :add_contacts_to_data_template]
    has_permission_on [:reports], :to => [:global_activity]
    has_permission_on [:users], :to => [:surrogate_set, :surrogate_return]
    has_permission_on [:events], :to => [:change_status]
    has_permission_on :faqs, :to => :manage
  end
  
  role :Supplier do
    
    has_permission_on [:contact_us], :to => [:index, :create]
    has_permission_on [:supplier_view], :to => [:as_supplier]
    
    has_permission_on [:items], :to => [:index] do
      if_attribute :invited_to_event => true, :invited_to_template => true, :event_viewable => true                  
      if_attribute :allow_with_no_params => true
    end
    
    has_permission_on :faqs, :to => [:create, :new] do      
      if_attribute :can_create_faq => true
      if_attribute :can_new_faq => true
    end
    
    has_permission_on :faqs, :to => [:update] do
      if_attribute :can_update_faq => true      
      if_attribute :can_get_blank_form => true  # this is just permission to bring up the edit form      
    end       
    
    has_permission_on :faqs, :to => [:read] do
      if_attribute :can_read_faq => true
    end
    
    has_permission_on [:users], :to => [:surrogate_return]
    
    # create, :show, :update, :delete if the user is connected to the supplier that uploaded an item?
    # ????
    has_permission_on [:items], :to => [:manage_noindex] do
      if_attribute :supplier_id => is_in { user.supplier_ids}
    end
    
    has_permission_on [:items], :to => [:new, :create] do
      if_attribute :can_create => true
    end
    
    # Verify a user can only view events they have been invited to
    # @see event :invited_users - Basically join the templates to this event and make sure the user has been invited to it.    
    has_permission_on [:events], :to => [:show] do
      if_attribute :invited_users => contains { Authorization::current_user }
    end
    
    has_permission_on [:upload], :to =>  [:index, :errors, :template_item_upload] do
      if_attribute :can_ul_this_template => true
    end
    
    has_permission_on [:download], :to => [:template_items_xls] do
      if_attribute :can_dl_this_template => true
    end
    
  end
  
end

privileges do
  privilege :manage, :includes => [:create, :read, :update, :delete]
  privilege :manage_noindex, :includes => [:create, :show, :update, :delete]
  privilege :create, :includes => :new
  privilege :read, :includes => [:index, :show]
  privilege :update, :includes => :edit  
  privilege :delete, :includes => :destroy
end