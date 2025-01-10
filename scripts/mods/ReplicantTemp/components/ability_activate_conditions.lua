local mod = get_mod("ReplicantTemp")

local is_unit_alive = Unit.alive

local function pos_is_near_unaggroed_patrol(pos, check_range_sq)
	local ai_group_system = Managers.state.entity:system("ai_group_system")
	
	if ai_group_system.groups_to_update then
		for id, group in pairs(ai_group_system.groups_to_update) do
			if group.group_type == "spline_patrol" and group.members then
				for patrol_unit, extension in pairs(group.members) do
					local patrol_blackboard	= patrol_unit and BLACKBOARDS[patrol_unit]
					local patrol_target		= patrol_blackboard and patrol_blackboard.target_unit
					local patrol_unit_pos		= POSITION_LOOKUP[patrol_unit]
					local patrol_unit_dist_sq	= pos and patrol_pos and Vector3.distance_squared(pos, patrol_pos)
					local patrol_has_target	= patrol_target and is_unit_alive(patrol_target)
					
					if patrol_unit_dist_sq and patrol_unit_dist_sq < check_range_sq and not patrol_has_target then
						return true
					end
				end
			end
		end
	end
end


local get_player_status = mod.utility.get_player_status

local get_status_of_players_in_radius = mod.utility.get_status_of_players_in_radius

local function get_player_fatigue_and_health(blackboard)
	local fatigue_level = blackboard.status_extension:current_fatigue() >= 60 and blackboard.status_extension:current_fatigue() / 100 or 0
	local health_level = blackboard.health_extension:current_health_percent()
	
	return fatigue_level, health_level
end

local BOSS = 1
local SPECIAL = 2
local ELITE = 3
local REGULAR = 4
local get_enemy_data = mod.utility.get_enemy_data

-----------------------------------------------------

local NORMAL_PLAYERS_NUMBER = 4
local HEALING_TEAM_HEALTH_THRESHOLD = 0.55
local ALLIES_STATUS_FACTOR_THRESHOLD = 0.6
local BOSS_THREAT_DISTANCE_SQ = 25
local STAGGERING_ABILITIES_NEEDED_THREAT_RATIO = 1

--------------------------------------------------------------------------------------------------------------------------------------------------

mod:hook(BTConditions.can_activate, "es_mercenary", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.es_mercenary then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	
	local max_heal_distance_sq = 225
	local max_stagger_distance_sq = 100
	local max_threat_distance_sq = 64
	local num_enemies_threshold = 25 * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	local threat_threshold = 50 * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	
	if pos_is_near_unaggroed_patrol(self_position, max_stagger_distance_sq) then
		return false
	end
	
	local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_heal_distance_sq)

	if num_players_needing_urgent_heal > 0 then
		--return true
	end
	
	if average_health_percent <= HEALING_TEAM_HEALTH_THRESHOLD then
		--return true
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_stagger_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target, is_unstaggered_boss = get_enemy_data(enemy_unit)
			
			if enemy_specific == BOSS then
				local is_enemy_target_disabled, enemy_target_health_percent = get_player_status(enemy_target)
				local boss_target_position = POSITION_LOOKUP[enemy_target]
				local boss_to_target_distance = boss_target_position and Vector3.distance_squared(boss_target_position, enemy_position) or math.huge
				
				if boss_to_target_distance <= BOSS_THREAT_DISTANCE_SQ and not is_unstaggered_boss and (is_enemy_target_disabled or enemy_target_health_percent <= 0.4) then
					return true
				end
			elseif enemy_distance_sq <= max_threat_distance_sq then
				total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		return true
	end
	
	return false
end)

mod:hook(BTConditions.can_activate, "es_huntsman", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.es_huntsman then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	
	local max_threat_distance_sq = 100
	local num_enemies_threshold = 15
	local threat_threshold = 35
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target = get_enemy_data(enemy_unit)
			
			total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1) * (enemy_specific == BOSS and (enemy_target == self_unit and 1 or 0) or 1)
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 10
		end
		
		local target = blackboard.target_unit
		local target_blackboard = BLACKBOARDS[target]
		local target_breed = target_blackboard and target_blackboard.breed
		if target_breed and target_breed.special then
			total_threat = total_threat + 10
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		return true
	end
	
	return false
end)

mod:hook(BTConditions.can_activate, "es_knight", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.es_knight then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	
	local max_threat_distance_sq = 64
	local min_ally_distance_sq = 25
	local max_distance_sq = 144
	local num_enemies_threshold = 15 * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	local threat_threshold = 25 * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
		
	local total_threat = 0
	local num_enemies = 0
	local charge_vector = Vector3(0, 0, 0)
	local sum_weights = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target, is_unstaggered_boss = get_enemy_data(enemy_unit)
			
			if enemy_specific == BOSS then
				local is_enemy_target_disabled, enemy_target_health_percent = get_player_status(enemy_target)
				local boss_target_position = POSITION_LOOKUP[enemy_target]
				local boss_to_target_distance = boss_target_position and Vector3.distance_squared(boss_target_position, enemy_position) or math.huge
				
				if boss_to_target_distance <= BOSS_THREAT_DISTANCE_SQ and not is_unstaggered_boss and (is_enemy_target_disabled or enemy_target_health_percent <= 0.8) then
					charge_vector = enemy_position
					local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, charge_vector, nil, 1, 1)
					
					if is_path_not_obstructed then
						blackboard.activate_ability_data.aim_position:store(charge_vector)
						
						if not pos_is_near_unaggroed_patrol(charge_vector, 10) then
							return true
						end
					end
				end
			elseif enemy_distance_sq <= max_threat_distance_sq then
				total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			if enemy_specific ~= BOSS then
				local enemy_vector = enemy_position - self_position
				local weight = enemy_specific ~= REGULAR and 1.4 or 1
				charge_vector = charge_vector + enemy_vector * weight
				sum_weights = sum_weights + weight
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	if charge_vector and sum_weights ~= 0 then
		charge_vector = charge_vector / sum_weights
		
		charge_vector = self_position + charge_vector
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		local target_ally_distance_sq = POSITION_LOOKUP[target_ally_unit] and Vector3.distance_squared(self_position, POSITION_LOOKUP[target_ally_unit]) or math.huge
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") and target_ally_distance_sq > min_ally_distance_sq and target_ally_distance_sq < max_distance_sq then
			total_threat = total_threat + 5
			
			charge_vector = POSITION_LOOKUP[target_ally_unit]
		end
		
		local target = blackboard.target_unit
		local target_blackboard = BLACKBOARDS[target]
		local target_breed = target_blackboard and target_blackboard.breed
		if target_breed and target_breed.special then
			total_threat = total_threat + 5
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, charge_vector, nil, 1, 1)
		
		if is_path_not_obstructed then
			blackboard.activate_ability_data.aim_position:store(charge_vector)
			
			if not pos_is_near_unaggroed_patrol(charge_vector, 10) then
				return true
			end
		end
	end
	
	return false
end)

mod:hook(BTConditions.can_activate, "es_questingknight", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.es_questingknight then
		return func(blackboard)
	end
	
	local target = blackboard.target_unit
	
	if not ALIVE[target] then
		return false
	end

	local target_blackboard = BLACKBOARDS[target]

	if not target_blackboard then
		return false
	end
	
	local max_threat_distance_sq = 49
	local max_target_distance_sq = 25
	local num_enemies_threshold = 20
	local threat_threshold = 40
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_double_ability = talent_extension:has_talent("markus_questing_knight_ability_double_activation")
	local _, target_specific = get_enemy_data(target)
	
	if has_double_ability and target_specific == BOSS and Vector3.distance_squared(self_position, POSITION_LOOKUP[target]) <= max_target_distance_sq then
		return true
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific = get_enemy_data(enemy_unit)
			
			if enemy_specific == BOSS then
				local is_enemy_target_disabled, enemy_target_health_percent = get_player_status(enemy_target)
				local boss_target_position = POSITION_LOOKUP[enemy_target]
				local boss_to_target_distance = boss_target_position and Vector3.distance_squared(boss_target_position, enemy_position) or math.huge
				
				if boss_to_target_distance <= BOSS_THREAT_DISTANCE_SQ and not is_unstaggered_boss and (is_enemy_target_disabled or enemy_target_health_percent <= 0.5) then
					blackboard.target_unit = enemy_unit
					
					if enemy_distance_sq <= max_target_distance_sq then
						return true
					end
				end
			elseif enemy_distance_sq <= max_threat_distance_sq then
				total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 5
			num_enemies = num_enemies + 5
		end
		
		if target_specific == SPECIAL then
			total_threat = total_threat + 10
			num_enemies = num_enemies + 3
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if not has_double_ability or target_specific ~= REGULAR then
		if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
			return true
		end
	else
		if total_threat >= threat_threshold * allies_status_factor * 2 or num_enemies >= num_enemies_threshold * allies_status_factor * 2 then
			return true
		end
	end
	
	return false
end)

