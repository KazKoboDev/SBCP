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
	class Plugin
		@@plugin_registry = []

		def self.register(plugin)
			@@plugin_registry.push(plugin)
		end

		def self.hook(hook_id, *args)
			overrides = false
			@@plugin_registry.each do |plgn|
				if plgn.respond_to?(hook_id)
					overrides = overrides || plgn.send(hook_id, *args)
				end
			end
			return overrides
		end
	end
end
