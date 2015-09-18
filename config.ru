# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
require 'rack'
require 'rack/file'
require 'rack/cors'

app = Rack::Builder.app do
  use Rack::Cors do
    allow do
      origins '*'
      resource '*', :headers => :any,
        :methods => [:get, :post, :put, :patch, :delete, :options]
    end
  end
  run Rails.application
end

run app
