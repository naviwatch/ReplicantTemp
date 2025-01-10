local mod = get_mod("ReplicantTemp")

mod:hook(AIBotGroupSystem, "init", function (func, self, context, system_name)
	func(self, context, system_name)
	
	self._update_allies_data_timer = -math.huge
	self._update_specials_timer = -math.huge
	self._alive_specials_table = {}
end)

mod:hook(AIBotGroupSystem, "update", function (func, self, context, t)
	--[[if not self._is_server or self._total_num_bots == 0 then
		return
	end

	self._t = t
	local dt = context.dt
	local bot_threat_queue = self._bot_threat_queue

	for i = 1, #bot_threat_queue, 1 do
		local threat = bot_threat_queue[i]
		local threat_position = threat[bot_threat_queue_position]:unbox()
		local shape = threat[bot_threat_queue_shape]
		local threat_size = threat[bot_threat_queue_size]:unbox()
		local threat_rotation = threat[bot_threat_queue_rotation]:unbox()
		local threat_duration = threat[bot_threat_queue_threat_duration]

		self:aoe_threat_created(threat_position, shape, threat_size, threat_rotation, threat_duration)

		bot_threat_queue[i] = nil
	end

	self:_update_proximity_bot_breakables(t)
	self:_update_urgent_targets(dt, t)
	self:_update_opportunity_targets(dt, t)
	self:_update_existence_checks(dt, t)
	self:_update_move_targets(dt, t)
	self:_update_priority_targets(dt, t)
	self:_update_pickups(dt, t)
	self:_update_ally_needs_aid_priority()--]]
	
	func(self, context, t)
	
	self:_update_allies_data(t)
end)

local SEPARATION_CHECK_DIST = 7
AIBotGroupSystem._update_allies_data = function (self, t)
	if self._update_allies_data_timer < t then
		self._update_allies_data_timer = t + 0.15 + Math.random() * 0.1
		
		local side_manager = Managers.state.side
		local bot_ai_data = self._bot_ai_data
		local unit_alive = Unit.alive
		
		if bot_ai_data then
			for side_id = 1, #bot_ai_data, 1 do
				local side = side_manager:get_side(side_id)
				local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
				local num_players = #player_and_bot_units
				
				for i = 1, num_players, 1 do
					local player_unit 	= player_and_bot_units[i]
					local player_pos	= POSITION_LOOKUP[player_unit]
					local player_bb 	= BLACKBOARDS[player_unit]
					player_bb.separation_check_allies = {}
					
					for i = 1, num_players, 1 do
						local sep_unit 	= player_and_bot_units[i]
						local sep_pos	= POSITION_LOOKUP[sep_unit]
						local sep_dist	= player_pos and sep_pos and Vector3.distance(player_pos, sep_pos)
						
						if sep_dist and sep_dist < SEPARATION_CHECK_DIST and unit_alive(sep_unit) then
							table.insert(player_bb.separation_check_allies, sep_unit)
						end
					end
				end
			end
		end
	end
end

