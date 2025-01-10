local mod = get_mod("ReplicantTemp")

local PUSHED_COOLDOWN = 1.5
local BLOCK_BROKEN_COOLDOWN = 2.5

local function is_safe_to_block_interact(status_extension, interaction_extension, wanted_interaction_type)
	local t = Managers.time:time("game")
	local pushed_t = status_extension.pushed_at_t
	local block_broken_t = status_extension.block_broken_at_t
	local enough_fatigue = true
	local is_interacting, interaction_type = interaction_extension:is_interacting()

	if not is_interacting or interaction_type ~= wanted_interaction_type then
		local current_fatigue, max_fatigue = status_extension:current_fatigue_points()
		local stamina_left = max_fatigue - current_fatigue
		local blocked_attack_cost = PlayerUnitStatusSettings.fatigue_point_costs.blocked_attack
		enough_fatigue = current_fatigue == 0 or blocked_attack_cost < stamina_left
	end

	if enough_fatigue and t > pushed_t + PUSHED_COOLDOWN and t > block_broken_t + BLOCK_BROKEN_COOLDOWN then
		return true
	else
		return false
	end
end

local revived_list = {}
local REVIVE_ATTEMPT_EXPIRE_TIME = 10
local BASE_MAX_TIME_IN_REVIVE_RANGE_WAITING = 0.7
local MAX_DISTANCE_REVIVE_SQ = 1.7 * 1.7
local MAX_Z_OFFSET_REVIVE_SQ = 1
local function can_interact_with_ally(blackboard, self_unit, target_ally_unit)
	local interactable_extension = ScriptUnit.extension(target_ally_unit, "interactable_system")
	local interactor_unit = interactable_extension:is_being_interacted_with()
	local can_interact_with_ally = interactor_unit == nil or interactor_unit == self_unit
	
	if can_interact_with_ally then
		local self_position = POSITION_LOOKUP[self_unit]
		local target_ally_aid_destination = blackboard.target_ally_aid_destination:unbox()
		local offset = target_ally_aid_destination - self_position
		local offset_sq = Vector3.length_squared(offset)
		local offset_z_sq = (offset.z)^2
		local current_time = Managers.time:time("game")
		
		if revived_list[target_ally_unit][self_unit] and current_time > revived_list[target_ally_unit][self_unit].time_get_in_range + REVIVE_ATTEMPT_EXPIRE_TIME then
			revived_list[target_ally_unit][self_unit] = nil
		end
		
		if not revived_list[target_ally_unit][self_unit] and offset_z_sq <= MAX_Z_OFFSET_REVIVE_SQ and offset_sq <= MAX_DISTANCE_REVIVE_SQ then
			revived_list[target_ally_unit][self_unit] = { time_get_in_range = current_time, randomised_revive_distance_sq = 0.0025 + (math.random())^(1.5) * 2.8875, randomised_waiting_time = BASE_MAX_TIME_IN_REVIVE_RANGE_WAITING + math.random() * 0.3 }
		end
		
		if revived_list[target_ally_unit][self_unit] and offset_z_sq <= MAX_Z_OFFSET_REVIVE_SQ and (offset_sq <= revived_list[target_ally_unit][self_unit].randomised_revive_distance_sq or (current_time > revived_list[target_ally_unit][self_unit].time_get_in_range + revived_list[target_ally_unit][self_unit].randomised_waiting_time and offset_sq <= MAX_DISTANCE_REVIVE_SQ)) then
			return true
		end
	end
	
	return false
end

-- Now requires multiple threatening elites to return true.
--[[local function is_there_threat_to_aid(self_unit, proximite_enemies, force_aid)
	local num_proximite_enemies = #proximite_enemies
	local num_threat = 0

	for i = 1, num_proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]

		if ALIVE[enemy_unit] then
			local enemy_blackboard = BLACKBOARDS[enemy_unit]
			local enemy_breed = enemy_blackboard.breed

			if enemy_blackboard.target_unit == self_unit and (not force_aid or enemy_breed.is_bot_aid_threat) then
				num_threat = num_threat + enemy_breed.threat_value
			end
		end
	end

	if num_threat > 14 then
		return true
	end

	return false
end--]]

