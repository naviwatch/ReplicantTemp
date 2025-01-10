local mod = get_mod("ReplicantTemp")

--[[mod:hook(BTConditions, "should_vent_overcharge", function (func, blackboard, args)
	if not mod.components.overcharge_tweaks then
		return func(blackboard, args)
	end
	
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	
	if career_name ~= "bw_scholar" and career_name ~= "bw_unchained" then
		return func(blackboard, args)
	end
	
	local overcharge_extension = blackboard.overcharge_extension
	local overcharge_limit_type = "maximum"
	local current_oc, threshold_oc, max_oc = overcharge_extension:current_overcharge_status()
	local overcharge_percentage = 0
	
	local condition_args = {
					start_min_percentage = 0.75,
					start_max_percentage = 0.95,
					stop_percentage = 0.55,
					overcharge_limit_type = "maximum"
				}

	local overcharge_percentage = current_oc / max_oc

	local should_vent = nil

	if blackboard.reloading then
		should_vent = condition_args.stop_percentage <= overcharge_percentage
	else
		should_vent = condition_args.start_min_percentage <= overcharge_percentage and overcharge_percentage <= condition_args.start_max_percentage
	end
	
	return should_vent
end)--]]

local function get_attacking_proximite_enemies(self_unit, check_range, max_height_offset)
	if not max_height_offset then
		max_height_offset = math.huge
	end
	
	local prox_enemies = {}

	local search_position = Vector3.copy(POSITION_LOOKUP[self_unit])
	
	local query_tmp = {}
	local enemy_broadphase = Managers.state.entity:system("ai_system").broadphase
	local num_hits = Broadphase.query(enemy_broadphase, search_position, check_range, query_tmp)
	local index = 1

	for i = 1, num_hits, 1 do
		local unit = query_tmp[i]
		local health_ext = unit and ScriptUnit.has_extension(unit, "health_system")

		if health_ext and health_ext.is_alive(health_ext) then
			local enemy_pos = POSITION_LOOKUP[unit]
			local offset = enemy_pos - search_position
			local distance = offset and Vector3.length(offset)
			local z_offset = offset and offset.z
			local in_range = offset and z_offset < max_height_offset and distance < check_range
			local enemy_bb = unit and BLACKBOARDS[unit]
			local is_targeting_player = enemy_bb.target_unit == self_unit

			-- if PlayerBotBase._target_valid(nil, unit, offset) then
			if in_range and is_targeting_player then
				local breed = Unit.get_data(unit, "breed")
				if breed and breed.name ~= "critter_pig" and breed.name ~= "critter_rat" then
					prox_enemies[index] = unit
					index = index + 1
				end
			end
		end
	end

	table.clear(query_tmp)

	return prox_enemies
end

local function is_unit_in_aoe_explosion_threat_area(unit)		-- check if the given unit is inside gas / fire patch / triggered barrel effect area
	if not unit then
		return false
	end
	
	local ret = false
	local unit_pos		= POSITION_LOOKUP[unit] or Unit.local_position(unit, 0) or false
	local nav_world		= Managers.state.entity:system("ai_system"):nav_world()
	local group_system	= Managers.state.entity:system("ai_bot_group_system")
	--
	if unit_pos and nav_world and group_system then
		local in_threat_area, _		= group_system:_selected_unit_is_in_disallowed_nav_tag_volume(nav_world, unit_pos)
		ret = in_threat_area
	end
	
	return ret
end

--[[mod:hook(BTConditions, "should_vent_overcharge", function(func, blackboard, args)
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	
	local original_start_min_percentage = args.start_min_percentage
	local original_stop_percentage = args.stop_percentage
	
	if career_name == "bw_unchained" then
		args.start_min_percentage = 0.75
		args.stop_percentage = 0.55
		args.overcharge_limit_type = "maximum"
	elseif career_name == "bw_scholar" then
		args.start_min_percentage = 0.90
		args.stop_percentage = 0.55
		args.overcharge_limit_type = "maximum"
	else
		args.start_min_percentage = 0.3		--0.2		--check if this interferes with shooting
		args.stop_percentage = 0.075
		args.overcharge_limit_type = "maximum"		--0.05		--0.1
	end
	
	local ret = func(blackboard, args)
	
	args.start_min_percentage = original_start_min_percentage
	args.stop_percentage = original_stop_percentage
	
	local self_unit = blackboard.unit
	local health_extension	= ScriptUnit.has_extension(self_unit, "health_system")
	local current_hp		= health_extension and health_extension:current_health()
	
	local prox_enemies = get_attacking_proximite_enemies(self_unit, 4)
	local num_enemies = #prox_enemies
	
	return (ret and (not current_hp or (current_hp > (career_name == "bw_unchained" and 10 or 20))) and not is_unit_in_aoe_explosion_threat_area(self_unit) and (num_enemies < 1))
end)--]]



local vent_check_interval = 1.5
local last_vent_check = {}