--------------------------------------------------------------------------------------------------------------------------------------------------

mod:hook(BTConditions.can_activate, "dr_ranger", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.dr_ranger then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	
	local max_stagger_distance_sq = 100
	local max_threat_distance_sq = 64
	local num_enemies_threshold = 25 * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	local threat_threshold = 55 * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	
	if pos_is_near_unaggroed_patrol(self_position, max_stagger_distance_sq) then
		return false
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_stagger_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target, is_unstaggered_boss = get_enemy_data(enemy_unit)
			
			if enemy_specific == BOSS then
				local is_enemy_target_disabled, enemy_target_health_percent = get_player_status(enemy_target)
				local boss_target_position = POSITION_LOOKUP[enemy_target]
				local boss_to_target_distance = boss_target_position and Vector3.distance_squared(boss_target_position, enemy_position) or math.huge
				
				if boss_to_target_distance <= BOSS_THREAT_DISTANCE_SQ and not is_unstaggered_boss and (is_enemy_target_disabled or enemy_target_health_percent <= 0.4) then
					return true
				end
			elseif enemy_distance_sq <= max_threat_distance_sq then
				total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 10
		end
		
		local target = blackboard.target_unit
		local target_blackboard = BLACKBOARDS[target]
		local target_breed = target_blackboard and target_blackboard.breed
		if target_breed and target_breed.special then
			total_threat = total_threat + 10
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		return true
	end
	
	return false
end)

local REEVALUATION_COOLDOWN = 2.5
local next_evaluation_time = 0
local randomiser = 0
local function get_randomised_boss_reaggro_health_threshold(total_threat, threat_threshold)
	local current_time = Managers.time:time("game")
	local threat_factor = math.min(total_threat / threat_threshold, 1)
	if current_time > next_evaluation_time then
		next_evaluation_time = current_time + REEVALUATION_COOLDOWN
		randomiser = math.random() * 3 / 5
	end
					
	return math.min(0.6 + threat_factor * 0.2 + randomiser, 1)
end

mod:hook(BTConditions.can_activate, "dr_ironbreaker", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.dr_ironbreaker then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_power_ult = talent_extension:has_talent("bardin_ironbreaker_activated_ability_power_buff_allies")
	local has_boss_staggering_ult = talent_extension:has_talent("bardin_ironbreaker_activated_ability_taunt_bosses")
	local has_increased_radius_ult = talent_extension:has_talent("bardin_ironbreaker_activated_ability_taunt_range_and_duration")
	
	local max_stagger_distance_sq = has_increased_radius_ult and 132 or 100
	local max_threat_distance_sq = has_increased_radius_ult and 72 or 64
	local num_enemies_threshold = (has_power_ult and 20 or 30) * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	local threat_threshold = (has_power_ult and 45 or 65) * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	
	if pos_is_near_unaggroed_patrol(self_position, max_stagger_distance_sq) then
		return false
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_stagger_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target, is_unstaggered_boss = get_enemy_data(enemy_unit)
			
			if has_boss_staggering_ult and enemy_specific == BOSS then
				local is_enemy_target_disabled, enemy_target_health_percent = get_player_status(enemy_target)
				local boss_target_position = POSITION_LOOKUP[enemy_target]
				local boss_to_target_distance = boss_target_position and Vector3.distance_squared(boss_target_position, enemy_position) or math.huge
				
				if boss_to_target_distance <= BOSS_THREAT_DISTANCE_SQ and enemy_target ~= self_unit and 
				(is_enemy_target_disabled or enemy_target_health_percent <= get_randomised_boss_reaggro_health_threshold(total_threat, threat_threshold)) then
					return true
				end
			elseif enemy_distance_sq <= max_threat_distance_sq then
				total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 15
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		return true
	end
	
	return false
end)

mod:hook(BTConditions.can_activate, "dr_slayer", function (func, blackboard)	
	if not mod.components.regular_active_abilities.detailed_settings.dr_slayer then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_staggering_ult = talent_extension:has_talent("bardin_slayer_activated_ability_impact_damage")
	
	local max_threat_distance_sq = 64
	local min_ally_distance_sq = 25
	local max_distance_sq = 100
	local num_enemies_threshold = 15
	local threat_threshold = 20
		
	local total_threat = 0
	local num_enemies = 0
	local leap_vector = Vector3(0, 0, 0)
	local sum_weights = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target, is_unstaggered_boss = get_enemy_data(enemy_unit)
			
			local enemy_vector = enemy_position - self_position
			local weight = enemy_specific ~= REGULAR and 1.4 or 1
			leap_vector = leap_vector + enemy_vector * weight
			sum_weights = sum_weights + weight
			
			total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			num_enemies = num_enemies + 1
		end
	end
	
	if leap_vector and sum_weights ~= 0 then
		leap_vector = leap_vector / sum_weights
		leap_vector = self_position + leap_vector
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		local target_ally_distance_sq = POSITION_LOOKUP[target_ally_unit] and Vector3.distance_squared(self_position, POSITION_LOOKUP[target_ally_unit]) or math.huge
		
		if has_staggering_ult and is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") and target_ally_distance_sq > min_ally_distance_sq and target_ally_distance_sq < max_distance_sq then
			total_threat = total_threat + 5
			
			leap_vector = POSITION_LOOKUP[target_ally_unit]
		end
		
		local target = blackboard.target_unit
		local target_blackboard = BLACKBOARDS[target]
		local target_breed = target_blackboard and target_blackboard.breed
		if target_breed and target_breed.special then
			total_threat = total_threat + 5
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, leap_vector, nil, 1, 1)
		
		if is_path_not_obstructed then
			blackboard.activate_ability_data.aim_position:store(leap_vector)
			
			if not pos_is_near_unaggroed_patrol(leap_vector, 10) then
				return true
			end
		end
	end
	
	return false
end)

--------------------------------------------------------------------------------------------------------------------------------------------------

