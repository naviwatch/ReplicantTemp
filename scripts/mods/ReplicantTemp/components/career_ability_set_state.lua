local mod = get_mod("ReplicantTemp")

--_career_ability_we_shade
--[[
mod:hook_origin(CareerAbilityWEShade, "_run_ability", function (self)
	local owner_unit = self._owner_unit
	local local_player = self._local_player
	local bot_player = self._bot_player
	local is_server = self._is_server
	local network_manager = self._network_manager
	local network_transmit = network_manager.network_transmit
	local buff_extension = self._buff_extension
	local career_extension = self._career_extension
	local status_extension = self._status_extension
	local talent_extension = ScriptUnit.extension(self._owner_unit, "talent_system")
	local has_phasing = talent_extension:has_talent("kerillian_shade_activated_ability_phasing")

	if has_phasing then
		local buffs_to_add = {
			"kerillian_shade_activated_ability_phasing"
		}

		for i = 1, #buffs_to_add, 1 do
			local buff_to_add = buffs_to_add[i]

			self._buff_system:add_buff(owner_unit, buff_to_add, owner_unit, false)
		end
	else
		local buff_name = "kerillian_shade_activated_ability"
		local buff_template_name_id = NetworkLookup.buff_templates[buff_name]
		local unit_object_id = network_manager:unit_game_object_id(owner_unit)

		if is_server then
			buff_extension:add_buff(buff_name, {
				attacker_unit = owner_unit
			})
			network_transmit:send_rpc_clients("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, false)
		else
			network_transmit:send_rpc_server("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, true)
		end
	end

	if not bot_player then
		local first_person_extension = self._first_person_extension

		first_person_extension:play_hud_sound_event("Play_career_ability_kerillian_shade_enter")

		if status_extension:current_stealth_counter() == 1 then
			first_person_extension:play_hud_sound_event("Play_career_ability_kerillian_shade_loop")
		end

		first_person_extension:animation_event("shade_stealth_ability")

		MOOD_BLACKBOARD.skill_shade = true
	end
	
	if not bot_player or (is_server and bot_player) then
		career_extension:set_state("kerillian_activate_shade")
	end

	if local_player or (is_server and bot_player) then
		local events = {
			"Play_career_ability_kerillian_shade_enter",
			"Play_career_ability_kerillian_shade_loop_husk"
		}
		local unit_id = network_manager:unit_game_object_id(owner_unit)
		local node_id = 0

		for _, event in ipairs(events) do
			local event_id = NetworkLookup.sound_events[event]

			if is_server then
				network_transmit:send_rpc_clients("rpc_play_husk_unit_sound_event", unit_id, node_id, event_id)
			else
				network_transmit:send_rpc_server("rpc_play_husk_unit_sound_event", unit_id, node_id, event_id)
			end
		end
	end

	if Managers.state.network:game() then
		status_extension:set_is_dodging(true)

		local unit_id = network_manager:unit_game_object_id(owner_unit)

		network_transmit:send_rpc_server("rpc_status_change_bool", NetworkLookup.statuses.dodging, true, unit_id, 0)
	end

	career_extension:start_activated_ability_cooldown()
	self:_play_vo()
end)

local function is_local(unit)
	local player = Managers.player:owner(unit)

	return player and not player.remote
end

local function is_bot(unit)
	local player = Managers.player:owner(unit)

	return player and player.bot_player
end

mod:hook_origin(BuffFunctionTemplates.functions, "shade_activated_ability_on_remove", function (unit, buff, params, world)
	local status_extension = nil

	if is_local(unit) then
		status_extension = ScriptUnit.extension(unit, "status_system")

		status_extension:remove_stealth_stacking()
		status_extension:remove_noclip_stacking()
	end

	local talent_extension = ScriptUnit.has_extension(unit, "talent_system")
	local buff_extension = ScriptUnit.has_extension(unit, "buff_system")

	if not talent_extension or not buff_extension then
		return
	end
	
	local did_restealth = false
	
	if talent_extension:has_talent("kerillian_shade_activated_stealth_combo") then
		buff_extension:add_buff("kerillian_shade_ult_invis_combo_blocker")
		buff_extension:add_buff("kerillian_shade_ult_invis")
		
		did_restealth = true
	end
	
	if talent_extension:has_talent("kerillian_shade_activated_ability_restealth") and buff.template.restealth then
		buff_extension:add_buff("kerillian_shade_activated_ability_restealth")
		
		did_restealth = true
	end
	
	if talent_extension:has_talent("kerillian_shade_activated_ability_phasing") then
		buff_extension:add_buff("kerillian_shade_phasing_buff")
		buff_extension:add_buff("kerillian_shade_movespeed_buff")
		buff_extension:add_buff("kerillian_shade_power_buff")
	end
	
	if is_local(unit) then
		if not is_bot(unit) and status_extension:current_stealth_counter() == 0 then
			local first_person_extension = ScriptUnit.extension(unit, "first_person_system")

			first_person_extension:play_hud_sound_event("Play_career_ability_kerillian_shade_exit")
			first_person_extension:play_hud_sound_event("Stop_career_ability_kerillian_shade_loop")

			MOOD_BLACKBOARD.skill_shade = false
		end
		
		if not is_bot(unit) or not did_restealth then
			local career_extension = ScriptUnit.extension(unit, "career_system")
			
			career_extension:set_state("default")
		end
		
		if Managers.state.network:game() then
			local status_extension = ScriptUnit.extension(unit, "status_system")

			status_extension:set_is_dodging(false)
		end
		
		local events = {
			"Play_career_ability_kerillian_shade_exit",
			"Stop_career_ability_kerillian_shade_loop_husk"
		}
		local network_manager = Managers.state.network
		local network_transmit = network_manager.network_transmit
		local is_server = Managers.player.is_server
		local unit_id = network_manager:unit_game_object_id(unit)
		local node_id = 0
		
		for i = 1, #events, 1 do
			local event = events[i]
			local event_id = NetworkLookup.sound_events[event]

			if is_server then
				network_transmit:send_rpc_clients("rpc_play_husk_unit_sound_event", unit_id, node_id, event_id)
			else
				network_transmit:send_rpc_server("rpc_play_husk_unit_sound_event", unit_id, node_id, event_id)
			end
		end
	end
end)
--]]

mod:hook_origin(CareerAbilityWEShade, "_run_ability", function (self)
	local owner_unit = self._owner_unit
	local bot_player = self._bot_player
	local network_manager = self._network_manager
	local network_transmit = network_manager.network_transmit
	local buff_extension = self._buff_extension
	local career_extension = self._career_extension
	local status_extension = self._status_extension
	local was_invisible = status_extension:is_invisible()
	local buff_name = "kerillian_shade_activated_ability"
	local talent_extension = ScriptUnit.extension(self._owner_unit, "talent_system")
	local has_phasing = talent_extension:has_talent("kerillian_shade_activated_ability_phasing")

	if has_phasing then
		buff_name = "kerillian_shade_activated_ability_phasing"
	end

	buff_extension:add_buff(buff_name)

	local first_person_extension = self._first_person_extension

	first_person_extension:play_hud_sound_event("Play_career_ability_kerillian_shade_enter", nil, true)
	first_person_extension:play_remote_hud_sound_event("Play_career_ability_kerillian_shade_loop_husk")

	if not bot_player then
		if not was_invisible then
			first_person_extension:play_hud_sound_event("Play_career_ability_kerillian_shade_loop")
		end

		first_person_extension:animation_event("shade_stealth_ability")
		career_extension:set_state("kerillian_activate_shade")
	end

	--edit start--
	if not bot_player or (self._is_server and bot_player) then
		career_extension:set_state("kerillian_activate_shade")
	end
	--edit end--

	if Managers.state.network:game() then
		status_extension:set_is_dodging(true)

		local unit_id = network_manager:unit_game_object_id(owner_unit)

		network_transmit:send_rpc_server("rpc_status_change_bool", NetworkLookup.statuses.dodging, true, unit_id, 0)
	end

	career_extension:start_activated_ability_cooldown()
	self:_play_vo()
end)

local function is_local(unit)
	local player = Managers.player:owner(unit)

	return player and not player.remote
end

local function is_bot(unit)
	local player = Managers.player:owner(unit)

	return player and player.bot_player
end

mod:hook_origin(BuffFunctionTemplates.functions, "on_shade_activated_ability_remove", function (unit, buff, params, world)
	if not ALIVE[unit] then
		return
	end

	if not is_local(unit) then
		return
	end

	local buff_template = buff.template
	local status_extension = ScriptUnit.extension(unit, "status_system")

	status_extension:set_invisible(false, nil, buff)
	status_extension:set_noclip(false, buff)

	local talent_extension = ScriptUnit.has_extension(unit, "talent_system")
	local buff_extension = ScriptUnit.has_extension(unit, "buff_system")

	if not talent_extension or not buff_extension then
		return
	end

	local first_person_extension = ScriptUnit.extension(unit, "first_person_system")

	first_person_extension:play_hud_sound_event("Stop_career_ability_kerillian_shade_loop")
	first_person_extension:play_hud_sound_event("Play_career_ability_kerillian_shade_exit", nil, true)
	first_person_extension:play_remote_hud_sound_event("Stop_career_ability_kerillian_shade_loop_husk")

	if not is_bot(unit) then
	--	MOOD_BLACKBOARD[stealth_identifier] = false
		Managers.state.camera:set_mood("skill_shade", buff, false)
	end

	--edit start--
	-- local career_extension = ScriptUnit.extension(unit, "career_system")

	-- career_extension:set_state("default")
	local did_restealth = (buff_template.can_restealth_combo and talent_extension:has_talent("kerillian_shade_activated_stealth_combo")) or (buff_template.can_restealth_on_remove and talent_extension:has_talent("kerillian_shade_activated_ability_restealth"))
	
	if not is_bot(unit) or not did_restealth then
		local career_extension = ScriptUnit.extension(unit, "career_system")
		
		career_extension:set_state("default")
	end
	--edit end--

	status_extension:set_is_dodging(false)

	if buff_template.can_restealth_combo and talent_extension:has_talent("kerillian_shade_activated_stealth_combo") then
		buff_extension:add_buff("kerillian_shade_ult_invis_combo_blocker")
		buff_extension:add_buff("kerillian_shade_ult_invis")
	end

	if buff_template.can_restealth_on_remove and talent_extension:has_talent("kerillian_shade_activated_ability_restealth") then
		buff_extension:add_buff("kerillian_shade_activated_ability_restealth")

		local restealth_buffs = buff_extension:get_stacking_buff("kerillian_shade_activated_ability_restealth")
		local restealth_buff = restealth_buffs[1]
		local inventory_extension = ScriptUnit.extension(unit, "inventory_system")
		local weapon_unit = inventory_extension:get_weapon_unit()
		local weapon_unit_extension = ScriptUnit.extension(weapon_unit, "weapon_system")

		if weapon_unit_extension:has_current_action() then
			local current_action = weapon_unit_extension:get_current_action()
			local action_start_t = current_action.action_start_t
			restealth_buff.triggering_action_start_t = action_start_t
		end
	end

	if talent_extension:has_talent("kerillian_shade_activated_ability_phasing") then
		buff_extension:add_buff("kerillian_shade_phasing_buff")
		buff_extension:add_buff("kerillian_shade_movespeed_buff")
		buff_extension:add_buff("kerillian_shade_power_buff")
	end
end)

--_career_ability_wh_zealot

mod:hook_origin(CareerAbilityWHZealot, "_run_ability", function (self)
	self:_stop_priming()

	local owner_unit = self._owner_unit
	local is_server = self._is_server
	local local_player = self._local_player
	local network_manager = self._network_manager
	local network_transmit = network_manager.network_transmit
	local status_extension = self._status_extension
	local career_extension = self._career_extension
	local buff_extension = self._buff_extension
	local buff_names = {
		"victor_zealot_activated_ability"
	}
	local talent_extension = ScriptUnit.extension(owner_unit, "talent_system")

	if talent_extension:has_talent("victor_zealot_activated_ability_power_on_hit", "witch_hunter", true) then
		buff_names[#buff_names + 1] = "victor_zealot_activated_ability_power_on_hit"
	end

	if talent_extension:has_talent("victor_zealot_activated_ability_ignore_death", "witch_hunter", true) then
		buff_names[#buff_names + 1] = "victor_zealot_activated_ability_ignore_death"
	end

	if talent_extension:has_talent("victor_zealot_activated_ability_cooldown_stack_on_hit", "witch_hunter", true) then
		buff_extension:add_buff("victor_zealot_activated_ability_cooldown_stack_on_hit", {
			attacker_unit = owner_unit
		})
	end

	-- for i = 1, #buff_names, 1 do
	for i = 1, #buff_names do
		local buff_name = buff_names[i]
		local unit_object_id = network_manager:unit_game_object_id(owner_unit)
		local buff_template_name_id = NetworkLookup.buff_templates[buff_name]

		if is_server then
			buff_extension:add_buff(buff_name, {
				attacker_unit = owner_unit
			})
			network_transmit:send_rpc_clients("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, false)
		else
			network_transmit:send_rpc_server("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, true)
		end
	end

	if local_player or (is_server and self._bot_player) then
		local first_person_extension = self._first_person_extension

		first_person_extension:play_hud_sound_event("Play_career_ability_victor_zealot_enter")
		first_person_extension:play_remote_unit_sound_event("Play_career_ability_victor_zealot_enter", owner_unit, 0)
		first_person_extension:play_hud_sound_event("Play_career_ability_victor_zealot_loop")

		if local_player then
			first_person_extension:animation_event("shade_stealth_ability")
			first_person_extension:play_hud_sound_event("Play_career_ability_zealot_charge")
			first_person_extension:play_remote_unit_sound_event("Play_career_ability_zealot_charge", owner_unit, 0)
			
		--	MOOD_BLACKBOARD.skill_zealot = true
			Managers.state.camera:set_mood("skill_zealot", "skill_zealot", true)
		end
		
		career_extension:set_state("victor_activate_zealot")
	end

	-- status_extension:add_noclip_stacking()
	status_extension:set_noclip(true, "skill_zealot")

	status_extension.do_lunge = {
		animation_end_event = "zealot_active_ability_charge_hit",
		allow_rotation = false,
		first_person_animation_end_event = "dodge_bwd",
		first_person_hit_animation_event = "charge_react",
		falloff_to_speed = 8,
		dodge = true,
		first_person_animation_event = "shade_stealth_ability",
		first_person_animation_end_event_hit = "dodge_bwd",
		duration = 0.75,
		initial_speed = 25,
		animation_event = "zealot_active_ability_charge_start",
		damage = {
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
	}

	career_extension:start_activated_ability_cooldown()
	self:_play_vo()
end)

--_career_ability_dr_slayer

mod:hook_origin(CareerAbilityDRSlayer, "_do_common_stuff", function (self)
	local owner_unit = self._owner_unit
	local is_server = self._is_server
	local local_player = self._local_player
	local bot_player = self._bot_player
	local network_manager = self._network_manager
	local network_transmit = network_manager.network_transmit
	local career_extension = self._career_extension
	local talent_extension = self._talent_extension
	local buffs = {
		"bardin_slayer_activated_ability"
	}

	if talent_extension:has_talent("bardin_slayer_activated_ability_movement") then
		buffs[#buffs + 1] = "bardin_slayer_activated_ability_movement"
	end

	local unit_object_id = network_manager:unit_game_object_id(owner_unit)

	if is_server then
		local buff_extension = self._buff_extension

		-- for i = 1, #buffs, 1 do
		for i = 1, #buffs do
			local buff_name = buffs[i]
			local buff_template_name_id = NetworkLookup.buff_templates[buff_name]

			buff_extension:add_buff(buff_name, {
				attacker_unit = owner_unit
			})
			network_transmit:send_rpc_clients("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, false)
		end
	else
		-- for i = 1, #buffs, 1 do
		for i = 1, #buffs do
			local buff_name = buffs[i]
			local buff_template_name_id = NetworkLookup.buff_templates[buff_name]

			network_transmit:send_rpc_server("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, true)
		end
	end

	if (is_server and bot_player) or local_player then
		local first_person_extension = self._first_person_extension

		first_person_extension:play_hud_sound_event("Play_career_ability_bardin_slayer_enter")
		first_person_extension:play_remote_unit_sound_event("Play_career_ability_bardin_slayer_enter", owner_unit, 0)
		first_person_extension:play_hud_sound_event("Play_career_ability_bardin_slayer_loop")

		if local_player then
		--	MOOD_BLACKBOARD.skill_slayer = true
			Managers.state.camera:set_mood("skill_slayer", "skill_slayer", true)
		end
		
		career_extension:set_state("bardin_activate_slayer")
	end

	career_extension:start_activated_ability_cooldown()
	self:_play_vo()
end)

--_career_ability_es_huntsman

mod:hook_origin(CareerAbilityESHuntsman, "_run_ability", function (self, skip_cooldown)
	local owner_unit = self.owner_unit
	local is_server = self.is_server
	local local_player = self.local_player
	local bot_player = self.bot_player
	local network_manager = self.network_manager
	local network_transmit = network_manager.network_transmit
	local inventory_extension = self._inventory_extension
	local buff_extension = self._buff_extension
	local career_extension = self._career_extension
	local talent_extension = ScriptUnit.extension(owner_unit, "talent_system")
	local server_buff_names = {
		"markus_huntsman_activated_ability",
		"markus_huntsman_activated_ability_headshot_multiplier"
	}
	local local_buff_names = {}

	if talent_extension:has_talent("markus_huntsman_activated_ability_improved_stealth") then
		local_buff_names = {
			"markus_huntsman_activated_ability_increased_zoom",
			"markus_huntsman_activated_ability_increased_reload_speed",
			"markus_huntsman_activated_ability_decrease_move_speed",
			"markus_huntsman_activated_ability_decrease_crouch_move_speed",
			"markus_huntsman_activated_ability_decrease_walk_move_speed",
			"markus_huntsman_activated_ability_decrease_dodge_speed",
			"markus_huntsman_activated_ability_decrease_dodge_distance"
		}
	elseif talent_extension:has_talent("markus_huntsman_activated_ability_duration") then
		local_buff_names = {
			"markus_huntsman_activated_ability_increased_zoom_duration",
			"markus_huntsman_activated_ability_increased_reload_speed_duration",
			"markus_huntsman_activated_ability_decrease_move_speed_duration",
			"markus_huntsman_activated_ability_decrease_crouch_move_speed_duration",
			"markus_huntsman_activated_ability_decrease_walk_move_speed_duration",
			"markus_huntsman_activated_ability_decrease_dodge_speed_duration",
			"markus_huntsman_activated_ability_decrease_dodge_distance_duration",
			-- "markus_huntsman_end_activated_on_ranged_hit_duration",
			-- "markus_huntsman_end_activated_on_melee_hit_duration"
			"markus_huntsman_end_activated_on_hit_duration"
		}
		server_buff_names = {
			"markus_huntsman_activated_ability_duration",
			"markus_huntsman_activated_ability_headshot_multiplier_duration"
		}
	else
		local_buff_names = {
			"markus_huntsman_activated_ability_increased_zoom",
			"markus_huntsman_activated_ability_increased_reload_speed",
			"markus_huntsman_activated_ability_decrease_move_speed",
			"markus_huntsman_activated_ability_decrease_crouch_move_speed",
			"markus_huntsman_activated_ability_decrease_walk_move_speed",
			"markus_huntsman_activated_ability_decrease_dodge_speed",
			"markus_huntsman_activated_ability_decrease_dodge_distance",
			-- "markus_huntsman_end_activated_on_ranged_hit",
			-- "markus_huntsman_end_activated_on_melee_hit"
			"markus_huntsman_end_activated_on_hit"
		}
		server_buff_names = {
			"markus_huntsman_activated_ability",
			"markus_huntsman_activated_ability_headshot_multiplier"
		}
	end

	local unit_object_id = network_manager:unit_game_object_id(owner_unit)

	for _, buff_name in ipairs(server_buff_names) do
		local buff_template_name_id = NetworkLookup.buff_templates[buff_name]

		if is_server then
			buff_extension:add_buff(buff_name, {
				attacker_unit = owner_unit
			})
			network_transmit:send_rpc_clients("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, false)
		else
			network_transmit:send_rpc_server("rpc_add_buff", unit_object_id, buff_template_name_id, unit_object_id, 0, true)
		end
	end

	for _, buff_name in ipairs(local_buff_names) do
		buff_extension:add_buff(buff_name, {
			attacker_unit = owner_unit
		})
	end

	if talent_extension:has_talent("markus_huntsman_activated_ability_cooldown_2") then
		local reference_buff = buff_extension:get_non_stacking_buff("markus_huntsman_passive")
		local max_stacks = reference_buff.template.max_sub_buff_stacks

		if not reference_buff.buff_list then
			reference_buff.buff_list = {}
		end

		-- for i = 1, max_stacks, 1 do
		for i = 1, max_stacks do
			if max_stacks > #reference_buff.buff_list then
				table.insert(reference_buff.buff_list, buff_extension:add_buff("markus_huntsman_auto_headshot"))
			end
		end
	end

	local weapon_slot = "slot_ranged"
	local slot_data = inventory_extension:get_slot_data(weapon_slot)
	local right_unit_1p = slot_data.right_unit_1p
	local left_unit_1p = slot_data.left_unit_1p
	local right_hand_ammo_extension = ScriptUnit.has_extension(right_unit_1p, "ammo_system")
	local left_hand_ammo_extension = ScriptUnit.has_extension(left_unit_1p, "ammo_system")
	local ammo_extension = right_hand_ammo_extension or left_hand_ammo_extension

	if ammo_extension then
		local clip_size = ammo_extension:clip_size()
		local ammo_count = ammo_extension:ammo_count()
		local reserve_ammo = ammo_extension:remaining_ammo()
		local clip_empty = ammo_count == 0
		local clip_full = ammo_count == clip_size
		local instant_ammo = 0

		if clip_empty then
			instant_ammo = clip_size
		elseif clip_full then
			if reserve_ammo == 0 then
				instant_ammo = clip_size
			elseif reserve_ammo < clip_size then
				instant_ammo = clip_size - reserve_ammo
			end
		elseif reserve_ammo == 0 then
			instant_ammo = clip_size - ammo_count + clip_size
		elseif reserve_ammo < clip_size then
			instant_ammo = clip_size - ammo_count + clip_size - reserve_ammo
		else
			instant_ammo = clip_size - ammo_count
		end

		ammo_extension:add_ammo_to_reserve(instant_ammo)

		if ammo_extension:can_reload() then
			if clip_empty then
				ammo_extension:start_reload(true)
			else
				ammo_extension:instant_reload(false, "reload")
			end
		end
	end

	local first_person_extension = self._first_person_extension

	if local_player then
		first_person_extension:play_hud_sound_event("Play_career_ability_markus_huntsman_enter", nil, true)
		first_person_extension:play_hud_sound_event("Play_career_ability_markus_huntsman_loop")
		first_person_extension:animation_event("shade_stealth_ability")

		Managers.state.camera:set_mood("skill_huntsman_surge", "skill_huntsman_surge", false)
		Managers.state.camera:set_mood("skill_huntsman_stealth", "skill_huntsman_stealth", true)
	end
	
	if local_player or (is_server and bot_player) then
		local status_extension = self._status_extension

		-- status_extension:set_invisible(true)
		status_extension:set_invisible(true, nil, "huntsman_ability")
		first_person_extension:play_remote_hud_sound_event("Play_career_ability_markus_huntsman_loop_husk")
		
		career_extension:set_state("markus_activate_huntsman")
	end

	if not skip_cooldown then
		career_extension:start_activated_ability_cooldown()
	end

	self:_play_vo()
end)



