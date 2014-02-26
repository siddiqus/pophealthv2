source 'http://rubygems.org'
#source 'http://gems.github.com'

gem 'rails', '3.2.14'

# added:
gem 'rack', '1.4.5'
gem 'macaddr', '1.6.1'

#gem 'quality-measure-engine', '~> 2.3.0'
#gem "health-data-standards", '~> 3.0.2'
#gem 'quality-measure-engine', '2.1.0', :git => 'https://github.com/pophealth/quality-measure-engine.git', :branch => 'develop'
#gem "health-data-standards", '3.2.7', :git => 'https://github.com/projectcypress/health-data-standards.git', :branch => 'develop'

gem 'quality-measure-engine', :path => "../quality-measure-engine"
gem "health-data-standards", :path => "../health-data-standards"


gem 'nokogiri', '1.6.0'#'~>1.5.5' #'1.5.10'
gem 'rubyzip', '0.9.9'

gem "will_paginate", '3.0.4'# we need to get rid of this, very inefficient with large data sets and mongoid
gem "kaminari", '0.14.1'

gem 'json', '1.8.0', :platforms => :jruby
# these are all tied to 1.3.1 because bson 1.4.1 was yanked.  To get bundler to be happy we need to force 1.3.1 to cause the downgrade

# added from bstrezze
gem 'bson', '1.9.2'
gem 'bson_ext', '1.9.2', :platforms => :mri

gem "mongoid", '3.1.4'

gem 'devise', '3.0.2'

gem 'foreman', '0.63.0'
gem "thin", '1.5.1'
gem 'formtastic', '2.2.1'
gem 'cancan', '1.6.10'
gem 'factory_girl', "2.6.3"
gem "rails-backbone", '0.9.10'
# Windows doesn't have syslog, so need a gem to log to EventLog instead
gem 'win32-eventlog', :platforms => [:mswin, :mingw]

# gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', '3.2.6'
  gem 'coffee-rails', '3.2.2'
  gem 'uglifier', '2.1.2'
  gem "bootstrap-sass", '2.3.2.1'
  gem 'jquery-datatables-rails', :git => 'https://github.com/rweng/jquery-datatables-rails'
  gem 'jquery-ui-rails', '4.0.4'
  gem 'jquery-rails', '2.1.4'
 # gem 'jquery-modal-rails', '0.0.3' #added by ssiddiqui
end

group :test, :develop do
  gem 'pry', '0.9.12.2'
  gem "unicorn", '4.6.3', :platforms => [:ruby, :jruby]
  gem 'turn', '0.9.6', :require => false
  gem 'cover_me', '1.2.0'
  gem 'minitest', '5.0.6'
  gem 'mocha', '0.14.0', :require => false
end

group :production do
  gem 'libv8', '3.11.8.17'
  gem 'therubyracer', '0.11.4', :platforms => [:ruby, :jruby] # 10.8 mountain lion compatibility
end

#gem 'jquery-rails', '2.1.4'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

# locking down versions 
#gem 'rake','10.1.1' 
#gem 'i18n','0.6.9' 
#gem 'multi_json','1.8.4' 
#gem 'activesupport','3.2.14' 
#gem 'builder','3.0.4' 
#gem 'activemodel','3.2.14' 
#gem 'erubis','2.7.0' 
#gem 'journey','1.0.4' 
##gem 'rack','1.4.5' 
#gem 'rack-cache','1.2' 
#gem 'rack-test','0.6.2' 
#gem 'hike','1.2.3' 
#gem 'tilt','1.4.1' 
#gem 'sprockets','2.2.2' 
#gem 'actionpack','3.2.14' 
#gem 'mime-types','1.25.1' 
#gem 'polyglot','0.3.4' 
#gem 'treetop','1.4.15' 
#gem 'mail','2.5.4' 
#gem 'actionmailer','3.2.14' 
#gem 'arel','3.0.3' 
#gem 'tzinfo','0.3.38' 
#gem 'activerecord','3.2.14' 
#gem 'activeresource','3.2.14' 
#gem 'ansi','1.4.3' 
#gem 'bcrypt-ruby','3.1.2' 
#gem 'sass','3.2.14' 
#gem 'bootstrap-sass','2.3.2.1' 
#gem 'bson','1.9.2' 
#gem 'bson_ext','1.9.2' 
#gem 'cancan','1.6.10' 
#gem 'coderay','1.0.9' 
#gem 'coffee-script-source','1.7.0' 
#gem 'execjs','2.0.2' 
#gem 'coffee-script','2.2.0' 
#gem 'rack-ssl','1.3.3' 
##gem 'json','1.8.1' 
#gem 'rdoc','3.12.2' 
#gem 'thor','0.18.1' 
#gem 'railties','3.2.14' 
#gem 'coffee-rails','3.2.2' 
#gem 'configatron','3.0.1' 
#gem 'hashie','2.0.5' 
#gem 'cover_me','1.2.0' 
#gem 'daemons','1.1.9' 
#gem 'delayed_job','3.0.5' 
#gem 'moped','1.5.2' 
#gem 'origin','1.1.0' 
#gem 'mongoid','3.1.4' 
#gem 'delayed_job_mongoid','2.0.0' 
#gem 'orm_adapter','0.5.0' 
#gem 'warden','1.2.3' 
#gem 'devise','3.0.2' 
#gem 'dotenv','0.9.0' 
#gem 'ejs','1.1.1' 
#gem 'eventmachine','1.0.3' 
#gem 'factory_girl','2.6.3' 
#gem 'foreman','0.63.0' 
#gem 'formtastic','2.2.1' 
#gem 'log4r','1.1.10' 
#gem 'memoist','0.9.1' 
#gem 'mini_portile','0.5.2' 
#gem 'nokogiri','1.6.0' 
#gem 'rest-client','1.6.7' 
#gem 'rubyzip','0.9.9' 
#gem 'systemu','2.5.2' 
#gem 'macaddr','1.6.1' 
#gem 'uuid','2.3.7' 
#gem 'jquery-rails','2.1.4' 
#gem 'sass-rails','3.2.6' 
#gem 'jquery-ui-rails','4.0.4' 
#gem 'kaminari','0.14.1' 
#gem 'kgio','2.9.2' 
#gem 'libv8','3.11.8.17' 
#gem 'metaclass','0.0.4' 
#gem 'method_source','0.8.2' 
#gem 'minitest','5.0.6' 
#gem 'mocha','0.14.0' 
#gem 'slop','3.4.7' 
#gem 'pry','0.9.12.2' 
#gem 'rubyXL','1.2.10' 
##gem 'rails','3.2.14' 
#gem 'rails-backbone','0.9.10' 
#gem 'raindrops','0.13.0' 
#gem 'ref','1.0.5' 
#gem 'therubyracer','0.11.4' 
#gem 'thin','1.5.1' 
#gem 'turn','0.9.6' 
#gem 'uglifier','2.1.2' 
#gem 'unicorn','4.6.3' 
#gem 'will_paginate','3.0.4' 

