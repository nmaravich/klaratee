class EventsController < ApplicationController
  
  layout "standard"
  before_filter :login_required , :dyna_connect  
  before_filter :set_aux_user
  filter_resource_access
  filter_access_to :index, :change_status
  
  # Need to be able to call force_set_selected_event method
  include EventAware
  
  # GET /events
  # GET /events.xml
  def index
    @events = Event.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events }
      format.json { render :json=>@events } 
    end
  end
  
  # GET /events/1
  # GET /events/1.xml
  def show
    @event = Event.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
      format.json { render :json => @event }
    end
  end
  
  # GET /events/new
  # GET /events/new.xml
  def new
    @event = Event.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end
  
  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
      format.json { render :json => @event }
    end
  end
  
  # POST /events
  # POST /events.xml
  def create
    @event = Event.new(params[:event])
    @event.status = "open" if params[:event][:status].blank?
    respond_to do |format|
      if @event.save
        flash.now[:notice] = 'Event was successfully created.'
        
        # Use EventAware module to set this event to be currently selected
        force_set_selected_event(@event)
        
        Faq.create!({:family_id => @event.id, :user_id=>current_user.id, :visibility=>"public", :text=> "Root FAQ for Event #{@event.id}"})
        format.html { redirect_to(@event) }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
        format.json { render :update do |page|                          
            page << "$('#event-list').replaceWith('" + escape_javascript(render(:partial => "events_table", :locals => { :events => Event.all, :table_id => "event-list" })) +"');" 
          end }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
        format.json { render :json  => @event.errors.full_messages().collect{|err_msg| "<li>" << err_msg << "</li>"}.to_s, :status => :unprocessable_entity  }
      end
    end
  end
  
  # PUT /events/1
  # PUT /events/1.xml
  def update
    @event = Event.find(params[:id])
    
    respond_to do |format|
      if @event.update_attributes(params[:event])
        flash.now[:notice] = 'Event was successfully updated.'        
        
        # Check for an event status change
        if !params[:event][:status].blank? and @event.status != params[:event][:status]           
          StatusException.delete_all({:event_id=>@event.id})
        end
        
        if @event.status_archived?
          # deselect this event if it is set to archived
          force_set_selected_event(nil) if load_event.id = @event.id
        else
          force_set_selected_event(@event)
        end
        
        # The event stored in REDIS will now be out of date. Update it for all users not just the guy logged in!
        update_event_for_all_users(@event)
        
        format.html { redirect_to events_path }
        format.xml  { head :ok }
        format.json { render :update do |page|                          
            page << "$('#event-list').replaceWith('" + escape_javascript(render(:partial => "events_table", :locals => { :events => Event.all, :table_id => "event-list" })) +"');" 
          end }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /events/1
  # DELETE /events/1.xml
  def destroy
    @event = Event.find(params[:id])
    @event.destroy
    
    # Wipe this event from being selected in the dropdown
    force_set_selected_event(nil)
    force_set_selected_data_template(nil)
    
    respond_to do |format|
      format.html { redirect_to(events_url) }
      format.xml  { head :ok }
      format.json { render :json => @event }
    end
  end
  
  # called when adding status exceptions
  def change_status
    @event = Event.find(params[:id])
    @invitees = @event.invited_users

    if @event.status_open?
      flash[:warn] = "That event is already open to all invitees."
      redirect_back_or_default events_path
    end
    if @event.status_archived?
      flash[:warn] = "That event is archived.  Change the event's status to closed before re-opening it to individual contacts."
      redirect_back_or_default events_path
    end    

    @statuses = ["open"]   # planning for multiple possible status exceptions, so put them in an array
    se = StatusException.find(:all, :conditions => {:event_id => @event.id })
    @status_exceptions = {}
    @statuses.each do |s|
      @status_exceptions[s] = se.reject{|x| ! x.status == s }.map{|a| a.aux_user_id }       
    end
    
  end
  
end
