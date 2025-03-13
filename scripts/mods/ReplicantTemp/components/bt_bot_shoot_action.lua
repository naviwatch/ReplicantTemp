local mod = get_mod("ReplicantTemp")
local mod_name = mod:get_name()

--[[ original prediction function from ProjectileTemplates.trajectory_templates.throw_trajectory
local original_prediction_function = function (speed, gravity, initial_position, target_position, target_velocity)
	local t = 0
	local angle = nil
	local EPSILON = 0.01
	local ITERATIONS = 10

	assert(gravity > 0, "Can't solve for <=0 gravity, use different projectile template")

	local estimated_target_position = target_position

	for i = 1, ITERATIONS, 1 do
		estimated_target_position = target_position + t * target_velocity
		local height = estimated_target_position.z - initial_position.z
		local speed_squared = speed^2
		local flat_distance = Vector3.length(Vector3.flat(estimated_target_position - initial_position))

		if flat_distance < EPSILON then
			return 0, estimated_target_position
		end

		local sqrt_val = speed_squared^2 - gravity * (gravity * flat_distance^2 + 2 * height * speed_squared)

		if sqrt_val <= 0 then
			return nil, estimated_target_position
		end

		local second_degree_component = math.sqrt(sqrt_val)
		local angle1 = math.atan((speed_squared + second_degree_component) / (gravity * flat_distance))
		local angle2 = math.atan((speed_squared - second_degree_component) / (gravity * flat_distance))
		angle = math.min(angle1, angle2)

		local flat_distance = Vector3.length(Vector3.flat(estimated_target_position - initial_position))
		t = flat_distance / (speed * math.cos(angle))
	end

	return angle, estimated_target_position
end--]]

-- local polynomials = dofile ("scripts/mods/"..mod:get_name().."/_polynomial_equations")
local polynomials = dofile("scripts/mods/"..mod_name.."/components/polynomial_equations")

local function get_best_real_time(times)
	local t = math.huge
	local assigned = false

	for i = 1, #times, 1 do
		if times[i] and times[i] >= 0 and times[i] < t then
			t = times[i]

			assigned = true
		end
	end

	return assigned and t or nil
end

local solve_moving_eq_const_speed = function (c0, c1, c2, c3, c4)
	local t1, t2, t3, t4 = polynomials.solveQuartic(c0, c1, c2, c3, c4)

	return get_best_real_time({ t1, t2, t3, t4 })
end

local solve_moving_eq_dampening_speed = function(c0, c1, c2_base, c3, c4, init_s, dampening)
	local t
	local old_t
	local s = init_s
	local k = dampening - 1

	for i = 1, 20, 1 do
		t = solve_moving_eq_const_speed(c0, c1, c2_base - s^2, c3, c4)

		if not t then
			break
		elseif old_t and math.abs(t - old_t) <= 0.00000000001 then
			break
		end

		s = init_s * math.exp(k * t)

		old_t = t
	end

	return t, s
end

-- it should be changed to predict aim more properly, especially for javelins which have linear dampening
-- all my attempts to do that were absolutely futile

mod:hook_origin(ProjectileTemplates.trajectory_templates.throw_trajectory, "prediction_function", function(speed, dampening, gravity, player_position, target_position, target_velocity)
	assert(gravity >= 0, "Can't solve for <0 gravity, use different projectile template")

	local P = target_position - player_position
	local G = Vector3(0, 0, gravity)   -- positive gravity! we imagine the target is "falling" UP
	local V = target_velocity
	local s = speed

	local c0 = Vector3.dot(G, G) / 4
	local c1 = Vector3.dot(V, G)
	local c2_base = Vector3.dot(P, G) + Vector3.dot(V, V)
	local c3 = 2 * Vector3.dot(P, V)
	local c4 = Vector3.dot(P, P)

	local t

	if dampening then
		t, s = solve_moving_eq_dampening_speed(c0, c1, c2_base, c3, c4, s, dampening)
	else
		t = solve_moving_eq_const_speed(c0, c1, c2_base - s^2, c3, c4)
	end

	if not t then
		return nil, nil
	end

	local aim_z = P.z + V.z * t + G.z * t^2 / 2    -- aim_pos = P + V * t + G * t^2 / 2
	local sin = aim_z / (s * t)                    -- aim_pos.z / (Vector3.length(aim_pos))

	if sin < -1 or sin > 1 then
		return nil, nil
	end

	local angle = math.asin(sin)
	local estimated_target_position = target_position + V * t

	return angle, estimated_target_position
end)

ProjectileTemplates.trajectory_templates.geiser_trajectory = { -- for conflag and deus staff
	prediction_function = function(speed, dampening, gravity, player_position, target_position, target_velocity) -- algorithm like standing target const projectile speed
		assert(gravity >= 0, "Can't solve for <0 gravity, use different projectile template")					 -- is needed because staffs aiming works like that - you look at some point and aim is calculated like if you
																												 -- throw something straight in the direction of view (with speed = 15 in case of these staffs), and it falls down

		local nav_world	= Managers.state.bot_nav_transition._nav_world
		local success, aim_z = GwNavQueries.triangle_from_position(nav_world, target_position, 3, 4) -- aim at ground

		if not success then
			return nil, nil
		else
			target_position.z = aim_z
		end

		local P = target_position - player_position
		--P = P - Vector3.normalize(P) -- center geiser on target, P is the 'bottom' part of explosion circle, maybe
		local G = Vector3(0, 0, gravity)    -- positive gravity! we imagine the target is "falling" UP
		local s = speed

		local c0 = Vector3.dot(G, G) / 4
		local c1 = Vector3.dot(P, G) - s^2
		local c2 = Vector3.dot(P, P)

		local u1, u2 = polynomials.solveQuadric(c0, c1, c2) -- u = t^2

		local u = get_best_real_time({ u1, u2 })

		if not u then
			return nil, nil
		end

		local aim_P = P + G * u / 2
		local angle = math.asin(aim_P.z / (s * math.sqrt(u)))

		return angle, target_position
	end
}

-- defalult constants and functions, nothing changed
local DEFAULT_AIM_DATA = {
	min_radius_pseudo_random_c = 0.0557,
	max_radius_pseudo_random_c = 0.01475,
	min_radius = math.pi / 72,
	max_radius = math.pi / 16
}
local THIS_UNIT = nil
local disengage_above_nav = 3
local disengage_below_nav = 3

local function dprint(...)
	if script_data.ai_bots_weapon_debug and script_data.debug_unit == THIS_UNIT then
		print(...)
	end
end

local function check_angle(nav_world, target_position, start_direction, angle, distance)
	local direction = Quaternion.rotate(Quaternion(Vector3.up(), angle), start_direction)
	local check_pos = target_position + direction * distance
	local success, altitude = GwNavQueries.triangle_from_position(nav_world, check_pos, disengage_above_nav, disengage_below_nav)

	if success then
		check_pos.z = altitude

		return true, check_pos
	else
		return false
	end
end

