if "production" == ENV["RAILS_ENV"]
  listen "/tmp/unicorn.movieapp.sock", :backlog => 64
  pid "tmp/pids/unicorn.pid"
  worker_processes 2
  timeout 30
else
  listen 3000 # File.expand_path("../../tmp/unicorn.sock", __FILE__)
  worker_processes 2
  timeout 60
end
