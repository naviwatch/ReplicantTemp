local mod = get_mod("ReplicantTemp")

-- region
local CIRCLE = 100
local TARGET = 200

-- stagger and damage
local NONE = 0
local WEAK = 1
local MEDIUM = 2
local STRONG = 3

-- target_reaching_type
local LEAP = 10
local WALK = 20
local SHOT = 30
local INDIRECT_SHOT = 40
local ABILITY_EXPLOSION = 50

local RESQUE_ATTEMPT_TIME_CIRCLE = 0.5
local RESQUE_ATTEMPT_TIME_TARGET_SHOT = 1.5
local RESQUE_ATTEMPT_TIME_TARGET_STAGGER = 1.5
local RESQUE_ATTEMPT_TIME_TARGET_KILL = 3
local RESQUE_ATTEMPT_TIME_TARGET_WALK_KILL = 4

local find_in_array = mod.utility.find_in_array

local wh_zealot_lunge_default = {
	depth_padding = 0.4,
	height = 1.8,
	collision_filter = "filter_explosion_overlap_no_player",
	hit_zone_hit_name = "full",
	ignore_shield = true,
	interrupt_on_max_hit_mass = true,
	power_level_multiplier = 0.8,
	interrupt_on_first_hit = false,
	damage_profile = "heavy_slashing_linesman",
	width = 1.5,
	allow_backstab = true,
	stagger_angles = {
		max = 90,
		min = 45
	},
	on_interrupt_blast = {
		allow_backstab = false,
		radius = 3,
		power_level_multiplier = 1,
		hit_zone_hit_name = "full",
		damage_profile = "heavy_slashing_linesman",
		ignore_shield = false,
		collision_filter = "filter_explosion_overlap_no_player"
	}
}

local es_knight_lunge_default = {
	offset_forward = 2.4,
	height = 1.8,
	depth_padding = 0.6,
	hit_zone_hit_name = "full",
	ignore_shield = false,
	collision_filter = "filter_explosion_overlap_no_player",
	interrupt_on_max_hit_mass = true,
	power_level_multiplier = 1,
	interrupt_on_first_hit = false,
	damage_profile = "markus_knight_charge",
	width = 2,
	allow_backstab = false,
	stagger_angles = {
		max = 80,
		min = 25
	},
	on_interrupt_blast = {
		allow_backstab = false,
		radius = 3,
		power_level_multiplier = 1,
		hit_zone_hit_name = "full",
		damage_profile = "markus_knight_charge_blast",
		ignore_shield = false,
		collision_filter = "filter_explosion_overlap_no_player"
	}
}

local es_knight_lunge_wide_charge = {
	offset_forward = 2.4,
	height = 1.8,
	depth_padding = 0.6,
	hit_zone_hit_name = "full",
	ignore_shield = false,
	collision_filter = "filter_explosion_overlap_no_player",
	interrupt_on_max_hit_mass = false,
	power_level_multiplier = 1,
	interrupt_on_first_hit = false,
	damage_profile = "markus_knight_charge",
	width = 5,
	allow_backstab = false,
	stagger_angles = {
		max = 80,
		min = 25
	},
	on_interrupt_blast = {
		allow_backstab = false,
		radius = 3,
		power_level_multiplier = 1,
		hit_zone_hit_name = "full",
		damage_profile = "markus_knight_charge_blast",
		ignore_shield = false,
		collision_filter = "filter_explosion_overlap_no_player"
	}
}

local we_maidenguard_lunge_default = {
	depth_padding = 0.4,
	height = 1.8,
	collision_filter = "filter_explosion_overlap_no_player",
	hit_zone_hit_name = "full",
	ignore_shield = true,
	interrupt_on_max_hit_mass = false,
	interrupt_on_first_hit = false,
	width = 1.5,
	allow_backstab = true,
	damage_profile = "maidenguard_dash_ability",
	power_level_multiplier = 0,
	stagger_angles = {
		max = 90,
		min = 90
	}
}

local we_maidenguard_lunge_bleed = {
	depth_padding = 0.4,
	height = 1.8,
	collision_filter = "filter_explosion_overlap_no_player",
	hit_zone_hit_name = "full",
	ignore_shield = true,
	interrupt_on_max_hit_mass = false,
	interrupt_on_first_hit = false,
	width = 1.5,
	allow_backstab = true,
	damage_profile = "maidenguard_dash_ability_bleed",
	power_level_multiplier = 1,
	stagger_angles = {
		max = 90,
		min = 90
	}
}

