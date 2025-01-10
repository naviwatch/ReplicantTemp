local mod = get_mod("ReplicantTemp")

local function get_others_healing_items(blackboard, self_unit)
	local side = blackboard.side
	local PLAYER_AND_BOT_UNITS = side.PLAYER_AND_BOT_UNITS
	local first_aid_kits_number = 0
	
	for i = 1, #PLAYER_AND_BOT_UNITS, 1 do
		local player_unit = PLAYER_AND_BOT_UNITS[i]
		
		if Unit.alive(player_unit) and player_unit ~= self_unit then
			local inventory_extension = ScriptUnit.extension(player_unit, "inventory_system")
			local slot_data = inventory_extension:get_slot_data("slot_healthkit")
			
			if slot_data then
				local current_item_template = inventory_extension:get_item_template(slot_data)
				local has_first_aid_kit = current_item_template.pickup_data and current_item_template.pickup_data.pickup_name == "first_aid_kit" or false
				
				if has_first_aid_kit then
					first_aid_kits_number = first_aid_kits_number + 1
				end
			end
		end
	end
	
	return first_aid_kits_number
end

local consts_ = mod.heal_constants

local WANTS_TO_HEAL_THRESHOLD_LOW = 0.25
local WANTS_TO_HEAL_THRESHOLD_HIGH = 0.6
mod:hook(BTConditions, "bot_should_heal", function (func, blackboard)
	local self_unit = blackboard.unit
	local force_use_health_pickup = blackboard.force_use_health_pickup
	local inventory_extension = blackboard.inventory_extension
	local buff_extension = ScriptUnit.extension(self_unit, "buff_system")
	local health_slot_data = inventory_extension:get_slot_data("slot_healthkit")
	local template = health_slot_data and inventory_extension:get_item_template(health_slot_data)
	local exists_ally_need_healing = blackboard.target_ally_unit and blackboard.target_ally_need_type == "in_need_of_heal"
	local can_heal_other = template and template.can_heal_other
	local can_heal_self = template and template.can_heal_self
	
	if not can_heal_self or (can_heal_other and exists_ally_need_healing) then
		return false
	end

	local is_zealot = ScriptUnit.has_extension(self_unit, "career_system") and ScriptUnit.extension(self_unit, "career_system"):career_name() == "wh_zealot"
	local has_natural_bond = buff_extension:has_buff_type("trait_necklace_no_healing_health_regen")
	local heal_threshold = nil

	local heal_threshold_zealot = mod.components.self_heal_threshold_zealot.value
	if is_zealot and heal_threshold_zealot ~= consts_.AS_OTHERS then
		heal_threshold = heal_threshold_zealot
	elseif has_natural_bond then
		heal_threshold = mod.components.self_heal_threshold_nb.value
	else
		heal_threshold = mod.components.self_heal_threshold.value
	end
	
	local current_health_percent = blackboard.health_extension:current_health_percent()
	local hurt = heal_threshold == consts_.ITEM_DEPENDENT and current_health_percent <= template.bot_heal_threshold or current_health_percent <= WANTS_TO_HEAL_THRESHOLD_HIGH
	local seriously_hurt = heal_threshold ~= consts_.ITEM_DEPENDENT and current_health_percent <= WANTS_TO_HEAL_THRESHOLD_LOW or false
	local target_unit = blackboard.target_unit
	local wounded = blackboard.status_extension:is_wounded()
	local hp_condition = nil

	if wounded and current_health_percent <= WANTS_TO_HEAL_THRESHOLD_LOW then
		hp_condition = consts_.WOUNDED_AND_LOW
	elseif wounded then
		hp_condition = consts_.WOUNDED
	elseif seriously_hurt then
		hp_condition = consts_.SERIOUSLY_HURT
	elseif hurt then
		hp_condition = consts_.HURT
	else
		hp_condition = consts_.IS_OK
	end
	
	if force_use_health_pickup and (not is_zealot or heal_threshold_zealot == consts_.AS_OTHERS) then
		hp_condition = consts_.EXTRA_HEAL_AVAILABLE
	end
	
	if heal_threshold == consts_.WAIT_HEAL_FROM_OTHERS and hp_condition > consts_.SERIOUSLY_HURT then
		local kits_num = get_others_healing_items(blackboard, self_unit)
		
		if kits_num == 0 then
			heal_threshold = consts_.WOUNDED
		end
	end
	
	local is_safe = not target_unit or ((template.fast_heal or blackboard.is_healing_self) and #blackboard.proximite_enemies == 0) or (target_unit ~= blackboard.priority_target_enemy and target_unit ~= blackboard.urgent_target_enemy and target_unit ~= blackboard.proximity_target_enemy and target_unit ~= blackboard.slot_target_enemy)
	
	return is_safe and heal_threshold <= hp_condition
end)

local SELF_HEAL_STICKINESS = 0.1
local PLAYER_HEAL_STICKYNESS = 0.11
local WANTS_TO_GIVE_HEAL_TO_OTHER = 0.6
mod:hook(PlayerBotBase, "_select_ally_by_utility", function (func, self, unit, blackboard, breed, t)
	local self_pos = POSITION_LOOKUP[unit]
	local closest_ally = nil
	local closest_dist = math.huge
	local closest_real_dist = math.huge
	local closest_in_need_type = nil
	local closest_ally_look_at = false
	local buff_extension = ScriptUnit.extension(unit, "buff_system")
	local inventory_extension = blackboard.inventory_extension
	local health_slot_data = inventory_extension:get_slot_data("slot_healthkit")
	local can_heal_other = false
	local can_give_healing_to_other = false
	local self_health_utiliy = 0
	local self_wounded = false

	if health_slot_data then
		self_wounded = self._status_extension:is_wounded()
		local template = inventory_extension:get_item_template(health_slot_data)
		local has_no_permanent_health_from_item_buff = buff_extension:has_buff_type("trait_necklace_no_healing_health_regen")
		can_heal_other = template.can_heal_other
		can_give_healing_to_other = template.can_give_other

		if not has_no_permanent_health_from_item_buff or self_wounded then
			local self_health_percent = self._health_extension:current_health_percent()
			self_health_utiliy = self:_calculate_healing_item_utility(self_health_percent, self_wounded, can_give_healing_to_other) + SELF_HEAL_STICKINESS * (can_heal_other and -1 or 1)
		end
	end

	local can_give_grenade_to_other = false
	local grenade_slot_data = inventory_extension:get_slot_data("slot_grenade")

	if grenade_slot_data then
		local template = inventory_extension:get_item_template(grenade_slot_data)
		can_give_grenade_to_other = template.can_give_other
	end

	local can_give_potion_to_other = false
	local potion_slot_data = inventory_extension:get_slot_data("slot_potion")

	if potion_slot_data then
		local template = inventory_extension:get_item_template(potion_slot_data)
		can_give_potion_to_other = template.can_give_other
	end

	local conflict_director = Managers.state.conflict
	local self_segment = conflict_director:get_player_unit_segment(unit) or 1
	local level_settings = LevelHelper:current_level_settings()
	local disable_bot_main_path_teleport_check = level_settings.disable_bot_main_path_teleport_check
	--local side = Managers.state.side.side_by_unit[unit]
	--local player_and_bot_units = side.PLAYER_AND_BOT_UNITS

	local players = Managers.player:players()
	
	--for k = 1, #player_and_bot_units, 1 do
	for _, player in pairs(players) do
		local player_unit = player.player_unit
		--local player_unit = player_and_bot_units[k]
		
		if player_unit ~= unit and Unit.alive(player_unit) then
			local status_ext = ScriptUnit.extension(player_unit, "status_system")		
			local utility = 0
			local look_at_ally = false
			
			local ready_for_respawn = status_ext:is_ready_for_assisted_respawn()
			local player_segment = conflict_director:get_player_unit_segment(player_unit) or (ready_for_respawn and 4 or 1)
			
			if not status_ext.near_vortex and (disable_bot_main_path_teleport_check or self_segment <= player_segment) then
				--local player = Managers.player:owner(player_unit)
				local is_bot = not player:is_player_controlled()
				local heal_player_preference = (is_bot and 0) or PLAYER_HEAL_STICKYNESS
				local in_need_type = nil
				
				if status_ext:is_knocked_down() then
					in_need_type = "knocked_down"
					utility = 100
				elseif ready_for_respawn then
					local follow_unit = blackboard.ai_bot_group_extension.data.follow_unit
					local follow_pos = follow_unit and POSITION_LOOKUP[follow_unit]
					local player_pos = POSITION_LOOKUP[player_unit]
					
					local distance_sq = (follow_pos and player_pos) and Vector3.distance_squared(player_pos, follow_pos) or math.huge
					
					if distance_sq <= 100 then
						in_need_type = "knocked_down"
						utility = 90
					end
				elseif status_ext:get_is_ledge_hanging() and not status_ext:is_pulled_up() then
					in_need_type = "ledge"
					utility = 100
				elseif status_ext:is_hanging_from_hook() then
					in_need_type = "hook"
					utility = 100
				else
					local health_percent = ScriptUnit.extension(player_unit, "health_system"):current_permanent_health_percent()
					local health_percent_temporary = ScriptUnit.extension(player_unit, "health_system"):current_health_percent()
					local has_no_permanent_health_from_item_buff = ScriptUnit.extension(player_unit, "buff_system"):has_buff_type("trait_necklace_no_healing_health_regen")
					local player_inventory_extension = ScriptUnit.extension(player_unit, "inventory_system")
					local player_locomotion_extension = ScriptUnit.extension(player_unit, "locomotion_system")
					local is_wounded = status_ext:is_wounded()
					local health_utility = self:_calculate_healing_item_utility(health_percent_temporary, is_wounded, can_give_healing_to_other) + heal_player_preference + (has_no_permanent_health_from_item_buff and 0.1 or 0)
					local heal_other_allowed = (can_heal_other and self_wounded and is_wounded) or self_health_utiliy < health_utility
					local need_attention_type, extra_utility = self:_player_needs_attention(unit, player_unit, blackboard, player_inventory_extension, player_locomotion_extension, t)
					local ally_is_zealot = ScriptUnit.has_extension(player_unit, "career_system") and ScriptUnit.extension(player_unit, "career_system"):career_name() == "wh_zealot"
					local hp_condition = nil
					local used_heal_threshold  = nil
					
					if ally_is_zealot and mod.components.others_heal_threshold_zealot.value ~= consts_.AS_OTHERS then
						used_heal_threshold = mod.components.others_heal_threshold_zealot.value
					else
						used_heal_threshold = mod.components.others_heal_threshold.value
					end
					
					if is_wounded and health_percent_temporary <= WANTS_TO_HEAL_THRESHOLD_LOW then
						hp_condition = consts_.WOUNDED_AND_LOW
					elseif is_wounded then
						hp_condition = consts_.WOUNDED
					elseif health_percent_temporary <= WANTS_TO_HEAL_THRESHOLD_LOW then
						hp_condition = consts_.SERIOUSLY_HURT
					elseif health_percent_temporary <= WANTS_TO_HEAL_THRESHOLD_HIGH then
						hp_condition = consts_.HURT
					else
						hp_condition = consts_.IS_OK
					end
					
					if can_heal_other and (used_heal_threshold <= hp_condition) and heal_other_allowed then
						in_need_type = "in_need_of_heal"
						utility = 70 + health_utility * 15
					elseif can_give_healing_to_other and (not has_no_permanent_health_from_item_buff or is_wounded) and (health_percent < WANTS_TO_GIVE_HEAL_TO_OTHER or is_wounded) and not player_inventory_extension:get_slot_data("slot_healthkit") and heal_other_allowed then
						in_need_type = "can_accept_heal_item"
						utility = 70 + health_utility * 10
					elseif can_give_grenade_to_other and (not player_inventory_extension:get_slot_data("slot_grenade") or player_inventory_extension:can_store_additional_item("slot_grenade")) and not is_bot then
						in_need_type = "can_accept_grenade"
						utility = 70
					elseif can_give_potion_to_other and not player_inventory_extension:get_slot_data("slot_potion") and not is_bot then
						in_need_type = "can_accept_potion"
						utility = 70
					elseif need_attention_type == "stop" then
						in_need_type = "in_need_of_attention_stop"
						look_at_ally = true
						utility = 5 + extra_utility
					elseif need_attention_type == "look_at" then
						in_need_type = "in_need_of_attention_look"
						look_at_ally = true
						utility = 2 + extra_utility
					end
				end

				if in_need_type or not is_bot then
					local target_pos = POSITION_LOOKUP[player_unit]
					local allowed_follow_path, allowed_aid_path = self:_ally_path_allowed(unit, player_unit, t)

					if allowed_follow_path then
						if not allowed_aid_path then
							in_need_type = nil
						elseif in_need_type then
							local alive_bosses = conflict_director:alive_bosses()
							local num_alive_bosses = #alive_bosses

							for i = 1, num_alive_bosses, 1 do
								local boss_unit = alive_bosses[i]
								local boss_position = POSITION_LOOKUP[boss_unit]
								local self_to_boss_distance_sq = Vector3.distance_squared(self_pos, boss_position)
								local boss_target = BLACKBOARDS[boss_unit].target_unit

								if boss_target == unit and self_to_boss_distance_sq < 36 then
									in_need_type = nil
									utility = 0

									break
								end
							end
						end

						if not is_bot then
							utility = utility * 1.25
						end

						if in_need_type or not is_bot then
							local real_dist = Vector3.distance(self_pos, target_pos)
							local dist = real_dist - utility

							if closest_dist > dist then
								closest_dist = dist
								closest_real_dist = real_dist
								closest_ally = player_unit
								closest_in_need_type = in_need_type
								closest_ally_look_at = look_at_ally
							end
						end
					end
				end
			end
		end
	end

	return closest_ally, closest_real_dist, closest_in_need_type, closest_ally_look_at
end)
