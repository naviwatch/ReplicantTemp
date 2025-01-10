local mod = get_mod("ReplicantTemp")

local DEFAULT_MAXIMAL_MELEE_RANGE = 5
local DEFAULT_MAXIMAL_MELEE_RANGE_SQ = 5
local DEFAULT_ATTACK_META_DATA = {
	tap_attack = {
		arc = 0,
		penetrating = false,
		max_range = DEFAULT_MAXIMAL_MELEE_RANGE
	},
	hold_attack = {
		arc = 2,
		penetrating = true,
		max_range = DEFAULT_MAXIMAL_MELEE_RANGE
	}
}

local function BetterMelee_BI_C(self, blackboard, target_unit)
	local num_enemies = #blackboard.proximite_enemies
	local outnumbered = 1 < num_enemies
	local massively_outnumbered = 3 < num_enemies
	local target_breed = Unit.get_data(target_unit, "breed")
	local target_armor = (target_breed and target_breed.armor_category) or 1
	local inventory_ext = blackboard.inventory_extension
	local wielded_slot_name = inventory_ext.get_wielded_slot_name(inventory_ext)
	local slot_data = inventory_ext.get_slot_data(inventory_ext, wielded_slot_name)
	local item_data = slot_data.item_data
	local item_template = blackboard.wielded_item_template
	local weapon_meta_data = item_template.attack_meta_data or DEFAULT_ATTACK_META_DATA

	if item_data.item_type == "bw_1h_sword" or item_data.item_type == "es_1h_sword" or item_data.item_type == "bw_flame_sword" then
		weapon_meta_data.tap_attack.arc = 2
		weapon_meta_data.tap_attack.penetrating = false
	end

	if item_data.item_type == "ww_2h_axe" then
		weapon_meta_data.tap_attack.arc = 2
		weapon_meta_data.tap_attack.penetrating = true
	end

	local best_utility = -1
	local best_attack_input, best_attack_meta_data = nil

	for attack_input, attack_meta_data in pairs(weapon_meta_data) do
		local utility = 0

		if (not outnumbered) and attack_meta_data.arc ~= 1 then
			utility = utility + 1
		end

		if target_armor ~= 2 or attack_meta_data.penetrating then
			utility = utility + 8
		end

		if best_utility < utility then
			best_utility = utility
			best_attack_input = attack_input
			best_attack_meta_data = attack_meta_data
		end
	end	

	return best_attack_input, best_attack_meta_data
end

local function is_in_front(camera_position, current_forward, enemy_position)
	local enemy_direction = Vector3.normalize(enemy_position - camera_position)
	local enemy_dot = Vector3.dot(current_forward, enemy_direction)
	
	if enemy_dot >= 0.643 then
		return true
	else
		return false
	end
end

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

