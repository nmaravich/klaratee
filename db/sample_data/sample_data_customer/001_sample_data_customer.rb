# Users - Auxiliary table (If you update this, update the corresponding users in the master seed)
#AuxUser.create!(:creator_id => 1, :login => "buyer", :email => "testing@avadatum.com", :first_name => "Sample", :last_name => "Buyer", :creator=> 1)

## Suppliers
#Supplier.create!(:company_name => 'Farmers Best' )
#Supplier.create!(:company_name => 'Ship CO' )
#
## Contacts
#Contact.create!(:f_name => "George", :l_name => "Jackson", :email=>"test-supplier@klaratee.com", :title=>"President", :user_id => 4)
#Contact.create!(:f_name => "Edward", :l_name => "Thomson", :email=>"test-supplier2@klaratee.com", :title=>"CEO", :user_id => 5)
#
## Supplier Contacts
## ValidTypes "Primary", "Secondary"
#SupplierContact.create!(:supplier_id => 1, :contact_id => 1, :contact_type=>'Primary' )
##SupplierContact.create!(:supplier_id => 1, :contact_id => 2, :contact_type=>'Secondary' )
#
## Same contact for two different companies is allowed.
#SupplierContact.create!(:supplier_id => 2, :contact_id  => 2, :contact_type=>'Primary' )
#
## Events
#Event.create!(:name => "Winter Packing", :start_date => "2010-04-19", :end_date => "2010-05-19", :status => :open)
#Event.create!(:name => "Summer Wheat Transfer", :start_date => "2010-06-19", :end_date => "2010-07-19", :status => :pending )
#
## DataTemplates
#DataTemplate.create!(:name => 'Northern Region', :description => 'Suppliers in the north', :event_id => 1 )
#DataTemplate.create!(:name => 'Southern Region', :description => 'Suppliers in the south', :event_id => 2 )
#
## Items (commented these out ... they were being created as zombies, without associated item values)
##Item.create!(:is_dirty => 1, :is_valid => 0, :is_approved => 1, :supplier => 1)
##Item.create!(:is_dirty => 1, :is_valid => 0, :is_approved => 1, :supplier => 1)
#
## DataTemplateColumns
#DataTemplateColumn.create!(:name=> 'name',        :col_type=>'string_value', :data_template_id=>1, :order=>1)
#DataTemplateColumn.create!(:name=> 'description', :col_type=>'string_value', :data_template_id=>1, :order=>2)
#DataTemplateColumn.create!(:name=> 'age',         :col_type=>'string_value', :data_template_id=>1, :order=>3)
#
#DataTemplateColumn.create(:name=> 'rank',        :col_type=>'string_value', :data_template_id=>2, :order=>1)
#DataTemplateColumn.create(:name=> 'serial number', :col_type=>'string_value', :data_template_id=>2, :order=>2)
#
## DataTemplateContacts  (i.e. invitees)
#DataTemplate.first.contacts << Contact.first
#DataTemplate.first.contacts << Contact.last
#DataTemplate.last.contacts << Contact.last