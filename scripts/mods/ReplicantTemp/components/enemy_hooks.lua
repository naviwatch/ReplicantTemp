local mod = get_mod("ReplicantTemp")



--Halescourege teleport to center flag
--now in player_bot_base.lua
--[[
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/54867e3cd2a1ec152433a090ce9057a3fbd039eb/scripts/entity_system/systems/behaviour/nodes/bt_enter_hooks.lua#L378

mod.last_halescourege_teleport_time = nil
mod:hook(BTEnterHooks, "teleport_to_center", function(func, unit, blackboard, t)	
	mod.last_halescourege_teleport_time = t
	
	return func(unit, blackboard, t)
end)
--]]


--Ratling fire threat box now triggers block and dodge so make it smaller
mod:hook_origin(BTRatlingGunnerShootAction, "_create_bot_threat_box", function(self, unit, attack_data, duration)
	local self_pos = POSITION_LOOKUP[unit]
	local target_pos = POSITION_LOOKUP[attack_data.target_unit]

	if self_pos and target_pos then
		local to_target = target_pos - self_pos
		local distance = Vector3.length(to_target)
		
		distance = math.min(distance, 2.7)	--1.5	--2		--3.5	--slightly longer than dodge distance to encourage side dodge
		
		local obstacle_position, obstacle_rotation, obstacle_size = AiUtils.calculate_oobb(distance * 2, self_pos, Quaternion.look(to_target))
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")

		ai_bot_group_system:aoe_threat_created(obstacle_position, "oobb", obstacle_size, obstacle_rotation, duration)
	end
end)



