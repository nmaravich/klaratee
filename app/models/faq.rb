class Faq < ActiveRecord::Base
    acts_as_tree_on_steroids
    enum_attr :status, %w(open archived), :nil => false, :init=>:open
    enum_attr :visibility, %w(public private), :nil => false, :init=>:private
    belongs_to :user, :class_name => "AuxUser"
    
    def event_id
       return Faq.find(id_path.split(/,/)[0].to_i).family_id
    end
  
    def date_of_newest_child
       date = self.children.find(:first, :order=>"updated_at DESC", :select=>:updated_at)
       if date.nil?
         return nil
       else
         return date.updated_at
       end
    end
  
  
end