mod:hook(BTConditions.can_activate, "we_waywatcher", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.we_waywatcher then
		return func(blackboard)
	end
	
	local target = blackboard.target_unit

	if not ALIVE[target] then
		return false
	end

	if not BLACKBOARDS[target] then
		return false
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_piercing_shot_ult = talent_extension:has_talent("kerillian_waywatcher_activated_ability_piercing_shot")
	local has_ammo_restore_ult = talent_extension:has_talent("kerillian_waywatcher_activated_ability_restore_ammo_on_career_skill_special_kill")
	local has_double_arrow_on_melee_kill = talent_extension:has_talent("kerillian_waywatcher_extra_arrow_melee_kill")
	
	local max_shot_distance = 80
	local max_threat_distance_sq = 100
	local num_enemies_threshold = 15
	local threat_threshold = 35
	
	local _, target_specific = get_enemy_data(target)
	local target_blackboard = BLACKBOARDS[target]
	local target_breed = target_blackboard and target_blackboard.breed
	local target_breed_name = target_breed and target_breed.name
	local conflict_director = Managers.state.conflict
	local alive_bosses = conflict_director:alive_bosses()
	local num_alive_bosses = alive_bosses and #alive_bosses or 0
	local no_bosses = not alive_bosses or num_alive_bosses == 0
	
	local is_globadier = target_breed_name == "skaven_poison_wind_globadier"
	local is_gutter_runner = target_breed_name == "skaven_gutter_runner"
	local is_cw = target_breed_name == "chaos_warrior"
	local is_boss = target_specific == BOSS
	local is_elite = not is_cw and target_specific == ELITE
	local good_priority_target = target == blackboard.priority_target_enemy and blackboard.priority_target_distance <= max_shot_distance and blackboard.priority_target_distance > 1
	local good_opportunity_target = target == blackboard.opportunity_target_enemy and blackboard.opportunity_target_distance <= 7 and blackboard.opportunity_target_distance > 1 and not is_gutter_runner and not is_globadier
	local good_urgent_target = target == blackboard.urgent_target_enemy and blackboard.urgent_target_distance <= max_shot_distance and blackboard.urgent_target_distance > 1 and not is_boss and not is_globadier
	local good_cw_target = target and target_breed_name == "chaos_warrior" and Vector3.distance_squared(self_position, POSITION_LOOKUP[target]) <= 225
	local good_boss_target = target == blackboard.urgent_target_enemy and blackboard.urgent_target_distance <= 15 and is_boss
	
	local good_elite_target = false
	--if is_elite then
	--	local target_locomotion_extension = ScriptUnit.has_extension(target, "locomotion_system")
	--	local target_current_velocity = (target_locomotion_extension and target_locomotion_extension:current_velocity()) or Vector3.zero()
	--	good_elite_target = is_elite and Vector3.distance_squared(self_position, POSITION_LOOKUP[target]) <= 625 and Vector3.length_squared(target_current_velocity) < 4
	--end
	
	if has_piercing_shot_ult and target_specific ~= REGULAR and ((no_bosses and (good_urgent_target or good_opportunity_target or good_cw_target or good_elite_target)) or good_boss_target or good_priority_target) then
		local obstruction = blackboard.ranged_obstruction_by_static
		local t = Managers.time:time("game")
		local obstructed = obstruction and obstruction.unit == target and t <= obstruction.timer + 0.3
		
		return not obstructed
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific = get_enemy_data(enemy_unit)
			
			total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1) * (enemy_specific == SPECIAL and 1.66667 or 1) * (enemy_specific == BOSS and 0 or 1)
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 5
			num_enemies = num_enemies + 5
		end
		
		if target_breed and target_breed.special then
			total_threat = total_threat + 10
			num_enemies = num_enemies + 3
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end
	
	local has_worthwhile_target = false
	local buff_extension = ScriptUnit.extension(self_unit, "buff_system")
	local has_double_arrow_buff = buff_extension:has_buff_type("kerillian_waywatcher_extra_arrow_melee_kill_buff")
	
	if has_piercing_shot_ult and target_specific == ELITE then
		if total_threat >= threat_threshold * allies_status_factor * 0.75 or num_enemies >= num_enemies_threshold * allies_status_factor * 0.75 then
			has_worthwhile_target = true
		end
	elseif not has_piercing_shot_ult and not has_ammo_restore_ult then
		if not has_double_arrow_on_melee_kill or has_double_arrow_buff then
			if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
				has_worthwhile_target = true
			end
		else
			if total_threat >= threat_threshold * allies_status_factor * 1.75 or num_enemies >= num_enemies_threshold * allies_status_factor * 1.75 then
				has_worthwhile_target = true
			end
		end
	elseif has_ammo_restore_ult then
		local inventory_extension = ScriptUnit.extension(self_unit, "inventory_system")
		local ammo_percentage = inventory_extension:ammo_percentage()
		
		if not has_double_arrow_on_melee_kill or has_double_arrow_buff then
			if (target_specific ~= REGULAR and ammo_percentage >= 0.5 and (total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor)) or
			(target_specific ~= REGULAR and ammo_percentage < 0.5) or
			(target_specific == REGULAR and ammo_percentage >= 0.5 and (total_threat >= threat_threshold * allies_status_factor * 1.5 or num_enemies >= num_enemies_threshold * allies_status_factor * 1.5)) then
				has_worthwhile_target = true
			end
		else
			if (target_specific ~= REGULAR and ammo_percentage >= 0.5 and (total_threat >= threat_threshold * allies_status_factor * 1.75 or num_enemies >= num_enemies_threshold * allies_status_factor * 1.75)) or
			(target_specific ~= REGULAR and ammo_percentage < 0.15) or
			(target_specific == REGULAR and ammo_percentage >= 0.5 and (total_threat >= threat_threshold * allies_status_factor * 2.25 or num_enemies >= num_enemies_threshold * allies_status_factor * 2.25)) then
				has_worthwhile_target = true
			end
		end
	end
	
	if has_worthwhile_target then
		local obstruction = blackboard.ranged_obstruction_by_static
		local t = Managers.time:time("game")
		local obstructed = obstruction and obstruction.unit == target and t <= obstruction.timer + 0.2
		
		return not obstructed
	else
		return false
	end
end)

mod:hook(BTConditions.can_activate, "we_maidenguard", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.we_maidenguard then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_invis_ult = talent_extension:has_talent("kerillian_maidenguard_activated_ability_invis_duration")
	local has_bleeds_ult = talent_extension:has_talent("kerillian_maidenguard_activated_ability_damage")
	
	local min_ally_distance_sq = 25
	local max_distance_sq = 100
	local max_threat_distance_sq = 64
	local num_enemies_threshold = 15
	local threat_threshold = 25
		
	local total_threat = 0
	local num_enemies = 0
	local charge_vector = Vector3(0, 0, 0)
	local sum_weights = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target, is_unstaggered_boss, is_superarmoured = get_enemy_data(enemy_unit)
			
			local enemy_vector = enemy_position - self_position
			local weight = enemy_specific ~= REGULAR and 1.4 or 1
			charge_vector = charge_vector + enemy_vector * weight
			sum_weights = sum_weights + weight
			
			total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1) * ((is_superarmoured and has_bleeds_ult) and 0 or 1)
			num_enemies = num_enemies + 1
		end
	end
	
	if charge_vector and sum_weights ~= 0 then
		charge_vector = charge_vector / sum_weights
		charge_vector = self_position + charge_vector
		
		if has_invis_ult then
			charge_vector = charge_vector * 0.7
		end
		
		local vector_length = Vector3.length(charge_vector)
		if vector_length < 1.5 then
			charge_vector = charge_vector * (1.5 / vector_length)
		end
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 7 + (1 - bot_health) * 7
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		local target_ally_distance_sq = POSITION_LOOKUP[target_ally_unit] and Vector3.distance_squared(self_position, POSITION_LOOKUP[target_ally_unit]) or math.huge
		
		if has_invis_ult and is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") and target_ally_distance_sq > min_ally_distance_sq and target_ally_distance_sq < max_distance_sq then
			total_threat = total_threat + 5
			
			charge_vector = POSITION_LOOKUP[target_ally_unit]
		end
		
		local target = blackboard.target_unit
		local target_blackboard = BLACKBOARDS[target]
		local target_breed = target_blackboard and target_blackboard.breed
		if target_breed and target_breed.special then
			total_threat = total_threat + 5
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, charge_vector, nil, 1, 1)
		
		if is_path_not_obstructed then
			blackboard.activate_ability_data.aim_position:store(charge_vector)
			
			if not pos_is_near_unaggroed_patrol(charge_vector, 10) then
				return true
			end
		end
	end
	
	return false
end)

