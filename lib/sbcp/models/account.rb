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

require 'data_mapper'

module SBCP
	module Models
		class Account
			USER = 0
			MOD = 1
			TECHMOD = 2
			ADMIN = 3

			include DataMapper::Resource
			property :id, Serial, :key => true
			property :username, String, :default => ''
			property :permission_level, Integer, :default => 0
			property :created, DateTime
			property :last_access, DateTime

			has n, :characters
			has n, :worlds
		end
	end
end