local function get_disengage_pos(nav_world, start_pos, disengage_vector, move_distance)
	local disengage_direction = Vector3.normalize(Vector3.flat(disengage_vector))
	local success, pos = check_angle(nav_world, start_pos, disengage_direction, 0, move_distance)

	if success then
		return pos
	end

	local subdivisions_per_side = 3
	local angle_inc = math.pi / 2 / subdivisions_per_side

	for i = 1, subdivisions_per_side, 1 do
		local angle = angle_inc * i
		success, pos = check_angle(nav_world, start_pos, disengage_direction, angle, move_distance)

		if success then
			return pos
		end

		success, pos = check_angle(nav_world, start_pos, disengage_direction, -angle, move_distance)

		if success then
			return pos
		end
	end

	return nil
end

local function get_disengage_vector(current_pos, enemy_unit, keep_distance, keep_distance_sq)
	if ALIVE[enemy_unit] then
		local target_unit_position = POSITION_LOOKUP[enemy_unit]
		local dist_sq = Vector3.distance_squared(current_pos, target_unit_position)

		if dist_sq < keep_distance_sq and dist_sq > 0 then
			local dist = math.sqrt(dist_sq)

			return (current_pos - target_unit_position) * (keep_distance - dist) / dist
		end
	end

	return nil
end

--------------------------------------------------------------------------------------------------------------------

mod:hook(BTBotShootAction, "enter", function (func, self, unit, blackboard, t)
	local input_ext = blackboard.input_extension
	local soft_aiming = false

	input_ext:set_aiming(true, soft_aiming, true)

	local target_unit = blackboard.target_unit
	local action_data = self._tree_node.action_data
	local inventory_extension = blackboard.inventory_extension
	local wielded_slot_name = action_data.slot_name or inventory_extension:get_wielded_slot_name()
	local slot_data = inventory_extension:get_slot_data(wielded_slot_name)
	local item_data = slot_data.item_data
	local item_template = BackendUtils.get_item_template(item_data)
	local attack_meta_data = item_template.attack_meta_data or {}
	local base_attack_action = item_template.actions[attack_meta_data.base_action_name or "action_one"]
	local attack_action = base_attack_action.default
	local charged_attack_action = base_attack_action[attack_meta_data.charged_attack_action_name or "shoot_charged"] or attack_action
	blackboard.shoot = {
		num_aim_rolls = 0,
		charging_shot = false,
		disengage_update_time = 0,
		attack_meta_data = attack_meta_data,
		attack_action = attack_action,
		charged_attack_action = charged_attack_action,
		aim_data = attack_meta_data.aim_data or DEFAULT_AIM_DATA,
		aim_data_charged = attack_meta_data.aim_data_charged or attack_meta_data.aim_data or DEFAULT_AIM_DATA,
		can_charge_shot = attack_meta_data.can_charge_shot,
		ignore_disabled_enemies_charged = attack_meta_data.ignore_disabled_enemies_charged,
		charge_shot_delay = attack_meta_data.charge_shot_delay,
		fire_input = attack_meta_data.fire_input or "fire",
		charge_input = attack_meta_data.charge_input or "charge_shot",
		next_evaluate = t + action_data.evaluation_duration,
		next_evaluate_without_firing = t + action_data.evaluation_duration_without_firing,
		minimum_charge_time = attack_meta_data.minimum_charge_time,
		reevaluate_obstruction_time = 0,
		charge_range_squared = (attack_meta_data.charge_above_range and attack_meta_data.charge_above_range^2) or nil,
		max_range_squared = (attack_meta_data.max_range and attack_meta_data.max_range^2) or math.huge,
		--max_range_squared_charged = (attack_meta_data.max_range_charged and attack_meta_data.max_range_charged^2) or (attack_meta_data.max_range and attack_meta_data.max_range^2) or math.huge,
		max_range_squared_charged = (attack_meta_data.max_range_charged and attack_meta_data.max_range_charged^2) or
									(attack_meta_data.max_range and not attack_meta_data.charge_when_outside_max_range and attack_meta_data.max_range^2) or
									math.huge,
		charge_when_obstructed = attack_meta_data.charge_when_obstructed,
		charge_when_outside_max_range = attack_meta_data.charge_when_outside_max_range,
		charge_when_outside_max_range_charged = attack_meta_data.charge_when_outside_max_range_charged == nil or attack_meta_data.charge_when_outside_max_range_charged,
		effective_against = attack_meta_data.effective_against or 0,
		effective_against_charged = attack_meta_data.effective_against_charged or 0,
		always_charge_before_firing = attack_meta_data.always_charge_before_firing,
		aim_at_node = attack_meta_data.aim_at_node or "j_spine",
		aim_at_node_charged = attack_meta_data.aim_at_node_charged or attack_meta_data.aim_at_node or "j_spine",
		projectile_info = attack_action.projectile_info,
		projectile_info_charged = charged_attack_action.projectile_info,
		projectile_speed = attack_action.min_speed or attack_action.speed,
		projectile_speed_charged = charged_attack_action.max_speed or charged_attack_action.min_speed or charged_attack_action.speed,
		obstruction_fuzzyness_range = attack_meta_data.obstruction_fuzzyness_range,
		obstruction_fuzzyness_range_charged = attack_meta_data.obstruction_fuzzyness_range_charged or attack_meta_data.obstruction_fuzzyness_range,
		hold_fire_condition = attack_meta_data.hold_fire_condition,
		keep_distance = attack_meta_data.keep_distance,

		is_ability_shot = (self._tree_node.action_data.name == "shoot_ability"),
		do_not_shoot_in_aoe_threat = attack_meta_data.do_not_shoot_in_aoe_threat,
		ai_bot_group_extension = (attack_meta_data.do_not_shoot_in_aoe_threat and ScriptUnit.extension(unit, "ai_bot_group_system")) or nil,

		charge_input_threat = attack_meta_data.charge_input_threat,
		has_alternative_shot = attack_meta_data.has_alternative_shot,
		alternative_input = attack_meta_data.alternative_input,
		effective_against_alternative = attack_meta_data.effective_against_alternative or 0,
		ignore_disabled_enemies_alternative = attack_meta_data.ignore_disabled_enemies_alternative,
		max_range_squared_alternative = attack_meta_data.max_range_alternative and attack_meta_data.max_range_alternative^2 or math.huge,
		alternative_when_obstructed = attack_meta_data.alternative_when_obstructed,
		alternative_attack_min_charge_time = attack_meta_data.alternative_attack_min_charge_time or 0,
		alternative_attack_max_charge_time = attack_meta_data.alternative_attack_max_charge_time or attack_meta_data.alternative_attack_min_charge_time or 0,
		alternative_attack_duration = attack_meta_data.alternative_attack_duration or 0.05,
		alternative_input_duration = attack_meta_data.alternative_input_duration or 0.05,
		always_use_alternative_attack = attack_meta_data.always_use_alternative_attack,
		disable_target_change = attack_meta_data.disable_target_change,
		dodge_while_firing = attack_meta_data.dodge_while_firing,
		hit_only_zones = attack_meta_data.hit_only_zones,

		obstructed_fire_shot = true,
		obstructed_charged_shot = true,
		obstructed_by_static = true,
		obstructed_by_enemy = function(self)
			return (self.charging_shot and self.obstructed_charged_shot) or self.obstructed_fire_shot
		end,

		uninterruptable_charge = attack_meta_data.uninterruptable_charge,
		max_hold_fire_duration = attack_meta_data.max_hold_fire_duration,
		aim_out_of_radius = true,
		fired = false
	}

	local shoot_bb = blackboard.shoot

	if shoot_bb.is_ability_shot then
		blackboard.activate_ability_data.is_using_ability = true
	end

	blackboard.ranged_obstruction_by_static = nil

	self:_set_new_aim_target(shoot_bb, target_unit, t)
	self:_update_collision_filter(target_unit, shoot_bb, blackboard.priority_target_enemy, blackboard.target_ally_unit, blackboard.target_ally_needs_aid, blackboard.target_ally_need_type)
end)

