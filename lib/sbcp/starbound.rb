module SBCP
	class Starbound

		def initialize
			@config = YAML.load_file(File.expand_path('../../../config.yml', __FILE__))
		end

		def start
			loop do
				puts @config
				sleep 2
			end
		end

		# The two methods below were implemeneted in the Starbound class because
		# they should both be working in order for the server to perform well.
		# These methods are also closely related to Starbound's files.
		# It just seemed unneccesary to separate them out.

		def rotate_logs

		end

		def create_backup

		end
	end
end