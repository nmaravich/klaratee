class SupplierContact < ActiveRecord::Base
  # Associations
  belongs_to :supplier
  belongs_to :contact
  user_stampable
  
  # make sure you have an :int column named delete in your model
  is_soft_deletable
  
  TYPES=["Primary", "Secondary"].freeze
end
