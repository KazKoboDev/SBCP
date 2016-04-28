module SBCP
	class Logs
		def self.age(directory, days)
			Dir.glob("#{directory}/*.log").each do |log|
				if ((Time.now - File.stat(log).mtime).to_i / 86400.0) >= days
					File.delete(log)
				end
			end
		end
	end
end