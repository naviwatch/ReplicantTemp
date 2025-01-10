local mod = get_mod("ReplicantTemp")
require("scripts/entity_system/systems/behaviour/nodes/bt_node")

BTBotDrinkPotAction = class(BTBotDrinkPotAction, BTNode)

BTBotDrinkPotAction.init = function (self, ...)
	BTBotHealAction.super.init(self, ...)
end

BTBotDrinkPotAction.name = "BTBotDrinkPotAction"

BTBotDrinkPotAction.enter = function (self, unit, blackboard, t)
	blackboard.is_drinking_potion = true
end

BTBotDrinkPotAction.leave = function (self, unit, blackboard, t, reason, destroy)
	blackboard.is_drinking_potion = false
end

BTBotDrinkPotAction.run = function (self, unit, blackboard, t, dt)
	blackboard.input_extension:hold_attack()

	--Vernon: Let bots dodge while using ranged weapons
	--only check non-AoE attacks only, as AoE attacks should be handled by threat box system
	--meh, i will just copy the whole _defend function for now
	local self_unit		= unit
	local prox_enemies = mod.get_proximite_enemies(self_unit, 8, 3.8)	--7, 3.8	--7, 3
	local input_ext = blackboard.input_extension
	
	for key, loop_unit in pairs(prox_enemies) do
		local loop_breed = Unit.get_data(loop_unit, "breed")
		local loop_bb = BLACKBOARDS[loop_unit]
		local loop_distance = Vector3.length(POSITION_LOOKUP[self_unit] - POSITION_LOOKUP[loop_unit])
		
		if loop_bb then
			if mod.TRASH_UNITS_AND_SHIELD_SV[loop_breed.name] or mod.BERSERKER_UNITS[loop_breed.name] then
				-- if loop_bb.attacking_target == self_unit and not loop_bb.past_damage_in_attack then
				if loop_bb.attacking_target == self_unit and not loop_bb.past_damage_in_attack and loop_distance < 4.5 then
					input_ext:dodge()
				end
			elseif mod.ELITE_UNITS_AOE[loop_breed.name] then
				if loop_bb.attacking_target and not loop_bb.past_damage_in_attack then
					--can refine the angle if we know hitbox and animation
					local infront_of_loop_unit, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, 160, 120)	--160, 120	--120, 120	--90, 120
					if infront_of_loop_unit or (loop_distance < 3 and not flanking_loop_unit) then
						if loop_bb.moving_attack then
							-- input_ext:dodge()
						elseif loop_distance < 5 then	--6	--5
							-- input_ext:dodge()
						end
					end
				end
			elseif mod.BOSS_AND_LORD_UNITS[loop_breed.name] then
				--TODO: change this after fixing _defend for bosses
				if loop_bb.attacking_target and not loop_bb.past_damage_in_attack then
					local infront_of_loop_unit, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, 160, 120)
					-- if infront_of_loop_unit or (loop_distance < 4.5 and not flanking_loop_unit) then	--4
					if infront_of_loop_unit and loop_distance < 4.5 then
						-- input_ext:dodge()
					end
				end
			end
		end
	end

	return "running"
end



--DrinkingPotions

local standart_potions = { 
	damage_boost_potion = true,
	speed_boost_potion = true,
	cooldown_reduction_potion = true
}

local get_player_status = mod.utility.get_player_status

local NORMAL_PLAYERS_NUMBER = 4
local ALLIES_STATUS_FACTOR_THRESHOLD = 0.53333
local get_status_of_players_in_radius = mod.utility.get_status_of_players_in_radius

local BOSS = 1
local SPECIAL = 2
local ELITE = 3
local REGULAR = 4
local get_enemy_data = mod.utility.get_enemy_data

local is_unit_alive = Unit.alive

local function pos_is_near_aggroed_patrol(pos, check_range_sq)
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
					
					if patrol_unit_dist_sq and patrol_unit_dist_sq < check_range_sq and patrol_has_target then
						return id
					end
				end
			end
		end
	end
	
	return nil
end

local drinker_unit = nil
local patrol_id = nil
local monster_unit = nil
local time_last_potion_was_used = -100
local POTION_USAGE_COOLDOWN = 40
local THREAT_DISTANCE_SQ = 100
local THREAT_THRESHOLD = 300
local NUM_ENEMIES_THRESHOLD = 150
BTConditions.bot_should_drink_buff_potion = function (blackboard)
	if not mod.components.drinking_potions.value then
		return false
	end
	
	local game_mode_key = Managers.state.game_mode:game_mode_key()
	
	if game_mode_key == "weave" or game_mode_key == "deus" then -- game_mode_key == "versus"
		return false
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	
	local is_drinking = blackboard.is_drinking_potion
	local should_start_drinking = (self_unit == drinker_unit)
	
	if should_start_drinking and is_drinking then
		drinker_unit = nil
	elseif should_start_drinking or is_drinking then
		return true
	end
	
	local current_time = Managers.time:time("game")
	if current_time - time_last_potion_was_used < POTION_USAGE_COOLDOWN then
		return false
	end
	
	local inventory_extension = blackboard.inventory_extension
	local potion_slot_data = inventory_extension:get_slot_data("slot_potion")
	local template = potion_slot_data and inventory_extension:get_item_template(potion_slot_data)
	local pickup_data = template and template.pickup_data
	local pickup_name = pickup_data and pickup_data.pickup_name
	local has_standart_potion = pickup_name and standart_potions[pickup_name] == true
	
	if not has_standart_potion then
		return false
	end
	
	local close_aggroed_patrol_id = pos_is_near_aggroed_patrol(self_position, 5)
	if close_aggroed_patrol_id and close_aggroed_patrol_id ~= patrol_id then
		time_last_potion_was_used = current_time
		drinker_unit = self_unit
		patrol_id = close_aggroed_patrol_id
		return true
	end
	
	local total_threat = 0
	local num_enemies = 0
	local proximite_enemies = blackboard.proximite_enemies
	for i = 1, #proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= THREAT_DISTANCE_SQ then
			local enemy_threat_value, enemy_specific = get_enemy_data(enemy_unit)
			
			if enemy_specific == BOSS then
				time_last_potion_was_used = current_time
				drinker_unit = self_unit
				return not AiUtils.unit_invincible(enemy_unit) and true
			else
				total_threat = total_threat + enemy_threat_value * (enemy_specific ~= REGULAR and 1.5 or 1) * (enemy_target == self_unit and 1.33334 or 1)
			end
			
			num_enemies = num_enemies + 1
		end
	end
	
	local allies_status_factor = 1
	if num_enemies > 0 then
		local num_players_in_range, average_health_percent = get_status_of_players_in_radius(blackboard, self_position, THREAT_DISTANCE_SQ)
		allies_status_factor = math.max(ALLIES_STATUS_FACTOR_THRESHOLD, average_health_percent * num_players_in_range / NORMAL_PLAYERS_NUMBER)
		
		if num_enemies > 10 then
			total_threat = total_threat + 15
		elseif num_enemies > 15 then
			total_threat = total_threat + 25
		end
	end
	
	if total_threat >= THREAT_THRESHOLD * allies_status_factor or num_enemies >= NUM_ENEMIES_THRESHOLD * allies_status_factor then
		time_last_potion_was_used = current_time
		drinker_unit = self_unit
		return true
	end
end