local BOSS = 1
local SPECIAL = 2
local ELITE = 3
local REGULAR = 4
local function BetterMelee_My(self, blackboard, target_unit, career_name)
	local target_breed = Unit.get_data(target_unit, "breed")
	local inventory_ext = blackboard.inventory_extension
	local wielded_slot_name = inventory_ext.get_wielded_slot_name(inventory_ext)
	local slot_data = inventory_ext.get_slot_data(inventory_ext, wielded_slot_name)
	local item_data = slot_data.item_data
	local item_template = blackboard.wielded_item_template
	local weapon_meta_data = item_template.attack_meta_data or DEFAULT_ATTACK_META_DATA
	
	local best_attack_input = "tap_attack"
	local best_attack_meta_data = weapon_meta_data[best_attack_input]
	
	if not target_breed or not Unit.alive(target_unit) then
		return best_attack_input, best_attack_meta_data
	end
	
	local self_unit = blackboard.unit
	local self_position = POSITION_LOOKUP[self_unit]
	local first_person_extension = blackboard.first_person_extension
	local camera_position = first_person_extension:current_position()
	local current_rotation = first_person_extension:current_rotation()
	local current_forward = Quaternion.forward(current_rotation)
	
	local massive_enemy_in_front = false
	local armoured_enemy_in_front = false
	for i = 1, #blackboard.proximite_enemies, 1 do
		local enemy_unit = blackboard.proximite_enemies[i]
		local enemy_position = POSITION_LOOKUP[enemy_unit]
		local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge

		if ALIVE[enemy_unit] and enemy_distance_sq <= DEFAULT_MAXIMAL_MELEE_RANGE_SQ then
			local enemy_blackboard = BLACKBOARDS[enemy_unit]
			local enemy_breed = enemy_blackboard.breed
			local specific = enemy_breed.boss and 1 or (enemy_breed.special and 2 or (enemy_breed.elite and 3 or 4))
			local is_armoured = enemy_breed.armor_category and enemy_breed.armor_category == 2
			local is_superarmoured = enemy_breed.primary_armor_category and enemy_breed.primary_armor_category == 6
			
			if specific ~= REGULAR then
				massive_enemy_in_front = massive_enemy_in_front or is_in_front(camera_position, current_forward, enemy_position)
			end
			
			if is_armoured or is_superarmoured then
				armoured_enemy_in_front = armoured_enemy_in_front or is_in_front(camera_position, current_forward, enemy_position)
			end
			
			if massive_enemy_in_front and armoured_enemy_in_front then
				break
			end
		end
	end
	
	local num_enemies = #blackboard.proximite_enemies
	local outnumber_degree = num_enemies > 3 and (num_enemies > 6 and (num_enemies > 11 and 3 or 2) or 1) or 0
	
	local target_specific = target_breed.boss and 1 or (target_breed.special and 2 or (target_breed.elite and 3 or 4))
	local target_is_armoured = target_breed.armor_category and target_breed.armor_category == 2
	local target_is_superarmoured = target_breed.primary_armor_category and target_breed.primary_armor_category == 6

	if item_data.item_type == "bw_1h_sword" or item_data.item_type == "es_1h_sword" then
		weapon_meta_data.tap_attack.arc = 2
		weapon_meta_data.tap_attack.penetrating = false
	end
	
	if item_data.item_type == "bw_flame_sword" then
		weapon_meta_data.tap_attack.arc = 0.8
		weapon_meta_data.tap_attack.penetrating = false
	end

	if item_data.item_type == "ww_2h_axe" then
		weapon_meta_data.tap_attack.arc = 2
		weapon_meta_data.tap_attack.penetrating = false
	end
	
	if item_data.item_type == "ww_dual_swords" then
		weapon_meta_data.tap_attack.arc = 1
		weapon_meta_data.tap_attack.penetrating = true
		weapon_meta_data.hold_attack.arc = 0.5
		weapon_meta_data.hold_attack.penetrating = true
	end
	
	if item_data.item_type == "es_2h_sword_executioner" then
		weapon_meta_data.tap_attack.penetrating = false
		weapon_meta_data.tap_attack.arc = 1.5
		weapon_meta_data.hold_attack.penetrating = true
	end
	
	if item_data.item_type == "bw_1h_flail_flaming" then
		weapon_meta_data.tap_attack.arc = 1
		weapon_meta_data.hold_attack.arc = 2
	end
	
	if item_data.item_type == "we_2h_spear" then
		weapon_meta_data.tap_attack.penetrating = true
		weapon_meta_data.tap_attack.arc = 1
		weapon_meta_data.hold_attack.arc = 0.75
	end
	
	if item_data.item_type == "es_deus_01" then
		weapon_meta_data.tap_attack.arc = 2
		weapon_meta_data.tap_attack.penetrating = false
		weapon_meta_data.hold_attack.arc = 1.5
		weapon_meta_data.tap_attack.penetrating = true
	end
	
	if item_data.item_type == "es_1h_sword_shield" then
		weapon_meta_data.tap_attack.arc = 1
		weapon_meta_data.hold_attack.arc = 2
	end
	
	if item_data.item_type == "es_bastard_sword" then
		weapon_meta_data.tap_attack.arc = 1
		weapon_meta_data.tap_attack.penetrating = false
		weapon_meta_data.hold_attack.arc = 1.5
		weapon_meta_data.hold_attack.penetrating = true
	end
	
	if item_template.name == "dual_wield_sword_dagger_template_1" then
		weapon_meta_data.tap_attack.arc = 2
		weapon_meta_data.tap_attack.penetrating = false
		weapon_meta_data.hold_attack.arc = 1.5
		weapon_meta_data.hold_attack.penetrating = true
	end
	
	--[[if item_data.item_type == "es_1h_mace_shield" then
		weapon_meta_data.tap_attack.penetrating = true
		weapon_meta_data.tap_attack.arc = 1
		weapon_meta_data.hold_attack.penetrating = true
		weapon_meta_data.hold_attack.arc = 2
	end--]] -- ok
	
	-- dr_1h_hammer_shield -- ok
	
	if item_data.item_type == "dr_1h_axe_shield" then
		weapon_meta_data.hold_attack.penetrating = true
	end

	local best_utility = -1
	local best_attack_input, best_attack_meta_data = nil
	local is_wh_with_rapier = career_name == "wh_captain" and item_data.item_type == "wh_fencing_sword"
	
	for attack_input, attack_meta_data in pairs(weapon_meta_data) do
		local utility = 0
		
		if outnumber_degree > 0 and attack_meta_data.arc > 0 then
			utility = utility + outnumber_degree * attack_meta_data.arc
		elseif attack_meta_data.arc == 1 then
			utility = utility + 1
		end
		
		if massive_enemy_in_front and outnumber_degree > attack_meta_data.arc and attack_meta_data.arc > 0 then
			utility = utility + attack_meta_data.arc / (attack_meta_data.penetrating and 1 or 2)
		end
		
		if armoured_enemy_in_front and outnumber_degree > attack_meta_data.arc and (attack_meta_data.arc > 0 and attack_meta_data.penetrating) then
			utility = utility + attack_meta_data.arc
		end
		
		if target_specific ~= REGULAR and attack_meta_data.penetrating then
			utility = utility + 1.5 * (target_specific == BOSS and 0.75 or 1)
		end
		
		if (target_is_armoured or target_is_superarmoured) and attack_meta_data.penetrating then
			utility = utility + 2 * (target_is_superarmoured and 3 or 2) * (outnumber_degree >= 3 and (attack_meta_data.arc / 2 + 0.5) or 1)
		end
		
		if attack_meta_data.penetrating and attack_input == "hold_attack" then
			utility = utility + 0.5
		end
		
		if not armoured_enemy_in_front and attack_input == "tap_attack" then
			utility = utility + 0.5
		end
		
		if target_is_superarmoured and attack_meta_data.penetrating then
			utility = utility + 3
		end
		
		if attack_input == "hold_attack" and is_shade_in_invis(career_name, self_unit) then
			utility = utility + 100
		end
		
		if attack_input == "tap_attack" and is_wh_with_rapier then
			utility = utility + 50
		end
		
		if attack_input == "hold_attack" and is_wh_with_rapier and (target_specific == BOSS or target_is_superarmoured or target_breed.name == "skaven_pack_master") then
			utility = utility + 100
		end

		if best_utility < utility then
			best_utility = utility
			best_attack_input = attack_input
			best_attack_meta_data = attack_meta_data
		end
	end
	
	return best_attack_input, best_attack_meta_data