local careers_abilities_rescue_types = {
	es_mercenary = {},
	es_knight = {},
	es_questingknight = {},
	dr_ranger = {},
	dr_ironbreaker = {},
	dr_slayer = {},
	we_waywatcher = {},
	we_maidenguard = {},
	we_shade = {},
	we_thornsister = {},
	wh_captain = {},
	wh_bountyhunter = {},
	wh_zealot = {},
	bw_adept = {},
	bw_scholar = {},
	bw_unchained = {}
}

local function init_rescue_types()
	local rescue_types = careers_abilities_rescue_types
	
	rescue_types.es_mercenary.default = { region = CIRCLE, stagger = STRONG, damage = NONE, target_reaching_type = NONE, max_distance = 10 }
	rescue_types.es_mercenary.markus_mercenary_activated_ability_damage_reduction = rescue_types.es_mercenary.default
	rescue_types.es_mercenary.markus_mercenary_activated_ability_cooldown_no_heal = rescue_types.es_mercenary.default
	rescue_types.es_mercenary.markus_mercenary_activated_ability_revive = rescue_types.es_mercenary.default
	
	rescue_types.es_knight.default = { region = TARGET, stagger = STRONG, damage = MEDIUM, target_reaching_type = es_knight_lunge_default, max_distance = 12 + 1 }
	rescue_types.es_knight.markus_knight_ability_invulnerability = rescue_types.es_knight.default
	rescue_types.es_knight.markus_knight_wide_charge = { region = TARGET, stagger = STRONG, damage = MEDIUM, target_reaching_type = es_knight_lunge_wide_charge, max_distance = 12 + 1 }
	rescue_types.es_knight.markus_knight_ability_attack_speed_enemy_hit = rescue_types.es_knight.default
	
	rescue_types.es_questingknight.default = { region = TARGET, stagger = STRONG, damage = STRONG, target_reaching_type = WALK, max_distance = 10 }
	rescue_types.es_questingknight.markus_questing_knight_ability_double_activation = rescue_types.es_questingknight.default
	rescue_types.es_questingknight.markus_questing_knight_ability_buff_on_kill = rescue_types.es_questingknight.default
	rescue_types.es_questingknight.markus_questing_knight_ability_tank_attack = rescue_types.es_questingknight.default
	
	rescue_types.dr_ranger.default = { region = CIRCLE, stagger = STRONG, damage = NONE, target_reaching_type = NONE, max_distance = 10 }
	rescue_types.dr_ranger.bardin_ranger_smoke_attack = rescue_types.dr_ranger.default
	rescue_types.dr_ranger.bardin_ranger_activated_ability_stealth_outside_of_smoke = rescue_types.dr_ranger.default
	rescue_types.dr_ranger.bardin_ranger_ability_free_grenade = rescue_types.dr_ranger.default
	
	rescue_types.dr_ironbreaker.default = { region = CIRCLE, stagger = MEDIUM, damage = NONE, target_reaching_type = NONE, max_distance = 10 }
	rescue_types.dr_ironbreaker.bardin_ironbreaker_activated_ability_power_buff_allies = rescue_types.dr_ironbreaker.default
	rescue_types.dr_ironbreaker.bardin_ironbreaker_activated_ability_taunt_bosses = { region = CIRCLE, stagger = STRONG, damage = NONE, target_reaching_type = NONE, max_distance = 10 }
	rescue_types.dr_ironbreaker.bardin_ironbreaker_activated_ability_taunt_range_and_duration = { region = CIRCLE, stagger = MEDIUM, damage = NONE, target_reaching_type = NONE, max_distance = 11.5 }
	
	rescue_types.dr_slayer.default = { region = TARGET, stagger = WEAK, damage = MEDIUM, target_reaching_type = LEAP, max_distance = 10 + 1 }
	rescue_types.dr_slayer.bardin_slayer_activated_ability_impact_damage = rescue_types.dr_slayer.default
	rescue_types.dr_slayer.bardin_slayer_activated_ability_leap_damage = rescue_types.dr_slayer.default
	rescue_types.dr_slayer.bardin_slayer_activated_ability_movement = rescue_types.dr_slayer.default
	
	rescue_types.we_waywatcher.default = { region = TARGET, stagger = NONE, damage = MEDIUM, target_reaching_type = INDIRECT_SHOT, max_distance = 70 }
	rescue_types.we_waywatcher.kerillian_waywatcher_activated_ability_piercing_shot = rescue_types.we_waywatcher.default
	rescue_types.we_waywatcher.kerillian_waywatcher_activated_ability_additional_projectile = rescue_types.we_waywatcher.default
	rescue_types.we_waywatcher.kerillian_waywatcher_activated_ability_restore_ammo_on_career_skill_special_kill = rescue_types.we_waywatcher.default
	
	rescue_types.we_maidenguard.default = { region = TARGET, stagger = NONE, damage = MEDIUM, target_reaching_type = we_maidenguard_lunge_default, max_distance = 10 }
	rescue_types.we_maidenguard.kerillian_maidenguard_activated_ability_invis_duration = { region = TARGET, stagger = NONE, damage = MEDIUM, target_reaching_type = we_maidenguard_lunge_default, max_distance = 10 + 1 }
	rescue_types.we_maidenguard.kerillian_maidenguard_activated_ability_damage = { region = TARGET, stagger = NONE, damage = MEDIUM, target_reaching_type = we_maidenguard_lunge_bleed, max_distance = 10 }
	rescue_types.we_maidenguard.kerillian_maidenguard_activated_ability_buff_on_enemy_hit = rescue_types.we_maidenguard.default
	
	rescue_types.we_shade.default = { region = TARGET, stagger = NONE, damage = MEDIUM, target_reaching_type = WALK, max_distance = 13 }
	rescue_types.we_shade.kerillian_shade_activated_stealth_combo = rescue_types.we_maidenguard.default
	rescue_types.we_shade.kerillian_shade_activated_ability_phasing = { region = TARGET, stagger = NONE, damage = WEAK, target_reaching_type = WALK, max_distance = 15 }
	rescue_types.we_shade.kerillian_shade_activated_ability_restealth = rescue_types.we_maidenguard.default
	
	rescue_types.we_thornsister.default = { region = TARGET, stagger = WEAK, damage = NONE, target_reaching_type = ABILITY_EXPLOSION, max_distance = 20 }
	rescue_types.we_thornsister.kerillian_thorn_sister_tanky_wall = rescue_types.we_thornsister.default
	rescue_types.we_thornsister.kerillian_thorn_sister_wall_push = { region = TARGET, stagger = MEDIUM, damage = NONE, target_reaching_type = ABILITY_EXPLOSION, max_distance = 20 }
	rescue_types.we_thornsister.kerillian_thorn_sister_debuff_wall = { region = TARGET, stagger = STRONG, damage = NONE, target_reaching_type = ABILITY_EXPLOSION, max_distance = 20 }
	
	rescue_types.wh_captain.default = { region = CIRCLE, stagger = STRONG, damage = NONE, target_reaching_type = NONE, max_distance = 10 }
	rescue_types.wh_captain.victor_captain_activated_ability_stagger_ping_debuff = rescue_types.wh_captain.default
	rescue_types.wh_captain.victor_witchhunter_activated_ability_guaranteed_crit_self_buff = rescue_types.wh_captain.default
	rescue_types.wh_captain.victor_witchhunter_activated_ability_refund_cooldown_on_enemies_hit = rescue_types.wh_captain.default
	
	rescue_types.wh_bountyhunter.default = { region = TARGET, stagger = STRONG, damage = MEDIUM, target_reaching_type = SHOT, max_distance = 70 }
	rescue_types.wh_bountyhunter.victor_bountyhunter_activated_ability_reset_cooldown_on_stacks = rescue_types.wh_bountyhunter.default
	rescue_types.wh_bountyhunter.victor_bountyhunter_activated_ability_railgun = rescue_types.wh_bountyhunter.default
	rescue_types.wh_bountyhunter.victor_bountyhunter_activated_ability_blast_shotgun = { region = TARGET, stagger = STRONG, damage = MEDIUM, target_reaching_type = SHOT, max_distance = 12 }
	
	rescue_types.wh_zealot.default = { region = TARGET, stagger = NONE, damage = MEDIUM, target_reaching_type = wh_zealot_lunge_default, max_distance = 12 }
	rescue_types.wh_zealot.victor_zealot_activated_ability_power_on_hit = rescue_types.wh_zealot.default
	rescue_types.wh_zealot.victor_zealot_activated_ability_ignore_death = rescue_types.wh_zealot.default
	rescue_types.wh_zealot.victor_zealot_activated_ability_cooldown_stack_on_hit = rescue_types.wh_zealot.default
	
	rescue_types.bw_adept.default = { region = TARGET, stagger = STRONG, damage = MEDIUM, target_reaching_type = LEAP, max_distance = 10 + 1 }
	rescue_types.bw_adept.sienna_adept_activated_ability_cooldown = rescue_types.bw_adept.default
	rescue_types.bw_adept.sienna_adept_activated_ability_explosion = rescue_types.bw_adept.default
	rescue_types.bw_adept.sienna_adept_ability_trail_double = rescue_types.bw_adept.default
	
	
	rescue_types.bw_scholar.default = { region = TARGET, stagger = STRONG, damage = MEDIUM, target_reaching_type = INDIRECT_SHOT, max_distance = 70 }
	rescue_types.bw_scholar.sienna_scholar_activated_ability_dump_overcharge = rescue_types.bw_scholar.default
	rescue_types.bw_scholar.sienna_scholar_activated_ability_heal = rescue_types.bw_scholar.default
	rescue_types.bw_scholar.sienna_scholar_activated_ability_crit_refresh_cooldown = rescue_types.bw_scholar.default
	
	rescue_types.bw_unchained.default = { region = CIRCLE, stagger = WEAK, damage = WEAK, target_reaching_type = NONE, max_distance = 5 }
	rescue_types.bw_unchained.sienna_unchained_activated_ability_power_on_enemies_hit = rescue_types.bw_unchained.default
	rescue_types.bw_unchained.sienna_unchained_activated_ability_fire_aura = { region = CIRCLE, stagger = STRONG, damage = MEDIUM, target_reaching_type = NONE, max_distance = 5 }
	rescue_types.bw_unchained.sienna_unchained_activated_ability_temp_health = rescue_types.bw_unchained.default
	
	for career_name, career_rescues in pairs(rescue_types) do
		for ability_specialisation, rescue_type in pairs(career_rescues) do
			if rescue_type.region == CIRCLE then
				rescue_type.rescue_attempt_time = RESQUE_ATTEMPT_TIME_CIRCLE
			elseif rescue_type.target_reaching_type == WALK then
				rescue_type.rescue_attempt_time = RESQUE_ATTEMPT_TIME_TARGET_WALK_KILL
			elseif rescue_type.target_reaching_type == SHOT or rescue_type.target_reaching_type == INDIRECT_SHOT then
				rescue_type.rescue_attempt_time = RESQUE_ATTEMPT_TIME_TARGET_SHOT
			elseif rescue_type.stagger < rescue_type.damage then
				rescue_type.rescue_attempt_time = RESQUE_ATTEMPT_TIME_TARGET_KILL
			else
				rescue_type.rescue_attempt_time = RESQUE_ATTEMPT_TIME_TARGET_STAGGER
			end
		end
	end