--Register swarm projectiles (Halescourge / Blood in the Darkness / Enchanter's Lair)
--now in player_bot_base.lua
--[[
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/95f497c2ad65b1a3454a2f9531dd868856ec7878/scripts/unit_extensions/weapons/projectiles/player_projectile_unit_extension.lua#L235
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/95f497c2ad65b1a3454a2f9531dd868856ec7878/scripts/entity_system/systems/projectile_locomotion/projectile_locomotion_system.lua#L77

--insect_swarm_missile_01
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/master/scripts/entity_system/systems/behaviour/nodes/chaos_sorcerer/bt_cast_missile_action.lua
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/54867e3cd2a1ec152433a090ce9057a3fbd039eb/scripts/unit_extensions/weapons/projectiles/true_flight_templates.lua#L117
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/6c69aa3488cf7259b6eae5e66f8100d7895df34b/scripts/unit_extensions/weapons/projectiles/projectile_true_flight_locomotion_extension.lua#L812
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/95f497c2ad65b1a3454a2f9531dd868856ec7878/scripts/unit_extensions/human/ai_player_unit/ai_breed_snippets.lua#L891
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/95f497c2ad65b1a3454a2f9531dd868856ec7878/scripts/settings/explosion_templates.lua#L1180
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/c0bfbb87d92fb0aa10804260d6f39f4bdda5cb9e/scripts/settings/breeds/breed_chaos_exalted_sorcerer.lua#L826

mod.swarm_projectile_list = {}
mod:hook(UnitSpawner, "spawn_network_unit", function(func, self, unit_name, unit_template_name, extension_init_data, position, rotation, material)
	local unit, go_id = func(self, unit_name, unit_template_name, extension_init_data, position, rotation, material)

	if unit_name == "units/weapons/projectile/insect_swarm_missile/insect_swarm_missile_01" or
		unit_name == "units/weapons/projectile/insect_swarm_missile_drachenfels/insect_swarm_missile_drachenfels_01" then
		
		mod.swarm_projectile_list[unit] = true
	end

	return unit, go_id
end)
--]]



--Poison globe landing prediction
mod:hook_origin(BTAdvanceTowardsPlayersAction, "_calculate_trajectory_to_target", function (self, unit, world, blackboard, action)
	local curr_pos = Vector3.copy(POSITION_LOOKUP[unit])
	local rot = LocomotionUtils.rotation_towards_unit_flat(unit, blackboard.target_unit)
	local x, y, z = unpack(action.attack_throw_offset)
	local pos = Vector3(x, y, z)
	local throw_offset = Quaternion.rotate(rot, pos)
	local throw_pos = curr_pos + throw_offset
	curr_pos.z = throw_pos.z
	local root_to_throw = throw_pos - curr_pos
	local direction = Vector3.normalize(root_to_throw)
	local length = Vector3.length(root_to_throw)
	local physics_world = World.get_data(world, "physics_world")
	local result = PhysicsWorld.immediate_raycast(physics_world, curr_pos, direction, length, "closest", "collision_filter", "filter_enemy_ray_projectile")

	if result then
		return false
	end

	local radius = action.radius - 1
	local max_distance = action.range
	local target_position = PerceptionUtils.pick_area_target(unit, blackboard, nil, radius, max_distance)
	local target_vector = Vector3.normalize(target_position - throw_pos)
	local hit, angle, speed = WeaponHelper:calculate_trajectory(world, throw_pos, target_position, ProjectileGravitySettings.default, blackboard.breed.max_globe_throw_speed)

	if hit then
		blackboard.throw_globe_data = blackboard.throw_globe_data or {
			throw_pos = Vector3Box(),
			target_direction = Vector3Box()
		}
		blackboard.throw_globe_data.angle = angle
		blackboard.throw_globe_data.speed = speed

		blackboard.throw_globe_data.throw_pos:store(throw_pos)
		blackboard.throw_globe_data.target_direction:store(target_vector)
		--edit start--
		blackboard.throw_globe_data.target_position = blackboard.throw_globe_data.target_position or Vector3Box()
		blackboard.throw_globe_data.target_position:store(target_position)
		blackboard.throw_globe_data.target_distance = Vector3.distance(throw_pos, target_position)
		--edit end--
	end

	return hit
end)

mod.bot_poison_wind_prediction_ids = {}
mod:hook_origin(ProjectileSystem, "spawn_globadier_globe", function (self, position, target_vector, angle, speed, initial_radius, radius, duration, owner_unit, damage_source, aoe_dot_damage, aoe_init_damage, aoe_dot_damage_interval, create_nav_tag_volume, instant_explosion, fixed_impact_data)
	if self.is_server then
		local nav_tag_volume_layer = create_nav_tag_volume and "bot_poison_wind" or nil
		local is_versus = Managers.mechanism:current_mechanism_name() == "versus"

		if instant_explosion then
			local extension_init_data = {
				area_damage_system = {
					area_ai_random_death_template = "area_poison_ai_random_death",
					damage_players = true,
					dot_effect_name = "fx/wpnfx_poison_wind_globe_impact",
					extra_dot_effect_name = "fx/chr_gutter_death",
					invisible_unit = true,
					player_screen_effect_name = "fx/screenspace_poison_globe_impact",
					aoe_dot_damage = aoe_dot_damage,
					aoe_init_damage = aoe_init_damage,
					aoe_dot_damage_interval = aoe_dot_damage_interval,
					radius = radius,
					initial_radius = initial_radius,
					life_time = duration,
					area_damage_template = is_versus and "globadier_area_dot_damage_vs" or "globadier_area_dot_damage",
					damage_source = damage_source,
					create_nav_tag_volume = create_nav_tag_volume,
					nav_tag_volume_layer = nav_tag_volume_layer,
					source_attacker_unit = owner_unit,
					threat_duration = duration,
				},
			}
			local aoe_unit_name = "units/weapons/projectile/poison_wind_globe/poison_wind_globe"
			local aoe_unit = Managers.state.unit_spawner:spawn_network_unit(aoe_unit_name, "aoe_unit", extension_init_data, position)
			local unit_id = Managers.state.unit_storage:go_id(aoe_unit)

			Unit.set_unit_visibility(aoe_unit, false)
			Managers.state.network.network_transmit:send_rpc_all("rpc_area_damage", unit_id, position)
		else
			local extension_init_data = {
				projectile_locomotion_system = {
					trajectory_template_name = "throw_trajectory",
					angle = angle,
					speed = speed,
					target_vector = target_vector,
					initial_position = position,
				},
				projectile_system = {
					damage_source = damage_source,
					impact_template_name = is_versus and "vs_globadier_impact" or "explosion_impact",
					owner_unit = owner_unit,
				},
				area_damage_system = {
					area_ai_random_death_template = "area_poison_ai_random_death",
					damage_players = true,
					invisible_unit = false,
					player_screen_effect_name = "fx/screenspace_poison_globe_impact",
					aoe_dot_damage = aoe_dot_damage,
					aoe_init_damage = aoe_init_damage,
					aoe_dot_damage_interval = aoe_dot_damage_interval,
					radius = radius,
					initial_radius = initial_radius,
					life_time = duration,
					dot_effect_name = is_versus and "fx/wpnfx_poison_wind_globe_impact_vs" or "fx/wpnfx_poison_wind_globe_impact",
					area_damage_template = is_versus and "globadier_area_dot_damage_vs" or "globadier_area_dot_damage",
					damage_source = damage_source,
					create_nav_tag_volume = create_nav_tag_volume,
					nav_tag_volume_layer = nav_tag_volume_layer,
					source_attacker_unit = owner_unit,
					owner_player = Managers.player:owner(owner_unit),
					threat_duration = duration,
				},
			}
			local unit_template = nil

			if fixed_impact_data then
				extension_init_data.projectile_impact_system = {
					owner_unit = owner_unit,
					impact_data = fixed_impact_data
				}
				unit_template = "aoe_projectile_unit_fixed_impact"
			else
				extension_init_data.projectile_impact_system = {
					server_side_raycast = true,
					collision_filter = "filter_enemy_ray_projectile",
					owner_unit = owner_unit
				}
				unit_template = "aoe_projectile_unit"
			end

			local projectile_unit_name = "units/weapons/projectile/poison_wind_globe/poison_wind_globe"
			
			--edit start--
			-- Managers.state.unit_spawner:spawn_network_unit(projectile_unit_name, unit_template, extension_init_data, position)
			local projectile_unit = Managers.state.unit_spawner:spawn_network_unit(projectile_unit_name, unit_template, extension_init_data, position)
			
			local volume_system = Managers.state.entity:system("volume_system")
			local blackboard = owner_unit and BLACKBOARDS[owner_unit]
			local target_position = blackboard and blackboard.throw_globe_data and blackboard.throw_globe_data.target_position and blackboard.throw_globe_data.target_position.unbox and blackboard.throw_globe_data.target_position:unbox()
			if target_position and volume_system then
				mod.bot_poison_wind_prediction_ids[projectile_unit] = {
					-- id = volume_system:create_nav_tag_volume_from_data(target_position, radius, nav_tag_volume_layer),
					expires_at = Managers.time:time("game") + 5,
				}
				mod.bot_poison_wind_prediction_ids[projectile_unit].id = volume_system:create_nav_tag_volume_from_data(target_position, radius, nav_tag_volume_layer)
			end
			--edit end--
		end
	else
		local owner_unit_id = self.unit_storage:go_id(owner_unit)
		local damage_source_id = NetworkLookup.damage_sources[damage_source]
		local fixed_impact, hit_unit_id = nil

		if fixed_impact_data then
			local hit_unit = fixed_impact_data.hit_unit
			hit_unit_id = self.network_manager:game_object_or_level_id(hit_unit)
			fixed_impact = hit_unit_id ~= nil
		end

		if fixed_impact then
			print("fixed impact!")

			local hit_position = fixed_impact_data.position:unbox()
			local direction = fixed_impact_data.direction:unbox()
			local hit_normal = fixed_impact_data.hit_normal:unbox()
			local actor_index = fixed_impact_data.actor_index
			local time = fixed_impact_data.time

			self.network_transmit:send_rpc_server("rpc_spawn_globadier_globe_fixed_impact", position, target_vector, angle, speed, initial_radius, radius, duration, owner_unit_id, damage_source_id, aoe_dot_damage, aoe_init_damage, aoe_dot_damage_interval, create_nav_tag_volume, instant_explosion, hit_unit_id, hit_position, direction, hit_normal, actor_index, time)
		else
			print("Standard impact!")
			self.network_transmit:send_rpc_server("rpc_spawn_globadier_globe", position, target_vector, angle, speed, initial_radius, radius, duration, owner_unit_id, damage_source_id, aoe_dot_damage, aoe_init_damage, aoe_dot_damage_interval, create_nav_tag_volume, instant_explosion)
		end
	end
end)

mod:hook(AreaDamageExtension, "start_area_damage", function (func, self)
	func(self)
	
	if self.unit and mod.bot_poison_wind_prediction_ids[self.unit] then
		local volume_system = Managers.state.entity:system("volume_system")

		if mod.bot_poison_wind_prediction_ids[self.unit].id then
			volume_system:destroy_nav_tag_volume(mod.bot_poison_wind_prediction_ids[self.unit].id)
		end
		mod.bot_poison_wind_prediction_ids[self.unit] = nil
	end
end)

--enlarge poison cloud nav tag volume
mod:hook(VolumeSystem, "create_nav_tag_volume_from_data", function (func, self, pos, size, layer_name)
	if layer_name == "bot_poison_wind" and size then
		size = size + 0.6
	end

	return func(self, pos, size, layer_name)
end)

--remove expired bot_poison_wind nav tag volume in mod.update



--Attempt to dodge packmasters better
mod:hook_origin(BTPackMasterAttackAction, "attack", function (self, unit, t, dt, blackboard)
	local action = blackboard.action
	local locomotion_extension = blackboard.locomotion_extension

	if blackboard.move_state ~= "attacking" then
		blackboard.move_state = "attacking"

		locomotion_extension:use_lerp_rotation(true)
		LocomotionUtils.set_animation_driven_movement(unit, true, false, true)
		Managers.state.network:anim_event(unit, action.attack_anim)

		blackboard.attack_time_ends = t + action.attack_anim_duration
		blackboard.create_bot_threat_at = t + 0.2	--action.bot_threat_start_time
	end

	local rotation = LocomotionUtils.rotation_towards_unit(unit, blackboard.target_unit)

	locomotion_extension:set_wanted_rotation(rotation)

	if blackboard.create_bot_threat_at and blackboard.create_bot_threat_at < t then
		self:create_bot_threat(unit, blackboard, t)

		blackboard.create_bot_threat_at = nil
	end

	if not blackboard.attack_time_ends or blackboard.attack_time_ends < t then
		blackboard.attack_aborted = true
	end
end)

mod:hook_origin(BTPackMasterAttackAction, "create_bot_threat", function (self, unit, blackboard, t)
	local action = blackboard.action
	local self_pos = POSITION_LOOKUP[unit]
	local to_target = POSITION_LOOKUP[blackboard.target_unit] - self_pos
	local distance = Vector3.length(to_target)
	local width = action.dodge_distance
	local obstacle_position, obstacle_rotation, obstacle_size = AiUtils.calculate_oobb(distance + 4, self_pos, Quaternion.look(to_target), 2.5, 2.5)
	local bot_threat_duration = blackboard.attack_time_ends - t
	local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
	
	ai_bot_group_system:aoe_threat_created(obstacle_position, "oobb", obstacle_size, obstacle_rotation, bot_threat_duration)
end)



--Add threat box to Leech grab
BTCorruptorGrabAction._create_bot_threat_box = function(self, unit, target_unit, duration)
	local self_pos = POSITION_LOOKUP[unit]
	local target_pos = target_unit and POSITION_LOOKUP[target_unit]
	
	if self_pos and target_pos then
		local to_target = target_pos - self_pos
		local distance = Vector3.length(to_target)
		
		local obstacle_position, obstacle_rotation, obstacle_size = AiUtils.calculate_oobb(distance + 4, self_pos, Quaternion.look(to_target), 2.5, 1.5)
		local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		
		ai_bot_group_system:aoe_threat_created(obstacle_position, "oobb", obstacle_size, obstacle_rotation, duration)
	end
end

local bot_threat_duration = 0.55
local bot_threat_start_time = 0.2
mod:hook_origin(BTCorruptorGrabAction, "attack", function (self, unit, t, dt, blackboard)
	local action = blackboard.action
	local locomotion_extension = blackboard.locomotion_extension
	local corruptor_target = blackboard.corruptor_target
	local self_pos = POSITION_LOOKUP[unit] + Vector3.up()
	local target_unit_pos = POSITION_LOOKUP[corruptor_target] + Vector3.up()
	local world = blackboard.world
	local physics_world = World.physics_world(world)
	local is_target_in_line_of_sight = PerceptionUtils.is_position_in_line_of_sight(unit, self_pos, target_unit_pos, physics_world)

	if is_target_in_line_of_sight then
		if blackboard.move_state ~= "attacking" then
			blackboard.move_state = "attacking"

			locomotion_extension:use_lerp_rotation(true)
			LocomotionUtils.set_animation_driven_movement(unit, true, false, true)
			Managers.state.network:anim_event(unit, action.attack_anim)
			
			blackboard.create_bot_threat_at = t + bot_threat_start_time --+ Math.random() * 0.2
		end
		
		local rotation = LocomotionUtils.rotation_towards_unit(unit, blackboard.corruptor_target)

		locomotion_extension:set_wanted_rotation(rotation)
		
		if blackboard.create_bot_threat_at and blackboard.create_bot_threat_at < t then
			local target_unit = blackboard.corruptor_target
			
			self:_create_bot_threat_box(unit, target_unit, bot_threat_duration) --+ Math.random() * 0.10)
			
			blackboard.create_bot_threat_at = nil
		end
		
		return true
	end

	return false
end)



