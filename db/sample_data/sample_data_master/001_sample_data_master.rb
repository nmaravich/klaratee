# create! a new user via ./script/console using these commands:
# salt = Digest::SHA1.hexdigest("#{Time.now.to_s}")
# User.encrypt('ss_adm!n', '481cd0a0df53edd9016117d48769639ac2ee457c')

# Using a sql insert here because the user model is protected using attr_accessible.
# That prevents you from being able to modify some of the fields from here.
#sql = ActiveRecord::Base.connection();

# decrypted password is: password
#sql.execute( "INSERT INTO users(login, email, state, salt, crypted_password, first_name, last_name, creator_id) 
#                              VALUES('buyer', 'testing@avadatum.com', 'active', 
#                              '40b0fd7a34880ba8c9a7c7d25224ea92b250a2ea', 
#                              '2562555c2d7e15310dd9bb73d85c4a60256a0d2d',
#                              'Sample', 'Buyer', 1
#                              )")
#                              
#RolesUsers.create!(:user_id => 2, :role_id=>2)
#
#sql.execute("INSERT INTO company_users (company_id, user_id) VALUES(1, 2)")         
#sql.execute("INSERT INTO company_users (company_id, user_id) VALUES(2, 1)")
#sql.execute("INSERT INTO company_users (company_id, user_id) VALUES(2, 3)")
#sql.execute("INSERT INTO company_users (company_id, user_id) VALUES(2, 4)")
#sql.execute("INSERT INTO company_users (company_id, user_id) VALUES(2, 5)")
