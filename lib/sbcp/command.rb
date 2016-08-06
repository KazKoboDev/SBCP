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

require 'time'
require 'yaml'

require_relative 'rcon'


module SBCP
	module Command
		@@EMPHASIS = '^#ddd37b;'
		@@WARNING = '^red;'
		@@PLAIN = '^#aaaaaa;'
		@@PLANET = '^green;'

		def self.beacon(id, args)
			case args.split(' ', 2)[0].downcase()
			when 'off'
				character_model = $database.get_character(Starbound::SESSION[:players][id][:account], Starbound::SESSION[:players][id][:name])
				if not character_model.nil?
					character_model.incognito = true
					character_model.last_access = DateTime.now()
					character_model.save()
					$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@PLAIN}Beacon disabled.")
				end
			when 'on'
				character_model = $database.get_character(Starbound::SESSION[:players][id][:account], Starbound::SESSION[:players][id][:name])
				if not character_model.nil?
					character_model.incognito = false
					character_model.last_access = DateTime.now()
					character_model.save()
					$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@PLAIN}Beacon enabled.")
				end
			else
				$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@PLAIN}Bad arguments.")
			end				
		end

		def self.claim(id, args)
			location = get_location(id)
			if location.nil?
				$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@PLAIN}Cannot locate.")
			else
				case args.split(' ', 2)[0].downcase()
				when 'new'
					if $database.claim_world(Starbound::SESSION[:players][id][:account], location[:world_id], location[:is_ship] )
						$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@PLAIN}Claim estabished.")
					else
						$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}Location already claimed.")
					end
				when 'release'
					if $database.release_world(Starbound::SESSION[:players][id][:account], location[:world_id] )
						$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@PLAIN}Claim released.")
					else
						$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}Claim does not belong to you.")
					end
				when 'name'
					world_model = $database.get_world(location[:world_id])
					account_model = $database.get_account(Starbound::SESSION[:players][id][:account])
					if not world_model.nil? and not account_model.nil? and world_model.account == account_model
						world_model.name = args.split(' ', 2)[1]
						world_model.last_access = DateTime.now()
						world_model.save()
						$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@PLAIN}Claim name set.")
					else
						$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}Claim does not belong to you.")
					end	
				when 'description'
					world_model = $database.get_world(location[:world_id])
					account_model = $database.get_account(Starbound::SESSION[:players][id][:account])
					if not world_model.nil? and not account_model.nil? and world_model.account == account_model
						world_model.description = args.split(' ', 2)[1]
						world_model.last_access = DateTime.now()
						world_model.save()
						$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@PLAIN}Claim description set.")
					else
						$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}Claim does not belong to you.")
					end
				else
					$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}Bad arguments.")
				end
			end
		end

		def self.examine(id, args)
			target_id = get_id_from_nick(args)
			if not target_id.nil?
				character_model = $database.get_character(Starbound::SESSION[:players][target_id][:account], Starbound::SESSION[:players][target_id][:name])
				if not character_model.nil? and not character_model.description.nil? and character_model.description != ''
					$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@EMPHASIS}#{args}: #{@@PLAIN}#{character_model.description}")
				else
					$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@EMPHASIS}#{args}: #{@@PLAIN}No description set.")
				end
			end
		end

		def self.find(id, args)
			account_model = $database.get_account(Starbound::SESSION[:players][id][:account])
			if not account_model.nil? and account_model.permission_level >= Models::Account::MOD
				mod = true
			else
				mod = false
			end

			poll_locations()
			target_id = get_id_from_nick(args)
			if target_id.nil?
				$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}Target not found.")
			else
				character_model =$database.get_character(Starbound::SESSION[:players][target_id][:account], Starbound::SESSION[:players][target_id][:name])
				if mod or character_model.nil? or not character_model.incognito
					location = get_location(target_id)
					if not location.nil?
						world_model = $database.get_world(location[:world_id])
						if world_model.nil? or world_model.name.nil? or world_model.name == ''
							$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@EMPHASIS}#{args} #{@@PLAIN}is at an unknown location.")
						else
							$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@EMPHASIS}#{args} #{@@PLAIN}is at #{@@EMPHASIS}#{world_model.name}.")
						end
					end
				else
					$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}Target not found.")
				end
			end
		end

		def self.online(id, args)
			account_model = $database.get_account(Starbound::SESSION[:players][id][:account])
			if not account_model.nil? and account_model.permission_level >= Models::Account::MOD
				mod = true
			else
				mod = false
			end

			list_str = "#{@@PLAIN}Characters online: "
			first = true
			Starbound::SESSION[:players].each_pair do |k, v|
				character_model =$database.get_character(v[:account], v[:name])
				if mod or character_model.nil? or not character_model.incognito
					if first
						list_str = list_str + v[:nick]
						first = false
					else
						list_str = list_str + ", #{v[:nick]}"
					end
				end
			end
			$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{list_str}")
		end

		def self.ping(id, args)
			poll_locations()
			places = []
			#Collect list of all places that players are at
			Starbound::SESSION[:players].each_pair do |k_player, player|
				found = false
				places.each do |planet|
					if player[:location][:world_id] == planet[:location][:world_id]
						planet[:count] = planet[:count] + 1
						found = true
					end
				end

				if not found
					new_place = {
						:location => player[:location],
						:count => 1
					}
					places << new_place
				end
			end

			#Organize results into a human friendly list
			planet_str = ''
			ship_str = ''
			unknown_planet_count = 0
			unknown_ship_count = 0
			places.each do |planet|
				world_model = $database.get_world(planet[:location][:world_id])
				if world_model.nil? or world_model.name.nil? or world_model.name == ''
					if planet[:location][:is_ship]
						unknown_ship_count = unknown_ship_count + planet[:count]
					else
						unknown_planet_count = unknown_planet_count + planet[:count]
					end
				else
					if planet[:location][:is_ship]
						ship_str = ship_str + "\n#{@@EMPHASIS}#{world_model.name} #{@@PLAIN}- #{planet[:count]}"
					else
						planet_str = planet_str + "\n#{@@EMPHASIS}#{world_model.name} #{@@PLAIN}- #{planet[:count]}"
					end							
				end
			end
			
			out_str = ''
			if planet_str != '' or unknown_planet_count > 0
				out_str = out_str + "#{@@PLAIN}Active Planets:"
				if planet_str != ''
					out_str = out_str + "#{planet_str}"
				end
				if unknown_planet_count > 0
					out_str = out_str + "\n#{@@PLAIN}Unknown Planets - #{unknown_planet_count}"
				end
			end
			if ship_str != '' or unknown_ship_count > 0
				out_str = out_str + "#{@@PLAIN}Active Ships:"
				if ship_str != ''
					out_str = out_str + "#{ship_str}"
				end
				if unknown_ship_count > 0
					out_str = out_str +"\n#{@@PLAIN}Unknown Ships - #{unknown_ship_count}"
				end
			end

			$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{out_str}")
		end

		def self.planet_chat(id, args)
			poll_locations()
			send_to_location(Starbound::SESSION[:players][id][:location], "#{@@EMPHASIS}#{Starbound::SESSION[:players][id][:name]}: #{@@PLANET}#{args}")
		end

		def self.planet(id, args)
			location = get_location(id)
			if location.nil?
				$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}Cannot locate.")
			else
				world_model = $database.get_world(location[:world_id])
				if world_model.nil?
					name = nil
					description = nil
				else
					name = world_model.name
					description = world_model.description
				end

				if name.nil? or name == ''
					if location[:is_ship]
						name = "Unknown Ship"
					else
						name = "Unknown Planet"
					end
				end
				if description.nil? or description == ''
					description = "No Data Available."
				end							
				$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@EMPHASIS}#{name}: #{@@PLAIN}#{description}")
			end
		end

		def self.roll(id, args)
			poll_locations()
			success = false
			spec = args.split(' ', 2)[0]
			roll = spec.split('d')
			if roll.length() == 2
				count = roll[0].to_i()
				if roll[1] == 'f'
					low = -1
					high = 1
				else
					low = 1
					high = roll[1].to_i()
				end
				if count > 0 and count <= 10 and high > 0 and high <= 100
					out_str = ""
					sum = 0
					count.times do |i|
						result = rand(high - low + 1) + low
						sum = sum + result
						if i == 0
							out_str = result.to_s()
						else
							out_str = out_str + ", #{result}"
						end
					end
					if count > 1
						send_to_location(Starbound::SESSION[:players][id][:location], "#{@@EMPHASIS}#{Starbound::SESSION[:players][id][:name]} #{@@PLAIN}rolled a #{@@EMPHASIS}#{sum} #{@@PLAIN}(#{spec}: #{out_str}).")
					else
						send_to_location(Starbound::SESSION[:players][id][:location], "#{@@EMPHASIS}#{Starbound::SESSION[:players][id][:name]} #{@@PLAIN}rolled a #{@@EMPHASIS}#{sum} #{@@PLAIN}(#{spec}).")
					end
					success = true
				end
			end
			if not success
				$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}/roll requires the format <x>d<y> with a maximum value of 10 for x and 100 for y.\nExamples: 1d20 3d6 4df")
			end
		end

		def self.setexamine(id, args)
			character_model = $database.get_character(Starbound::SESSION[:players][id][:account], Starbound::SESSION[:players][id][:name])
			if not character_model.nil?
				character_model.description = args
				character_model.last_access = DateTime.now()
				character_model.save()
				$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@PLAIN}Description set.")
			else
				$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}Failed to set description.")
			end
		end

		def self.help(id, args)
			help_cmd = args.split(' ', 2)[0]
			if help_cmd == ''
				list = ''
				first = true
				CommandHandler.commands.each do |cmd|
					if first
						list = cmd.command
					else
						list = list + ", #{cmd.command}"
					end
				end
				$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@PLAIN}Server commands: #{list}.")
			else
				CommandHandler.commands.each do |cmd|
					if cmd.command == help_cmd
						$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@EMPHASIS}/#{cmd.command} #{@@PLAIN}#{cmd.help}")
						return
					end
				end
				$rcon.execute("say /w #{Starbound::SESSION[:players][id][:nick]} #{@@WARNING}No such command #{help_cmd}.")
			end
		end

		def self.poll_locations()
			now = Time.now()
			if Starbound::SESSION[:info][:last_location_poll].nil? or (now - Starbound::SESSION[:info][:last_location_poll]) >= 5
				Starbound::SESSION[:info][:last_location_poll] = now
				Starbound::SESSION[:players].each_pair do |k,v|
					v[:location] = get_location(k)
				end
			end
		end

		def self.get_location(id)
			reply = $rcon.execute("whereis #{Starbound::SESSION[:players][id][:nick]}")
			if not reply.nil?
				case reply
				when /.+ is (\w+?):(\S+)/
					return {
						:is_ship => ($1 == 'ClientShipWorld'),
						:world_id => $2,
					}
				end
			end
			return nil
		end

		def self.send_to_location(location, msg)
			Starbound::SESSION[:players].each_pair do |k,v|
				if not v[:location].nil?
					if v[:location][:world_id] == location[:world_id]
						$rcon.execute("say /w #{v[:nick]} #{msg}")
					end
				end
			end
		end

		def self.get_id_from_nick(nick)
			Starbound::SESSION[:players].each_pair do |k,v|
				return k if v[:nick] == nick
			end
			return nil
		end
	end

	class CommandHandler
		 @@commands = [
			{
				:command => '?',
				:handler => 'help',
				:help => "[command] - Displays list of commands or help text for a command."
			},
			{
				:command => 'beacon',
				:handler => 'beacon',
				:help => "[on] [off] - Shows/Hides this character in the /online and /find results."
	 		},
 			{
				:command => 'claim',
				:handler => 'claim',
				:help => "[new] [release] [name <name>] [description <description>] - Manages planet claims."
			},
			{
				:command => 'examine',
				:handler => 'examine',
				:help => "<target> - Dislays the target's description."
	 		},
			{
				:command => 'find',
				:handler => 'find',
				:help => "<target> - Displays the current location of the target character."
	 		},
			{
				:command => 'online',
				:handler => 'online',
				:help => "- Lists all characters currently online."
	 		},
	 		{
 				:command => 'p',
				:handler => 'planet_chat',
				:help => "- Sends a messsage to the current planet."
			},
			{
				:command => 'ping',
				:handler => 'ping',
				:help => "- Lists populations of all active locations."
	 		},
 			{
				:command => 'planet',
				:handler => 'planet',
				:help => "- Displays the current location's description."
			},
 			{
				:command => 'roll',
				:handler => 'roll',
				:help => "<xdy> - Rolls x dice with y sides. Maximum of 10 dice and 100 sides."
			},
	 		{
				:command => 'setexamine',
				:handler => 'setexamine',
				:help => "<description>- Sets this character's description."
 			},
		 ]
		 def self.commands
		 	return @@commands
		 end

		 def initialize
		 	#TODO Load text colors from yaml?
		 end

		 def execute(user_id, command, args)
	 		@@commands.each do |cmd|
	 			if command == cmd[:command]
	 				Command.send(cmd[:handler], user_id, args)
	 				return
	 			end
	 		end
		 end
	end
end
