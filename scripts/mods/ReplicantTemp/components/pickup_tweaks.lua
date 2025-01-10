local mod = get_mod("ReplicantTemp")

mod:hook(AIBotGroupSystem, "_order_pickup", function (func, self, bot_unit, pickup_unit, ordering_player)
	if not mod.components.pickup_tweaks.value then
		return func(self, bot_unit, pickup_unit, ordering_player)
	end
	
	if self._is_server then
		local pickup_ext = ScriptUnit.extension(pickup_unit, "pickup_system")
		local settings = pickup_ext:get_pickup_settings()
		local slot_name = settings.slot_name

		if settings.type == "ammo" then
			self:_order_ammo_pickup(bot_unit, pickup_unit, ordering_player)
		elseif slot_name then
			local bot_data = self._bot_ai_data_lookup[bot_unit]

			if bot_data then
				local inventory_extension = ScriptUnit.extension(bot_unit, "inventory_system")
				local slot_data = inventory_extension:get_slot_data(slot_name)
				local can_hold_more = inventory_extension:can_store_additional_item(slot_name)

				if slot_data and not can_hold_more then
					local current_item_template = inventory_extension:get_item_template(slot_data)
					local has_similar_item_already = (pickup_ext.pickup_name ~= "grimoire" and current_item_template.pickup_data and current_item_template.pickup_data.pickup_name == pickup_ext.pickup_name) or (pickup_ext.pickup_name == "grimoire" and current_item_template.is_grimoire)
					local has_grimoire = current_item_template.is_grimoire
					
					if has_similar_item_already then
						self:_chat_message(bot_unit, ordering_player, "already_have_item", Unit.get_data(pickup_unit, "interaction_data", "hud_description"))
						return
					elseif has_grimoire then
						Managers.chat:send_chat_message(1, Managers.player:owner(bot_unit):local_player_id(), mod:localize("sry_have_the_grim"))
						return
					end
				end

				local side = bot_data.side
				local side_id = side.side_id
				local side_bot_data = self._bot_ai_data[side_id]

				for unit, data in pairs(side_bot_data) do
					local order = data.pickup_orders[slot_name]

					if order and order.unit == pickup_unit then
						if unit == bot_unit then
							self:_chat_message(bot_unit, ordering_player, "already_picking_up")

							return
						end

						self:_chat_message(unit, ordering_player, "abort_pickup_assigned_to_other")

						data.pickup_orders[slot_name] = nil
						data.blackboard.needs_target_position_refresh = true
					end
				end

				self:_chat_message(bot_unit, ordering_player, "acknowledge_pickup", Unit.get_data(pickup_unit, "interaction_data", "hud_description"))

				bot_data.pickup_orders[slot_name] = {
					unit = pickup_unit,
					pickup_name = pickup_ext.pickup_name
				}
				bot_data.blackboard.needs_target_position_refresh = true
			else
				local party_manager = Managers.party
				local party = party_manager:get_party_from_player_id(ordering_player:network_id(), ordering_player:local_player_id())
				local side_manager = Managers.state.side
				local side = side_manager.side_by_party[party]
				local side_id = side.side_id
				local side_bot_data = self._bot_ai_data[side_id]

				for unit, data in pairs(side_bot_data) do
					local order = data.pickup_orders[slot_name]

					if order and order.unit == pickup_unit then
						self:_chat_message(unit, ordering_player, "abort_pickup_assigned_to_other")

						data.pickup_orders[slot_name] = nil
						data.blackboard.needs_target_position_refresh = true
					end
				end
			end
		end
	end
end)

local grimoire_drops = {}
local WAIT_BEFORE_DROP_GRIM_TIME = 3
local find_in_array = mod.utility.find_in_array

