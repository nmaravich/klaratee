# create! a new user via ./script/console using these commands:
# salt = Digest::SHA1.hexdigest("#{Time.now.to_s}")
# User.encrypt('ss_adm!n', salt)

# Using a sql insert here because the user model is protected using attr_accessible.
# That prevents you from being able to modify some of the fields from here.
sql = ActiveRecord::Base.connection();

# decrypted password is:  ss_adm!n
sql.execute( "INSERT INTO users(id, login, email, state, salt, crypted_password, first_name, last_name, creator_id) 
                              VALUES(1, 'klaratee', 'admin@avadatum.com', 'active', 
                              '06fa6733ed54e07efdd088da9236158a1a3601d7',
                              '11a7731d41178b1ea6b5747e57984d242eee7193',
                              'Klara', 'Tee', 1
                              )")

## Companies ( connected to the same db since its dev )
#Company.create!(:id => 1, :name => "Avadatum", :db_config => "klaratee_development_default" )

## Roles
Role.create!(:id => 1, :name => "Admin",   :description => "Klaratee Admin")
Role.create!(:id => 2, :name => "Buyer",   :description => "Klaratee Buyer")
Role.create!(:id => 3, :name => "Supplier",:description => "Klaratee Supplier")

RolesUsers.create!(:user_id => 1, :role_id=>1)
