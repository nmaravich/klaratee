require "set"
# Include the EventAware module in controllers that will have the event and or template
# selections.
# Example: ( items_controller )
#  include EventAware 
#  before_filter :event_aware, :only => [ :index, :master_items, :new ]

# The module will handle remembering the previously selected value so if you choose event 1
# on the items page, and then leave the page and come back it will automatically show event 1
# as selected, and the available templates will be those associated with event 1.
#
# If you leave the page and select and event 2 on another event_aware enabled page, when
# you return to the items page now event 2 will be selected, and templates for event 2 displayed.
#
# Details:
# This module relies on the REDIS store to 'remember' the selected event and template.

# An expiration of 1 week is placed on the key.  Meaning if you logout and return after
# a week then Klaratee won't know the event you selected last.  
# If you don't put some sort of expiry on the key, then it will hang around in memory for everyone
# and we'll have data in there that we don't need.
#
# Make sure you use the premade shared views for including the view components to your pages.
# They have the variable names that event_aware expects! 
module EventAware
  
  # The general idea here is to figure out if the event or the template side of things
  # has changed, and then use that information to set the necessary parameters to populate
  # the event and template dropdowns correctly.
  def event_aware
    
    # Populate the events dropdown list.
    @ea_events = !has_role?(Role::SUPPLIER.to_sym) ? Event.non_archived : Event.with_invitee(current_aux_user).opened_or_closed
    
    # Read the params in from the form submission 
    event_id = params[:selected_event][:id] rescue nil
    data_template_id = params[:selected_data_template][:id] rescue nil
    
    if event_id.nil? && data_template_id.nil?
      #puts "## nothing changed"
      # Change nothing because no params were passed(form submission didn't come from event or template change form )
      @selected_event = load_event_from_redis
      @selected_data_template = load_template_from_redis
    elsif event_changed?(event_id)
      #puts "## event changed"
      # User has made a change to the event selected. 
      event_changes(event_id)
    elsif data_template_id.nil?
      #puts "## template null"
      # handle case of switching from page with both selectors to just event selector - only load event
      @selected_event = load_event_from_redis
      @selected_data_template = load_template_from_redis
    elsif data_template_changed?(data_template_id)
      #puts "## template changed"
      # User has made a change to the data template list
      data_template_changes(data_template_id)
    else
      #puts "## fallback"
      # handle case of query string only, no changes
      @selected_event = load_event_from_redis
      @selected_data_template = load_template_from_redis
    end
    
    # Populate the template dropdown according to the now selected event
    @ea_data_templates = get_template_list(@selected_event)
    
    # Update redis with the latest selected event and template
    update_redis(@selected_event,@selected_data_template)
  end
  
  # Sometimes you may want to update the selected event manually. 
  # This happens when you create a new event. We'll call this to set the new event to the selected event
  # because its likely you'll want to operate on the newly created event. 
  def force_set_selected_event(event)
    save_event(event)
    @selected_event=event
  end

  # Allows manual setting of the data_template in redis. 
  # NOTE: You want to call this if any associated models are changed, like when the contacts that belong to 
  #       a template have changed.
  def force_set_selected_data_template(data_template)
    save_data_template(data_template)
    @selected_data_template=data_template
  end  
  
  # Update to the given event for all existing selected_event keys across all users.
  def update_event_for_all_users(event=nil)
    # Ex. A supplier has an event selected that is currently closed.
    #     Buyer reopens that event.  The supplier logs in but he is still unable to import items 
    #     because the import link is only available when an event is open.
    #     If you call this method after updating the event then the supplier will have the correct event data when he needs it. 
    REDIS.keys("selected_event*").each do |key|
      REDIS.set(key,Marshal.dump(event))
    end
  end
  
  # The visibilty doesn't make all that much difference since this is a module ( unless you mix it in to something and 
  # event_aware is accessed from a subclass ) but it seems more readable to me as it highlights the methods that you will
  # likely be using while the private methods won't be called directly.
  
# *********************************************  
	private
# *********************************************
  # Determine if the selected event was changed.
  def event_changed?(event_id)
    cur_event_id = load_event_from_redis.id rescue nil
    if cur_event_id.to_s == event_id.to_s
      return false
    end
    true
  end
  
  # Determine if the selected data template was changed.
  def data_template_changed?(template_id)
    # Get template from redis and compare to param passed
    cur_template_id = load_template_from_redis.id rescue nil
    if cur_template_id.to_s == template_id.to_s
      return false
    end
    true
  end

  # Set the selected event and data template based on the event_id given
  def event_changes(event_id)
    if event_id.blank?
      # This means they selected 'show all' so we want to make sure nothing is selected.
      @selected_event = nil
      @selected_data_template = nil
    else
      @selected_event = Event.find_by_id(event_id)
      @selected_data_template = @selected_event.data_templates.first
    end
  end
  
  # Set the selected data template based on the template_id given
  def data_template_changes(template_id)
    if template_id.blank?
      # This means they selected 'show all' so we want to make sure nothing is selected
      @selected_event = nil
      @selected_data_template = nil
    else       
      @selected_data_template = DataTemplate.find_by_id(template_id)
      # Handles case where you select a template before an event. We then automatically select the event. 
      @selected_event = load_event_from_redis ||= @selected_data_template.event
    end
  end
  
  # Easy way to populate the template dropdown list.  
  # Method accounts limiting list based on the event selected, and the role of the user.
  def get_template_list(event=nil)
    if !has_role?(Role::SUPPLIER.to_sym)
      event.nil? ?  DataTemplate.with_open_or_closed_events : DataTemplate.with_open_or_closed_events.with_event(@selected_event) 
    else
      event.nil? ? DataTemplate.with_invitee(current_aux_user) : DataTemplate.with_invitee(current_aux_user).with_event_ids(@ea_events) 
    end
  end
  
  # retrieve the selected event stored in redis.
  def load_event_from_redis
    # Objects are saved in redis as binary strings (@see update_redis) so we need to 
    # Marshal.load to reassemble the objects.  
    Marshal.load(REDIS["selected_event_#{key_suffix}"]) rescue nil
  end
  
  # retrieve the selected data template stored in redis.
  def load_template_from_redis
    Marshal.load(REDIS["selected_template_#{key_suffix}"]) rescue nil  
  end
  
  def save_event(event)
    REDIS["selected_event_#{key_suffix}"]=Marshal.dump(event)
    REDIS.expire "selected_event_#{key_suffix}", 1.week
  end
  
  def save_data_template(data_template)
    REDIS["selected_template_#{key_suffix}"]=Marshal.dump(data_template)
    REDIS.expire "selected_template_#{key_suffix}", 1.week
  end
  
  # When saving objects to redis you need to Marshal the object first.
  # This converts it to a binary string that can later be reassembled into the proper object.
  def update_redis(event, data_template)
    save_event(event)
    save_data_template(data_template)
  end
  
  # Adds the current user's id to the key as well as the current company.
  def key_suffix
    "#{current_aux_user.id}_#{session[:cur_company].id}" rescue nil
  end  
  
end