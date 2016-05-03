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

require 'securerandom'
require 'fileutils'
require 'rsync'
require 'yaml'
module SBCP
	class Backup

		# This methods backs up various files.
		# It supports 3 types of backups.
		# Starbound: backs up world and related log files.
		# SBCP: backs up the SBCP database and related log files.
		# Full: backs up both Starbound and SBCP data.
		# Defaults to Starbound.

		def self.create_backup(type='starbound')
			config = YAML.load_file(File.expand_path('../../../config.yml', __FILE__))
			if config['backup_history'] == 'none'
				puts 'Backups are currently disabled.'
				return
			end
			case type
			when 'starbound'
				root = config['starbound_directory']
				world_files = "#{root}/giraffe_storage/universe/*.world"
				latest_files_directory = File.expand_path('../../../backup', __FILE__)
				backup_directory = config['backup_directory']
				backup_name = "#{Time.now.strftime("%m-%d-%Y-%H-%M-%S")}-starbound_backup.tar.bz2"
				changed_files = Array.new
				Rsync.run(world_files, latest_files_directory, ['-a']) do |result|
					if result.success?
						unless result.changes.length == 0
							result.changes.each do |change|
								changed_files.push("#{root}/giraffe_storage/universe/#{change.filename}")
							end
							FileUtils.cd('/tmp') do
								random_name = SecureRandom.urlsafe_base64
								FileUtils.mkdir random_name
								FileUtils.cp changed_files, random_name
								system("tar cjpf #{backup_name} #{random_name}")
								FileUtils.mv backup_name, backup_directory # Move the created backup to the backup directory
								FileUtils.rm_r random_name # Remove the folder after we're done with it
							end
						end
					end
				end
			when 'sbcp'
				puts "Unimplemented."
			when 'full'
				# This should take a complete backup of Starbound and SBCP.
				# Currently only supports Starbound.
				root = config['starbound_directory']
				giraffe_directory = "#{root}/giraffe_storage"
				backup_directory = config['backup_directory']
				backup_name = "#{Time.now.strftime("%m-%d-%Y-%H-%M-%S")}-full_backup.tar.bz2"
				FileUtils.cd('/tmp') do
					system("tar cjpf #{backup_name} #{giraffe_directory} > /dev/null 2>&1")
					FileUtils.mv backup_name, backup_directory # Move the created backup to the backup directory
				end
			end
			puts "Backup completed successfully."
		end
	end
end