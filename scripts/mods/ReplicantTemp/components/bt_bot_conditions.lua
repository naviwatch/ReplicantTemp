local mod = get_mod("ReplicantTemp")

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

--melee range decides whether bots have melee weapons out

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

local is_unit_alive = Unit.alive

mod:hook_origin(SimpleInventoryExtension, "current_ammo_status", function (self, slot_name)
	local slot_data = self._equipment.slots[slot_name]

	if not slot_data then
		return
	end

	local item_data = slot_data.item_data
	local item_template = slot_data.item_template or BackendUtils.get_item_template(item_data)
	local ammo_data = item_template.ammo_data

	if ammo_data then
		local right_unit = slot_data.right_unit_1p
		local left_unit = slot_data.left_unit_1p
		local ammo_extension = GearUtils.get_ammo_extension(right_unit, left_unit)

		if ammo_extension then
			local remaining_ammo = ammo_extension:total_remaining_ammo()
			local max_ammo = ammo_extension:max_ammo()
			local ammo_in_clip = ammo_extension:ammo_count()
			local clip_size = ammo_extension:clip_size()
			
			return remaining_ammo, max_ammo, ammo_in_clip, clip_size
		end
	end
end)

mod:hook(BTConditions, "has_target_and_ammo_greater_than", function(func, blackboard, args)
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	local target_unit = blackboard.target_unit
	
	if not ALIVE[target_unit] then
		return false
	end
	
	local breed = Unit.get_data(target_unit, "breed")
	
	if breed == nil then
		return false
	end
	
	local inventory_extension = blackboard.inventory_extension
	local ranged_slot_data = inventory_extension:get_slot_data("slot_ranged")
	local ranged_slot_template = inventory_extension:get_item_template(ranged_slot_data)
	local ranged_slot_name = ranged_slot_template.name
	local ranged_slot_buff_type = ranged_slot_template and ranged_slot_template.buff_type
	local is_ranged = RangedBuffTypes[ranged_slot_buff_type]

	if not is_ranged then
		return false
	end
	
	local target_buff_extension = ScriptUnit.has_extension(target_unit, "buff_system")

	if target_buff_extension and target_buff_extension:has_buff_perk("invulnerable_ranged") then
		return false
	end
	
	if blackboard.ranged_combat_preferred then
		return true
	end
	
	if mod.stop_trash_shooting_ranged[ranged_slot_name] and mod.TRASH_UNITS[breed.name] and not blackboard.ranged_combat_preferred then
		return false
	end
	
	local current, max, ammo_in_clip = inventory_extension:current_ammo_status("slot_ranged")
	local ammo_ok = not current or (args.ammo_percentage < current / max and ammo_in_clip > 0)
	local overcharge_extension = blackboard.overcharge_extension
	local overcharge_limit_type = args.overcharge_limit_type
	local current_oc, threshold_oc, max_oc = overcharge_extension:current_overcharge_status()
	local overcharge_ok = current_oc == 0 or (overcharge_limit_type == "threshold" and current_oc / threshold_oc < args.overcharge_limit) or (overcharge_limit_type == "maximum" and current_oc / max_oc < args.overcharge_limit)
	local obstruction = blackboard.ranged_obstruction_by_static
	local t = Managers.time:time("game")
	local obstructed = obstruction and obstruction.unit == blackboard.target_unit and t <= obstruction.timer + 0.3	--0.5	--1	--3
	local effective_target = AiUtils.has_breed_categories(breed.category_mask, ranged_slot_template.attack_meta_data.effective_against_combined)
	
	local ret = ammo_ok and overcharge_ok and not obstructed and (effective_target or blackboard.ranged_combat_preferred)
	
	if career_name == "we_waywatcher" then
		--mod:echo(current and current / max or nil)
	end
	
	local patrol_in_firing_cone = false
		
	if ret then
		-- check that there is no patrol rats marching on the background
		
		local ai_group_system = Managers.state.entity:system("ai_group_system")
		local self_unit = blackboard.unit
		local self_pos = POSITION_LOOKUP[self_unit]
		
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
							patrol_in_firing_cone = true
							break
						end
					end
				end
			end
		end
	end
	
	--if career_name == "bw_adept" and not ret then
		--mod:echo("not allowed")
	--end
	
	return ret and not patrol_in_firing_cone
end)

