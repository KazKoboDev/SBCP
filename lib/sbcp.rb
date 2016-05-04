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
require 'time_diff'
require 'tempfile'
require 'yaml'
require 'pp'

require_relative 'sbcp/backup'
require_relative 'sbcp/config'
require_relative 'sbcp/daemon'
require_relative 'sbcp/rcon'
require_relative 'sbcp/setup'

module SBCP
	class SBCP
		def initialize
			@config = YAML.load_file(File.expand_path('../../config.yml', __FILE__))
			@commands = ['backup', 'clear', 'config', 'detach', 'exit', 'get', 'kill', 'quit', 'reboot', 'restart', 'say', 'setup', 'start', 'stop', 'help']
			@commands_scheme = [
				"<%= color('backup', :command) %>",
				"<%= color('clear', :command) %>",
				"<%= color('config', :command) %>",
				"<%= color('detach', :command) %>",
				"<%= color('exit', :command) %>",
				"<%= color('get', :command) %>",
				"<%= color('kill', :command) %>",
				"<%= color('quit', :command) %>",
				"<%= color('reboot', :command) %>",
				"<%= color('restart', :command) %>",
				"<%= color('say', :command) %>",
				"<%= color('setup', :command) %>",
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
				cs[:info] =			[ :bold, :blue, :on_black ]
				cs[:help] =			[ :magenta, :on_black ]
			end
			HighLine.color_scheme = scheme
		end

		def repl
			system('clear')
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
				when /^(backup|backup\s?(\S+))$/
					backup($2)
				when 'clear'
					system('clear')
				when 'config'
					Config.new.config_menu(:main)
				when 'detach'
					system('screen -d')
				when 'exit', 'quit'
					say("<%= color('!!! This action could result in data loss !!!', :warning) %>")
					say("<%= color('!!! Starbound shall be stopped if running !!!', :warning) %>")
					if agree("Are you sure? ", true)
						stop('SIGKILL') unless `pidof starbound_server`.empty?
						exit
					end
				when /^(get|get\s?(\S+))$/
					get($2)
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
				when /^(say|say\s?(.+))$/
					sb_say($2)
				when 'setup'
					Setup.new.run
				when 'start'
					if `pidof starbound_server`.empty?
						if $daemon.nil?
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
				when /^(help|help\s?(\S+))$/
					command = $2
					if not command.nil?
						if @commands.include? command.strip
							help(command)
						else
							say("The command \"#{command.strip}\" does not exist.")
						end
					else
						help
					end
				else
					say('Invalid command. Try help for a list of possible commands.')
				end
			end
		ensure
			$daemon.terminate unless $daemon.nil?
		end

		def backup(type=nil)
			if not type.nil?
				case type
				when 'starbound', 'sbcp', 'full'
					Backup.create_backup(type)
				else
					say("Backup type \"#{type}\" is not valid.")
				end
			else
				say('Please specify a backup type.')
			end
		end

		def get(data=nil)
			if not data.nil?
				case data
				when 'info'
					unless Starbound::SESSION.nil? || Starbound::SESSION.empty?
						Starbound::SESSION[:info][:uptime] = Time.diff(Starbound::SESSION[:info][:started], Time.now, '%H %N %S')[:diff]
						unless Starbound::SESSION[:info][:restart_in] == 'Never'
							Starbound::SESSION[:info][:restart_in] = "#{(((@config['restart_schedule']*60*60) - (Time.now - Starbound::SESSION[:info][:started]))/60).to_i} minutes" # Inaccurate for first start, fairly acurrate thereafter
						end
						Starbound::SESSION[:info].each_pair do |key, value|
							say("<%= color('#{key.to_s.capitalize}:', :info) %> #{value}")
						end
					else
						say("<%= color('Error!', :failure) %> Session data is missing or empty.")
					end
				when 'players'
					unless Starbound::SESSION.nil? || Starbound::SESSION.empty?
						pp(Starbound::SESSION[:players])
					else
						say("<%= color('Error!', :failure) %> Session data is missing or empty.")
					end
				else
					say("Data type \"#{data}\" is not valid.")
				end
			else
				say('Please specify a data type.')
			end
		end

		def restart(signal='SIGTERM')
			say('Sending restart request...')
			kill(signal)
		end

		def start
			say('Starting the Starbound server...')
			supervisor = Daemon.supervise
			$daemon = supervisor.actors.first
			$daemon.async.start
			say("<%= color('Operation complete.', :success) %>")
		end

		def stop(signal='SIGTERM')
			say('Sending stop request...')
			file = Tempfile.new('sb-shutdown')
			kill(signal)
		ensure
			unless file.nil?
				file.close
				file.unlink
			end
		end

		def sb_say(string)
			unless string.nil?
				if not $rcon.nil?
					$rcon.execute("say #{string}")
					say("<%= color('Message sent to server.', :success) %>")
				else
					say("<%= color('RCON is not running.', :warning) %>")
				end
			else
				say("Please type something to say.")
			end
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
			say("<%= color('Aborting request. See details below.', :failure) %>")
			return say('Unable to locate the starbound_server process. Is it running?')
		end

		def help(command=nil)
			if not command.nil?
				case command
				when 'backup'
				else
					say("Could not find help for \"#{command}\" command.")
				end
			else
				say("<%= color('Command list. Type help [command] to learn more.', :help) %>")
				say("#{@commands_scheme.join(", ")}")
			end
		end
	end
end