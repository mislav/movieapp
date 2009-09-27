# set :application, "movie"
set :remote, "online"
# set :repository,  "set your repository location here"
# set :deploy_to, "/var/www/#{application}"
# set :use_sudo, false

server remote_host, :app, :web, :db, :primary => true
# role :web, "your web-server here"