end

mod:hook(BTBotMeleeAction, "_choose_attack", function(func, self, blackboard, target_unit)
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	local career_name_m = career_name.."_m"
	
	if mod.components.melee_choices.detailed_settings[career_name_m] == mod.melee_settings.default then
		return func(self, blackboard, target_unit)
	elseif mod.components.melee_choices.detailed_settings[career_name_m] == mod.melee_settings.as_in_BI_C then
		return BetterMelee_BI_C(self, blackboard, target_unit)
	else
		return BetterMelee_My(self, blackboard, target_unit, career_name)
	end
end)

local shielded_weapons = {
	es_1h_sword_shield = true,
	es_1h_mace_shield = true,
	es_1h_sword_shield_breton = true,
	
	wh_flail_shield = true,
	wh_hammer_shield = true,
}

--[[local weapon_efectiveness = {
	es_2h_sword_executioner = {
		elite = true,
		monsters = true,
		
	}
}--]]

local function get_player_fatigue_and_health(blackboard)
	local fatigue_level = blackboard.status_extension:current_fatigue() >= 60 and blackboard.status_extension:current_fatigue() / 100 or 0
	local health_level = blackboard.health_extension:current_health_percent()
	
	return fatigue_level, health_level
end

BTConditions.get_best_defensive_slot = function(blackboard)
	if BTConditions.has_double_weapon_slots(blackboard, {"slot_melee"}) then
		local inventory_ext = blackboard.inventory_extension
		local melee_slot_data = inventory_ext:get_slot_data("slot_melee")
		local ranged_slot_data = inventory_ext:get_slot_data("slot_ranged")
		
		local is_shielded_melee_slot = shielded_weapons[melee_slot_data.item_data.item_type]
		local is_shielded_ranged_slot = shielded_weapons[ranged_slot_data.item_data.item_type]
		
		if is_shielded_melee_slot then
			return "slot_melee"
		elseif is_shielded_ranged_slot then
			return "slot_ranged"
		end
	end
	
	return "slot_melee"
