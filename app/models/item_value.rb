require 'ar-extensions'
class ItemValue < ActiveRecord::Base
  belongs_to :data_template_column
  belongs_to :item
  
  def self.create(item_id, col, value)
    iv = ItemValue.new
    iv.item_id = item_id
    iv.data_template_column_id = col.id
    # Warning!  Rails Magic!
    # This is pretty cool, but pretty nuts.  The send method calls the object's method that has the name given.
    # So iv.send("string_value") calls the ItemValue's string_value getter as if you types: iv.string_value
    # I'm using it to set the incoming value into the correct place without a messy decision structure.
    # If you didn't do this you would have to have an if block like:
    # if col.col_type == "string_value" then iv.string_value = params[col.name] elsif col.col_type == "integer_value", etc
    # That logic would also require a code change here if another type was added, while this rubified solution won't.  
    # The second magic is the params[col.name].  We're saying take from the params the parameter
    # that has the same name as this particular columns name and set it to the appropriate column.
    # Again, its like saying params["description"] but saves us work.
    # And finally, the weirdness with "#{col.col_type}=" is that we need the string_value setter and the 
    # setter's method name is officially string_value= while the getter is just string_value.
    # So now all the lines i've saved with this cool trick i've uglied up with a humungous comment block :)
    if col.col_type == 'select_one'
      iv.string_value = value
    elsif col.col_type == 'select_many'
      iv.string_value = value.collect {|i| i }.join(', ') unless value.nil?
    else
      iv.send("#{col.col_type}=", value)
    end
    iv # return value
  end  
  
end
