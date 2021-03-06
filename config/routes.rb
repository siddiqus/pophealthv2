PopHealth::Application.routes.draw do

  resources :practices
	
  devise_for :users, :controllers => {:registrations => "registrations"}

	# added by ssiddiqui - enable sign out
  devise_for :users do 
  	get '/users/sign_out' => 'devise/sessions#destroy' 
  end
  
  get "admin/users"
  post "admin/promote"
  post "admin/demote"
  post "admin/approve"
  post "admin/disable"
  post "admin/update_npi"
  get "admin/patients"
  put "admin/upload_patients"
  delete "admin/remove_patients"
  delete "admin/remove_caches"
	delete "admin/remove_providers" #added for button, ssiddiqui
	delete "providers/remove"
	get "admin/user_profile"
	post "measures/export_report"
	post "measures/provider_report"
	post 'admin/remove_end_dates'
	get "admin/patient_list"
	get "measures/measure_table"
	get "admin/delete_provider"
	delete 'admin/remove_practice_patients'
	post 'admin/remove_practice_patients'
	post 'measures/export_patients'
	post "admin/set_user_practice"
	
	delete "measures/remove_selections" #added for button, ssiddiqui
	delete "logs/delete_logs"
	
	match 'admin/edit_teams/:id', :to => 'admin#edit_teams', :via => [ :get, :post ] # added from bstrezze
	match 'admin/delete_user/:id', :to => 'admin#delete_user', :via => [ :get, :post, :delete] # added by ssiddiqui

  get "logs/index"
  post "logs/index" #added for log filters
  
  match 'measures', :to => 'measures#index', :as => :dashboard, :via => :get
  match "measure/:id(/:sub_id)/providers", :to => "measures#providers", :via => :get
  match 'measure/:id(/:sub_id)', :to => 'measures#show', :as => :measure, :via => :get
  match 'measures/result/:id(/:sub_id)', :to => 'measures#result', :as => :measure_result, :via => :get
  match 'measures/definition/:id(/:sub_id)', :to => 'measures#definition', :as => :measure_definition, :via => :get
  match 'measures/patients/:id(/:sub_id)', :to => 'measures#patients', :as => :patients, :via => :get
  match 'measure/:id/select', :to => 'measures#select', :as => :select, :via => :post
  match 'measure/:id/remove', :to => 'measures#remove', :as => :remove, :via => :delete
  match 'measures/measure_patients/:id(/:sub_id)', :to=>'measures#measure_patients', :as => :measure_patients, :via=> :get
  match 'measures/measure_report', :to=>'measures#measure_report', :as => :measure_report, :via=> :get
  match 'measures/patient_list/:id(/:sub_id)', :to=>'measures#patient_list', :as => :patient_list, :via=> :get
  match 'measures/period', :to=>'measures#period', :as => :period, :via=> :post
  
  match 'provider/:npi', :to => "measures#index", :as => :provider_dashboard, :via => :get
  
  match 'records', :to => 'records#create', :via => :post
  
  match 'patients', :to => 'patients#index', :via => :get
  match 'patients/show/:id', :to => 'patients#show'
  match 'patients/toggle_excluded/:id/:measure_id(/:sub_id)', :to => 'patients#toggle_excluded', :via => :post
  
	root :to => 'measures#index'
  
  resources :measures do
    member { get :providers }
  end
  
  resources :providers do
    resources :patients do
      collection do
        get :manage
        put :update_all
      end
    end
   
    member do
      get :merge_list
      put :merge
    end
  end
  
  resources :teams
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
