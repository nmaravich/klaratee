module SoftDelete
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def is_soft_deletable(*attrs)
      self.class_eval do
        # Add a default scope to this model so deleted items won't appear in the views
        logger = ActiveRecord::Base.logger
        begin
          # only add the new default_scope if this class has the deleted column
          default_scope :conditions=>{:deleted => 0}# if self.column_names.include?("deleted")
          # Note: if you check for the deleted column first then you'll get an error after you restart your server because
          # at that point you haven't selected a db to connect to so it will try the default ( which is the master ). 
          # Deleted records will appear in your views at that point because the scope won't have been added.
        rescue Exception => e
          logger.error "SoftDelete: #{e}"
        end
      end
    end # is_soft_deleteable
  end # ClassMethods
end # SoftDelete

# Important because any model you use this in will extend from activeRecord.
ActiveRecord::Base.send :include, SoftDelete
