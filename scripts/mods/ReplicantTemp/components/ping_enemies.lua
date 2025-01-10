local mod = get_mod("ReplicantTemp")

-- Breeds.chaos_corruptor_sorcerer.special = true
-- Breeds.chaos_vortex_sorcerer.special = true

local check_obstruction = mod.utility.check_obstruction

local pinged_enemies = mod:persistent_table("pinged_enemies")
pinged_enemies.enemies = {}

local find_in_array = mod.utility.find_in_array

local NO_UNIT = "no unit"
local PING_STANDART_COOLDOWN = 2	--1	--2
local KEEP_PINGED_COEFFICIENTS = { none = 0, elite = 1, special = 7.5, boss = 5 }
local PING_EFFECT_DURATION = 15
local PING_EXPIRED_RATE = 3 / 5
local BOT_TARGET_ENEMIES_CATEGORIES = { "target_unit", "slot_target_enemy", "priority_target_enemy", "urgent_target_enemy", "opportunity_target_enemy"}
mod.components.ping_enemies.attempt_ping_enemy = function (blackboard)
	local self_unit = blackboard.unit
	
	if self_unit == nil or ScriptUnit.extension(self_unit, "status_system"):is_disabled() then
		return
	end
	
	local side = Managers.state.side.side_by_unit[self_unit]
	local player_and_bot_units = side.PLAYER_AND_BOT_UNITS
	local ENEMIES = blackboard.proximite_enemies
	local last_ping_time = 0
	local last_ping_specific = "none"
	
	for k = 1, #player_and_bot_units, 1 do
		local player_unit = player_and_bot_units[k]
		if not pinged_enemies[player_unit] then
			pinged_enemies[player_unit] = { unit = NO_UNIT, time = 0, specific = "none"}
		else
			if not pinged_enemies[player_unit].unit or (pinged_enemies[player_unit].unit ~= NO_UNIT and (not Unit.alive(pinged_enemies[player_unit].unit) or Managers.time:time("game") - pinged_enemies[player_unit].time > PING_EFFECT_DURATION)) then
				pinged_enemies[player_unit].unit = NO_UNIT
				pinged_enemies[player_unit].time = 0
				pinged_enemies[player_unit].specific = "none"
			end
			
			if player_unit == self_unit then
				last_ping_time = pinged_enemies[player_unit].time
				last_ping_specific = pinged_enemies[player_unit].specific
			end
		end
	end

	local expired_pings = {}
	for k = 1, #pinged_enemies.enemies, 1 do
		local pinged_enemy = pinged_enemies.enemies[k]
		local time_from_was_pinged = Managers.time:time("game") - pinged_enemy.time
		
		local is_alive = pinged_enemy.unit and pinged_enemy.unit ~= NO_UNIT and Unit.alive(pinged_enemy.unit)
		
		if not is_alive or time_from_was_pinged > PING_EFFECT_DURATION * PING_EXPIRED_RATE then
			table.insert(expired_pings, k)
		end
	end
	
	for k = 1, #expired_pings, 1 do
		table.remove(pinged_enemies.enemies, expired_pings[k] - (k - 1))
	end
	
	local targets_num = 0
	local target_enemies = {}
	
	for _, category in pairs(BOT_TARGET_ENEMIES_CATEGORIES) do
		if blackboard[category] then
			table.insert(target_enemies, blackboard[category])
			targets_num = targets_num + 1
		end
	end
	
	local should_ping = false
	local enemy_ping_data = { unit = NO_UNIT, time = 0, specific = "none" }
	for k = 1, targets_num + #ENEMIES, 1 do
		local enemy_unit = nil
		local is_bot_target = false
		
		if k <= targets_num then
			enemy_unit = target_enemies[k]
			is_bot_target = true
		else
			enemy_unit = ENEMIES[k - targets_num]
		end
		
		local current_time = Managers.time:time("game")
		local ping_ext = ScriptUnit.extension(enemy_unit, "ping_system")
		local enemy_bb = BLACKBOARDS[enemy_unit]
		local enemy_breed = (enemy_bb and not enemy_bb.breed.not_bot_target) and enemy_bb.breed or nil
		local enemy_specific = enemy_breed and (enemy_breed.elite and "elite" or (enemy_breed.special and "special" or (enemy_breed.boss and "boss" or "none"))) or "none"
		local enemy_target = enemy_bb and enemy_bb.target_unit
		
		local is_alive = enemy_unit and Unit.alive(enemy_unit)
		
		if is_alive and enemy_specific ~= "none" then
			local is_in_pinged_enemies_array = find_in_array(pinged_enemies.enemies, enemy_unit, "unit")
			local is_pinged = ping_ext and ping_ext:pinged() or false
			
			for k = 1, #player_and_bot_units, 1 do
				local player_unit = player_and_bot_units[k]
				if pinged_enemies[player_unit] and pinged_enemies[player_unit].unit == enemy_unit then
					is_pinged = true
					break
				end
			end
			
			local was_recently_pinged = is_in_pinged_enemies_array and true or false
			local is_targeting_player_or_bot = find_in_array(player_and_bot_units, enemy_target, nil)
			local bot_has_other_pinged_enemy = (pinged_enemies[self_unit].unit and pinged_enemies[self_unit].unit ~= NO_UNIT) and true or false
			local bot_ping_cooldown_is_over = not bot_has_other_pinged_enemy or (last_ping_time + PING_STANDART_COOLDOWN * KEEP_PINGED_COEFFICIENTS[last_ping_specific]) < current_time
		
			if (is_targeting_player_or_bot or enemy_specific == "special" or enemy_specific == "boss" or is_bot_target) and not is_pinged and bot_ping_cooldown_is_over then
				local obstructed_line_of_sight = check_obstruction(blackboard, enemy_unit, { mode = "los" })
				if not was_recently_pinged and not obstructed_line_of_sight then
					enemy_ping_data.unit = enemy_unit
					enemy_ping_data.time = current_time
					enemy_ping_data.specific = enemy_specific
					should_ping = true
					if enemy_specific == "special" or enemy_specific == "boss" then
						break
					end
				elseif not bot_has_other_pinged_enemy and not obstructed_line_of_sight then
					enemy_ping_data.unit = enemy_unit
					enemy_ping_data.time = current_time
					enemy_ping_data.specific = enemy_specific
					should_ping = true
				end
			end
		end
	end
	
	if should_ping then
		table.insert(pinged_enemies.enemies, { unit = enemy_ping_data.unit, time = enemy_ping_data.time })
		pinged_enemies[self_unit].unit = enemy_ping_data.unit
		pinged_enemies[self_unit].time = enemy_ping_data.time
		pinged_enemies[self_unit].specific = enemy_ping_data.specific
		local network_manager = Managers.state.network
		local self_unit_id = network_manager.unit_game_object_id(network_manager, self_unit)
		local enemy_unit_id = network_manager.unit_game_object_id(network_manager, enemy_ping_data.unit)
		local ping_type = PingTypes.PING_ONLY
		-- network_manager.network_transmit:send_rpc_server("rpc_ping_unit", self_unit_id, enemy_unit_id, false, ping_type, 1)
		-- network_manager.network_transmit:send_rpc_server("rpc_ping_unit", self_unit_id, enemy_unit_id, false, false, ping_type, 1)
		
		local Peregrinaje = get_mod("Peregrinaje")
		local fifth_argument = (Peregrinaje and "tag") or false
		
		network_manager.network_transmit:send_rpc_server("rpc_ping_unit", self_unit_id, enemy_unit_id, false, fifth_argument, ping_type, 1)
	end
	
	return
end


-- replaced to file "AggroTweaks.lua"
--[[mod:hook(PlayerBotBase, "_update_target_enemy", function (func, self, ...)
	result = func(self, ...)
	
	if mod.components.ping_enemies.value then
		mod.components.ping_enemies.attempt_ping_enemy(self._blackboard)
	end
	
	return result
end)--]]


-- old version, has limited distance (40 m if I can remember)
--[[mod:hook(BTBotMeleeAction, "run", function (func, self, unit, blackboard, t, dt)
	local result = func(self, unit, blackboard, t, dt)

	if mod:get("ping_enemies") then
		attempt_ping_enemy(blackboard)
	end

	return result
end)

mod:hook(BTBotShootAction, "run", function (func, self, unit, blackboard, t, dt)
	local result = func(self, unit, blackboard, t, dt)
	
	if mod:get("ping_enemies") then
		attempt_ping_enemy(blackboard)
	end

	return result
end)--]]