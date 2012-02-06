class DownloadController < ApplicationController
  
  require 'spreadsheet'
  include EventAware
  before_filter :event_aware, :only => [ :template_items_xls, :master_items_xls ]
  before_filter :login_required, :dyna_connect
  # COLORS = [ :builtin_black, :builtin_white, :builtin_red, :builtin_green,
  #            :builtin_blue, :builtin_yellow, :builtin_magenta, :builtin_cyan,
  #            :text, :border, :pattern_bg, :dialog_bg, :chart_text, :chart_bg,
  #            :chart_border, :tooltip_bg, :tooltip_text, :aqua,
  #            :black, :blue, :cyan, :brown, :fuchsia, :gray, :grey, :green,
  #            :lime, :magenta, :navy, :orange, :purple, :red, :silver, :white,
  #            :yellow ]
  
  filter_access_to :all
  filter_access_to :template_items_xls, :attribute_check => true, :load_method => :template_items_xls_obj
  
  def template_items_xls_obj
    @obj = {}
    @obj = {:can_dl_this_template => current_aux_user.invited_to_template?(params[:data_template_id])}
  end  
  private :template_items_xls_obj
  
  
  def index
    flash[:notice] = "Upload INDEX"
    redirect_back_or_default('/suppliers')
  end
  
  ############################################################
  # download_supplier_xls
  #
  def download_supplier_xls
    
    # Defines attributes being uploaded
    s_header_row_static = Supplier::HEADER_ROW
    c_header_row_static = Contact::HEADER_ROW
    
    #    Spreadsheet.client_encoding = 'UTF-8'
    #    Spreadsheet.client_encoding = 'LATIN1//TRANSLIT//IGNORE' 
    #    utf8(string, client=Spreadsheet.client_encoding)
    #     utf8("", Spreadsheet.client_encoding)
    Spreadsheet.client_encoding = 'UTF-8'
    
    book = Spreadsheet::Workbook.new
    
    # Add worksheet(s)
    sheet1 = book.create_worksheet :name => 'Instructions'
    sheet2 = book.create_worksheet :name => 'Suppliers'
    sheet3 = book.create_worksheet :name => 'Contacts'
    
    # Populate instructions sheet
    sheet1.row(0).default_format = Spreadsheet::Format.new :color =>'white', :pattern => 2 ,:pattern_bg_color => "orange",
        :weight => :bold, :size => 12
    sheet1.row(0).push "Klaratee Supplier and Supplier Contact Workbook"
    sheet1.row(2).push "Use the Suppliers sheet to edit or add new suppliers."
    sheet1.row(4).push "Use the Contacts sheet to edit or add new supplier contacts."
    sheet1.row(5).push "For each contact, use the text 'Primary' or 'Secondary' to designate the contact type for that supplier."
    sheet1.row(7).push "To delete an existing supplier or contact, insert a 'y' into the last column titled 'Delete?' for that row."
    sheet1.row(9).push "Make sure you do not save this file as excel 2007 file format (.xslx) or newer before uploading."
    sheet1.row(10).push "Klaratee only supports the MS Excel 97-2003 file format (.xls)."
    sheet1.row(12).push "After uploading/importing this spreadsheet, make sure you download/export a new spreadsheet before making more changes."
    sheet1.row(13).push "If you upload this sheet more than once, you risk adding duplicate contacts or suppliers."
    
    # Make first column wide to facilitate reading the instructions
    sheet1.column(0).width = 100
    
    
    # POPULATE SUPPLIERS SHEET
    # This is the formatting for the top row.  In order to get the background color to work you need
    # the pattern in there.
    sheet2.row(0).default_format = Spreadsheet::Format.new :color =>'white', :pattern => 2 ,:pattern_bg_color => "green",
        :weight => :bold, :size => 12
    
    # Building the static portion of the header row
    current_col = 0
    s_header_row_static.each_with_index do |attribute, index|
      current_col = index
      sheet2.row(0).push s_header_row_static[index][:col_name]
      sheet2.column(current_col).width = s_header_row_static[index][:col_width]
    end
    
    # Build the dynamic portion of the header row
    tmp_supplier = Supplier.new
    tmp_supplier.dynamo_fields do |field_name|
      current_col += 1
      sheet2.row(0).push field_name
      sheet2.column(current_col).width = 15      
    end
    
    #Build the delete column
    sheet2.row(0).push 'Delete?'
    sheet2.column(current_col + 1).width = 10      
    
    # Load suppliers from DB
    suppliers = Supplier.find( :all )
    
    # Write the supplier rows
    if suppliers != nil
      suppliers.each_with_index do |supplier, i| 
        offset = i + 1
        # populate static data
        s_header_row_static.each_with_index do |attribute, index|
          sheet2.row(offset).push supplier.attributes[ s_header_row_static[index][:attr_name] ] || ""
        end
        # populate dynamic data
        supplier.dynamo_fields do |field_name|
          sheet2.row(offset).push supplier.send(field_name)
        end
      end
    end
    
    # POPULATE CONTACTS SHEET
    # This is the formatting for the top row.  In order to get the background color to work you need
    # the pattern in there.
    sheet3.row(0).default_format = Spreadsheet::Format.new :color =>'white', :pattern => 2 ,:pattern_bg_color => "blue",
        :weight => :bold, :size => 12
    
    #Build the Company Name column
    sheet3.row(0).push 'Company Name'
    sheet3.column(0).width = 25
    
    #Build the Contact Type column
    sheet3.row(0).push 'Contact Type'
    sheet3.column(1).width = 16    
    
    # Building the static fields portion of the contacts header row
    current_col = 2
    c_header_row_static.each_with_index do |attribute, index|
      current_col = index + 2
      sheet3.row(0).push c_header_row_static[index][:col_name]
      sheet3.column(current_col).width = c_header_row_static[index][:col_width]
    end
    
    # Build the dynamic portion of the contacts header row
    tmp_contact = Contact.new
    tmp_contact.dynamo_fields do |field_name|
      current_col += 1
      sheet3.row(0).push field_name
      sheet3.column(current_col).width = 15      
    end
    
    #Build the delete column
    sheet3.row(0).push 'Delete?'
    sheet3.column(current_col + 1).width = 10    
    
    # Load contacts from DB
    contacts = Contact.find( :all )
    # Write the contact rows
    if contacts != nil
      offset = 0
      contacts.each_with_index do |contact, j|
        
        # Output a separate line for each contact-supplier relationship.
        # I am guessing this could be made more efficient by
        # using a native SQL query, not sure how many queries this code generates?
        contact.supplier_contacts.each_with_index do |sup_con, k|
          if ! sup_con.supplier.nil?
            offset += 1
            
            # output company name
            sheet3.row(offset).push sup_con.supplier.company_name
            
            # output contact type
            sheet3.row(offset).push sup_con.contact_type
            
            # output static contact data fields
            c_header_row_static.each_with_index do |attribute, c_index|
              sheet3.row(offset).push contact.attributes[ c_header_row_static[c_index][:attr_name] ] || ""
            end
            # populate dynamic (dynamo) contact data
            contact.dynamo_fields do |field_name|
              sheet3.row(offset).push contact.send(field_name)
            end
          else
            #delete supplier contact entry linked to a non-existent supplier (KLARATEE-83)
            sup_con.delete
          end
          
        end
        
      end
    end
    
    output_excel_spreadsheet(book, "suppliers_#{file_download_label}.xls")    
  end
  
  ############################################################
  # download_template_items_xls
  #
  def template_items_xls
    
    # spit to the log the database we are connected to
    db_cfg = ActiveRecord::Base.connection.instance_variable_get "@config"
    logger.info "DB = #{db_cfg[:database]}"
    
    Spreadsheet.client_encoding = 'UTF-8'
    
    book = Spreadsheet::Workbook.new
    
    # Add worksheet(s)
    sheet1 = book.create_worksheet :name => 'Instructions'
    sheet2 = book.create_worksheet :name => 'Items'
    
    this_event = Event.find_by_id(@selected_event)
    this_template = DataTemplate.find_by_id(params[:data_template_id])
    
    # Populate instructions sheet
    sheet1.row(0).default_format = Spreadsheet::Format.new :color =>'white', :pattern => 2 ,:pattern_bg_color => "orange",
        :weight => :bold, :size => 12
    sheet1.row(0).push "Klaratee Template Items Workbook"
    if this_event.nil?
      sheet1.row(2).push "Event: Not Selected"
    else
      sheet1.row(2).push "Event: " + this_event.name
    end
    sheet1.row(3).push "Template: " + this_template.name
    sheet1.row(5).push "Use the Items sheet to edit or add new items."
    sheet1.row(7).push "To delete an existing item, insert a 'y' into the last column titled 'Delete?' for that row."
    sheet1.row(9).push "Make sure you do not save this file as excel 2007 file format (.xslx) or newer before uploading."
    sheet1.row(10).push "Klaratee only supports the MS Excel 97-2003 file format (.xls)."
    sheet1.row(12).push "After uploading/importing this spreadsheet, make sure you download/export a new spreadsheet before making more changes."
    sheet1.row(13).push "If you upload this sheet more than once, you risk adding duplicate items."
    
    # Make first column wide to facilitate reading the instructions
    sheet1.column(0).width = 100
    
    data_template = DataTemplate.find_by_id(params[:data_template_id]) unless params[:data_template_id].blank? 
    
    if ! params[:data_template_id].blank? && ! data_template.nil?
      
      # This is the formatting for the top row.  In order to get the background color to work you need
      # the pattern in there.
      sheet2.row(0).default_format = Spreadsheet::Format.new :color =>'white', :pattern => 2 ,:pattern_bg_color => "brown",
          :weight => :bold, :size => 12
      
      # Create the Items sheet header row
      sheet2.row(0).push data_template.id
      audit_col_offset = 0
      if ! params[:show_item_audit].nil? && params[:show_item_audit] == 'yes'
        sheet2.row(0).push "Created By"
        sheet2.column(1).width = 15
        sheet2.row(0).push "Created"
        sheet2.column(2).width = 24
        sheet2.row(0).push "Last Updated By"
        sheet2.column(3).width = 20
        sheet2.row(0).push "Last Updated"
        sheet2.column(4).width = 24
        audit_col_offset = 4
      end
      
      data_template.data_template_columns.each_with_index do |col, index|
        
        sheet2.row(0).push col.name
        sheet2.column(index + 1 + audit_col_offset).width = 15
        
      end
      sheet2.row(0).push 'Delete?'
      
      # Hide first item sheet column for item ID
      sheet2.column(0).hidden = true
      
      if (has_role? :Supplier)
        sql = Item.generate_items_for_template_supplier( data_template, current_user, nil )
      else
        sql = Item.generate_items_for_template( data_template, nil )
      end
      
      # Run said sql to get the items.
      items =  Item.find_by_sql( sql ) unless sql.nil?
      
      # Warning: Ruby magic above!
      # because of the use of find_by_sql on a query that returns non-item table columns the Item objects
      # in the array will have getters for any of those joined in columns.  For example:
      # The query builds grouping statements into the query like this:
      # group_concat(CASE 'price' WHEN dtc.name THEN iv.decimal_value end order by iv.decimal_value asc) AS 'price'
      # That means that @items.first.price will return the price defined by this column in the query even though the
      # item object doesn't actually have a price attribute.  Crazy stuff.
      
      
      # Write the item rows
      if items != nil
        items.each_with_index do |item, i|
          sheet2.row(i + 1).push item.id
          if ! params[:show_item_audit].nil? && params[:show_item_audit] == 'yes'
            sheet2.row(i + 1).push item.created_by + (item.surrogate_creator_id.nil? ? '' : (' (via ' + item.created_by_sgt + ')'))
            sheet2.row(i + 1).push item.created_at.in_time_zone.strftime("%m/%d/%Y %I:%M%p %Z")
            sheet2.row(i + 1).push item.last_updated_by + (item.surrogate_updater_id.nil? ? '' : (' (via ' + item.last_updated_by_sgt + ')'))
            sheet2.row(i + 1).push item.updated_at.in_time_zone.strftime("%m/%d/%Y %I:%M%p %Z")
          end
          data_template.data_template_columns.each_with_index do |col, index|
            raw_value = item.send(col.sha1_name)
            if col.col_type == 'int_value'
              sheet2.row(i + 1).push raw_value.nil? ? nil : raw_value.to_i         
            elsif col.col_type == 'decimal_value'
              sheet2.row(i + 1).push raw_value.nil? ? nil : raw_value.to_f            
            else
              sheet2.row(i + 1).push raw_value            
            end
          end
        end
      end
      
    end
    
    filename = "Items-#{data_template.name}_#{file_download_label}.xls"
    # Audit this template item download
    AuditRecord.create(current_user.id, session, this_event.id, data_template.id, session[:acting_as_supplier],
    AuditRecord::CATEGORIES[:item_sheet_download], params[:controller], params[:action], filename)    
    
    output_excel_spreadsheet(book, filename)  
  end
  
  ############################################################
  # master_items_xls
  #
  def master_items_xls
    Spreadsheet.client_encoding = 'UTF-8'
    
    #not_in_template_format = Spreadsheet::Format.new :pattern => 2 ,:pattern_bg_color => "silver"
    
    book = Spreadsheet::Workbook.new
    
    # Add worksheet(s)
    sheet1 = book.create_worksheet :name => 'Instructions'
    sheet2 = book.create_worksheet :name => 'Master Items'
    
    this_event = Event.find_by_id(@selected_event)
    
    # Populate instructions sheet
    sheet1.row(0).default_format = Spreadsheet::Format.new :color =>'white', :pattern => 2 ,:pattern_bg_color => "orange",
        :weight => :bold, :size => 12
    sheet1.row(0).push "Klaratee Master Items Workbook"
    sheet1.row(2).push "This spreadsheet shows all items from all templates in this event."
    sheet1.row(4).push "Event: " + this_event.name
    sheet1.row(6).push "Templates: "
    
    @ea_data_templates.each_with_index do |template, k|
      sheet1.row(7 + k).push "           " + template.name
    end
    
    # Make first column wide to facilitate reading the instructions
    sheet1.column(0).width = 100
    
    if ! @ea_data_templates.empty?
      
      # hash of master items column names as keys, value is number of times used in all templates
      # so that we can sort and show the most used columns first
      mi_cols = {}
      
      template_cols_by_template_id = []
      
      # Determine master items columns (all unique column names across templates)
      @ea_data_templates.each_with_index do |template, k|
        
        tcols = Set.new
        template.data_template_columns.each do |col|
          tcols.add(col.sha1_name)
        end
        template_cols_by_template_id[template.id] = tcols
        
        template.data_template_columns.each_with_index do |col, index|
          if ! mi_cols.has_key?(col.name)
            mi_cols[col.name] = 10000 - col.order - (100 * k) # give weight based on template and template column order
          else
            # column already exists, so increment our column occurrence hash value counter
            mi_cols[col.name] = mi_cols[col.name] + 10000
          end
        end
      end
      
      # Sort the master items columns so that frequently used columns are shown first
      #   technically we are doing a reverse value-based hash sort here
      #   see http://corelib.rubyonrails.org/classes/Hash.html#M000705
      #   results (sorted_cols) in a nested array with the hash contents sorted
      #   col[0] is now the column name
      #   col[1] is the column weighting computed above for the col order
      sorted_cols = mi_cols.sort { |a,b| b[1] <=> a[1] }
      
      # Set col[3] to the sha1 hash of the column name as this is used throughout the view
      # for paging/sorting and in the master items DB query to properly handle column names with special characters
      sorted_cols.each do |col|
        col[3] = Digest::SHA1.hexdigest(col[0])
      end
      # This is the formatting for the top row.  In order to get the background color to work you need
      # the pattern in there.
      sheet2.row(0).default_format = Spreadsheet::Format.new :color =>'white', :pattern => 2 ,:pattern_bg_color => "brown",
          :weight => :bold, :size => 12
      
      # Create the Master Items sheet header row
      audit_col_offset = 0
      if ! params[:show_item_audit].nil? && params[:show_item_audit] == 'yes'
        sheet2.row(0).push "Created By"
        sheet2.column(0).width = 15
        sheet2.row(0).push "Created"
        sheet2.column(1).width = 24
        sheet2.row(0).push "Last Updated By"
        sheet2.column(2).width = 20
        sheet2.row(0).push "Last Updated"
        sheet2.column(3).width = 24
        audit_col_offset = 4
      end
      sheet2.row(0).push "Template"
      sheet2.column(audit_col_offset).width = 20
      
      sorted_cols.each_with_index do |col, index|  
        sheet2.row(0).push col[0]
        sheet2.column(index + 1 + audit_col_offset).width = 15
      end
      
      rowIndex = 1
      
      # get master items query
      sql = Item.generate_master_items_query( this_event, nil )
      
      # Run said sql to get the master items
      items =  Item.find_by_sql( sql ) unless sql.nil?
      
      # Output Master Items data rows
      items.each do |item|
        
        if ! params[:show_item_audit].nil? && params[:show_item_audit] == 'yes'
          sheet2.row(rowIndex).push item.created_by + (item.surrogate_creator_id.nil? ? '' : (' (via ' + item.created_by_sgt + ')'))
          sheet2.row(rowIndex).push item.created_at.in_time_zone.strftime("%m/%d/%Y %I:%M%p %Z")
          sheet2.row(rowIndex).push item.last_updated_by + (item.surrogate_updater_id.nil? ? '' : (' (via ' + item.last_updated_by_sgt + ')'))
          sheet2.row(rowIndex).push item.updated_at.in_time_zone.strftime("%m/%d/%Y %I:%M%p %Z")
        end
        
        sheet2.row(rowIndex).push item.template_name
        
        # Output column value for each column, if column exists in template
        sorted_cols.each_with_index do |col, cIndex|
          if ! template_cols_by_template_id[item.my_template_id.to_i].include?(col[3])
            sheet2.row(rowIndex).push "---"
            #sheet2[rowIndex,cIndex].set_format(not_in_template_format)
          else
            sheet2.row(rowIndex).push item.send(col[3]) || ""
          end
        end
        
        rowIndex = rowIndex + 1
      end
      
    end # if ! all_templates.empty?
    
    output_excel_spreadsheet(book,"Master_Items_#{this_event.name}_#{file_download_label}.xls")  
  end
  
  
  ############################################################
  # global_activity_xls
  #
  def global_activity_xls
    Spreadsheet.client_encoding = 'UTF-8'
    
    book = Spreadsheet::Workbook.new
    
    # Add worksheet(s)
    sheet1 = book.create_worksheet :name => 'Klaratee Global Activity'  
    
    # POPULATE GLOBAL ACTIVITY SHEET
    # This is the formatting for the top row.  In order to get the background color to work you need
    # the pattern in there.
    sheet1.row(0).default_format = Spreadsheet::Format.new :color =>'white', :pattern => 2 ,:pattern_bg_color => "green",
        :weight => :bold, :size => 12
    
    # Building the header row
    AuditRecord::HEADER_ROW.each_with_index do |attribute, index|
      sheet1.row(0).push AuditRecord::HEADER_ROW[index][:col_name]
      sheet1.column(index).width = AuditRecord::HEADER_ROW[index][:col_width]
    end        
    
    audit_records = AuditRecord.find_by_sql(AuditRecord::GLOBAL_ACTIVITY_SQL + 'ar.time desc')
    
    # Write the audit_records rows
    if audit_records != nil
      audit_records.each_with_index do |a_record, i|
        sheet1.row(i + 1).push a_record.user_name
        sheet1.row(i + 1).push a_record.surrogate_parent_login
        sheet1.row(i + 1).push a_record.supplier_name
        sheet1.row(i + 1).push AuditRecord::CATEGORY_TEXT[a_record.category]
        sheet1.row(i + 1).push a_record.time.getlocal.strftime("%m/%d/%Y %I:%M%p %Z")
        sheet1.row(i + 1).push a_record.event_name
        sheet1.row(i + 1).push a_record.template_name
      end
    end
    
    output_excel_spreadsheet(book, "Global_Activity_Report_#{file_download_label}")  
  end
  
  def output_excel_spreadsheet(workbook,filename)
    # http://www.ruby-doc.org/core/classes/IO.html#M002270
    excelStream = StringIO.new
    # http://spreadsheet.rubyforge.org/Spreadsheet/Workbook.html
    workbook.write excelStream
    # Need to rewind before read to prevent excel data corruption
    #  see: http://rubyforge.org/forum/forum.php?thread_id=29606&forum_id=2920
    excelStream.rewind
    send_data(excelStream.read, {:filename => filename, :type => 'application/excel'})
  end
  private :output_excel_spreadsheet
  
end
