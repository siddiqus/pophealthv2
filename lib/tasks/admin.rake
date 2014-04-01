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
  
#  3452667166
#  
#   task :providers, [:provider_json] do |t, args|
#    if !args.provider_json || args.provider_json.size==0
#      raise "please specify a value for provider_json"
#    end
#    
#    providers = JSON.parse(File.new(args.provider_json).read)
#    providers.each {|provider_hash| Provider.new(provider_hash).save}
#    puts "imported #{providers.count} providers"
#  end
#  
end