--Tweak threat box to Assassin jump
mod:hook_origin(BTCrazyJumpAction, "create_bot_threat", function (self, unit, blackboard, t)
	local self_pos = POSITION_LOOKUP[unit]
	local to_target = POSITION_LOOKUP[blackboard.target_unit] - self_pos
	local distance = Vector3.length(to_target)
	local obstacle_position, obstacle_rotation, obstacle_size = AiUtils.calculate_oobb(distance + 6, self_pos, Quaternion.look(to_target), 4, 3.2)
	local bot_threat_duration = 1
	local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
	
	ai_bot_group_system:aoe_threat_created(obstacle_position, "oobb", obstacle_size, obstacle_rotation, bot_threat_duration)
end)



--Tweak threat box to Ratling fire line
-- mod:hook_origin(BTRatlingGunnerShootAction, "_create_bot_threat_box", function (self, unit, attack_data, duration)
	-- local self_pos = POSITION_LOOKUP[unit]
	-- local target_pos = POSITION_LOOKUP[attack_data.target_unit]
	
	-- if self_pos and target_pos then
		-- local to_target = target_pos - self_pos
		
		-- local obstacle_position, obstacle_rotation, obstacle_size = AiUtils.calculate_oobb(35, self_pos, Quaternion.look(to_target), 3, 3)
		-- local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
		
		-- ai_bot_group_system:aoe_threat_created(obstacle_position, "oobb", obstacle_size, obstacle_rotation, duration, nil, "shield")
	-- end
-- end)



