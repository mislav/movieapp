Movies::Application.routes.draw do |map|

  match 'movies/towatch/:id' => 'movies#add_to_watch', :as => :add_to_watch, :via => :put
  match 'movies/watched/:id' => 'movies#add_watched', :as => :add_watched, :via => :put
  
  resources :movies, :only => [:show]
  
  match 'user/:username' => 'movies#watched', :as => :watched, :via => :get
  match 'user/:username/liked' => 'movies#liked', :as => :liked, :via => :get
  match 'user/:username/to-watch' => 'movies#to_watch', :as => :to_watch, :via => :get
  
  match 'director/*director' => 'movies#index', :as => :director, :via => :get

  match 'login/instant' => 'sessions#instant_login', :as => :instant_login
  match 'login/facebook' => Movies::Application.config.facebook_client.login_handler

  match 'logout' => 'sessions#logout', :as => :logout

  root :to => "movies#index"

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
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
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
  #       get :recent, :on => :collection
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
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
