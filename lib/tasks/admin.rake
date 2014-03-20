require ::File.expand_path('../../../config/environment',  __FILE__)

namespace :admin do
  task :create_admin_account do
    admin_account = User.new(
                     :first_name =>     "Administrator",
                     :last_name =>      "Administrator",
                     :username =>       "pophealth",
                     :password =>       "pophealth",
                     :email =>          "provideadmin@providemycompanyname.com",
                     :agree_license =>  true,
                     :admin =>          true,
                     :approved =>       true)
    admin_account.grant_admin                
    admin_account.save!
  end
  
  task :create_user, [:user, :pass, :practice] => :environment do |t, args|
#  	args = params
  	user = args[:user]
  	pass = args[:pass]
  	fqhc = args[:practice]
    user_account = User.new(
                     :first_name =>     "Administrator",
                     :last_name =>      "Administrator",
                     :username =>       user,
                     :password =>       pass,
                     :email =>          "provideadmin@providemycompanyname.com",
                     :agree_license =>  true,
                     :admin =>          true,
                     :approved =>       true,
                     :fqhc => fqhc)
		                
    admin_account.save!
  end
  
  
  
end
