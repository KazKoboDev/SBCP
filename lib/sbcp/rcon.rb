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

module SBCP
	class RCON
		def initialize(port, pass)
			original_verbosity = $VERBOSE
			$VERBOSE = nil
			SteamSocket.timeout = 100
			@rcon = SourceServer.new("127.0.0.1:#{port}")
			@rcon.rcon_auth(pass)
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