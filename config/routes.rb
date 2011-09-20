Movies::Application.routes.draw do

  match 'about' => 'movies#about', :as => :about, :via => :get

  match 'movies/_dups' => 'movies#dups', :via => :get
  match 'movies/_netflix' => 'movies#without_netflix', :via => :get
  
  resources :movies, :only => [:show] do
    member do
      get :wikipedia
      put :change_plot_field
      put :link_to_netflix
      put :add_to_watch
      delete :remove_from_to_watch
      put :add_watched
      delete :remove_from_watched
    end
  end
  
  resources :users, :only => [:index]
  match 'compare/:users' => 'users#compare', :as => :compare, :via => :get, :users => /[^\/]+/
  
  match 'director/*director' => 'movies#index', :as => :director, :via => :get

  config = Movies::Application.config
  twitter = config.twitter_login.login_handler(:return_to => '/login/finalize')
  facebook = config.facebook_client.login_handler(:return_to => '/login/finalize')

  match 'login/instant' => 'sessions#instant_login', :as => :instant_login
  mount twitter => 'login/twitter', :as => :twitter_login
  mount facebook => 'login/facebook', :as => :facebook_login

  match 'login/finalize' => 'sessions#finalize'
  match 'logout' => 'sessions#logout', :as => :logout

  root :to => "movies#index"
  
  match 'following' => 'users#following', :as => :following, :via => :get
  match 'following/:id' => 'users#follow', :as => :follow, :via => :post
  match 'following/:id' => 'users#unfollow', :as => :unfollow, :via => :delete

  with_options :username => /[^\/]+/ do |user|
    user.match 'user/:username' => redirect('/%{username}')
    user.match 'user/:username/:more' => redirect('/%{username}/%{more}')

    user.match ':username' => 'users#show', :as => :watched, :via => :get
    user.match ':username/liked' => 'users#liked', :as => :liked, :via => :get
    user.match ':username/to-watch' => 'users#to_watch', :as => :to_watch, :via => :get
    user.match ':username/friends' => redirect('/following')
  end

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