mod:hook(AIBotGroupSystem, "_order_drop", function (func, self, bot_unit, pickup_name, ordering_player)
	if not mod.components.pickup_tweaks.value then
		return func(self, bot_unit, pickup_name, ordering_player)
	end
	
	if self._is_server then
		local bot_data = self._bot_ai_data_lookup[bot_unit]

		if bot_data then
			local pickup_settings = AllPickups[pickup_name]
			local slot_name = pickup_settings.slot_name
			local order = bot_data.pickup_orders[slot_name]
			
			if pickup_name == "grimoire" then
				local current_time = Managers.time:time("game")
				local drop_index = find_in_array(grimoire_drops, bot_unit, "unit")
				if drop_index then
					grimoire_drops[drop_index].time = current_time
				else
					table.insert(grimoire_drops, { unit = bot_unit, time = current_time })
				end
			end

			if order and order.pickup_name == pickup_name then
				bot_data.pickup_orders[slot_name] = nil

				self:_chat_message(bot_unit, ordering_player, "acknowledge_drop")
			end
		end
	end
end)

mod:hook(BTConditions, "should_drop_grimoire", function (func, blackboard)
	if not mod.components.pickup_tweaks.value then
		return func(blackboard)
	end
	
	local inventory_extension = blackboard.inventory_extension
	local slot_name = "slot_potion"
	local slot_data = inventory_extension:get_slot_data(slot_name)

	if slot_data then
		local item_template = inventory_extension:get_item_template(slot_data)
		local is_grimoire = item_template.is_grimoire
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		local order = ai_bot_group_system:get_pickup_order(blackboard.unit, slot_name)
		
		return is_grimoire and ((order == nil and Managers.time:time("game") >= grimoire_drops[find_in_array(grimoire_drops, blackboard.unit, "unit")].time + WAIT_BEFORE_DROP_GRIM_TIME) or (order ~= nil and order.pickup_name ~= "grimoire"))
	end

	return false
end)