mod:hook(BTConditions.can_activate, "we_shade", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.we_shade then
		return func(blackboard)
	end
	
	local target = blackboard.target_unit

	if not ALIVE[target] then
		return false
	end

	if not BLACKBOARDS[target] then
		return false
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_combo_ult = talent_extension:has_talent("kerillian_shade_activated_stealth_combo")
	--local has_phasing_ult = talent_extension:has_talent("kerillian_shade_activated_ability_phasing")
	--local has_restealth_ult = talent_extension:has_talent("kerillian_shade_activated_ability_restealth")
	
	local max_threat_distance_sq = 100
	local num_enemies_threshold = 20
	local threat_threshold = 30
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target = get_enemy_data(enemy_unit)
			
			if enemy_specific == BOSS then
				
				if enemy_distance_sq <= BOSS_THREAT_DISTANCE_SQ then
					local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, enemy_position, nil, 1, 1)
					
					if is_path_not_obstructed then
						blackboard.target_unit = enemy_unit
						return true
					end
				end
			else
				total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	local target_blackboard = BLACKBOARDS[target]
	local target_breed = target_blackboard and target_blackboard.breed
	local target_threat_value = (target_breed and target_breed.threat_value) or 0
	
	local dash_position = nil
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 5 + (1 - bot_health) * 5
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 10
		end
		
		if target_breed and target_breed.special then
			total_threat = total_threat + 10
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end
	
	local target_unit = blackboard.target_unit
	local target_position = target_unit and POSITION_LOOKUP[target_unit]
	local target_distance_sq = Vector3.distance_squared(self_position, target_position)
	local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, target_position, nil, 1, 1)
	local has_reachable_target = target_position and target_distance_sq < 25 and is_path_not_obstructed
	
	if has_phasing_ult and (total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor) and has_reachable_target then
		return true
	elseif --[[(has_combo_ult or has_restealth_ult) and--]] (total_threat >= threat_threshold * allies_status_factor * 2 or num_enemies >= num_enemies_threshold * allies_status_factor * 2 or target_threat_value >= 12) and has_reachable_target then
		return true
	end
	
	return false
end)

mod:hook(BTConditions.can_activate, "we_thornsister", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.we_thornsister then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.has_extension(self_unit, "talent_system")
	local has_explosion_ult = talent_extension:has_talent("kerillian_thorn_sister_debuff_wall")
	local has_push_ult = talent_extension:has_talent("kerillian_thorn_sister_wall_push")
	local has_additional_buff_ult = talent_extension:has_talent("kerillian_thorn_sister_passive_team_buff")
	
	local max_distance_sq = 144
	local num_enemies_threshold = 20
	local threat_threshold = 25
	
	local total_threat = 0
	local num_enemies = 0
	local ability_vector = Vector3(0, 0, 0)
	local sum_weights = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target = get_enemy_data(enemy_unit)
			
			if enemy_specific == BOSS and not has_push_ult then
				local is_enemy_target_disabled, enemy_target_health_percent = get_player_status(enemy_target)
				local boss_target_position = POSITION_LOOKUP[enemy_target]
				local boss_to_target_distance = boss_target_position and Vector3.distance_squared(boss_target_position, enemy_position) or math.huge
				
				if boss_to_target_distance <= BOSS_THREAT_DISTANCE_SQ then
					ability_vector = has_explosion_ult and enemy_position or enemy_position * 0.6
					--[[local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, ability_vector, nil, 1, 1)
					
					if is_path_not_obstructed then
						blackboard.activate_ability_data.aim_position:store(ability_vector)
						
						if not pos_is_near_unaggroed_patrol(ability_vector, 4) then
							return true
						end
					end--]]
					if not pos_is_near_unaggroed_patrol(ability_vector, 4) then
						blackboard.activate_ability_data.aim_position:store(ability_vector)
						return true
					end
				end
			elseif enemy_specific ~= BOSS then
				total_threat = total_threat + enemy_threat_value * ((has_explosion_ult or has_push_ult) and (enemy_specific == SPECIAL and 2 or (enemy_specific == ELITE and 1.5 or 1)) or (enemy_specific ~= REGULAR and 1.5 or 1)) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			if enemy_specific ~= BOSS then
				local enemy_vector = enemy_position - self_position
				local weight = (has_explosion_ult and (enemy_specific == SPECIAL and 5 or (enemy_specific == ELITE and 1 or 0.2)) or 1)
				ability_vector = ability_vector + enemy_vector * weight
				sum_weights = sum_weights + weight
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	if ability_vector and sum_weights ~= 0 then
		ability_vector = ability_vector / sum_weights
		
		if has_push_ult then
			ability_vector = ability_vector * 1.3
		elseif not has_explosion_ult then
			ability_vector = ability_vector * 0.7
		end
		
		local vector_length = Vector3.length(ability_vector)

		if vector_length < (has_push_ult and 2.5 or 1) then
			ability_vector = ability_vector * ((has_push_ult and 2.5 or 1) / vector_length)
		end
		
		ability_vector = self_position + ability_vector
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 5 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 5
			num_enemies = num_enemies + 5
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end
	
	local career_extension = blackboard.career_extension
	local has_additional_ability = career_extension and career_extension:get_extra_ability_uses() > 0 or false
	local regular_ability_cd = career_extension and career_extension:current_ability_cooldown_percentage(1) or 0
	if has_additional_ability and regular_ability_cd > 0 then
		if has_additional_buff_ult then
			if total_threat >= threat_threshold * allies_status_factor * 1.7 or num_enemies >= num_enemies_threshold * allies_status_factor * 1.5 then
				--[[local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, ability_vector, nil, 1, 1)
				
				if is_path_not_obstructed then
					blackboard.activate_ability_data.aim_position:store(ability_vector)
					
					if not pos_is_near_unaggroed_patrol(ability_vector, 4) then
						return true
					end
				end--]]
				if not pos_is_near_unaggroed_patrol(ability_vector, 4) then
					blackboard.activate_ability_data.aim_position:store(ability_vector)
					return true
				end
			end
		else
			if total_threat >= threat_threshold * allies_status_factor * 1.5 or num_enemies >= num_enemies_threshold * allies_status_factor * 1.3 then
				--[[local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, ability_vector, nil, 1, 1)
				
				if is_path_not_obstructed then
					blackboard.activate_ability_data.aim_position:store(ability_vector)
					
					if not pos_is_near_unaggroed_patrol(ability_vector, 4) then
						return true
					end
				end--]]
				if not pos_is_near_unaggroed_patrol(ability_vector, 4) then
					blackboard.activate_ability_data.aim_position:store(ability_vector)
					return true
				end
			end
		end
	else
		if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
			--[[local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, ability_vector, nil, 1, 1)
			
			if is_path_not_obstructed then
				blackboard.activate_ability_data.aim_position:store(ability_vector)
				
				if not pos_is_near_unaggroed_patrol(ability_vector, 4) then
					return true
				end
			end--]]
			if not pos_is_near_unaggroed_patrol(ability_vector, 4) then
				blackboard.activate_ability_data.aim_position:store(ability_vector)
				return true
			end
		end
	end
	
	return false
end)

--------------------------------------------------------------------------------------------------------------------------------------------------

local is_secondary_within_cone = function(self_unit, target_unit, secondary_unit, cone_angle_deg)	-- check if a secondary target unit is within the specified cone centered to the line from self to target
	local ret = false
	if Unit.alive(self_unit) and Unit.alive(target_unit) and Unit.alive(secondary_unit) then
		local self_pos = POSITION_LOOKUP[self_unit]
		local target_pos = POSITION_LOOKUP[target_unit]
		local secondary_pos = POSITION_LOOKUP[secondary_unit]
		local target_vector = target_pos - self_pos
		local secondary_vector = secondary_pos - self_pos
		
		if Vector3.length(target_vector) > 0 and Vector3.length(secondary_vector) > 0 then
			-- essentially, calculate the dot product of normalized self-target, self-secondary vectors = cosine of the angle between those two vectors
			local secondary_deviation_angle_cos = Vector3.dot(Vector3.normalize(target_vector), Vector3.normalize(secondary_vector))
			-- then get the actual angle from the cosine and convert it into degrees
			local secondary_deviation_angle_deg = (math.acos(secondary_deviation_angle_cos) / math.pi) * 180
			
			-- "cone_angle_deg/2" because secondary_deviation_angle_deg equals half of the opening angle of the cone inside which the secondary currently is
			if secondary_deviation_angle_deg <= (cone_angle_deg/2) then
				ret = true
			end
		end
	end
	
	return ret
end

