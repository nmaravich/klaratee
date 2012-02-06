class Item < ActiveRecord::Base
  
  belongs_to :supplier
  belongs_to :data_template
  has_many :item_values, :dependent => :destroy
  has_many :data_template_columns, :through => :item_values
  user_stampable 

  # System columns for items and master items screens
  SYSTEM_COLS = ['created_by',
               'created_at',
               'last_updated_by',
               'updated_at',
               'template_name'].freeze

  def self.generate_items_for_template_supplier(template, supplier_user, order_string)
    
    dyna_cols = Array.new
    template.data_template_columns.each do |col|
      dyna_cols.push build_column_sql(col,false,1)
    end
    
    # If this template has no columns i'm out
    return nil if dyna_cols.size < 1

    the_first = Supplier.first_of_user(supplier_user)[0]

    if the_first.nil?
      return generate_items_for_template(template, order_string)
    else
      supplier_id = the_first[:id]
    end

    # Make sure you only retrieve the values for the correct data templates.  Otherwise a template in two separate events
    # has the same column name its values will appear here.
    where_clause = "WHERE dtc.data_template_id = #{template.id} AND i.supplier_id = #{supplier_id}"
    
    #ordering
    if order_string.nil?
      order_string = 'id asc'
    end
    
    sql = build_template_items_sql(dyna_cols, where_clause, order_string)
    
    sql # return value
  end
  
  def self.generate_items_for_template(template, order_string)
    
    dyna_cols = Array.new
    template.data_template_columns.each do |col|
      dyna_cols.push build_column_sql(col,false,1)
    end
    
    # If this template has no columns i'm out.
    return nil if dyna_cols.size < 1

    # Make sure you only retrieve the values for the correct data templates.  Otherwise a template in two separate events
    # has the same column name its values will appear here.
    dt_where_clause = "WHERE dtc.data_template_id = #{template.id} "
    
    #ordering
    if order_string.nil?
      order_string = 'id asc'
    end
    
    sql = build_template_items_sql(dyna_cols, dt_where_clause, order_string)

    sql # return value
  end
  
  def self.generate_master_items_query(event, order_string)
    
    return nil if event.nil?
    
    dyna_cols = Array.new
    dt_ids = []
    col_name_counts = {}
    event.data_templates.each do |dt|
      dt_ids.push dt.id
      dt.data_template_columns.each do |col|
        if col_name_counts.has_key?(col.name)
          col_name_counts[col.name] = col_name_counts[col.name] + 1
        else
          # only generate column name SQL for the first appearance of the column name
          dyna_cols.push build_column_sql(col,true,col_name_counts[col.name])
          col_name_counts[col.name] = 1
        end
      end
    end
    
    # If this event has no templates or columns make like a tree... and get outta here.
    return nil if dyna_cols.size < 1
    
    # Make sure you only retrieve the values for the correct data templates.  Otherwise a template in two separate events
    # has the same column name its values will appear here.
    dt_where_clause = "WHERE dtc.data_template_id IN ( #{dt_ids.join(',')} ) "
    
    #ordering
    if order_string.nil?
      order_string = 'id asc'
    end
    
    sql = build_master_items_sql(dyna_cols, dt_where_clause, order_string)
    
    sql # return value
  end     
  
  #  private
  def self.build_column_sql(col, is_master_items, col_use_count)
    sql = ""
    # If its a select list type column then the selected value is stored in the string_value column.
    # This differs from the other columns where the data_template_column.col_type = the item_values column name. ( string_value / string_value )
    if( col.col_type == 'select_one' || col.col_type == 'select_many' )
      sql += "group_concat(CASE '#{col.name}' WHEN dtc.name THEN iv.string_value end) " +
             "AS '" + col.sha1_name + "' "
    elsif ( col.col_type == 'decimal_value' )
      sql += "group_concat(CASE '#{col.name}' WHEN dtc.name THEN CAST(iv.decimal_value as char) end) " +
             "AS '" + col.sha1_name + "' "
    else
      sql += "group_concat(CASE '#{col.name}' WHEN dtc.name THEN iv.#{col.col_type} end) " +
             "AS '" + col.sha1_name + "' "
    end
    
    sql # return value
    
  end
  
  def self.build_template_items_sql(dyna_cols, where_clause, order_string)
    
        <<-sql  
        SELECT *
        FROM (
          SELECT i.id, cr_user.login as created_by, ed_user.login as last_updated_by, i.created_at, i.updated_at,
                 i.surrogate_creator_id, i.surrogate_updater_id,
                 scr_user.login as created_by_sgt, sed_user.login as last_updated_by_sgt, 
          #{dyna_cols.join(",\n")}
          FROM data_template_columns dtc
          inner join  item_values iv on iv.data_template_column_id = dtc.id
          inner join items i on i.id = iv.item_id
          inner join aux_users cr_user on cr_user.id = i.creator_id
          inner join aux_users ed_user on ed_user.id = i.updater_id
          left outer join aux_users scr_user on scr_user.id = i.surrogate_creator_id
          left outer join aux_users sed_user on sed_user.id = i.surrogate_updater_id
          #{where_clause}          
          GROUP BY i.id
      ) AS x ORDER BY #{order_string}
sql
      
  end
  
  def self.build_master_items_sql(dyna_cols, where_clause, order_string)
    
        <<-sql  
        SELECT *
        FROM (
          SELECT i.id, template.id as my_template_id, template.name as template_name,
                  cr_user.login as created_by, ed_user.login as last_updated_by, i.created_at, i.updated_at,
                  i.surrogate_creator_id, i.surrogate_updater_id,
                  scr_user.login as created_by_sgt, sed_user.login as last_updated_by_sgt, 
          #{dyna_cols.join(",\n")}
          FROM data_template_columns dtc
          INNER join item_values iv on iv.data_template_column_id = dtc.id
          INNER join items i on i.id = iv.item_id
          INNER join data_templates template on dtc.data_template_id = template.id
          inner join aux_users cr_user on cr_user.id = i.creator_id
          inner join aux_users ed_user on ed_user.id = i.updater_id
          left outer join aux_users scr_user on scr_user.id = i.surrogate_creator_id
          left outer join aux_users sed_user on sed_user.id = i.surrogate_updater_id
          #{where_clause}          
          GROUP BY i.id
      ) AS x ORDER BY #{order_string}
sql
      
  end
  
end
