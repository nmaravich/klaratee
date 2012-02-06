module ApplicationHelper
  
  def link_to_delete_modal(obj, obj_name=obj.class.to_s.downcase, msg=nil, modal_height=140)
    html=[]
    html <<  link_to_function('Delete', "generic_modal_confirm_delete(#{obj.id}, '#{obj_name}', '#{msg}', #{modal_height})");
  end
  
  def get_current_company
    session[:cur_company].name
  end
  
  def file_download_label
    "#{get_current_company}_#{Time.now.strftime("%m%d%Y-%H%M%S")}"
  end
  
end
