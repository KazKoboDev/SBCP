require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/flash'
require 'securerandom'
require 'fileutils'
require 'logger'
require 'pry'

require 'sbcp/daemon'

module SBCP
  class Panel < Sinatra::Base
  	register Sinatra::Contrib
  	register Sinatra::Flash
  	config_file 'config.yml'
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
	run! if app_file == $0
  end
end