mod:hook(BTConditions.can_activate, "wh_captain", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.wh_captain then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	
	local max_stagger_distance_sq = 100
	local max_threat_distance_sq = 64
	local num_enemies_threshold = 27 * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	local threat_threshold = 55 * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	
	if pos_is_near_unaggroed_patrol(self_position, max_stagger_distance_sq) then
		return false
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_stagger_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target, is_unstaggered_boss = get_enemy_data(enemy_unit)
			
			if enemy_specific == BOSS then
				local is_enemy_target_disabled, enemy_target_health_percent = get_player_status(enemy_target)
				local boss_target_position = POSITION_LOOKUP[enemy_target]
				local boss_to_target_distance = boss_target_position and Vector3.distance_squared(boss_target_position, enemy_position) or math.huge
				
				if boss_to_target_distance <= BOSS_THREAT_DISTANCE_SQ then
					blackboard.target_unit = enemy_unit
					return true
				end
			elseif enemy_distance_sq <= max_threat_distance_sq then
				total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 10
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		return true
	end
	
	return false
end)

mod:hook(BTConditions.can_activate, "wh_bountyhunter", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.wh_bountyhunter then
		return func(blackboard)
	end
	
	local target = blackboard.target_unit

	if not ALIVE[target] then
		return false
	end

	if not BLACKBOARDS[target] then
		return false
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_blast_shot = talent_extension:has_talent("victor_bountyhunter_activated_ability_blast_shotgun")
	
	local max_shot_distance = 30
	local max_blast_distance_sq = 100
	local max_threat_distance_sq = 100
	local num_enemies_threshold = 20
	local threat_threshold = 40
	
	local _, target_specific = get_enemy_data(target)
	local target_blackboard = BLACKBOARDS[target]
	local target_breed = target_blackboard and target_blackboard.breed
	local target_breed_name = target_breed and target_breed.name
	local has_cw_target = target and target_breed_name == "chaos_warrior"

	if not has_blast_shot and ((target == blackboard.urgent_target_enemy and target_specific == BOSS and blackboard.urgent_target_distance <= max_shot_distance) or (has_cw_target and Vector3.distance_squared(self_position, POSITION_LOOKUP[target]) <= max_shot_distance * max_shot_distance)) then
		local obstruction = blackboard.ranged_obstruction_by_static
		local t = Managers.time:time("game")
		local obstructed = obstruction and obstruction.unit == target and t <= obstruction.timer + 0.2
		
		return not obstructed
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific = get_enemy_data(enemy_unit)
			
			total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 5
			num_enemies = num_enemies + 5
		end
		
		if BLACKBOARDS[blackboard.target_unit].breed.special then
			total_threat = total_threat + 10
			num_enemies = num_enemies + 3
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end
	
	local has_worthwhile_target = false
	if not has_blast_shot then
		if target_specific ~= REGULAR and (total_threat >= threat_threshold * allies_status_factor * 2 or num_enemies >= num_enemies_threshold * allies_status_factor * 2) then
			has_worthwhile_target = true
		end
	else
		if total_threat >= threat_threshold * allies_status_factor * 2 or num_enemies >= num_enemies_threshold * allies_status_factor * 2 then
			has_worthwhile_target = true
		end
	end
	
	if has_worthwhile_target then
		local obstruction = blackboard.ranged_obstruction_by_static
		local t = Managers.time:time("game")
		local obstructed = obstruction and obstruction.unit == target and t <= obstruction.timer + 0.2

		if not obstructed then
			local ai_group_system = Managers.state.entity:system("ai_group_system")
			local patrol_in_cone = false
			
			if ai_group_system.groups_to_update then
				for id, group in pairs(ai_group_system.groups_to_update) do
					if group.group_type == "spline_patrol" and group.members then
						for patrol_unit, extension in pairs(group.members) do
							local patrol_blackboard	= patrol_unit and BLACKBOARDS[patrol_unit]
							local patrol_target		= patrol_blackboard and patrol_blackboard.target_unit
							local patrol_pos		= POSITION_LOOKUP[patrol_unit]
							local patrol_dist		= self_pos and patrol_pos and Vector3.length(patrol_pos - self_pos)
							-- local patrol_has_target	= patrol_target and Unit.alive(patrol_target)
							local patrol_has_target	= patrol_target and is_unit_alive(patrol_target)
							
							if patrol_dist and patrol_dist < 60 and is_secondary_within_cone(self_unit, target_unit, patrol_unit, 20) and not patrol_has_target then
								patrol_in_cone = true
								break
							end
						end
					end
				end
			end
			
			return not patrol_in_cone
		end
	end
	
	return false
end)

mod:hook(BTConditions.can_activate, "wh_zealot", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.wh_zealot then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	
	local min_ally_distance_sq = 25
	local max_distance_sq = 100
	local max_threat_distance_sq = 64
	local num_enemies_threshold = 15
	local threat_threshold = 25
		
	local total_threat = 0
	local num_enemies = 0
	local charge_vector = Vector3(0, 0, 0)
	local sum_weights = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target, is_unstaggered_boss, is_superarmoured = get_enemy_data(enemy_unit)
			
			local enemy_vector = enemy_position - self_position
			local weight = enemy_specific ~= REGULAR and 1.4 or 1
			charge_vector = charge_vector + enemy_vector * weight
			sum_weights = sum_weights + weight
			
			total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			num_enemies = num_enemies + 1
		end
	end
	
	if charge_vector and sum_weights ~= 0 then
		charge_vector = charge_vector / sum_weights
		charge_vector = self_position + charge_vector
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 5 + (1 - bot_health) * 2
		num_enemies = num_enemies + bot_fatigue * 2 + (1 - bot_health) * 1
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		local target_ally_distance_sq = POSITION_LOOKUP[target_ally_unit] and Vector3.distance_squared(self_position, POSITION_LOOKUP[target_ally_unit]) or math.huge
		
		if has_staggering_ult and is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") and target_ally_distance_sq > min_ally_distance_sq and target_ally_distance_sq < max_distance_sq then
			total_threat = total_threat + 5
			
			charge_vector = POSITION_LOOKUP[target_ally_unit]
		end
		
		local target = blackboard.target_unit
		local target_blackboard = BLACKBOARDS[target]
		local target_breed = target_blackboard and target_blackboard.breed
		if target_breed and target_breed.special then
			total_threat = total_threat + 5
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, charge_vector, nil, 1, 1)
		
		if is_path_not_obstructed then
			blackboard.activate_ability_data.aim_position:store(charge_vector)
			
			if not pos_is_near_unaggroed_patrol(charge_vector, 10) then
				return true
			end
		end
	end
	
	return false
end)

--------------------------------------------------------------------------------------------------------------------------------------------------

