local mod = get_mod("ReplicantTemp")

local is_positioned_between_self_and_ally = function(self_unit, ally_unit, enemy_unit)		-- check if the enemy unit is positioned between self and ally
	if self_unit and ally_unit and enemy_unit then
		local self_pos	= POSITION_LOOKUP[self_unit]
		local ally_pos	= POSITION_LOOKUP[ally_unit]
		local enemy_pos	= POSITION_LOOKUP[enemy_unit]
		if self_pos and ally_pos and enemy_pos then
			local ally_dist = Vector3.distance(self_pos, ally_pos)
			local zone_dist = math.sqrt((ally_dist^2) + (2^2)) + 2
			
			local self_to_enemy_dist = Vector3.distance(self_pos, enemy_pos)
			local ally_to_enemy_dist = Vector3.distance(ally_pos, enemy_pos)
			
			if self_to_enemy_dist < ally_dist and ally_to_enemy_dist < ally_dist and (self_to_enemy_dist + ally_to_enemy_dist) < zone_dist then
				-- the enemy is positioned between self and ally
				return true
			end
		end
	end
	
	return false
end

local unit_alive = Unit.alive
local BLACKBOARDS = BLACKBOARDS
local PROXIMITY_CHECK_RANGE = 15
local PROXIMITY_CHECK_RANGE_ALLY_NEEDS_AID = 10
local PROXIMITY_CHECK_RANGE_ALLY_NEEDS_AID_REVIVING = 8
local PROXIMITY_CHECK_RANGE_ALLY_NEEDS_AID_SUPPORT = 15
local STICKYNESS_DISTANCE_MODIFIER = 0-- -0.2	--using the declaration in the "_update_target_enemy"
local FOLLOW_TIMER_LOWER_BOUND = 1
local FOLLOW_TIMER_UPPER_BOUND = 1.5
local ENEMY_PATH_FAILED_REPATH_THRESHOLD = 9
local ENEMY_PATH_FAILED_REPATH_VERTICAL_THRESHOLD = 0.8
local FLAT_MOVE_TO_EPSILON = BotConstants.default.FLAT_MOVE_TO_EPSILON
local Z_MOVE_TO_EPSILON = BotConstants.default.Z_MOVE_TO_EPSILON
local HOLD_POSITION_MAX_ALLOWED_Z = 0.5
local VORTEX_SAFE_PATH_CHECK_DISTANCE = 15
local MIN_ALLOWED_VORTEX_DISTANCE = 2

mod:hook(PlayerBotBase, "init", function (func, self, extension_init_context, unit, extension_init_data)
	func(self, extension_init_context, unit, extension_init_data)
	
	self._blackboard.separation_check_allies = {}
	
	self._num_broadphase_hits = 0
	
	self._update_liquid_escape_destination_timer = 0
end)

local assigned_enemies = {}
mod:hook(PlayerBotBase, "update", function (func, self, unit, input, dt, context, t)
	self._t = t
	local health_extension = self._health_extension
	local status_extension = self._status_extension
	local locomotion_extension = self._locomotion_extension
	local is_alive = health_extension:is_alive()
	local is_ready_for_assisted_respawn = status_extension:is_ready_for_assisted_respawn()
	local is_linked_movement = locomotion_extension:is_linked_movement()

	if is_alive and not is_ready_for_assisted_respawn and not is_linked_movement then
		--SELF_UNIT = unit

		self:_update_blackboard(dt, t)
		self:_update_swarm_projectiles(dt, t)
		self:_update_ability_conditions(t)
		self:_update_target_enemy(dt, t)
		self:_update_assigned_enemies(dt, t)
		self:_update_target_ally(dt, t)
		self:_update_liquid_escape(t)
		self:_update_vortex_escape()
		self:_update_pickups(dt, t)
		self:_update_interactables(dt, t)
		self:_update_weapon_loadout_data()
		self:_update_best_weapon()
		self._brain:update(unit, t, dt)

		local moving_platform = locomotion_extension:get_moving_platform()
		local is_disabled = status_extension:is_disabled()

		if is_disabled or moving_platform then
			self._navigation_extension:teleport(POSITION_LOOKUP[unit])
		elseif locomotion_extension:is_on_ground() then
			self:_update_movement_target(dt, t)
		end

		self:_update_attack_request(t)
	end
end)

local has_buffs = function(buffs, self_unit, t)
	local buff_extension = ScriptUnit.extension(self_unit, "buff_system")
	local ability_buff = nil
	local num_buffs = #buffs
	
	for i = 1, num_buffs, 1 do
		local buff_name = buffs[i]
		ability_buff = buff_extension:get_buff_type(buff_name) -- buff_extension:get_non_stacking_buff(buff_name)
		
		if ability_buff then
			break
		end
	end
	
	if ability_buff then
		local end_time = ability_buff.end_time or (ability_buff.start_time and ability_buff.duration and ability_buff.start_time + ability_buff.duration) -- was only ability_buff.end_time
		
		if end_time and t <= end_time then
			return true
		end
	end
	
	return false
end

local career_buffs = {
	dr_ranger = "bardin_activate_ranger",
	bw_adept = "sienna_activate_adept",
	bw_unchained = "sienna_activate_unchained",
	dr_slayer = "bardin_activate_slayer",
	es_huntsman = "markus_activate_huntsman",
	we_maidenguard = "kerillian_activate_maiden_guard",
	we_shade = "kerillian_activate_shade",
	wh_zealot = "victor_activate_zealot"
}

local has_ability_buff = function(blackboard)
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	
	local state = career_extension:get_state()
	
	return state == career_buffs[career_name] -- state ~= "default" - returns true when bot is in bardin ranger's smoke
end

local set_post_effects = function(blackboard, post_effects, value)
	for i = 1, #post_effects, 1 do
		local effect_name = post_effects[i]
		blackboard[effect_name] = value
	end
end

