class UploadController < ApplicationController
  
  require 'spreadsheet'
  layout "standard"

  include EventAware 
  before_filter :event_aware, :only => [ :load_data_template, :template_item_upload]
  before_filter :login_required, :dyna_connect
  filter_access_to :all
  filter_access_to :template_item_upload, :attribute_check => true, :load_method => :load_data_template
  
  def load_data_template
    return if (has_role?(Role::BUYER.to_sym) || has_role?(Role::ADMIN.to_sym))
    @obj = {:can_ul_this_template => current_aux_user.invited_to_template?(params[:dt_id])}
    if ! params[:dt_id].blank?
      dt_id = params[:dt_id]
      dt = DataTemplate.find_by_id(dt_id)
      if ! dt.event.open_to_user?(current_user.id)
        @obj[:can_ul_this_template] = false
        flash[:warn] = "Event is not open for uploads at this time."
      end
    end
    
    if ! @selected_event.nil? and ! Event.find(@selected_event.id).open_to_user?(current_user.id)
      @obj[:can_ul_this_template] = false
      flash[:warn] = "Event is not open for uploads at this time."
    end
    
    @obj
  end

  private :load_data_template
  
  def index
    
    order_string = ! params[:sort_by].nil? ?
                   "#{params[:sort_by]} #{params[:sort_type].upcase}" : nil
    if order_string.nil?
      order_string = "created_at DESC"
    end
    
    @results = ItemUploadResult.paginate_by_sql([ItemUploadResult::UR_SQL + order_string, current_user.id],
                                                :page => params[:page])
  end
  
  def errors
    
    @result = ItemUploadResult.find_by_id params[:iur_id]
    
    order_string = ! params[:sort_by].nil? ?
                   "#{params[:sort_by]} #{params[:sort_type].upcase}" : nil
    if order_string.nil?
      order_string = "id asc"
    end
    
    # security check that iur_id belongs to current_user (prevent URL string hacking)
    if ! @result.nil? && @result.creator_id == current_user.id
      @errors = ItemUploadError.paginate_by_sql([ItemUploadError::UE_SQL + order_string, params[:iur_id].to_i],
                                                :page => params[:page])
    else
      flash[:error] = "You are not authorized to view the requested page."
      redirect_back_or_default('/upload')
    end
                                                
    # Load possible values for error messages
    # TODO query performance tune this loop using eager fetching of the possible values)
    @possible_values_by_col_id = []
    template_cols = DataTemplateColumn.find_all_by_data_template_id(@result.data_template_id)
    template_cols.each do |col|
      if col.col_type == 'select_one' || col.col_type == 'select_many'
        @possible_values_by_col_id[col.id] = col.data_template_column_possible_values.collect { |p_val| p_val.possible_value }.join(', ')
      end
    end
    
  end
  
  ##############################################################################################
  # supplier_xls
  def supplier_xls
    
    if params[:upload_supplier].nil?
      flash[:error] = "File Not Found"
      logger.error "Uploaded a blank file."
      redirect_back_or_default('/suppliers')
      return
    end
    
    # If you don't set this it won't bring cell values in, in the correct encoding and 'some_string' won't equal 'some_string'
    Spreadsheet.client_encoding = 'UTF-8'
    header_row = Supplier::HEADER_ROW
    c_header_row = Contact::HEADER_ROW
    
    # upload_supplier comes from the index file, and supplier_file is the File object transfered from the file_field
    my_file = params[:upload_supplier][:supplier_file] 
    if File.extname(my_file.original_path) != '.xls' ||
      (my_file.content_type != 'application/excel' && my_file.content_type != 'application/vnd.ms-excel' && my_file.content_type != 'application/octet-stream')
      
      rejectUploadWithError("Only MS Excel 97-2003 file format (.xls) supported for uploads.", '/suppliers')
      return
    end
    
    if File.size(my_file) > 20000000
      rejectUploadWithError("Maximum upload file size of 20MB exceeded.", '/suppliers')
    end
    
    #    Spreadsheet.client_encoding = 'UTF-16LE'
    book = Spreadsheet.open my_file
    
    all_sheets = book.worksheets
    
    if all_sheets.size < 3
      flash[:error] = 'Spreadsheet Invalid:  Please download a fresh copy of the template and try again.'
      logger.error "Invalid Number of sheets uploaded."
      redirect_back_or_default('/suppliers')
      return
    end
    
    supplier_sheet = all_sheets.second
    contact_sheet = all_sheets.third
    
    c_create_count = 0
    c_modify_count = 0
    c_delete_count = 0
    s_create_count = 0
    s_modify_count = 0
    s_delete_count = 0
    
    supplier_results = {:created => [], :deleted => [], :skipped => [], :updated=>[] }
    contact_results = {:created => [], :deleted => [], :skipped => [], :updated=>[] }
    deleted_suppliers = []
    
    tmp_supplier = Supplier.new

    dyn_fields = []
    tmp_supplier.dynamo_fields do |a_field|
      dyn_fields.push a_field
    end
    
    # Validate supplier header row matches what is expected
     (0..supplier_sheet.row(0).size-2).each_with_index do |cell, i|
      
      an_error = false
      col_text = supplier_sheet.[](0, cell)
      if i < header_row.length
        # column validation for static supplier fields
        if col_text != header_row[i][:col_name]
          an_error = true
        end
      else
        # column validation for dynamic supplier fields
        if ! dyn_fields.include?(col_text)
          an_error = true
        end
      end
      
      if an_error
        flash[:error] = "Invalid Spreadsheet structure: Try downloading a clean sheet and upload again  "
        logger.error "Invalid Spreadsheet: Supplier sheet column out of order or invalid: #{supplier_sheet.[](0, cell)}"
        redirect_back_or_default('/suppliers')
        return
      end
      
    end
    
    tmp_contact = Contact.new

    dyn_fields_c = []
    tmp_contact.dynamo_fields do |a_field|
      dyn_fields_c.push a_field
    end
    
    # Validate contact header row matches what is expected
    (2..contact_sheet.row(0).size-2).each_with_index do |cell, i|      
      
      an_error = false
      col_text = contact_sheet.[](0, cell)
      if i < c_header_row.length
        # column validation for static contact fields
        if col_text != c_header_row[i][:col_name]
          an_error = true
        end
      else
        # column validation for dynamic contact fields
        if ! dyn_fields_c.include?(col_text)
          an_error = true
        end
      end
      
      if an_error
        flash[:error] = "Invalid Spreadsheet structure: Try downloading a clean sheet and upload again  "
        logger.error "Invalid Spreadsheet: Contact sheet column out of order or invalid:i=#{i} cell=#{cell} #{col_text}"
        redirect_back_or_default('/suppliers')
        return
      end
            
    end
    
    # # # # # # # # # # # # # # #
    # Process Suppliers sheet
    #
    
    # Dimensions: [0] =first used row, [1]first unused row, [2]first used column, [3]first unused column
    ( supplier_sheet.dimensions()[0]+1..supplier_sheet.dimensions()[1]-1 ).each_with_index do |row, row_count|
      
      row_count += 2 # offset ( 1 for header row, and one because excel isn't 0 based ) 
      attrs = {}
      
      # the attrs will be a hash of attr_name => column_value. Used to create supplier obj.
      header_row.each_with_index do |attr, i|
        # Read the cell values into attrs which will later be applied to the object.
        attrs[ header_row[i][:attr_name].to_sym ] = get_cell_value(supplier_sheet.[](row, i))
      end
      
      # handle dynamic (dynamo) attributes, if any
      header_row_length = header_row.size
      dyn_count = 0
      tmp_supplier.dynamo_fields do |field_name|
        dyn_col = header_row_length.to_i + dyn_count
        attrs[ field_name.to_sym ] = get_cell_value(supplier_sheet.[](row, dyn_col))
        dyn_count += 1
      end
      
      # force non-numeric conversions for string type fields that can contain only numbers (prevent 15222.0 zip code in DB)
      [:zip, :phone_number, :fax].each do |field|
        attrs[field] = non_numeric_to_string(attrs[field])
      end
      
      # Counting on the delete column being the last column on the sheet!
      is_deleted = supplier_sheet.[](row, supplier_sheet.dimensions()[3]-1)
      
      # Query for a supplier with the company name of this row
      old_supplier = Supplier.find_by_company_name(attrs[:company_name])
      
      # Delete the supplier if they exist. If not report that supplier didn't exist and was skipped. 
      if is_deleted == 'y' || is_deleted == 'Y' || is_deleted == 'yes' || is_deleted == 'Yes'
        if old_supplier.nil?
          supplier_results[:skipped].push " Row: #{row_count} - Attempted to delete a supplier that doesn't exist."
        else
          # delete any supplier contact relationships for this supplier (KLARATEE-83)
          number_of_scs = old_supplier.supplier_contacts.size
          old_supplier.supplier_contacts.each do |supplier_contact|
            supplier_contact.delete
          end
          if number_of_scs > 0
            contact_results[:deleted].push " #{number_of_scs} contacts deleted due to supplier #{attrs[:company_name]} deleted."
          end
          
          # delete the supplier record
          old_supplier.delete
          supplier_results[:deleted].push " Row: #{row_count} Deleted"
          # store all deleted company names for contact sheet processing
          deleted_suppliers.push attrs[:company_name]
          s_delete_count += 1
          
        end
        next
      end
      
      # Create or update depending on pre existence of supplier obj
      if old_supplier.nil?
        
        new_supplier = Supplier.new(attrs)
        # event = Event.find(watermark)
        #new_supplier.events.push event
        new_supplier.save
        
        if !new_supplier.errors.empty?
          supplier_results[:skipped].push(" Skipping update for: #{new_supplier.company_name}")
        else
          supplier_results[:created].push " Row: #{row_count} Created"
        end
        
        s_create_count += 1
        
      else
        
        # Run a quick check to see if the object has changed. If not then no point in updating.
        needs_update = false
        attrs.keys.each do |new_key|
          if attrs[new_key].to_s != old_supplier.send(new_key.to_s).to_s
            needs_update = true
            break
          end
        end
        
        if needs_update
          old_supplier.update_attributes(attrs)
          supplier_results[:updated].push " Row: #{row_count} Updated"
          s_modify_count += 1
        else
          supplier_results[:skipped].push " #{row_count} ( Already exists. )"
        end
        
      end
      
    end
    
    # # # # # # # # # # # # # # #
    # Process Contacts sheet
    #
     ( contact_sheet.dimensions()[0]+1..contact_sheet.dimensions()[1]-1 ).each_with_index do |row, row_count|
      
      row_count += 2 # offset ( 1 for header row, and one because excel isn't 0 based ) 
      attrs = {}      
      
      company_name = nil
      contact_type = nil
      
      # get the first two static contact column values
      company_name = contact_sheet.[](row, 0)
      contact_type = contact_sheet.[](row, 1)               
      
      # the attrs will be a hash of attr_name => column_value. Used to create contact obj.
      c_header_row.each_with_index do |attr, i|
        # Read the cell values into attrs which will later be applied to the object.
        attrs[ c_header_row[i][:attr_name].to_sym ] = get_cell_value(contact_sheet.[](row, i + 2))       
      end
      
      # handle dynamic (dynamo) attributes, if any
      header_row_length = c_header_row.size
      dyn_count = 0
      tmp_contact.dynamo_fields do |field_name|
        dyn_col = header_row_length.to_i + 2 + dyn_count
        sheet_val = get_cell_value(contact_sheet.[](row, dyn_col)) 
        attrs[ field_name.to_sym ] = sheet_val
        #puts "dynamo field name = #{field_name}, sheet value = #{sheet_val}"
        dyn_count += 1
      end
      
      # Counting on the delete column being the last column on the sheet!
      is_deleted = contact_sheet.[](row, contact_sheet.dimensions()[3]-1)
      
      # Query for a supplier with the company name of this row
      db_supplier = Supplier.find_by_company_name(company_name)
      
      # Query for a contact with the email or name of this row
      sc_count = 0
      if ! attrs[:email].nil?
        old_contact = Contact.find_by_email(attrs[:email])
        if ! old_contact.nil?
          sc_count = old_contact.supplier_contacts.size
        end
      else
        old_contacts = Contact.find( :all, :conditions => [ "f_name = ? AND l_name = ?", attrs[:f_name], attrs[:l_name] ])
        if old_contacts.size == 1
          old_contact = old_contacts[0]
          sc_count = old_contact.supplier_contacts.size
        else
          old_contact = nil
        end
      end
      
      # Delete any contact where the parent supplier was just deleted and it is not attached to other suppliers
      if deleted_suppliers.include?(company_name) && ! old_contact.nil? && sc_count == 0
        old_contact.delete
        c_delete_count += 1
        next
      end
      
      # query for existing supplier contact table entry
      if ! old_contact.nil? && ! db_supplier.nil? 
        old_sc = SupplierContact.find( :first, :conditions => [ "supplier_id = ? AND contact_id = ?", db_supplier.id, old_contact.id ])
      end
      
      # Delete the contact if requested and they exist. If not report that contact didn't exist and was skipped. 
      if is_deleted == 'y' || is_deleted == 'Y' || is_deleted == 'yes' || is_deleted == 'Yes'
        if old_contact.nil? || old_sc.nil?
          contact_results[:skipped].push " Row: #{row_count} - Attempted to delete a contact that doesn't exist."
        else
          # delete the supplier contact table entry
          old_sc.delete  
          
          # delete the contact table entry if the contact only belongs to one supplier
          if sc_count == 1
            old_contact.delete
          end
          
          contact_results[:deleted].push " Row: #{row_count} Deleted"
          c_delete_count += 1
          
        end
        next
      end
      
      # Reject contacts where supplier is not found
      if db_supplier.nil?
        contact_results[:skipped].push(" Skipping create for contact: #{attrs[:email]} - company (#{company_name}) not found!")
        next
      end      
      
      # Create or update depending on pre existence of contact obj
      if old_contact.nil? || old_sc.nil?
        
        if old_contact.nil?
          # create contact table entry
          new_contact = Contact.new(attrs)
          new_contact.save
        end
        
        if old_sc.nil?
          #create supplier contact relationship table entry
          the_id = (old_contact.nil?) ? new_contact.id : old_contact.id
          new_sc = SupplierContact.new()
          new_sc.contact_id = the_id
          new_sc.supplier_id = db_supplier.id
          new_sc.contact_type = contact_type
          new_sc.save
        end
        
        if (!new_contact.nil? && !new_contact.errors.empty?) || (!new_sc.nil? && !new_sc.errors.empty?)
          contact_results[:skipped].push(" Skipping update for: #{new_contact.email}")
        else
          contact_results[:created].push " Row: #{row_count} Created"
          c_create_count += 1
        end
        
      else
        
        # Run a quick check to see if the object has changed. If not then no point in updating.
        needs_update = false
        attrs.keys.each do |attr_key|
          #puts "processing attribute[#{attr_key}] new value = #{attrs[attr_key].to_s}, old value = #{old_contact.send(attr_key.to_s).to_s}"
          if attrs[attr_key].to_s != old_contact.send(attr_key.to_s).to_s
            needs_update = true
            break
          end 
        end
        if contact_type != old_sc.contact_type
          needs_update = true
        end
        
        if needs_update
          old_contact.update_attributes(attrs)
          contact_results[:updated].push row_count
          c_modify_count += 1
          
          #update supplier contact if contact type modified
          if contact_type != old_sc.contact_type
            old_sc.contact_type = contact_type
            old_sc.update
          end
          
        else
          contact_results[:skipped].push " #{row_count} ( Already exists. )"
        end
        
      end
      
    end
    
    # Clean up contacts that have lost relationships to any suppliers (should only happen due to code exceptions)
    orphan_contacts = Contact.find( :all, :conditions => ["id not in (select distinct contact_id from supplier_contacts)"])
    orphan_contacts.each do |an_orphan|
      an_orphan.delete
    end
    
    s_stats = "Suppliers: #{s_create_count} created. #{s_modify_count} modified. #{s_delete_count} deleted."
    c_stats = "Contacts: #{c_create_count} created. #{c_modify_count} modified. #{c_delete_count} deleted."
    
    flash[:notice] = "Supplier/Contact sheet processed successfully.<br />#{s_stats}<br />#{c_stats}"
    
    # For now just cram the results in flash and we'll throw on the page.  
    # Later we'll do a real report.
    #flash[:supplier_results] = supplier_results
    #flash[:contact_results] = contact_results
    redirect_to :controller => "suppliers", :action => "index"
    
  end
  
  ##############################################################################################
  # template_item_upload
  def template_item_upload
    
    if params[:upload_template_items].nil?
      rejectUploadWithError("No Upload File Found", '/items')
      return
    end
    
    # upload_template_items comes from the index file, and template_items_file is the File object transfered from the file_field
    my_file = params[:upload_template_items][:template_items_file] 
    if File.extname(my_file.original_path) != '.xls' ||
      (my_file.content_type != 'application/excel' && my_file.content_type != 'application/vnd.ms-excel' && my_file.content_type != 'application/octet-stream')
      
      rejectUploadWithError("Only MS Excel 97-2003 file format (.xls) supported for uploads.", '/items')
      return
    end
    
    if File.size(my_file) > 20000000
      rejectUploadWithError("Maximum upload file size of 20MB exceeded.", '/items')
    end    
    
    # If you don't set this it won't bring cell values in, in the correct encoding and 'some_string' won't equal 'some_string'
    Spreadsheet.client_encoding = 'UTF-8'
    
    begin
      book = Spreadsheet.open my_file
    rescue Ole::Storage::FormatError => f_error
      logger.error "Error opening item sheet #{f_error}"
      rejectUploadWithError("Only MS Excel 97-2003 file format (.xls) supported for uploads.#{f_error}", '/items')
      return
    end
    
    all_sheets = book.worksheets
    
    if all_sheets.size < 2
      rejectUploadWithError('Spreadsheet Invalid:  Please download a fresh copy of the template and try again.', '/items')
      return
    end
    
    item_sheet = all_sheets.second
    
    # Pull the template ID from the 0,0 position (hidden) on the items sheet
    # And attempt to load the template from the database 
    excel_template_id = non_numeric_to_string( item_sheet.[](0,0) )
    # handle if the extra audit columns were included in the item sheet dowload
    audit_info_included = item_sheet.[](0,1) == 'Created By'
    audit_offset = audit_info_included ? 4 : 0 
    
    working_template_id = params[:dt_id]
    working_template = DataTemplate.find_by_id(working_template_id) unless working_template_id.nil?
    
    # reject upload if item sheet template does not match current working template (KLARATEE-188)
    if excel_template_id.to_s != working_template_id
      rejectUploadWithError("Invalid Spreadsheet: The uploaded spreadsheet item template does not match current working item template (#{working_template._?.name}).", '/items')
      return            
    end    
    
    data_template = working_template
    dt_columns = data_template.data_template_columns
    
    # show error and abort if we cannot load the template from the ID stored in the spreadsheet
    if data_template.nil?
      rejectUploadWithError("Invalid Spreadsheet: The data template for this sheet could not be loaded.", '/items')
      return      
    end
    
    # Check that the template columns have not changed since downloading the spreadsheet
    # preventing upload for now, should maybe be more lenient if only column ordering changed?
    dt_columns.each_with_index do |col, index|
      logger.info col.name + '|' + item_sheet.[](0,index + 1 + audit_offset)
      if item_sheet.[](0,index + 1 + audit_offset).to_s != col.name.to_s
        rejectUploadWithError("Invalid Spreadsheet: The template has changed since you dowloaded the items sheet, or you made unsupported structural changes to this items sheet.  Please download a new items sheet and retry the upload.", '/items')
        return
      end
    end
    
    # Create the item upload result record
    iur = ItemUploadResult.new
    iur.creator_id = current_user.id
    iur.created_at = Time.now
    iur.event_id = @selected_event.id
    iur.data_template_id = data_template.id
    iur.filename = my_file.original_path
    iur.save # save now as we need the id for persisting the error records
    
    # # # # # # # # # # # # # # #
    # Process Items sheet
    #
    ivs_to_create = []
    ies_to_create = []
    create_count = 0
    modify_count = 0
    delete_count = 0
    
     ( item_sheet.dimensions()[0]+1..item_sheet.dimensions()[1]-1 ).each_with_index do |row, row_count|
      
      row_count += 1 # offset for header row 
      
      # get item ID column value, if it exists
      item_id = item_sheet.[](row_count,0)
      
      # get the deleted? column contents
      deleted = item_sheet.[](row_count, dt_columns.size + audit_offset + 1)
      
      if item_id.nil?
        # process item CREATE
        if createTemplateItem(data_template.id, dt_columns, item_sheet, audit_offset, row_count, ivs_to_create, ies_to_create, iur.id)
          create_count += 1
        end
        
      else 
        if deleted.nil? || (deleted != 'y' && deleted != 'Y' && deleted != 'yes' && deleted != 'Yes')
          # process item MODIFY
          if modifyTemplateItem(item_id, dt_columns, item_sheet, audit_offset, row_count, ies_to_create, iur.id)
            modify_count += 1
          end
          
        else
          # process item DELETE
          if deleteTemplateItem(item_id)
            delete_count += 1
          end
        end
      end
      
    end
    
    # bulk insert all item values, if any item creates in this upload
    if create_count > 0
      #Note: include binary value even though it is not yet supported in the app
      fields = [:item_id, :data_template_column_id, :string_value, :int_value, :decimal_value, :text_value, :binary_value]
      ItemValue.import fields, ivs_to_create
    end
    
    # bulk insert all item errors, if any were encountered during processing
    if ies_to_create.size > 0
      fields = [:item_upload_result_id, :excel_sheet, :excel_line, :item_id, :data_template_column_id, :entered_value, :error_message]
      ItemUploadError.import fields, ies_to_create
    end
    
    # Create the item upload results DB record
    iur.new_count = create_count
    iur.mod_count = modify_count
    iur.deleted_count = delete_count
    iur.error_count = ies_to_create.size
    iur.save
    
    stats = "#{create_count} created. #{modify_count} modified. #{delete_count} deleted. #{ies_to_create.size.to_s} errors."
    
    # Add audit table entry for this template items excel upload
    AuditRecord.create(current_user.id, session, @selected_event.id, data_template.id, session[:acting_as_supplier],
                       AuditRecord::CATEGORIES[:item_sheet_upload], params[:controller], params[:action],
                       "User uploaded template items file, #{stats}")    
    
    flash[:notice] = "Item sheet processed successfully. #{stats}" + (ies_to_create.size > 0 ?
                     "  <a href='#{url_for(:controller => 'upload', :action => 'errors', :iur_id => iur.id)}'>Click here</a> to view the error report." : "")
    
    redirect_to(upload_index_url + "?data_template[id]=#{params[:dt_id]}&event[id]=#{@selected_event.id}")
    
  end
  
  def rejectUploadWithError (error_message, redirect_location)
    flash[:error] = error_message
    logger.error error_message
    redirect_back_or_default redirect_location
  end
  private :rejectUploadWithError
  
  def deleteTemplateItem item_id
    item_to_delete = Item.find_by_id item_id
    if !item_to_delete.nil?
      # delete item values
      ivs_to_delete = ItemValue.find(:all, {:conditions => ["item_id = ?", item_id]})
      if !ivs_to_delete.nil?
        ivs_to_delete.each do |iv_to_delete|
          iv_to_delete.delete
        end
      end
      item_to_delete.delete
      return true
    else
      return false
    end
  end
  private :deleteTemplateItem
  
  def modifyTemplateItem item_id, dt_columns, item_sheet, audit_offset, row_count, ies_to_create, iur_id
    
    # grab the item
    mod_item = Item.find_by_id(item_id)
    
    # find all item values for this item and place in a map by template col id
    ivs = ItemValue.find(:all, {:conditions => ["item_id = ?", item_id]})
    iv_by_col_id = {}
    ivs.each do |item_val|
      iv_by_col_id[item_val.data_template_column_id] = item_val
    end
    
    item_modified = false
    item_valid = true
    
    # cycle through template columns, editing item values as needed
    dt_columns.each_with_index do |col, c_index|
      iv = iv_by_col_id[col.id]
      
      item_validation_errors = []
      
      if iv.nil?
        # add a new item value table entry, since one is missing (new template column was added)
        iv = ItemValue::create(item_id, col, nil)
      end
      
      cell_data = get_cell_value(item_sheet[row_count, c_index + 1 + audit_offset])
      
      if col.required && cell_data.nil?
        item_validation_errors.push 'item_value_errors.required'
      end
      
      if (col.col_type == 'select_one' || col.col_type == 'select_many' || col.col_type == 'string_value')
        str_cell_value = validate_string_value(col, cell_data, item_validation_errors)
        if str_cell_value != iv.string_value
          iv.string_value = str_cell_value
          iv.save
          item_modified = true
        end
      elsif col.col_type == 'int_value'
        if cell_data != iv.int_value
          if cell_data.kind_of?(Integer) || cell_data.kind_of?(Float)
            iv.int_value = cell_data
            iv.save
            item_modified = true
          else
            item_validation_errors.push 'item_value_errors.integer_type' 
          end
        end
      elsif col.col_type == 'decimal_value'
        if cell_data != iv.decimal_value
          if cell_data.kind_of?(Float) || cell_data.kind_of?(Integer)
            iv.decimal_value = cell_data
            iv.save
            item_modified = true
          else
            item_validation_errors.push 'item_value_errors.decimal_type' 
          end
        end
      elsif col.col_type == 'text_value'
        text_cell_value = non_numeric_to_string(cell_data)
        if text_cell_value != iv.text_value
          iv.text_value = text_cell_value
          iv.save
          item_modified = true
        end
      end
      
      # build item validation errors for this column to persist in DB
      item_validation_errors.each do |error|
        item_valid = false
        ive = []
        ive.push iur_id
        ive.push 'Items'
        ive.push row_count + 1
        ive.push item_id
        ive.push col.id
        ive.push cell_data
        ive.push error
        ies_to_create.push ive
      end      
            
    end
    
    if item_modified || ! (item_valid == mod_item.is_valid) 
      # force the item level user stamps to be updated
      mod_item.is_valid = item_valid
      mod_item.updated_at = Time.now
      mod_item.surrogate_updater_id = session[:surrogate_parent].nil? ? nil : session[:surrogate_parent][:user_id]    
      mod_item.save
    end
    
    return item_modified
  end
  private :modifyTemplateItem
  
  def createTemplateItem data_template_id, dt_columns, item_sheet, audit_offset, row_count, ivs_to_create, ies_to_create, iur_id
    
    item = Item.new
    item.is_dirty = false
    item.is_approved = false
    item.is_valid = true
    # set the supplier id to the supplier stored in the session (contact supplier or event manager surrogate supplier)
    item.supplier_id = session[:acting_as_supplier].id unless session[:acting_as_supplier].nil?
    # Set the surrogate audit information if this item is being added via surrogate
    surr_id = session[:surrogate_parent].nil? ? nil : session[:surrogate_parent][:user_id]
    item.surrogate_creator_id = surr_id
    item.surrogate_updater_id = surr_id
    
    item.data_template_id = data_template_id
    item.save
    
    dt_columns.each_with_index do |col, c_index|
      i_val = []
      item_validation_errors = []
      
      # create an array including all column values for bulk insert later using ar-extensions gem import function
      i_val.push item.id
      i_val.push col.id
      
      cell_data = get_cell_value(item_sheet[row_count, c_index + 1 + audit_offset])
      
      if col.required && cell_data.nil?
        item_validation_errors.push 'item_value_errors.required'
      end
      
      string_val = validate_string_value(col, cell_data, item_validation_errors)
      i_val.push(string_val)
      
      int_val = nil
      if col.col_type == 'int_value'
        if cell_data.kind_of?(Integer) || cell_data.kind_of?(Float)
          int_val = cell_data
        else
          item_validation_errors.push 'item_value_errors.integer_type' 
        end
      end
      i_val.push(int_val)
      
      decimal_val = nil
      if col.col_type == 'decimal_value'
        if cell_data.kind_of?(Float) || cell_data.kind_of?(Integer)
          decimal_val = cell_data
        else
          item_validation_errors.push 'item_value_errors.decimal_type' 
        end
      end
      i_val.push(decimal_val)
      
      text_val = nil
      if col.col_type == 'text_value'
        text_val = non_numeric_to_string(cell_data)
      end
      i_val.push(text_val)
      i_val.push nil #binary value
      
      # build item validation errors for this column to persist in DB
      item_validation_errors.each do |error|
        item.is_valid = false
        ive = []
        ive.push iur_id
        ive.push 'Items'
        ive.push row_count + 1
        ive.push item.id
        ive.push col.id
        ive.push cell_data
        ive.push error
        ies_to_create.push ive
      end      
      
      ivs_to_create.push i_val
    end
    
    if ! item.is_valid
      item.save        #only save if changing item validity
    end
    
    return true
  end
  private :createTemplateItem
  
  def validate_string_value col, data, error_messages
    string_val = nil
    if (col.col_type == 'select_one' || col.col_type == 'select_many') && ! (data.nil? || data == '')
      pos_vals = col.data_template_column_possible_values.collect { |p_val| p_val.possible_value }
      string_val = non_numeric_to_string data
      if col.col_type == 'select_many'
        #disect multiple string values for validation
        excel_values = string_val.split ','
        validated_vals = []
        all_valid = true
        excel_values.each do |e_val|
          if pos_vals.include? e_val
            validated_vals.push e_val
          else
            all_valid = false
          end
        end
        
        if ! all_valid
          error_messages.push 'item_value_errors.multiple_select_invalid'
        end
        
        # put validated values back together for DB insertion
        string_val = validated_vals.join ','
      else
        if !pos_vals.include?(string_val)
          error_messages.push 'item_value_errors.select_invalid'
          string_val = nil
        end
      end
    elsif col.col_type == 'string_value'
      string_val = non_numeric_to_string data
    end
    
    return string_val
  end
  private :validate_string_value
  
  
  def force_string_conversions attrs, fields
    # Make sure the these fields get converted to a strings properly
    fields.each do |field|
      attrs[field] = non_numeric_to_string(attrs[field])
    end
  end
  private :force_string_conversions  
  
  def non_numeric_to_string input
    if !input.nil?
      if !input.kind_of?(String) && !input.kind_of?(Date)
        input = sprintf("%.0f", input)
      elsif input.kind_of?(Date)
        input = input.strftime("%m/%d/%Y")
      end
    end
    return input
  end
  private :non_numeric_to_string  
  
  def get_cell_value input
    value = nil
    if !input.nil?
      value = input.kind_of?(Spreadsheet::Formula) ? input.value : input
    end
    return value
  end
  private :get_cell_value  
  
end