mod:hook(ContextAwarePingExtension, "social_message_attempt", function (func, self, unit, social_wheel_event_id, target_unit)
	if not mod.components.pickup_tweaks.value then
		return func(self, unit, social_wheel_event_id, target_unit)
	end
	
	if not self:_have_free_events() then
		local error_message = Localize("social_wheel_too_many_messages_warning")

		Managers.chat:add_local_system_message(1, error_message, true)

		return false
	end

	if LEVEL_EDITOR_TEST then
		return false
	end
	
	local social_wheel_event_name = social_wheel_event_id and NetworkLookup.social_wheel_events[social_wheel_event_id] or nil
	
	if social_wheel_event_name == "social_wheel_general_no" and #grimoire_drops > 0 then
		local current_time = Managers.time:time("game")
		for k = #grimoire_drops, 1, -1 do
			local last_drop = grimoire_drops[#grimoire_drops]
			local drop_order_time = last_drop.time
			
			if current_time < drop_order_time + WAIT_BEFORE_DROP_GRIM_TIME then
				local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
				local bot_unit = last_drop.unit
				local bot_data = ai_bot_group_system._bot_ai_data_lookup[bot_unit]

				bot_data.pickup_orders["slot_potion"] = {
					pickup_name = "grimoire"
				}
				
				table.remove(grimoire_drops)
				
				break
			else
				grimoire_drops = {}
				break
			end
		end
	end

	social_wheel_event_id = social_wheel_event_id or NetworkLookup.social_wheel_events["n/a"]
	
	local network_manager = Managers.state.network
	local pinger_unit_id = network_manager:unit_game_object_id(unit)
	local pinged_unit_id = (target_unit and Unit.alive(target_unit) and network_manager:unit_game_object_id(target_unit)) or 0

	network_manager.network_transmit:send_rpc_server("rpc_social_message", pinger_unit_id, social_wheel_event_id, pinged_unit_id)
	self:_consume_ping_event()

	return true
end)

local PICKUP_CHECK_RANGE = 10	--15
local PICKUP_FETCH_RESULTS = {}
mod:hook(AIBotGroupSystem, "_update_pickups_near_player", function (func, self, player_unit, t)
	if not mod.components.pickup_tweaks.value then
		return func(self, player_unit, t)
	end
	
	local side = Managers.state.side.side_by_unit[player_unit]
	local side_id = side.side_id
	local side_bot_data = self._bot_ai_data[side_id]
	local self_pos = POSITION_LOOKUP[player_unit]
	local hp_pickups = self._available_health_pickups[side_id]
	local mule_pickups = self._available_mule_pickups[side_id]

	for unit, data in pairs(side_bot_data) do
		local blackboard = data.blackboard
		local ammo_pickup = blackboard.ammo_pickup

		if Unit.alive(ammo_pickup) then
			local ammo_distance = Vector3.distance(POSITION_LOOKUP[unit], POSITION_LOOKUP[ammo_pickup])
			blackboard.ammo_dist = ammo_distance
			data.ammo_dist = ammo_distance
		elseif blackboard.ammo_pickup then
			blackboard.ammo_pickup = nil
			blackboard.ammo_dist = nil
			data.ammo_dist = nil

			if data.ammo_pickup_order_unit then
				data.ammo_pickup_order_unit = nil
			end
		end
	end

	local check_player_ammo = true
	local all_players_are_ok = true
	local check_players_and_bots_health = true
	local all_players_have_ammo = true
	local valid_until = t + 5	--3?
	local ammo_stickiness = 2.5
	local allowed_distance_to_self = 5
	-- local allowed_distance_to_follow_pos = 15
	local allowed_distance_to_follow_pos = 7	--15
	local game_mode_key = Managers.state.game_mode:game_mode_key()
	local pickup_system = Managers.state.entity:system("pickup_system")
	local num_pickups = pickup_system:get_pickups(self_pos, PICKUP_CHECK_RANGE, PICKUP_FETCH_RESULTS)

	for i = 1, num_pickups, 1 do
		local pickup_unit = PICKUP_FETCH_RESULTS[i]
		local pickup_extension = ScriptUnit.has_extension(pickup_unit, "pickup_system")
		local aware_extension = ScriptUnit.has_extension(pickup_unit, "surrounding_aware_system")

		if pickup_extension and (not aware_extension or aware_extension.has_been_seen or ScriptUnit.extension(pickup_unit, "ping_system"):pinged()) then
			local pickup_name = pickup_extension.pickup_name
			local pickup_data = AllPickups[pickup_name]

			if pickup_name == "healing_draught" or pickup_name == "first_aid_kit" then
				if check_players_and_bots_health and pickup_name == "healing_draught" then
					local PLAYER_AND_BOT_UNITS = side.PLAYER_AND_BOT_UNITS
					local num_human_players = #PLAYER_AND_BOT_UNITS

					for i = 1, num_human_players, 1 do
						local player_unit = PLAYER_AND_BOT_UNITS[i]

						if Unit.alive(player_unit) then
							local inventory_extension = ScriptUnit.extension(player_unit, "inventory_system")
							local slot_data = inventory_extension:get_slot_data("slot_healthkit")
							
							if slot_data then
								local current_item_template = inventory_extension:get_item_template(slot_data)
								local has_tome = current_item_template.pickup_data and current_item_template.pickup_data.pickup_name == "tome" or false
								
								local health_extension = ScriptUnit.extension(player_unit, "health_system")
								local status_extension = ScriptUnit.extension(player_unit, "status_system")
								local buff_extension = ScriptUnit.extension(player_unit, "buff_system")
								local career_extension = ScriptUnit.extension(player_unit, "career_system")
								local health_percent = health_extension:current_health_percent()
								local is_wounded = status_extension:is_knocked_down() or status_extension:is_wounded()
								local has_natural_bond = buff_extension:has_buff_type("trait_necklace_no_healing_health_regen")
								local is_zealot = career_extension:career_name() == "wh_zealot"

								if has_tome and (is_wounded or ((not is_zealot and not has_natural_bond) and health_percent <= 0.25)) then
									all_players_are_ok = false
									
									break
								end
							end
						end
					end

					check_players_and_bots_health = false
				end
				
				if all_players_are_ok then
					local template = BackendUtils.get_item_template(ItemMasterList[pickup_data.item_name])

					if not hp_pickups[pickup_unit] then
						hp_pickups[pickup_unit] = {
							template = template,
							valid_until = valid_until
						}
					else
						hp_pickups[pickup_unit].valid_until = valid_until
						hp_pickups[pickup_unit].template = template
					end
				end
			elseif pickup_data.bots_mule_pickup then
				local slot_name = pickup_data.slot_name
				mule_pickups[slot_name][pickup_unit] = valid_until
			elseif pickup_data.type == "ammo" then
				local lowest_bot_ammo = {
					bot_unit = nil,
					ammo_percentage = 10
				}
				
				if check_player_ammo then
					local PLAYER_AND_BOT_UNITS = side.PLAYER_AND_BOT_UNITS
					local num_players = #PLAYER_AND_BOT_UNITS

					for i = 1, num_players, 1 do
						local player_unit = PLAYER_AND_BOT_UNITS[i]
						local player = Managers.player:owner(player_unit)
						local is_bot = not player:is_player_controlled()
						
						if Unit.alive(player_unit) then
							local inventory_ext = ScriptUnit.extension(player_unit, "inventory_system")
							local ammo_percentage = inventory_ext:ammo_percentage() or 10
							
							if not is_bot and ammo_percentage < 0.9 then
								all_players_have_ammo = false
							elseif is_bot then
								if ammo_percentage < lowest_bot_ammo.ammo_percentage then
									lowest_bot_ammo.bot_unit = player_unit
									lowest_bot_ammo.ammo_percentage = ammo_percentage
								end
							end
						end
					end

					check_player_ammo = false
				end

				for unit, data in pairs(side_bot_data) do
					local bb = data.blackboard
					local ammo_pickup_order_unit = data.ammo_pickup_order_unit

					if not ammo_pickup_order_unit or bb.ammo_pickup_valid_until <= t then
						local current_pickup = bb.ammo_pickup
						local pickup_pos = POSITION_LOOKUP[pickup_unit]
						local dist = Vector3.distance(POSITION_LOOKUP[unit], pickup_pos)
						local follow_pos = data.follow_position
						local inventory_extension = bb.inventory_extension
						local equipped_ammo_kind = inventory_extension:current_ammo_kind("slot_ranged")
						local pickup_ammo_kind = pickup_data.ammo_kind or "default"
						local same_kind = equipped_ammo_kind == pickup_ammo_kind
						local allowed_to_take_ammo = nil

						if game_mode_key == "survival" then
							if pickup_data.only_once then
								local current_ammo, _ = inventory_extension:current_ammo_status("slot_ranged")
								allowed_to_take_ammo = current_ammo and current_ammo == 0
							else
								allowed_to_take_ammo = true
							end
						else
							local self_unit = bb.unit
							allowed_to_take_ammo = (pickup_ammo_kind == "thrown" and true) or (bb.has_ammo_missing and (not pickup_data.only_once or (bb.needs_ammo and all_players_have_ammo and lowest_bot_ammo.bot_unit and self_unit == lowest_bot_ammo.bot_unit)))
						end

						local ammo_condition = (dist < allowed_distance_to_self or (follow_pos and Vector3.distance(follow_pos, pickup_pos) < allowed_distance_to_follow_pos)) and (not current_pickup or dist - ((current_pickup == pickup_unit and ammo_stickiness) or 0) < data.ammo_dist)

						if same_kind and allowed_to_take_ammo and ammo_condition then
							bb.ammo_pickup = pickup_unit
							bb.ammo_pickup_valid_until = valid_until
							bb.ammo_dist = dist
							data.ammo_dist = dist

							if ammo_pickup_order_unit then
								data.ammo_pickup_order_unit = nil
							end
						end
					end
				end
			end
		end
	end

	table.clear(PICKUP_FETCH_RESULTS)
end)