mod:hook(BTBotShootAction, "_set_new_aim_target", function (func, self, shoot_blackboard, target_unit, t)
	local breed = target_unit and Unit.get_data(target_unit, "breed") or nil
	shoot_blackboard.target_unit = target_unit
	shoot_blackboard.target_breed = breed

	shoot_blackboard.reevaluate_obstruction_time = 0
	shoot_blackboard.aim_speed_yaw = 0
	shoot_blackboard.aim_speed_pitch = 0
	shoot_blackboard.reevaluate_aim_time = 0

	shoot_blackboard.disengage_update_time = 0
	shoot_blackboard.disengage_position_set = false

	shoot_blackboard.fired = shoot_blackboard.hold_fire_condition and shoot_blackboard.fired or false
end)

mod:hook(BTBotShootAction, "run", function (func, self, unit, blackboard, t, dt)
	THIS_UNIT = unit
	local done, evaluate = self:_aim(unit, blackboard, dt, t)

	if done then
		return "done", "evaluate"
	else
		return "running", (evaluate and "evaluate") or nil
	end
end)

mod:hook(BTBotShootAction, "leave", function (func, self, unit, blackboard, t, reason, destroy)
	local input_ext = blackboard.input_extension

	input_ext:set_aim_rotation(Quaternion(Vector3.zero(), 0))
	input_ext:set_aiming(false)

	local action_data = self._tree_node.action_data

	local shoot_bb = blackboard.shoot

	if shoot_bb.is_ability_shot then
		blackboard.activate_ability_data.is_using_ability = false
	end

	if shoot_bb.charging_shot or shoot_bb.fired then
		self:_discard_shot(input_ext, shoot_bb, action_data, true)
	end

	blackboard.shoot = nil
end)

BTBotShootAction._discard_shot = function(self, input_extension, shoot_blackboard, action_data, on_destroy)
	local abort_input = action_data.abort_input

	if input_extension and abort_input and abort_input ~= "none" then
		input_extension[abort_input](input_extension)
	end

	if not on_destroy then
		shoot_blackboard.fired = false
		shoot_blackboard.doing_alternative_attack = false
		shoot_blackboard.charging_shot = false
		shoot_blackboard.charge_start_time = math.huge
	end
end

--------------------------------------------------------------------------------------------------------------------

mod:hook(BTBotShootAction, "_wanted_aim_rotation", function (func, self, self_unit, target_unit, current_position, projectile_info, projectile_speed, aim_at_node)
	--Override for Stormfiends
	local target_unit_blackboard = BLACKBOARDS[target_unit]
	local target_breed = target_unit_blackboard and target_unit_blackboard.breed
	
	if target_breed and (target_breed.name == "skaven_stormfiend" or target_breed.name == "skaven_stormfiend_boss") then
		local _, flanking = mod.check_alignment_to_target(self_unit, target_unit, nil, 90)
		if flanking then
			aim_at_node = "c_packmaster_sling_02"
		end
	end

	local target_node = Unit.has_node(target_unit, aim_at_node) and Unit.node(target_unit, aim_at_node) or 0
	local target_pos = Unit.world_position(target_unit, target_node)
	local target_locomotion_extension = ScriptUnit.has_extension(target_unit, "locomotion_system")
	local target_current_velocity = (target_locomotion_extension and target_locomotion_extension:current_velocity()) or Vector3.zero()
	local target_rotation, target_position = nil

	local prediction_function = projectile_info and ProjectileTemplates.trajectory_templates[projectile_info.trajectory_template_name].prediction_function

	if prediction_function then
		local linear_dampening = projectile_info.linear_dampening -- javelins' and throwing axes' own tangential (!) velocity become less with time (they have 0.691 dampening)
																  -- the 'law' of it is: new_v = v - (1 - dampening) * v * dt (such formula can be found in game code, in some projectile update function)
																  -- or mathematical 'strict' version: dv = (dampening - 1) * v * dt
																  -- if we solve this differential equation we'll get: v = v_0 * exp((dampening - 1) * t)
																  -- NOTE: this effect absolutely doesn't affect the obtained 'gravity' velocity!
																  -- like if the missle was launced vertically down - the simpliest example - its velosity is calculated like
																  -- v = own_v + g * t,  where  own_v = v_0 * exp((dampening - 1) * t)
																  --
																  -- ###############################################################################################################
																  --
																  -- the trajectory (in my case - relative position from start point) is estimated on the base of the last! veocity:
																  -- P = V * t + G * t^2, where V is start velocity vector which module is |V| = v_0 * exp((dampening - 1) * t)

		local gravity_setting = ProjectileGravitySettings[projectile_info.gravity_settings]
		local angle = nil

		angle, target_position = prediction_function(projectile_speed / 100, linear_dampening, -gravity_setting, current_position, target_pos, target_current_velocity)

		if not angle then
			if self_unit == script_data.debug_unit then
				print("BTBotShootAction no angle found, target out of range")
			end

			return nil, nil
		end

		target_rotation = Quaternion.multiply(Quaternion.look(Vector3.normalize(Vector3.flat(target_position - current_position)), Vector3.up()), Quaternion(Vector3.right(), angle))
	else
		target_position = target_pos
		target_rotation = Quaternion.look(Vector3.normalize(target_position - current_position), Vector3.up())
	end

	return target_rotation, target_position
end)

