# SBCP - Starbound Server Management Solution for Linux Servers
# Copyright (C) 2016 Kazyyk

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

require 'steam-condenser'
require 'json'
require 'yaml'

module SBCP
	class RCON
		def initialize
			original_verbosity = $VERBOSE
			$VERBOSE = nil
			config = YAML.load_file(File.expand_path('../../../config.yml', __FILE__))
			sb_config_raw = File.read("#{config['starbound_directory']}/giraffe_storage/starbound.config")
			sb_config_parsed = JSON.parse(sb_config_raw)
			if sb_config_parsed["runRconServer"] == true
				@rcon = SourceServer.new("127.0.0.1:#{sb_config_parsed["rconServerPort"]}")
				@rcon.rcon_auth(sb_config_parsed["rconServerPassword"])
			else
				return("RCON is not enabled. Please check your starbound.config file.")
			end
			$VERBOSE = original_verbosity
		end

		def execute(command)
			# We swallow the time out exception here because Steam Condenser expects a reply
			# Starbound doesn't seem to always give a reply, even though the commands work
			begin
				@rcon.rcon_exec(command)
			rescue Exception
			end
		end
	end
end