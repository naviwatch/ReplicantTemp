local mod = get_mod("ReplicantTemp")

mod:hook(BTBotActivateAbilityAction, "enter", function (func, self, unit, blackboard, t)
	if not mod.components.activate_abilities_tweaks.value then
		--return func(self, unit, blackboard, t)
	end
	
	local action_data = self._tree_node.action_data
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	local ability_action_data = action_data[career_name]
	
	local inventory_extension = blackboard.inventory_extension
	local activate_ability_data = blackboard.activate_ability_data
	activate_ability_data.is_using_ability = true
	activate_ability_data.do_start_input = true
	activate_ability_data.started = false
	activate_ability_data.enter_time = t
	activate_ability_data.start_time = math.huge
	activate_ability_data.destination_reached = nil
	activate_ability_data.next_repath_t = t
	activate_ability_data.activation = ability_action_data.activation
	activate_ability_data.wait_action = ability_action_data.wait_action
	activate_ability_data.end_condition = ability_action_data.end_condition
	activate_ability_data.is_weapon_ability = inventory_extension:get_slot_data("slot_career_skill_weapon") ~= nil
	
	if activate_ability_data.activation.action == "aim_at_target" then
		local aim_position = activate_ability_data.aim_position:unbox()
		local input_extension = blackboard.input_extension
		local soft_aim = not ability_action_data.fast_aim
		
		input_extension:set_aiming(true, soft_aim, false)
		input_extension:set_aim_position(aim_position)
	end
	
	---------------------------------------------------------
	
	activate_ability_data.post_effects = ability_action_data.post_effects
end)

mod:hook(BTBotActivateAbilityAction, "leave", function (func, self, unit, blackboard, t, reason, destroy)
	local activate_ability_data = blackboard.activate_ability_data
	
	if activate_ability_data.activation.action == "aim_at_target" then
		local input_extension = blackboard.input_extension
		
		input_extension:set_aiming(false)
	end
	
	if activate_ability_data.post_effects then
		blackboard.ability_post_effects = table.clone(activate_ability_data.post_effects)
		
		activate_ability_data.post_effects = nil
	end
	
	activate_ability_data.is_using_ability = false
	
	if reason ~= "done" then
		self:_cancel_ability(activate_ability_data, blackboard, t)
	end
end)

local get_yaw_and_pitch_offsets = function(current_rotation, aim_rotation)
	local current_yaw = Quaternion.yaw(current_rotation)
	local current_pitch = Quaternion.pitch(current_rotation)
	
	local aim_yaw = Quaternion.yaw(aim_rotation)
	local aim_pitch = Quaternion.pitch(aim_rotation)
	
	local pi = math.pi
	local yaw_offset = (current_yaw - aim_yaw + pi) % (pi * 2) - pi
	local pitch_offset = current_pitch - aim_pitch
	
	return yaw_offset, pitch_offset
end

local YAW_TRESHOLD = math.pi / 30
local PITCH_TRESHOLD = math.pi / 15
mod:hook(BTBotActivateAbilityAction, "_start_ability", function (func, self, activate_ability_data, blackboard, t)
	local started = false
	local do_start_input = activate_ability_data.do_start_input
	local activation_data = activate_ability_data.activation
	local activation_action = activation_data.action
	
	local needs_aiming = activation_action == "aim_at_target"
	local defend_while_aiming = activation_data.defend_while_aiming
	
	if do_start_input then
		local input_extension = blackboard.input_extension

		local enter_time = activate_ability_data.enter_time
		local min_hold_time = activation_data.min_hold_time or 0
		
		if t >= enter_time + min_hold_time then
			if needs_aiming then
				local first_person_extension = blackboard.first_person_extension
				local current_rotation = first_person_extension:current_rotation()
				
				local camera_position = first_person_extension:current_position()
				local aim_position = activate_ability_data.aim_position:unbox()
				local aim_rotation = Quaternion.look(Vector3.normalize(aim_position - camera_position), Vector3.up())
				
				local yaw_offset, pitch_offset = get_yaw_and_pitch_offsets(current_rotation, aim_rotation)
				
				if math.abs(yaw_offset) <= YAW_TRESHOLD and math.abs(pitch_offset) <= PITCH_TRESHOLD then
					do_start_input = activation_data.max_distance_sq and activation_data.max_distance_sq < Vector3.distance_squared(camera_position, aim_position)
				else
					do_start_input = true
				end
			else
				do_start_input = false
			end
		else
			do_start_input = true
		end
		
		if defend_while_aiming and (needs_aiming and do_start_input) then
			input_extension:defend()
		else
			input_extension:activate_ability()
		end
	elseif activate_ability_data.is_weapon_ability then
		local inventory_extension = blackboard.inventory_extension
		local wielded_slot_data = inventory_extension:get_wielded_slot_data()

		if wielded_slot_data.id ~= "slot_career_skill_weapon" then
			started = false
			do_start_input = true
		else
			started = true
			do_start_input = false
		end
	else
		started = true
		do_start_input = false
	end

	return do_start_input, started
end)


