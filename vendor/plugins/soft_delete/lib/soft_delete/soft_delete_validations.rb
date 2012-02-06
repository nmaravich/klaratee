module SoftDeleteValidations
  
  def self.included(base)
    base.class_eval do
      # You don't want to consider model rows that have been soft deleted during a uniqueness validation.
      # Example:
      # Create a supplier with a :company_name of 'sears'  
      # In the Supplier model you have: validates_uniqueness_of :company_name
      # Now you delete that supplier.
      # When you create a new Supplier and try to give a company_name of 'sears' the validation will fail!
      # 
      # To resolve this you just need to add a scope:
      # alidates_uniqueness_of :company_name, :scope=> :deleted
      # But you don't want someone using the plugin to have to do that in their models.
      # 
      # Instead we automatically at the scope for them here using some metaprogramming magic.
      def validates_uniqueness_of_with_deleted(*attr)
        if table_exists? && column_names.include?('deleted')
          configuration = attr.extract_options!
          configuration[:scope] ||= :deleted
          attr.push(configuration)
        end
        validates_uniqueness_of_without_deleted(*attr)
      end
      
      alias_method_chain :validates_uniqueness_of, :deleted
      
    end #class_eval
  end #included
end # SoftDeletedValidations

ActiveRecord::Validations::ClassMethods.send :include, SoftDeleteValidations