PlayerBotBase._update_ability_conditions = function(self, t)
	local blackboard = self._blackboard
	local post_effects = blackboard.ability_post_effects
	
	if not post_effects then
		return
	end
	
	if not post_effects.start_time then
		post_effects.start_time = t
	end
	
	local end_condition = post_effects.end_condition
	
	if post_effects.start_time + end_condition.duration < t and not blackboard._ability_post_effects_applied then
		set_post_effects(blackboard, post_effects, nil)
		blackboard.ability_post_effects = nil
		return
	end
	
	local ability_buffs = end_condition.ability_buffs
	local buffs_on = not ability_buffs or has_ability_buff(blackboard) or (#ability_buffs > 0 and has_buffs(ability_buffs, blackboard.unit, t))
	
	if buffs_on and not blackboard._ability_post_effects_applied then
		set_post_effects(blackboard, post_effects, true)
		
		blackboard._ability_post_effects_applied = true
	elseif not buffs_on and blackboard._ability_post_effects_applied then
		set_post_effects(blackboard, post_effects, false)
		
		blackboard._ability_post_effects_applied = false
	end
end

mod:hook(PlayerBotBase, "_update_blackboard", function (func, self, dt, t)
	-- if not mod.components.aggro_tweaks.value then
		-- return func(self, dt, t)
	-- end
	
	local bb = self._blackboard
	local status_extension = self._status_extension
	local locomotion_extension = self._locomotion_extension
	bb.is_dead = status_extension:is_dead()
	bb.is_knocked_down = status_extension:is_knocked_down()
	bb.is_grabbed_by_pack_master = status_extension:is_grabbed_by_pack_master()
	bb.is_pounced_down = status_extension:is_pounced_down()
	bb.is_hanging_from_hook = status_extension:is_hanging_from_hook()
	bb.is_ledge_hanging = status_extension:get_is_ledge_hanging()
	bb.is_transported = status_extension:is_using_transport() or locomotion_extension:get_moving_platform()
	bb.is_ready_for_assisted_respawn = status_extension:is_ready_for_assisted_respawn()
	bb.is_grabbed_by_tentacle = status_extension:is_grabbed_by_tentacle()
	bb.is_in_vortex = status_extension:is_in_vortex()
	bb.is_grabbed_by_corruptor = status_extension:is_grabbed_by_corruptor()
	bb.is_overpowered = status_extension:is_overpowered()
	--local unit = self._unit
	--local target_unit = bb.target_unit

	--if ALIVE[target_unit] then
	--	bb.target_dist = Vector3.distance(POSITION_LOOKUP[target_unit], POSITION_LOOKUP[unit])
	--else
	--	bb.target_dist = math.huge
	--	bb.target_unit = nil
	--end

	for _, action_data in pairs(bb.utility_actions) do
		action_data.time_since_last = t - action_data.last_time
	end
end)

PlayerBotBase._update_assigned_enemies = function(self, dt, t)
	local blackboard = self._blackboard
	local self_unit = self._unit
	
	-- clean assigned enemies table
	-- make sure there is no enemies that are assigned to non-active bots (happens when player joins mid combat)
	for key, assigned_unit in pairs(assigned_enemies) do
		if assigned_unit == self_unit then
			assigned_enemies[key] = nil
		else
			local assigned_to_inactive_bot = true
			
			--[[for _, loop_owner in pairs(active_bots) do
				local loop_unit			= loop_owner.player_unit
				-- local loop_d			= get_d_data(loop_unit)
				
				-- local loop_is_disabled	= not loop_d or loop_d.disabled
				local status_extension = ScriptUnit.has_extension(loop_unit, "status_system")
				local loop_is_disabled = (status_extension and status_extension:is_disabled()) or false
				
				if assigned_unit == loop_unit and not loop_is_disabled then
					assigned_to_inactive_bot = false
					break
				end
			end--]]
			
			local status_extension = ScriptUnit.has_extension(self_unit, "status_system")
			local is_disabled = (status_extension and status_extension:is_disabled()) or false
			
			-- the enemy has disabled bot assigned to it >> remove the assignement
			if is_disabled then --assigned_to_inactive_bot then
				assigned_enemies[key] = nil
			end
		end
	end
	
	-- assign self to current target enemy
	if blackboard.target_unit then
		assigned_enemies[blackboard.target_unit] = self_unit
	end
end

-- local STICKYNESS_DISTANCE_MODIFIER = -0.2

local function is_shade_in_invis(career_name, self_unit)
	if career_name == "we_shade" then
		local buff_extension = ScriptUnit.extension(self_unit, "buff_system")
		local ability_buff = nil
		
		local shade_buffs = {
			"kerillian_shade_activated_ability",
			"kerillian_shade_activated_ability_duration"
		}
		local num_buffs = #shade_buffs
		
		for i = 1, num_buffs, 1 do
			local buff_name = shade_buffs[i]
			ability_buff = buff_extension:get_non_stacking_buff(buff_name)
			
			if ability_buff then
				break
			end
		end
		
		if not ability_buff then
			ability_buff = buff_extension:get_buff_type("kerillian_shade_ult_invis") or buff_extension:get_buff_type("kerillian_shade_activated_ability_restealth")
		end
		
		if ability_buff then
			return true
		end
	end
	
	return false
end

--[[local function get_players_in_range_from_pos(pos, distance)
	local players_in_range = {}
	
	local players = Managers.player:players()
	
	for _, player in pairs(players) do
		local player_unit	= player.player_unit
		local player_pos	= POSITION_LOOKUP[player_unit]
		local player_dist	= pos and player_pos and Vector3.distance(pos, player_pos)
		
		if player_dist and player_dist < distance and Unit.alive(loop_unit) then
			table.insert(players_in_range, player_unit)
		end
	end
	
	return players_in_range
end--]]

local function summary_distance_to_players(pos)
	local summary_distance = 0
	
	local players = Managers.player:players()
	
	for _, player in pairs(players) do
		local player_unit = player.player_unit
		
		if Unit.alive(player_unit) then
			local player_pos = POSITION_LOOKUP[player_unit]
			local player_dist = (player_pos and pos and Vector3.length(pos - player_pos)) or 0
			summary_distance = summary_distance + player_dist
		end
	end
	
	return summary_distance
end

local is_patrol_member = function(unit)
	local ai_group_system = Managers.state.entity:system("ai_group_system")
	
	if ai_group_system.groups_to_update then
		for id, group in pairs(ai_group_system.groups_to_update) do
			if group.group_type == "spline_patrol" and group.members then
				return group.members[unit]
			end
		end
	end
end

PlayerBotBase._target_valid = function (self, blackboard, unit, enemy_offset)
	if not blackboard or not unit or not enemy_offset or not Unit.alive(unit) or not blackboard.breed or blackboard.breed.not_bot_target then
		return false
	end

	if ScriptUnit.has_extension(unit, "ai_group_system") and (not blackboard.target_unit and is_patrol_member(unit)) then
		return false
	end
	
	--local up_dot_product = Vector3.dot(Vector3.up(), Vector3.normalize(enemy_offset))

	--if PROXIMITY_UP_DOWN_THRESHOLD < up_dot_product or up_dot_product < -PROXIMITY_UP_DOWN_THRESHOLD then
	--	return false
	--end

	return true
end

--[[PlayerBotBase._target_valid = function (self, unit, enemy_offset)
	local blackboard = BLACKBOARDS[unit]

	if not blackboard or blackboard.breed.not_bot_target then
		return false
	end

	if ScriptUnit.has_extension(unit, "ai_group_system") and not blackboard.target_unit then
		return false
	end

	local up_dot_product = Vector3.dot(Vector3.up(), Vector3.normalize(enemy_offset))

	if PROXIMITY_UP_DOWN_THRESHOLD < up_dot_product or up_dot_product < -PROXIMITY_UP_DOWN_THRESHOLD then
		return false
	end

	return true
end--]]

local DIST_TRESHOLD = 5
local function ClosestEnemyStructure()
	local unit = nil
	local real_dist = math.huge
	local distance = math.huge
	local is_optimal_target = false
	
	return {
		unit = function() return unit end;
		real_dist = function() return real_dist end;
		distance = function() return distance end;
		is_optimal_target = function() return is_optimal_target end;
		UpdateEnemy = function(new_unit, new_real_dist, new_distance, new_is_optimal_target)
			local new_is_less_optimal = is_optimal_target and not new_is_optimal_target
			
			if new_is_less_optimal then
				return
			end
			
			local distance_difference = nil
			
			if new_distance then
				distance_difference = distance - new_distance
			elseif new_real_dist then
				distance_difference = real_dist - new_real_dist
			end
			
			if distance_difference > (not new_is_less_optimal and 0 or DIST_TRESHOLD) then
				unit = new_unit
				real_dist = new_real_dist
				distance = new_distance
				is_optimal_target = new_is_optimal_target
			end
		end
	}
end

PlayerBotBase.update_separating_targets = function(self, closest_separating, enemy_unit, enemy_real_dist, enemy_dist)
	local self_unit = self._unit
	local blackboard = self._blackboard
	
	for _, separation_check_unit in pairs(blackboard.separation_check_allies) do
		local is_separation_threat = is_positioned_between_self_and_ally(self_unit, separation_check_unit, enemy_unit)
		
		if is_separation_threat then
			closest_separating.UpdateEnemy(enemy_unit, enemy_real_dist, enemy_dist)
		end
	end
end

PlayerBotBase.choose_best_broadphase_targets = function(self, self_pos, broadphase_query)
	local self_unit = self._unit
	local blackboard = self._blackboard
	
	local prox_enemies = blackboard.proximite_enemies
	local index = 1
	
	table.clear(prox_enemies)
	
	local closest_enemy	 	= ClosestEnemyStructure()
	local best_elite 	 	= ClosestEnemyStructure()
	local best_trash		= ClosestEnemyStructure()
	local best_separating 	= ClosestEnemyStructure()
	
	for i = 1, self._num_broadphase_hits, 1 do
		local enemy_unit 	= broadphase_query[i]	
		local enemy_bb		= BLACKBOARDS[enemy_unit]
		local enemy_pos		= POSITION_LOOKUP[enemy_unit]
		local enemy_offset	= enemy_pos and self_pos and enemy_pos - self_pos
		
		if self:_target_valid(enemy_bb, enemy_unit, enemy_offset) then
			local enemy_breed		= Unit.get_data(enemy_unit, "breed")
			local enemy_real_dist	= Vector3.length(enemy_offset)
			local enemy_dist		= enemy_real_dist
			
			local abs_z_offset 		= math.abs(enemy_offset.z)
			local height_modifier	= (abs_z_offset > 0.2) and (0.75 * abs_z_offset) or 0
			local enemy_is_after_me	= enemy_bb and (enemy_bb.target_unit == self_unit or enemy_bb.attacking_target == self_unit)
			
			enemy_dist = enemy_dist + summary_distance_to_players(enemy_pos) * 0.05   -- add some extra to the check distance of enemies that are far away from other players to encourage the bots not to spread out too wide
			enemy_dist = enemy_dist + height_modifier								  -- if the target is above / below past a threashold then it should be less attractive than targets on the same plane.
			
			local is_elite = mod.ELITE_UNITS[enemy_breed.name] or mod.BERSERKER_UNITS[enemy_breed.name]
			local is_trash = mod.TRASH_UNITS[enemy_breed.name]
			-- local is_boss = (mod.BOSS_UNITS[enemy_breed.name] and not mod.LORD_UNITS[enemy_breed.name]) or enemy_breed.name == "chaos_spawn_exalted_champion_norsca"
			local is_boss = mod.BOSS_AND_LORD_UNITS[enemy_breed.name]
			local can_be_assigned = not assigned_enemies[enemy_unit] or assigned_enemies[enemy_unit] == self_unit or enemy_is_after_me
			
			if is_elite then
				--mod:echo(blackboard.career_extension:career_name())
				best_elite.UpdateEnemy(enemy_unit, enemy_real_dist, enemy_dist, can_be_assigned)
				
			elseif is_trash or (enemy_breed.name == "skaven_loot_rat" and enemy_dist < 5) then	
				
				if enemy_bb.attacking_target == self_unit and not enemy_bb.past_damage_in_attack then
					enemy_dist = enemy_dist - 0.5		--1
				end
				
				best_trash.UpdateEnemy(enemy_unit, enemy_real_dist, enemy_dist, can_be_assigned)
				
			end	-- specials / ogres are handled separately
			
			
			if not is_boss then  -- find group separation threats; separation threat can be any non-boss enemy unit that is positioned between team members
				self:update_separating_targets(best_separating, enemy_unit, enemy_real_dist, enemy_dist)
			end
			
			if enemy_real_dist < PROXIMITY_CHECK_RANGE then
				closest_enemy.UpdateEnemy(enemy_unit, enemy_real_dist)
				
				prox_enemies[index] = enemy_unit
				index = index + 1
			end
		end
	end
	
	blackboard.proximity_target_enemy = closest_enemy.unit()
	blackboard.proximity_target_distance = closest_enemy.real_dist()
	
	blackboard.elite_target_enemy = best_elite.unit()
	blackboard.elite_target_distance = best_elite.real_dist()
	
	blackboard.trash_target_enemy = best_trash.unit()
	blackboard.trash_target_distance = best_trash.real_dist()
	
	blackboard.separating_target_enemy = best_separating.unit()
	blackboard.separating_target_distance = best_separating.real_dist()
end

mod.swarm_projectile_list = {}

mod:hook(UnitSpawner, "spawn_network_unit", function(func, self, unit_name, unit_template_name, extension_init_data, position, rotation, material)
	local unit, go_id = func(self, unit_name, unit_template_name, extension_init_data, position, rotation, material)

	if unit_name == "units/weapons/projectile/insect_swarm_missile/insect_swarm_missile_01" or
		unit_name == "units/weapons/projectile/insect_swarm_missile_drachenfels/insect_swarm_missile_drachenfels_01" or
		unit_name == "units/props/blk/blk_curse_shadow_homing_skull_01" or	--need testing
		unit_name == "units/beings/enemies/undead_ethereal_skeleton/chr_undead_ethereal_skeleton_skull" then	--need testing
		
		mod.swarm_projectile_list[unit] = true
	end

	return unit, go_id
end)

PlayerBotBase._update_swarm_projectiles = function(self, dt, t)
	local self_pos = POSITION_LOOKUP[self._unit]
	local blackboard = self._blackboard
	
	local closest_swarm_projectile = ClosestEnemyStructure()
		
	for proj_unit, _ in pairs(mod.swarm_projectile_list) do
		if not Unit.alive(proj_unit) then
			mod.swarm_projectile_list[proj_unit] = nil
		else
			local proj_locomotion_extension = ScriptUnit.extension(proj_unit, "projectile_locomotion_system")
			-- local proj_pos = Unit.local_position(proj_unit, 0) or POSITION_LOOKUP[proj_unit]
			local proj_pos = (proj_locomotion_extension and proj_locomotion_extension.current_position and proj_locomotion_extension:current_position()) or POSITION_LOOKUP[proj_unit] or Unit.world_position(proj_unit, 0)
			local proj_offset = self_pos and proj_pos and proj_pos - self_pos
			local proj_dist	= proj_offset and Vector3.length(proj_offset)
			
			closest_swarm_projectile.UpdateEnemy(proj_unit, proj_dist)
		end
	end
	
	blackboard.closest_swarm_projectile_unit = closest_swarm_projectile.unit()
	blackboard.closest_swarm_projectile_dist = closest_swarm_projectile.real_dist()
end

local function get_enemies_in_range(enemies, pos, distance_sq)
	local ret = {}
	local index = 1
	
	for i = 1, #enemies, 1 do
		local enemy_unit = enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(pos, enemy_position) or math.huge

		if enemy_distance_sq <= distance_sq then
			ret[index] = enemy_unit
			index = index + 1
		end
	end
	
	return ret
end

-- not revised in a normal way, just perfunctory changes in order to other things
mod:hook(PlayerBotBase, "_update_target_enemy", function(func, self, dt, t)
	local self_pos = POSITION_LOOKUP[self._unit]

	self:_update_slot_target(dt, t, self_pos)
	self:_update_proximity_target(dt, t, self_pos)
	
	local bb = self._blackboard
	local self_unit = self._unit
	local career_extension = bb.career_extension
	local is_using_ability = bb.activate_ability_data.is_using_ability
	local career_name = career_extension:career_name()
	
	local old_target = bb.target_unit
	local slot_enemy = bb.slot_target_enemy
	local prox_enemy = bb.proximity_target_enemy
	local priority_enemy = bb.priority_target_enemy
	local urgent_enemy = bb.urgent_target_enemy
	local opportunity_enemy = bb.opportunity_target_enemy
	local near_enemies = get_enemies_in_range(bb.proximite_enemies, self_pos, 25)
	local num_near_enemies = #near_enemies
	
	local STICKYNESS_DISTANCE_MODIFIER = -0.05
	
	-- if bb.shoot and bb.shoot.charging_shot then
		-- STICKYNESS_DISTANCE_MODIFIER = -3	
	-- end
	
	local prox_enemy_dist = bb.proximity_target_distance + ((prox_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local prio_enemy_dist = bb.priority_target_distance + ((priority_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local urgent_enemy_dist = bb.urgent_target_distance + ((urgent_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local opp_enemy_dist = bb.opportunity_target_distance + ((opportunity_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local slot_enemy_dist = math.huge
	
	if slot_enemy then
		slot_enemy_dist = Vector3.length(POSITION_LOOKUP[slot_enemy] - self_pos) + ((slot_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	end
	
	local urgent_breed = urgent_enemy and Unit.get_data(urgent_enemy, "breed") 
	local urgent_is_boss = urgent_breed and urgent_breed.boss or false
	
	local opportunity_los		= mod.check_line_of_sight(self_unit, opportunity_enemy)
	local urgent_flanking		= mod.check_alignment_to_target(self_unit, urgent_enemy)
	local urgent_bb				= BLACKBOARDS[urgent_enemy]
	local urgent_targeting_me	= (urgent_bb and urgent_bb.target_unit == self_unit) or false
	
	--local active_bots			= Managers.player:bots()
	--local bot_count				= #active_bots
		
	local blackboard				= self._blackboard
	local inventory_extension 		= blackboard.inventory_extension
	local ranged_slot_data 			= inventory_extension:get_slot_data("slot_ranged")
	local ranged_slot_template		= inventory_extension:get_item_template(ranged_slot_data)
	local ranged_slot_name 			= ranged_slot_template.name
	local sniper_target_selection 	= mod.sniper_selection_ranged[ranged_slot_name]
	
	local enhanced_target_choice = blackboard.enhanced_target_choice
	local boss_priority = mod:get("focus_bosses") or enhanced_target_choice
	local elite_priority = enhanced_target_choice
	
	local further_logic = false
	
	if boss_priority and urgent_is_boss and urgent_enemy_dist < 20 then -- old 10 
		bb.target_unit = urgent_enemy
	elseif priority_enemy and prio_enemy_dist < 10 then		--4.5	--5		--3
		bb.target_unit = priority_enemy
	elseif urgent_is_boss and urgent_enemy_dist < 10 then -- extra logic check for when laser boss is off
		bb.target_unit = urgent_enemy
	elseif bb.closest_swarm_projectile_unit and bb.closest_swarm_projectile_dist < 4 then
		bb.target_unit = bb.closest_swarm_projectile_unit
	elseif opportunity_enemy and opp_enemy_dist < 3 then
		bb.target_unit = opportunity_enemy
	elseif urgent_enemy and urgent_enemy_dist < 3 and not urgent_is_boss then
		bb.target_unit = urgent_enemy
	elseif slot_enemy and slot_enemy_dist < 3.5 then	--3
		bb.target_unit = slot_enemy
		further_logic = true
	elseif prox_enemy and prox_enemy_dist < 3.5 then	--2
		bb.target_unit = prox_enemy
		further_logic = true
	elseif priority_enemy then
		bb.target_unit = priority_enemy
	elseif opportunity_enemy and opportunity_los then
		bb.target_unit = opportunity_enemy
	elseif urgent_enemy and urgent_is_boss and (num_near_enemies < 3 or (urgent_enemy_dist < 5 and not urgent_flanking) or (urgent_enemy_dist < 7 and urgent_targeting_me)) then
		bb.target_unit = urgent_enemy
	elseif urgent_enemy and not urgent_is_boss then
		bb.target_unit = urgent_enemy
	else
		further_logic = true
	end
	
	if further_logic then
		
		-- if not sniper_target_selection and separation_threat.unit then
		if not elite_priority then 
			if bb.separating_target_enemy and bb.separating_target_distance < 3.5 then
				blackboard.target_unit = bb.separating_target_enemy
			elseif sniper_target_selection and bb.elite_target_enemy and (bb.trash_target_distance > 3.5 or bb.trash_target_distance > bb.elite_target_distance) then	--3		--3.5
				blackboard.target_unit = bb.elite_target_enemy
			elseif bb.trash_target_enemy or bb.elite_target_enemy then
				if bb.trash_target_distance < bb.elite_target_distance then
					blackboard.target_unit = bb.trash_target_enemy
				else
					blackboard.target_unit = bb.elite_target_enemy
				end
			elseif slot_enemy then
				blackboard.target_unit = slot_enemy
			elseif urgent_enemy then
				blackboard.target_unit = urgent_enemy
			--edit start--
			elseif prox_enemy then
				blackboard.target_unit = prox_enemy
			--edit end--
			elseif blackboard.target_unit then
				blackboard.target_unit = nil
			end
		else
			local closest_elite_is_cw = bb.elite_target_enemy and Unit.get_data(bb.elite_target_enemy, "breed") and Unit.get_data(bb.elite_target_enemy, "breed").name == "chaos_warrior"
			
			if closest_elite_is_cw and bb.elite_target_distance < 10 then
				blackboard.target_unit = bb.elite_target_enemy
			elseif opportunity_enemy and opp_enemy_dist < 8 then
				blackboard.target_unit = opportunity_enemy
			elseif bb.elite_target_enemy and bb.elite_target_distance < 8 then
				blackboard.target_unit = bb.elite_target_enemy
			-- elseif bb.separating_target_enemy and bb.separating_target_distance < 3.5 then
			elseif bb.separating_target_enemy and bb.separating_target_distance < 3.5 and blackboard.separation_check_allies and #blackboard.separation_check_allies < 3 then
				blackboard.target_unit = bb.separating_target_enemy
			elseif urgent_enemy and urgent_enemy_dist < 10 then
				blackboard.target_unit = urgent_enemy
			elseif bb.trash_target_enemy or bb.elite_target_enemy then
				if bb.trash_target_distance < bb.elite_target_distance then
					blackboard.target_unit = bb.trash_target_enemy
				else
					blackboard.target_unit = bb.elite_target_enemy
				end
			elseif slot_enemy then
				blackboard.target_unit = slot_enemy
			elseif prox_enemy and prox_enemy_dist < 3.5 then	--2
				bb.target_unit = prox_enemy
			elseif urgent_enemy then
				blackboard.target_unit = urgent_enemy
			--edit start--
			elseif prox_enemy then
				blackboard.target_unit = prox_enemy
			--edit end--
			elseif blackboard.target_unit then
				blackboard.target_unit = nil
			end
		end
	end
	
	if not blackboard.target_unit and bb.elite_target_enemy and ALIVE[bb.elite_target_enemy] then
		blackboard.target_unit = bb.elite_target_enemy
	end
	
	if ALIVE[blackboard.target_unit] then
		blackboard.target_dist = Vector3.distance(POSITION_LOOKUP[blackboard.target_unit], self_pos)
	elseif blackboard.target_unit then
		blackboard.target_dist = math.huge
		blackboard.target_unit = nil
	end
	
	if mod.components.ping_enemies.value then
		mod.components.ping_enemies.attempt_ping_enemy(self._blackboard)
	end
end)


--[[PlayerBotBase._target_valid = function (self, unit, enemy_offset)
	local blackboard = BLACKBOARDS[unit]

	if not blackboard or blackboard.breed.not_bot_target then
		return false
	end

	if ScriptUnit.has_extension(unit, "ai_group_system") and not blackboard.target_unit then
		return false
	end

	local up_dot_product = Vector3.dot(Vector3.up(), Vector3.normalize(enemy_offset))

	if PROXIMITY_UP_DOWN_THRESHOLD < up_dot_product or up_dot_product < -PROXIMITY_UP_DOWN_THRESHOLD then
		return false
	end

	return true
end--]]

local BROADPHASE_QUERY_TEMP = {}
local DETECT_ENEMIES_RANGE_FAR = 50
mod:hook(PlayerBotBase, "_update_proximity_target", function (func, self, dt, t, self_position)
	-- if not mod.components.aggro_tweaks.value then
		-- return func(self, dt, t, self_position)
	-- end
	
	local blackboard = self._blackboard
	
	local prev_num_prox_enemies = #blackboard.proximite_enemies
	
	if self._proximity_target_update_timer < t then
		local self_unit = self._unit
		self._proximity_target_update_timer = t + 0.25 + Math.random() * 0.15

		local check_range = PROXIMITY_CHECK_RANGE
		blackboard.aggressive_mode = false
		blackboard.force_aid = false
		local search_position = nil

		if ALIVE[blackboard.target_ally_unit] and blackboard.target_ally_needs_aid and self:within_aid_range(blackboard) then
			search_position = POSITION_LOOKUP[blackboard.target_ally_unit]
			local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
			local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, blackboard.target_ally_unit)
			local is_reviving = blackboard.current_interaction_unit == blackboard.target_ally_unit

			if is_prioritized and is_reviving then
				check_range = PROXIMITY_CHECK_RANGE_ALLY_NEEDS_AID_REVIVING
				blackboard.force_aid = true
			elseif is_prioritized then
				check_range = PROXIMITY_CHECK_RANGE_ALLY_NEEDS_AID
				blackboard.force_aid = true
			else
				blackboard.aggressive_mode = true
				check_range = PROXIMITY_CHECK_RANGE_ALLY_NEEDS_AID_SUPPORT
			end
		else
			search_position = self_position
			
			if prev_num_prox_enemies < 4 then
				check_range = DETECT_ENEMIES_RANGE_FAR
			end
		end

		self._num_broadphase_hits = Broadphase.query(self._enemy_broadphase, search_position, check_range, BROADPHASE_QUERY_TEMP)
	end
	
	self:choose_best_broadphase_targets(self_position, BROADPHASE_QUERY_TEMP)
end)

mod.last_halescourege_teleport_time = nil

mod:hook(BTEnterHooks, "teleport_to_center", function(func, unit, blackboard, t)
	-- local level_analysis = Managers.state.conflict.level_analysis
	-- local node_units = level_analysis.generic_ai_node_units.sorcerer_boss_center
	-- local center_unit = node_units[1]
	-- local teleport_pos = unit_local_position(center_unit, 0)

	-- if teleport_pos then
		-- blackboard.quick_teleport_exit_pos = Vector3Box(teleport_pos)
		-- blackboard.quick_teleport = true
		-- blackboard.move_pos = nil

		-- return
	-- end
	
	mod.last_halescourege_teleport_time = t
	
	return func(unit, blackboard, t)
end)

mod:hook(PlayerBotBase, "_enemy_path_allowed", function (func, self, enemy_unit)
	if not mod.components.stop_chasing.value then
		return func(self, enemy_unit)
	end
	
	local self_unit = self._unit
	local self_pos = POSITION_LOOKUP[self_unit]
	local blackboard = self_unit and BLACKBOARDS[self_unit]
	
	if not self_unit or not self_pos or not blackboard then
		return false
	end
	
	local enemy_pos = POSITION_LOOKUP[enemy_unit]
	local enemy_breed = Unit.get_data(enemy_unit, "breed")
	local breed_bb = enemy_unit and BLACKBOARDS[enemy_unit]
	
	if not enemy_unit or not enemy_pos or not enemy_breed or not breed_bb then
		if not enemy_pos then
			--mod:echo("Error: invalid enemy")
		end
		return false
	end
	
	--edit start--
	if blackboard.shoot and mod.BOSS_AND_LORD_UNITS[enemy_breed.name] then
		return false
	end
	--edit end--
	
	local dont_chase = {
		skaven_ratling_gunner = true,
		skaven_warpfire_thrower = true,
		skaven_explosive_loot_rat = true,
		
		skaven_poison_wind_globadier = true,
		chaos_vortex_sorcerer = true,
	}
	
	local dont_chase_unless_no_ranged = {
		-- skaven_poison_wind_globadier = true,
		-- chaos_vortex_sorcerer = true,
	}
	
	local inventory_extension = blackboard.inventory_extension
	local ammo = inventory_extension:ammo_percentage()
	local ranged_slot_data = inventory_extension:get_slot_data("slot_ranged")
	local ranged_slot_template = inventory_extension:get_item_template(ranged_slot_data)
	local ranged_slot_name = ranged_slot_template.name
	local ranged_slot_buff_type = ranged_slot_template and ranged_slot_template.buff_type
	local is_ranged = RangedBuffTypes[ranged_slot_buff_type]
	-- local ammo_ok = (not mod.heat_weapon[ranged_slot_name] and ammo > 0) or (mod.heat_weapon[ranged_slot_name] and ammo > 0.1)
	local ammo_ok = is_ranged and ((not mod.heat_weapon[ranged_slot_name] and ammo > 0) or mod.heat_weapon[ranged_slot_name])

	if enemy_breed and (dont_chase[enemy_breed.name] or (ammo_ok and dont_chase_unless_no_ranged[enemy_breed.name])) then
		return false
	end
	
	local follow_unit = blackboard.ai_bot_group_extension.data.follow_unit
	local follow_pos = POSITION_LOOKUP[follow_unit]
	
	if not follow_pos then
		--mod:echo("Error: invalid follow position")
		return false
	end
	
	local in_line_of_fire = blackboard.in_line_of_fire
	
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	
	if Vector3.distance_squared(enemy_pos, self_pos) > (not in_line_of_fire and 289 or 16) then
		return false
	end
	
	if enemy_breed and enemy_breed.name == "chaos_exalted_sorcerer" then
		local current_time = Managers.time:time("game")
		
		if (breed_bb and breed_bb.action and (breed_bb.action.name == "spawn_boss_vortex" or breed_bb.action.name == "spawn_flower_wave")) or
			(mod.last_halescourege_teleport_time and current_time < mod.last_halescourege_teleport_time + 3.5) then
			
			return false
		end
	end

	return func(self, enemy_unit)
end)

mod:hook(PlayerBotBase, "_update_movement_target", function (func, self, dt, t)
	local unit = self._unit
	local self_pos = POSITION_LOOKUP[unit]
	local blackboard = self._blackboard
	local override_box = blackboard.navigation_destination_override
	--edit start--
	-- local override_melee = blackboard.melee and blackboard.melee.engage_position_set and override_box:unbox()
	local override_melee = blackboard.melee and (blackboard.melee.disengage_position_set or blackboard.melee.engage_position_set) and override_box:unbox()
	--edit end--
	local override_ranged = blackboard.shoot and blackboard.shoot.disengage_position_set and override_box:unbox()
	local override_ability = blackboard.activate_ability_data and blackboard.activate_ability_data.move_to_position_set and override_box:unbox()
	local override_liquid_escape = blackboard.use_liquid_escape_destination and blackboard.navigation_liquid_escape_destination_override:unbox()
	local override_vortex_escape = blackboard.use_vortex_escape_destination and blackboard.navigation_vortex_escape_destination_override:unbox()
	local moving_towards_follow_position = false
	local follow_bb = blackboard.follow
	local cover_bb = blackboard.taking_cover
	local cover_position = self:_update_cover(unit, self_pos, blackboard, cover_bb, follow_bb)
	local transport_unit_override = nil
	local nav_world = self._nav_world
	local target_ally_unit = blackboard.target_ally_unit
	local target_ally_need_type = blackboard.target_ally_need_type
	local target_ally_has_moved_from_start_position = true

	if ALIVE[target_ally_unit] then
		local ally_status_extension = ScriptUnit.extension(target_ally_unit, "status_system")
		local transport_unit = ally_status_extension:get_inside_transport_unit()

		if unit_alive(transport_unit) and not blackboard.target_ally_needs_aid then
			blackboard.ally_inside_transport_unit = transport_unit
			local transportation_ext = ScriptUnit.extension(blackboard.ally_inside_transport_unit, "transportation_system")
			local has_valid_transportation_unit = transportation_ext.story_state == "stopped_beginning"

			if has_valid_transportation_unit then
				transport_unit_override = LocomotionUtils.new_goal_in_transport(nav_world, unit, target_ally_unit)
			end
		elseif blackboard.ally_inside_transport_unit then
			blackboard.ally_inside_transport_unit = nil
		elseif not target_ally_need_type or target_ally_need_type == "in_need_of_attention_stop" or target_ally_need_type == "in_need_of_attention_look" then
			local ally_locomotion_extension = ScriptUnit.extension(target_ally_unit, "locomotion_system")
			target_ally_has_moved_from_start_position = ally_locomotion_extension.has_moved_from_start_position
		end
	else
		blackboard.ally_inside_transport_unit = nil
	end

	local navigation_extension = blackboard.navigation_extension
	local previous_destination = navigation_extension:destination()
	local ai_bot_group_extension = blackboard.ai_bot_group_extension
	local hold_position, hold_position_max_distance_sq = ai_bot_group_extension:get_hold_position()
	local hold_position_offset = hold_position and hold_position - previous_destination
	local hold_position_offset_z = hold_position_offset and math.abs(hold_position_offset.z)
	local flat_hold_position_offset_length_sq = hold_position_offset and Vector3.length_squared(Vector3.flat(hold_position_offset))
	local should_go_back = hold_position_offset and (HOLD_POSITION_MAX_ALLOWED_Z < hold_position_offset_z or hold_position_max_distance_sq < flat_hold_position_offset_length_sq)
	local stop_for_vortex = not override_vortex_escape and blackboard.vortex_exist and not navigation_extension:is_path_safe_from_vortex(VORTEX_SAFE_PATH_CHECK_DISTANCE, MIN_ALLOWED_VORTEX_DISTANCE)

	if should_go_back then
		navigation_extension:move_to(hold_position)

		blackboard.using_navigation_destination_override = true
	elseif stop_for_vortex then
		local path_callback = navigation_extension:path_callback()

		if path_callback then
			path_callback(false, previous_destination, true)
		end

		navigation_extension:stop()

		if override_melee then
			blackboard.melee.engage_position_set = false
			--edit start--
			blackboard.melee.disengage_position_set = false
			--edit end--
		end

		if override_ranged then
			blackboard.shoot.disengage_position_set = false
		end

		if override_ability then
			blackboard.activate_ability_data.move_to_position_set = false
		end
	elseif override_vortex_escape or override_liquid_escape or cover_position or override_melee or override_ranged or override_ability then
		local override = transport_unit_override or override_vortex_escape or override_liquid_escape or cover_position or override_melee or override_ranged or override_ability
		local offset = override - previous_destination
		local override_allowed = hold_position == nil or Vector3.distance_squared(hold_position, override) <= hold_position_max_distance_sq
		
		if override_allowed and (Z_MOVE_TO_EPSILON < math.abs(offset.z) or FLAT_MOVE_TO_EPSILON < Vector3.length(Vector3.flat(offset))) then --
			local should_stop = (override_melee and blackboard.melee.stop_at_current_position) or (override_ranged and blackboard.shoot.stop_at_current_position)

			if should_stop then
				navigation_extension:stop()
			else
				local path_callback = (not transport_unit_override and cover_position and callback(self, "cb_cover_point_path_result", to_hash(override))) or nil
				
				navigation_extension:move_to(override, path_callback)
			end
			
			blackboard.using_navigation_destination_override = true
		end
	else
		follow_bb.follow_timer = follow_bb.follow_timer - dt
		local interaction_extension = blackboard.interaction_extension
		local is_interacting = interaction_extension:is_interacting()
		local need_to_stop = target_ally_need_type == "in_need_of_attention_stop"

		if not follow_bb.needs_target_position_refresh and (follow_bb.follow_timer < 0 or need_to_stop or (blackboard.target_ally_needs_aid and not is_interacting and navigation_extension:destination_reached())) then
			follow_bb.needs_target_position_refresh = true
		end

		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local has_ammo_pickup_order = ai_bot_group_system:get_ammo_pickup_order_unit(unit) ~= nil
		local has_pickup_order = has_ammo_pickup_order or ai_bot_group_system:has_pending_pickup_order(unit)

		if follow_bb.needs_target_position_refresh and (target_ally_has_moved_from_start_position or has_pickup_order) then
			local target_position, should_stop = nil
			local goal_selection_func_name = blackboard.follow.goal_selection_func
			local path_callback = nil
			local enemy_unit = blackboard.target_unit
			local priority_target_enemy = blackboard.priority_target_enemy
			local health_slot_pickup_order = ai_bot_group_system:get_pickup_order(unit, "slot_healthkit")
			local health_slot_pickup_order_unit = (health_slot_pickup_order and health_slot_pickup_order.unit) or nil
			local potion_slot_pickup_order = ai_bot_group_system:get_pickup_order(unit, "slot_potion")
			local potion_slot_pickup_order_unit = (potion_slot_pickup_order and potion_slot_pickup_order.unit) or nil

			if blackboard.revive_with_urgent_target and blackboard.target_ally_needs_aid and target_ally_need_type ~= "in_need_of_attention_look" then
				target_position, should_stop = self:_alter_target_position(nav_world, self_pos, target_ally_unit, POSITION_LOOKUP[target_ally_unit], target_ally_need_type)
				blackboard.interaction_unit = target_ally_unit

				blackboard.target_ally_aid_destination:store(target_position)

				path_callback = callback(self, "cb_ally_path_result", target_ally_unit)
			elseif priority_target_enemy and enemy_unit ~= priority_target_enemy and self:_enemy_path_allowed(priority_target_enemy) then
				target_position = self:_find_target_position_on_nav_mesh(nav_world, POSITION_LOOKUP[priority_target_enemy])
				path_callback = callback(self, "cb_enemy_path_result", priority_target_enemy)
			elseif enemy_unit and (enemy_unit == priority_target_enemy or enemy_unit == blackboard.urgent_target_enemy) and self:_enemy_path_allowed(enemy_unit) then
				target_position = self:_find_target_position_on_nav_mesh(nav_world, POSITION_LOOKUP[enemy_unit])
				path_callback = callback(self, "cb_enemy_path_result", enemy_unit)
			elseif enemy_unit and blackboard.move_to_target_unit and self:_enemy_path_allowed(enemy_unit) then
				target_position = self:_find_target_position_on_nav_mesh(nav_world, POSITION_LOOKUP[enemy_unit])
				path_callback = callback(self, "cb_enemy_path_result", enemy_unit)
			elseif blackboard.target_ally_needs_aid and target_ally_need_type ~= "in_need_of_attention_look" then
				target_position, should_stop = self:_alter_target_position(nav_world, self_pos, target_ally_unit, POSITION_LOOKUP[target_ally_unit], target_ally_need_type)
				blackboard.interaction_unit = target_ally_unit

				blackboard.target_ally_aid_destination:store(target_position)

				path_callback = callback(self, "cb_ally_path_result", target_ally_unit)
			elseif goal_selection_func_name and ALIVE[target_ally_unit] then
				local func = LocomotionUtils[goal_selection_func_name]
				target_position = func(nav_world, unit, target_ally_unit)
			elseif unit_alive(blackboard.health_pickup) and blackboard.allowed_to_take_health_pickup and t < blackboard.health_pickup_valid_until and (self._last_health_pickup_attempt.unit ~= blackboard.health_pickup or not self._last_health_pickup_attempt.blacklist or health_slot_pickup_order_unit == blackboard.health_pickup) then
				local pickup_unit = blackboard.health_pickup
				target_position = self:_find_pickup_position_on_navmesh(nav_world, self_pos, pickup_unit, self._last_health_pickup_attempt)
				local allowed_to_take_without_path = pickup_unit == health_slot_pickup_order_unit

				if target_position then
					path_callback = callback(self, "cb_health_pickup_path_result", pickup_unit)
					blackboard.interaction_unit = pickup_unit
				elseif allowed_to_take_without_path then
					blackboard.interaction_unit = pickup_unit
					blackboard.forced_pickup_unit = pickup_unit
				end
			elseif unit_alive(blackboard.mule_pickup) and (self._last_mule_pickup_attempt.unit ~= blackboard.mule_pickup or not self._last_mule_pickup_attempt.blacklist or potion_slot_pickup_order_unit == blackboard.mule_pickup) then
				local pickup_unit = blackboard.mule_pickup
				target_position = self:_find_pickup_position_on_navmesh(nav_world, self_pos, pickup_unit, self._last_mule_pickup_attempt)
				local allowed_to_take_without_path = pickup_unit == potion_slot_pickup_order_unit

				if target_position then
					path_callback = callback(self, "cb_mule_pickup_path_result", pickup_unit)
					blackboard.interaction_unit = pickup_unit
				elseif allowed_to_take_without_path then
					blackboard.interaction_unit = pickup_unit
					blackboard.forced_pickup_unit = pickup_unit
				end
			end

			if not target_position and unit_alive(blackboard.ammo_pickup) and blackboard.has_ammo_missing and t < blackboard.ammo_pickup_valid_until then
				local ammo_position = POSITION_LOOKUP[blackboard.ammo_pickup]
				local dir = Vector3.normalize(self_pos - ammo_position)
				local above = 0.5
				local below = 1.5
				local lateral = INTERACT_RAY_DISTANCE - 0.3
				local distance = 0
				target_position = self:_find_position_on_navmesh(nav_world, ammo_position, ammo_position + dir, above, below, lateral, distance)

				if target_position then
					blackboard.interaction_unit = blackboard.ammo_pickup
				end
			end

			local new_position_is_outside_hold_radius = hold_position and target_position and hold_position_max_distance_sq < Vector3.distance_squared(hold_position, target_position)

			if new_position_is_outside_hold_radius then
				target_position = nil
			end

			if not target_position then
				target_position = ai_bot_group_extension.data.follow_position
				moving_towards_follow_position = true
			end

			if should_stop then
				navigation_extension:stop()
			elseif target_position then
				blackboard.moving_toward_follow_position = moving_towards_follow_position
				follow_bb.needs_target_position_refresh = false
				follow_bb.follow_timer = math.lerp(FOLLOW_TIMER_LOWER_BOUND, FOLLOW_TIMER_UPPER_BOUND, Math.random())

				follow_bb.target_position:store(target_position)

				if self:new_destination_distance_check(self_pos, previous_destination, target_position, navigation_extension) then
					navigation_extension:move_to(target_position, path_callback)
				end

				blackboard.using_navigation_destination_override = false
			end
		end

		if blackboard.using_navigation_destination_override then
			navigation_extension:move_to(follow_bb.target_position:unbox())

			blackboard.using_navigation_destination_override = false
		end

		local current_goal = navigation_extension:current_goal()
		local area_damage_system = Managers.state.entity:system("area_damage_system")

		if current_goal and (area_damage_system:is_position_in_liquid(current_goal, BotNavTransitionManager.NAV_COST_MAP_LAYERS)) then --or ai_bot_group_system:_selected_unit_is_in_disallowed_nav_tag_volume(nav_world, current_goal)
			navigation_extension:stop()
		end
	end
end)







local is_position_inside_liquid = function (liquid_extension, position, nav_cost_map_table, radius)
	local nav_cost_map_cost_type = liquid_extension._nav_cost_map_cost_type

	if nav_cost_map_cost_type == nil or (nav_cost_map_table and nav_cost_map_table[nav_cost_map_cost_type] == 1) then
		return false
	end
	
	local grid = liquid_extension._grid
	
	local _i, _j, _k = grid:find_index(position)
	
	if not radius or radius < 1 then radius = 1 end
	
	for di = -radius, radius, 1 do
		for dj = -radius, radius, 1 do
			for dk = 0, 1, 1 do
				local i, j, k = _i + di, _j + dj, _k + dk
				
				if not grid:is_out_of_bounds(i, j, k) then
					local real_index = grid:real_index(i, j, k)
					local liquid = liquid_extension._flow[real_index]
					
					if liquid then -- and liquid.full - but this works bad
						return true
					end
				end
			end
		end
	end
	
	return false
end

AreaDamageSystem.get_position_liquid_extension_extended = function (self, position, nav_cost_map_table, radius)
	local liquid_extensions = self.liquid_extensions
	local num_liquid_extensions = self.num_liquid_extensions
	
	for i = 1, num_liquid_extensions, 1 do
		local extension = liquid_extensions[i]
		is_inside = is_position_inside_liquid(extension, position, nav_cost_map_table, radius)

		if is_inside then
			return extension
		end
	end

	return nil
end

AreaDamageSystem.is_position_in_liquid_extended = function (self, position, nav_cost_map_table, radius)
	local liquid_extensions = self.liquid_extensions
	local num_liquid_extensions = self.num_liquid_extensions
	local result = false
	
	for i = 1, num_liquid_extensions, 1 do
		local extension = liquid_extensions[i]
		result = is_position_inside_liquid(extension, position, nav_cost_map_table, radius)

		if result then
			break
		end
	end

	return result
end

local directions_vectors = {
	Vector3Box(0,-1,0),
	Vector3Box(-0.5,-0.866,0),
	Vector3Box(-0.866,-0.5,0),
	Vector3Box(-1,0,0),
	Vector3Box(-0.866,0.5,0),
	Vector3Box(-0.5,0.866,0),
	Vector3Box(0,1,0),
	Vector3Box(0.5,0.866,0),
	Vector3Box(0.866,0.5,0),
	Vector3Box(1,0,0),
	Vector3Box(0.866,-0.5,0),
	Vector3Box(0.5,-0.866,0),
}

local above	= 2.5
local below	= 2.5
local find_global_escape = function(position, area_damage_system, nav_cost_map_layers)
	local nav_world	= Managers.state.bot_nav_transition._nav_world
	
	for radius_i = 1, 20, 1 do
		local dist_multiplier = radius_i > 10 and (radius_i - 5) or radius_i * 0.5
		
		for i = 1, 12, 1 do
			local direction = directions_vectors[i]:unbox() + Vector3(0.2 * (0.5 - Math.random()), 0.2 * (0.5 - Math.random()), 0)
			local try = position + direction * dist_multiplier
			
			local success, z = GwNavQueries.triangle_from_position(nav_world, try, above, below)
			
			if success then
				try.z = z
				
				ray_can_go = GwNavQueries.raycango(nav_world, try, position)
				
				local in_liquid = area_damage_system:is_position_in_liquid_extended(try, nav_cost_map_layers)
				
				local z_diff = math.abs(z - position.z)
				
				if ray_can_go and not in_liquid and z_diff < 6 then
					return try
				end
			end
		end
	end
	
	return nil
end

local original_update_liquid_escape = function (self)
	local unit = self._unit
	local blackboard = self._blackboard
	local status_extension = self._status_extension
	local in_liquid = status_extension:is_in_liquid()
	local use_liquid_escape_destination = blackboard.use_liquid_escape_destination
	local navigation_extension = blackboard.navigation_extension
	local is_disabled = status_extension:is_disabled()

	if in_liquid and not is_disabled and (not use_liquid_escape_destination or navigation_extension:destination_reached()) then
		local liquid_unit = status_extension.in_liquid_unit
		local liquid_extension = ScriptUnit.extension(liquid_unit, "area_damage_system")
		local rim_nodes, is_array = liquid_extension:get_rim_nodes()
		local bot_position = POSITION_LOOKUP[unit]
		local best_distance_sq = math.huge
		local best_position = nil

		if is_array then
			local num_nodes = #rim_nodes

			for i = 1, num_nodes, 1 do
				local position = rim_nodes[i]:unbox()
				local distance_sq = Vector3.distance_squared(bot_position, position)

				if distance_sq < best_distance_sq then
					best_position = position
					best_distance_sq = distance_sq
				end
			end
		else
			for _, node in pairs(rim_nodes) do
				local position = node.position:unbox()
				local distance_sq = Vector3.distance_squared(bot_position, position)

				if distance_sq < best_distance_sq then
					best_position = position
					best_distance_sq = distance_sq
				end
			end
		end

		if best_position then
			blackboard.navigation_liquid_escape_destination_override:store(best_position)

			blackboard.use_liquid_escape_destination = true
		end
	elseif use_liquid_escape_destination and (is_disabled or not in_liquid) then
		blackboard.use_liquid_escape_destination = false
	end
end

local modified_original_escape_evaluate = function (self, area_damage_system, status_extension, bot_position, nav_cost_map_layers, t)
	local in_liquid = status_extension:is_in_liquid()
	local liquid_unit = in_liquid and status_extension.in_liquid_unit or nil
	local liquid_extension = ScriptUnit.extension(liquid_unit, "area_damage_system") or area_damage_system:get_position_liquid_extension_extended(bot_position, nav_cost_map_layers, 2)
	
	if not liquid_extension then
		return nil
	end
	
	local rim_nodes, is_array = liquid_extension:get_rim_nodes()
	
	local best_distance_sq = math.huge
	local best_position = nil
	
	if is_array then
		local num_nodes = #rim_nodes
		
		for i = 1, num_nodes, 1 do
			local position = rim_nodes[i]:unbox()
			local distance_sq = Vector3.distance_squared(bot_position, position)
			local pos_in_liquid = area_damage_system:is_position_in_liquid_extended(position, nav_cost_map_layers, 2)
			
			if not pos_in_liquid and distance_sq < best_distance_sq then
				best_position = position
				best_distance_sq = distance_sq
			end
		end
	else
		for _, node in pairs(rim_nodes) do
			local position = node.position:unbox()
			local distance_sq = Vector3.distance_squared(bot_position, position)
			local pos_in_liquid = area_damage_system:is_position_in_liquid_extended(position, nav_cost_map_layers, 2)
			
			if not pos_in_liquid and distance_sq < best_distance_sq then
				best_position = position
				best_distance_sq = distance_sq
			end
		end
	end
	
	return best_position
end

local function safe_call(mod, error_prefix_data, func, ...)
  local success, return_values = pack_pcall(xpcall(func, print_error_callstack, ...))
  
  if not success then
    show_error(mod, error_prefix_data, return_values[1])
	return success
  end
  
  return success, return_values
end



local function pack_pcall(status, ...)
  return status, {n = select('#', ...), ...}
end

local function print_error_callstack(error_message)
  if type(error_message) == "table" and error_message.error then
    error_message = error_message.error
  end
  print("Error: " .. tostring(error_message) .. "\n" .. Script.callstack())
  return error_message
end

local function show_error(mod, error_prefix_data, error_message)
  local error_prefix
  if type(error_prefix_data) == "table" then
    error_prefix = string.format(error_prefix_data[1], error_prefix_data[2], error_prefix_data[3], error_prefix_data[4])
  else
    error_prefix = error_prefix_data
  end

  mod:error("%s: %s", error_prefix, error_message)
end


mod.protect_func = function(self, func)
	return function(...)
		local success, return_values = safe_call(self, "Error", func, ...)
		
		if success then
			return unpack(return_values, 1, return_values.n)
		end
	end
end

mod.protected_hook = function(self, obj, method, handler)
	handler = self:protect_func(handler)
	
	self:hook(obj, method, handler)
end

--Vernon: xpcall causes crash...
-- mod:protected_hook(PlayerBotBase, "_update_liquid_escape", function (func, self, t)
mod:hook(PlayerBotBase, "_update_liquid_escape", function (func, self, t)
	local unit = self._unit
	local bot_position = POSITION_LOOKUP[unit]
	
	local nav_cost_map_layers = BotNavTransitionManager.NAV_COST_MAP_LAYERS
	local area_damage_system = Managers.state.entity:system("area_damage_system")
	local liquid_exists = area_damage_system.num_liquid_extensions > 0
	local in_liquid = liquid_exists and area_damage_system:is_position_in_liquid_extended(bot_position, nav_cost_map_layers, 2)
	
	local blackboard = self._blackboard
	local navigation_extension = blackboard.navigation_extension
	local status_extension = self._status_extension
	
	local use_liquid_escape_destination = blackboard.use_liquid_escape_destination
	local destination_reached = navigation_extension:destination_reached()
	local is_disabled = status_extension:is_disabled()
	local update_time = self._update_liquid_escape_destination_timer < t
	
	if in_liquid and not is_disabled and (not use_liquid_escape_destination or destination_reached or (liquid_exists and update_time)) then
		best_position = modified_original_escape_evaluate(self, area_damage_system, status_extension, bot_position, nav_cost_map_layers, t) or 
						find_global_escape(bot_position, area_damage_system, nav_cost_map_layers)
		
		if best_position then
			blackboard.navigation_liquid_escape_destination_override:store(best_position)
			
			blackboard.use_liquid_escape_destination = true
			
			self._update_liquid_escape_destination_timer = t + 0.5
		end
		
	elseif use_liquid_escape_destination and (is_disabled or not in_liquid) and (destination_reached or not liquid_exists or update_time) then --or self._update_liquid_escape_destination_timer < t
		blackboard.use_liquid_escape_destination = false
	end
end)

