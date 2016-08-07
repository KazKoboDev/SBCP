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
require 'tempfile'

require_relative 'rcon'

module SBCP
	class Parser
		include Celluloid

		def initialize
			## START HACKY FIX
			require 'fileutils'
			FileUtils.mkdir_p($settings['backups']['storage']) if not Dir.exist?($settings['backups']['storage'])
			FileUtils.mkdir_p($settings['logging']['storage']) if not Dir.exist?($settings['logging']['storage'])
			## END HACKY FIX
			Starbound::SESSION[:players] = {} if not Starbound::SESSION[:players].empty?
			sb_config_raw = File.read("#{$settings['system']['starbound']}/storage/starbound_server.config")
			@sb_config_parsed = JSON.parse(sb_config_raw)
			@tmp = {}
			if $settings['logging']['mode'] == 1 then
				@log = Logger.new("#{$settings['logging']['storage']}/starbound.log", 'daily', $settings['logging']['lifetime'])
			elsif $settings['logging']['mode'] == 2 then
				stamp = "#{Time.now.strftime("%m-%d-%Y-%H-%M-%S")}-starbound"
				@log = Logger.new("#{$settings['logging']['storage']}/#{stamp}.log")
			end
			@log.formatter = proc { |severity, datetime, progname, msg| date_format = datetime.strftime("%H:%M:%S.%N")[0...-6]; "[#{date_format}] #{msg}" }
			@log.level = Logger::INFO
			@log.info("---------- SBCP is starting a new Starbound instance ----------\n")
		end

		def log(string)
			@log.info(string)
		end

		def parse(line)
			if line.include? "Chat:"
				parse_chat(line)
			else
				case line
				when /Starting UniverseServer with UUID:/
					if @sb_config_parsed["runRconServer"] == true
						$rcon = RCON.new(@sb_config_parsed["rconServerPort"], @sb_config_parsed["rconServerPassword"])
					else
						puts "RCON is not enabled. Please check your starbound.config file."
						puts "Some of SBCP's features may not work correctly without RCON."
					end
				when /Logged in account '(.+)' as player '(.+)' from address (.+)/
					id = Starbound::SESSION[:players].count + 1
					@tmp[id] = {
						:account => $1,
						:name => $2,
						:ip => $3,
						:nick => nil
					}
				when /Client '(.+)' <(\d+)> \((.+)\) connected/
					if get_id_from_name($1)
						unless $rcon.nil?
							$rcon.execute("kick $#{$2} \"#{$settings['system']['kick_message']}\"")
							id = get_tempid_from_name($1)
							@tmp.delete(id)
						else
							log('DUPLICATE NAME DETECTED BUT RCON DISABLED - CANNOT HANDLE')
						end
					elsif id = get_tempid_from_name($1)
						Starbound::SESSION[:players][$2] = @tmp[id]
						@tmp.delete(id)
					end
				when /Client '(.+)' <(\d+)> \((.+)\) disconnected/
					Starbound::SESSION[:players].delete($2) unless Starbound::SESSION[:players][$2].nil?
				end
				log(line)
			end
		end

		def close
			@log.close
		end

		private

			def parse_chat(line)
				case line
				when /<(.+)> \/nick (.+)/
					id = get_id_from_name($1)
					Starbound::SESSION[:players][id][:nick] = $2
				end
				log(line)
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