--[[
mod.SPECIAL_UNITS = {
	skaven_warpfire_thrower = true,
	skaven_ratling_gunner = true,
	skaven_pack_master = true,
	skaven_gutter_runner = true,
	skaven_poison_wind_globadier = true,
	chaos_vortex_sorcerer = true,
	chaos_corruptor_sorcerer = true,
	
	-- beastmen_standard_bearer = true,		--would make bots shoot it, check later

	skaven_explosive_loot_rat = true,

	curse_mutator_sorcerer = true,
	-- chaos_dummy_sorcerer = true,	--what's this???
	chaos_plague_sorcerer = true,	--what's this???
	chaos_plague_wave_spawner = true,	--what's this???
	chaos_tentacle_sorcerer = true,		--what's this???

	-- chaos_vortex = true,			--the vortex itself? don't know how to classify yet
	-- chaos_tentacle = true,		--what's this???
}

AIBotGroupSystem._update_specials = function(self, dt, t)
	local alive_specials = self._alive_specials_table
	
	if self._update_specials_timer < t then
		self._update_specials_timer = t + 0.1
		
		table.clear(alive_specials)
		
		local index = 1
		
		local conflict_director = Managers.state.conflict
		
		for breed_name, _ in pairs(mod.SPECIAL_UNITS) do
			local spawns = conflict_director._spawned_units_by_breed[breed_name]
			
			for _, unit in pairs(spawns) do
				if Unit.alive(unit) then
					alive_specials[index] = unit
					index = index + 1
				end
			end
		end
	end
	
	return alive_specials
end

local FALLBACK_OPPORTUNITY_DISTANCE = 80
local FALLBACK_OPPORTUNITY_DISTANCE_SQ = FALLBACK_OPPORTUNITY_DISTANCE^2
mod:hook(AIBotGroupSystem, "_update_opportunity_targets", function (func, self, dt, t)
	local alive_specials = self:_update_specials(dt, t)
	local num_alive_specials = #alive_specials
	local Vector3_distance_squared = Vector3.distance_squared
	local bot_ai_data = self._bot_ai_data

	for side_id = 1, #bot_ai_data, 1 do
		local side_bot_data = bot_ai_data[side_id]

		for bot_unit, data in pairs(side_bot_data) do
			local best_utility = -math.huge
			local best_target = nil
			local best_distance = math.huge
			local blackboard = data.blackboard
			local self_pos = POSITION_LOOKUP[bot_unit]
			local old_target = blackboard.opportunity_target_enemy
			local side = blackboard.side

			for i = 1, num_alive_specials, 1 do
				local target_unit = alive_specials[i]
				local opportunity_target_blackboard = BLACKBOARDS[target_unit]
				
				if target_unit and Unit.alive(target_unit) and opportunity_target_blackboard then
					local ignore_bot_opportunity = opportunity_target_blackboard.breed.ignore_bot_opportunity
					local target_pos = POSITION_LOOKUP[target_unit]

					if not ignore_bot_opportunity and Vector3_distance_squared(target_pos, self_pos) < FALLBACK_OPPORTUNITY_DISTANCE_SQ then
						local utility, distance = self:_calculate_opportunity_utility(bot_unit, blackboard, self_pos, old_target, target_unit, t, false, true)

						if best_utility < utility then
							best_utility = utility
							best_target = target_unit
							best_distance = distance
						end
					end
				end
			end

			local VALID_ENEMY_TARGETS_PLAYERS_AND_BOTS = side.VALID_ENEMY_TARGETS_PLAYERS_AND_BOTS

			for target_unit, is_valid in pairs(VALID_ENEMY_TARGETS_PLAYERS_AND_BOTS) do
				if is_valid then
					local ghost_mode_ext = ScriptUnit.has_extension(target_unit, "ghost_mode_system")

					if not ghost_mode_ext or not ghost_mode_ext:is_in_ghost_mode() then
						local target_pos = POSITION_LOOKUP[target_unit]

						if Unit.alive(target_unit) and Vector3_distance_squared(target_pos, self_pos) < FALLBACK_OPPORTUNITY_DISTANCE_SQ then
							local utility, distance = self:_calculate_opportunity_utility(bot_unit, blackboard, self_pos, old_target, target_unit, t, false, true)

							if best_utility < utility then
								best_utility = utility
								best_target = target_unit
								best_distance = distance
							end
						end
					end
				end
			end

			blackboard.opportunity_target_enemy = best_target
			blackboard.opportunity_target_distance = best_distance
		end
	end
end)

local BOSS_ENGAGE_DISTANCE = 25
local BOSS_ENGAGE_DISTANCE_SQ = BOSS_ENGAGE_DISTANCE^2
mod:hook_origin(AIBotGroupSystem, "_update_urgent_targets", function(self, dt, t)
	local conflict_director = Managers.state.conflict
	local alive_bosses = conflict_director:alive_bosses()
	
	local num_alive_bosses = #alive_bosses
	local bot_ai_data = self._bot_ai_data
	local urgent_targets = self._urgent_targets

	for side_id = 1, #bot_ai_data, 1 do
		local side_bot_data = bot_ai_data[side_id]

		for bot_unit, data in pairs(side_bot_data) do
			local best_utility = -math.huge
			local best_target = nil
			local best_distance = math.huge
			local blackboard = data.blackboard
			local self_pos = POSITION_LOOKUP[bot_unit]
			local old_target = blackboard.urgent_target_enemy
			
			--local career_extension = blackboard and blackboard.career_extension
			--local career_name = career_extension and career_extension:career_name()
			--local is_boss_killer = career_name and boss_killers[career_name]

			for target_unit, is_target_until in pairs(urgent_targets) do
				local time_left = is_target_until - t

				if time_left > 0 then
					if Unit.alive(target_unit) then
						local utility, distance = self:_calculate_opportunity_utility(bot_unit, blackboard, self_pos, old_target, target_unit, t, false, false)

						if best_utility < utility then
							best_utility = utility
							best_target = target_unit
							best_distance = distance
						end
					else
						urgent_targets[target_unit] = nil
					end
				else
					urgent_targets[target_unit] = nil
				end
			end

			if not best_target then
				for j = 1, num_alive_bosses, 1 do
					local target_unit = alive_bosses[j]
					local pos = POSITION_LOOKUP[target_unit]

					if Unit.alive(target_unit) and not AiUtils.unit_invincible(target_unit) and Vector3.distance_squared(pos, self_pos) < BOSS_ENGAGE_DISTANCE_SQ and not BLACKBOARDS[target_unit].defensive_mode_duration then
						local utility, distance = self:_calculate_opportunity_utility(bot_unit, blackboard, self_pos, old_target, target_unit, t, false, false)

						if best_utility < utility then
							best_utility = utility
							best_target = target_unit
							best_distance = distance
						end
					end
				end
			end

			blackboard.revive_with_urgent_target = best_target and self:_can_revive_with_urgent_target(bot_unit, self_pos, blackboard, best_target, t)
			blackboard.urgent_target_enemy = best_target
			blackboard.urgent_target_distance = best_distance
			local hit_by_projectile = blackboard.hit_by_projectile

			for attacking_unit, _ in pairs(hit_by_projectile) do
				if not Unit.alive(attacking_unit) then
					hit_by_projectile[attacking_unit] = nil
				end
			end
		end
	end
end)
--]]

