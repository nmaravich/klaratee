class StatusException < ActiveRecord::Base  
  belongs_to :event
  belongs_to :aux_user
end
