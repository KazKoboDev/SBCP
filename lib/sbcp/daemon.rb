require 'yaml'
require 'logger'
require 'tempfile'
require 'rufus-scheduler'
require 'celluloid/current'
require_relative 'starbound'
require_relative 'backup'
require_relative 'parser'
require_relative 'logs'
module SBCP
	class Daemon
		def initialize
			# Loads the config into an instance variable for use in GUI mode
			@config = YAML.load_file(File.expand_path('../../../config.yml', __FILE__))
		end

		def self.run
			# This method is used when starting SBCP from the sbcp executable.
			# It's primary purpose is to enable running SBCP in CLI mode.
			# The Sinatra web server is completely bypassed in this case.

			# Check to see if the daemon is already running.
			# This can happen after a server shut down and it's taking a backup or handling log files.
			abort("SBCP is currently running. If you recently shut down Starbound, please allow a few minutes.\nSBCP is likely handling backup or log file operations. Interruption could lead to data loss.") if not Dir.glob('/tmp/sbcp_daemon-pid*').empty?

			# Create a file containing the pid of this process so it can be aborted if neccesary.
			pid_file = Tempfile.new('sbcp_daemon-pid')
			pid = Process.pid.to_s
			pid_file.write(pid)

			# Next, we perform a check to ensure that the server isn't already running.
			abort('Starbound is already running.') if not `pidof starbound_server`.empty?

			# We should load the config values into a local variable.
			# Since CLI mode does not create an instance of the daemon method,
			# we have to set things up separately so they can be used.
			config = YAML.load_file(File.expand_path('../../../config.yml', __FILE__))

			# Quick check for invalid config values.
			abort('Error - Invalid starbound directory') if not Dir.exist?(config['starbound_directory']) && Dir.exist?(config['starbound_directory'] + '/giraffe_storage')
			abort('Error - Invalid backup directory') if not Dir.exist?(config['backup_directory'])
			abort('Error - Invalid backup schedule') if not ['hourly', 2, 3, 4, 6, 8, 12, 'daily', 'restart'].include? config['backup_schedule']
			abort('Error - Invalid backup history') if not config['backup_history'] >= 1 || config['backup_history'] == 'none'
			abort('Error - Invalid log directory') if not Dir.exist?(config['log_directory'])
			abort('Error - Invalid log history') if not config['log_history'].is_a?(Integer) && config['log_history'] >= 1
			abort('Error - Invalid log style') if not ['daily', 'restart'].include? config['log_style']
			abort('Error - Invalid restart schedule') if not ['none', 'hourly', 2, 3, 4, 6, 8, 12, 'daily'].include? config['restart_schedule']

			# Require any present plugins
			plugins_directory = "#{config['starbound_directory']}/sbcp/plugins"
			$LOAD_PATH.unshift(plugins_directory)
			Dir[File.join(plugins_directory, '*.rb')].each {|file| require File.basename(file) }

			# We detach and daemonize this process to prevent a block in the calling executable.
			Process.daemon(nochdir=true)

			# We create an infinite loop so we can easily restart the server.
			loop do
				# Next we invoke the Starbound class to create an instance of the server.
				# This class will spawn a sub-process containing the server.
				server = SBCP::Starbound.new
				server.start

				# We wait for the server process to conclude before moving on.
				# This normally occurs after a shutdown, crash, or restart.
				# The daemon process will do nothing until the server closes.

				# Once the server has finished running, we'll want to rotate our logfiles.
				# We'll also take backups here if they've been set to behave that way.
				#SBCP::Logs.rotate if config['log_style'] == 'restart'
				SBCP::Backup.create_backup if config['backup_schedule'] == 'restart'

				# Now we must determine if the server was closed intentionally.
				# If the server was shut down on purpose, we don't want to automatically restart it.
				# If the shutdown file exists, it was an intentional shutdown.
				# We break the loop which ends the method and closes the Daemon process.
				break if not Dir.glob('/tmp/sb-shutdown*').empty?
			end
		ensure
			unless pid_file.nil?
				pid_file.close
				pid_file.unlink
			end
		end

		private

		# These methods are used only in GUI mode for managing the server.
		# In CLI mode, server management is handled via CLI options.

		def start_server
			# TODO: Create code that spawns a sub-process containing the server
		end

		def restart_server
		end

		def force_restart_server
		end

		def stop_server
		end

		def force_stop_server
		end

		def server_status
		end
  	end
end
