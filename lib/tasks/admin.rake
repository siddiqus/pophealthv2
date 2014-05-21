require ::File.expand_path('../../../config/environment',  __FILE__)

namespace :admin do
  task :create_admin_account do
    admin_account = User.new(
                     :first_name =>     "Administrator",
                     :last_name =>      "Administrator",
                     :username =>       "pophealth",
                     :password =>       "pophealth",
                     :email =>          "cipci@providemycompanyname.com",
                     :agree_license =>  true,
                     :admin =>          true,
                     :approved =>       true)
    admin_account.grant_admin                
    admin_account.save!
  end
  
  task :create_user, [:user, :pass, :practice] do |t, args|
  	user = args.user
  	pass = args.pass
  	practice = args.practice
    user_account = User.new(
                     :first_name =>     "Administrator",
                     :last_name =>      "Administrator",
                     :username =>       user,
                     :password =>       pass,
                     :email =>          "provideadmin@providemycompanyname.com",
                     :agree_license =>  true,
                     :staff_role =>			true,
                     :approved =>       true,
                     :practice => practice)
		                
    admin_account.save!
  end
  
 	task :check_npi, [:npi] do |t, args|
    if !args.npi || args.npi.size==0
      raise "please specify a value for provider_json"
    end		
		if (Provider.valid_npi?("#{args.npi}"))		   
	    puts "NPI valid"
	  else
	  	puts "NPI invalid"
	  end	  
  end
  

end
