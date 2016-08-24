class PlayerAnnouncer
	def login(*args)
		name, cid, ip = *args
		$rcon.execute( "say ^\#ddd37b;#{name}^\#aaaaaa; has connected") 
	end

	def logout(*args)
		name, cid, ip = *args
		$rcon.execute( "say ^\#ddd37b;#{name}^\#aaaaaa; has disconnected") 
	end
end

SBCP::Plugin.register(PlayerAnnouncer.new())