end

init_rescue_types()

local captures = {}

local function update_allies_captures(self_unit)
	local _captures = { num_valid_allies = 1 }
	local side = Managers.state.side.side_by_unit[self_unit]
	local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
	
	for k = 1, #player_and_bot_units, 1 do
		local player_unit = player_and_bot_units[k]
		local status_ext = ScriptUnit.extension(player_unit, "status_system")
		local _disabler = status_ext:get_disabler_unit()
		
		if not _disabler then
			if status_ext:is_disabled() and player_unit ~= self_unit then
				_captures.num_valid_allies = _captures.num_valid_allies + 1
			end
		elseif status_ext:is_grabbed_by_chaos_spawn() or status_ext:is_grabbed_by_tentacle() then
			table.insert(_captures, {disabler = _disabler, vitality = STRONG, victim = player_unit, nature = "tentacle", power = STRONG, danger_for_life = 10})
		elseif status_ext:is_grabbed_by_pack_master() then
			table.insert(_captures, {disabler = _disabler, vitality = MEDIUM, victim = player_unit, nature = "pack_master", power = MEDIUM, danger_for_life = 1})
		elseif status_ext:is_pounced_down() then
			table.insert(_captures, {disabler = _disabler, vitality = WEAK, victim = player_unit, nature = "assasin", power = WEAK, danger_for_life = 3})
		elseif status_ext:is_grabbed_by_corruptor() then
			table.insert(_captures, {disabler = _disabler, vitality = MEDIUM, victim = player_unit, nature = "corruptor", power = WEAK, danger_for_life = 1.5})
		end
	end
	
	for k = 1, #captures, 1 do
		local capture = captures[k]
		local capture_disabler = capture.disabler
		local index = find_in_array(_captures, capture_disabler, "disabler")
		
		if capture.helper and index then
			_captures[index].helper = capture.helper
			_captures[index].rescue_start_time = capture.rescue_start_time
			_captures[index].rescue_attempt_time = capture.rescue_attempt_time
		end
	end
	
	captures = table.clone(_captures)