mod:hook(BTBotShootAction, "_calculate_aim_speed", function(func, self, self_unit, dt, current_yaw, current_pitch, wanted_yaw, wanted_pitch, shoot_blackboard)
	-- The newest original Fatsharks version of this method contain different systems.
	-- They use system based on acceleration and deceleration, calculating of 'overshots', etc.
	-- I dislike that system cause:
	-- a) it need too much fixes to improve aiming speed not getting bots' aim swinging left and right
	-- b) it is absolutely wrong with what players do:
	--     1) we most of the time look at the direction where target can/should appear - so we usually have much less offsets
	--     2) we don't accelerate and decelerate our mouses all the time - only at the beginning and at the ending of movement;
	--        bots instead accelerate it all the 'way' to the target, then, when they got 'overshot', they decelerate movement back

	local current_yaw_speed = shoot_blackboard.aim_speed_yaw
	local current_pitch_speed = shoot_blackboard.aim_speed_pitch
	local doing_alternative_attack = shoot_blackboard.doing_alternative_attack

	local pi = math.pi
	local yaw_offset = (wanted_yaw - current_yaw + pi)%(pi*2) - pi
	local pitch_offset = wanted_pitch - current_pitch

	local speed_multiplier = 10*100*dt	--4*100*dt	--6*100*dt	--8*100*dt		-- Mainly nerf bots sniping speed here

	-- yaw_offset can take values from -pi to +pi.
	-- Let's take one of the limitings: yaw_offset = pi.
	-- Let dt = 0.015. Then we'll have:
	--    speed_multiplier = 10*100*dt = 15
	--    yaw_mult = pi^(0.6) = 1.9874
	--    new_yaw_speed = 1.9874 * 15 = 29.8

	-- Now let's check this condition:
	--    math.abs(new_yaw_speed) > yaw_abs/dt = 314
	-- It won't be true, and really our speed is >10 times less than 'one-frame-destination-reach' speed (it is yaw_abs/dt).
	-- And this speed is also getting the slower the lower offset is.


	local yaw_sign = math.sign(yaw_offset)
	local yaw_abs = math.abs(yaw_offset)
	local yaw_mult = math.max(math.sqrt(yaw_abs), yaw_abs^(0.8)) --  x^(0.8) > sqrt(x) when x > 1, it makes bots rotate faster with large offsets
																 -- (let me remind you that 0 <= yaw_abs <= pi)

	local new_yaw_speed = yaw_sign * yaw_mult * speed_multiplier

	if math.abs(new_yaw_speed) > yaw_abs/dt then
		new_yaw_speed = yaw_offset/dt
	elseif doing_alternative_attack then -- added because bots cannot predict animations in a normal way, so at least they'll aim more properly during the shot
		new_yaw_speed = yaw_offset/dt
	end

	local pitch_sign = math.sign(pitch_offset)
	local pitch_abs = math.abs(pitch_offset)
	local pitch_mult = math.max(math.sqrt(pitch_abs), pitch_abs^(0.8)) --  the same thing

	local new_pitch_speed = pitch_sign * pitch_mult * speed_multiplier

	if math.abs(new_pitch_speed) > pitch_abs/dt then
		new_pitch_speed	= pitch_offset/dt
	elseif doing_alternative_attack then
		new_yaw_speed = pitch_offset/dt
	end

	return new_yaw_speed, new_pitch_speed
end)

-- tried to improve the 'default' aim system, but it went bad and sometimes even caused bugs like rotation around.
--[[mod:hook(BTBotShootAction, "_calculate_aim_speed", function(func, self, self_unit, dt, current_yaw, current_pitch, wanted_yaw, wanted_pitch, current_yaw_speed, current_pitch_speed)
	local pi = math.pi
	local yaw_offset = (wanted_yaw - current_yaw + pi) % (pi * 2) - pi
	local pitch_offset = wanted_pitch - current_pitch

	local new_yaw_speed = (math.abs(current_yaw_speed) < 0.5 and math.abs(yaw_offset) <= pi / 72) and yaw_offset / dt or nil
	local lerped_pitch_speed = pitch_offset / dt

	if new_yaw_speed then
		return new_yaw_speed, lerped_pitch_speed
	end

	local wanted_yaw_speed = yaw_offset / dt * 0.8 --yaw_offset * math.pi * 10
		local offset_degree = math.abs(yaw_offset) / pi
		local speed_degree = wanted_yaw_speed ~= 0 and 1.25 * math.min(math.abs(current_yaw_speed / wanted_yaw_speed), 1) or 0
	local acceleration = math.max(15 + offset_degree * 25 - speed_degree * 28, 1)													--7.5
	local deceleration = math.max(40 + math.min( math.max(speed_degree, 0.5) / offset_degree, 30) + speed_degree * 40, 1) 			--25

	local yaw_offset_sign = math.sign(yaw_offset)
	local yaw_speed_sign = math.sign(current_yaw_speed)
	local has_overshot = yaw_speed_sign ~= 0 and yaw_offset_sign ~= yaw_speed_sign

	if has_overshot and yaw_offset_sign > 0 then
		new_yaw_speed = math.min(current_yaw_speed + deceleration * dt, 0)
	elseif has_overshot then
		new_yaw_speed = math.max(current_yaw_speed - deceleration * dt, 0)
	elseif yaw_offset_sign > 0 then
		if current_yaw_speed <= wanted_yaw_speed then
			new_yaw_speed = math.min(current_yaw_speed + acceleration * dt, wanted_yaw_speed)
		else
			new_yaw_speed = math.max(current_yaw_speed - deceleration * dt, wanted_yaw_speed)
		end
	elseif wanted_yaw_speed <= current_yaw_speed then
		new_yaw_speed = math.max(current_yaw_speed - acceleration * dt, wanted_yaw_speed)
	else
		new_yaw_speed = math.min(current_yaw_speed + deceleration * dt, wanted_yaw_speed)
	end

	return new_yaw_speed, lerped_pitch_speed
end)--]]

mod:hook(BTBotShootAction, "_aim_position", function (func, self, dt, t, self_unit, current_position, current_rotation, target_unit, shoot_blackboard)
	local projectile_info, projectile_speed, aim_at_node = nil

	if shoot_blackboard.charging_shot then
		projectile_info = shoot_blackboard.projectile_info_charged
		projectile_speed = shoot_blackboard.projectile_speed_charged
		aim_at_node = (shoot_blackboard.target_breed and shoot_blackboard.target_breed.override_bot_target_node) or shoot_blackboard.aim_at_node_charged
	else
		projectile_info = shoot_blackboard.projectile_info
		projectile_speed = shoot_blackboard.projectile_speed
		aim_at_node = (shoot_blackboard.target_breed and shoot_blackboard.target_breed.override_bot_target_node) or shoot_blackboard.aim_at_node
	end

	local wanted_rotation, aim_position = self:_wanted_aim_rotation(self_unit, target_unit, current_position, projectile_info, projectile_speed, aim_at_node)

	if not wanted_rotation then
		return nil, nil, nil, nil, nil
	end

	local current_yaw = Quaternion.yaw(current_rotation)
	local current_pitch = Quaternion.pitch(current_rotation)
	local wanted_yaw = Quaternion.yaw(wanted_rotation)
	local wanted_pitch = Quaternion.pitch(wanted_rotation)
	local yaw_speed, pitch_speed = self:_calculate_aim_speed(self_unit, dt, current_yaw, current_pitch, wanted_yaw, wanted_pitch, shoot_blackboard)
	shoot_blackboard.aim_speed_yaw = yaw_speed
	shoot_blackboard.aim_speed_pitch = pitch_speed
	local new_yaw = current_yaw + yaw_speed * dt
	local new_pitch = current_pitch + pitch_speed * dt
	local yaw_rot = Quaternion(Vector3.up(), new_yaw)
	local pitch_rot = Quaternion(Vector3.right(), new_pitch)
	local actual_rotation = Quaternion.multiply(yaw_rot, pitch_rot)
	local pi = math.pi
	local yaw_offset = (new_yaw - wanted_yaw + pi) % (pi * 2) - pi
	local pitch_offset = new_pitch - wanted_pitch

	return yaw_offset, pitch_offset, wanted_rotation, actual_rotation, aim_position
end)

