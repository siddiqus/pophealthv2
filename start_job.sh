sudo start delayed_worker
bundle exec rake jobs:work RAILS_ENV=development
