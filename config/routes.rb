Movies::Application.routes.draw do

  get 'about' => 'movies#about', :as => :about
  get 'privacy' => 'movies#privacy', :as => :privacy_policy

  get 'movies/_dups' => 'movies#dups'
  get 'movies/_netflix' => 'movies#without_netflix'
  
  resources :movies, :only => [:show, :edit, :update] do
    collection do
      get :opensearch
    end
    member do
      get :wikipedia
      get :raw
      get :pick_poster
      put :broken_poster
      put :change_plot_field
      put :add_to_watch
      delete :remove_from_to_watch
      put :add_watched
      delete :remove_from_watched
      put :ignore_recommendation
    end
  end

  get 'users/watched.:format' => 'users#watched_index'
  resources :users, :only => [:index]
  get 'compare/:users' => 'users#compare', :as => :compare, :users => /[^\/]+/
  
  get 'director/*director' => 'movies#index', :as => :director

  get   'login/instant'           => 'sessions#instant_login', :as => :instant_login
  match 'auth/failure'            => 'sessions#auth_failure', :via => [:get, :post]
  match 'auth/:provider/callback' => 'sessions#finalize', :via => [:get, :post]
  get   'login/connect'           => 'sessions#connect', :as => :connect
  get   'login/facebook'          => 'sessions#legacy_facebook', :as => :facebook_login
  get   'logout'                  => 'sessions#logout', :as => :logout

  root :to => "movies#index"
  
  get    'following' => 'users#following', :as => :following
  post   'following/:id' => 'users#follow', :as => :follow
  delete 'following/:id' => 'users#unfollow', :as => :unfollow

  get 'timeline' => 'users#timeline', :as => :timeline

  with_options :username => /[^\/]+/ do |user|
    user.get ':username' => 'users#show', :as => :watched, :via => :get
    user.get ':username/liked' => 'users#liked', :as => :liked, :via => :get
    user.get ':username/to-watch' => 'users#to_watch', :as => :to_watch, :via => :get
    user.get ':username/friends' => redirect('/following')
    user.get ':username/recommendations' => 'users#recommendations', :as => :movie_recommendations
  end

end