local OUT_OF_RADIUS_TRESHOLD = math.pi / 12  -- (15 degrees)
mod:hook(BTBotShootAction, "_aim_good_enough", function(func, self, dt, t, shoot_blackboard, yaw_offset, pitch_offset, distance_squared) -- added distance_squared
	local bb = shoot_blackboard

	if bb.reevaluate_aim_time < t then
		local distance = math.sqrt(distance_squared)
		local fuzzyness = math.clamp(distance, 1, 50) -- depending on distance bots will aim more or less accurate

		--local improved_pitch_offset = pitch_offset * 2 -- to make bots aim more precisely in vertical axis
		local aim_data = (bb.charging_shot and bb.aim_data_charged) or bb.aim_data
		local offset = math.sqrt(pitch_offset * pitch_offset + yaw_offset * yaw_offset)

		local max_radius = aim_data.max_radius / 6 / fuzzyness -- 4
		local min_radius = aim_data.min_radius / 3 / fuzzyness -- 2

		if max_radius < offset then
			bb.aim_good_enough = false
			bb.num_aim_rolls = 0

			dprint("bad aim - offset:", offset)
		else
			local success = nil
			local num_rolls = bb.num_aim_rolls + 1

			if offset < min_radius then
				local prob = (aim_data.min_radius_pseudo_random_c + 0.05 / fuzzyness) * num_rolls
				success = Math.random() < prob
			else
				local prob = (math.auto_lerp(min_radius, max_radius, aim_data.min_radius_pseudo_random_c, aim_data.max_radius_pseudo_random_c, offset) + 0.01 / fuzzyness) * num_rolls
				success = Math.random() < prob
			end

			if success then
				bb.aim_good_enough = true
				bb.num_aim_rolls = 0

				dprint("fire! - offset:", offset, " num_rolls:", num_rolls)
			else
				bb.aim_good_enough = false
				bb.num_aim_rolls = num_rolls

				dprint("not yet - offset:", offset, " num_rolls:", num_rolls)
			end
		end

		local out_of_radius_treshold = math.max(OUT_OF_RADIUS_TRESHOLD, aim_data.max_radius)

		if out_of_radius_treshold < offset then -- for alternative shots
			bb.aim_out_of_radius = true
		else
			bb.aim_out_of_radius = false
		end

		bb.reevaluate_aim_time = t + 0.10
	end

	return bb.aim_good_enough
end)

mod:hook(BTBotShootAction, "_may_attack", function (func, self, unit, enemy_unit, shoot_blackboard, range_squared, t)
	local bb = BLACKBOARDS[enemy_unit]

	if not bb then
		return false
	end

	if script_data.ai_bots_disable_player_range_attacks and bb.is_player then
		return false
	end

	if not DamageUtils.is_enemy(unit, enemy_unit) then
		return false
	end

	if shoot_blackboard.doing_alternative_attack and shoot_blackboard.alternative_attack_start_t < t then -- added for alt. shots, they perform charging by their own after initiating
		return false
	end

	local charging = shoot_blackboard.charging_shot
	local sufficiently_charged = not shoot_blackboard.minimum_charge_time or (not shoot_blackboard.always_charge_before_firing and not charging) or (charging and shoot_blackboard.minimum_charge_time <= t - shoot_blackboard.charge_start_time)
	local max_range_squared = (charging and shoot_blackboard.max_range_squared_charged) or shoot_blackboard.max_range_squared
	local obstructed = shoot_blackboard:obstructed_by_enemy() or shoot_blackboard.hit_invalid_zone
	local may_fire = nil

	if bb.is_ai then
		may_fire = sufficiently_charged and not bb.hesitating and not bb.in_alerted_state and not obstructed and range_squared < max_range_squared
	else
		may_fire = sufficiently_charged and not obstructed and range_squared < max_range_squared
	end

	-- added hit_invalid_zone check

	return may_fire
end)

--------------------------------------------------------------------------------------------------------------------

mod:hook(BTBotShootAction, "_should_charge", function (func, self, shoot_blackboard, range_squared, target_unit, t)
	local next_charge_shot_t = shoot_blackboard.next_charge_shot_t

	if not shoot_blackboard.can_charge_shot or (next_charge_shot_t and t < next_charge_shot_t) then
		return false
	end

	if shoot_blackboard.doing_alternative_attack then
		return false
	end

	if shoot_blackboard.ignore_disabled_enemies_charged then
		local target_bb = BLACKBOARDS[target_unit]

		if target_bb.in_vortex then
			return false
		end
	end

	local max_range_squared_charged = shoot_blackboard.max_range_squared_charged

	if shoot_blackboard.max_range_squared_charged < range_squared and not shoot_blackboard.charge_when_outside_max_range_charged then
		return false
	end

	if shoot_blackboard:obstructed_by_enemy() then
		return shoot_blackboard.charge_when_obstructed and not shoot_blackboard.obstructed_charged_shot or false
	end

	local max_range_squared = shoot_blackboard.max_range_squared

	if max_range_squared < range_squared then
		return shoot_blackboard.charge_when_outside_max_range
	end

	if shoot_blackboard.always_charge_before_firing or shoot_blackboard.charging_shot then
		return true
	end

	if shoot_blackboard.charge_range_squared and shoot_blackboard.charge_range_squared < range_squared then
		return true
	end

	local target_breed = shoot_blackboard.target_breed

	if target_breed then 
		local target_breed_category_mask = target_breed.category_mask
		local normal_shot_util = bit.band(target_breed_category_mask, shoot_blackboard.effective_against)
		local charge_shot_util = bit.band(target_breed_category_mask, shoot_blackboard.effective_against_charged)
		local alternative_shot_util = bit.band(target_breed_category_mask, shoot_blackboard.effective_against_alternative)

		return normal_shot_util < charge_shot_util and alternative_shot_util <= charge_shot_util
	end

	return false
end)

mod:hook(BTBotShootAction, "_fire_shot", function (func, self, shoot_blackboard, action_data, input_extension, t)
	shoot_blackboard.fired = true

	if shoot_blackboard.charging_shot and not shoot_blackboard.uninterruptable_charge then
		shoot_blackboard.charging_shot = false
		shoot_blackboard.charge_start_time = math.huge
	end

	local input = action_data.fire_input or shoot_blackboard.fire_input

	if input_extension and input and input ~= "none" then
		input_extension[input](input_extension)
	end

	if shoot_blackboard.charge_shot_delay then
		shoot_blackboard.next_charge_shot_t = t + shoot_blackboard.charge_shot_delay
	end
end)

