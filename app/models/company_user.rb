class CompanyUser < ActiveRecord::Base
  establish_connection RAILS_ENV
  belongs_to :user
  belongs_to :company
end
