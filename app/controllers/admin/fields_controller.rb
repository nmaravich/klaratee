class Admin::FieldsController < ApplicationController
  layout 'standard'
  
  before_filter :login_required, :dyna_connect
  # These are based on a 'context'.  Declaritive auth doesn't handle actual namespaces, but this seems to work.
  # See the authorization_rules file to see how we read this to allow permission
  filter_access_to :all, :context => :admin_fields
  
  def index
    # We need to populate a dropdown of all the models someone is able to add dynamic attributes to.
    # This solution is based on what I found on this post: 
    # http://stackoverflow.com/questions/516579/is-there-a-way-to-get-a-collection-of-all-the-models-in-your-rails-app
    @dynamo_models = []
    ActiveRecord::Base.send(:subclasses).each do |model|
      @dynamo_models << model.name if model.instance_methods.include?('is_dynamo_field?')
    end
    
    respond_to do |format|
      format.html # index.html.erb
    end    
  end
  
  # Edit a model( add / delete dynamic fields )
  def edit
    # Reflection to get a class for the model name passed in.
    @dynamo_model = Kernel.const_get(params[:model_name])
    respond_to do |format|
      format.html # edit.html.erb
    end    
  end
  
  # Create a new dynamic field for the given model
  def create
    errors = []
    begin
      @dynamo_model = Kernel.const_get(params[:model_name])
      model = @dynamo_model.add_dynamo_field( params[:field_name], params[:field_type] )
      errors << model.errors.full_messages() unless model.errors.blank?
    rescue Exception => e
      errors << e      
    end
    
    flash[:error]=errors.collect{|err_msg| "<li>" << err_msg << "</li>"}.to_s unless errors.empty?
    respond_to do |format|
      format.html { render :html=>@dynamo_model, :controller => "admin/fields", :action=>"edit"}
    end
    
  end
  
  # Remove a dynamo field from the given model
  def destroy
    Kernel.const_get(params[:model_name]).remove_dynamo_field(params[:field_name])
    redirect_to :controller => "admin/fields", :action => "edit", :model_name=>params[:model_name]
  end
  
end