local previous_ult_time = -10
local SIENNA_DOUBLE_ULT_CD = 10
mod:hook(BTConditions.can_activate, "bw_adept", function (func, blackboard)	
	if not mod.components.regular_active_abilities.detailed_settings.bw_adept then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_double_ult = talent_extension:has_talent("sienna_adept_ability_trail_double")
	local current_time = Managers.time:time("game")
	local has_free_ult = current_time <= previous_ult_time + SIENNA_DOUBLE_ULT_CD
	
	local min_ally_distance_sq = 25
	local max_distance_sq = 100
	local max_threat_distance_sq = 100
	local num_enemies_threshold = 20 * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	local threat_threshold = 30 * STAGGERING_ABILITIES_NEEDED_THREAT_RATIO
	
	if has_free_ult then
		num_enemies_threshold = num_enemies_threshold * 0.3555
		threat_threshold = threat_threshold * 0.4
	else
		previous_ult_time = -10
	end
	
	local total_threat = 0
	local num_enemies = 0
	local leap_vector = Vector3(0, 0, 0)
	local sum_weights = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target, is_unstaggered_boss = get_enemy_data(enemy_unit)
			
			if enemy_specific == BOSS then
				local is_enemy_target_disabled, enemy_target_health_percent = get_player_status(enemy_target)
				local boss_target_position = POSITION_LOOKUP[enemy_target]
				local boss_to_target_distance = boss_target_position and Vector3.distance_squared(boss_target_position, enemy_position) or math.huge
				
				if boss_to_target_distance <= BOSS_THREAT_DISTANCE_SQ and not is_unstaggered_boss and (is_enemy_target_disabled or enemy_target_health_percent <= (has_free_ult and 1 or 0.7)) then
					leap_vector = enemy_position
					local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, leap_vector, nil, 1, 1)
					
					if is_path_not_obstructed then
						blackboard.activate_ability_data.aim_position:store(leap_vector)
						
						if has_double_ult then
							previous_ult_time = current_time
						end
						
						if not pos_is_near_unaggroed_patrol(leap_vector, 10) then
							return true
						end
					end
				end
			elseif enemy_distance_sq <= max_threat_distance_sq then
				total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			if enemy_specific ~= BOSS then
				local enemy_vector = enemy_position - self_position
				local weight = enemy_specific ~= REGULAR and 1.4 or 1
				leap_vector = leap_vector + enemy_vector * weight
				sum_weights = sum_weights + weight
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	if leap_vector and sum_weights ~= 0 then
		leap_vector = leap_vector / sum_weights
		leap_vector = self_position + leap_vector
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 5 + (1 - bot_health) * 5
		num_enemies = num_enemies + bot_fatigue * 3 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		local ally_position = target_ally_unit and POSITION_LOOKUP[target_ally_unit] or nil	
		local target_ally_distance_sq = ally_position and Vector3.distance_squared(self_position, ally_position) or math.huge
		
		if has_staggering_ult and is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") and target_ally_distance_sq > min_ally_distance_sq and target_ally_distance_sq < max_distance_sq then
			total_threat = total_threat + 5
			
			leap_vector = POSITION_LOOKUP[target_ally_unit]
		end
		
		local target = blackboard.target_unit
		local target_blackboard = BLACKBOARDS[target]
		local target_breed = target_blackboard and target_blackboard.breed
		if target_breed and target_breed.special then
			total_threat = total_threat + 10
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end
	
	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		local is_path_not_obstructed = LocomotionUtils.ray_can_go_on_mesh(blackboard.nav_world, self_position, leap_vector, nil, 1, 1)
		
		if is_path_not_obstructed then
			blackboard.activate_ability_data.aim_position:store(leap_vector)
			
			if has_double_ult then
				previous_ult_time = current_time
			end
						
			if not pos_is_near_unaggroed_patrol(leap_vector, 10) then
				return true
			end
		end
	end
	
	return false
end)

mod:hook(BTConditions.can_activate, "bw_scholar", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.bw_scholar then
		return func(blackboard)
	end
	
	local target = blackboard.target_unit

	if not ALIVE[target] then
		return false
	end

	if not BLACKBOARDS[target] then
		return false
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_healing_ult = talent_extension:has_talent("sienna_scholar_activated_ability_heal")
	local has_crit_refresh_ult = talent_extension:has_talent("sienna_scholar_activated_ability_crit_refresh_cooldown")
	
	local max_shot_distance = 30
	local max_threat_distance_sq = 100
	local num_enemies_threshold = 15
	local threat_threshold = 25
	
	local _, target_specific = get_enemy_data(target)
	local target_blackboard = BLACKBOARDS[target]
	local target_breed = target_blackboard and target_blackboard.breed
	local target_breed_name = target_breed and target_breed.name
	
	local health_percent = blackboard.health_extension:current_health_percent()
	if has_healing_ult and health_percent <= 0.2 and target then
		local obstruction = blackboard.ranged_obstruction_by_static
		local t = Managers.time:time("game")
		local obstructed = obstruction and obstruction.unit == target and t <= obstruction.timer + 0.2

		return not obstructed
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific = get_enemy_data(enemy_unit)
			
			total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 5
			num_enemies = num_enemies + 5
		end
		
		if BLACKBOARDS[blackboard.target_unit].breed.special then
			total_threat = total_threat + 10
			num_enemies = num_enemies + 3
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end
	
	local has_worthwhile_target = false
	if has_healing_ult then
		if total_threat >= threat_threshold * allies_status_factor * health_percent or num_enemies >= num_enemies_threshold * allies_status_factor * health_percent then
			has_worthwhile_target = true
		end
	elseif has_crit_refresh_ult then
		local overcharge_extension = blackboard.overcharge_extension
		local overcharge_value, _, max_overcharge_value = overcharge_extension:current_overcharge_status()
		local overcharge_percent = overcharge_value / max_overcharge_value
		
		if total_threat >= threat_threshold * allies_status_factor / (0.4 + overcharge_percent) or num_enemies >= num_enemies_threshold * allies_status_factor / (0.1 + overcharge_percent) then
			has_worthwhile_target = true
		end
	else
		if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
			has_worthwhile_target = true
		end
	end
	
	if has_worthwhile_target then
		local obstruction = blackboard.ranged_obstruction_by_static
		local t = Managers.time:time("game")
		local obstructed = obstruction and obstruction.unit == target and t <= obstruction.timer + 0.2

		return not obstructed
	else
		return false
	end
end)

mod:hook(BTConditions.can_activate, "bw_unchained", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.bw_unchained then
		return func(blackboard)
	end
	
	local overcharge_extension = blackboard.overcharge_extension
	local is_exploding = overcharge_extension:are_you_exploding()

	if is_exploding then
		return true
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_healing_ult = talent_extension:has_talent("sienna_unchained_activated_ability_temp_health")
	local has_boss_staggering_ult = talent_extension:has_talent("sienna_unchained_activated_ability_fire_aura")
	
	local max_heal_distance_sq = 100
	local max_stagger_distance_sq = 25
	local max_threat_distance_sq = 25
	local num_enemies_threshold = has_healing_ult and 50 or 35
	local threat_threshold = has_healing_ult and 150 or 70
	
	if pos_is_near_unaggroed_patrol(self_position, max_stagger_distance_sq) then
		return false
	end
	
	local num_players_in_range, average_health_percent, num_players_needing_urgent_heal, num_active_players = get_status_of_players_in_radius(blackboard, self_position, max_heal_distance_sq)
	
	if has_healing_ult then
		if num_players_needing_urgent_heal > (num_active_players > 2 and 2 or 1) then
			return true
		end
		
		if average_health_percent <= HEALING_TEAM_HEALTH_THRESHOLD / 1.5 then
			return true
		end
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific, enemy_target = get_enemy_data(enemy_unit)
			
			if has_boss_staggering_ult and enemy_specific == BOSS then
				local is_enemy_target_disabled, enemy_target_health_percent = get_player_status(enemy_target)
				local boss_target_position = POSITION_LOOKUP[enemy_target]
				local boss_to_target_distance = boss_target_position and Vector3.distance_squared(boss_target_position, enemy_position) or math.huge
				
				if boss_to_target_distance <= BOSS_THREAT_DISTANCE_SQ and not is_unstaggered_boss and (is_enemy_target_disabled or enemy_target_health_percent <= 0.4) then
					blackboard.target_unit = enemy_unit
					return true
				end
			elseif enemy_distance_sq <= max_threat_distance_sq then
				total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 10
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end

	if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
		return true
	end
	
	return false
end)

--------------------------------------------------------------------------------------------------------------------------------------------------

local NOT_USED = -1
local STAGGERING_ABILITIES = {
	es_mercenary = { stagger_end_time = NOT_USED, threat_reduce_end_time = NOT_USED },
	es_knight = { stagger_end_time = NOT_USED, threat_reduce_end_time = NOT_USED },
	dr_ironbreaker = { stagger_end_time = NOT_USED, threat_reduce_end_time = NOT_USED },
	we_thornsister = { stagger_end_time = NOT_USED, threat_reduce_end_time = NOT_USED },
	wh_captain = { stagger_end_time = NOT_USED, threat_reduce_end_time = NOT_USED },
	bw_adept = { stagger_end_time = NOT_USED, threat_reduce_end_time = NOT_USED }
}

