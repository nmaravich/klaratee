module Admin::FieldsHelper
  
  # Return array of dynamic attributes for the given model
  # example:
  #  dump_dynamo_attributes('Supplier')
  def dump_dynamo_attributes(model)
    attrs=[]
    model.dynamo_fields.each do |attr|
      attrs << attr 
    end
    attrs
  end
  
  def dynamo_delete_attr_link(model_name,field_name)
    link_to(image_tag("template-col-delete.png", :alt => 'delete field', :border=>0), { :controller=> "admin/fields", :method=>:delete, :action=>'destroy', :field_name=>field_name, :model_name=>model_name}, :confirm=>'Careful. This action is not reversable.Are you sure you want to remove?')
  end
  
  def dump_non_dynamo_attributes(model)
    # We don't want to display these because they aren't normally displayed/manipulated attributes.
    hide_these=['updated_at','creator_id','updater_id']
    returning [] do |show_these|
      # Need an instance so we have access to the instance methods
      dynamo_model_instance = model.new
      dynamo_model_instance.attributes.keys.each do |attr|
        if !dynamo_model_instance.is_dynamo_field?(attr) && !hide_these.include?(attr)
          show_these << attr        
        end
      end
    end
  end
  
end # Admin::FieldsHelper
