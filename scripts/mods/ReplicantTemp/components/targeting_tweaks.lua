local mod = get_mod("ReplicantTemp")

local unit_alive = Unit.alive
local BLACKBOARDS = BLACKBOARDS
local PROXIMITY_CHECK_RANGE = 12
local PROXIMITY_CHECK_RANGE_ALLY_NEEDS_AID = 10
local PROXIMITY_CHECK_RANGE_ALLY_NEEDS_AID_REVIVING = 8
local PROXIMITY_CHECK_RANGE_ALLY_NEEDS_AID_SUPPORT = 15
local STICKYNESS_DISTANCE_MODIFIER = 0-- -0.2
local FOLLOW_TIMER_LOWER_BOUND = 1
local FOLLOW_TIMER_UPPER_BOUND = 1.5
local ENEMY_PATH_FAILED_REPATH_THRESHOLD = 9
local ENEMY_PATH_FAILED_REPATH_VERTICAL_THRESHOLD = 0.8
local FLAT_MOVE_TO_EPSILON = BotConstants.default.FLAT_MOVE_TO_EPSILON
local Z_MOVE_TO_EPSILON = BotConstants.default.Z_MOVE_TO_EPSILON
local HOLD_POSITION_MAX_ALLOWED_Z = 0.5
local VORTEX_SAFE_PATH_CHECK_DISTANCE = 15
local MIN_ALLOWED_VORTEX_DISTANCE = 2

--[[mod:hook(PlayerBotBase, "_update_blackboard", function (func, self, dt, t)
	if not mod.components.aggro_tweaks.value then
		return func(self, dt, t)
	end

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
	local unit = self._unit
	local target_unit = bb.target_unit

	if ALIVE[target_unit] then
		bb.target_dist = Vector3.distance(POSITION_LOOKUP[target_unit], POSITION_LOOKUP[unit])
	else
		bb.target_dist = math.huge
		bb.target_unit = nil
	end

	for _, action_data in pairs(bb.utility_actions) do
		action_data.time_since_last = t - action_data.last_time
	end
end)--]]

