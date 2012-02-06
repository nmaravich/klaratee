class MasterItemsController < ApplicationController
  layout "standard"
  before_filter :login_required , :dyna_connect  

  include EventAware 
  before_filter :event_aware
  
  filter_resource_access :additional_collection => :master_items

  
  # GET /master_items
  # GET /master_items.xml
  def index
    
    if !@selected_event.nil? && !@selected_data_template.nil?
      
      # hash of master items column names as keys, value is number of times used in all templates
      # so that we can sort and show the most used columns first
      mi_cols = {}
      
      @template_cols_by_template_id = []
      col_names_sha1 = []
      
      # Determine master items columns (all unique column names across templates)
      @ea_data_templates.each_with_index do |template, k|
        
        tcols = Set.new
        template.data_template_columns.each do |col|
          tcols.add(col.sha1_name)
        end
        
        @template_cols_by_template_id[template.id] = tcols
        
        template.data_template_columns.each_with_index do |col, index|
          col_name_sha1 = col.sha1_name
          col_names_sha1.push col_name_sha1 unless col_names_sha1.include?(col_name_sha1)
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
      @sorted_cols = mi_cols.sort { |a,b| b[1] <=> a[1] }
      
      # Set col[3] to the sha1 hash of the column name as this is used throughout the view
      # for paging/sorting and in the master items DB query to properly handle column names with special characters
      @sorted_cols.each do |col|
        col[3] = Digest::SHA1.hexdigest(col[0])
      end
      
      order_string = (! params[:sort_by].nil? && (col_names_sha1.include?(params[:sort_by]) || Item::SYSTEM_COLS.include?(params[:sort_by]))) ?
                   "`#{params[:sort_by]}` #{params[:sort_type].upcase}" : nil
      
      # get template items
      sql = Item.generate_master_items_query( @selected_event, order_string )
      
      # Run said sql to get the items
      @items =  Item.paginate_by_sql( sql , :page => params[:page] ) unless sql.nil?
      
    end
    
    respond_to do |format|
      format.html # master_items.html.erb
    end
    
  end
    
end