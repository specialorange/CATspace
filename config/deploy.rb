require 'mongrel_cluster/recipes'

set :application, "catspace.web-cat.org"
set :user, "deploy"
set :repository,  "http://subversion.assembla.com/svn/catspace"
set :deploy_to, "/home/deploy/catspace"

role :app, "catspace.web-cat.org"
role :web, "catspace.web-cat.org"
role :db,  "catspace.web-cat.org", :primary => true

# Cluster Config
set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"

#We're going to deploy via workstation; i.e., the server never accesses the SVN. The workstation does that, then zips up the file and send it via ssh to the remote server.
set :deploy_via, :copy

#Setting which user runs the mongrel instances
set :runner, deploy

task :after_update_code do
  %w{database.yml environment.rb facebooker.yml}.each do |config|
    run "ln -nfs #{shared_path}/config/#{config} #{release_path}/config/#{config}"
  end
end