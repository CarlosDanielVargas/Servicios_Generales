# config valid for current version and patch releases of Capistrano
lock "~> 3.18.0"

set :application, "servicios_generales"
set :repo_url, "git@github.com:CarlosDanielVargas/Servicios_Generales.git"

# Deploy to the user's home directory
set :deploy_to, "/home/deploy/#{fetch :application}"

append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system', 'public/uploads'

# Only keep the last 5 releases to save disk space
set :keep_releases, 5

# Change the default branch from :master to :deploy
set :branch, :deploy

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# Bundle
namespace :bundle do
  desc "Install the current Bundler environment."
  task :install => [:default_config] do
    on release_roles(fetch(:bundle_roles)) do
      args = []
      args << "--jobs #{fetch(:bundle_jobs)}" if fetch(:bundle_jobs)
      args << "--path #{fetch(:bundle_path)}" if fetch(:bundle_path)
      args << "--binstubs #{fetch(:bundle_binstubs)}" if fetch(:bundle_binstubs)
      args << "--without #{fetch(:bundle_without)}" if fetch(:bundle_without)
      args << "--gemfile #{fetch(:bundle_gemfile)}" if fetch(:bundle_gemfile)
      args << "--deployment" if fetch(:bundle_deployment)
      args << "--quiet" if fetch(:bundle_quiet)
      args << "--retry #{fetch(:bundle_retry)}" if fetch(:bundle_retry)
      args << "--clean" if fetch(:bundle_clean)
      args << "--trust-policy" if fetch(:bundle_trust_policy)
      args << "--frozen" if fetch(:bundle_frozen)
      args << "--system" if fetch(:bundle_system)
      args << "--shebang" << fetch(:bundle_shebang) if fetch(:bundle_shebang)
      args << "--local" if fetch(:bundle_local)
      args << "--standalone" if fetch(:bundle_standalone)
      args << "--no-cache" if fetch(:bundle_no_cache)
      args << "--no-prune" if fetch(:bundle_no_prune)
      args << "--no-exe" if fetch(:bundle_no_exe)
      args << "--gemfile #{fetch(:bundle_gemfile)}" if fetch(:bundle_gemfile)
      args << "--with-pg-config=#{fetch(:pg_config)}"
      args << "--with-pg-include=#{fetch(:pg_include)}"
      args << "--with-pg-lib=#{fetch(:pg_lib)}"
      execute :bundle, :install, *args
    end
  end
end
