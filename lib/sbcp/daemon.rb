require 'yaml'
require 'celluloid/current'
require_relative 'starbound'
require_relative 'backup'
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

			# We first perform a check to ensure that the server isn't already running.
			abort('Starbound is already running.') if not `pidof starbound_server`.empty?

			# We detach and daemonize this process to prevent a block in the calling executable.
			#Process.daemon

			# First, we should load the config values into a local variable.
			# Since CLI mode does not create an instance of the daemon method,
			# we have to set things up separately so they can be used.
			config = YAML.load_file(File.expand_path('../../../config.yml', __FILE__))

			# We create an infinite loop so we can easily restart the server.
			loop do 
				# Next we invoke the Starbound class to create an instance of the server.
				# This class will spawn a sub-process containing the server.
				server = SBCP::Starbound.new
				server.start

				# We wait for the server process to conclude before moving on.
				# This normally occurs after a shutdown, crash, or restart.
				# The daemon process will do nothing until the server closes.
				Process.wait(server)

				# Once the server has finished running, we'll want to rotate our logfiles.
				# We'll also take backups here if they've been set to behave that way.
				server.rotate_logs
				server.create_backup if config['backup_schedule'] == 'restart'

				# Now we must determine if the server was closed intentionally.
				# If the server was shut down on purpose, we don't want to automatically restart it.
				# If the shutdown file exists, it was an intentional shutdown.
				# We break the loop which ends the method and closes the Daemon process.
				shutdown = File.expand_path('../../../tmp/shutdown', __FILE__)
				if File.exist?(shutdown)
					# We remove the shutdown file to avoid any confusion later.
					File.delete(shutdown)
					server.terminate # Required by Celluloid's design
					break
				end
			end
		end

		# We make the full backup method a class method so it can be called via CLI.
		# However, it is also used in GUI mode to take manual backups.
		def self.create_full_backup
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

		def create_backup
		end
  	end
end
