require 'rvm/capistrano'
require 'bundler/capistrano'

#general info
set :user, 'open311'
set :application, "open311"
set :domain, 'open311.xoverto.com'
set :applicationdir, "/home/#{user}/#{application}"
set :scm, 'git'
set :repository,  "git@github.com:andrewsage/open311server.git"
set :branch, 'master'
set :git_shallow_clone, 1
set :scm_verbose, true
set :deploy_via, :remote_cache
set :use_sudo, false

#RVM and bundler settings
set :bundle_cmd, "/home/#{user}/.rvm/gems/ruby-2.1.2@global/bin/bundle"
set :bundle_dir, "/home/#{user}/.rvm/gems/ruby-2.1.2/gems"
set :rvm_ruby_string, '2.1.2'
set :rack_env, :production
set :rvm_type, :user

role :web, domain                          # Your HTTP server, Apache/etc
role :app, domain                          # This may be the same as your `Web` server
role :db,  domain, :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"
#deploy config
set :deploy_to, applicationdir
set :deploy_via, :export

#addition settings. mostly ssh
ssh_options[:forward_agent] = true
#ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")]
#ssh_options[:paranoid] = false
default_run_options[:pty] = true
# if you want to clean up old releases on each deploy uncomment this:
after "deploy:restart", "deploy:cleanup"


# After an initial (cold) deploy, symlink the app and restart nginx
after "deploy:cold" do
  admin.nginx_restart
end

# As this isn't a rails app, we don't start and stop the app invidually
namespace :deploy do
  desc "Not starting as we're running passenger."
  task :start do
  end
end