--in DifferentBots.lua
--[[
mod:hook_origin(BTConditions, "bot_in_melee_range", function(blackboard)
	local self_unit = blackboard.unit
	local self_owner = Managers.player:unit_owner(self_unit)
	
	local target_unit = blackboard.target_unit
	
	if not ALIVE[target_unit] then
		return false
	end
	
	local breed = Unit.get_data(target_unit, "breed")
	--mod:echo(Unit.get_data(target_unit, "unit_name"))
	
	if not breed then	--this includes halescourge / blood in the darkness / enchanter's lair boss swarm projectiles, use default function
		-- self_owner.last_melee_range_check = false
		-- return false
		
		local melee_range = 4		--3
		local offset = POSITION_LOOKUP[target_unit] - POSITION_LOOKUP[self_unit]
		local distance_squared = Vector3.length_squared(offset)
		local in_range = distance_squared < melee_range^2
		local z_offset = offset.z
		-- local ret = in_range and z_offset > -1.5 and z_offset < 2
		return in_range
	end
	
	local breed_name = breed.name
	local inventory_extension = blackboard.inventory_extension
	local ranged_slot_data = inventory_extension:get_slot_data("slot_ranged")
	local ranged_slot_template = inventory_extension:get_item_template(ranged_slot_data)
	local ranged_slot_name = ranged_slot_template.name
	local ranged_slot_buff_type = ranged_slot_template and ranged_slot_template.buff_type
	local is_ranged = RangedBuffTypes[ranged_slot_buff_type]
	local effective_target = false

	if is_ranged then
		effective_target = AiUtils.has_breed_categories(breed.category_mask, ranged_slot_template.attack_meta_data.effective_against_combined)
	end
	
	--add exception for halescourge's vortex	--anim == "attack_staff"
	if breed_name == "chaos_exalted_sorcerer" then
		local breed_bb = target_unit and BLACKBOARDS[target_unit]
		local current_time = Managers.time:time("game")
		
		-- mod:echo("chaos_exalted_sorcerer")
		-- if breed_bb and breed_bb.action then
			-- mod:echo(breed_bb.action.name)
		-- end
		
		if (breed_bb and breed_bb.action and (breed_bb.action.name == "spawn_boss_vortex" or breed_bb.action.name == "spawn_flower_wave")) or
			(last_halescourege_teleport_time and current_time < last_halescourege_teleport_time + 3.5) then
			
			return false
		end
	end
	
	if blackboard.melee_combat_preferred then
		return true
	end
	
	local breed_melee_range = {
		-- skaven_slave = true,
		-- skaven_clan_rat = true,
		-- skaven_clan_rat_with_shield = true,
		-- chaos_fanatic = true,
		-- chaos_marauder = true,
		-- chaos_marauder_with_shield = true,
		-- beastmen_gor = true,
		-- beastmen_ungor = true,
		-- beastmen_ungor_archer = true,
		-- skaven_storm_vermin = true,
		-- skaven_storm_vermin_commander = true,
		-- skaven_storm_vermin_with_shield = true,
		-- chaos_raider = true,
		-- chaos_warrior = true,
		-- beastmen_bestigor = true,
		-- beastmen_standard_bearer = true,
		-- skaven_plague_monk = true,
		-- chaos_berzerker = true,
		skaven_warpfire_thrower = 2,
		skaven_ratling_gunner = 2,
		skaven_pack_master = 1,
		-- skaven_gutter_runner = true,
		-- skaven_poison_wind_globadier = true,
		-- chaos_vortex_sorcerer = true,
		-- chaos_corruptor_sorcerer = true,
		skaven_explosive_loot_rat = 0,
		-- curse_mutator_sorcerer = true,
		-- chaos_plague_sorcerer = true,
		-- chaos_plague_wave_spawner = true,
		-- chaos_tentacle_sorcerer = true,
		-- skaven_rat_ogre = true,
		-- skaven_stormfiend = true,
		-- chaos_troll = true,
		-- chaos_spawn = true,
		-- beastmen_minotaur = true,
		-- skaven_stormfiend_boss = true,
		-- skaven_storm_vermin_warlord = true,
		chaos_exalted_sorcerer = 5,		--6		--10	--20	--12
		-- chaos_exalted_champion_warcamp = true,
		-- chaos_exalted_champion_norsca = true,
		skaven_grey_seer = 5,	--12
		-- skaven_stormfiend_boss = true,
		chaos_exalted_sorcerer_drachenfels = 3,	--12
		-- critter_rat = true,
		-- critter_pig = true,
		-- skaven_loot_rat = true,
	}
	
	local party_danger = AiUtils.get_party_danger()
	local melee_range = math.lerp(12, 5, party_danger)	--12		--bot_settings.default.melee_range.default
	-- local melee_range = 12
	
	
	-- if mod.TRASH_UNITS[breed_name] or mod.BERSERKER_UNITS[breed_name] then
	if mod.TRASH_UNITS[breed_name] then
		melee_range = 3

		-- local follow_bb			= blackboard.follow
		-- local follow_position	= nil
		-- local follow_unit		= nil
		-- if blackboard and blackboard.ai_bot_group_extension and blackboard.ai_bot_group_extension.data then
			-- follow_position	= blackboard.ai_bot_group_extension.data.follow_position
			-- follow_unit		= blackboard.ai_bot_group_extension.data.follow_unit
		-- end
		
		-- local career_extension = blackboard.career_extension
		-- local career_name = career_extension:career_name()
	
	elseif mod.ELITE_UNITS[breed_name] or mod.BERSERKER_UNITS[breed_name] then
		melee_range = 4
	elseif mod.SPECIAL_UNITS[breed_name] then
		melee_range = 3
	elseif mod.BOSS_UNITS[breed_name] then
		melee_range = 6		--3		--make bots melee bosses
	elseif mod.LORD_UNITS[breed_name] then
		melee_range = 6		--3		--make bots melee bosses
	end
	
	if breed_melee_range[breed_name] then
		melee_range = breed_melee_range[breed_name]
	end
	
	local aoe_threat = true
	if self_owner.defense_data then
		if not self_owner.defense_data.threat.boss and not self_owner.defense_data.threat.aoe_elite then
			aoe_threat = false
		end
	end
		
	if mod.TRASH_UNITS[breed_name] or mod.ELITE_UNITS[breed_name] or mod.BERSERKER_UNITS[breed_name] then
		--pull out melee weapons to defend sooner in case of aoe threat
		if aoe_threat then
			melee_range = 5
		end
	-- elseif mod.BOSS_UNITS[breed_name] or mod.LORD_UNITS[breed_name] then
	elseif mod.BOSS_UNITS[breed_name] then
		local flank_angle = (self_owner.last_melee_range_check and 90) or 120
		local in_front, flanking = mod.check_alignment_to_target(self_unit, target_unit, 90, flank_angle)
		-- if not flanking then
			-- melee_range = 6
		-- end
		
		if flanking then
			local career_extension = blackboard.career_extension
			local career_name = career_extension:career_name()
			
			if mod.monster_dps_ranged[ranged_slot_name] or
				(ranged_slot_name == "shortbow_hagbane_template_1" and career_name == "we_waywatcher") or
				(ranged_slot_name == "staff_spark_spear_template_1" and career_name == "bw_adept") then
				
				melee_range = 0
			end
		end
	end
	
	--stickiness to melee when enemies got knocked back (conditions can be improved but generally only trash units get huge knockback)
	local wielded_slot = blackboard.inventory_extension:equipment().wielded_slot
	if mod.TRASH_UNITS[breed_name] and wielded_slot == "slot_melee" then
		melee_range = 5
	end
	
	local check_range = math.min(melee_range, 3.5)
	
	local target_aim_position = nil
	local override_aim_node_name = breed.bot_melee_aim_node

	--Override for Chaos Warriors
	if breed_name == "chaos_warrior" then
		override_aim_node_name = "j_head"
	end
	
	--Override for Chaos Trolls
	if breed_name == "chaos_troll" then
		override_aim_node_name = "j_head"
	end
	
	--Override for Maulers
	if breed_name == "chaos_raider" then
		override_aim_node_name = "j_spine"
	end
	
	if override_aim_node_name then
		local override_aim_node = Unit.node(target_unit, override_aim_node_name)
		target_aim_position = Unit.world_position(target_unit, override_aim_node)
	else
		target_aim_position = POSITION_LOOKUP[target_unit]
	end
	
	if blackboard.ranged_combat_preferred then
		melee_range = 0
	end
	
	local offset = target_aim_position - POSITION_LOOKUP[self_unit]
	local distance_squared = Vector3.length_squared(offset)
	-- local use_melee = distance_squared < check_range^2
	local use_melee = distance_squared < melee_range^2
	
	--meh, i will just copy the whole _defend function for now
	local prox_enemies = mod.get_proximite_enemies(self_unit, 7, 3.8)	--7, 3
	for key, loop_unit in pairs(prox_enemies) do
		local loop_breed = Unit.get_data(loop_unit, "breed")
		local loop_bb = BLACKBOARDS[loop_unit]
		local loop_distance = Vector3.length(POSITION_LOOKUP[self_unit] - POSITION_LOOKUP[loop_unit])
		
		if loop_bb then
			if mod.TRASH_UNITS[loop_breed.name] or mod.BERSERKER_UNITS[loop_breed.name] then
				if loop_bb.attacking_target == self_unit and not loop_bb.past_damage_in_attack_1 then
					use_melee = true
				end
			elseif mod.ELITE_UNITS[loop_breed.name] or loop_breed.name == "beastmen_standard_bearer" then
				if loop_bb.attacking_target and not loop_bb.past_damage_in_attack_1 then
					--can refine the angle if we know hitbox and animation
					local infront_of_loop_unit, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, 160, 120)	--160, 120	--120, 120	--90, 120
					if infront_of_loop_unit or (loop_distance < 3 and not flanking_loop_unit) then
						if loop_bb.moving_attack then
							aoe_threat = true
						elseif loop_distance < 6 then	--5
							aoe_threat = true
						end
					end
				end
			elseif mod.BOSS_UNITS[loop_breed.name] or mod.LORD_UNITS[loop_breed.name] then
				--TODO: change this after fixing _defend for bosses
				if loop_bb.attacking_target and not loop_bb.past_damage_in_attack_1 then
					local infront_of_loop_unit, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, 160, 120)
					if infront_of_loop_unit or (loop_distance < 4.5 and not flanking_loop_unit) then	--4
						aoe_threat = true
					end
				end
			end
		end
	end
	
	local ret = use_melee or aoe_threat
	-- local ret = use_melee or aoe_threat or (prox_enemy_count > 0)
	self_owner.last_melee_range_check = ret
	
	return ret
end)
--]]