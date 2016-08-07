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

require 'tempfile'
require 'celluloid/current'
require_relative 'starbound'
require_relative 'backup'
require_relative 'logs'

module SBCP
	class Daemon
		include Celluloid

		def start
			# Quick check for invalid config values.
			#raise('Please run setup first.') if $settings['starbound_directory'].nil?
			#raise('Error - Invalid starbound directory') if not Dir.exist?($settings['starbound_directory']) && Dir.exist?($settings['starbound_directory'] + '/storage')
			#raise('Error - Invalid backup directory') if not Dir.exist?($settings['backup_directory'])
			#raise('Error - Invalid backup schedule') if not ['hourly', 2, 3, 4, 6, 8, 12, 'daily', 'restart'].include? $settings['backup_schedule']
			#raise('Error - Invalid backup history') if not  $settings['backup_history'] == 'none' || $settings['backup_history'] >= 1
			#raise('Error - Invalid log directory') if not Dir.exist?($settings['log_directory'])
			#raise('Error - Invalid log history') if not $settings['log_history'].is_a?(Integer) && $settings['log_history'] >= 1
			#raise('Error - Invalid log style') if not ['daily', 'restart'].include? $settings['log_style']
			#raise('Error - Invalid restart schedule') if not ['none', 'hourly', 2, 3, 4, 6, 8, 12, 'daily'].include? $settings['restart_schedule']

			# Require any present plugins
			#plugins_directory = "#{$settings['system']['starbound']}/sbcp/plugins"
			#$LOAD_PATH.unshift(plugins_directory)
			#Dir[File.join(plugins_directory, '*.rb')].each {|file| require File.basename(file) }

			# We create an infinite loop so we can easily restart the server.
			loop do
				# Next we invoke the Starbound class to create an instance of the server.
				# This class will spawn a sub-process containing the server.
				Starbound.new.start

				# We wait for the server process to conclude before moving on.
				# This normally occurs after a shutdown, crash, or restart.
				# The daemon process will do nothing until the server closes.

				# Once the server has finished running, we'll want to age our logfiles.
				# We'll also take backups here if they've been set to behave that way.
				# There's probably a better way than sending config values as arguements, but...
				Logs.age($settings['logging']['storage'], $settings['logging']['storage']) if $settings['logging']['mode'] == 2 # Restart mode
				Backup.create_backup if $settings['backups']['frequency'] == 0 # Once per restart

				# Now we must determine if the server was closed intentionally.
				# If the server was shut down on purpose, we don't want to automatically restart it.
				# If the shutdown file exists, it was an intentional shutdown.
				# We break the loop which ends the method and closes the Daemon process.
				if not Dir.glob('/tmp/sb-shutdown*').empty?
					$daemon = nil
					break
				end

				# This delay is needed or some commands don't report back correctly
				sleep 5
			end
		end
  	end
end
