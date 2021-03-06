set :application, 'personal-site'
set :deploy_user, 'deployer'
set :scm, :git
set :repo_url, 'git@github.com:owenconnor/personal-site.git'
set :keep_releases, 5
set :linked_files, %w{config/database.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :tests, []
set :assets_roles, [:app]
set(:config_files, %w(
nginx.conf
database.example.yml
unicorn.rb
unicorn_init.sh
))
set(:executable_config_files, %w(
unicorn_init.sh
))
# files which need to be symlinked to other parts of the
# filesystem. For example nginx virtualhosts, log rotation
# init scripts etc. The full_app_name variable isn't
# available at this point so we use a custom template {{}}
# tag and then add it at run time.
set(:symlinks, [
    {
        source: "nginx.conf",
        link: "/etc/nginx/sites-enabled/default"
    },
    {
        source: "unicorn_init.sh",
        link: "/etc/init.d/unicorn_personal-site_prodcution"
    }
])
# this:
# http://www.capistranorb.com/documentation/getting-started/flow/
# is worth reading for a quick overview of what tasks are called
# and when for `cap stage deploy`
namespace :deploy do
# make sure we're deploying what we think we're deploying
  before :deploy, "deploy:check_revision"
# only allow a deploy with passing tests to deployed
  before :deploy, "deploy:run_tests"
# compile assets locally then rsync

  #after 'deploy:symlink:shared', 'deploy:compile_assets_locally'
  after :finishing, "deploy:cleanup"
# remove the default nginx configuration as it will tend
# to conflict with our configs.
  before "deploy:setup_config", "nginx:remove_default_vhost"
# reload nginx to it will pick up any modified vhosts from
# setup_config
  after "deploy:setup_config", "nginx:reload"
# Restart monit so it will pick up any monit configurations
# we've added
#  after "deploy:setup_config", "monit:restart"
# As of Capistrano 3.1, the `deploy:restart` task is not called
# automatically.
  after "deploy:publishing", "deploy:restart"
end