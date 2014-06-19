root_dir = File.dirname(__FILE__)
app_file = File.join(root_dir, 'open311.rb')
require app_file

set :environment, ENV['RACK_ENV'].to_sym
set :root, root_dir
set :app_file, app_file
set :run, false
run Open311App