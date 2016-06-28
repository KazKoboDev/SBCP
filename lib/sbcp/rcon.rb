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

#Extend the Source Server to patch the rcon_exec method
#There appears to be an issue with SB's handling of multipacket responses
class StarboundRConServer < SourceServer
	def rcon_exec(command)
		raise RCONNoAuthError unless @rcon_authenticated

		@rcon_socket.send RCONExecRequest.new(@rcon_request_id, command)

		response_packet = @rcon_socket.reply

		if response_packet.nil? || response_packet.is_a?(RCONAuthResponse)
			@rcon_authenticated = false
			raise RCONNoAuthError
		end

		return response_packet.response
	end
end

module SBCP
	class RCON
		def initialize(port, pass)
			SteamSocket.timeout = 1000
			@port = port
			@pass = pass
			connect()
		end

		def connect
			tries = 0
			original_verbosity = $VERBOSE
			$VERBOSE = nil
			begin
				@rcon = StarboundRConServer.new("127.0.0.1:#{@port}")
				@rcon.rcon_auth(@pass)
				say("<%= color('RCon Connection Established.', :success) %>")
				$VERBOSE = original_verbosity
				return true
			rescue
				if tries < 3
					tries += 1
					retry
				else
					say("<%= color('RCon Connection failed.', :warning) %>")
				end
			end
			$VERBOSE = original_verbosity
			return false
		end

		def execute(command)
			# We swallow the time out exception here because Steam Condenser expects a reply
			# Starbound doesn't seem to always give a reply, even though the commands work
			reply = nil
			begin
				reply = @rcon.rcon_exec(command)
			rescue Exception
				say("<%= color('RCon Error: #{$!}', :warning) %>")
				say("<%= color('Attempting to reconnect.', :warning) %>")
				if connect()
					reply = @rcon.rcon_exec(command)
				end
			end
			return reply
		end
	end
end