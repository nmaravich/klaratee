class DataTemplateColumnsController < ApplicationController
  
  before_filter :login_required #, :only => [ :edit, :update ]
  before_filter :dyna_connect
  layout "standard"
  
  protect_from_forgery
  
  filter_resource_access :additional_collection => [:update_possible_values, :quick_create]
  
  COL_ERROR_EXISTS = "This template already contains a column named '%s'.  "
  COL_ERROR_EXISTS_TYPE = "Unable to add column '%s' as the column type needs to be '%s' to match with a column with the same name already defined in template '%s'.  "
  COL_ERROR_EXISTS_UPDATE = "Unable to update column.  Columns with the same name across templates must have the same column type."
  
  # GET /data_template_columns/1/edit
  def edit
    @data_template_column = DataTemplateColumn.find(params[:id])
  end
  
  # GET /data_template_columns/quick_create
  # Allows user to add several columns at once via a comma separated list using a :quick_add parameter
  def quick_create
    @data_template = DataTemplate.find(params[:data_template_id])
    current_columns = @data_template.data_template_columns
    
    event_cols_by_name = get_event_columns_by_name(@data_template.event_id, @data_template.id)
    
    quick_cols = params[:quick_add].split(',').collect{ |col| col.strip }
    @cols_saved = []
    cols_failed = []
    
    max_order = current_columns.maximum('order') || 0
    quick_cols.each { |col |
      existing_cols = event_cols_by_name[col]
      existing_local_col = nil
      existing_other_col = nil
      if ! existing_cols.nil?
        existing_cols.each do |column| 
          if column.data_template_id != @data_template.id
            existing_other_col = column
          else
            existing_local_col = column
          end
        end
      end
      
      fail_msg = nil
      if ! existing_cols.nil? && ! existing_cols.empty? 
        if ! existing_local_col.nil? && existing_local_col.data_template_id.to_s == @data_template.id.to_s
          fail_msg = COL_ERROR_EXISTS % [col]
        end
        if ! existing_other_col.nil? && existing_other_col.col_type != 'string_value'
          fail_msg = COL_ERROR_EXISTS_TYPE % [col, I18n.t("column_types.#{existing_other_col.col_type}"), existing_other_col.data_template.name]
        end  
      end
      
      if fail_msg.nil?
                                
        @dt_col = DataTemplateColumn.new(:name => col)
        # LOOK AT ME!!  
        # Right now any quick added columns are hard coded to string.  Later there should be some
        # decision logic to help more intelligently guess on the column type.
        @dt_col.col_type = "string_value"
        @dt_col.data_template = @data_template
        @dt_col.order = max_order += 1
        
        if @dt_col.save
          @cols_saved << @dt_col.name
        else
          cols_failed << @dt_col.errors.on(:name)
        end
      else
        cols_failed << fail_msg
      end      
    }
    
    respond_to do |format|
      flash[:notice] = "Saved columns: #{@cols_saved.join(', ')}" unless @cols_saved.empty?
      flash[:error] = cols_failed.join('<br/>') unless cols_failed.empty?
      
      format.html { redirect_to( :controller => 'data_templates', :action=>'edit', :id => @data_template.id) }
    end
    
  end  
  
  # POST /data_template_columns
  # POST /data_template_columns.xml
  # Creation of a single data_template_column.  To add multiple columns see above quick_create method.
  def create

    # the template this column belongs to is passed in separate. If there is a way to make this work
    # with the constructor like all other attributes above then change it.
    @data_template = DataTemplate.find(params[:data_template_id])
    
    error_msg = validate_template_col(params[:data_template_column][:name],
                                      params[:data_template_column][:col_type], @data_template, false)
    if error_msg.nil?
      @data_template_column = DataTemplateColumn.new(params[:data_template_column])
      
      
      # A column must be assigned to a specific template.
      @data_template_column.data_template = @data_template
    
      # Add this new column after the existing columns
      previous_max = @data_template.data_template_columns.maximum('order')
      @data_template_column.order = previous_max.nil? ? 1 : previous_max + 1
  
      # These will come through if a select_one or select_many column type was created.
      @possible_values = params[:possible_values].split(',') unless params[:possible_values].nil?
      
      is_good_transaction = true
    else 
      is_good_transaction = false
    end

    if is_good_transaction
      ActiveRecord::Base.transaction do
        begin
          # Save it now so I can get the id that is needed to create the possible value objects.
          @data_template_column.save!
          
          # Create possible value objects if any exist.
          @possible_values.each { |pos_val|
            pVal = DataTemplateColumnPossibleValue.new();
            pVal.data_template_column_id = @data_template_column.id
            pVal.possible_value = pos_val.gsub(/ /,'')
            pVal.save
          } unless @possible_values.nil?
          
        rescue Exception=> e
          logger.warn "Exception while creating a template column: #{e}"
          error_msg = "#{e}"    
          is_good_transaction = false
        end
      end
    end
    
    respond_to do |format|
      if is_good_transaction
        flash.now[:notice] = 'Template column created successfully.'
        format.html { redirect_to(:controller => "data_templates", :action => "edit", :id => @data_template_column.data_template.id ) }
        format.json { render :json => @data_template_column }
      else
        flash.now[:error] = error_msg
        format.html { render :action => "edit" }
        format.json { render :json => error_msg, :status => 400 }
      end
    end         
    
  end
  
  # PUT /data_template_columns/1
  # PUT /data_template_columns/1.xml
  def update
    
    @data_template_column = DataTemplateColumn.find(params[:id])
    template = @data_template_column.data_template
    
    error_msg = validate_template_col(params[:data_template_column][:name],
                                      params[:data_template_column][:col_type], template, true)
    
    if ( error_msg.nil? && params[:possible_values] )
      @poss_obj = []
      # Just clear the current values and replace with the new ones for now.
      # TODO Probably a better way to do this.
      DataTemplateColumnPossibleValue.delete( @data_template_column.data_template_column_possible_values )
      
      params[:possible_values].split(',').each { |pos_val|
        pVal = DataTemplateColumnPossibleValue.new();
        pVal.data_template_column_id = @data_template_column.id
        pVal.possible_value = pos_val.gsub(/ /,'')
        @poss_obj.push pVal  
      }
      @data_template_column.data_template_column_possible_values = @poss_obj
    end
    
    success = false
    if ! error_msg.nil?
      flash.now[:error] = error_msg
    else
      success = @data_template_column.update_attributes!( params[:data_template_column] )
    end
    
    respond_to do |format|
      if success
        flash.now[:notice] = 'Data template column was successfully updated.'
        format.html { redirect_to(:controller => "data_templates", :action => "edit", :id => @data_template_column.data_template.id ) }
        format.json { render :json => @data_template_column }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @data_template_column.errors, :status => :unprocessable_entity }
        format.json { render :json => error_msg, :status => 400 }
      end
    end
    
  end
  
  # Used to update the order of the columns.
  # Its designed to be called from ajax only right now.
  def update_order
    
    @data_template_column = DataTemplateColumn.find(params[:id])
    new_order = params[:data_template_column][:order]
    
    # You need to know if the new order is + or - the old order to make the algorithm work.
    (new_order.to_i < @data_template_column.order) ? moving_left = true : moving_left = false
    
    # Set the new order for the column you just moved. This means that another column and this one will have the same order right now.
    @data_template_column.order = new_order
    @data_template_column.save!
    
    # Grab all the columns except for the one we just updated.
    if moving_left
      # we do greater or equal because of the fact that another column has the same order and we want that one, but our main column is already
      # in the proper order so we don't grab it from this list
      all_cols = DataTemplateColumn.belongs_to_template(@data_template_column.data_template_id).order_greater_or_equal(new_order, @data_template_column.id)
    else
      all_cols = DataTemplateColumn.belongs_to_template(@data_template_column.data_template_id).order_less_or_equal(new_order, @data_template_column.id)
    end
    
    mod = new_order.to_i
    
    all_cols.each do |col|
      if(moving_left)
        mod += 1 
      else
        mod -= 1 
      end
      
      col.order = mod
      col.save!
    end
    
    respond_to do |format|
      format.json { render :json => @data_template_column}
    end
    
    
  end
  
  def update_possible_values
    
    @data_template_column = DataTemplateColumn.find(params[:id])
    # The possible vals are stored in the db as piped values.  This splits them into an array, adds the new value, and pipes them back up.
    @data_template_column.possible_values = @data_template_column.possible_values.split('|').push(params[:possible_value]).join('|')
    
    if @data_template_column.save!
      render :update do |page|
        page.replace_html 'update_me', :partial => 'possible_values'
      end    
    else
      format.html { redirect_to(:controller => "data_templates", :action => "edit", :id => @data_template_column.data_template.id ) }
    end
  end
  
  
  # DELETE /data_template_columns/1
  # DELETE /data_template_columns/1.xml
  def destroy
    
    @data_template_column = DataTemplateColumn.find(params[:id])
    @dt = @data_template_column.data_templates
    @data_template_column.destroy
    
    # Fix all the column orders and set back to 0 based.  
    all_cols = DataTemplateColumn.find(:all, :order => 'order')
    all_cols.each_with_index do |col, i|
      col.order = i
      col.save!
    end
    
    respond_to do |format|
      format.html { redirect_to :controller => 'data_templates', :action => 'edit', :id => 1 }
      format.xml  { head :ok }
    end
  end
  
  def get_event_columns_by_name event_id, template_id
    
    # Collect all columns defined for all templates in this event.  We want to make sure the
    #  user cannot define columns with the same name, but different data type
    event_columns = DataTemplateColumn.all(:joins => [:data_template], :conditions => ['data_templates.event_id = ?', event_id])
    event_cols_by_name = {}
    event_columns.each_with_index do |col, index|
      if event_cols_by_name[col.name].nil?
        event_cols_by_name[col.name] = []
      end
      event_cols_by_name[col.name].push col 
    end

    return event_cols_by_name
  end
  
  def validate_template_col col_name, col_type, data_template, is_update
    fail_msg = nil
    event_cols_by_name = get_event_columns_by_name(data_template.event_id, data_template.id)
    existing_cols = event_cols_by_name[col_name]
    existing_local_col = nil
    existing_other_col = nil
    if ! existing_cols.nil?
      existing_cols.each do |column| 
        if column.data_template_id != data_template.id
          existing_other_col = column
        else
          existing_local_col = column
        end
      end
    end
    
    if ! existing_cols.nil? && ! existing_cols.empty?
      if ! is_update && ! existing_local_col.nil? && existing_local_col.data_template_id.to_s == data_template.id.to_s
        fail_msg = COL_ERROR_EXISTS % [col_name]
      end
      if ! existing_other_col.nil? && existing_other_col.col_type != col_type
        if is_update
          fail_msg = COL_ERROR_EXISTS_UPDATE
        else
          fail_msg = COL_ERROR_EXISTS_TYPE % [col_name, I18n.t("column_types.#{existing_other_col.col_type}"), existing_other_col.data_template.name]
        end
      end  
    end
    
    return fail_msg
  end
  
end
