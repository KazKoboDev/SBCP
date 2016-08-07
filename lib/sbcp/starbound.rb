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

require 'logger'
require 'rufus-scheduler'
require 'celluloid/current'

require_relative 'parser'

module SBCP
	class Starbound
		include Celluloid

		SESSION = {}
		
		def initialize
			SESSION[:info] = {
				:started	=> nil,
				:uptime		=> nil,
				:restart_in	=> nil,
			}
			SESSION[:players] = {}
			SESSION[:info][:restart_in] = 'Never' if $settings['restarts']['enabled'] == false
			backup_schedule = $settings['backups']['frequency']
			restart_schedule = $settings['restarts']['frequency']
			scheduler = Rufus::Scheduler.new
			unless $settings['restarts']['enabled'] == false or $settings['restarts']['frequency'] == 0 # Only run backups if they're not set to run at restart or aren't disabled
				if backup_schedule == 60
					scheduler.cron "0 */1 * * *" do
						Backup.create_backup
					end
				elsif backup_schedule == 1440
					scheduler.cron "0 0 * * *" do
						Backup.create_backup
					end
				else
					backup_schedule = backup_schedule / 60
					scheduler.cron "0 */#{backup_schedule} * * *" do
						Backup.create_backup
					end
				end
			end
			unless $settings['restarts']['enabled'] == false # Only schedule restarts if enabled
				if restart_schedule == 60
					scheduler.cron "0 */1 * * *" do
						pid = `pidof starbound_server`
						system("kill -15 #{pid.to_i}") if not pid.empty?
					end
				elsif restart_schedule == 1440
					scheduler.cron "0 0 * * *" do
						pid = `pidof starbound_server`
						system("kill -15 #{pid.to_i}") if not pid.empty?
					end
				else
					restart_schedule = restart_schedule / 60
					scheduler.cron "0 */#{restart_schedule} * * *" do
						pid = `pidof starbound_server`
						system("kill -15 #{pid.to_i}") if not pid.empty?
					end
				end
			end
		end

		def start
			parser = Parser.new

			SESSION[:info][:started] = Time.now

			IO.popen("#{$settings['system']['starbound']}/linux/starbound_server", :chdir=>"#{$settings['system']['starbound']}/linux", :err=>[:child, :out]) do |output|
				while line = output.gets
					parser.async.parse(line)
				end
			end

		ensure
			parser.log("---------- Starbound has successfully shut down ----------\n")
			parser.log("\n") # Adds a newline space at the end of the log. Helpful for separating restarts in daily logs.
			parser.close
			parser.terminate
		end
	end
end