mod:hook(BTBotActivateAbilityAction, "_evaluate_end_condition", function (func, self, activate_ability_data, unit, blackboard, t)
	if not mod.components.activate_abilities_tweaks.value then
		--return func(self, activate_ability_data, unit, blackboard, t)
	end
	
	local end_condition = activate_ability_data.end_condition
	
	if end_condition == nil then
		return "done"
	end

	if end_condition.is_slot_not_wielded then
		local wielded_slot = blackboard.inventory_extension:equipment().wielded_slot

		if not table.contains(end_condition.is_slot_not_wielded, wielded_slot) then
			return "done"
		end
	end

	if end_condition.buffs then
		local buff_extension = ScriptUnit.extension(unit, "buff_system")
		local ability_buff = nil
		local buffs = end_condition.buffs
		local num_buffs = #buffs

		for i = 1, num_buffs, 1 do
			local buff_name = buffs[i]
			ability_buff = buff_extension:get_non_stacking_buff(buff_name)

			if ability_buff then
				break
			end
		end

		local offset_time = end_condition.offset_time

		if ability_buff == nil or (offset_time and ability_buff and ability_buff.end_time and t > ability_buff.end_time - offset_time) then
			return "done"
		end
	end

	if end_condition.done_when_arriving_at_destination then
		local navigation_extension = blackboard.navigation_extension
		local locomotion_extension = blackboard.locomotion_extension
		local current_velocitiy = locomotion_extension:current_velocity()
		local speed_sq = Vector3.length_squared(current_velocitiy)
		local min_speed_sq = 0.04000000000000001
		local duration = t - activate_ability_data.enter_time
		local min_duration = 0.5

		if duration > min_duration and (navigation_extension:destination_reached() or speed_sq <= min_speed_sq) then
			return "done"
		end
	end
	
	local stop_when_destination_reached = end_condition.stop_when_destination_reached
	
	if stop_when_destination_reached then
		local first_person_extension = blackboard.first_person_extension
		local self_position = first_person_extension:current_position()
		local current_rotation = first_person_extension:current_rotation()
		local current_forward = Quaternion.forward(current_rotation)
		local flat_forward = Vector3.normalize(Vector3.flat(current_forward))
		
		local locomotion_extension = blackboard.locomotion_extension
		local current_velocitiy = locomotion_extension:current_velocity()
		local speed_sq = Vector3.length_squared(current_velocitiy)
		local min_speed_sq = 0.09000000000000001
		
		local aim_position = activate_ability_data.aim_position:unbox()
		local offset = aim_position - self_position
		local offset_sq = Vector3.length_squared(offset)
		
		local max_distance = stop_when_destination_reached.max_distance or math.huge
		if offset_sq > max_distance then
			offset = Vector3.normalize(offset) * max_distance
		end
		
		local flat_offset = Vector3.flat(offset)
		
		local normal_dist = Vector3.dot(flat_offset, flat_forward)
		local min_normal_dist = 0.5
		
		local duration = t - activate_ability_data.start_time
		local max_duration = stop_when_destination_reached.max_duration or 1.5
		local min_duration = 0.05 + max_duration / 3
		
		activate_ability_data.destination_reached = activate_ability_data.destination_reached or normal_dist <= min_normal_dist
		
		if (activate_ability_data.destination_reached or (speed_sq <= min_speed_sq and duration > min_duration)) or duration >= max_duration then
			self:_cancel_ability(activate_ability_data, blackboard, t)
			
			return "done"
		end
	end

	return "running"
end)

local function update_target_location(target_unit, aim_position)
	local node = 0
	local target_breed = Unit.get_data(target_unit, "breed")
	local aim_node = (target_breed and (target_breed.bot_melee_aim_node or "j_spine")) or "rp_center"
	
	if Unit.has_node(target_unit, aim_node) then
		node = Unit.node(target_unit, aim_node)
	end
	
	local aim_pos = Unit.world_position(target_unit, node)
	
	aim_position:store(aim_pos)
	
	return aim_pos
end

