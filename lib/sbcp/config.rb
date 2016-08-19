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

require 'json'
require 'highline'

module SBCP
	class Config
		def initialize
			@cli = HighLine.new
			@settings = JSON.parse(File.read(File.expand_path('../../../config.json', __FILE__)))
			@notice = nil
			system('clear')
		end

		def run(settings=nil)
			system('clear')
			@cli.say(@notice) unless @notice.nil?
			@notice = nil
			settings = @settings if settings.nil?
			@cli.choose do |menu| 
				menu.confirm = false
				menu.nil_on_handled = true
				menu.prompt = 'Choose an option'
				settings.each_pair do |key, value|
					menu.choice(key.capitalize) do
						if value.is_a?(Hash)
							@category = key
							run(value)
						else
							system('clear')
							@cli.say("#{key.capitalize} is currently set to: #{value}")
							if @cli.agree("Would you like to change this value? [y/n]")
								if value.is_a?(TrueClass)
									input = !value
								elsif value.is_a?(FalseClass)
									input = !value
								elsif value.is_a?(Integer)
									input = @cli.ask('Enter a new value:', Integer) # Answer must be an integer
								else # Assumes String
									input = @cli.ask('Enter a new value:')
								end
								@settings[@category][key] = input
								@notice = "VALUE UPDATED SUCCESSFULLY : #{key.capitalize} is now set to #{input}"
								run(@settings[@category])
							else
								run(@settings[@category])
							end
						end
					end
				end
				menu.choice('Main Menu') { @category = nil; run(@settings) } unless @category.nil?
				if @category.nil?
					menu.choice('Save and Exit') { File.open(File.expand_path('../../../config.json', __FILE__), 'w') { |f| f.write(JSON.pretty_generate(@settings)) } }
					menu.choice('Exit')
				end
			end
		end
	end
end