end

local target_position = mod.utility.target_position
	
local get_talent_specialisation = mod.utility.get_talent_specialisation

local obstructed_path = mod.utility.check_obstruction

local function _threat_to_ally_level(ally, enemies, disabler)
	local ally_position = POSITION_LOOKUP[ally]
	local total_threat_value = 0
	local threat_cap = 30
	
	local threat_distance_sq = 100
	local min_safe_distance_sq = 25
	
	for _, enemy_unit in pairs(enemies) do		
		if ALIVE[enemy_unit] and (not disabler or enemy_unit ~= disabler) then
			local enemy_position = POSITION_LOOKUP[enemy_unit]
			local enemy_distance_sq = Vector3.distance_squared(ally_position, enemy_position)

			if enemy_distance_sq <= threat_distance_sq then
				local enemy_blackboard = BLACKBOARDS[enemy_unit]
				local enemy_breed = enemy_blackboard.breed
				local is_elite = enemy_breed.elite
				local is_targeting_bot = enemy_blackboard.target_unit == self_unit
				local threat_value = (enemy_breed.threat_value * (is_elite and 0.5 or 1) + (is_targeting_bot and (is_elite and (10 + enemy_breed.threat_value * 0.5) or 4) or 0)) * (enemy_distance_sq < min_safe_distance_sq and 1.7 or 1)
				
				total_threat_value = total_threat_value + threat_value
				
				if total_threat_value >= threat_cap * 1.5 then
					break
				end
			end
		end
	end
	
	return total_threat_value < threat_cap * 1.5 and total_threat_value / threat_cap or 1.5
