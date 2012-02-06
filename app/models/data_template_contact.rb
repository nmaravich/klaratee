class DataTemplateContact < ActiveRecord::Base
  belongs_to :data_template
  belongs_to :contact
end
