class SupplierNote < ActiveRecord::Base
  belongs_to :supplier
  user_stampable
  
end