--[[mod:hook(PlayerBotBase, "_update_target_enemy", function (func, self, dt, t)
	if not mod.components.aggro_tweaks.value then
		func(self, dt, t)
	else
		local pos = POSITION_LOOKUP[self._unit]

		self:_update_slot_target(dt, t, pos)
		self:_update_proximity_target(dt, t, pos)

		local bb = self._blackboard
		local old_target = bb.target_unit
		local slot_enemy = bb.slot_target_enemy
		local prox_enemy = bb.proximity_target_enemy
		local priority_enemy = bb.priority_target_enemy
		local urgent_enemy = bb.urgent_target_enemy
		local opportunity_enemy = bb.opportunity_target_enemy
		local prox_enemy_dist = bb.proximity_target_distance + ((prox_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
		local prio_enemy_dist = bb.priority_target_distance + ((priority_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
		local urgent_enemy_dist = bb.urgent_target_distance + ((urgent_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
		local opp_enemy_dist = bb.opportunity_target_distance + ((opportunity_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
		local slot_enemy_dist = math.huge
		
		if slot_enemy then
			slot_enemy_dist = Vector3.length(POSITION_LOOKUP[slot_enemy] - pos) + ((slot_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
		end

		if priority_enemy and prio_enemy_dist < 4 then
			bb.target_unit = priority_enemy
		elseif urgent_enemy and urgent_enemy_dist < 4 then
			bb.target_unit = urgent_enemy
		elseif opportunity_enemy and opp_enemy_dist < 4 then
			bb.target_unit = opportunity_enemy
		elseif slot_enemy and slot_enemy_dist < 4 then
			bb.target_unit = slot_enemy
		elseif prox_enemy and prox_enemy_dist <= 3 then
			bb.target_unit = prox_enemy
		elseif priority_enemy then
			bb.target_unit = priority_enemy
		elseif prox_enemy and prox_enemy_dist <= 10 then
			bb.target_unit = priority_enemy
		elseif prox_enemy and bb.proximity_target_is_player and prox_enemy_dist < 10 then
			bb.target_unit = prox_enemy
		elseif urgent_enemy then
			bb.target_unit = urgent_enemy
		elseif opportunity_enemy then
			bb.target_unit = opportunity_enemy
		elseif slot_enemy then
			bb.target_unit = slot_enemy
		elseif prox_enemy and prox_enemy_dist <= 20 then
			bb.target_unit = prox_enemy
		elseif bb.target_unit then
			bb.target_unit = nil
		end
	end
	
	if mod.components.ping_enemies.value then
		mod.components.ping_enemies.attempt_ping_enemy(self._blackboard)
	end
end)--]]

mod:hook(BTConditions, "is_disabled", function (func, blackboard)
	if not mod.components.aggro_tweaks.value then
		return func(blackboard)
	end

	return blackboard.is_dead or
	blackboard.is_pounced_down or
	blackboard.is_knocked_down or
	blackboard.is_grabbed_by_pack_master or
	blackboard.get_is_ledge_hanging or
	blackboard.is_hanging_from_hook or
	blackboard.is_ready_for_assisted_respawn or
	blackboard.is_grabbed_by_tentacle or
	blackboard.is_grabbed_by_chaos_spawn or
	blackboard.is_in_vortex or
	blackboard.is_grabbed_by_corruptor or
	blackboard.is_overpowered
end)


--[[local ZEALOT_PERMANENT_HEALTH_THRESHOLD = 0.16667
local URGENT_HEALING_NEED_THRESHOLD = 0.2
local get_player_status = function(player_unit)
	local status_ext = ScriptUnit.extension(player_unit, "status_system")
	
	local is_disabled = status_ext and status_ext:is_disabled()
	local disabler_unit = nil
	local health_percent = 0
	local needs_urgent_healing = false
	
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
		
		if health_percent <= URGENT_HEALING_NEED_THRESHOLD then
			needs_urgent_healing = true
		end
	else
		disabler_unit = status_ext:get_disabler_unit()
	end
	
	return is_disabled, disabler_unit, health_percent, needs_urgent_healing
end

AIBotGroupSystem._update_players_and_bots = function(self)
	if not self.players_and_bots then
		self.players_and_bots = {}
	end
	
	for side_id = 1, #bot_ai_data, 1 do
		local side = side_manager:get_side(side_id)
		local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
		local num_players = #player_and_bot_units

		for i = 1, num_players, 1 do
			local player_unit = player_and_bot_units[i]
			
			if not self.players_and_bots[player_unit] then
				self.players_and_bots[player_unit] = {}
			end
			
			local is_disabled, disabler_unit, health_percent, needs_urgent_healing = get_player_status(player_unit)
			
			self.players_and_bots[player_unit].is_disabled = is_disabled
			self.players_and_bots[player_unit].disabler_unit = disabler_unit
			self.players_and_bots[player_unit].health_percent = health_percent
			self.players_and_bots[player_unit].needs_urgent_healing = health_percent
		end
	end
end

local PRIORITY_TARGETS_TEMP = {}
local NEW_TARGETS = {}
local TEMP_PLAYER_UNITS = {}
local TEMP_DISABLED_PLAYER_UNITS = {}
local TEMP_PLAYER_POSITIONS = {}
local TEMP_MAN_MAN_POINTS = {}
local VORTEX_STAY_NEAR_PLAYER_MAX_DISTANCE = 3
local ccc = 1
mod:hook(AIBotGroupSystem, "_update_priority_targets", function (func, self, dt, t)
	local side_manager = Managers.state.side
	local bot_ai_data = self._bot_ai_data
	local old_priority_targets = self._old_priority_targets

	for side_id = 1, #bot_ai_data, 1 do
		if ccc == 1 then
			mod:echo("side"..side_id)
		end
		local side = side_manager:get_side(side_id)
		local side_old_priority_targets = old_priority_targets[side_id]
		local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
		local num_players = #player_and_bot_units

		for i = 1, num_players, 1 do
			local player_unit = player_and_bot_units[i]
			local status_ext = ScriptUnit.extension(player_unit, "status_system")

			if not status_ext.near_vortex then
				local target = nil

				if status_ext:is_pounced_down() then
					target = status_ext:get_pouncer_unit()
				elseif status_ext:is_grabbed_by_pack_master() then
					target = status_ext:get_pack_master_grabber()
				elseif status_ext:is_overpowered() then
					target = status_ext.overpowered_attacking_unit
				end

				if Unit.alive(target) then
					PRIORITY_TARGETS_TEMP[player_unit] = target
					NEW_TARGETS[target] = (side_old_priority_targets[target] or 0) + dt
				end
			end
		end

		local side_bot_data = bot_ai_data[side_id]

		for unit, data in pairs(side_bot_data) do
			if ccc == 1 then
				mod:echo(unit)
			end
			if not ALIVE[data.current_priority_target] then
				data.current_priority_target = nil
			end

			local status_ext = data.status_extension

			table.clear(data.priority_targets)

			if PRIORITY_TARGETS_TEMP[unit] or status_ext:is_disabled() then
				data.current_priority_target_disabled_ally = nil
				data.current_priority_target = nil
				data.priority_target_distance = math.huge
			else
				local self_pos = POSITION_LOOKUP[unit]
				local best_target, best_ally = nil
				local best_utility = -math.huge
				local best_distance = math.huge

				for ally, target in pairs(PRIORITY_TARGETS_TEMP) do
					local utility, distance = self:_calculate_priority_target_utility(self_pos, target, NEW_TARGETS[target], data.current_priority_target)
					data.priority_targets[target] = utility

					if best_utility < utility then
						best_utility = utility
						best_target = target
						best_distance = distance
						best_ally = ally
					end
				end

				data.current_priority_target_disabled_ally = best_ally
				data.current_priority_target = best_target
				data.priority_target_distance = best_distance
			end

			local bb = data.blackboard

			if bb.priority_target_disabled_ally or data.current_priority_target_disabled_ally then
				bb.priority_target_disabled_ally = data.current_priority_target_disabled_ally
			end

			if bb.priority_target_enemy or data.current_priority_target then
				bb.priority_target_enemy = data.current_priority_target
			end

			bb.priority_target_distance = data.priority_target_distance
		end

		table.clear(PRIORITY_TARGETS_TEMP)
		table.create_copy(side_old_priority_targets, NEW_TARGETS)
		table.clear(NEW_TARGETS)
	end
	
	ccc = 2
end)

local is_valid_elite = function (unit)
	local blackboard = BLACKBOARDS[unit]

	if not blackboard or not blackboard.breed or blackboard.breed.not_bot_target then
		return false
	end

	if ScriptUnit.has_extension(unit, "ai_group_system") and not blackboard.target_unit then
		--return false
	end

	if not blackboard.breed.elite then
		return false
	end

	return true
end

mod:hook(SideManager, "_create_sides", function (func, self, side_compositions)
	local sides = {}
	local side_lookup = {}

	for i = 0, #side_compositions, 1 do
		local definition = side_compositions[i]
		local side_name = definition.name
		mod:echo(side_name)
		
		fassert(side_lookup[side_name] == nil, "Side with the same name exists in side_composition, side_name(%s)", side_name)

		local side = Side:new(definition, i)
		sides[i] = side
		side_lookup[side_name] = side
	end

	fassert(table.is_empty(sides) == false, "No sides specified")

	return sides, side_lookup
end)

local BROADPHASE_QUERY_TEMP = {}
local CHECK_RANGE_GLOBAL = 50
mod:hook(PlayerBotBase, "_update_proximity_target", function (func, self, dt, t, self_position)
	if not mod.components.aggro_tweaks.value then
		return func(self, dt, t, self_position)
	end
	
	local blackboard = self._blackboard

	if self._proximity_target_update_timer < t then
		local self_unit = self._unit
		self._proximity_target_update_timer = t + 0.25 + Math.random() * 0.15
		local prox_enemies = blackboard.proximite_enemies

		table.clear(prox_enemies)

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
		end

		local num_hits = Broadphase.query(self._enemy_broadphase, search_position, CHECK_RANGE_GLOBAL, BROADPHASE_QUERY_TEMP)
		local closest_dist = math.huge
		local closest_dist_elite = math.huge
		local closest_enemy = nil
		local closest_elite = nil
		local closest_real_dist = math.huge
		local side = blackboard.side

		for PLAYER_UNIT, _ in pairs(side.VALID_ENEMY_TARGETS_PLAYERS_AND_BOTS) do
			num_hits = num_hits + 1
			BROADPHASE_QUERY_TEMP[num_hits] = PLAYER_UNIT
		end

		local index = 1

		for i = 1, num_hits, 1 do
			local unit = BROADPHASE_QUERY_TEMP[i]
			local health_ext = ScriptUnit.extension(unit, "health_system")
			
			--mod:echo(Unit.get_data(unit, "unit_name"))
			
			if health_ext:is_alive() then
				local enemy_pos = POSITION_LOOKUP[unit]
				local enemy_offset = enemy_pos - search_position
				local enemy_real_dist = Vector3.length(enemy_offset)
				
				if enemy_real_dist <= check_range and self:_target_valid(unit, enemy_offset) then
					prox_enemies[index] = unit
					index = index + 1
					local enemy_dist = enemy_real_dist + ((unit == blackboard.target_unit and STICKYNESS_DISTANCE_MODIFIER) or 0)

					if closest_dist > enemy_dist then
						closest_enemy = unit
						closest_dist = enemy_dist
						closest_real_dist = enemy_real_dist
					end
				end
				
				if is_valid_elite(unit) then
					if closest_dist_elite > enemy_real_dist then
						closest_elite = unit
						closest_dist_elite = enemy_real_dist
					end
				end
			end
		end

		if blackboard.proximity_target_enemy or closest_enemy then
			blackboard.proximity_target_enemy = closest_enemy
			blackboard.proximity_target_is_player = side.VALID_ENEMY_TARGETS_PLAYERS_AND_BOTS[closest_enemy] ~= nil
		end
		
		if blackboard.elite_target or closest_elite then
			blackboard.elite_target = closest_elite
			blackboard.elite_target_is_player = side.VALID_ENEMY_TARGETS_PLAYERS_AND_BOTS[elite_target] ~= nil
		end

		blackboard.proximity_target_distance = closest_real_dist
	elseif blackboard.proximity_target_enemy and not ALIVE[blackboard.proximity_target_enemy] then
		blackboard.proximity_target_enemy = nil
		blackboard.proximity_target_distance = math.huge
		blackboard.proximity_target_is_player = nil
	end
end)
--]]
local PRIORITY_TARGETS_TEMP = {}
local NEW_TARGETS = {}
mod:hook(AIBotGroupSystem, "_update_priority_targets", function (func, self, dt, t)
	if not mod.components.aggro_tweaks.value then
		return func(self, dt, t)
	end

	local side_manager = Managers.state.side
	local bot_ai_data = self._bot_ai_data
	local old_priority_targets = self._old_priority_targets

	for side_id = 1, #bot_ai_data, 1 do
		local side = side_manager:get_side(side_id)
		local side_old_priority_targets = old_priority_targets[side_id]
		local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
		local num_players = #player_and_bot_units

		for i = 1, num_players, 1 do
			local player_unit = player_and_bot_units[i]
			local status_ext = ScriptUnit.extension(player_unit, "status_system")

			if not status_ext.near_vortex then
				local target = nil

				if status_ext:is_pounced_down() then
					target = status_ext:get_pouncer_unit()
				elseif status_ext:is_grabbed_by_pack_master() then
					target = status_ext:get_pack_master_grabber()
				elseif status_ext:is_grabbed_by_corruptor() then
					target = status_ext.corruptor_unit
				elseif status_ext:is_overpowered() then
					target = status_ext.overpowered_attacking_unit
				end

				if Unit.alive(target) then
					PRIORITY_TARGETS_TEMP[player_unit] = target
					NEW_TARGETS[target] = (side_old_priority_targets[target] or 0) + dt
				end
			end
		end

		local side_bot_data = bot_ai_data[side_id]

		for unit, data in pairs(side_bot_data) do
			if not ALIVE[data.current_priority_target] then
				data.current_priority_target = nil
			end

			local status_ext = data.status_extension

			table.clear(data.priority_targets)

			if PRIORITY_TARGETS_TEMP[unit] or status_ext:is_disabled() then
				data.current_priority_target_disabled_ally = nil
				data.current_priority_target = nil
				data.priority_target_distance = math.huge
			else
				local self_pos = POSITION_LOOKUP[unit]
				local best_target, best_ally = nil
				local best_utility = -math.huge
				local best_distance = math.huge

				for ally, target in pairs(PRIORITY_TARGETS_TEMP) do
					local utility, distance = self:_calculate_priority_target_utility(self_pos, target, NEW_TARGETS[target], data.current_priority_target)
					data.priority_targets[target] = utility

					if best_utility < utility then
						best_utility = utility
						best_target = target
						best_distance = distance
						best_ally = ally
					end
				end

				data.current_priority_target_disabled_ally = best_ally
				data.current_priority_target = best_target
				data.priority_target_distance = best_distance
			end

			local bb = data.blackboard

			if bb.priority_target_disabled_ally or data.current_priority_target_disabled_ally then
				bb.priority_target_disabled_ally = data.current_priority_target_disabled_ally
			end

			if bb.priority_target_enemy or data.current_priority_target then
				bb.priority_target_enemy = data.current_priority_target
			end

			bb.priority_target_distance = data.priority_target_distance
		end

		table.clear(PRIORITY_TARGETS_TEMP)
		table.create_copy(side_old_priority_targets, NEW_TARGETS)
		table.clear(NEW_TARGETS)
	end
end)