local THREAT_DISTANCE = 10
mod:hook(BTBotShootAction, "_charge_shot", function (func, self, shoot_blackboard, action_data, input_extension, t, closest_enemy_dist)
	if not shoot_blackboard.charging_shot then
		shoot_blackboard.charge_start_time = t
		shoot_blackboard.charging_shot = true
	end

	local input = action_data.charge_input or shoot_blackboard.charge_input

	local charge_input_threat = shoot_blackboard.charge_input_threat -- added for activate abilities

	if charge_input_threat and closest_enemy_dist and closest_enemy_dist < THREAT_DISTANCE then
		input = charge_input_threat
	end

	if input_extension and input and input ~= "none" then
		input_extension[input](input_extension)
	end
end)

BTBotShootAction._update_target  = function(self, blackboard, shoot_bb, t)
	local bb_target = blackboard.target_unit
	local shoot_bb_target = shoot_bb.target_unit

	local bb_target_valid = bb_target and mod.is_unit_alive(bb_target)
	local shoot_bb_target_valid = shoot_bb_target and mod.is_unit_alive(shoot_bb_target)

	if not shoot_bb.disable_target_change and bb_target and bb_target_valid and bb_target ~= shoot_bb_target then
		self:_set_new_aim_target(shoot_bb, bb_target, t)

		return bb_target
	end

	return shoot_bb_target_valid and shoot_bb_target or nil
end

BTBotShootAction._should_use_alternative_attack = function(self, shoot_blackboard, range_squared, target_unit, t)
	if not shoot_blackboard.has_alternative_shot then
		return false
	end

	if shoot_blackboard.doing_alternative_attack then
		return true
	end

	if shoot_blackboard.ignore_disabled_enemies_alternative then
		local target_bb = BLACKBOARDS[target_unit]

		if target_bb.in_vortex then
			return false
		end
	end

	local max_range_squared_alternative = shoot_blackboard.max_range_squared_alternative

	if max_range_squared_alternative < range_squared then
		return false
	end

	if shoot_blackboard:obstructed_by_enemy() then
		return shoot_blackboard.alternative_when_obstructed or false
	end

	if shoot_blackboard.always_use_alternative_attack then
		return true
	end

	local target_breed = shoot_blackboard.target_breed

	if target_breed then
		local target_breed_category_mask = target_breed.category_mask
		local normal_shot_util = bit.band(target_breed_category_mask, shoot_blackboard.effective_against)
		local charge_shot_util = bit.band(target_breed_category_mask, shoot_blackboard.effective_against_charged)
		local alternative_shot_util = bit.band(target_breed_category_mask, shoot_blackboard.effective_against_alternative)

		return normal_shot_util < alternative_shot_util and charge_shot_util < alternative_shot_util
	end

	return false
end

BTBotShootAction._alternative_shot = function(self, shoot_blackboard, action_data, input_extension, t)

	-- initiate alt. attack

	if not shoot_blackboard.doing_alternative_attack then
		local min_charge_time = shoot_blackboard.alternative_attack_min_charge_time
		local max_charge_time = shoot_blackboard.alternative_attack_max_charge_time

		alternative_charge_time = min_charge_time + Math.random() * (max_charge_time - min_charge_time)

		shoot_blackboard.alternative_attack_start_t = t + alternative_charge_time
		shoot_blackboard.doing_alternative_attack = true
	end

	-- make alt. attack charging and alt. input

	if shoot_blackboard.doing_alternative_attack then
		local aim_out_of_radius = shoot_blackboard.aim_out_of_radius
		local is_obstructed = shoot_blackboard:obstructed_by_enemy() or shoot_blackboard.hit_invalid_zone
		local alt_attack_start_t = shoot_blackboard.alternative_attack_start_t
		local alt_attack_charging = (t < alt_attack_start_t)

		if aim_out_of_radius or is_obstructed then 	-- discard bad shot
			self:_discard_shot(input_extension, shoot_blackboard, action_data)

		elseif alt_attack_charging then 			-- charge alt. attack
			self:_fire_shot(shoot_blackboard, action_data, input_extension, t)

		else										-- perform alt. input, only after charging enough
			local input = shoot_blackboard.alternative_input
			local alt_input_duration = shoot_blackboard.alternative_input_duration
			local alt_attack_duration = shoot_blackboard.alternative_attack_duration

			if input and t <= alt_attack_start_t + alt_input_duration then -- make alt. input, can be less than total alt. shot duration or equal to it ('all time input')
				if input_extension and input and input ~= "none" then
					input_extension[input](input_extension)
				end
			end

			if alt_attack_start_t + alt_attack_duration <= t then -- just wait more time if needed, f.e. to prevent interruption of shot animation with new shots
				shoot_blackboard.doing_alternative_attack = false
				shoot_blackboard.fired = false
			end
		end
	end
end

BTBotShootAction._should_disengage  = function(self, blackboard, shoot_blackboard, target_breed, t)
	local breed_distance_override = target_breed and target_breed.bots_stay_ranged
	local ranged_combat_preferred = blackboard.ranged_combat_preferred

	return (breed_distance_override and not shoot_blackboard:obstructed_by_enemy()) or shoot_blackboard.keep_distance or ranged_combat_preferred
end

mod:hook(BTBotShootAction, "_update_disengage_position", function (func, self, blackboard, target_breed, t)
	if blackboard.shoot.disengage_update_time < t then
		local first_person_ext = blackboard.first_person_extension
		local self_position = first_person_ext:current_position()
		local shoot_bb = blackboard.shoot
		local keep_distance = (target_breed and target_breed.bots_stay_ranged) or shoot_bb.keep_distance or 6
		local keep_distance_sq = keep_distance * keep_distance
		local num_close_targets = 0
		local disengage_vector = Vector3.zero()
		local proximite_enemies = blackboard.proximite_enemies

		if proximite_enemies then
			for i = 1, #proximite_enemies, 1 do
				local result = get_disengage_vector(self_position, proximite_enemies[i], keep_distance, keep_distance_sq)

				if result then
					num_close_targets = num_close_targets + 1
					disengage_vector = disengage_vector + result
				end
			end
		end

		local self_unit = blackboard.unit
		local target_unit = shoot_bb.target_unit
		local target_bb = BLACKBOARDS[target_unit]
		if target_unit and not (target_breed and target_bb and target_breed.boss and target_bb.target_unit == self_unit) then -- added check for bosses, attempt to make bots not to disengage if boss is attacking them
			local result = get_disengage_vector(self_position, target_unit, keep_distance, keep_distance_sq)

			if result then
				num_close_targets = num_close_targets + 1
				disengage_vector = disengage_vector + result
			end
		end

		local disengage_position, should_stop = nil

		if num_close_targets > 0 then
			local nav_world = blackboard.nav_world
			disengage_vector = Vector3.divide(disengage_vector, num_close_targets)
			disengage_position = get_disengage_pos(nav_world, self_position, disengage_vector, Vector3.length(disengage_vector))
		end

		local interval = 1

		if disengage_position then
			local override_box = blackboard.navigation_destination_override
			local override_destination = override_box:unbox()
			local distance = Vector3.distance(self_position, disengage_position)
			local disengage_distance_delta = Vector3.distance_squared(disengage_position, override_destination)

			if distance > 0.01 and disengage_distance_delta > 0.01 then
				override_box:store(disengage_position)

				shoot_bb.disengage_position_set = true
				shoot_bb.stop_at_current_position = should_stop
			else
				shoot_bb.disengage_position_set = false
			end

			local min_dist = 5
			local max_dist = 10
			interval = math.auto_lerp(min_dist, max_dist, 0.5, 1, math.clamp(distance, min_dist, max_dist)) -- old limits: 0.5, 2
		else
			shoot_bb.disengage_position_set = false
		end

		shoot_bb.disengage_update_time = t + interval
	end
end)

