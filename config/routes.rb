Movies::Application.routes.draw do

  match 'about' => 'movies#about', :as => :about, :via => :get

  match 'movies/_dups' => 'movies#dups', :via => :get
  match 'movies/_netflix' => 'movies#without_netflix', :via => :get
  
  resources :movies, :only => [:show, :edit, :update] do
    collection do
      get :opensearch
    end
    member do
      get :wikipedia
      get :raw
      get :pick_poster
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

  match 'login/instant'           => 'sessions#instant_login', :as => :instant_login
  get   'auth/failure'            => 'sessions#auth_failure'
  match 'auth/:provider/callback' => 'sessions#finalize'
  match 'login/connect'           => 'sessions#connect', :as => :connect
  match 'logout'                  => 'sessions#logout', :as => :logout

  root :to => "movies#index"
  
  match 'following' => 'users#following', :as => :following, :via => :get
  match 'following/:id' => 'users#follow', :as => :follow, :via => :post
  match 'following/:id' => 'users#unfollow', :as => :unfollow, :via => :delete

  match 'timeline' => 'users#timeline', :as => :timeline, :via => :get

  with_options :username => /[^\/]+/ do |user|
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