local function update_staggering_abilities(current_time)
	local stagger = false
	local threat_reduce = false
	
	for career, ability in pairs(STAGGERING_ABILITIES) do
		if ability.stagger_end_time ~= NOT_USED then
			if current_time <= ability.stagger_end_time then
				stagger = true
			end
			
			if current_time <= ability.threat_reduce_end_time then
				threat_reduce = true
			elseif current_time > ability.threat_reduce_end_time then
				ability.stagger_end_time = NOT_USED
				ability.threat_reduce_end_time = NOT_USED
			end
		end
	end
	
	return stagger, threat_reduce
end

local BASE_STAGGER_ABILITY_TIME = 1.5
local BASE_THREAT_REDUCE_ABILITY_TIME = 3.5

mod:hook(BTConditions, "can_activate_ability", function (func, blackboard, args)
	if mod.components.rescue_allies_active_ability.value then
		can_rescue = BTConditions.can_activate_ability_to_rescue_ally(blackboard, args)
		if can_rescue then
			return true
		end
	end
	
	if not mod.components.regular_active_abilities.value then
		return func(blackboard, args)
	end
	
	local career_extension = blackboard.career_extension
	local is_using_ability = blackboard.activate_ability_data.is_using_ability
	local career_name = career_extension:career_name()
	local ability_check_category_name = args[1]
	local ability_check_category = BTConditions.ability_check_categories[ability_check_category_name]

	if not ability_check_category or not ability_check_category[career_name] then
		return false
	end

	if ability_check_category_name == "shoot_ability" and (not blackboard.target_unit or not ALIVE[blackboard.target_unit] or not Unit.has_data(blackboard.target_unit, "breed")) then
		return false
	end

	local condition_function = BTConditions.can_activate[career_name]

	if ability_check_category_name == "ranged_weapon" or ability_check_category_name == "melee_weapon" then
		return condition_function and condition_function(blackboard)
	end
	
	if ability_check_category_name == "shoot_ability" then
		return career_extension:can_use_activated_ability() and (is_using_ability or (condition_function and condition_function(blackboard)))
	end

	local is_staggering = STAGGERING_ABILITIES[career_name] and true or false
	
	if is_staggering then
		if is_using_ability then
			return true
		end
	
		local current_time = Managers.time:time("game")
		local stagger, threat_reduce = update_staggering_abilities(current_time)
		
		if stagger then
			return false
		elseif threat_reduce then
			STAGGERING_ABILITIES_NEEDED_THREAT_RATIO = 1.5
		else
			STAGGERING_ABILITIES_NEEDED_THREAT_RATIO = 1
		end
		
		local should_use_ability = career_extension:can_use_activated_ability() and condition_function and condition_function(blackboard)
		
		if should_use_ability then
			STAGGERING_ABILITIES[career_name] = { stagger_end_time = current_time + BASE_STAGGER_ABILITY_TIME + math.random() * 1.5, threat_reduce_end_time = current_time + math.random() * 4}
			return true
		end
	end
	
	return is_using_ability or (career_extension:can_use_activated_ability() and condition_function and condition_function(blackboard))
end)

--------------------------------------------------------------------------------------------------------------------------------------------------
--[[
local function is_in_bounds(value, lower_bound, upper_bound)
	return value >= lower_bound and value <= upper_bound
end

local INDEX_ACTOR = 4
local function enemies_behind(blackboard, self_pos, direction_to_target, max_dist)
	local raycast_hits = PhysicsWorld.immediate_raycast(World.get_data(blackboard.world, "physics_world"), self_pos, direction_to_target, max_dist, "all", "collision_filter", "filter_ray_ping")
	
	local enemies_behind = 0
	if raycast_hits then
		local num_hits = #raycast_hits

		for i = 1, num_hits, 1 do
			local hit = raycast_hits[i]
			local hit_actor = hit[INDEX_ACTOR]
			local hit_unit = Actor.unit(hit_actor)
			local is_static = Actor.is_static(hit_actor)
			
			if not is_static and Unit.alive(hit_unit) then
				enemies_behind = enemies_behind + 1
			elseif is_static then
				break
			end
		end
	end
	
	return enemies_behind
end

local function target_is_good_for_piercing_shot(blackboard, target_unit)
	local max_shot_distance = 80
	
	local _, target_specific = get_enemy_data(target_unit)
	local target_blackboard = BLACKBOARDS[target]
	local target_breed = target_blackboard and target_blackboard.breed
	local target_breed_name = target_breed and target_breed.name
	
	local is_regular = target_specific == REGULAR
	local is_elite = target_specific == ELITE
	local is_boss = target_specific == BOSS
	local is_globadier = target_breed_name == "skaven_poison_wind_globadier"
	local is_gutter_runner = target_breed_name == "skaven_gutter_runner"
	local is_cw = target_breed_name == "chaos_warrior"
	
	local conflict_director = Managers.state.conflict
	local alive_bosses = conflict_director:alive_bosses()
	local num_alive_bosses = alive_bosses and #alive_bosses or 0
	local no_bosses = not alive_bosses or num_alive_bosses == 0
	
	local target_distance = blackboard.target_dist
	
	local target_pos = POSITION_LOOKUP[target_unit]
	local self_pos = POSITION_LOOKUP[blackboard.unit]
	local direction_to_target = Vector3.normalize(target_pos - self_pos)
	local flat_direction_to_target = Vector3.normalize(Vector3.flat(direction_to_target))
	
	local target_locomotion_extension = ScriptUnit.has_extension(target_unit, "locomotion_system")
	local target_velocity = (target_locomotion_extension and target_locomotion_extension:current_velocity()) or Vector3.zero()
	local target_flat_velocity = Vector3.normalize(Vector3.flat(target_velocity))
	
	local target_moves_to_player = Vector3.dot(flat_direction_to_target, target_flat_velocity) <= -0.995
	local small_vertical_velocity = target_velocity.z < 0.25
	local standing_still = Vector3.length_squared(target_velocity) < 0.01
	
	local good_standing_dist = standing_still and target_distance <= 50
	local good_moving_dist = target_moves_to_player and small_vertical_velocity and is_in_bounds(target_distance, 1, 15)
	
	local enemies_behind = enemies_behind(blackboard, self_pos, direction_to_target, 80)
	
	local is_good_priority_target = target_unit == blackboard.priority_target_enemy and is_in_bounds(target_distance, 1, max_shot_distance)
	local is_good_opportunity_target = target_unit == blackboard.opportunity_target_enemy and small_vertical_velocity and is_in_bounds(target_distance, 1, 10) and not is_globadier and not is_gutter_runner
	local is_good_urgent_target = target_unit == blackboard.urgent_target_enemy and not is_boss and small_vertical_velocity and is_in_bounds(target_distance, 1, max_shot_distance) and (not is_globadier or #blackboard.proximite_enemies > 25)
	local is_good_elite_target = is_elite and ((good_standing_dist or good_moving_dist) or (is_cw and target_distance <= 25))
	local is_good_boss_target = target_unit == blackboard.urgent_target_enemy and is_boss and small_vertical_velocity and target_distance <= 15 
	local is_good_regular_target = is_regular and ((target_moves_to_player and small_vertical_velocity) or standing_still) and is_in_bounds(target_distance, 2, 50) and enemies_behind >= 8
	
	if is_good_priority_target or is_good_boss_target or (no_bosses and (is_good_urgent_target or is_good_opportunity_target or is_good_elite_target or is_good_regular_target)) then
		local obstruction = blackboard.ranged_obstruction_by_static
		local t = Managers.time:time("game")
		local obstructed = obstruction and obstruction.unit == target_unit and t <= obstruction.timer + 0.3
		
		return not obstructed
	else
		return false
	end
end

mod:hook(BTConditions.can_activate, "we_waywatcher", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.we_waywatcher then
		return func(blackboard)
	end
	
	local target_unit = blackboard.target_unit

	if not ALIVE[target_unit] then
		return false
	end

	if not BLACKBOARDS[target_unit] then
		return false
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
	local has_piercing_shot_ult = talent_extension:has_talent("kerillian_waywatcher_activated_ability_piercing_shot")
	local has_ammo_restore_ult = talent_extension:has_talent("kerillian_waywatcher_activated_ability_restore_ammo_on_career_skill_special_kill")
	local has_double_arrow_on_melee_kill = talent_extension:has_talent("kerillian_waywatcher_extra_arrow_melee_kill")
	
	local max_threat_distance_sq = 100
	local num_enemies_threshold = 15
	local threat_threshold = 35
	
	if has_piercing_shot_ult then
		return target_is_good_for_piercing_shot(blackboard, target_unit)
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= max_threat_distance_sq then
			local enemy_threat_value, enemy_specific = get_enemy_data(enemy_unit)
			
			total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1) * (enemy_specific == SPECIAL and 1.66667 or 1) * (enemy_specific == BOSS and 0 or 1)
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		
		total_threat = total_threat + bot_fatigue * 10 + (1 - bot_health) * 10
		num_enemies = num_enemies + bot_fatigue * 5 + (1 - bot_health) * 5
		
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local target_ally_unit = blackboard.target_ally_unit
		local is_prioritized = ai_bot_group_system:is_prioritized_ally(self_unit, target_ally_unit)
		local target_ally_need_type = blackboard.target_ally_need_type
		
		if is_prioritized and (target_ally_need_type == "knocked_down" or target_ally_need_type == "hook" or target_ally_need_type == "ledge") then
			total_threat = total_threat + 5
			num_enemies = num_enemies + 5
		end
		
		if target_breed and target_breed.special then
			total_threat = total_threat + 10
			num_enemies = num_enemies + 3
		end
		
		local num_players_in_range, average_health_percent, num_players_needing_urgent_heal = get_status_of_players_in_radius(blackboard, self_position, max_threat_distance_sq)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
	end
	
	local has_worthwhile_target = false
	local buff_extension = ScriptUnit.extension(self_unit, "buff_system")
	local has_double_arrow_buff = buff_extension:has_buff_type("kerillian_waywatcher_extra_arrow_melee_kill_buff")
	
	if not has_ammo_restore_ult then
		if not has_double_arrow_on_melee_kill or has_double_arrow_buff then
			if total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor then
				has_worthwhile_target = true
			end
		else
			if total_threat >= threat_threshold * allies_status_factor * 1.75 or num_enemies >= num_enemies_threshold * allies_status_factor * 1.75 then
				has_worthwhile_target = true
			end
		end
	else
		local inventory_extension = ScriptUnit.extension(self_unit, "inventory_system")
		local ammo_percentage = inventory_extension:ammo_percentage()
		
		if not has_double_arrow_on_melee_kill or has_double_arrow_buff then
			if (target_specific ~= REGULAR and ammo_percentage >= 0.5 and (total_threat >= threat_threshold * allies_status_factor or num_enemies >= num_enemies_threshold * allies_status_factor)) or
			(target_specific ~= REGULAR and ammo_percentage < 0.5) or
			(target_specific == REGULAR and ammo_percentage >= 0.5 and (total_threat >= threat_threshold * allies_status_factor * 1.5 or num_enemies >= num_enemies_threshold * allies_status_factor * 1.5)) then
				has_worthwhile_target = true
			end
		else
			if (target_specific ~= REGULAR and ammo_percentage >= 0.5 and (total_threat >= threat_threshold * allies_status_factor * 1.75 or num_enemies >= num_enemies_threshold * allies_status_factor * 1.75)) or
			(target_specific ~= REGULAR and ammo_percentage < 0.15) or
			(target_specific == REGULAR and ammo_percentage >= 0.5 and (total_threat >= threat_threshold * allies_status_factor * 2.25 or num_enemies >= num_enemies_threshold * allies_status_factor * 2.25)) then
				has_worthwhile_target = true
			end
		end
	end
	
	if has_worthwhile_target then
		local obstruction = blackboard.ranged_obstruction_by_static
		local t = Managers.time:time("game")
		local obstructed = obstruction and obstruction.unit == target and t <= obstruction.timer + 0.3
		
		return not obstructed
	else
		return false
	end
end)
--]]

