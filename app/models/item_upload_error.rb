class ItemUploadError < ActiveRecord::Base
  
  
  UE_SQL = "
      select ue.*, dtc.name as template_col_name
        from item_upload_errors ue
        left outer join data_template_columns dtc on ue.data_template_column_id = dtc.id
        where ue.item_upload_result_id = ?
        order by "
  
end