BTBotShootAction._can_hold_fire = function(self, blackboard, shoot_bb, t)
	local should_hold_fire = shoot_bb.hold_fire_condition and shoot_bb.hold_fire_condition(t, blackboard)
	local can_hold_fire = should_hold_fire

	if should_hold_fire then
		if not shoot_bb.hold_fire_start_t then
			shoot_bb.hold_fire_start_t = t
		elseif shoot_bb.max_hold_fire_duration and shoot_bb.hold_fire_start_t + shoot_bb.max_hold_fire_duration < t then
			can_hold_fire = false
			shoot_bb.hold_fire_start_t = nil
			shoot_bb.fired = false
		end
	end

	return can_hold_fire
end

BTBotShootAction._update_evaluation = function(self, ordinary_evaluation, shoot_blackboard, action_data, t)
	local fired = shoot_blackboard.fired and not shoot_blackboard.doing_alternative_attack

	local evaluate = ordinary_evaluation and (fired and shoot_blackboard.next_evaluate < t or shoot_blackboard.next_evaluate_without_firing < t)

	if evaluate then
		shoot_blackboard.next_evaluate = t + action_data.evaluation_duration
		shoot_blackboard.next_evaluate_without_firing = t + action_data.evaluation_duration_without_firing
		shoot_blackboard.fired = false
	end

	return evaluate
end

mod:hook(BTBotShootAction, "_aim", function (func, self, unit, blackboard, dt, t)
	-- *return true* causes _leave() shoot action
	-- *return false, true* (or 'evaluate') causes _leave() shoot action; I don't know if it is the same as *return true*, but it seems like they are very similar

	local shoot_bb = blackboard.shoot
	local target_unit = self:_update_target(blackboard, shoot_bb, t) -- changed, not the prefered target is shoot_bb target, not main blackboard one

	if not target_unit then
		return true
	end
	------
	------

	if self:_should_disengage(blackboard, shoot_bb, shoot_bb.target_breed, t) then -- fixed to make it work, originally the disengage_position_set was turned off the next frame it even was turned on, so doesn't work at all
		self:_update_disengage_position(blackboard, shoot_bb.target_breed, t)
	end

	------

	local action_data = self._tree_node.action_data
	local first_person_ext = blackboard.first_person_extension
	local camera_position = first_person_ext:current_position()
	local camera_rotation = first_person_ext:current_rotation()

	local yaw_offset,
		  pitch_offset,
		  wanted_aim_rotation,
		  actual_aim_rotation,
		  actual_aim_position = self:_aim_position(dt, t, unit, camera_position, camera_rotation, target_unit, shoot_bb)

	if not actual_aim_rotation then
		local evaluate = self:_update_evaluation(true, shoot_bb, action_data, t)

		return false, evaluate
	end

	------
	------
	self:_reevaluate_obstruction(unit, blackboard, shoot_bb, action_data, t, camera_position, wanted_aim_rotation, unit, target_unit, actual_aim_position, blackboard.priority_target_enemy, blackboard.target_ally_unit, blackboard.target_ally_needs_aid, blackboard.target_ally_need_type)
	-- all checks, timers, assignments and other replaced inside the function

	if shoot_bb.obstructed_by_static then -- added, originally it was waiting for condition function to abort action 'from outside', now it breaks invalid shots straightaway
		return true
	end
	------
	------

	-- added aoe threat check, now for abilities only
	if shoot_bb.do_not_shoot_in_aoe_threat then
		local ai_bot_group_extension = shoot_bb.ai_bot_group_extension or ScriptUnit.extension(unit, "ai_bot_group_system")

		local threat_data = ai_bot_group_extension and ai_bot_group_extension.data.aoe_threat
		local is_in_aoe_threat = threat_data and t < threat_data.expires

		if is_in_aoe_threat then
			return true
		end
	end

	------

	local input_ext = blackboard.input_extension
	local range_squared = Vector3.distance_squared(camera_position, actual_aim_position)

	local closest_enemy_dist = math.min(blackboard.target_dist, blackboard.proximity_target_distance) -- it is 'raw version', just for now - needed for shoot abilities and dodges

	if self:_should_charge(shoot_bb, range_squared, target_unit, t) then
		self:_charge_shot(shoot_bb, action_data, input_ext, t, closest_enemy_dist) -- added "threat input" for ability shots
	end

	------

	input_ext:set_aim_rotation(actual_aim_rotation)

	------

	if self:_aim_good_enough(dt, t, shoot_bb, yaw_offset, pitch_offset, range_squared) and self:_may_attack(unit, target_unit, shoot_bb, range_squared, t) then
		self:_fire_shot(shoot_bb, action_data, input_ext, t)
	end

	------

	if shoot_bb.fired and self:_should_use_alternative_attack(shoot_bb, range_squared, target_unit, t) then -- absolutely new, for abilities and staff blast beam
		self:_alternative_shot(shoot_bb, action_data, input_ext, t)
	end

	------

	-- if shoot_bb.fired and shoot_bb.dodge_while_firing then -- for now works only for some shoot abilities
		-- if closest_enemy_dist < 4.5 then
			-- input_ext:dodge()
		-- end
	-- end

	------

	local ordinary_evaluation = true

	if self:_can_hold_fire(blackboard, shoot_bb, t) then -- changed, look inside function - now hold fire can be interrupted after some max time
		self:_fire_shot(shoot_bb, action_data, input_ext, t)

		ordinary_evaluation = false
	end

	------
	------

	-- replaced to a method and added a bit
	local evaluate = self:_update_evaluation(ordinary_evaluation, shoot_bb, action_data, t)


	--Vernon: Let bots dodge while using ranged weapons
	--only check non-AoE attacks only, as AoE attacks should be handled by threat box system
	--meh, i will just copy the whole _defend function for now
	local self_unit		= unit
	local prox_enemies = mod.get_proximite_enemies(self_unit, 8, 3.8)	--7, 3.8	--7, 3
	
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

	return false, evaluate
end)

