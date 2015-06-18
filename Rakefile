# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

$:.unshift './lib'
require 'xn/api'
require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

desc 'Query users from the API server and create login accounts'
task :create_users_from_api => [:"db:migrate", :environment] do
  XN::Api.create_users!
end

desc "create_users_from_api, now with less typing"
task users: :create_users_from_api