local EPSILON = 0.01
local function detect_cylinder(nav_world, traverse_logic, bot_position, bot_height, bot_radius, x, y, z, rotation, size)
	local bot_x = bot_position.x
	local bot_y = bot_position.y
	local bot_z = bot_position.z
	local offset_x = bot_x - x
	local offset_y = bot_y - y
	local flat_dist_from_center = math.sqrt(offset_x * offset_x + offset_y * offset_y)
	local radius = math.max(size.x, size.y)
	local half_height = size.z

	if flat_dist_from_center <= radius + bot_radius and bot_z > z - bot_height - half_height and bot_z < z + half_height then
		local escape_dist = radius - flat_dist_from_center
		local escape_dir = nil

		if flat_dist_from_center < EPSILON then
			escape_dir = Vector3(0, 1, 0)
		else
			escape_dir = Vector3(offset_x / flat_dist_from_center, offset_y / flat_dist_from_center, 0)
		end

		local to = bot_position + escape_dir * escape_dist
		local above = 2
		local below = 2
		local success, z = GwNavQueries.triangle_from_position(nav_world, to, above, below)

		if not success then
			return
		end

		to.z = z
		success = GwNavQueries.raycango(nav_world, bot_position, to, traverse_logic)

		if success then
			return to
		end
	end
end

local function detect_sphere(nav_world, traverse_logic, bot_position, bot_height, bot_radius, sphere_x, sphere_y, sphere_z, rotation, sphere_radius)
	local bot_x = bot_position.x
	local bot_y = bot_position.y
	local bot_z = bot_position.z
	local offset_x = bot_x - sphere_x
	local offset_y = bot_y - sphere_y
	local flat_dist_from_center = math.sqrt(offset_x * offset_x + offset_y * offset_y)

	if flat_dist_from_center > sphere_radius + bot_radius then
		return
	elseif bot_z < sphere_z + sphere_radius and bot_z > sphere_z - bot_height - sphere_radius then
		local escape_dist = sphere_radius - flat_dist_from_center
		local escape_dir = nil

		if flat_dist_from_center < EPSILON then
			escape_dir = Vector3(0, 1, 0)
		else
			escape_dir = Vector3(offset_x / flat_dist_from_center, offset_y / flat_dist_from_center, 0)
		end

		local to = bot_position + escape_dir * escape_dist
		local above = 2
		local below = 2
		local success, z = GwNavQueries.triangle_from_position(nav_world, to, above, below)

		if not success then
			return
		end

		to.z = z
		success = GwNavQueries.raycango(nav_world, bot_position, to, traverse_logic)

		if success then
			return to
		end
	end
