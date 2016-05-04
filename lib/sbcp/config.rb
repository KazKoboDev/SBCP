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
require 'highline'

module SBCP
	class Config
		def initialize
			@cli = HighLine.new
		end

		def config_menu(menu)
			config_file = File.expand_path('../../../config.yml', __FILE__)
			config = YAML.load_file(config_file)
			case menu
			when :main
				answer = @cli.choose do |menu|
					menu.prompt = "Please select a menu option\n> "
					@cli.say("=== SBCP Configuration Menu ===")
					menu.choice(:General) { config_menu(:general) }
					menu.choice(:Backups) { config_menu(:backups) }
					menu.choice(:Logs) { config_menu(:logs) }
					menu.choice(:Restarts) { config_menu(:restarts) }
					menu.choice(:Exit) { puts 'Thank you for using SBCP.' }
				end
			when :general
				answer = @cli.choose do |menu|
					menu.prompt = "Please select a menu option\n> "
					@cli.say("=== SBCP General Settings ===")
					menu.choice('Starbound Directory') do
						@cli.choose do |sub_menu|
							sub_menu.prompt = "Please select a menu option\n> "
							@cli.say("=== SBCP Starbound Directory Setting ===")
							@cli.say('Your current starbound directory is:')
							@cli.say("\"#{config['starbound_directory']}\"")
							sub_menu.choice('Keep this directory') { @cli.say('Directory kept.'); config_menu(:general) }
							sub_menu.choice('Change this directory') do
								response = ''
								until Dir.exist?(response) && Dir.exist?(response + '/giraffe_storage') && File.writable?(response)
									response = @cli.ask("Please enter a new directory.\n> ")
									if not Dir.exist?(response) && Dir.exist?(response + '/giraffe_storage')
										@cli.say('Error - This dirctory does not exist or is not a valid starbound installation. Try again.')
									elsif not File.writable?(response)
										@cli.say('Error - This dirctory cannot be written to. Check permissions and try again.')
									end
								end
								config['starbound_directory'] = response
								File.write(config_file, config.to_yaml)
								@cli.say('Changes saved successfully.')
								config_menu(:general)
							end
						end
					end
					menu.choice('Back to Main Menu') { config_menu(:main) }
				end
			when :backups
				@cli.choose do |menu|
					menu.prompt = "Please select a menu option\n> "
					@cli.say("=== SBCP Backup Settings ===")
					menu.choice('Backup Directory') do
						@cli.choose do |sub_menu|
							sub_menu.prompt = "Please select a menu option\n> "
							@cli.say("=== SBCP Backup Directory Setting ===")
							@cli.say('Your current backup directory is:')
							@cli.say("\"#{config['backup_directory']}\"")
							sub_menu.choice('Keep this directory') { @cli.say('Directory kept.'); config_menu(:backups) }
							sub_menu.choice('Change this directory') do
								response = ''
								until Dir.exist?(response) && File.writable?(response)
									response = @cli.ask("Please enter a new directory.\n> ")
									if not Dir.exist?(response)
										@cli.say('Error - This dirctory does not exist. Try again.')
									elsif not File.writable?(response)
										@cli.say('Error - This dirctory cannot be written to. Check permissions and try again.')
									end
								end
								config['backup_directory'] = response
								File.write(config_file, config.to_yaml)
								@cli.say('Changes saved successfully.')
								config_menu(:backups)
							end
						end
					end
					menu.choice('Backup History') do
						@cli.choose do |sub_menu|
							sub_menu.prompt = "Please select a menu option\n> "
							@cli.say("=== SBCP Backup History Setting ===")
							@cli.say('Backups are currently set to remain archived for:')
							@cli.say(config['backup_history'].to_s + ' days')
							sub_menu.choice('Keep this setting') { @cli.say('Setting kept.'); config_menu(:backups) }
							sub_menu.choice('Change this setting') do
								until response > 0
									response = @cli.ask("Enter a new value in days (enter 0 to disable backups)\n> ", Integer)
									@cli.say('Value must be greater than zero.') if not response > 0
								end
								config['backup_history'] = response
								File.write(config_file, config.to_yaml)
								@cli.say('Changes saved successfully.')
								config_menu(:backups)
							end
						end
					end
					menu.choice('Backup Schedule') do
						@cli.choose do |sub_menu|
							sub_menu.prompt = "Please select a menu option\n> "
							@cli.say("=== SBCP Backup Schedule Setting ===")
							@cli.say('The backup schedule is currently set to:')
							config['backup_schedule'].is_a?(Integer) ? @cli.say('Every ' + config['backup_schedule'].to_s + ' hours') : @cli.say(config['backup_schedule'].to_s)
							sub_menu.choice('Keep this setting') { @cli.say('Setting kept.'); config_menu(:backups) }
							sub_menu.choice('Change this setting') do
								response = @cli.ask("Enter a new value in hours (enter 0 for on restart)\n> ", Integer) { |q| q.in = [0, 1, 2, 3, 4, 6, 8, 12, 24] }
								response = 'restart' if response == 0
								response = 'hourly' if response == 1
								response = 'daily' if response == 24
								config['backup_schedule'] = response
								File.write(config_file, config.to_yaml)
								@cli.say('Changes saved successfully.')
								config_menu(:backups)
							end
						end
					end
					menu.choice('Back to Main Menu') { config_menu(:main) }
				end
			when :logs
				@cli.choose do |menu|
					menu.prompt = "Please select a menu option\n> "
					@cli.say("=== SBCP Log Settings ===")
					menu.choice('Log Directory') do 
						@cli.choose do |sub_menu|
							sub_menu.prompt = "Please select a menu option\n> "
							@cli.say("=== SBCP Log Directory Setting ===")
							@cli.say('Your current logs directory is:')
							@cli.say("\"#{config['log_directory']}\"")
							sub_menu.choice('Keep this directory') { @cli.say('Directory kept.'); config_menu(:logs) }
							sub_menu.choice('Change this directory') do
								response = ''
								until Dir.exist?(response) && File.writable?(response)
									response = @cli.ask("Please enter a new directory.\n> ")
									if not Dir.exist?(response)
										@cli.say('Error - This dirctory does not exist. Try again.')
									elsif not File.writable?(response)
										@cli.say('Error - This dirctory cannot be written to. Check permissions and try again.')
									end
								end
								config['log_directory'] = response
								File.write(config_file, config.to_yaml)
								@cli.say('Changes saved successfully.')
								config_menu(:logs)
							end
						end
					end
					menu.choice('Log History') do
						@cli.choose do |sub_menu|
							sub_menu.prompt = "Please select a menu option\n> "
							@cli.say("=== SBCP Log History Setting ===")
							@cli.say('Logs are currently set to remain archived for:')
							@cli.say(config['log_history'].to_s + ' days')
							sub_menu.choice('Keep this setting') { @cli.say('Setting kept.'); config_menu(:logs) }
							sub_menu.choice('Change this setting') do
								until response >= 1
									response = @cli.ask("Enter a new value in days\n> ", Integer)
									@cli.say('Value must be greater than or equal to one.') if not response >= 1
								end
								config['log_history'] = response
								File.write(config_file, config.to_yaml)
								@cli.say('Changes saved successfully.')
								config_menu(:logs)
							end
						end
					end
					menu.choice('Log Style') do
						@cli.choose do |sub_menu|
							sub_menu.prompt = "Please select a menu option\n> "
							@cli.say("=== SBCP Log Style Setting ===")
							@cli.say('The log style is currently set to:')
							@cli.say(config['log_style'])
							sub_menu.choice('Keep this setting') { @cli.say('Setting kept.'); config_menu(:logs) }
							sub_menu.choice('Change this setting') do
								response = @cli.ask("Enter a style name (daily, restart))\n> ") { |q| q.in = ['daily', 'restart'] }
								config['log_style'] = response
								File.write(config_file, config.to_yaml)
								@cli.say('Changes saved successfully.')
								config_menu(:logs)
							end
						end
					end
					menu.choice('Back to Main Menu') { config_menu(:main) }
				end
			when :restarts
				@cli.choose do |menu|
					menu.prompt = "Please select a menu option\n> "
					@cli.say("=== SBCP Restart Settings ===")
					menu.choice('Restart Schedule') do
						@cli.choose do |sub_menu|
							sub_menu.prompt = "Please select a menu option\n> "
							@cli.say("=== SBCP Restart Schedule Setting ===")
							@cli.say('The restart schedule is currently set to:')
							config['restart_schedule'].is_a?(Integer) ? @cli.say('Every ' + config['restart_schedule'].to_s + ' hours') : @cli.say(config['restart_schedule'].to_s.capitalize)
							sub_menu.choice('Keep this setting') { @cli.say('Setting kept.'); config_menu(:restarts) }
							sub_menu.choice('Change this setting') do
								response = @cli.ask("Enter a new value in hours\n> ", Integer) { |q| q.in = [0, 1, 2, 3, 4, 6, 8, 12, 24] }
								response = 'disabled' if response == 0
								config['restart_schedule'] = response
								File.write(config_file, config.to_yaml)
								@cli.say('Changes saved successfully.')
								config_menu(:restarts)
							end
						end
					end
					menu.choice('Back to Main Menu') { config_menu(:main) }
				end
			end
		end
	end
end