end

BTConditions.get_best_slot_against_target = function(blackboard)
	return nil
end

mod:hook(BTConditions, "has_better_alt_weapon", function (func, blackboard, args)
	local main_slot = args[1]
	
	local best_defensive_slot = BTConditions.get_best_defensive_slot(blackboard)
	--if blackboard.career_extension:career_name() == "es_questingknight" then
	--	mod:echo(blackboard._avoiding_aoe_threat_)
	--end
	if best_defensive_slot ~= main_slot then
		local self_unit = blackboard.unit
		local self_position = POSITION_LOOKUP[self_unit]
		local first_person_extension = blackboard.first_person_extension
		local camera_position = first_person_extension:current_position()
		local current_rotation = first_person_extension:current_rotation()
		local current_forward = Quaternion.forward(current_rotation)
		
		local is_under_berzerker_attack = false
		local is_under_boss_attack = false
		local total_threat = 0
		for i = 1, #blackboard.proximite_enemies, 1 do
			local enemy_unit = blackboard.proximite_enemies[i]
			local enemy_position = POSITION_LOOKUP[enemy_unit]
			local enemy_distance_sq = enemy_position and Vector3.distance_squared(self_position, enemy_position) or math.huge
			
			if ALIVE[enemy_unit] and enemy_distance_sq <= DEFAULT_MAXIMAL_MELEE_RANGE_SQ then
				local enemy_blackboard = BLACKBOARDS[enemy_unit]
				local enemy_breed = enemy_blackboard.breed
				local specific = enemy_breed.boss and 1 or (enemy_breed.special and 2 or (enemy_breed.elite and 3 or 4))
				local is_berzerker = enemy_breed.armor_category and enemy_breed.armor_category == 5
				local is_attacking_me = enemy_blackboard and enemy_blackboard.target_unit == self_unit
				
				if is_berzerker and is_attacking_me and enemy_distance_sq <= 9 then
					is_under_berzerker_attack = true 
				end
				
				if specific == BOSS and is_attacking_me then
					is_under_boss_attack = true
				end
				
				total_threat = (is_attacking_me and total_threat or 1) + (enemy_breed.threat or 0)
			end
		end
		
		local bot_fatigue, bot_health = get_player_fatigue_and_health(blackboard)
		local in_lof = blackboard.in_line_of_fire
		
		if  (total_threat > 30 and bot_fatigue > 0.5) or
			(total_threat > 20 and bot_fatigue > 0.9) or
			(is_under_boss_attack and bot_health < 0.7) or
			(is_under_berzerker_attack) or
			blackboard._avoiding_aoe_threat_ or in_lof then
			
			return true
		end
		
	end
	
	local best_slot_against_target = BTConditions.get_best_slot_against_target(blackboard)
	
	if best_slot_against_target and best_slot_against_target ~= main_slot then
		return true
	elseif BTConditions.has_double_weapon_slots(blackboard, {main_slot}) then
		local weapon_scores = blackboard.weapon_scores
		
		if weapon_scores then
			local alt_slot = args[2]
			local main_weapon_score = weapon_scores[main_slot].score or -1
			local alt_weapon_score = weapon_scores[alt_slot].score or -1
			
			return main_weapon_score < alt_weapon_score
		end
	end
	
	return false
end)