end

local function detect_oobb(nav_world, traverse_logic, bot_position, bot_height, bot_radius, x, y, z, rotation, extents)
	local half_bot_height = bot_height * 0.5
	local offset = bot_position - Vector3(x, y, z - half_bot_height)
	local right_vector = Quaternion.right(rotation)
	local x_offset = Vector3.dot(right_vector, offset)
	local y_offset = Vector3.dot(Quaternion.forward(rotation), offset)
	local z_offset = Vector3.dot(Quaternion.up(rotation), offset)
	local extents_x = extents.x + bot_radius
	local extents_y = extents.y + bot_radius
	local extents_z = extents.z + half_bot_height

	if extents_x < x_offset or x_offset < -extents_x or extents_y < y_offset or y_offset < -extents_y or extents_z < z_offset or z_offset < -extents_z then
		return
	end

	local area_damage_system = Managers.state.entity:system("area_damage_system")
	local above = 2
	local below = 2
	local sign = (x_offset == 0 and 1 - math.random(0, 1) * 2) or math.sign(x_offset)
	local stop_at = nil
	local right_offset = x_offset * right_vector
	local right_extent = (bot_radius + extents_x) * right_vector

	for i = 1, 2, 1 do
		local to = bot_position - right_offset + sign * right_extent
		local on_nav_mesh, z = GwNavQueries.triangle_from_position(nav_world, to, above, below)

		if on_nav_mesh then
			to.z = z
		end

		local raycango = on_nav_mesh and GwNavQueries.raycango(nav_world, bot_position, to, traverse_logic)

		if raycango then
			local in_liquid = area_damage_system:is_position_in_liquid(to, BotNavTransitionManager.NAV_COST_MAP_LAYERS)

			if not in_liquid or stop_at == nil then
				stop_at = to

				if not in_liquid then
					break
				end
			end
		end

		sign = -sign
	end

	return stop_at
end

mod:hook_origin(AIBotGroupSystem, "aoe_threat_created", function (self, position, shape, size, rotation, duration, best_escape_direction, block_requirements)
	local bot_radius = 1.25
	local bot_height = 1.8
	local t = Managers.time:time("game")
	local nav_world = Managers.state.entity:system("ai_system"):nav_world()
	local traverse_logic = Managers.state.bot_nav_transition:traverse_logic()
	local detect_func = nil

	if shape == "oobb" then
		detect_func = detect_oobb
	elseif shape == "cylinder" then
		detect_func = detect_cylinder
	elseif shape == "sphere" then
		detect_func = detect_sphere
	end

	local pos_x = position.x
	local pos_y = position.y
	local pos_z = position.z
	local bot_ai_data = self._bot_ai_data

	if bot_ai_data then
		for side_id = 1, #bot_ai_data, 1 do
			local side_bot_data = bot_ai_data[side_id]

			for unit, data in pairs(side_bot_data) do
				local threat_data = data.aoe_threat
				local expires = t + duration

				if threat_data.expires < expires then
					local escape_to = detect_func(nav_world, traverse_logic, POSITION_LOOKUP[unit], bot_height, bot_radius, pos_x, pos_y, pos_z, rotation, size)
					
					if escape_to then
						threat_data.expires = expires

						threat_data.escape_to:store(escape_to)
					end
				end
				
				if not block_requirements then
					threat_data.can_block = true
				elseif block_requirements == "shield" then
					local has_shield = DialogueSystem:player_shield_check(unit, "slot_melee") == 1 or DialogueSystem:player_shield_check(unit, "slot_ranged") == 1
					threat_data.can_block = has_shield
				elseif block_requirements == "no_block" then
					threat_data.can_block = false
				end
				
				if rotation then
					local forward = Quaternion.rotate(rotation, Vector3.forward()) * size.y
					local up = Vector3.up() * size.z
					
					local source_pos = position - forward - up
					source_pos.z = source_pos.z + 1.25
					
					threat_data.source_pos = Vector3Box(source_pos)
				else
					threat_data.source_pos = nil
				end
				
				threat_data.best_escape_direction = best_escape_direction
			end
		end
	end
end)

