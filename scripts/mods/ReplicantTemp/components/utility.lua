local mod = get_mod("ReplicantTemp")

EchoConsole = function(str)
	mod:echo(str)
end

-- shorthand to check is a unit is alive based on its health extension
mod.is_unit_alive = function(unit)
	-- this checks only if the unit still exists and has a body / corpse
	if not unit or not Unit.alive(unit) then
		return false
	end
	
	-- but a units should be considered dead if it has 0 health even if the corpse is still lying around..
	local health_extension	= ScriptUnit.has_extension(unit, "health_system")
	local is_alive			= (health_extension and health_extension:is_alive()) or false
	
	return is_alive
end



mod.utility = {}

mod.utility.find_in_array = function(array, value, field)
	for k = 1, #array, 1 do
		local element = array[k]
		local element_field = nil
		if field then
			element_field = element[field]
		end
		
		if (element_field and element_field == value) or (not element_field and element == value) then
			return k
		end
	end
	
	return nil
end

BackendInterfaceTalentsPlayfab.get_talent_ids = function (self, career_name)
	local career_settings = CareerSettings[career_name]
	local profile_name = career_settings.profile_name
	local talent_tree_index = career_settings.talent_tree_index
	local talent_tree = talent_tree_index and TalentTrees[profile_name][talent_tree_index]
	local talent_ids = {}
	local talents = self:get_talents(career_name)

	if talents then
		for i = 1, #talents, 1 do
			local column = talents[i]

			if column ~= 0 then
				local talent_name = talent_tree[i][column]
				local talent_lookup = TalentIDLookup[talent_name]

				if talent_lookup and talent_lookup.talent_id then
					talent_ids[#talent_ids + 1] = talent_lookup.talent_id
				end
			end
		end
	end

	return talent_ids
end

local function to_string(data)
	if type(data) == 'table' then
		
		local str = '{ ' -- beginning of the string
		
		for id, value in pairs(data) do
			
			if type(id) ~= 'number' then
				id = '"'..id..'"' -- if id is not number take it to quotes
			end
			
			str = str .. '['..id..'] = ' .. to_string(value) .. ','  -- recursive call/s
		end
		
		return str .. '} ' -- end string and return
		
	else
		return tostring(data) -- use standart function for numbers, etc
	end
end

local function CrossTable()
	return {
		Add = function(self, identifier)
			if self[identifier] then
				return
			end
			
			local id_type = type(identifier)
			local index = #self + 1
			
			if id_type == "number" then
				self[index] = identifier
				return
			else
				self[index] = identifier
				self[identifier] = index
			end
		end,
		Remove = function(self, identifier)
			local length = #self
			
			if length <= 0 then
				return
			end
			
			if not identifier then
				identifier = length
			end
			
			local id_type = type(identifier)
			
			if id_type == "number" then
				local remove_value = self[identifier]
				
				if remove_value and type(remove_value) ~= "number" then
					self[remove_value] = nil
				end
				
				self[identifier] = nil
				
				return
			else
				local index = self[identifier]
				
				self[identifier] = nil
				
				for i = index, length - 1, 1 do
					local next_value = self[i + 1]
					
					self[i] = next_value
					
					if type(next_value) ~= "number" then
						self[next_value] = i
					end
				end
				
				self[length] = nil
			end
		end,
		Clear = function(self)
			local length = #self
			
			for i = 1, length, 1 do
				local remove_value = self[i]
				
				self[i] = nil
				
				if type(remove_value) ~= "number" then
					self[remove_value] = nil
				end
			end
		end
	}
end

mod.utility.get_talent_specialisation = function(career_name, talent_line_index)
	if not career_name or not talent_line_index then
		return nil
	end
	
	local career_settings = CareerSettings[career_name]
	local profile_name = career_settings.profile_name
	local talent_tree_index = career_settings.talent_tree_index
	local talent_tree = talent_tree_index and TalentTrees[profile_name][talent_tree_index]
	local talent_interface = Managers.backend:get_talents_interface()
	local talent_ids = talent_interface:get_talent_ids(career_name)
	
	local talent_line = talent_tree[talent_line_index]
	local ret_talents = CrossTable() -- {}
	
	for i = 1, #talent_ids, 1 do
		local talent_id = talent_ids[i]
		local talent_lookup = TalentIDLookup[talent_name]
		
		for j = 1, #talent_line, 1 do
			local talent_name = talent_line[j]
			local talent_lookup = TalentIDLookup[talent_name]
			
			if talent_lookup and talent_lookup.talent_id and talent_lookup.talent_id == talent_id then
				--table.insert(ret_talents, talent_name)
				--ret_talents[talent_name] = true
				ret_talents:Add(talent_name)
			end
		end
	end
	
	return ret_talents
end

--[[mod.utility.get_talent_specialisation = function(career_name, talent_line)
	if not career_name or not talent_line then
		return false
	end
	
	local talent_interface = Managers.backend:get_talents_interface()
	local talent_ids = talent_interface:get_talent_ids(career_name)

	for k = 1, #talent_ids, 1 do
		local talent_id = talent_ids[k]
		
		mod:echo(talent_id)
		if talent_id > 3 * (talent_line - 1) and talent_id < 3 * talent_line then
			return Talents[career_name][talent_id]
		end
	end
	
	return "default"
end--]]

mod.utility.target_position = function(target, prefered_aim_node)
	local aim_node = nil
	if prefered_aim_node then
		aim_node = prefered_aim_node
	else
		local target_unit_blackboard = BLACKBOARDS[target]
		local target_breed = target_unit_blackboard and target_unit_blackboard.breed
		aim_node = (target_breed and (target_breed.bot_melee_aim_node or "j_spine")) or "rp_center"
	end
	
	local node = 0
	if Unit.has_node(target, aim_node) then
		node = Unit.node(target, aim_node)
	end

	local target_position = Unit.world_position(target, node)

	return target_position
end

--[[local get_hit_zone = function (unit, actor)
	local breed = AiUtils.unit_breed(unit)

	if breed then
		local node = Actor.node(actor)
		local hit_zone = breed.hit_zones_lookup[node]
		local hit_zone_name = hit_zone.name
		local hit_actor_name = hit_zone.actor_name
		
		return hit_zone_name, hit_actor_name
	else
		return "full", nil
	end
end--]]

local INDEX_POSITION = 1
local INDEX_DISTANCE = 2
local INDEX_NORMAL = 3
local INDEX_ACTOR = 4
local COLLISION_FILTER = "filter_player_ray_projectile"
mod.utility.calculate_obstruction = function(physics_world, from, to, ignore_unit, aim_unit, aim_zones, check_spread, collision_filter)	
	local offset = to - from
	local distance = Vector3.length(offset)
	local direction = Vector3.normalize(offset)
	
	if distance < 0.001 or Vector3.length_squared(direction) < 0.000001 then
		-- prevents zero length distance raycast crash
		return false
	end
	
	PhysicsWorld.prepare_actors_for_raycast(physics_world, from, direction, 0.01, check_spread, distance * distance)
	local raycast_hits = PhysicsWorld.immediate_raycast(physics_world, from, direction, distance, "all", "collision_filter", collision_filter)
	
	local obstructed_by_enemy = false
	local obstructed_enemy_to_target_dist = math.huge
	local obstructed_by_static = math.huge
	
	if raycast_hits then
		local num_hits = #raycast_hits

		for i = 1, num_hits, 1 do
			local hit = raycast_hits[i]
			local hit_actor = hit[INDEX_ACTOR]
			local hit_unit = Actor.unit(hit_actor)
			
			if hit_unit == aim_unit then
				if aim_zones then
					local hit_zone_name = DamageUtils.hit_zone(hit_unit, hit_actor)
					
					local hit_valid_zone = aim_zones[hit_zone_name] or hit_zone_name == "full"
					
					if hit_zone_name ~= "afro" then
						return false, nil, false, not hit_valid_zone
					end
					
				else
					return false
				end
			elseif hit_unit ~= ignore_unit then
				local obstructed_by_static = Actor.is_static(hit_actor)
				
				if obstructed_by_static then
					return true, distance - hit[INDEX_DISTANCE], obstructed_by_static, true
				end
			end
		end
	end
	
	return false
end

local modes = {
	path = 1,
	los = 2,
	lof = 3
}
mod.utility.check_obstruction = function(blackboard, target_unit, params) -- params:  mode, target_position, target_node, fire_node
	local mode = modes[params.mode] or modes.path
	local self_unit = blackboard.unit
	local raycast_from_pos = nil
	
	if not blackboard or not self_unit or not target_unit then
		return true
	end
	
	if mode == modes.lof or mode == modes.los then
		local camera_position = blackboard.first_person_extension:current_position()
		raycast_from_pos = camera_position
	elseif mode == modes.path then
		local self_pos = POSITION_LOOKUP[self_unit]
		raycast_from_pos = self_pos
		raycast_from_pos.z = raycast_from_pos.z + 0.1
	end
	
	if not raycast_from_pos then
		return true
	end
	
	local physics_world = World.get_data(blackboard.world, "physics_world")
	local target_node = params.target_node or "rp_center"
	local target_position = params.target_position or mod.utility.target_position(target_unit, target_node)
	local fire_node_actor = (mode == modes.lof) and (params.fire_node_actors or { head = true }) or nil
	
	local is_obstructed, _, obstructed_by_static, hit_invalid_zone = mod.utility.calculate_obstruction(physics_world, raycast_from_pos, target_position, self_unit, target_unit, fire_node_actors, mode == modes.lof and 0.5 or 10, COLLISION_FILTER)

	return is_obstructed or obstructed_by_static or hit_invalid_zone
end


mod.utility.copy_data = function(table_from, table_to)
	for name, cell in pairs(table_from) do
		table_to[name] = cell
	end
end

local ZEALOT_PERMANENT_HEALTH_THRESHOLD = 0.16667
--[[
mod.utility.get_player_status = function(player_unit)
	local status_ext = ScriptUnit.extension(player_unit, "status_system")
	local is_disabled = status_ext and status_ext:is_disabled()
	
	local health_percent = 0
	
	if not is_disabled then
		local career_ext = ScriptUnit.extension(player_unit, "career_system")
		local health_ext = ScriptUnit.extension(player_unit, "health_system")
		local is_zealot = career_ext and career_ext:career_name() == "wh_zealot"
		local is_bleeding_out = status_ext and not status_ext:has_wounds_remaining()
		health_percent = health_ext and health_ext:current_health_percent()
		
		if is_zealot and not is_bleeding_out and health_ext:current_permanent_health_percent() > ZEALOT_PERMANENT_HEALTH_THRESHOLD then
			health_percent = 1
		elseif is_bleeding_out then
			health_percent = health_percent / 2
		end
	end
	
	return is_disabled, health_percent, needs_urgent_healing
end
--]]
mod.utility.get_player_status = function(player_unit)
	local status_ext = ScriptUnit.extension(player_unit, "status_system")
	local is_disabled = status_ext and status_ext:is_disabled()
	
	local health_percent = 0
	
	if not is_disabled then
		local career_ext = ScriptUnit.extension(player_unit, "career_system")
		local health_ext = ScriptUnit.extension(player_unit, "health_system")
		local is_zealot = career_ext and career_ext:career_name() == "wh_zealot"
		local is_bleeding_out = status_ext and not status_ext:has_wounds_remaining()
		health_percent = health_ext and health_ext:current_health_percent()
		
		-- local zealot_full_stack = false
		-- if is_zealot then
			-- local chunk_size = 25
			-- local damage_taken = health_ext and health_ext:get_damage_taken("uncursed_max_health")
			-- local uncursed_max_health = health_ext and health_ext:get_uncursed_max_health()
			-- local max_stacks = math.min(math.floor(uncursed_max_health / chunk_size) - 1, 6)
			-- local health_chunks = math.floor(damage_taken / chunk_size)
			-- local num_chunks = math.min(max_stacks, health_chunks)
			
			-- if max_stacks <= num_chunks then
				-- zealot_full_stack = true
			-- end
		-- end
		
		-- local buff_extension = self_unit and ScriptUnit.has_extension(self_unit, "buff_system")
		-- local zealot_death_resist_active = buff_extension and buff_extension:has_buff_type("victor_zealot_gain_invulnerability_on_lethal_damage_taken")
		
		-- if is_zealot and not is_bleeding_out and health_ext:current_permanent_health_percent() > ZEALOT_PERMANENT_HEALTH_THRESHOLD then
		if is_zealot and not is_bleeding_out then
			health_percent = 1
		elseif is_bleeding_out then
			health_percent = health_percent / 2
		end
	end
	
	return is_disabled, health_percent, needs_urgent_healing
end

local URGENT_HEALING_NEED_THRESHOLD = 0.2
mod.utility.get_status_of_players_in_radius = function(blackboard, self_position, radius_sq)
	local side = blackboard.side
	local PLAYER_AND_BOT_UNITS = side.PLAYER_AND_BOT_UNITS
	
	local summary_health_percent = 0
	local num_players = 0
	local needing_urgent_healing = 0
	local num_active_players = 0
	
	for i = 1, #PLAYER_AND_BOT_UNITS, 1 do
		local player_unit = PLAYER_AND_BOT_UNITS[i]
		local player_position = POSITION_LOOKUP[player_unit]
		local distance_squared = player_position and Vector3.distance_squared(self_position, player_position) or math.huge
		
		local is_disabled, health_percent = mod.utility.get_player_status(player_unit)
		
		if not is_disabled and distance_squared <= radius_sq then
			num_players = num_players + 1
			summary_health_percent = summary_health_percent + health_percent
			
			if health_percent <= URGENT_HEALING_NEED_THRESHOLD then
				needing_urgent_healing = needing_urgent_healing + 1
			end
		end
		
		if not is_disabled then
			num_active_players = num_active_players + 1
		end
	end
	
	local average_health_percent = 0
	if num_players > 0 then
		average_health_percent = summary_health_percent / num_players
	end
	
	return num_players, average_health_percent, needing_urgent_healing, num_active_players
end

local BOSS = 1
local SPECIAL = 2
local ELITE = 3
local REGULAR = 4
local UNSTAGGERED_BOSSES = { "chaos_exalted_sorcerer_drachenfels" }
mod.utility.get_enemy_data = function(enemy_unit)
	local blackboard = BLACKBOARDS[enemy_unit]
	
	local breed = blackboard.breed
	local specific = breed.boss and 1 or (breed.special and 2 or (breed.elite and 3 or 4))
	local target = blackboard.target_unit
	local threat_value = breed.threat_value
	
	local is_unstaggered_boss = false
	if specific == BOSS and mod.utility.find_in_array(UNSTAGGERED_BOSSES, breed.name) then
		is_unstaggered_boss = true
	end
	
	local is_superarmoured = breed.primary_armor_category and breed.primary_armor_category == 6
	
	return threat_value, specific, target, is_unstaggered_boss, is_superarmoured
end


local CombinedTable = function(...)
	return {
		tables = {...},
		Append = function(self, ...)
			local current_tables_num = #self.tables
			local tables_to_add = {...}
			
			for i = 1, #tables_to_add, 1 do
				self.tables[current_tables_num + i] = tables_to_add[i]
			end
		end,
		Get = function(self, field_name, ...)
			for i = 1, #self.tables, 1 do
				local table = self.tables[i]
				
				local res = table[field_name]
				
				local inner_fields = {...}
				for j = 1, #inner_fields, 1 do
					local inner_field = inner_fields[j]
					
					if res and type(res) == "table" and inner_field then
						res = res[inner_field]
					else
						res = nil
						break
					end
				end
				
				if res then
					return res
				end
			end
			
			return nil
		end,
		GetTable = function(self, index)
			return self.tables[index]
		end
	}
end

-----------------------------------------------

mod.get_proximite_enemies = function(self_unit, check_range, max_height_offset)
	if not max_height_offset then
		max_height_offset = math.huge
	end
	
	local prox_enemies = {}

	local search_position = Vector3.copy(POSITION_LOOKUP[self_unit])
	
	local query_tmp = {}
	local enemy_broadphase = Managers.state.entity:system("ai_system").broadphase
	local num_hits = Broadphase.query(enemy_broadphase, search_position, check_range, query_tmp)
	local index = 1

	for i = 1, num_hits, 1 do
		local unit = query_tmp[i]
		local health_ext = unit and ScriptUnit.has_extension(unit, "health_system")

		if health_ext and health_ext.is_alive(health_ext) then
			local enemy_pos = POSITION_LOOKUP[unit]
			local offset = enemy_pos - search_position
			local distance = offset and Vector3.length(offset)
			local z_offset = offset and offset.z
			local in_range = offset and z_offset < max_height_offset and distance < check_range

			-- if PlayerBotBase._target_valid(nil, unit, offset) then
			if in_range then
				local breed = Unit.get_data(unit, "breed")
				if breed and breed.name ~= "critter_pig" and breed.name ~= "critter_rat" then
					prox_enemies[index] = unit
					index = index + 1
				end
			end
		end
	end

	table.clear(query_tmp)

	return prox_enemies
end

mod.check_alignment_to_target = function(unit, target_unit, opt_infront_angle, opt_flank_angle)
	-- determine if the bot is flanking the target unit (thanks Fatshark for putting this to your bot movement code)
	local infront_angle	= opt_infront_angle or 90	-- deg forward cone
	local flank_angle	= opt_flank_angle or 120	-- deg flank cone
	local flanking_target_unit = false
	local infront_of_target_unit = false
	
	local self_position = POSITION_LOOKUP[unit]	-- taking copies of the position vectors because the z-coordinate is modified when determining positioning towards the enemy
	local target_unit_pos = POSITION_LOOKUP[target_unit]
	if self_position and target_unit_pos then
		-- ignore Z-axiz difference when determining the flanking vs in-front
		local self_position_copy = Vector3.copy(self_position)
		local target_unit_pos_copy = Vector3.copy(target_unit_pos)
		Vector3.set_z(self_position_copy,0)
		Vector3.set_z(target_unit_pos_copy,0)
		local enemy_offset = target_unit_pos_copy - self_position_copy
		local enemy_rot = Unit.local_rotation(target_unit, 0)
		local enemy_dir = Quaternion.forward(enemy_rot)
		local dot = Vector3.dot(enemy_dir, enemy_offset)
		local div = Vector3.length(enemy_dir) * Vector3.length(enemy_offset)
		if div ~= 0 then
			-- normalize the dot product so that it actually is reduced into a cosine of the angle between
			-- the enemy's facing direction vector and the bot-enemy vector in xy-plane
			dot = dot / div
		end
		
		-- check where the bot is in relation to the target, dot = -1 >>> dead in front, dot = +1 >>> directly behind
		local infront_angle_compare	= math.cos(((180-(infront_angle * 0.5)) / 180) * math.pi)
		local flank_angle_compare	= math.cos(((flank_angle * 0.5) / 180) * math.pi)
		if infront_angle_compare > dot then
			infront_of_target_unit = true
		end
		if flank_angle_compare < dot then
			flanking_target_unit = true
		end
	else
		-- This seems to happen randomly, happened once when I opened a chest with lootd die inside, then again during the end run of drachenfels.
		-- this definitely happens when bots are close to destructible objects such as doors / barricades
	end
	return infront_of_target_unit, flanking_target_unit
end

mod.check_line_of_sight = function(self_unit, target_unit)	--edit-- can be reworked
	-- some presudy pastes for further rework
	-- local camera_position = blackboard.first_person_extension:current_position()
	-- local attack_meta_data = item_template.attack_meta_data or {}
	-- aim_at_node = attack_meta_data.aim_at_node or "j_spine",
	-- aim_at_node_charged = attack_meta_data.aim_at_node_charged or attack_meta_data.aim_at_node or "j_spine",
	local obstructed_by_static = true
	
	if self_unit and target_unit then
		local world = Managers.state.spawn.world
		local physics_world = World.get_data(world, "physics_world")
		local self_pos_raw = false
		local target_pos_raw = false
		
		-- self_pos_raw	= POSITION_LOOKUP[self_unit]	-- this returns coordinates at the floor level where the actor stands
		local self_bb = BLACKBOARDS[self_unit]
		local first_person_ext = self_bb.first_person_extension
		self_pos_raw	= first_person_ext:current_position()
		target_pos_raw	= POSITION_LOOKUP[target_unit]	-- this returns coordinates at the floor level where the actor stands
		
		if self_pos_raw and target_pos_raw then
			local self_pos		= Vector3(self_pos_raw.x,	self_pos_raw.y,		self_pos_raw.z)
			local target_pos	= Vector3(target_pos_raw.x,	target_pos_raw.y,	target_pos_raw.z + 1.5)
			local dir			= Vector3.normalize(target_pos-self_pos)
			local dist			= Vector3.length(target_pos-self_pos)
			
			if Vector3.length(dir) < 0.001 then
				-- prevents zero length dir raycast crash
				return false
			end
			
			physics_world:prepare_actors_for_raycast(self_pos, dir, 0.01, 0.5, dist*dist)
			local hit, hit_pos = physics_world:immediate_raycast(self_pos, dir, dist, "closest", "collision_filter", "filter_ai_line_of_sight_check")
			if not hit then obstructed_by_static = false end
		end
	end
	
	return not obstructed_by_static
end

