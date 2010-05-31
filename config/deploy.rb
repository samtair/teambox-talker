set :application, "talker"
set :repository,  "git@github.com:micho/talker.git"

set :deploy_to, "/mnt/apps/#{application}"
set :deploy_via, :remote_cache

set :runner, "admin"
set :user, "admin"
# set :port, 30000 # ssh port

set :scm, :git

set :volume_id, "vol-2589074c"

server = "ec2-174-129-84-220.compute-1.amazonaws.com"
role :app, server
role :web, server
role :db,  server, :primary => true

# TODO This gets automaticly included in default server list
# role :data, "ec2-174-129-133-121.compute-1.amazonaws.com"