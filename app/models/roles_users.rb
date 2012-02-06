class RolesUsers < ActiveRecord::Base
  establish_connection RAILS_ENV
  # the habtm join table for roles X users
end