---------------------------------------

--Add some random lower bound to special detection

local potential_target_first_check = {}

local OPPORTUNITY_TARGET_MIN_REACTION_TIME = 0.2
local OPPORTUNITY_TARGET_MAX_REACTION_TIME = 0.65
local OPPORTUNITY_TARGET_DIFFICULTY_REACTION_TIMES = BotConstants.default.OPPORTUNITY_TARGET_REACTION_TIMES

mod:hook_origin(AIBotGroupSystem, "_calculate_opportunity_utility", function (self, bot_unit, bot_blackboard, self_position, current_target, potential_target, t, force_seen, use_difficulty_reaction_times)
	local side = bot_blackboard.side

	if not side.enemy_units_lookup[potential_target] then
		return -math.huge, math.huge
	end

	local prox_ext = ScriptUnit.has_extension(potential_target, "proximity_system")
	local distance = math.max(Vector3.distance(self_position, POSITION_LOOKUP[potential_target]), 1)

	if prox_ext and not prox_ext.has_been_seen and not force_seen then
		--edit start--
		-- return -math.huge, math.huge
		
		if not potential_target_first_check[potential_target] or not potential_target_first_check[potential_target][bot_unit] then
			-- local min_reaction_time, max_reaction_time = nil

			-- if use_difficulty_reaction_times then
				-- local current_difficulty = Managers.state.difficulty:get_difficulty()
				-- local reaction_times = OPPORTUNITY_TARGET_DIFFICULTY_REACTION_TIMES[current_difficulty]
				-- min_reaction_time = reaction_times.min
				-- max_reaction_time = reaction_times.max
			-- else
				-- min_reaction_time = OPPORTUNITY_TARGET_MIN_REACTION_TIME
				-- max_reaction_time = OPPORTUNITY_TARGET_MAX_REACTION_TIME
			-- end
			
			-- potential_target_first_check[potential_target] = {}
			-- potential_target_first_check[potential_target][bot_unit] = t + 15 * Math.random(min_reaction_time, max_reaction_time)
			
			potential_target_first_check[potential_target] = {}
			potential_target_first_check[potential_target][bot_unit] = t + math.random(7.5, 15)
			
			return -math.huge, math.huge
		elseif t < potential_target_first_check[potential_target][bot_unit] then
			return -math.huge, math.huge
		end
		--edit end--
	elseif prox_ext then
		local react_at = prox_ext.bot_reaction_times[bot_unit]

		if not react_at then
			--local min_reaction_time, max_reaction_time = nil

			--if use_difficulty_reaction_times then
			--	local current_difficulty = Managers.state.difficulty:get_difficulty()
			--	local reaction_times = OPPORTUNITY_TARGET_DIFFICULTY_REACTION_TIMES[current_difficulty]
			--	min_reaction_time = reaction_times.min
			--	max_reaction_time = reaction_times.max
			--else
			--	min_reaction_time = 0.65
			--	max_reaction_time = 0.2
			--end
			
			--edit start--
			--prox_ext.bot_reaction_times[bot_unit] = t + Math.random(min_reaction_time, max_reaction_time)
			
			local reaction_time = math.random(0.2, 0.65)
			if potential_target_first_check[potential_target] and potential_target_first_check[potential_target][bot_unit] and t < potential_target_first_check[potential_target][bot_unit] then
				local remaining_time = potential_target_first_check[potential_target][bot_unit] - t
				reaction_time = math.min(reaction_time, remaining_time)
			end
			
			prox_ext.bot_reaction_times[bot_unit] = t + reaction_time
			--edit end--

			return -math.huge, math.huge
		elseif t < react_at then
			return -math.huge, math.huge
		end
	end

	local stickyness_modifier = (potential_target == current_target and STICKYNESS_DISTANCE_MODIFIER) or 0
	local proximity = 1 / (distance + stickyness_modifier)

	return proximity, distance
end)

