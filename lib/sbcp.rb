# SBCP - Starbound Server Management Solution for Linux Servers
# Copyright (C) 2016-2017 Kobold Software (Kazyyk)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'sinatra/base'
require 'sinatra/contrib'
require 'sinatra/flash'
require 'securerandom'
require 'fileutils'
require 'logger'
require 'json'
require_relative 'sbcp/daemon'

module SBCP
	class WebServer < Sinatra::Base
		register Sinatra::Contrib
		register Sinatra::Flash
		configure do
			set :environment, :development
			set :server, 'thin'
			set :threaded, true
			set :bind, '0.0.0.0'
			use Rack::Session::Cookie, 
				:key => 'rack.session',
				:path => '/',
				:expire_after => 3600
		end
		run! if app_file == $0

		def initialize
			# TODO
		end

		def start
			# TODO
		end

		def restart
			# TODO
		end

		def stop
			# TODO
		end
	end
end
