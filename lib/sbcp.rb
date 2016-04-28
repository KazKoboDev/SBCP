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
		# First thing's first, we create a file containing the current process pid.
		# This is used later when we need to grace or force quit SBCP.
		# Note to self: Don't forget to close and unlink
		pid_file = Tempfile.new('sbcp_panel-pid')
		pid_file.write(Process.pid.to_s)
		# Require any present plugins
		plugins_directory = "#{config['starbound_directory']}/sbcp/plugins"
		$LOAD_PATH.unshift(plugins_directory)
		Dir[File.join(plugins_directory, '*.rb')].each {|file| require File.basename(file) }
		run! if app_file == $0
	end
end
