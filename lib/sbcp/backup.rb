module SBCP
	class Backup
		include Celluloid

		# This methods backs up various files.
		# It supports 3 types of backups.
		# Starbound: backs up world and related log files.
		# SBCP: backs up the SBCP database and related log files.
		# Full: backs up both Starbound and SBCP data.
		# Defaults to Starbound.

		def self.create_backup(kind='starbound')
			case kind
			when 'starbound'
			when 'sbcp'
			when 'full'
			else
			end
		end
	end
end