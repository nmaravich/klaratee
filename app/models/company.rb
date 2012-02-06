class Company < ActiveRecord::Base

  has_many :company_products
  has_many :products, :through => :company_products
  has_many :company_users
  has_many :users, :through => :company_users
  
  # Company is in the top level db
  establish_connection RAILS_ENV
  
  has_and_belongs_to_many :users
  user_stampable :stamper_class_name => :user
  
end
