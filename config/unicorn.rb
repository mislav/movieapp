if "production" == ENV['RACK_ENV']
  worker_processes 4
  timeout 30
else
  worker_processes 1
  timeout 60
end
