class DataTemplatesController < ApplicationController
  
  layout "standard"
  before_filter :login_required, :dyna_connect
  
  include EventAware 
  before_filter :event_aware, :only => [ :index, :edit, :create ]
  
  filter_resource_access :additional_collection => [:remove_template_column, :remove_contact_from_template]
  filter_resource_access
  
  # GET /data_templates
  # GET /data_templates.xml
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @ea_data_templates }
    end
  end
  
  # GET /data_templates/1
  # GET /data_templates/1.xml
  def show
    @data_template = DataTemplate.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @data_template }
    end
  end
  
  # GET /data_templates/new
  # GET /data_templates/new.xml
  def new
    @data_template = DataTemplate.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @data_template }
    end
  end
  
  # GET /data_templates/1/edit
  def edit
    @data_template = DataTemplate.find_by_id( params[:id] )
    # Use EventAware module to set this event to be currently selected
    force_set_selected_event(@data_template.event)
  end
  
  # POST /data_templates
  # POST /data_templates.xml
  def create
    
    if ! @selected_event.status_open?
      flash[:warn] = "Event is not open.  Unable to create a new template."
      permission_denied
    else
      
      @data_template.event = @selected_event
      
      respond_to do |format|
        if @data_template.save
          flash.now[:notice] = 'DataTemplate was successfully created.'
          format.html { redirect_to(data_templates_url) }
          format.json { render :json => @data_template }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @data_template.errors, :status => :unprocessable_entity }
          format.json { render :json  => @data_template.errors.full_messages().collect{|err_msg| "<li>" << err_msg << "</li>"}.to_s, :status => :unprocessable_entity  }
        end
      end     
    end
  end
  
  # PUT /data_templates/1
  # PUT /data_templates/1.xml
  def update
    
    @data_template = DataTemplate.find(params[:id])
    
    respond_to do |format|
      if @data_template.update_attributes(params[:data_template])
        flash.now[:notice] = 'DataTemplate was successfully updated.'
        format.html { redirect_to( :controller => 'data_templates', :action=>'edit', :id => @data_template.id) }
        format.json { render :json => @data_template}
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @data_template.errors, :status => :unprocessable_entity }
        format.json { render :json => @data_template}
      end
    end
  end
  
  # DELETE /data_templates/1
  # DELETE /data_templates/1.xml
  def destroy
    
    @data_template = DataTemplate.find(params[:id])
    @data_template.destroy
    
    respond_to do |format|
      format.html { redirect_to(data_templates_url) }
      format.xml  { head :ok }
      format.json { render :json => @data_template }
    end
    
  end
  
  # DELETE data_templates/1/contact/1
  def remove_contact_from_template
    @data_template = DataTemplate.find(params[:id])
    contacts_to_remove = @data_template.contacts.select{ |contact| contact.id.to_s == params[:contact] } 
    @data_template.contacts.delete(contacts_to_remove)
    
    respond_to do |format|
      format.html { redirect_to :action => 'edit', :id => params[:id] }
      format.xml  { head :ok }
      format.json { render :json => contacts_to_remove }
    end
  end
  
  # /data_templates/1/remove_template_column/1
  # TODO Possible orphaned method
  def remove_template_column
    @data_template = DataTemplate.find(params[:id])
    @data_template.data_template_columns.find(params[:col]).delete
    
    respond_to do |format|
      format.html { redirect_to :action => 'edit', :id => params[:id] }
      format.xml  { head :ok }
      format.json { render :json => params[:col] }
    end
  end
  
end
