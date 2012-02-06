class Role < ActiveRecord::Base
  establish_connection RAILS_ENV
  
  ADMIN = "Admin"
  BUYER = "Buyer"
  SUPPLIER = "Supplier"
  
  user_stampable :stamper_class_name => :user
end
