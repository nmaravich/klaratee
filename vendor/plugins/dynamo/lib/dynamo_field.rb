class DynamoField < ActiveRecord::Base
  # Associations
  has_many :dynamo_field_values, :dependent => :destroy
  validates_presence_of :field_name
end