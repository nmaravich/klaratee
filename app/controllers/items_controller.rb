class ItemsController < ApplicationController
  layout "standard"
  before_filter :login_required , :dyna_connect  

  include EventAware 
  before_filter :event_aware, :only => [ :index, :master_items, :new, :create ]
  
  filter_resource_access :additional_collection => :master_items
  filter_access_to :index, :attribute_check => true, :load_method => :make_index_object
  filter_access_to [:new, :create], :attribute_check => true, :load_method => :make_new_object
  
  # Should be part of the user object maybe? 
  def make_new_object
    return if (has_role?(Role::BUYER.to_sym) || has_role?(Role::ADMIN.to_sym))  
    @obj = {}

    @obj[:can_create] = current_aux_user.invited_to_template?(@selected_data_template)
    
    #puts "CanCreate1: #{@obj[:can_create]} - SelectedTemplate: #{@selected_data_template.id rescue nil}"
    
    if !@selected_data_template.nil?
      if ! @selected_data_template.event.open_to_user?(current_user.id)
        @obj[:can_create] = false
        flash[:warn] = "Event is not open at this time."
      end
    end
    
    @obj
  end
  protected :make_new_object
  
  def make_index_object
    
    @obj = {:items_editable => true}
    return if (has_role?(Role::BUYER.to_sym) || has_role?(Role::ADMIN.to_sym))  
    
    # Event will be displayed on the screen
    @obj[:event_viewable] = true
    
    if !@selected_event.nil?
      @obj[:invited_to_event] = current_aux_user.invited_to_event?(@selected_event.id)
      if @selected_event.status_archived?
        @obj[:event_viewable] = false      
        # put code here for selective opening of the event to certain contacts, even when the event is closed
        flash[:warn] = "Event is closed."
		  elsif @selected_event.status_closed?        
        if StatusException.exists?({:event_id=> @selected_event.id, :aux_user_id => current_user.id, :status=>"open"})
        else
          # supplier can't edit items in a closed event
          @obj[:items_editable] = false   
        end   
      end
      @selected_event = nil if (!@obj[:invited_to_event])
    else
      # No event is selected, so let them through (even though they may have a template selected)
      @obj[:allow_with_no_params] = true
    end
    
    if !@selected_data_template.nil?
      
      @obj[:invited_to_template] = current_aux_user.invited_to_template?(@selected_data_template.id)
      
      if @selected_data_template.event.status_archived?
        @obj[:event_viewable] = false
        # put code here for selective opening of the event to certain contacts, even when the event is closed
        flash[:warn] = "That template's event is archived."
      elsif @selected_data_template.event.status_closed?
        if !@selected_event.nil? && StatusException.exists?({:event_id=> @selected_event.id, :aux_user_id => current_user.id, :status=>"open"})
          # flash[:notice] = "Event selectively re-opened for supplier."
        else
          @obj[:items_editable] = false   # supplier can't edit items in a closed event
        end   
      end
      
    else
      @obj[:invited_to_template] = true
    end
    
    if @selected_data_temlate.nil? && @selected_event.nil?
      @obj[:allow_with_no_params] = true
    end
    
    @obj  
  end
  
  # GET /items
  # GET /items.xml
  def index
    
    if !@selected_event.nil? && !@selected_data_template.nil?
      if current_aux_user.invited_to_template?(@selected_data_template.id)
        # Only show the items for the supplier invited to the template  
        sql = Item.generate_items_for_template_supplier(@selected_data_template, current_user, build_order_clause)
      else        
        # This user was not invited so show all items?
        sql = Item.generate_items_for_template( @selected_data_template, build_order_clause)
      end
      
      @items =  Item.paginate_by_sql( sql, :page => params[:page] ) unless sql.nil?
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @items }
    end
    
  end
  
  # GET /items/1
  # GET /items/1.xml
  def show
    @item = Item.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @item }
    end
  end
  
  # GET /items/new
  def new
    
    @dt_cols = Array.new
    unless @selected_data_template.nil?
      # Handles fetching the data template columns for the user to populate for a particular item.
      @dt_cols = DataTemplateColumn.find_all_by_data_template_id( @selected_data_template.id )
    end
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # GET /items/1/edit
  def edit
    @item = Item.find(params[:id])
  end
  
  # POST /items
  # POST /items.xml
  def create
    # If no template is given we can't create the item because we won't know which
    # columns are available, etc.
    if (params[:dt_id].blank? )
      flash[:error] = 'Unable to create Item. Unknown Template given.'
      redirect_to :action => "new"
      return
    end
    
    # Grab the dataTemplate object, and its columns.  
    template_cols = DataTemplateColumn.find_all_by_data_template_id( params[:dt_id] )
    
    # Validate required item attributes were entered
    missing_attrs = []
    template_cols.each { |col|
      if col.required && (params[col.name].nil? || params[col.name].empty?)
        missing_attrs.push col.name
      end      
    }
    if missing_attrs.size > 0
      flash[:error] = "Unable to create Item. The following required item values were not entered: #{missing_attrs.join(', ')}."
      redirect_to :action => "new"
      return
    end
    
    # Need all of these db operations to succeed or we need to rollback 
    is_good_transaction = true
    
    ActiveRecord::Base.transaction do
      begin
        # Start with the item. There are a few attributes that save directly in the item.
        # The values are stored in connecting tables.
        @item = Item.new()
        @item.is_dirty         = params[:is_dirty] unless params[:is_dirty].blank?
        @item.is_approved      = params[:is_approved] unless params[:is_approved].blank?
        @item.is_valid         = params[:is_valid] unless params[:is_valid].blank?
        
        @item.supplier_id = session[:acting_as_supplier].id unless session[:acting_as_supplier].nil?
        @item.surrogate_creator_id = session[:surrogate_parent].nil? ? nil : session[:surrogate_parent][:user_id]    
        
        @item.data_template_id = params[:dt_id] unless params[:dt_id].blank?
        @item.save
        
        # Grab the dataTemplate object, and its columns.  
        template_cols = DataTemplateColumn.find_all_by_data_template_id( params[:dt_id] )
        
        template_cols.each { |col|
          
          iv = ItemValue::create(@item.id, col, params[col.name])
          
          iv.save
        }
        
      rescue
        # It looks like it gets logged anyway so you don't need this.  
        log_error($!)
        is_good_transaction = false
      end
    end
    
    respond_to do |format|
      if is_good_transaction
        flash[:notice] = 'Item created successfully.'
        format.html { redirect_to(items_url + "?dt_id=" + params[:dt_id]) }
        format.json { render :json=>Event.first } 
      else
        flash[:error] = 'Problem creating the item.'
        format.html { redirect_to(items_url + "?dt_id=" + params[:dt_id]) }
      end
    end        
    
    
  end
  
  
  # PUT /items/1
  # PUT /items/1.xml
  def update
    
    # Had to smush together the col and item id because of the inline edit package.
    # I couldn't figure out another way to do it.
    ids =  params[:column_id_item_id].split('-')
    
    # TODO If it turns out you don't need the full DTC just pass the col_type from the view so you don't need to query here.
    @data_template_column = DataTemplateColumn.find_by_id(ids[0])
    
    if has_role?(Role::SUPPLIER.to_sym) and ! @data_template_column.data_template.event.open_to_user?(current_user.id)
      permission_denied
    else 
      
      iv = ItemValue.find_by_item_id(ids[1], :conditions => {:data_template_column_id => ids[0]}) || ItemValue.new
      iv.send("#{@data_template_column.col_type}=", params[:value].strip)
      
      iv.data_template_column_id = ids[0]
      iv.item_id = ids[1] if iv.item_id.nil?
      iv.save
      
      # updating the audit info for the item, since the user-stamp does not catch this
      item = Item.find_by_id(ids[1])
      item.updater_id = current_user.id
      item.updated_at = Time.now
      item.surrogate_updater_id = session[:surrogate_parent].nil? ? nil : session[:surrogate_parent][:user_id]    
      item.save
      
      respond_to do |format|
        format.xml  { head :ok }
        format.json { render :json=>params[:value] } 
      end
    end
  end
  
  # DELETE /items/1
  # DELETE /items/1.xml
  def destroy
    @item = Item.find(params[:id])
    @item.destroy
    
    respond_to do |format|
      format.html { redirect_to(items_url) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  # Builds an order clause based on the template columns of the selected template and the Item::SYSTEM_COLS
  def build_order_clause
    # See if the sort_by column passed exists in the special system_cols, or the normal data_template cols.
    # Note: The standard template names are converted to sha1 hashes so we don't give away db col names in the url
    sorting = (@selected_data_template.get_columns_as_sha1+Item::SYSTEM_COLS).include?(params[:sort_by]) rescue false
    # If so then build the appropriate order clause
    order_clause = " `#{params[:sort_by]}` #{params[:sort_type].upcase}" if sorting
  end
  
end