mod:hook(BTBotShootAction, "_update_collision_filter", function(func, self, target_unit, shoot_blackboard, priority_target_enemy, target_ally_unit, target_ally_needs_aid, need_type)
	-- I think filtering enemies is needed for some weapons, but allies - not, so I exluded the last one
	local attack_meta_data = shoot_blackboard.attack_meta_data
	local target_bb = BLACKBOARDS[target_unit]
	local has_important_target = target_unit == priority_target_enemy or (target_ally_needs_aid and (need_type == "hook" or need_type == "knocked_down" or need_type == "ledge") and target_bb and target_bb.target_unit == target_ally_unit)

	if has_important_target then
		shoot_blackboard.collision_filter = "filter_bot_ranged_line_of_sight_no_allies_no_enemies"
		shoot_blackboard.collision_filter_charged = "filter_bot_ranged_line_of_sight_no_allies_no_enemies"

		return
	end

	local ignore_enemies_for_obstruction = attack_meta_data.ignore_enemies_for_obstruction
	local ignore_enemies_for_obstruction_charged = (attack_meta_data.ignore_enemies_for_obstruction_charged == nil and ignore_enemies_for_obstruction) or attack_meta_data.ignore_enemies_for_obstruction_charged

	shoot_blackboard.collision_filter = (ignore_enemies_for_obstruction and "filter_bot_ranged_line_of_sight_no_allies_no_enemies") or "filter_bot_ranged_line_of_sight_no_allies"
	shoot_blackboard.collision_filter_charged = (ignore_enemies_for_obstruction_charged and "filter_bot_ranged_line_of_sight_no_allies_no_enemies") or "filter_bot_ranged_line_of_sight_no_allies"
end)

BTBotShootAction._update_blackboard_ostruction  = function(self, blackboard, shoot_blackboard, obstructed, t)
	-- just original code replaced to separate method
	if obstructed then
		if not blackboard.ranged_obstruction_by_static then
			blackboard.ranged_obstruction_by_static = {
				unit = shoot_blackboard.target_unit,
				timer = t
			}
		else
			local obstructed_by_static = blackboard.ranged_obstruction_by_static
			obstructed_by_static.unit = shoot_blackboard.target_unit
			obstructed_by_static.timer = t
		end

		return true
	else
		blackboard.ranged_obstruction_by_static = nil
	end
end

local INDEX_POSITION = 1
local INDEX_DISTANCE = 2
local INDEX_NORMAL = 3
local INDEX_ACTOR = 4
-- "clever" obstruction check
local calculate_obstruction = function(physics_world, from, to, ignore_unit, aim_unit, aim_zones, check_spread, collision_filter)
	local offset = to - from
	local distance = Vector3.length(offset)
	local direction = Vector3.normalize(offset)

	if distance < 0.001 or Vector3.length_squared(direction) < 0.000001 then
		return false
	end

	PhysicsWorld.prepare_actors_for_raycast(physics_world, from, direction, 0.01, check_spread, distance * distance)
	local raycast_hits = PhysicsWorld.immediate_raycast(physics_world, from, direction, distance, "all", "collision_filter", collision_filter)

	local obstructed_by_enemy = nil
	local obstruction_enemy_to_target_dist = nil
	local obstructed_by_static = false
	local hit_invalid_zone = nil

	if raycast_hits then
		local num_hits = #raycast_hits

		for i = 1, num_hits, 1 do
			local hit = raycast_hits[i]
			local hit_actor = hit[INDEX_ACTOR]
			local hit_unit = Actor.unit(hit_actor)
			local hit_zone_name = DamageUtils.hit_zone(hit_unit, hit_actor)

			if hit_unit == aim_unit then
				if hit_zone_name ~= "afro" then
					if aim_zones and hit_invalid_zone == nil then
						hit_invalid_zone = not aim_zones[hit_zone_name] and not (hit_zone_name == "full")
					end

					obstructed_by_enemy = false
				end
			elseif hit_unit ~= ignore_unit then
				if Actor.is_static(hit_actor) then
					obstructed_by_static = true
				elseif obstructed_by_enemy == nil and hit_zone_name ~= "afro" then
					obstructed_by_enemy = true
					obstruction_enemy_to_target_dist = distance - hit[INDEX_DISTANCE]
				end
			end
		end
	end

	return obstructed_by_enemy, obstruction_enemy_to_target_dist, obstructed_by_static, hit_invalid_zone
end

mod:hook(BTBotShootAction, "_is_shot_obstructed", function (func, self, physics_world, shoot_blackboard, from, direction, self_unit, target_unit, actual_aim_position, collision_filter)
	local hit_zones = shoot_blackboard.hit_only_zones

	return calculate_obstruction(physics_world, from, actual_aim_position, self_unit, target_unit, hit_zones, 0.5, collision_filter)
	-- now it can check if raycast hits needed hit_zone or not ("head" and "neck" for kerillian piercing shot)
end)

mod:hook(BTBotShootAction, "_reevaluate_obstruction", function (func, self, unit, blackboard, shoot_blackboard, action_data, t, ray_from, wanted_aim_rotation, self_unit, target_unit, actual_aim_position, priority_target_enemy, target_ally_unit, target_ally_needs_aid, target_ally_need_type)
	-- now the reevaluate timer is here, inside the function
	if shoot_blackboard.reevaluate_obstruction_time <= t then
		local min = action_data.minimum_obstruction_reevaluation_time
		local max = action_data.maximum_obstruction_reevaluation_time
		shoot_blackboard.reevaluate_obstruction_time = t + min + Math.random() * (max - min)

		self:_update_collision_filter(target_unit, shoot_blackboard, priority_target_enemy, target_ally_unit, target_ally_needs_aid, target_ally_need_type)

		local direction = Quaternion.forward(wanted_aim_rotation)
		local physics_world = World.get_data(blackboard.world, "physics_world")
		local collision_filter = (shoot_blackboard.charging_shot and shoot_blackboard.collision_filter_charged) or shoot_blackboard.collision_filter
		local obstructed_by_enemy, distance_from_target, obstructed_by_static, hit_invalid_zone = self:_is_shot_obstructed(physics_world, shoot_blackboard, ray_from, direction, unit, target_unit, actual_aim_position, collision_filter)

		local obstructed_fire_shot = obstructed_by_enemy
		local obstructed_charged_shot = obstructed_by_enemy

		if obstructed_by_enemy then
			local fuzzyness = shoot_blackboard.obstruction_fuzzyness_rang
			local fuzzyness_charged = shoot_blackboard.obstruction_fuzzyness_range_charged

			if fuzzyness and distance_from_target <= fuzzyness then
				obstructed_fire_shot = false
			end

			if fuzzyness_charged and distance_from_target <= fuzzyness_charged then
				obstructed_charged_shot = false
			end
		end

		self:_update_blackboard_ostruction(blackboard, shoot_blackboard, obstructed_by_static, t)

		shoot_blackboard.obstructed_fire_shot = obstructed_fire_shot
		shoot_blackboard.obstructed_charged_shot = obstructed_charged_shot
		shoot_blackboard.obstructed_by_static = obstructed_by_static
		shoot_blackboard.hit_invalid_zone = hit_invalid_zone
	end

	-- no more return needed
end)


