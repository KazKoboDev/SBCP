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
require 'yaml'

module SBCP
	class Database
		def initialize
			#TODO Add configurable database path
 			DataMapper.setup(:default, "sqlite:SBCP.db")

 			require_relative 'models/account'
			require_relative 'models/character'
			require_relative 'models/world'

			DataMapper.finalize()
			#DataMapper.auto_upgrade!()
			DataMapper.auto_migrate!()
 		end

 		def add_character(username, character_name)
 			account_model = Models::Account.first_or_new(:username => username)
 			now = DateTime.now()
 			if account_model.created.nil?
 				account_model.created = now
 			end
 			account_model.last_access = now
 			account_model.save()

 			character_model = Models::Character.first_or_new({:name => character_name, :account => account_model})
  			if character_model.created.nil?
 				character_model.created = now
 			end
 			character_model.last_access = now
 			character_model.save()
 		end

 		def claim_world(username, planet, is_ship)
 			success = false
 			account_model = Models::Account.first(:username => username)
 			if not account_model.nil?
				world_model = Models::World.first_or_new(:planet =>planet)
				if world_model.account == nil or account_model.permission_level == Models::Account::TECHMOD
					now = DateTime.now()

					world_model.account = account_model
					world_model.is_ship = is_ship
		  			if world_model.created.nil?
 						world_model.created = now
						end
 					world_model.last_access = now		
					world_model.save()
					success = true
				end
 			end
 			return success
 		end

 		def get_account(username)
 			account_model = Models::Account.first(:username => username)
 			if not account_model.nil?
				return account_model
 			end
 			return nil
 		end

		def get_character(username, character_name)
 			account_model = Models::Account.first(:username => username)
 			if not account_model.nil?
				character_model = Models::Character.first({:name => character_name, :account => account_model})
				if not character_model.nil?
					return character_model
				end
 			end
 			return nil
 		end

  		def get_world(planet)
			world_model = Models::World.first(:planet => planet)
			if not world_model.nil?
				return world_model
			end
 			return nil
 		end

  		def release_world(username, planet)
 			success = false
 			account_model = Models::Account.first(:username => username)
 			if not account_model.nil?
				world_model = Models::World.first(:planet => planet)
				if not world_model.nil?
					if world_model.account == account_model or account_model.permission_level == Models::Account::TECHMOD
						world_model.account = nil
						world_model.last_access = DateTime.now()	
						world_model.save()
						success = true
					end
				end
 			end
 			return success
 		end

 	end
 end
