ActionController::Routing::Routes.draw do |map|
  map.resources :contacts
  
  map.resources :item_values
  
  map.resources :faqs
  map.resources :items
  map.resources :master_items
  
  map.resources :data_template_columns
  
  map.resources :supplier_docs
  
  map.resources :supplier_notes
  # -------------------------------------------------  
  #  Just copied these over not sure if they are needed
  # resource maps of authentication models
  #  map.resources :sessions
  #  map.with_options :controller => 'sessions' do |session|
  #    session.login  '/login',  :action => 'new'
  #    session.logout '/logout', :action => 'destroy'
  #  end
  # -------------------------------------------------  
  
  map.resources :roles
  
  map.resources :data_templates
  
  map.resources :suppliers
  
  map.resources :events
  
  map.resources :companies
  
  map.resource :session
  
  map.resources :upload
  
  map.resources :download
  
  map.resources :system_settings
  
  map.landing 'landing', :controller => 'login', :action => 'landing'    
  
  map.connect 'reports/global_activity', :controller => 'reports', :action => 'global_activity'    
  
  map.connect 'settings', :controller => 'system_settings', :action => 'index'    
  map.connect 'settings/:id', :controller => 'system_settings', :action => 'edit'    
  
  map.connect 'supplierview/:action', :controller => 'supplier_view' 
  
  map.connect 'supplier_xls', :controller => 'upload', :action => 'supplier_xls'
  
  map.connect 'download_supplier', :controller => 'download', :action => 'download_supplier_xls'
  
  map.connect 'download_template_items', :controller => 'download', :action => 'template_items_xls'
  map.connect 'download_master_items', :controller => 'download', :action => 'master_items_xls'
  map.connect 'download_global_activity', :controller => 'download', :action => 'global_activity_xls'
  
  map.connect 'template_item_upload', :controller => 'upload', :action => 'template_item_upload'
  
  map.connect 'item_upload_results', :controller => 'upload', :action => 'index'
  map.connect 'item_upload_errors', :controller => 'upload', :action => 'errors'
  
  # TODO Possible orphaned route ( function is tagged as todo also )
  map.connect 'data_templates/:id/remove_template_column/:col', :controller => 'data_templates', :action => 'remove_template_column'
  map.connect 'data_templates/:id/contact/:contact', :controller=>'data_templates', :action => 'remove_contact_from_template'
  
  map.connect 'contacts/data_template/:data_template_id/add', :controller => 'contacts', :action => 'add_contacts_to_data_template'
  map.connect 'contacts/data_template/:data_template_id',     :controller => 'contacts', :action => 'remove_contacts_from_data_template'
  
  map.connect 'suppliers/:id/add_document', :controller => 'suppliers', :action => 'add_document'
  
  map.change_status  'events/:id/change_status', :controller => 'events', :action => 'change_status'
  # orphaned?: TODO: cleanup all orphaned routes 
  map.connect 'suppliers/:id/contact/:contact', :controller => 'suppliers', :action => 'remove_contact_from_supplier'
  
  
  map.connect 'data_template_columns/:id/update_possible_values', :controller => 'data_template_columns', :action => 'update_possible_values'
  map.connect 'data_template_columns/quick_create', :controller => 'data_template_columns', :action => 'quick_create'
  map.connect 'data_template_columns/:id/update_order', :controller => 'data_template_columns', :action => 'update_order'
  
  map.connect 'users/switch_db/:id', :controller=>'users', :action=>'switch_db'
  
  map.surrogate_set 'surrogate_set/:child_id', :controller=>'users', :action=>'surrogate_set'
  map.surrogate_return 'surrogate_return',  :controller=>'users', :action=>'surrogate_return'
  
  # ------------------------------------------------------------------------------                                             
  # Added by me when doing the restful_auth / acts_as_state_machine stuff
  # map.resources :users
  #  map.resources :users, :member => { :suspend => :put, :unsuspend => :put, :purge => :delete }
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate'
  # No more signup.  Users are created in the admin section now.
  #  map.signup '/signup', :controller => 'users', :action => 'new'
  map.login  '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.forgot_password '/forgot_password', :controller => 'users', :action => 'forgot_password'
  map.reset_password '/reset_password/:id', :controller => 'users', :action => 'reset_password'  
  # ------------------------------------------------------------------------------                                             
  
  map.connect 'suppliers/:id', :controller => 'suppliers', :action => 'update'
  
  map.supplier_doc_download 'suppliers/download/:id', :controller => 'suppliers', :action => 'download_document'
  
  map.with_options :controller => 'contact_us' do |contact|
    contact.contact_us '/contact_us',
    :action => 'index',
    :conditions => { :method => :get }
    
    contact.contact_us '/contact_us',
    :action => 'create',
    :conditions => { :method => :post }
  end
  
  # ----  ADMIN ROUTES ---- #
  map.reset_password 'admin/reset_password/:id', :controller => 'admin/users', :action => 'reset_password'
  map.reset_password 'admin/update_password/:id', :controller => 'admin/users', :action => 'update_password'
  map.edit_model 'admin/fields/dynamo', :controller => 'admin/fields', :action => 'edit'
  map.edit_model 'admin/fields/delete', :controller => 'admin/fields', :action => 'destroy', :method=>:delete
  
  # This is how you handle the admin/ namespace.
  map.namespace :admin do |admin|
    # Directs /admin/users/* to Admin::UsersController (app/controllers/admin/users_controller.rb)
    admin.resources :users
    admin.resources :admin
    admin.resources :fields
    admin.resources :settings
  end  
  # ----------------------- #
  
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action
  
  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)
  
  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products
  
  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }
  
  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end
  
  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end
  
  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  
  # See how all your routes lay out with "rake routes"
  
  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect '/', :controller => 'sessions', :action => 'new'
  
  map.connect "/*company", :controller => 'sessions', :action => 'new'
  
  # catch badly formed requests
  map.connect "*anything.:ext", :controller => 'sessions', :action => 'unknown_request'
  map.connect "*anything", :controller => 'sessions', :action => 'unknown_request'
  
end