mod:hook(BTBotActivateAbilityAction, "run", function (func, self, unit, blackboard, t, dt)
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
	
	local data = blackboard.activate_ability_data
	local activation_data = data.activation
	
	if activation_data.dynamic_target_unit then
		local target_unit = (activation_data.custom_target_unit and data.target_unit) or blackboard.target_unit
		
		if ALIVE[target_unit] then
			if target_unit == unit then
				local input_extension = blackboard.input_extension
				
				local first_person_extension = blackboard.first_person_extension
				local camera_position = first_person_extension:current_position()
				local current_rotation = first_person_extension:current_rotation()
				local current_forward = Quaternion.forward(current_rotation)
				
				input_extension:set_aim_position(camera_position + current_forward)
			else
				local aim_position = update_target_location(target_unit, data.aim_position)
				local input_extension = blackboard.input_extension
				
				input_extension:set_aim_position(aim_position)
			end
		else
			return "failed"
		end
	end
	
	if blackboard.status_extension:is_disabled() then
		return "failed"
	end
	
	if not data.started then
		data.do_start_input, data.started = self:_start_ability(data, blackboard, t)
		
		if data.started then
			data.start_time = t
		end
		
		return "running"
	end
	
	if data.is_weapon_ability and data.started then
		blackboard.input_extension:release_ability_hold()
	end
	
	if data.wait_action then
		self:_perform_wait_action(data, unit, blackboard)
	end
	
	return self:_evaluate_end_condition(data, unit, blackboard, t)
end)

mod:hook(PlayerBotInput, "_update_actions", function (func, self)
	return func(self)
	
	--[[local input = self._input

	if self._fire_hold then
		self._fire_hold = false
		input.action_one_hold = true

		if not self._fire_held then
			input.action_one = true
			self._fire_held = true
		end
	elseif self._fire_held then
		self._fire_held = false
		input.action_one_release = true
	elseif self._fire then
		self._fire = false
		input.action_one = true
	end

	if self._melee_push then
		self._melee_push = false
		self._defend = false

		if self._defend_held then
			input.action_one = true
		else
			self._defend_held = true
			input.action_two = true
		end

		input.action_two_hold = true
	elseif self._defend then
		self._defend = false

		if not self._defend_held then
			self._defend_held = true
			input.action_two = true
		end

		input.action_two_hold = true
	elseif self._defend_held then
		self._defend_held = false
		input.action_two_release = true
	end

	if self._cancel_held_ability then
		self._cancel_held_ability = false
		self._activate_ability = false
		self._activate_ability_held = false
		input.action_two = true
	end

	if self._activate_ability then
		self._activate_ability = false

		if not self._activate_ability_held then
			self._activate_ability_held = true
			input.action_career = true
		end

		--mod:echo("start")
		input.action_career_hold = true
	elseif self._activate_ability_held then
		self._activate_ability_held = false
		input.action_career_release = true
		--mod:echo("release")
	end

	if self._weapon_reload then
		self._weapon_reload = false
		input.weapon_reload = true
		input.weapon_reload_hold = true
	end

	if self._hold_attack then
		input.action_one = true
		input.action_one_hold = true
		self._hold_attack = false
		self._attack_held = true
	elseif self._attack_held then
		self._attack_held = false
		input.action_one_release = true
	elseif not self._tap_attack_released then
		self._tap_attack_released = true
		input.action_one_release = true
	elseif self._tap_attack then
		self._tap_attack_released = false
		self._tap_attack = false
		input.action_one = true
	end

	if self._charge_shot then
		self._charge_shot = false
		input.action_two_hold = true

		if not self._charge_shot_held then
			input.action_two = true
			self._charge_shot_held = true
		end
	elseif self._charge_shot_held then
		self._charge_shot_held = false
		input.action_two_release = true
	end

	if self._interact then
		self._interact = false

		if not self._interact_held then
			self._interact_held = true
			input.interact = true
		end

		input.interacting = true
	elseif self._interact_held then
		self._interact_held = false
	end

	local slot_to_wield = self._slot_to_wield

	if slot_to_wield then
		self._slot_to_wield = nil
		local slots = InventorySettings.slots
		local num_slots = #slots
		local wield_input = nil

		for i = 1, num_slots, 1 do
			local slot_data = slots[i]

			if slot_data.name == slot_to_wield then
				wield_input = slot_data.wield_input
			end
		end

		input[wield_input] = true
	end

	if self._dodge then
		input.dodge = true
		input.dodge_hold = true
		self._dodge = false
	end--]]
end)
