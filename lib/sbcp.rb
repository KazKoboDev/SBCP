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

require 'highline/import'
require 'celluloid/current'
require 'pry'

module SBCP
	class SBCP
		def initialize
			@commands = ['backup', 'detach', 'exit', 'kill', 'quit', 'reboot', 'restart', 'start', 'stop', 'help']
			@commands_scheme = [
				"<%= color('backup', :command) %>",
				"<%= color('detach', :command) %>",
				"<%= color('exit', :command) %>",
				"<%= color('kill', :command) %>",
				"<%= color('quit', :command) %>",
				"<%= color('reboot', :command) %>",
				"<%= color('restart', :command) %>",
				"<%= color('start', :command) %>",
				"<%= color('stop', :command) %>",
				"<%= color('help', :command) %>"
			]
			scheme = HighLine::ColorScheme.new do |cs|
				cs[:headline] =		[ :bold, :yellow, :on_black ]
				cs[:subheader] =	[ :cyan, :on_black ]
				cs[:command] =		[ :green, :on_black ]
				cs[:warning] = 		[ :red, :on_black ]
				cs[:failure] =		[ :bold, :red, :on_black ]
				cs[:success] =		[ :bold, :green, :on_black]
				cs[:help] =			[ :magenta, :on_black ]
			end
			HighLine.color_scheme = scheme
		end

		def repl
			say("<%= color(' .d8888b.  888888b.    .d8888b.  8888888b.', :headline) %>")
			say("<%= color('d88P  Y88b 888  \"88b  d88P  Y88b 888   Y88b', :headline) %>")
			say("<%= color('Y88b.      888  .88P  888    888 888    888', :headline) %>")
			say("<%= color(' \"Y888b.   8888888K.  888        888   d88P', :headline) %>")
			say("<%= color('    \"Y88b. 888  \"Y88b 888        8888888P\"', :headline) %>")
			say("<%= color('      \"888 888    888 888    888 888', :headline) %>")
			say("<%= color('Y88b  d88P 888   d88P Y88b  d88P 888', :headline) %>")
			say("<%= color(' \"Y8888P\"  8888888P\"   \"Y8888P\"  888', :headline) %>")
			say("<%= color('       (    (        *       ) (', :subheader) %>")
			say("<%= color('   (   )\\ ) )\\ )   (  `   ( /( )\\ )', :subheader) %>")
			say("<%= color('   )\\ (()/((()/(   )\\))(  )\\()|()/(  (', :subheader) %>")
			say("<%= color(' (((_) /(_))/(_)) ((_)()\\((_)\\ /(_)) )', :subheader) %>")
			say("<%= color(' )\\___(_)) (_))   (_()((_) ((_|_))_ ((_)', :subheader) %>")
			say("<%= color('((/ __| |  |_ _|  |  \\/  |/ _ \\|   \\| __|', :subheader) %>")
			say("<%= color(' | (__| |__ | |   | |\\/| | (_) | |) | _|', :subheader) %>")
			say("<%= color('  \\___|____|___|  |_|  |_|\\___/|___/|___|', :subheader) %>")
			say("\n")
			loop do
				input = ask('> ')
				case input
				when /^backup\s?(starbound|sbcp|full)?$/ # eg. backup starbound; backup sbcp; backup full
					type = input.split("backup")
					type = type.empty? ? nil : type.last.strip
					backup(type)
				when 'kill'
					say("<%= color('!!! This action could result in data loss !!!', :warning) %>")
					if agree("Are you sure? ", true)
						stop('SIGKILL')
					end
				when 'reboot'
					say("<%= color('!!! This action could result in data loss !!!', :warning) %>")
					if agree("Are you sure? ", true)
						restart('SIGKILL')
					end
				when 'restart'
					if agree("Are you sure? ", true)
						restart
					end
				when 'start'
					if `pidof starbound_server`.empty?
						if @daemon.nil?
							start
						else
							say("<%= color('Duplicate prevented.', :warning) %> The daemon is still processing. Please wait and try again.")
						end
					else
						say("<%= color('Duplicate prevented.', :warning) %> The server is already running.")
					end
				when 'stop'
					if agree("Are you sure? ", true)
						stop
					end
				when 'detach', 'quit', 'exit'
					system('screen -d')
				when /^(help|help\s?(\S+))$/
					command = input.split("help")
					if not command.empty?
						if @commands.include? command.last.strip
							help(command)
						else
							say("The command \"#{command.last.strip}\" does not exist.")
						end
					else
						help
					end
				end
			end
		rescue => e
			puts e
			sleep
		ensure
			@daemon.terminate unless @daemon.nil?
		end

		def backup(type=nil)
			if not type.nil?
				require_relative 'sbcp/backup'
				Backup.create_backup(type)
			else
				say("Please specify a backup type.")
			end
		end

		def restart(signal='SIGTERM')
			say('Sending restart request...')
			kill(signal)
		end

		def start
			require_relative 'sbcp/daemon'
			say('Starting the Starbound server...')
			supervisor = Daemon.supervise
			@daemon = supervisor.actors.first
			@daemon.async.start
			say("<%= color('Operation complete.', :success) %>")
		end

		def stop(signal='SIGTERM')
			say('Sending stop request...')
			# USE TEMPFILE TO TRACK PERMA KILLS, VARIABLES WON'T WORK
			kill(signal)
		end

		def kill(signal='SIGTERM')
			pid = `pidof starbound_server`
			unless pid.empty?
				system("kill -s #{signal} #{pid.to_i}")
				t = Time.now
				d = 0
				until `pidof starbound_server`.empty? || d >= 5
					sleep(1)
					d = Time.now - t
				end
				if not `pidof starbound_server`.empty?
					return say("<%= color('Failure!', :failure) %> The server is still running.")
				end
				return say("<%= color('Operation complete.', :success) %>")
			end
			say("<%= color('Aborting stop request. See details below.', :failure) %>")
			return say('Unable to locate the starbound_server process. Is it running?')
		end

		def help(command=nil)
			if not command.nil?
				case command
				when 'backup'
				end
			else
				say("<%= color('Command list. Type help [command] to learn more.', :help) %>")
				say("#{@commands_scheme.join(", ")}")
			end
		end
	end
end