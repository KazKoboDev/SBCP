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

		def self.create_backup(kind=:starbound)
			config = YAML.load_file(File.expand_path('../../../config.yml', __FILE__))
			return('Backups disabled.') if config['backup_history'] == 'none'
			case kind
			when :starbound
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
			when :sbcp
				abort("Unimplemented.")
			when :full
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
		end
	end
end