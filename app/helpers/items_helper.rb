module ItemsHelper
  
  # Saves some ugly in the view.
  def
    show_item_values(item)
    return item.item_values.collect {|i| i.value }.join(', ')
  end
  
end
