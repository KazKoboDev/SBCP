module SBCP
	class Starbound
		def initialize
			@config = YAML.load_file(File.expand_path('../../../config.yml', __FILE__))
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

			IO.popen("#{@config['starbound_directory']}/linux64/starbound_server", :chdir=>"#{@config['starbound_directory']}/linux64", :err=>[:child, :out]) do |output|
				while line = output.gets
					log.info(line)
				end
			end

		ensure
			log.info("---------- Starbound has successfully shut down ----------\n")
			log.info("\n") # Adds a newline space at the end of the log. Helpful for separating restarts in daily logs.
			log.close
		end
	end
end