local mod = get_mod("ReplicantTemp")

-- create default dynamic data
mod.d_data_create_default = function(owner)
	local d = {}
	
	d.fresh = false

	d.unit								= owner.player_unit
	d.owner								= owner
	d.name								= owner.character_name
	d.current_time						= Managers.time:time("game")
	d.current_hitpoint_percentage		= 1
	d.position							= false
	d.disabled							= false	-- true if this bot is disabled
	d.overheated						= false
	d.melee_attack_allowed				= true	-- if false the bot is not allowed to attack with melee
	d.ranged_attack_allowed				= true	-- if false the bot is not allowed to attack with ranged
	d.reduced_ambient_shooting			= false	-- if true, the bot should try to avoid shooting ambient enemies
	-- d.last_ranged_kill					= 0		-- time when the bot did its last ranged kill
	-- d.take_damage_cooldown				= 0		-- time before which the bot is not allowed to intentionally take in damage
	d.teleport_allowed_timer_duration	= 6
	d.teleport_allowed_timer			= 0
	d.teleport_allowed					= false
	d.follow_target						= false	-- follow target's unit id
	d.follow_target_position			= false	-- follow target's position
	d.extensions_ready					= false	-- true if all extension data hae been loaded (for the d.unit)
	-- d.melee_reach_tracker				= 0
	d.vent_allowed						= false
	d.vent_hp_threshold					= 0.5
	d.vent_heat_threshold				= 2
	d.vent_cooldown						= 0
	d.using_melee						= true
	d.using_ranged						= false
	d.has_enough_ammo					= false
	d.is_venting						= false
	d.enough_hp_to_vent					= false	
	-- d.warded_krench_as_target			= false
	d.ranged_not_yet_wielded			= true	-- init to true on creation to workaround a bug that causes bots not to get some weapon buffs after spawning

	d.unstuck_data = {}
	d.unstuck_data.is_stuck				= false
	d.unstuck_data.last_update			= false
	d.unstuck_data.last_attack			= false
	d.unstuck_data.last_position		= false

	-- d.settings = {}

	d.extensions = {}
	d.extensions.status				= false
	d.extensions.inventory			= false
	d.extensions.career				= false
	d.extensions.buff				= false
	d.extensions.input				= false
	d.extensions.overcharge			= false

	d.equipped = {}
	d.equipped.melee				= false
	d.equipped.melee_weapon_template	= false
	d.equipped.melee_chain_position	= 0
	d.equipped.melee_chain_state	= "none"
	d.equipped.anti_armor			= false
	d.equipped.ranged				= false
	d.equipped.sniper				= false
	d.equipped.heat_weapon			= false
	d.equipped.ranged_can_reload	= false
	d.equipped.ranged_ammo			= false
	d.equipped.weapon_unit			= false
	d.equipped.weapon_id			= false
	d.equipped.weapon_template		= false
	d.equipped.weapon_extension		= false
	d.equipped.dodge_distance		= 2
	
	d.equipped.heat_amount				= 0
	d.equipped.heat_threshold			= 0
	d.equipped.heat_max					= 0
	d.equipped.ranged_weapon_template	= false
	d.equipped.ranged_weapon_extension	= false
	d.equipped.melee_weapon_extension	= false

	d.enemies = {}
	-- d.enemies.push				= {}	-- unit array of push range enemies
	d.enemies.melee				= {}	-- unit array of close range enemies, 3.5u
	d.enemies.near				= {}	-- unit array of close range enemies, 5u
	d.enemies.medium			= {}	-- unit array of medium range enemies, 8u
	d.enemies.far				= {}	-- unit array of long range enemies, 20u
	d.enemies.bosses			= {}	-- unit array of all alive bosses
	d.enemies.specials			= {}	-- unit array of all alive specials
	d.enemies.melee_control_arc = {}	-- units in the bot's control weapon's control arc

	d.defense = {}
	d.defense.awareness = {}
	d.defense.awareness.attacks		= {}
	d.defense.awareness.cleaned		= d.current_time
	d.defense.current_stamina		= false -- 0..x indicates amount of stamina the bot has left, 2 stamina = 1 shield in the UI
	d.defense.dodge_count_left		= 2		-- Vernon: 2 is the default for weapon templates
	d.defense.is_dodging			= false	-- Vernon: added data
	d.defense.can_dodge				= true	-- Vernon: added data
	d.defense.on_ground				= true	-- Vernon: added data
	d.defense.calculate_dodge_update_time = nil
	d.defense.need_dodge_direction_fix = false

	d.defense.is_surrounded			= false	-- Vernon: added data
	d.defense.check_surrounded_timer = 0	--nil	-- Vernon: added data
	d.defense.must_push_gutter		= false -- true is the bot can interrupt stabbing gutter with push
	d.defense.assassin_on_field		= false

	d.defense.closest_able_ally_distance	= math.huge	-- Vernon: added data
	d.defense.closest_human_distance = math.huge	-- Vernon: added data
	d.defense.closest_bot_distance	= math.huge	-- Vernon: added data
	
	d.defense.threat_boss			= {}	-- array of threatening bosses around the bot
	d.defense.threat_trash			= {}	-- array of threatening trash rats around the bot
	d.defense.threat_trash_general	= {}	-- array of rats threatening any player around the bot (within the bot's push range)
	d.defense.threat_running_attack = false -- true if there is a threat from a thrash rat's running attack
	
	d.defense.count					= {}
	d.defense.count.trash			= 0
	d.defense.count.aoe_elite		= 0
	d.defense.count.berserker		= 0
	d.defense.count.boss			= 0
	d.defense.closest				= {}
	d.defense.closest.aoe_elite		= nil
	d.defense.closest.trash			= nil
	
	d.defense.threat								= {}
	d.defense.threat.running_attack					= false
	d.defense.threat.trash_attacking				= false
	d.defense.threat.trash_outside_push_range		= false
	d.defense.threat.trash_count					= 0
	d.defense.threat.berserker_attacking			= false
	d.defense.threat.aoe_elite						= false
	d.defense.threat.aoe_elite_in_push_range		= false
	d.defense.threat.aoe_elite_outside_push_range	= false
	d.defense.threat.boss							= false
	
	d.defense.stamina_left							= 0
	d.defense.dodge_count_left						= 0
	d.defense.dodge_reset_time						= 0
	
	d.defense.is_boss_target					= false
	d.defense.followed_player_is_boss_target	= false
	
	d.holding_spot = {				-- original objective_defence used as holding spot
		enabled			= false,	-- true if objective defence is currently active
		position		= false,	-- position of the objective defence target
		bot_positions	= false,	-- array of bot stand positions around the defense objective
	}	
	
	d.regroup = {}
	d.regroup.enabled				= false	-- true if forced regroup is active and the bot must return to the regroup anchor
	d.regroup.position				= false	-- Vector3 position of the forced regroup anchor
	d.regroup.distance				= false	-- distance between the bot location and the regroup position
	d.regroup.distance_threshold	= false	-- current distance threshold for forced regroup
	
	d.melee = {}
	d.melee.target_unit						= false -- unit id for the melee target unit
	d.melee.target_position					= false -- Vector3 position of the melee target unit
	d.melee.target_offset					= false -- Vector3 form self >> target
	d.melee.target_distance					= false -- Vector3.length of target_offset
	d.melee.target_breed					= false -- breed id of the target enemy
	d.melee.aim_position					= false -- Vector3 position of the target unit's node
	d.melee.is_aiming						= false -- true if the bot should aim at its current target
	d.melee.may_engage						= false -- true if the bot should actively engage its current target
	d.melee.has_line_of_sight				= false -- true if the bot has line of sight to its ranged target
	d.melee.threats_outside_control_angle	= false	-- true if there are rat threats outside the arc the bot's control weapon can manage
	
	d.heal = {}
	d.heal.target_unit			= false
	
	d.token = {}
	d.token.jump				= false
	d.token.dodge				= false
	d.token.push				= false
	d.token.block				= false
	d.token.block_override		= false
	d.token.melee_light			= false
	d.token.melee_heavy			= false
	d.token.melee_push_attack	= false
	d.token.melee_expire		= 0
	d.token.ranged_light		= false
	d.token.ranged_heavy		= false
	d.token.ranged_vent			= false
	d.token.take_damage			= false
	d.token.heal				= false

	-- d.stepping_fix = {}
	-- d.stepping_fix.old_velocity			= Vector3Box(Vector3(1,0,0))
	-- d.stepping_fix.old_position			= Vector3Box(Vector3(0,0,0))
	-- d.stepping_fix.turn_counter			= 0
	-- d.stepping_fix.turn_counter2		= 0
	-- d.stepping_fix.turn_counter_timer	= 0
	-- d.stepping_fix.is_stepping_timer	= 0

	d.items =
	{
		tome				= false,
		medkit				= false,
		draught				= false,
		
		grim				= false,
		speed_potion		= false,
		strength_potion		= false,
		concentration_potion = false,
		
		fire_grenade		= false,
		frag_grenade		= false,
	}

	owner.d_data = d
	
	return
end

mod.d_data_update = function(d)
	
	-- update the freshness check
	d.fresh = Vector3(0,0,0)

	-- check if the current stored unit is still valid (e.g. in case human player takes the bot's spot)
	local unit_is_valid = false
	for _, loop_owner in pairs(Managers.player:bots()) do
		if loop_owner.player_unit == d.unit then
			unit_is_valid = true
		end
	end

	if d.owner.player_unit ~= d.unit then
		unit_is_valid = false
	end

	-- When bot dies / despawns, the d.unit becomes invalid and needs to be re-aquired
	if not Unit.alive(d.unit) or not unit_is_valid then
		d.unit					= d.owner.player_unit	-- unit needs refresh
		d.name					= d.owner.character_name
		d.extensions_ready		= false		-- extensions need refresh
		d.extensions.status		= false
		d.extensions.inventory	= false
		d.extensions.career		= false
		d.extensions.buff		= false
		d.extensions.input		= false
		d.extensions.overcharge	= false
		d.token.block_override	= false
	end
	
	-- some general updates
	local local_player_unit = (Managers.player and Managers.player:local_player() and Managers.player:local_player().player_unit) or d.unit
	local local_player_status_extension = ScriptUnit.has_extension(local_player_unit, "status_system")
	local local_player_disabled = local_player_status_extension and local_player_status_extension:is_disabled()
	
	local blackboard				= BLACKBOARDS[d.unit]
	if not blackboard then
		return
	end
	
	d.current_time					= Managers.time:time("game")
	-- d.current_hitpoint_percentage	= get_bot_current_health_percent(d.unit)
	d.position						= POSITION_LOOKUP[d.unit]
	d.follow_target					= (blackboard.ai_bot_group_extension and blackboard.ai_bot_group_extension.data and blackboard.ai_bot_group_extension.data.follow_unit) or nil
	d.follow_target_position		= (d.follow_target and POSITION_LOOKUP[d.follow_target]) or d.position
	
	-- update extensions as needed
	if not d.extensions_ready then
		d.extensions.status				= ScriptUnit.has_extension(d.unit, "status_system")
		d.extensions.inventory			= ScriptUnit.has_extension(d.unit, "inventory_system")
		d.extensions.career				= ScriptUnit.has_extension(d.unit, "career_system")
		d.extensions.buff				= ScriptUnit.has_extension(d.unit, "buff_system")
		d.extensions.input				= ScriptUnit.has_extension(d.unit, "input_system")
		d.extensions_ready				= (d.extensions.status and d.extensions.inventory and d.extensions.career and d.extensions.buff and d.extensions.input and true) or false
	end
	
	-- update extension dependent data
	local wounded = false
	if d.extensions_ready then
		d.disabled = d.extensions.status:is_disabled()
		local catapulted = d.extensions.status.catapulted
		local pushed = d.extensions.status.pushed
		
		if d.teleport_allowed_timer == nil then d.teleport_allowed_timer = 0 end
		if d.disabled or pushed or catapulted then
			d.teleport_allowed_timer = d.current_time + d.teleport_allowed_timer_duration
			d.teleport_allowed = false
		elseif d.current_time > d.teleport_allowed_timer then
			d.teleport_allowed = true
		else
			d.teleport_allowed = false
		end
		
		wounded = d.extensions.status:is_wounded()
	else
		d.teleport_allowed = false
	end
	
	if not d.unstuck_data.last_update then
		d.unstuck_data.last_update		= d.current_time
		d.unstuck_data.last_attack		= d.current_time
		d.unstuck_data.last_position	= Vector3Box(d.position)
	end
	
	-- ***********************************************
	-- ** update equipped weapon information        **
	-- ***********************************************
	--....................
	
	--Vernon: handle THP later
	local health_extension		= ScriptUnit.has_extension(d.unit, "health_system")
	local max_hp				= (health_extension and DamageUtils.networkify_health(health_extension:_calculate_max_health())) or 100
	local current_damage		= (health_extension and health_extension.damage) or 0
	local current_hp			= max_hp - current_damage
	local venting_threats_life	= (current_hp - predicted_vent_damage_tick) < 5
	
	d.enough_hp_to_vent					= d.vent_allowed and ((d.current_hitpoint_percentage > d.vent_hp_threshold and not venting_threats_life and not wounded) or d.equipped.heat_amount < d.equipped.heat_threshold)
	d.vent_allowed						= bot_settings.menu_settings.vent_allowed			-- bot won't vent if its not allowed
	d.vent_hp_threshold					= bot_settings.menu_settings.vent_hp_threshold		-- bot won't vent if its hp% is below this point
	d.vent_heat_threshold				= bot_settings.menu_settings.vent_heat_threshold	-- bot won't vent below this point
	
	-- ***********************************************
	-- ** update equipped items information         **
	-- ***********************************************
	
	if d.extensions.inventory then
		local carried_heal		= d.extensions.inventory:get_item_name("slot_healthkit")
		local carried_potion	= d.extensions.inventory:get_item_name("slot_potion")
		local carried_grenade	= d.extensions.inventory:get_item_name("slot_grenade")
		
		--"slot_career_skill_weapon"
		
		d.items.tome				= carried_heal == "wpn_side_objective_tome_01"
		d.items.medkit				= carried_heal == "healthkit_first_aid_kit_01"
		d.items.draught				= carried_heal == "potion_healing_draught_01"
		
		d.items.grim				= carried_potion == "wpn_grimoire_01"
		d.items.speed_potion		= carried_potion == "potion_speed_boost_01"
		d.items.strength_potion		= carried_potion == "potion_damage_boost_01"
		d.items.concentration_potion = carried_potion == "potion_cooldown_reduction_01"
		
		d.items.fire_grenade		= carried_grenade == "grenade_fire_01" or carried_grenade == "grenade_fire_02"
		d.items.frag_grenade		= carried_grenade == "grenade_frag_01" or carried_grenade == "grenade_frag_02"
	end
	
	-- ***********************************************
	-- ** update enemy lists                        **
	-- ***********************************************
	
	local filter_unit_list_by_distance = function(distance, unit_list)
		if unit_list == nil then
			unit_list = d.enemies.far
		end
		local validity_check = false
		if distance == nil then
			distance = math.huge
			validity_check = true
		end
		
		local ret = {}
		for _,loop_unit in pairs(unit_list) do
			local loop_position = POSITION_LOOKUP[loop_unit]
			local loop_bb		= BLACKBOARDS[loop_unit]
			local loop_breed	= Unit.get_data(loop_unit, "breed")
			-- local valid_target	= not validity_check or not (loop_breed.name == "skaven_clan_rat" or loop_breed.name == "skaven_slave") or (loop_bb.target_unit or loop_bb.attacking_target or loop_bb.special_attacking_target)
			-- local valid_target	= not validity_check or not mod.TRASH_UNITS_EXCEPT_ARCHERS[loop_breed.name] or (loop_bb.target_unit or loop_bb.attacking_target)
			-- if valid_target and Vector3.length(d.position - loop_position) < distance then
			if Vector3.length(d.position - loop_position) < distance then
				table.insert(ret,loop_unit)
			end
		end
		
		return ret
	end
	
	local max_height_offset	= 3.8
	local far_radius		= 25
	local medium_radius		= 10
	local near_radius		= 5
	local melee_radius		= 3.5
	local push_radius		= 2.5
	
	d.enemies.far		= mod.get_proximite_enemies(d.unit, far_radius, max_height_offset)	--doesn't have a target anymore
	d.enemies.far		= filter_unit_list_by_distance()
	d.enemies.medium	= filter_unit_list_by_distance(medium_radius, d.enemies.far)
	d.enemies.near		= filter_unit_list_by_distance(near_radius, d.enemies.medium)
	d.enemies.melee		= filter_unit_list_by_distance(melee_radius, d.enemies.near)
	d.enemies.push		= filter_unit_list_by_distance(push_radius, d.enemies.near)
	d.enemies.bosses	= mod.get_spawned_bosses_and_lords()
	d.enemies.specials	= mod.get_spawned_specials()
	-- d.enemies.medium_sv	= {}
	-- d.enemies.closest_boss_distance = math.huge
	
	-- ***********************************************
	-- ** identify immediate threats around the bot **
	-- ***********************************************
	
	-- clean the awareness table as needed
	if d.current_time - d.defense.awareness.cleaned > 5 then
		for key,_ in pairs(d.defense.awareness.attacks) do
			if not Unit.alive(key) then
				d.defense.awareness.attacks[key] = nil
				d.defense.awareness.extend_block[key] = nil
			end
		end
		d.defense.awareness.cleaned = d.current_time
	end
	
	local aggressive_melee_exceptions = 
	{
		-- ww_2h_axe			= 0.2,
		-- dr_2h_axes			= 0.2,
		-- dr_1h_axe_shield	= 0.2,
		-- dr_1h_hammer_shield	= 0.2,
		-- dr_2h_hammer		= 0.2,
		-- es_1h_sword_shield	= 0.2,
		-- es_1h_mace_shield	= 0.2,
		-- es_2h_war_hammer	= 0.2,
	}
	-- local aggressive_melee_allowance = (d.equipped.weapon_id and aggressive_melee_exceptions[d.equipped.weapon_id]) or 0.6
	local aggressive_melee_allowance = 0.6
	local aggressive_melee_allowance_running = 0.6	--Reverted: 0.2
	local aggressive_melee_allowance_sv = 0.8	--0.9
	local aggressive_melee_allowance_sv_sweep = 0.8		--0.9
	local aggressive_melee_allowance_sv_overhead = 0.9	--1.1
	
	local AGGRESSIVE_MELEE_ALLOWANCE_STANDING = 0.4
	local AGGRESSIVE_MELEE_ALLOWANCE_RUNNING = 0.2
	local AGGRESSIVE_MELEE_ALLOWANCE_STANDING_ELITE = 0.4
	local AGGRESSIVE_MELEE_ALLOWANCE_RUNNING_ELITE = 0.2
	
	local AGGRESSIVE_MELEE_ALLOWANCE = {
		chaos_warrior = {
			special_attack_cleave = {
				default = 1,
				moving_attack = 1.2,
			},
			special_attack_sweep = {
				default = 0.2,
				moving_attack = 0.3,
			},
			special_attack_launch = {
				default = 0.3,
			}
		},
		chaos_raider = {
			special_attack_cleave = {
				default = 0.4,
				moving_attack = 1.3,
			},
			running_attack = {
				default = 0.7,
				moving_attack = 0.7,
			},
		},
	}
	
	local current_fatigue, max_fatigue = d.extensions.status:current_fatigue_points()
	d.defense.current_stamina	= max_fatigue - current_fatigue
	d.defense.dodge_count_left	= d.extensions.status.dodge_count - d.extensions.status.dodge_cooldown
	d.defense.dodge_reset_time	= d.extensions.status.dodge_cooldown_delay or d.current_time + 0.5
	d.defense.is_dodging		= d.extensions.status:get_is_dodging()
	d.defense.can_dodge			= d.extensions.status:can_dodge(d.current_time)
	d.defense.on_ground			= true
	
	local locomotion_extension	= ScriptUnit.extension(d.unit, "locomotion_system")
	if locomotion_extension then
		d.defense.on_ground = locomotion_extension:is_colliding_down()
	end
	
	d.defense.closest_able_ally_distance = math.huge
	for _, player in pairs(Managers.player:players()) do
		local loop_unit = player.player_unit
		-- local ally_is_bot	= player.bot_player
		-- local ally_is_human	= not ally_is_bot
		if loop_unit ~= d.unit then
			local status_extension = ScriptUnit.has_extension(loop_unit, "status_system")
			local enabled = status_extension and not status_extension:is_disabled()
			if enabled then
				local loop_position = POSITION_LOOKUP[loop_unit]
				local loop_distance = loop_position and Vector3.length(d.position - loop_position)
				if loop_distance and d.defense.closest_able_ally_distance and d.defense.closest_able_ally_distance < loop_distance then
					d.defense.closest_able_ally_distance = loop_distance
				end
			end
		end
	end
	
	
end

mod.get_d_data = function(self_unit)
	if self_unit == nil then
		return false
	end
	
	local self_owner = Managers.player:unit_owner(self_unit)
	
	if not self_owner then
		return false
	end
	
	local blackboard = Unit.get_data(self_unit, "blackboard")
	local d = self_owner.d_data
	
	-- check if d_data actually exist
	if not d then
		-- if not >> try to generate it
		mod.d_data_create_default(self_owner)
		mod.d_data_update(self_owner.d_data)
		local d_tmp = self_owner.d_data
		
		--.......
		
	end

	d = self_owner.d_data

	-- check again, now there really should be d_data
	if not d then
		-- if not, complain about it
		EchoConsole("*** d_data generation failed ***")
	end
	
	-- if the data has not been updated on this frame >> update it
	if tostring(d.fresh) ~= "Vector3(0, 0, 0)" then
		mod.d_data_update(self_owner.d_data)
	end
	
	d.settings = bot_settings.menu_settings
	
	return d
end