local find_in_array = mod.utility.find_in_array

local MAX_DISTANCE_TO_CONTINUE_REVIVE = 25
-- Increased ally_distance from 1 to 1.5, allowing the bots to revive without standing on top of the downed player. Still shorter range than players.
mod:hook(BTConditions, "can_revive", function (func, blackboard)
	if not mod.components.improved_revive.value then
		return func(blackboard)
	end
	
	local target_ally_unit = blackboard.target_ally_unit

	if blackboard.interaction_unit == target_ally_unit and blackboard.target_ally_need_type == "knocked_down" then
		if not revived_list[target_ally_unit] then
			revived_list[target_ally_unit] = {}
		end
		
		---
		local interaction_extension = blackboard.interaction_extension

		if not is_safe_to_block_interact(blackboard.status_extension, interaction_extension, "revive") then
			return false
		end

		local self_unit = blackboard.unit
		--local health = ScriptUnit.extension(target_ally_unit, "health_system"):current_health_percent()

		--if health > 0.3 and is_there_threat_to_aid(self_unit, blackboard.proximite_enemies, blackboard.force_aid) then
		--	return false
		--end

		---
		local ally_distance = blackboard.ally_distance
		local is_interacting, interaction_type = interaction_extension:is_interacting()
		
		if is_interacting and (interaction_type == "revive" or interaction_type == "assisted_respawn") and ally_distance <= MAX_DISTANCE_TO_CONTINUE_REVIVE then
			return true
		end
		
		local self_position = POSITION_LOOKUP[self_unit]
		local can_interact_with_ally = can_interact_with_ally(blackboard, self_unit, target_ally_unit)

		if can_interact_with_ally then
			return true
		end
	end
	
	local side = blackboard.side
	local PLAYER_AND_BOT_UNITS = side.PLAYER_AND_BOT_UNITS
	for unit, _ in pairs(revived_list) do
		local exists = find_in_array(PLAYER_AND_BOT_UNITS, unit)
		if not exists or not ScriptUnit.extension(target_ally_unit, "status_system") or not ScriptUnit.extension(target_ally_unit, "status_system"):is_knocked_down() then
			revived_list[unit] = nil
		end
	end
	
	return false
end)

local function is_there_threat_to_aid_requiring_ability(self_unit, proximite_enemies, force_aid)
	local num_proximite_enemies = #proximite_enemies
	
	for i = 1, num_proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]

		if ALIVE[enemy_unit] then
			local enemy_blackboard = BLACKBOARDS[enemy_unit]
			local enemy_breed = enemy_blackboard.breed

			if enemy_blackboard.target_unit == self_unit and (not force_aid or enemy_breed.is_bot_aid_threat) then
				return true
			end
		end
	end

	return false
end

BTConditions.can_activate_ability_revive = function (blackboard, args)
	local career_extension = blackboard.career_extension
	local is_using_ability = blackboard.activate_ability_data.is_using_ability
	local career_name = career_extension:career_name()
	local ability_check_category_name = args[1]
	local ability_check_category = BTConditions.ability_check_categories[ability_check_category_name]
	
	if not ability_check_category or not ability_check_category[career_name] then
		return false
	end

	if ability_check_category_name == "shoot_ability" or career_name == "we_maidenguard" or career_name == "dr_slayer" or career_name == "wh_zealot" or career_name == "bw_adept" or career_name == "es_knight" or career_name == "es_questingknight" then
		return false
	end
	
	if not career_extension._abilities[1].is_ready then
		return false
	end
	
	if not is_there_threat_to_aid_requiring_ability(blackboard.unit, blackboard.proximite_enemies, false) then
		return false
	end
	
	return true
end