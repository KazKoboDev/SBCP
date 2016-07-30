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

require 'yaml'
require 'fileutils'
require 'highline'

module SBCP
	class Setup
		def initialize
			@cli = HighLine.new
		end

		def run
			config_file = File.expand_path('../../../config.yml', __FILE__)
			config = YAML.load_file(config_file)
			response = @cli.agree('Are you sure you want to run the first-time setup? (y/n)')
			if response # If response is true, continue
				# First, we must attempt to locate where Starbound is installed.
				# This performs a recursive search on the OS for a folder named 'giraffe_storage'
				@cli.newline
				@cli.say('SBCP is starting up...')
				@cli.say('SBCP is attempting to automatically locate Starbound...')
				result = Dir.glob('/**/*/Starbound/storage')
				if result.empty?
					@cli.say('Unable to locate the Starbound installation directory.')
					a = ''
					until Dir.exist?(a) && Dir.exist?(a + '/storage') && File.writable?(a)
						a = @cli.ask("Please locate the directory manually and enter it below.\n> ")
						if not Dir.exist?(a) && Dir.exist?(a + '/storage')
							@cli.say('Error - This dirctory does not exist or is not a Starbound installation. Try again.')
						elsif not File.writable?(a)
							@cli.say('Error - This dirctory cannot be written to. Check permissions and try again.')
						end
					end
					config['starbound_directory'] = a
				else
					if result.count > 1
						@cli.say('SBCP encountered multiple possible directories.')
						answer = @cli.choose do |menu|
							menu.prompt = "Please select a directory\n> "
							result.each do |dir|
								dir = dir.split("/")[0..3].join("/") 
								menu.choice(dir) { abort('Error - This directory cannot be written to. Check permissions and try again.') if not File.writable?(dir); config['starbound_directory'] = dir }
							end
						end
						@cli.say("Starbound installation directory set to \"#{config['starbound_directory']}\"")
					else
						r = result.first.split("/storage").first
						@cli.say('SBCP successfully located the Starbound installation directory at:')
						@cli.say("\"#{r}\"")
						abort('Error - This directory cannot be written to. Check permissions and try again.') if not File.writable?(r)
						config['starbound_directory'] = r
					end
				end
				root = config['starbound_directory']

				@cli.newline
				@cli.say('Welcome to SBCP.')
				@cli.say('You can change any options later by running the config command. (config)')
				if @cli.agree("Would you like to skip setup and just use SBCP's default settings? (See README) (y/n)")
					# So we're running with the defaults. Let's get 'em setup!
					FileUtils.mkdir "#{root}/sbcp" if not Dir.exist?("#{root}/sbcp")
					FileUtils.mkdir "#{root}/sbcp/backups" if not Dir.exist?("#{root}/sbcp/backups")
					FileUtils.mkdir "#{root}/sbcp/logs" if not Dir.exist?("#{root}/sbcp/logs")
					config['backup_directory'] = "#{root}/sbcp/backups"
					config['backup_history'] = 90
					config['backup_schedule'] = "hourly"
					config['log_directory'] = "#{root}/sbcp/logs"
					config['log_history'] = 90
					config['log_style'] = "daily"
					config['duplicate_names'] = false
					config['duplicate_kick_msg'] = "Another player is currently online with your character's name."
					config['restart_schedule'] = 4
				else
					# Backup Settings
					@cli.newline
					@cli.say('--- Automatic Backups ---')
					if @cli.agree('Would you like to enable automatic backups?')
						@cli.newline
						@cli.say('--- Backup Directory Location ---')
						answer = ''
						until Dir.exist?(answer) && File.writable?(answer) || answer == 'default'
							answer = @cli.ask('Where would you like backups to be stored? Type "default" to use default.')
							if not Dir.exist?(answer)
								@cli.say('Error - This dirctory does not exist. Try again.') unless answer == 'default'
							elsif not File.writable?(answer)
								@cli.say('Error - This dirctory cannot be written to. Check permissions and try again.')
							end
						end
						if answer == 'default'
							config['backup_directory'] = "#{root}/sbcp/backups"
							FileUtils.mkdir_p "#{root}/sbcp/backups" if not Dir.exist?("#{root}/sbcp/backups")
						else
							config['backup_directory'] = answer
						end

						@cli.newline
						@cli.say('--- Backup Schedule ---')
						answer = @cli.ask('How frequently would you like to take backups (in hours)? Type 0 for on restart.', Integer) { |q| q.in = [0, 1, 2, 3, 4, 6, 8, 12, 24] }
						answer = 'restart' if answer == 0
						answer = 'hourly' if answer == 1
						answer = 'daily' if answer == 24
						config['backup_schedule'] = answer

						@cli.newline
						@cli.say('--- Backup History ---')
						answer = 0
						until answer > 0
							answer = @cli.ask('How long would like to keep the backups (in # of days)?', Integer)
							@cli.say('Value must be greater than zero.') if not answer > 0
						end
						config['backup_history'] = answer
					else
						config['backup_history'] = 'none'
					end
					File.write(config_file, config.to_yaml) # Periodic save

					# Log Settings
					@cli.newline
					@cli.say('--- Log Directory Location ---')
					answer = ''
					until Dir.exist?(answer) && File.writable?(answer) || answer == 'default'
						answer = @cli.ask('Where would you like log files to be stored? Type "default" to use default.')
						if not Dir.exist?(answer)
							@cli.say('Error - This dirctory does not exist. Try again.') unless answer == 'default'
						elsif not File.writable?(answer)
							@cli.say('Error - This dirctory cannot be written to. Check permissions and try again.')
						end
					end
					if answer == 'default'
						config['log_directory'] = "#{root}/sbcp/logs"
						FileUtils.mkdir_p "#{root}/sbcp/logs" if not Dir.exist?("#{root}/sbcp/logs")
					else
						config['log_directory'] = answer
					end

					@cli.newline
					@cli.say('--- Log History ---')
					answer = 0
					until answer > 0
						answer = @cli.ask('How long would you like log files to be kept (in days)?', Integer)
						@cli.say('Value must be greater than zero.') if not answer > 0
					end
					config['log_history'] = answer

					@cli.newline
					@cli.say('--- Log Style ---')
					@cli.say('There are two types of log styles available.')
					@cli.say('Daily: One log file per day. Bigger files, but less of them.')
					@cli.say('Restart: One log file per restart. Smaller files, but more of them.')
					answer = @cli.ask("What kind of log style do you prefer?\n> ") { |q| q.in = ['daily', 'restart'] }
					config['log_style'] = answer
					File.write(config_file, config.to_yaml)

					# Restart Settings
					@cli.newline
					@cli.say('--- Restart Schedule ---')
					answer = @cli.ask('How frequently would you like the Starbound server to restart (in hours)? Type 0 to disable.', Integer) { |q| q.in = [0, 1, 2, 3, 4, 6, 8, 12, 24] }
					answer = 'none' if response == 0
					answer = 'hourly' if response == 1
					answer = 'daily' if response == 24
					config['restart_schedule'] = answer
					File.write(config_file, config.to_yaml)
				end

				# Create the plugins directory and readme
				FileUtils.mkdir_p "#{root}/sbcp/plugins" if not Dir.exist?("#{root}/sbcp/plugins")
				File.write("#{root}/sbcp/plugins/README.txt", "You can override SBCP's behavior by writing your own Ruby plugins and placing them here.\nCheck the README on GitHub for more information.")

				# We save everything back to the config file at the end.
				File.write(config_file, config.to_yaml)

				@cli.newline
				@cli.say('SBCP has been configured successfully.')
				@cli.say('Type help for a list of commands.')
			end
		end
	end
end