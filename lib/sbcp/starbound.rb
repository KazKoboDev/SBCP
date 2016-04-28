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

module SBCP
	class Starbound
		def initialize
			@config = YAML.load_file(File.expand_path('../../../config.yml', __FILE__))
			backup_schedule = @config['backup_schedule']
			restart_schedule = @config['restart_schedule']
			scheduler = Rufus::Scheduler.new
			unless ['restart', 'none'].include? backup_schedule # Only run backups if they're not set to run at restart or aren't disabled
				if backup_schedule == 'hourly'
					scheduler.cron "0 */1 * * *" do
						SBCP::Backup.create_backup
					end
				elsif backup_schedule == 'daily'
					scheduler.cron "0 0 * * *" do
						SBCP::Backup.create_backup
					end
				else
					scheduler.cron "0 */#{backup_schedule} * * *" do
						SBCP::Backup.create_backup
					end
				end
			end
			unless restart_schedule == 'none' # Only schedule restarts if enabled
				if restart_schedule == 'hourly'
					scheduler.cron "0 */1 * * *" do
						pid = `pidof starbound_server`
						system("kill -15 #{pid.to_i}") if not pid.empty?
					end
				elsif restart_schedule == 'daily'
					scheduler.cron "0 0 * * *" do
						pid = `pidof starbound_server`
						system("kill -15 #{pid.to_i}") if not pid.empty?
					end
				else
					scheduler.cron "0 */#{restart_schedule} * * *" do
						pid = `pidof starbound_server`
						system("kill -15 #{pid.to_i}") if not pid.empty?
					end
				end
			end
		end

		def start
			if @config['log_style'] == 'daily' then
				log = Logger.new("#{@config['log_directory']}/starbound.log", 'daily', @config['log_history'])
			elsif @config['log_style'] == 'restart' then
				stamp = "#{Time.now.strftime("%m-%d-%Y-%H-%M-%S")}-starbound"
				log = Logger.new("#{@config['log_directory']}/#{stamp}.log")
			else
				abort("Error: Invalid log style")
			end
			log.formatter = proc { |severity, datetime, progname, msg| date_format = datetime.strftime("%H:%M:%S.%N")[0...-6]; "[#{date_format}] #{msg}" }
			log.level = Logger::INFO
			log.info("---------- SBCP is starting a new Starbound instance ----------\n")
			#parser = SBCP::Parser.new

			IO.popen("#{@config['starbound_directory']}/linux64/starbound_server", :chdir=>"#{@config['starbound_directory']}/linux64", :err=>[:child, :out]) do |output|
				while line = output.gets
					log.info(line)
					#parser.async.parse(line)
				end
			end

		ensure
			log.info("---------- Starbound has successfully shut down ----------\n")
			log.info("\n") # Adds a newline space at the end of the log. Helpful for separating restarts in daily logs.
			log.close
			#parser.terminate
		end
	end
end