--Tweak threat box to Chaos Spawn tentacle grab
mod:hook_origin(BTMeleeOverlapAttackAction, "_create_bot_aoe_threat", function (self, unit, attack_rotation, attack, bot_threat, bot_threat_duration)
	local unit_position = POSITION_LOOKUP[unit]
	local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
	
	local best_escape_dir = bot_threat.best_escape_direction and bot_threat.best_escape_direction or nil
	
	if bot_threat.collision_type == "cylinder" then
		local obstacle_position, rotation, obstacle_size = self:_calculate_cylinder_collision(attack, bot_threat, unit_position, attack_rotation)
		
		ai_bot_group_system:aoe_threat_created(obstacle_position, "cylinder", obstacle_size, rotation, bot_threat_duration, best_escape_dir)
	elseif bot_threat.collision_type == "oobb" or not bot_threat.collision_type then
		local obstacle_position, obstacle_rotation, obstacle_size = self:_calculate_oobb_collision(attack, bot_threat, unit_position, attack_rotation)
		
		ai_bot_group_system:aoe_threat_created(obstacle_position, "oobb", obstacle_size, obstacle_rotation, bot_threat_duration, best_escape_dir)
	end
	
	if mod.DEBUG then
		mod:echo("_create_bot_aoe_threat")
	end
end)

