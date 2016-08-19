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
require 'fileutils'
require 'highline'

require_relative 'config'

module SBCP
	class Setup

		def initialize
			@cli = HighLine.new
			@settings = Hash.new
			@settings['restarts'] = Hash.new
			@settings['backups'] = Hash.new
			@settings['logging'] = Hash.new
			@settings['system'] = Hash.new
		end

		def run
			@cli.say('Hello! Thank you for installing SBCP. It is time to perform first time setup.')
			@cli.say('Before we begin, SBCP will attempt to determine Starbound\'s install location.')
			@cli.say('Searching for Starbound install directory...')
			locate_starbound
			@cli.say('Press ENTER when you are ready to continue.')
			gets
			system('clear')
			if @cli.agree('Would you prefer to run setup in Advanced mode? [y/n - not reccomended]') { |q| q.confirm = true }
				# setup_mode = :ADVANCED
				@cli.say('You\'ve chosen to run in Advanced mode. You can switch modes by restarting the program. (Press CTRL + C to interrupt)')
				@cli.say('We will prompt you to directly set the configurable parameters for SBCP. Some light input validation is in effect.')
				@cli.say('Should the configuration ever become corrupt, check SBCP\'s help menu on how to reset it.')
				@cli.say('Press ENTER when you are ready to continue.')
				gets
				system('clear')
				advanced_setup
			else
				# setup_mode = :NORMAL
				@cli.say('You\'ve chosen NOT to run in Advanced mode.')
				@cli.say('We will ask you a series of questions to determine how to best configure SBCP to match your needs.')
				@cli.say('Should the configuration ever become corrupt, check SBCP\'s help menu on how to reset it.')
				@cli.say('Press ENTER when you are ready to continue.')
				gets
				system('clear')
				simple_setup
			end
		end

		def locate_starbound
			result = Dir.glob('/**/*/Starbound/storage')
			if result.empty?
				# Ask the user to manually provide a directory 
				# Check and make sure it contains the starbound server executable
				# It's also important that it's writable by the current user
				@cli.say('Unable to locate the Starbound install directory.')
				input = ''
				until File.exist?(input + '/linux/starbound_server') && File.writable?(input)
					input = @cli.ask("Please locate the directory manually and enter it below.\n> ")
					if not File.exist?(input + '/linux/starbound_server')
						@cli.say('This directory does not exist or is not a Starbound installation. Please try again.')
					elsif not File.writable?(input)
						@cli.say('This directory cannot be written to. Please check permissions and try again.')
					end
				end
				@settings['system']['starbound'] = input
			else
				if result.count > 1
					@cli.say('SBCP encountered multiple possible directories.')
					@cli.choose do |menu|
						menu.prompt = "Please select a directory\n> "
						result.each do |dir|
							dir = dir.split("/")[0..3].join("/") 
							menu.choice(dir) { abort('This directory cannot be written to. Please check permissions and try again.') if not File.writable?(dir); @settings['system']['starbound'] = dir }
						end
					end
					@cli.say("Starbound installation directory set to \"#{@settings['system']['starbound']}\"")
				else
					r = result.first.split("/storage").first
					@cli.say('SBCP successfully located the Starbound installation directory at:')
					@cli.say("\"#{r}\"")
					abort('This directory cannot be written to. Please check permissions and try again.') if not File.writable?(r)
					@settings['system']['starbound'] = r
				end
			end
		end

		def advanced_setup
			# Restarts
			@settings['restarts']['enabled'] = true
			@settings['restarts']['cron'] = true
			@settings['restarts']['frequency'] = 240
			# Backups
			@settings['backups']['enabled'] = true
			@settings['backups']['cron'] = true
			@settings['backups']['frequency'] = 60
			@settings['backups']['lifetime'] = 720
			@settings['backups']['storage'] = @settings['system']['starbound'] + '/backups'
			# Logging
			@settings['logging']['enabled'] = true
			@settings['logging']['storage'] = @settings['system']['starbound'] + '/logs'
			@settings['logging']['lifetime'] = 2160
			@settings['logging']['mode'] = 1
			# System
			@settings['system']['kick_message'] = "Another player is currently online with that character name."
			@settings['system']['duplicate_names'] = false
			save_settings
			Config.new.run # lib/config.rb
		end

		def simple_setup
			# SETUP: RESTARTS
			if @cli.agree('Would you like the server to periodically restart on it\'s own?') { |q| q.confirm = true }
				@settings['restarts']['enabled'] = true
				@settings['restarts']['cron'] = true
				system('clear')
				@cli.choose do |menu| 
					menu.confirm = true
					menu.nil_on_handled = true
					menu.prompt = 'How frequently would you like the server to restart?'
					# Selections are in hours, but values are stored in minutes (ex: value * 60)
					menu.choice('Every hour')			{ @settings['restarts']['frequency'] = 60	}
					menu.choice('Every two hours')		{ @settings['restarts']['frequency'] = 120	}
					menu.choice('Every four hours')		{ @settings['restarts']['frequency'] = 240	} # default
					menu.choice('Every six hours')		{ @settings['restarts']['frequency'] = 360	}
					menu.choice('Every eight hours')	{ @settings['restarts']['frequency'] = 480	}
					menu.choice('Every twelve hours')	{ @settings['restarts']['frequency'] = 720	}
					menu.choice('Once per day')			{ @settings['restarts']['frequency'] = 1440	}
				end
			else
				@settings['restarts']['enabled'] = false
				@settings['restarts']['cron'] = true
				@settings['restarts']['frequency'] = 240
			end
			system('clear')
			# SETUP: BACKUPS
			if @cli.agree('Would you like periodic server backups?') { |q| q.confirm = true }
				@settings['backups']['enabled'] = true
				@settings['backups']['cron'] = true
				system('clear')
				@cli.choose do |menu| 
					menu.confirm = true
					menu.nil_on_handled = true
					menu.prompt = 'How frequently would you like server backups to be taken?'
					menu.choice('Every hour')			{ @settings['backups']['frequency'] = 60	} # default
					menu.choice('Every two hours')		{ @settings['backups']['frequency'] = 120	}
					menu.choice('Every four hours')		{ @settings['backups']['frequency'] = 240	}
					menu.choice('Every six hours')		{ @settings['backups']['frequency'] = 360	}
					menu.choice('Every eight hours')	{ @settings['backups']['frequency'] = 480	}
					menu.choice('Every twelve hours')	{ @settings['backups']['frequency'] = 720	}
					menu.choice('Once per day')			{ @settings['backups']['frequency'] = 1440	}
					menu.choice('Once per restart')		{ @settings['backups']['frequency'] = 0		}
				end
				system('clear')
				@cli.choose do |menu| 
					menu.confirm = true
					menu.nil_on_handled = true
					menu.prompt = 'How long would you like to keep the backups for?'
					# Selections are in days, but values are stored in hours (ex: value * 24)
					menu.choice('7 days')			{ @settings['backups']['lifetime'] = 168	}
					menu.choice('14 days')			{ @settings['backups']['lifetime'] = 336	}
					menu.choice('30 days')			{ @settings['backups']['lifetime'] = 720	} # default
					menu.choice('60 days')			{ @settings['backups']['lifetime'] = 1440	}
					menu.choice('90 days')			{ @settings['backups']['lifetime'] = 2160	}
					menu.choice('180 days')			{ @settings['backups']['lifetime'] = 4320	}
					menu.choice('365 days')			{ @settings['backups']['lifetime'] = 8760	}
					menu.choice('Indefinitely')		{ @settings['backups']['lifetime'] = 0		}
				end
				system('clear')
				@settings['backups']['storage'] = @settings['system']['starbound'] + '/backups'
				@cli.say("Starbound backups will be stored in \"#{@settings['system']['starbound']}/backups\"")
				@cli.say('You can change this using the configuration utility at any time. See help for more information.')
				@cli.say('Press ENTER when you are ready to continue.')
				gets
			else
				@settings['backups']['enabled'] = false
				@settings['backups']['cron'] = true
				@settings['backups']['frequency'] = 60
				@settings['backups']['lifetime'] = 720
				@settings['backups']['storage'] = @settings['system']['starbound'] + '/backups'
			end
			system('clear')
			# SETUP: LOGGING
			if @cli.agree('Would you like to enable logging? [Recommended]') { |q| q.confirm = true }
				@settings['logging']['enabled'] = true
				system('clear')
				@cli.choose do |menu| 
					menu.confirm = true
					menu.nil_on_handled = true
					menu.prompt = 'How long would you like to keep logging data for?'
					# Selections are in days, but values are stored in hours (ex: value * 24)
					menu.choice('7 days')			{ @settings['logging']['lifetime'] = 168	}
					menu.choice('14 days')			{ @settings['logging']['lifetime'] = 336	}
					menu.choice('30 days')			{ @settings['logging']['lifetime'] = 720	}
					menu.choice('60 days')			{ @settings['logging']['lifetime'] = 1440	}
					menu.choice('90 days')			{ @settings['logging']['lifetime'] = 2160	} # default
					menu.choice('180 days')			{ @settings['logging']['lifetime'] = 4320	}
					menu.choice('365 days')			{ @settings['logging']['lifetime'] = 8760	}
					menu.choice('Indefinitely')		{ @settings['logging']['lifetime'] = 0		}
				end
				system('clear')
				@settings['logging']['storage'] = @settings['system']['starbound'] + '/logs'
				@cli.say("Starbound logs will be stored in \"#{@settings['system']['starbound']}/logs\"")
				@cli.say('You can change this using the configuration editor utility at any time. See help for more information.')
				@cli.say('Press ENTER when you are ready to continue.')
				gets
				# Mode 1 = daily, Mode 2 = restart
				# Default to mode 1
				@settings['logging']['mode'] = 1
			else
				@settings['logging']['enabled'] = false
				@settings['logging']['storage'] = @settings['system']['starbound'] + '/logs'
				@settings['logging']['lifetime'] = 2160
				@settings['logging']['mode'] = 1
			end
			# SETUP: SYSTEM
			@settings['system']['kick_message'] = "Another player is currently online with that character name."
			@settings['system']['duplicate_names'] = false
			save_settings
		end

		def save_settings
			old_config = File.expand_path('../../../config.yml', __FILE__)
			File.delete(old_config) if File.exist?(old_config)
			config = File.open(File.expand_path('../../../config.json', __FILE__), 'w')
			config.write(JSON.pretty_generate(@settings))
			config.close
		end
	end
end