--Vernon: add a small buffer to prevent just below vent line -> use staff -> vent loop
local should_vent_overcharge = function(func, blackboard, args)
	local current_time = Managers.time:time("game")
	if blackboard.unit and last_vent_check[blackboard.unit] then
		if current_time < last_vent_check[blackboard.unit].t + vent_check_interval then
			return last_vent_check[blackboard.unit].should_vent
		else
			last_vent_check[blackboard.unit] = nil
		end
	end

	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	
	local original_start_min_percentage = args.start_min_percentage
	local original_stop_percentage = args.stop_percentage
	
	if career_name == "bw_unchained" then
		args.start_min_percentage = 0.80
		args.stop_percentage = 0.55
		args.overcharge_limit_type = "maximum"
	elseif career_name == "bw_scholar" then
		args.start_min_percentage = 0.90
		args.stop_percentage = 0.55
		args.overcharge_limit_type = "maximum"
	else
		args.start_min_percentage = 0.4		--0.2		--check if this interferes with shooting
		args.stop_percentage = 0.075
		args.overcharge_limit_type = "maximum"		--0.05		--0.1
	end
	
	local ret = func(blackboard, args)
	
	args.start_min_percentage = original_start_min_percentage
	args.stop_percentage = original_stop_percentage
	
	local self_unit = blackboard.unit
	local health_extension	= ScriptUnit.has_extension(self_unit, "health_system")
	local current_hp		= health_extension and health_extension:current_health()
	
	local prox_enemies = get_attacking_proximite_enemies(self_unit, 4)
	local num_enemies = #prox_enemies
	
	-- return (ret and (not current_hp or (current_hp > (career_name == "bw_unchained" and 10 or 20))) and not is_unit_in_aoe_explosion_threat_area(self_unit) and (num_enemies < 1))
	local should_vent = (ret and (not current_hp or (current_hp > (career_name == "bw_unchained" and 10 or 20))) and not is_unit_in_aoe_explosion_threat_area(self_unit) and (num_enemies < 1))
	
	if blackboard.unit then
		last_vent_check[blackboard.unit] = {
			should_vent = should_vent,
			t = current_time
		}
	end
	
	return should_vent
end


local RELOAD_TYPES = {
	regular_ammo = 1,
	unique_ammo = 2,
	vent_overcharge = 3,
	ability_weapon = 4
}

mod:hook(BTConditions, "should_reload_weapon", function (func, blackboard, args)
	if blackboard._current_reload and blackboard._current_reload ~= RELOAD_TYPES.regular_ammo then
		return false
	end
	
	local should_reload = func(blackboard, args)
	
	blackboard._current_reload = should_reload and RELOAD_TYPES.regular_ammo or nil
	
	return should_reload
end)

mod:hook(BTConditions, "should_recall_unique_ammo", function (func, blackboard, args)
	if blackboard._current_reload and blackboard._current_reload ~= RELOAD_TYPES.unique_ammo then
		return false
	end
	
	local should_reload = func(blackboard, args)
	
	blackboard._current_reload = should_reload and RELOAD_TYPES.unique_ammo or nil
	
	return should_reload
end)

mod:hook(BTConditions, "should_vent_overcharge", function (func, blackboard, args)
	if blackboard._current_reload and blackboard._current_reload ~= RELOAD_TYPES.vent_overcharge then
		return false
	end
	
	local should_reload = should_vent_overcharge(func, blackboard, args)
	
	blackboard._current_reload = should_reload and RELOAD_TYPES.vent_overcharge or nil
	
	return should_reload
end)

mod:hook(BTConditions, "should_reload_ability_weapon", function (func, blackboard, args)
	if blackboard._current_reload and blackboard._current_reload ~= RELOAD_TYPES.ability_weapon then
		return false
	end
	
	local should_reload = func(blackboard, args)
	
	blackboard._current_reload = should_reload and RELOAD_TYPES.ability_weapon or nil
	
	return should_reload
end)

mod:hook(BTConditions.reload_ability_weapon, "dr_engineer", function (func, blackboard, args)
	local self_unit = blackboard.unit
	
	local career_extension = blackboard.career_extension
	
	if self_unit and career_extension then
		local proximite_enemies = blackboard.proximite_enemies

		local can_reload = args.ability_cooldown_theshold < career_extension:current_ability_cooldown() and #proximite_enemies == 0
		
		if can_reload then
			local buff_extension = ScriptUnit.extension(self_unit, "buff_system")
			local talent_extension = ScriptUnit.extension(self_unit, "talent_system")
			
			local buff_name = nil
			if talent_extension:has_talent("bardin_engineer_pump_buff_long") then
				buff_name = "bardin_engineer_pump_buff_long"
			else
				buff_name = "bardin_engineer_pump_buff"
			end
			
			local num_stacks = buff_extension:num_buff_type(buff_name)
			local buff_type = buff_extension:get_buff_type(buff_name)
			
			if buff_type then
				local buff_template = buff_type.template
				local end_time = buff_type.end_time
				
				local current_time = Managers.time:time("game")
				if num_stacks < buff_template.max_stacks then
					return true
				elseif not infinite_buff and end_time and current_time > end_time - 5 then
					return true
				end
			else
				return true
			end
		end
	end

	return false
end)

--[[BTConditions.need_swap_to_ranged = function (blackboard, args)
	local wielded_slot = blackboard.inventory_extension:equipment().wielded_slot
	local wanted_slot = args[1]
	local exception_slot = args[2]

	if exception_slot and exception_slot == wielded_slot then
		return false
	elseif blackboard._can_take_aim then
		return wielded_slot ~= wanted_slot
	end
	
	return false
end--]]