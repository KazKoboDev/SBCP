require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/flash'
require 'securerandom'
require 'fileutils'
require 'logger'
require 'yaml'

require 'sbcp/daemon'

module SBCP
  class Panel < Sinatra::Base
  	register Sinatra::Contrib
  	register Sinatra::Flash
  	config = YAML.load_file(File.expand_path('../../config.yml', __FILE__))
  	configure do
		set :environment, :development
		set :server, 'thin'
		set :threaded, true
		set :bind, '0.0.0.0'
		use Rack::Session::Cookie, 
			:key => 'rack.session',
			:path => '/',
			:expire_after => 3600 # In seconds
	end
	Process.daemon unless settings.environment == :development
	# Require any present plugins
	plugins_directory = "#{config['starbound_directory']}/sbcp/plugins"
	$LOAD_PATH.unshift(plugins_directory)
	Dir[File.join(plugins_directory, '*.rb')].each {|file| require File.basename(file) }
	run! if app_file == $0
  end
end
