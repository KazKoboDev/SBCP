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

require 'celluloid/current'
require 'yaml'

require_relative 'rcon'

module SBCP
	class Parser
		include Celluloid

		def initialize
			Starbound::SESSION[:players] = {} if not Starbound::SESSION[:players].empty?
			@config = YAML.load_file(File.expand_path('../../../config.yml', __FILE__))
			@tmp = {}
		end

		def parse(line)
			if line.include? "Chat:"
				process_chat(line)
			else
				case line
				when /Starting UniverseServer with UUID:/
					@rcon = RCON.new
				when /Logged in account '(.+)' as player '(.+)' from address (.+)/
					id = Starbound::SESSION[:players].count + 1
					@tmp[id] = {
						:account => $1,
						:name => $2,
						:ip => $3
					}
				when /Client '(.+)' <(\d+)> \((.+)\) connected/
					if get_id_from_name($1)
						@rcon.execute("kick $#{$2} \"#{@config['duplicate_kick_msg']}\"")
						id = get_tempid_from_name($1)
						@tmp.delete(id)
					elsif id = get_tempid_from_name($1)
						Starbound::SESSION[:players][$2] = @tmp[id]
						@tmp.delete(id)
					end
				when /Client '(.+)' <(\d+)> \((.+)\) disconnected/
					Starbound::SESSION[:players].delete($2) unless Starbound::SESSION[:players][$2].nil?
				end
			end
		end

		def process_chat(line)
			# TODO
		end

		def get_tempid_from_name(name)
			@tmp.each_pair { |k,v|
				return k if v[:name] == name
			}
			return nil
		end

		def get_id_from_name(name)
			Starbound::SESSION[:players].each_pair { |k,v|
				return k if v[:name] == name
			}
			return nil
		end
	end
end