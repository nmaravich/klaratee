class ItemUploadResult < ActiveRecord::Base
  
  
  UR_SQL = "
      select ur.*, ev.name as event_name, dt.name as template_name
        from item_upload_results ur
        left outer join events ev on ur.event_id = ev.id
        left outer join data_templates dt on ur.data_template_id = dt.id
        where ur.creator_id = ?
        order by "
  
end