end

local function _passage_block_level(blackboard, target_reaching_type, self_unit, career_extension, self_position, aim_position, exception_unit)
	local proximite_enemies = blackboard.proximite_enemies
	local num_proximite_enemies = #proximite_enemies
	local aim_vector = aim_position - self_position
	local aim_distance_squared = Vector3.distance_squared(self_position, aim_position)
	local is_ability_lunge = target_reaching_type ~= NONE and target_reaching_type ~= WALK and target_reaching_type ~= LEAP and target_reaching_type ~= SHOT and target_reaching_type ~= INDIRECT_SHOT and target_reaching_type ~= ABILITY_EXPLOSION
	
	local damage_settings = nil
	local max_targets = nil
	if is_ability_lunge then
		damage_settings = target_reaching_type
		local damage_profile_name = damage_settings.damage_profile or "default"
		local career_power_level = career_extension:get_career_power_level()
		local power_level_multiplier = damage_settings.power_level_multiplier
		local power_level = career_power_level * power_level_multiplier
		power_level = math.clamp(power_level, MIN_POWER_LEVEL, MAX_POWER_LEVEL)
		local damage_profile = DamageProfileTemplates[damage_profile_name]
		local difficulty_level = Managers.state.difficulty:get_difficulty()
		local cleave_power_level = ActionUtils.scale_power_levels(power_level, "cleave", owner_unit, difficulty_level)
		local max_targets_attack, max_targets_impact = ActionUtils.get_max_targets(damage_profile, cleave_power_level)
		local max_targets_attack = max_targets_attack
		local max_targets_impact = max_targets_impact
		max_targets = (max_targets_impact < max_targets_attack and max_targets_attack) or max_targets_impact
	end
	
	local passage_block_level = 0
	local passage_block_cap = 30
	local amount_of_mass_hit = 0
	local will_lunge_be_aborted = false
	
	
	for i = 1, num_proximite_enemies, 1 do
		local enemy_unit = proximite_enemies[i]
		
		if ALIVE[enemy_unit] and (not exception_unit or enemy_unit ~= exception_unit) then
			local enemy_position = POSITION_LOOKUP[enemy_unit]
			local enemy_distance_sq = Vector3.distance_squared(aim_position, enemy_position)
			local enemy_blackboard = BLACKBOARDS[enemy_unit]

			if enemy_blackboard and enemy_distance_sq < aim_distance_squared then
				local enemy_breed = enemy_blackboard.breed
				local enemy_threat = enemy_breed.threat_value
				local enemy_vector = enemy_position - self_position
				local passage_block_vector = aim_vector + enemy_vector
				local passage_block_direction = Vector3.normalize(passage_block_vector)
				local aim_direction = Vector3.normalize(aim_vector)
				local dot = Vector3.dot(aim_direction, passage_block_direction)
				local is_blocking_passage = dot >= ((enemy_threat < 8) and 0.99 or 0.965)
				
				if is_blocking_passage then
					passage_block_level = passage_block_level + enemy_threat
					
					if is_ability_lunge then
						local is_enemy = Managers.state.side:is_enemy(self_unit, enemy_unit)
						local hit_mass_total = 0
						if enemy_breed and is_enemy then
							local difficulty_rank = Managers.state.difficulty:get_difficulty_rank()
							local shield_blocked = not damage_settings.ignore_shield and AiUtils.attack_is_shield_blocked(enemy_unit, self_unit)
							hit_mass_total = (shield_blocked and ((enemy_breed.hit_mass_counts_block and enemy_breed.hit_mass_counts_block[difficulty_rank]) or enemy_breed.hit_mass_count_block)) or (enemy_breed.hit_mass_counts and enemy_breed.hit_mass_counts[difficulty_rank]) or enemy_breed.hit_mass_count or 1
							local action_mass_override = damage_settings.hit_mass_count

							if action_mass_override and action_mass_override[enemy_breed.name] then
								local mass_cost_multiplier = damage_settings.hit_mass_count[enemy_breed.name]
								hit_mass_total = hit_mass_total * (mass_cost_multiplier or 1)
							end
						end
						
						amount_of_mass_hit = amount_of_mass_hit + hit_mass_total
						local hit_mass_count_reached = max_targets <= amount_of_mass_hit or enemy_breed.armor_category == 2 or enemy_breed.armor_category == 3
						will_lunge_be_aborted = damage_settings.interrupt_on_first_hit or (hit_mass_count_reached and damage_settings.interrupt_on_max_hit_mass)
					end
				end
				
				if passage_block_level >= passage_block_cap * 1.5 or will_lunge_be_aborted then
					break
				end
			end
		end
	end
	
	return passage_block_level < passage_block_cap * 1.5 and passage_block_level / passage_block_cap or 1.5, will_lunge_be_aborted
