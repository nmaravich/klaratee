class ActiveRecord::Base
  alias :old_destroy :destroy
  
  def destroy
    if self.respond_to?(:deleted)
      run_callbacks(:before_destroy)
      # This handles associated tables also.  So users.deleted=1 as does users.address.deleted and addresses.deleted
      connection.execute("UPDATE #{self.class.quoted_table_name} SET deleted = 1 " + "WHERE #{self.class.quoted_table_name}.#{self.class.primary_key} = #{self.id}")
      run_callbacks(:after_destroy)
    else
      unless new_record?
        self.old_destroy
      end
    end
  end
end