local buff_perks = require("scripts/unit_extensions/default_player_unit/buffs/settings/buff_perk_names")

local WP_MAX_ASSIST_DIST = 15
local WP_CLOSE_DISTANCE_SQ = 10
local WP_MIN_THREAT = 5
local WP_THREAT_THRESHOLD = 50	--15

local function is_target_already_shielded(unit)
	local buff_extension = ScriptUnit.has_extension(unit, "buff_system")

	return not buff_extension or buff_extension:has_buff_perk(buff_perks.invulnerable)
end

mod:hook(BTConditions.can_activate, "wh_priest", function (func, blackboard)
	if not mod.components.regular_active_abilities.detailed_settings.wh_priest then
		return func(blackboard)
	end
	
	local self_unit = blackboard.unit
	local target_ally_unit = blackboard.target_ally_unit
	local should_target_ally = false
	local should_target_self = false

	if ALIVE[self_unit] and ALIVE[target_ally_unit] and blackboard.ally_distance and blackboard.ally_distance < WP_MAX_ASSIST_DIST then
		local ally_status_ext = ScriptUnit.has_extension(target_ally_unit, "status_system")

		if ally_status_ext then
			if ally_status_ext:is_pounced_down() or ally_status_ext:is_grabbed_by_pack_master() or ally_status_ext:is_grabbed_by_corruptor() then
				should_target_ally = true
			end

			if not should_target_ally then
				local talent_extension = ScriptUnit.has_extension(self_unit, "talent_system")
				local has_revive_talent = talent_extension and talent_extension:has_talent("victor_priest_6_3")

				if has_revive_talent and ally_status_ext:is_knocked_down() then
					should_target_ally = true
				end
			end
		end
	end

	if not should_target_ally then
		local ally_too_far = blackboard.ally_distance and WP_MAX_ASSIST_DIST < blackboard.ally_distance
		local target = blackboard.target_unit
		local target_blackboard = BLACKBOARDS[target]
		local target_breed = target_blackboard and target_blackboard.breed
		local target_threat = target_breed and target_breed.threat_value or 0

		if WP_MIN_THREAT <= target_threat then
			local self_unit = blackboard.unit
			local self_position = POSITION_LOOKUP[self_unit]
			local proximite_enemies = blackboard.proximite_enemies
			local num_proximite_enemies = #proximite_enemies
			local total_threat_value = 0
			local close_threat_value = 0
			local far_threat_value = 0

			for i = 1, num_proximite_enemies do
				local enemy_unit = proximite_enemies[i]
				local enemy_position = POSITION_LOOKUP[enemy_unit]

				if ALIVE[enemy_unit] then
					local enemy_blackboard = BLACKBOARDS[enemy_unit]
					local enemy_breed = enemy_blackboard.breed
					local breed_threat_value = enemy_breed.threat_value

					if ally_too_far then
						close_threat_value = close_threat_value + breed_threat_value

						if WP_THREAT_THRESHOLD < close_threat_value then
							break
						end
					elseif Vector3.distance_squared(self_position, enemy_position) <= WP_CLOSE_DISTANCE_SQ then
						close_threat_value = close_threat_value + breed_threat_value
					else
						far_threat_value = far_threat_value + breed_threat_value

						if WP_THREAT_THRESHOLD < far_threat_value then
							break
						end
					end
				end
			end

			if blackboard.ally_distance and blackboard.ally_distance <= 3.2 then
				far_threat_value = math.max(close_threat_value, far_threat_value)
			end

			if WP_THREAT_THRESHOLD < far_threat_value then
				should_target_ally = true
			elseif WP_THREAT_THRESHOLD < close_threat_value then
				should_target_self = true
			end
		end
	end

	if should_target_ally or should_target_self then
		local target_to_shield = nil

		if should_target_ally and not is_target_already_shielded(target_ally_unit) then
			target_to_shield = target_ally_unit
		elseif should_target_self and not is_target_already_shielded(self_unit) then
			target_to_shield = self_unit
		end

		blackboard.activate_ability_data.target_unit = target_to_shield

		return target_to_shield ~= nil
	end

	return false
end)