end

local function _lack_of_health_level(ally)
	local health_ext = ScriptUnit.extension(ally, "health_system")
	local ally_health_percent = health_ext:current_permanent_health_percent()
	
	return Unit.alive(ally) and 1 - ally_health_percent or 1
end

local function _remoteness_level(distance, max_distance)
	return distance < max_distance and distance / max_distance or 1
end

BTConditions.can_activate_ability_to_rescue_ally = function (blackboard, args)
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	local ability_check_category_name = args[1]
	local ability_check_category = BTConditions.ability_check_categories[ability_check_category_name]
	
	if not ability_check_category or not ability_check_category[career_name] then
		return false
	end
	
	local self_unit = blackboard.unit
	local is_using_ability = blackboard.activate_ability_data.is_using_ability
	local active_ability_talents = career_name and get_talent_specialisation(career_name, 6) or nil
	local active_ability_specialisation = active_ability_talents and (#active_ability_talents > 0 and active_ability_talents[1] or "default") or nil
	local has_charge_reset = false
	local career_rescue_types = career_name and careers_abilities_rescue_types[career_name] or nil
	local rescue_type = nil
	local status_ext = ScriptUnit.extension(self_unit, "status_system")
	
	if career_rescue_types then
		rescue_type = career_rescue_types[active_ability_specialisation]
		
		if not rescue_type then
			return false
		end
	end
	
	local utility = 0
	if career_name == "es_knight" and get_talent_specialisation(career_name, 5).markus_knight_charge_reset_on_incapacitated_allies then
		utility = utility + 1.2
	end
	
	if career_name == "we_thornsister" and get_talent_specialisation(career_name, 4).kerillian_thorn_sister_passive_team_buff then
		utility = utility - 1
	end
	
	if not career_extension:can_use_activated_ability() then
		return false
	end
	
	if not rescue_type then
		return false
	end
	
	if not Unit.alive(self_unit) or status_ext:is_disabled() then
		return false
	end
	
	if is_using_ability then
		if ability_check_category_name == "shoot_ability" then
			return false
		end
		
		return true
	end
	
	update_allies_captures(self_unit)
	
	local first_person_extension = blackboard.first_person_extension
	local self_position = first_person_extension:current_position()
	local can_activate = false
	
	for k = 1, #captures, 1 do
		local capture = captures[k]
		local disabler = capture.disabler
		local current_time = Managers.time:time("game")
		
		if ALIVE[disabler] and (capture.helper == nil or (current_time - capture.rescue_start_time) > capture.rescue_attempt_time) then
			local disabler_position = target_position(disabler)
			if capture.nature == "pack_master" then
				local bb_disabler = BLACKBOARDS[disabler]
				local bb_locomotion_extension = bb_disabler.locomotion_extension
				local velocity_direction = Vector3.normalize(Vector3.flat(-bb_locomotion_extension:current_velocity()))
				disabler_position = disabler_position + velocity_direction * 3
			end
			local disabler_distance_sq = Vector3.distance_squared(self_position, disabler_position)
			local is_in_range = disabler_distance_sq <= rescue_type.max_distance * rescue_type.max_distance
			
			if is_in_range and math.max(rescue_type.stagger, rescue_type.damage) >= capture.power then
				if can_activate and rescue_type.region == CIRCLE then
					capture.helper = self_unit
				else
					local ally = capture.victim
					local disabler_distance = math.sqrt(disabler_distance_sq)
					local threat_to_ally_level = _threat_to_ally_level(ally, blackboard.proximite_enemies, disabler)
					local passage_block_level, will_lunge_be_aborted = (disabler_distance > 0.5) and _passage_block_level(blackboard, rescue_type.target_reaching_type, self_unit, career_extension, self_position, disabler_position, disabler) or 0, false					
					local is_vortex_near = ScriptUnit.extension(ally, "status_system").near_vortex
					
					if is_vortex_near and capture.target_reaching_type ~= NONE and capture.target_reaching_type ~= SHOT and capture.target_reaching_type ~= INDIRECT_SHOT then
						will_lunge_be_aborted = true
					end
					
					local lack_of_health_level = _lack_of_health_level(ally)
					local remoteness_level = _remoteness_level(disabler_distance, rescue_type.max_distance)
					utility = (0.75 + remoteness_level * 0.6) * threat_to_ally_level + (0.75 + remoteness_level * 0.5) * passage_block_level + (0.2 + remoteness_level * 0.8) * lack_of_health_level * capture.danger_for_life + 0.05 * remoteness_level + 0.5 * ((3 - captures.num_valid_allies) * 0.5) + 100 * (capture.danger_for_life >= 10 and 1 or 0)
					local worth_to_use_ult = utility > 1.7 and not will_lunge_be_aborted
					
					if worth_to_use_ult then
						if rescue_type.region == TARGET and rescue_type.target_reaching_type ~= WALK and rescue_type.target_reaching_type ~= INDIRECT_SHOT then
							local is_target_obstructed_by_static = obstructed_path(blackboard, disabler, { target_position = disabler_position })
							if not is_target_obstructed_by_static then
								capture.helper = self_unit
								capture.rescue_start_time = current_time
								capture.rescue_attempt_time = rescue_type.rescue_attempt_time
								if rescue_type.target_reaching_type ~= SHOT then
									blackboard.activate_ability_data.aim_position:store(disabler_position)
								end
								blackboard.target_unit = disabler
								can_activate = true
								break
							end
						elseif rescue_type.region == TARGET and rescue_type.target_reaching_type == WALK then
							capture.helper = self_unit
							capture.rescue_start_time = current_time
							capture.rescue_attempt_time = rescue_type.rescue_attempt_time
							blackboard.target_unit = disabler
							can_activate = true
							break
						elseif rescue_type.region == TARGET and rescue_type.target_reaching_type == INDIRECT_SHOT then
							capture.helper = self_unit
							capture.rescue_start_time = current_time
							capture.rescue_attempt_time = rescue_type.rescue_attempt_time
							blackboard.target_unit = disabler
							can_activate = true
							break
						else
							capture.helper = self_unit
							capture.rescue_start_time = current_time
							capture.rescue_attempt_time = rescue_type.rescue_attempt_time
							can_activate = true
						end
					end
				end
			end
		end
	end

	return can_activate
end
