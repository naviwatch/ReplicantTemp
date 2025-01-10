local mod = get_mod("ReplicantTemp")

mod.stop_trash_shooting_ranged = {	--criteria: limited ammo or long reload time, can also consider conservative shooter and career abilities
	handgun_template_1 = true,
	handgun_template_2 = true,
	crossbow_template_1 = true,
	longbow_template_1 = true,
	brace_of_pistols_template_1 = true,
	dr_deus_01_template_1 = true,
	heavy_steam_pistol_template_1 = true,
	longbow_empire_template = true,
	repeating_crossbow_template_1 = true,
	repeating_crossbow_elf_template = true,
	repeating_handgun_template_1 = true,
	repeating_pistol_template_1 = true,
}
mod.sniper_selection_ranged = {	--criteria: limited ammo or long reload time, can also consider conservative shooter and career abilities
	handgun_template_1 = true,
	handgun_template_2 = true,
	crossbow_template_1 = true,
	longbow_template_1 = true,
	brace_of_pistols_template_1 = true,
	-- dr_deus_01_template_1 = true,
	heavy_steam_pistol_template_1 = true,
	longbow_empire_template = true,
	-- repeating_crossbow_template_1 = true,
	-- repeating_crossbow_elf_template = true,
	repeating_handgun_template_1 = true,
	-- repeating_pistol_template_1 = true,
	
	staff_spark_spear_template_1 = true,
}
mod.heat_weapon = {
	brace_of_drakefirepistols_template_1 = true,
	bw_deus_01_template_1 = true,
	drakegun_template_1 = true,
	staff_blast_beam_template_1 = true,
	staff_fireball_fireball_template_1 = true,
	staff_fireball_geiser_template_1 = true,
	staff_flamethrower_template = true,
	staff_life = true,
	staff_spark_spear_template_1 = true,
}
--[[
https://discord.com/channels/719364428595855408/719365902058913792/908346409227522078

Volley Xbow(All 3 Saltz),Moonbow(all Elves),Hagbane(ammo dump,Waystalker only),Beam Staff(BW),Fireball(Pyro's the best,BW is okay with Volcanic/Famished,UC does decently with it),Coruscation(all 3 Sienna),Manbow(Huntsman),Masterwork Pistol(RV),Trollpedo(IB and Engi)
Javelin's damage primarily comes from spamming the lights compared to actually throwing it for boss damage
Based on my experience atleast,numbers could tell the opposite
Xbow actually does decent enough boss damage if you hit the head
--]]
mod.monster_dps_ranged = {	--bots with these weapons prefer to use ranged for monsters even in melee range, possibly includes BW with any staff
	longbow_empire_template = true,
	heavy_steam_pistol_template_1 = true,
	dr_deus_01_template_1 = true,
	shortbow_hagbane_template_1 = true,		--with ammo regen only, mostly waystalker
	repeating_crossbow_elf_template = true,
	javelin_template = true,		--melee attack
	repeating_crossbow_template_1 = true,
	staff_blast_beam_template_1 = true,
	staff_fireball_fireball_template_1 = true,
	bw_deus_01_template_1 = true,
	
	one_handed_throwing_axes_template = true,
	brace_of_pistols_template_1 = true,
	longbow_template_1 = true,
	staff_spark_spear_template_1 = true,
	repeating_handgun_template_1 = true,
}
mod.pre_charge_ranged = {
	staff_spark_spear_template_1 = true,
	longbow_empire_template = true,
}



mod.update_ranged_weapon_templates_meta = function()
	Projectiles.geiser = table.clone(Projectiles.default)
	Projectiles.geiser.trajectory_template_name = "geiser_trajectory"

	-- handguns: make bots take aim earlier to avoid misses
	Weapons.handgun_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.handgun_template_2.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.handgun_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.handgun_template_2.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.handgun_template_1.attack_meta_data.charge_above_range = 5	--6	--7	--5
	Weapons.handgun_template_2.attack_meta_data.charge_above_range = 5	--6	--7	--5
	Weapons.handgun_template_1.attack_meta_data.aim_at_node = "j_head"
	Weapons.handgun_template_2.attack_meta_data.aim_at_node = "j_head"
	Weapons.handgun_template_1.attack_meta_data.minimum_charge_time = 0.41
	Weapons.handgun_template_2.attack_meta_data.minimum_charge_time = 0.41
	Weapons.handgun_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Shielded, BreedCategory.SuperArmor, BreedCategory.Boss)	--BreedCategory.Infantry
	Weapons.handgun_template_2.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Shielded, BreedCategory.SuperArmor, BreedCategory.Boss)	--BreedCategory.Infantry
	
	-- crossbows: make bots take aim earlier to avoid misses
	Weapons.crossbow_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.crossbow_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.crossbow_template_1.attack_meta_data.charge_above_range = 5
	Weapons.crossbow_template_1.attack_meta_data.aim_at_node_charged = "j_head"
	Weapons.crossbow_template_1.attack_meta_data.aim_at_node = "j_head"
	Weapons.crossbow_template_1.attack_meta_data.minimum_charge_time = 0.2	--0.16		--0.25		--0.2	--need to charge to longer to make crosshair smaller
	Weapons.crossbow_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.SuperArmor, BreedCategory.Boss)	--BreedCategory.Infantry
	
	-- longbow (reduced charge_above_range so the bots actually use charged shot every now and then)
	Weapons.longbow_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.longbow_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.longbow_template_1.attack_meta_data.charge_above_range = 0	--5
	Weapons.longbow_template_1.attack_meta_data.minimum_charge_time = 0.51
	Weapons.longbow_template_1.attack_meta_data.charged_attack_action_name = "shoot_special_charged"
	Weapons.longbow_template_1.attack_meta_data.aim_at_node = "j_head"
	Weapons.longbow_template_1.attack_meta_data.always_charge_before_firing = true
	Weapons.longbow_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.SuperArmor, BreedCategory.Boss)	--BreedCategory.Infantry
	Weapons.longbow_template_1.attack_meta_data.keep_distance = 4
	
	-- shortbow (reduced charge_above_range so the bots actually use charged shot every now and then)
	Weapons.shortbow_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.shortbow_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.shortbow_template_1.attack_meta_data.charge_above_range = 15	--20
	Weapons.shortbow_template_1.attack_meta_data.aim_at_node = "j_head"	--j_spine1	--j_spine
	Weapons.shortbow_template_1.attack_meta_data.aim_at_node_charged = "j_head"
	Weapons.shortbow_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special)
	Weapons.shortbow_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	-- Weapons.shortbow_template_1.attack_meta_data.charge_when_obstructed = true		--test; seems to make bot use charged for trash units, need to assign cloest unit with target selection function
	Weapons.shortbow_template_1.attack_meta_data.keep_distance = 4
	
	Weapons.one_handed_throwing_axes_template.attack_meta_data.ignore_enemies_for_obstruction = false
	Weapons.one_handed_throwing_axes_template.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.one_handed_throwing_axes_template.attack_meta_data.minimum_charge_time = 0.66
	Weapons.one_handed_throwing_axes_template.attack_meta_data.aim_at_node = "j_head"
	Weapons.one_handed_throwing_axes_template.attack_meta_data.charge_when_obstructed = true
	Weapons.one_handed_throwing_axes_template.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.one_handed_throwing_axes_template.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	
	Weapons.blunderbuss_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.blunderbuss_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.blunderbuss_template_1.attack_meta_data.max_range = 14	--12
	Weapons.blunderbuss_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Shielded)
	Weapons.blunderbuss_template_1.attack_meta_data.keep_distance = 4
	
	Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.ignore_enemies_for_obstruction = false
	Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.max_range = 30	--25
	-- Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.charge_above_range = 0
	-- Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.charge_when_obstructed = true	--false	--true seems to make bot use charged for trash units
	-- Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.max_range.aim_at_node_charged = "j_spine1"	--j_neck
	Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.always_charge_before_firing = true
	Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special)
	Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker)
	Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.keep_distance = 4
	Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.fire_input = "fire_hold"
	Weapons.brace_of_drakefirepistols_template_1.attack_meta_data.hold_fire_condition = function (t, blackboard)
		if blackboard then
			local inventory_extension = blackboard.inventory_extension
			local _, right_hand_weapon_extension, left_hand_weapon_extension = CharacterStateHelper.get_item_data_and_weapon_extensions(inventory_extension)
			local current_action_settings = CharacterStateHelper.get_current_action_data(left_hand_weapon_extension, right_hand_weapon_extension)

			if current_action_settings then
				local action_lookup = current_action_settings.lookup_data

				return action_lookup and action_lookup.action_name == "action_one" and action_lookup.sub_action_name == "shoot_charged"
			end
		end

		return false
	end
	
	Weapons.brace_of_pistols_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.brace_of_pistols_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.brace_of_pistols_template_1.attack_meta_data.aim_at_node = "j_spine1"
	Weapons.brace_of_pistols_template_1.attack_meta_data.can_charge_shot = true
	Weapons.brace_of_pistols_template_1.attack_meta_data.charged_attack_action_name = "fast_shot"
	-- Weapons.brace_of_pistols_template_1.attack_meta_data.minimum_charge_time = 0.01
	-- Weapons.brace_of_pistols_template_1.attack_meta_data.charge_above_range = 0
	Weapons.brace_of_pistols_template_1.attack_meta_data.max_range_charged = 10	--7	--6
	Weapons.brace_of_pistols_template_1.attack_meta_data.charge_when_outside_max_range_charged = false
	Weapons.brace_of_pistols_template_1.attack_meta_data.aim_at_node_charged = "j_head"		--j_spine1
	Weapons.brace_of_pistols_template_1.attack_meta_data.charge_when_obstructed = true	--false
	Weapons.brace_of_pistols_template_1.attack_meta_data.always_charge_before_firing = true
	Weapons.brace_of_pistols_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.brace_of_pistols_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.brace_of_pistols_template_1.attack_meta_data.keep_distance = 4
	Weapons.brace_of_pistols_template_1.attack_meta_data.uninterruptable_charge = true
	
	--coruscation staff
	Weapons.bw_deus_01_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.bw_deus_01_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.bw_deus_01_template_1.attack_meta_data.max_range = 15	--12
	Weapons.bw_deus_01_template_1.attack_meta_data.can_charge_shot = true
	Weapons.bw_deus_01_template_1.attack_meta_data.charged_attack_action_name = "geiser_launch"
	Weapons.bw_deus_01_template_1.attack_meta_data.minimum_charge_time = 0.21	--0.6
	-- Weapons.bw_deus_01_template_1.attack_meta_data.charge_above_range = 7	--6	--7
	Weapons.bw_deus_01_template_1.attack_meta_data.max_range_charged = 22.5		--20
	Weapons.bw_deus_01_template_1.attack_meta_data.charge_when_outside_max_range = true
	Weapons.bw_deus_01_template_1.attack_meta_data.charge_when_outside_max_range_charged = false
	Weapons.bw_deus_01_template_1.attack_meta_data.aim_at_node_charged = "j_spine"	--c_rightfoot
	Weapons.bw_deus_01_template_1.attack_meta_data.charge_when_obstructed = true	--false	--true
	Weapons.bw_deus_01_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Berserker, BreedCategory.Special)
	-- Weapons.bw_deus_01_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.bw_deus_01_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Armored, BreedCategory.Shielded, BreedCategory.SuperArmor, BreedCategory.Boss)
	Weapons.bw_deus_01_template_1.attack_meta_data.keep_distance = 4	--5
	Weapons.bw_deus_01_template_1.actions.action_one.geiser_launch.projectile_info = Projectiles.geiser
	-- Weapons.bw_deus_01_template_1.attack_meta_data.aim_data = {
		-- min_radius_pseudo_random_c = 0.0705,
		-- max_radius_pseudo_random_c = 0.0098,
		-- min_radius = math.pi / 36,
		-- max_radius = math.pi / 8
	-- }
	
	--trollhammer
	Weapons.dr_deus_01_template_1.attack_meta_data.ignore_enemies_for_obstruction = false
	Weapons.dr_deus_01_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.dr_deus_01_template_1.attack_meta_data.max_range = 10	--25	--20	--25	--make it short range so easier to hit head
	Weapons.dr_deus_01_template_1.aim_at_node = "j_head"
	-- Weapons.dr_deus_01_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Armored, BreedCategory.Special, BreedCategory.Shielded, BreedCategory.SuperArmor, BreedCategory.Boss)
	Weapons.dr_deus_01_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Armored, BreedCategory.Shielded, BreedCategory.SuperArmor, BreedCategory.Boss)
	
	Weapons.drakegun_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.drakegun_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.drakegun_template_1.attack_meta_data.minimum_charge_time = 0.9	--1
	Weapons.drakegun_template_1.attack_meta_data.max_range = 7	--8
	Weapons.drakegun_template_1.attack_meta_data.max_range_charged = 8	--9		--10		--11
	-- Weapons.drakegun_template_1.attack_meta_data.charge_above_range = 0		--3		--0
	Weapons.drakegun_template_1.attack_meta_data.charge_shot_delay = 0.1	--???
	Weapons.drakegun_template_1.attack_meta_data.charge_when_outside_max_range_charged = true	--false	--true
	Weapons.drakegun_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Berserker, BreedCategory.Armored, BreedCategory.Special)
	-- Weapons.drakegun_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Shielded, BreedCategory.Armored)
	Weapons.drakegun_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Shielded)
	Weapons.drakegun_template_1.attack_meta_data.keep_distance = 4	--5
	Weapons.drakegun_template_1.attack_meta_data.fire_input = "fire_hold"
	-- Weapons.staff_flamethrower_template.attack_meta_data.max_hold_fire_duration = 2.5
	Weapons.drakegun_template_1.attack_meta_data.hold_fire_condition = function (t, blackboard)
		if blackboard then
			local inventory_extension = blackboard.inventory_extension
			local _, right_hand_weapon_extension, left_hand_weapon_extension = CharacterStateHelper.get_item_data_and_weapon_extensions(inventory_extension)
			local current_action_settings = CharacterStateHelper.get_current_action_data(left_hand_weapon_extension, right_hand_weapon_extension)

			if current_action_settings then
				local action_lookup = current_action_settings.lookup_data

				return action_lookup and action_lookup.action_name == "action_one" and action_lookup.sub_action_name == "shoot_charged"
			end
		end

		return false
	end
	Weapons.drakegun_template_1.attack_meta_data.aim_data = {
		min_radius_pseudo_random_c = 0.3021,
		max_radius_pseudo_random_c = 0.03222,
		min_radius = math.pi / 72,
		max_radius = math.pi / 16
	}
	
	Weapons.grudge_raker_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.grudge_raker_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.grudge_raker_template_1.attack_meta_data.max_range = 25
	-- Weapons.grudge_raker_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special)
	Weapons.grudge_raker_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Shielded)
	Weapons.grudge_raker_template_1.attack_meta_data.keep_distance = 4
	
	--masterwork pistol
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.max_range = 60	--50
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.can_charge_shot = true
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.charged_attack_action_name = "fast_shot"
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.minimum_charge_time = 0.51
	-- Weapons.heavy_steam_pistol_template_1.attack_meta_data.charge_above_range = 0
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.max_range_charged = 7	--5	--4
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.charge_when_outside_max_range_charged = false
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.aim_at_node_charged = "j_spine1"
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.charge_when_obstructed = false
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.always_charge_before_firing = true
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.keep_distance = 6	--5
	Weapons.heavy_steam_pistol_template_1.attack_meta_data.uninterruptable_charge = true
	
	--check bot javelin reload fix
	Weapons.javelin_template.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.javelin_template.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.javelin_template.attack_meta_data.max_range = 80	--60	--50
	Weapons.javelin_template.attack_meta_data.charge_above_range = 3	--0	--5		--do bots use javelin melee attack?
	Weapons.javelin_template.attack_meta_data.aim_at_node = "j_head"
	Weapons.javelin_template.attack_meta_data.aim_at_node_charged = "j_head"
	Weapons.javelin_template.attack_meta_data.minimum_charge_time = 0.51
	-- Weapons.javelin_template.attack_meta_data.always_charge_before_firing = true
	Weapons.javelin_template.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.SuperArmor, BreedCategory.Boss)
	Weapons.javelin_template.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.SuperArmor, BreedCategory.Boss)
	-- Weapons.javelin_template.attack_meta_data.keep_distance = 5
	
	--check if we want heavy charged shots, takes 1.25s to charge...
	-- Weapons.longbow_empire_template.attack_meta_data.charge_above_range = 5
	-- Weapons.longbow_empire_template.attack_meta_data.minimum_charge_time = 0.51
	-- Weapons.longbow_empire_template.attack_meta_data.aim_at_node = "j_head"
	-- Weapons.longbow_empire_template.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.SuperArmor)
	
	Weapons.longbow_empire_template.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.longbow_empire_template.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.longbow_empire_template.attack_meta_data.charge_above_range = 5
	Weapons.longbow_empire_template.attack_meta_data.charge_when_obstructed = true
	Weapons.longbow_empire_template.attack_meta_data.charged_attack_action_name = "shoot_charged_heavy"
	Weapons.longbow_empire_template.attack_meta_data.minimum_charge_time = 1.26
	Weapons.longbow_empire_template.attack_meta_data.aim_at_node = "j_head"
	Weapons.longbow_empire_template.attack_meta_data.always_charge_before_firing = true
	Weapons.longbow_empire_template.attack_meta_data.obstruction_fuzzyness_range_charged = math.huge
	Weapons.longbow_empire_template.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.SuperArmor, BreedCategory.Boss)
	Weapons.longbow_empire_template.attack_meta_data.keep_distance = 7	--6
	
	Weapons.repeating_crossbow_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.repeating_crossbow_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.repeating_crossbow_template_1.attack_meta_data.charge_above_range = 3
	Weapons.repeating_crossbow_template_1.attack_meta_data.max_range_charged = 7
	Weapons.repeating_crossbow_template_1.attack_meta_data.aim_at_node = "j_head"
	Weapons.repeating_crossbow_template_1.attack_meta_data.minimum_charge_time = 0.31
	Weapons.repeating_crossbow_template_1.attack_meta_data.always_charge_before_firing = true
	Weapons.repeating_crossbow_template_1.attack_meta_data.charge_when_outside_max_range_charged = false
	Weapons.repeating_crossbow_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.repeating_crossbow_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.repeating_crossbow_template_1.attack_meta_data.keep_distance = 4
	Weapons.repeating_crossbow_template_1.attack_meta_data.uninterruptable_charge = true
	
	Weapons.repeating_crossbow_elf_template.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.repeating_crossbow_elf_template.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.repeating_crossbow_elf_template.attack_meta_data.charge_above_range = 3
	Weapons.repeating_crossbow_elf_template.attack_meta_data.max_range_charged = 12	--7
	Weapons.repeating_crossbow_elf_template.attack_meta_data.aim_at_node = "j_head"
	Weapons.repeating_crossbow_elf_template.attack_meta_data.minimum_charge_time = 0.31
	Weapons.repeating_crossbow_elf_template.attack_meta_data.always_charge_before_firing = true
	Weapons.repeating_crossbow_elf_template.attack_meta_data.charge_when_outside_max_range_charged = false
	Weapons.repeating_crossbow_elf_template.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.repeating_crossbow_elf_template.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.repeating_crossbow_elf_template.attack_meta_data.keep_distance = 4
	Weapons.repeating_crossbow_elf_template.attack_meta_data.uninterruptable_charge = true
	
	--add charged shots probably
	Weapons.repeating_handgun_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.repeating_handgun_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.repeating_handgun_template_1.attack_meta_data.aim_at_node = "j_head"
	-- Weapons.repeating_handgun_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored)
	Weapons.repeating_handgun_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Boss)
	Weapons.repeating_handgun_template_1.attack_meta_data.keep_distance = 4
	Weapons.repeating_handgun_template_1.attack_meta_data.uninterruptable_charge = true
	
	--add charged shots probably
	Weapons.repeating_pistol_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.repeating_pistol_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.repeating_pistol_template_1.attack_meta_data.aim_at_node = "j_head"
	-- Weapons.repeating_pistol_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Berserker, BreedCategory.Special)
	-- Weapons.repeating_pistol_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Boss)
	Weapons.repeating_pistol_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Boss)
	Weapons.repeating_pistol_template_1.attack_meta_data.keep_distance = 4
	
	Weapons.shortbow_hagbane_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.shortbow_hagbane_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.shortbow_hagbane_template_1.attack_meta_data.charge_above_range = 4		--5
	-- Weapons.shortbow_hagbane_template_1.attack_meta_data.aim_at_node = "j_spine"
	Weapons.shortbow_hagbane_template_1.attack_meta_data.aim_at_node_charged = "j_head"
	Weapons.shortbow_hagbane_template_1.attack_meta_data.minimum_charge_time = 0.31
	Weapons.shortbow_hagbane_template_1.attack_meta_data.always_charge_before_firing = true
	-- Weapons.shortbow_hagbane_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Boss)
	-- Weapons.shortbow_hagbane_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Berserker, BreedCategory.Special)
	Weapons.shortbow_hagbane_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Special, BreedCategory.Boss)
	-- Weapons.shortbow_hagbane_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Shielded, BreedCategory.Boss)
	Weapons.shortbow_hagbane_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Shielded)
	Weapons.shortbow_hagbane_template_1.attack_meta_data.keep_distance = 5	--6	--4
	
	
	--need to add handgun shots
	--[[
	Weapons.staff_blast_beam_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.staff_blast_beam_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.staff_blast_beam_template_1.attack_meta_data.charge_above_range = 0
	-- Weapons.staff_blast_beam_template_1.attack_meta_data.charge_when_obstructed = false
	-- Weapons.staff_blast_beam_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Special, BreedCategory.Boss)
	-- Weapons.staff_blast_beam_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Special, BreedCategory.Boss)
	Weapons.staff_blast_beam_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Special, BreedCategory.Armored, BreedCategory.SuperArmor, BreedCategory.Boss)
	Weapons.staff_blast_beam_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Armored)
	--]]
	
	Weapons.staff_blast_beam_template_1.attack_meta_data.max_range_charged = 6
	Weapons.staff_blast_beam_template_1.attack_meta_data.charge_when_obstructed = true
	Weapons.staff_blast_beam_template_1.attack_meta_data.obstruction_fuzzyness_range_charged = 6
	Weapons.staff_blast_beam_template_1.attack_meta_data.charge_when_outside_max_range_charged = false
	Weapons.staff_blast_beam_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.staff_blast_beam_template_1.attack_meta_data.has_alternative_shot = true
	Weapons.staff_blast_beam_template_1.attack_meta_data.alternative_input = "defend"
	Weapons.staff_blast_beam_template_1.attack_meta_data.aim_at_node = "j_head"
	Weapons.staff_blast_beam_template_1.attack_meta_data.ignore_disabled_enemies_alternative = true
	Weapons.staff_blast_beam_template_1.attack_meta_data.max_range_alternative = 50
	Weapons.staff_blast_beam_template_1.attack_meta_data.alternative_when_obstructed = false
	Weapons.staff_blast_beam_template_1.attack_meta_data.alternative_attack_min_charge_time = 0.6
	Weapons.staff_blast_beam_template_1.attack_meta_data.alternative_attack_max_charge_time = 0.9
	Weapons.staff_blast_beam_template_1.attack_meta_data.alternative_attack_duration = 0.2
	Weapons.staff_blast_beam_template_1.attack_meta_data.alternative_input_duration = 0.2
	Weapons.staff_blast_beam_template_1.attack_meta_data.keep_distance = 6
	Weapons.staff_blast_beam_template_1.attack_meta_data.uninterruptable_charge = true
	Weapons.staff_blast_beam_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Boss, BreedCategory.SuperArmor)
	Weapons.staff_blast_beam_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker)
	Weapons.staff_blast_beam_template_1.attack_meta_data.effective_against_alternative = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.SuperArmor)
	
	Weapons.staff_fireball_fireball_template_1.attack_meta_data.ignore_enemies_for_obstruction = false
	Weapons.staff_fireball_fireball_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.staff_fireball_fireball_template_1.attack_meta_data.max_range = 60		--50
	Weapons.staff_fireball_fireball_template_1.attack_meta_data.max_range_charged = 30		--40		--50
	-- Weapons.staff_fireball_fireball_template_1.attack_meta_data.charge_above_range = 4	--5	--6
	Weapons.staff_fireball_fireball_template_1.attack_meta_data.aim_at_node_charged = "j_hips"		--c_rightfoot
	Weapons.staff_fireball_fireball_template_1.attack_meta_data.minimum_charge_time = 0.21	--0.6
	Weapons.staff_fireball_fireball_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Shielded, BreedCategory.SuperArmor, BreedCategory.Boss)
	Weapons.staff_fireball_fireball_template_1.attack_meta_data.keep_distance = 6	--5
	Weapons.staff_fireball_fireball_template_1.attack_meta_data.uninterruptable_charge = true
	
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.ignore_enemies_for_obstruction = false
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.staff_fireball_geiser_template_1.attack_meta_data.max_range_charged = 50
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.max_range = 60	--50
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.max_range_charged = 22.5	--25	--20
	-- Weapons.staff_fireball_geiser_template_1.attack_meta_data.charge_above_range = 5	--6
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.minimum_charge_time = 0.5	--test
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.charge_when_outside_max_range_charged = true	--false
	-- Weapons.staff_fireball_geiser_template_1.attack_meta_data.charge_when_obstructed = false
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.aim_at_node_charged = "j_spine"	--c_rightfoot
	-- Weapons.staff_fireball_geiser_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special)
	-- Weapons.staff_fireball_geiser_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Boss)
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Armored, BreedCategory.Special, BreedCategory.Boss)
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Armored, BreedCategory.Shielded, BreedCategory.SuperArmor)
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.keep_distance = 6		--5
	Weapons.staff_fireball_geiser_template_1.actions.action_one.geiser_launch.projectile_info = Projectiles.geiser
	Weapons.staff_fireball_geiser_template_1.attack_meta_data.aim_data = {
		min_radius_pseudo_random_c = 0.0903,
		max_radius_pseudo_random_c = 0.0132,
		min_radius = math.pi / 36,
		max_radius = math.pi / 8
	}
	
	-- Weapons.staff_flamethrower_template.attack_meta_data.max_range = 15
	Weapons.staff_flamethrower_template.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.staff_flamethrower_template.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.staff_flamethrower_template.attack_meta_data.can_charge_shot = true
	Weapons.staff_flamethrower_template.attack_meta_data.minimum_charge_time = 0.9	--1
	Weapons.staff_flamethrower_template.attack_meta_data.max_range = 7	--8
	Weapons.staff_flamethrower_template.attack_meta_data.max_range_charged = 8	--9		--10		--11
	-- Weapons.staff_flamethrower_template.attack_meta_data.charge_above_range = 0		--3		--0
	Weapons.staff_flamethrower_template.attack_meta_data.charge_shot_delay = 0.1
	-- Weapons.staff_flamethrower_template.attack_meta_data.obstruction_fuzzyness_range_charged = 1
	-- Weapons.staff_flamethrower_template.attack_meta_data.obstruction_fuzzyness_range = 1
	Weapons.staff_flamethrower_template.attack_meta_data.charge_when_outside_max_range_charged = true	--false	--true
	Weapons.staff_flamethrower_template.attack_meta_data.effective_against = bit.bor(BreedCategory.Berserker, BreedCategory.Armored, BreedCategory.Special)
	-- Weapons.staff_flamethrower_template.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Shielded, BreedCategory.Armored)
	Weapons.staff_flamethrower_template.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Shielded)
	Weapons.staff_flamethrower_template.attack_meta_data.keep_distance = 4	--5
	Weapons.staff_flamethrower_template.attack_meta_data.fire_input = "fire_hold"
	-- Weapons.staff_flamethrower_template.attack_meta_data.max_hold_fire_duration = 2.5
	Weapons.staff_flamethrower_template.attack_meta_data.hold_fire_condition = function (t, blackboard)
		if blackboard then
			local inventory_extension = blackboard.inventory_extension
			local _, right_hand_weapon_extension, left_hand_weapon_extension = CharacterStateHelper.get_item_data_and_weapon_extensions(inventory_extension)
			local current_action_settings = CharacterStateHelper.get_current_action_data(left_hand_weapon_extension, right_hand_weapon_extension)

			if current_action_settings then
				local action_lookup = current_action_settings.lookup_data

				return action_lookup and action_lookup.action_name == "action_one" and action_lookup.sub_action_name == "shoot_charged"
			end
		end

		return false
	end
	Weapons.staff_flamethrower_template.attack_meta_data.aim_data = {
		min_radius_pseudo_random_c = 0.3021,
		max_radius_pseudo_random_c = 0.03222,
		min_radius = math.pi / 72,
		max_radius = math.pi / 16
	}
	
	--need to play with this staff to understand what to change
	--need to find a way to use charged more effectively
	Weapons.staff_life.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.staff_life.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.staff_life.attack_meta_data.max_range = 60	--40
	Weapons.staff_life.attack_meta_data.max_range_charged = 100	--50
	-- Weapons.staff_life.attack_meta_data.charge_when_obstructed = false		--the lockon won't reach the enemy (but this will be overwritten by the hook...)
	-- Weapons.staff_life.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Boss)
	Weapons.staff_life.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Special, BreedCategory.Boss)
	-- Weapons.staff_life.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Armored, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Shielded, BreedCategory.SuperArmor)
	Weapons.staff_life.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Armored, BreedCategory.Special, BreedCategory.Shielded, BreedCategory.SuperArmor)
	Weapons.staff_life.attack_meta_data.keep_distance = 4
	
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.max_range = 20
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.charge_above_range = 7	--10	--15	--10
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.minimum_charge_time = 0.61	--1.26	--0.61
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.charged_attack_action_name = "shoot_charged_2"	--shoot_charged_3	--shoot_charged_2
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Special)
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored)
	
	Weapons.staff_spark_spear_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.staff_spark_spear_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.staff_spark_spear_template_1.attack_meta_data.max_range = 20	--7	--20
	Weapons.staff_spark_spear_template_1.attack_meta_data.charge_when_outside_max_range = true
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.charge_when_obstructed = true
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.charge_above_range = 7	--9
	Weapons.staff_spark_spear_template_1.attack_meta_data.minimum_charge_time = 1.26
	Weapons.staff_spark_spear_template_1.attack_meta_data.charged_attack_action_name = "shoot_charged_3"
	Weapons.staff_spark_spear_template_1.attack_meta_data.obstruction_fuzzyness_range_charged = math.huge
	-- Weapons.staff_spark_spear_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Special)
	Weapons.staff_spark_spear_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry)
	Weapons.staff_spark_spear_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Armored, BreedCategory.Shielded, BreedCategory.SuperArmor, BreedCategory.Boss)
	Weapons.staff_spark_spear_template_1.attack_meta_data.keep_distance = 7	--6		--5
	
	-- moonfire bow
	Weapons.we_deus_01_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.we_deus_01_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.we_deus_01_template_1.attack_meta_data.max_range = 15	--25
	-- Weapons.we_deus_01_template_1.attack_meta_data.aim_at_node = "j_spine1"
	Weapons.we_deus_01_template_1.attack_meta_data.aim_at_node = "j_head"
	Weapons.we_deus_01_template_1.attack_meta_data.aim_at_node_charged = "j_head"
	Weapons.we_deus_01_template_1.attack_meta_data.max_range_charged = 80	--nil	--80
	-- Weapons.we_deus_01_template_1.attack_meta_data.charge_above_range = 0	--5
	Weapons.we_deus_01_template_1.attack_meta_data.minimum_charge_time = 0.31
	Weapons.we_deus_01_template_1.attack_meta_data.always_charge_before_firing = true
	-- Weapons.we_deus_01_template_1.attack_meta_data.charge_when_obstructed = true
	-- Weapons.we_deus_01_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Berserker, BreedCategory.Armored, BreedCategory.Special, BreedCategory.Shielded, BreedCategory.SuperArmor, BreedCategory.Boss)
	Weapons.we_deus_01_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Special)
	Weapons.we_deus_01_template_1.attack_meta_data.effective_against_charged = bit.bor(BreedCategory.Special, BreedCategory.Boss)
	Weapons.we_deus_01_template_1.attack_meta_data.keep_distance = 4
	
	-- griffon foot
	Weapons.wh_deus_01_template_1.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.wh_deus_01_template_1.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.wh_deus_01_template_1.attack_meta_data.max_range = 12	--13	--12	--15
	-- Weapons.wh_deus_01_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special)
	Weapons.wh_deus_01_template_1.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Special, BreedCategory.Shielded)
	Weapons.wh_deus_01_template_1.attack_meta_data.keep_distance = 4
	
	
	
	
	
	Weapons.bardin_engineer_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction = false
	Weapons.bardin_engineer_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.bardin_engineer_career_skill_weapon.attack_meta_data.max_range = 30
	Weapons.bardin_engineer_career_skill_weapon.attack_meta_data.stop_fire_delay = nil
	Weapons.bardin_engineer_career_skill_weapon.attack_meta_data.aim_at_node = "j_head"
	Weapons.bardin_engineer_career_skill_weapon.attack_meta_data.keep_distance = 7
	Weapons.bardin_engineer_career_skill_weapon.attack_meta_data.can_charge_shot = true
	Weapons.bardin_engineer_career_skill_weapon.attack_meta_data.charge_when_outside_max_range = true
	Weapons.bardin_engineer_career_skill_weapon.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Boss, BreedCategory.Berserker, BreedCategory.Special)
	
	Weapons.bardin_engineer_career_skill_weapon_special.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.bardin_engineer_career_skill_weapon_special.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.bardin_engineer_career_skill_weapon_special.attack_meta_data.max_range = 30
	Weapons.bardin_engineer_career_skill_weapon_special.attack_meta_data.stop_fire_delay = nil
	Weapons.bardin_engineer_career_skill_weapon_special.attack_meta_data.aim_at_node = "j_head"
	Weapons.bardin_engineer_career_skill_weapon_special.attack_meta_data.keep_distance = 7
	Weapons.bardin_engineer_career_skill_weapon_special.attack_meta_data.can_charge_shot = true
	Weapons.bardin_engineer_career_skill_weapon_special.attack_meta_data.charge_when_outside_max_range = true
	Weapons.bardin_engineer_career_skill_weapon_special.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Boss, BreedCategory.Special, BreedCategory.Armored)
	
	
	-- Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction = true
	-- Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.keep_distance = 5
	-- Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.fire_input = "release_ability_hold"
	-- Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.minimum_charge_time = 0.26
	-- Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.charge_shot_delay = nil
	-- Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.charge_when_obstructed = false
	-- Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.aim_data = {
		-- min_radius_pseudo_random_c = 0.2077,
		-- max_radius_pseudo_random_c = 0.1156,
		-- min_radius = math.pi / 72 * 8,
		-- max_radius = math.pi / 16 * 8
	-- }
	
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.keep_distance = 5
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.minimum_charge_time = nil	--0.26
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.charge_shot_delay = nil
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.charge_when_obstructed = false
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.aim_data = {
		min_radius_pseudo_random_c = 0.2077,
		max_radius_pseudo_random_c = 0.1156,
		min_radius = (math.pi / 72) * 8,
		max_radius = (math.pi / 16) * 8
	}
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.has_alternative_shot = true
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.always_use_alternative_attack = true
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.alternative_input = "release_ability_hold"
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.alternative_attack_min_charge_time = 0.2
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.alternative_attack_duration = 0.3
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.alternative_input_duration = 0.3
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.ignore_disabled_enemies_alternative = true
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.charge_input_threat = "defend"
	Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.disable_target_change = true
	-- Weapons.kerillian_waywatcher_career_skill_weapon.attack_meta_data.do_not_shoot_in_aoe_threat = true
	
	-- Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.ignore_enemies_for_obstruction = false
	-- Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.ignore_enemies_for_obstruction_charged = false
	-- Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.keep_distance = 5
	-- Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.fire_input = "release_ability_hold"
	-- Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.minimum_charge_time = 0.26
	-- Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.charge_shot_delay = nil
	-- Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.charge_when_obstructed = false
	-- Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.aim_data = {
		-- min_radius_pseudo_random_c = 0.0701,
		-- max_radius_pseudo_random_c = 0.0095,
		-- min_radius = math.pi / 72 / 4,
		-- max_radius = math.pi / 16 / 6
	-- }
	
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.ignore_enemies_for_obstruction = false
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.ignore_enemies_for_obstruction_charged = false
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.keep_distance = 5
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.minimum_charge_time = nil	--0.26
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.charge_shot_delay = nil
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.charge_when_obstructed = false
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.aim_data = {
		min_radius_pseudo_random_c = 0.0701,
		max_radius_pseudo_random_c = 0.0095,
		min_radius = (math.pi / 72) / 4,
		max_radius = (math.pi / 16) / 6
	}
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.has_alternative_shot = true
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.always_use_alternative_attack = true
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.alternative_input = "release_ability_hold"
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.alternative_attack_min_charge_time = 0.26
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.alternative_attack_duration = 0.3
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.alternative_input_duration = 0.3
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.ignore_disabled_enemies_alternative = true
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.charge_input_threat = "defend"
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.disable_target_change = true
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.hit_only_zones = { head = true, neck = true }
	Weapons.kerillian_waywatcher_career_skill_weapon_piercing_shot.attack_meta_data.do_not_shoot_in_aoe_threat = true
	
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction = true
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.keep_distance = 6
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.aim_at_node = "j_head"
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.fire_input = "release_ability_hold"
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.minimum_charge_time = 0.11
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.charge_shot_delay = nil
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.charge_when_obstructed = false
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Boss, BreedCategory.Special, BreedCategory.SuperArmor)
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.aim_data = {
		-- min_radius_pseudo_random_c = 0.2081,
		-- max_radius_pseudo_random_c = 0.1175,
		-- min_radius = math.pi / 72 * 8,
		-- max_radius = math.pi / 16 * 8
	-- }
	
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction = true
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction_charged = true
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.keep_distance = 6
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.aim_at_node = "j_head"
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.minimum_charge_time = nil	--0.11
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.charge_shot_delay = nil
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.charge_when_obstructed = false
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.effective_against = bit.bor(BreedCategory.Infantry, BreedCategory.Berserker, BreedCategory.Boss, BreedCategory.Special, BreedCategory.SuperArmor)
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.aim_data = {
		min_radius_pseudo_random_c = 0.2081,
		max_radius_pseudo_random_c = 0.1175,
		min_radius = (math.pi / 72) * 8,
		max_radius = (math.pi / 16) * 8
	}
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.has_alternative_shot = true
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.always_use_alternative_attack = true
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.alternative_input = "release_ability_hold"
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.alternative_attack_min_charge_time = 0.2
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.alternative_attack_duration = 0.3
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.alternative_input_duration = 0.3
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.ignore_disabled_enemies_alternative = true
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.charge_input_threat = "defend"
	Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.disable_target_change = true
	-- Weapons.sienna_scholar_career_skill_weapon.attack_meta_data.do_not_shoot_in_aoe_threat = true
	
	-- Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction = false
	-- Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction_charged = false
	-- Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.keep_distance = 5
	-- Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.fire_input = "release_ability_hold"
	-- Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.minimum_charge_time = 0.36
	-- Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.charge_shot_delay = nil
	-- Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.charge_when_obstructed = false
	-- Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.aim_data = {
		-- min_radius_pseudo_random_c = 0.0699,
		-- max_radius_pseudo_random_c = 0.0101,
		-- min_radius = math.pi / 72 / 4,
		-- max_radius = math.pi / 16 / 6
	-- }
	
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction = false
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.ignore_enemies_for_obstruction_charged = false
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.keep_distance = 5
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.minimum_charge_time = nil	--0.36
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.charge_shot_delay = nil
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.charge_when_obstructed = false
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.aim_data = {
		min_radius_pseudo_random_c = 0.0699,
		max_radius_pseudo_random_c = 0.0101,
		min_radius = (math.pi / 72) / 4,
		max_radius = (math.pi / 16) / 6
	}
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.has_alternative_shot = true
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.always_use_alternative_attack = true
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.alternative_input = "release_ability_hold"
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.alternative_attack_min_charge_time = 0.1
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.alternative_attack_duration = 0.4
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.alternative_input_duration = 0.4
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.ignore_disabled_enemies_alternative = true
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.charge_input_threat = "defend"
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.disable_target_change = true
	Weapons.victor_bountyhunter_career_skill_weapon.attack_meta_data.do_not_shoot_in_aoe_threat = true
end
mod.update_melee_weapon_templates_meta = function()
-- NOTE: "penetrating" is not in use anymore

	-- Weapons.one_handed_crowbill.attack_meta_data.tap_attack.arc = 0
	
--edit--	check Weapons.one_handed_flail_template_1.attack_meta_data.hold_attack.attack_chain
--edit--	check WeaponUtils.add_bot_meta_data_chain_actions
	
	Weapons.one_handed_flails_flaming_template.attack_meta_data.tap_attack.penetrating = false
	Weapons.one_handed_flails_flaming_template.attack_meta_data.hold_attack.arc = 2
	
	Weapons.one_handed_sword_shield_template_1.attack_meta_data.tap_attack.arc = 1		--check this
	Weapons.one_handed_sword_shield_template_1.attack_meta_data.hold_attack.arc = 2		--check this
	
	Weapons.flaming_sword_template_1.attack_meta_data.tap_attack.arc = 1
	
	Weapons.we_one_hand_sword_template_1.attack_meta_data.tap_attack.arc = 2
	
	Weapons.two_handed_axes_template_2.attack_meta_data.tap_attack.penetrating = false
	
	Weapons.two_handed_billhooks_template.attack_meta_data.tap_attack.arc = 1
	Weapons.two_handed_billhooks_template.attack_meta_data.hold_attack.arc = 0
	
	Weapons.two_handed_cog_hammers_template_1.attack_meta_data.tap_attack.arc = 2
	Weapons.two_handed_cog_hammers_template_1.attack_meta_data.hold_attack.arc = 0
	
	Weapons.two_handed_heavy_spears_template.attack_meta_data.hold_attack.arc = 1
	
	Weapons.dual_wield_axe_falchion_template.attack_meta_data.tap_attack.arc = 1
	
	Weapons.dual_wield_hammer_sword_template.attack_meta_data.tap_attack.arc = 1	--2
	Weapons.dual_wield_hammer_sword_template.attack_meta_data.hold_attack.arc = 2
	
	Weapons.dual_wield_hammers_template.attack_meta_data.tap_attack.arc = 1	--2
	Weapons.dual_wield_hammers_template.attack_meta_data.hold_attack.arc = 2	--1
	Weapons.dual_wield_hammers_priest_template.attack_meta_data.tap_attack.arc = 1	--2
	Weapons.dual_wield_hammers_priest_template.attack_meta_data.hold_attack.arc = 2	--1
	
	Weapons.dual_wield_sword_dagger_template_1.attack_meta_data.tap_attack.arc = 2	--1
	Weapons.dual_wield_sword_dagger_template_1.attack_meta_data.hold_attack.arc = 1
	
	Weapons.dual_wield_swords_template_1.attack_meta_data.tap_attack.arc = 2
	Weapons.dual_wield_swords_template_1.attack_meta_data.tap_attack.penetrating = true
	
	Weapons.two_handed_swords_executioner_template_1.attack_meta_data.tap_attack.penetrating = false
	Weapons.two_handed_swords_executioner_template_1.attack_meta_data.hold_attack.penetrating = true
	
	Weapons.bastard_sword_template.attack_meta_data.tap_attack.arc = 2
	Weapons.bastard_sword_template.attack_meta_data.hold_attack.arc = 1
	Weapons.bastard_sword_template.attack_meta_data.tap_attack.penetrating = false
	Weapons.bastard_sword_template.attack_meta_data.hold_attack.penetrating = true
	
	Weapons.es_deus_01_template.attack_meta_data.tap_attack.arc = 2
	Weapons.es_deus_01_template.attack_meta_data.hold_attack.arc = 1
	
	Weapons.two_handed_spears_elf_template_1.attack_meta_data.tap_attack.arc = 1
	Weapons.two_handed_spears_elf_template_1.attack_meta_data.hold_attack.arc = 1
	Weapons.two_handed_spears_elf_template_1.attack_meta_data.tap_attack.penetrating = true
	
	Weapons.one_hand_axe_shield_template_1.attack_meta_data.hold_attack.penetrating = true
	
	--attack_chain experiment
--[[
	Weapons.we_one_hand_sword_template_1.attack_meta_data.tap_attack.attack_chain = {
		start_sub_action_name = "default",
		start_action_name = "action_one",
		transitions = {
			action_one = {
				default = {
					wanted_sub_action_name = "light_attack_left",
					wanted_action_name = "action_one",
					bot_wanted_input = "tap_attack"
				},
				default_right = {
					wanted_sub_action_name = "light_attack_right",
					wanted_action_name = "action_one",
					bot_wanted_input = "tap_attack"
				},
				-- default_left = {
					-- wanted_sub_action_name = "default",
					-- wanted_action_name = "action_two",
					-- bot_wait_input = "defend",
					-- bot_wanted_input = "defend"
				-- },
				-- heavy_attack_left = {
					-- wanted_sub_action_name = "default_left",
					-- wanted_action_name = "action_one",
					-- bot_wanted_input = "tap_attack"
				-- },
				-- heavy_attack_right = {
					-- wanted_sub_action_name = "default",
					-- wanted_action_name = "action_one",
					-- bot_wanted_input = "tap_attack"
				-- },
				-- heavy_attack_up = {
					-- wanted_sub_action_name = "default_right",
					-- wanted_action_name = "action_one",
					-- bot_wanted_input = "tap_attack"
				-- },
				light_attack_left = {
					wanted_sub_action_name = "default_right",
					wanted_action_name = "action_one",
					bot_wanted_input = "tap_attack"
				},
				light_attack_right = {
					-- wanted_sub_action_name = "default_left",
					-- wanted_action_name = "action_one",
					-- bot_wanted_input = "tap_attack"
					wanted_sub_action_name = "default",
					wanted_action_name = "action_two",
					bot_wait_input = "defend",
					bot_wanted_input = "defend"
				},
				-- light_attack_last = {
					-- wanted_sub_action_name = "default",
					-- wanted_action_name = "action_one",
					-- bot_wanted_input = "tap_attack"
				-- },
			},
			action_two = {
				default = {
					wanted_sub_action_name = "default",
					wanted_action_name = "action_one",
					bot_wanted_input = "tap_attack"
				},
			}
		}
	}
	
	WeaponUtils.add_bot_meta_data_chain_actions(Weapons.we_one_hand_sword_template_1.actions, Weapons.we_one_hand_sword_template_1.attack_meta_data.tap_attack.attack_chain.transitions)
--]]

--[[
	Weapons.one_handed_crowbill.attack_meta_data.tap_attack = {
		penetrating = true,
		arc = 0
	}
	-- Weapons.one_hand_falchion_template_1.attack_meta_data.tap_attack = {
--edit--	check this
		-- max_range = 2.25,
		-- arc = 1,
		-- penetrating = false
	-- }
--edit--	check Weapons.one_handed_flail_template_1.attack_meta_data.hold_attack.attack_chain
--edit--	check WeaponUtils.add_bot_meta_data_chain_actions
	Weapons.one_handed_flails_flaming_template.attack_meta_data.tap_attack = {
--edit--	check this
		-- penetrating = false,
		arc = 1
	}
	Weapons.one_handed_swords_template_1.attack_meta_data.tap_attack = {
		penetrating = false,
--edit--	check this
		arc = 2
	}
	Weapons.one_handed_sword_shield_template_1.attack_meta_data.hold_attack = {
--edit--	check this
		penetrating = true,
		arc = 1
	}
	Weapons.we_one_hand_sword_template_1.attack_meta_data.tap_attack = {
		penetrating = false,
--edit--	check this
		arc = 2
	}
	Weapons.two_handed_axes_template_2.attack_meta_data.tap_attack = {
		penetrating = true,
--edit--	check this
		arc = 1
	}
	Weapons.two_handed_billhooks_template.attack_meta_data.tap_attack = {
		penetrating = false,
		arc = 1
	}
	Weapons.two_handed_billhooks_template.attack_meta_data.hold_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.two_handed_cog_hammers_template_1.attack_meta_data.tap_attack = {
		penetrating = false,
		arc = 2
	}
	Weapons.two_handed_cog_hammers_template_1.attack_meta_data.hold_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.two_handed_heavy_spears_template.attack_meta_data.hold_attack = {
		penetrating = true,
		arc = 1
	}
	Weapons.two_handed_swords_executioner_template_1.attack_meta_data.tap_attack = {
--edit--	check this
		-- penetrating = false,
		arc = 2
	}
	Weapons.two_handed_swords_executioner_template_1.attack_meta_data.hold_attack = {
--edit--	check this
		-- penetrating = true,
		arc = 0
	}
	Weapons.bastard_sword_template.attack_meta_data.tap_attack = {
--edit--	check this
		-- penetrating = false,
		arc = 1
	}
	Weapons.bastard_sword_template.attack_meta_data.hold_attack = {
--edit--	check this
		-- penetrating = true,
		arc = 2
	}
	Weapons.dual_wield_axe_falchion_template.attack_meta_data.tap_attack = {
		penetrating = true,
		arc = 1
	}
	Weapons.dual_wield_hammer_sword_template.attack_meta_data.tap_attack = {
		penetrating = false,
		arc = 2
	}
	Weapons.dual_wield_hammer_sword_template.attack_meta_data.hold_attack = {
		penetrating = true,
		arc = 1
	}
	Weapons.dual_wield_hammers_template.attack_meta_data.tap_attack = {
		penetrating = false,
		arc = 1
	}
	Weapons.dual_wield_hammers_template.attack_meta_data.hold_attack = {
		penetrating = true,
		arc = 1
	}
	Weapons.dual_wield_sword_dagger_template_1.attack_meta_data.tap_attack = {
		penetrating = false,
		arc = 1
	}
	Weapons.dual_wield_sword_dagger_template_1.attack_meta_data.hold_attack = {
		penetrating = true,
		arc = 1
	}
	Weapons.two_handed_halberds_template_1.attack_meta_data.tap_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.two_handed_halberds_template_1.attack_meta_data.hold_attack = {
		penetrating = true,
		arc = 2
	}
	
	------------------------------
	--Melee weapons push attacks
	------------------------------
	
	Weapons.one_hand_axe_template_1.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.one_hand_axe_template_2.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.one_hand_axe_shield_template_1.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.we_one_hand_axe_template.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.one_handed_crowbill.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.one_handed_daggers_template_1.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 0
	}
	Weapons.one_hand_falchion_template_1.attack_meta_data.push_attack = {
--edit--	check this
		-- max_range = 2.25,
		arc = 1,
		penetrating = false
	}
	Weapons.one_handed_flail_template_1.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 1
	}
	Weapons.one_handed_flails_flaming_template.attack_meta_data.push_attack = {
--edit--	check this
		-- penetrating = false,
		arc = 1
	}
	Weapons.one_handed_hammer_template_1.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 2
	}
	Weapons.one_handed_hammer_template_2.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 2
	}
	Weapons.one_handed_hammer_shield_template_1.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.one_handed_hammer_shield_template_2.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.one_handed_hammer_wizard_template_1.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 2
	}
	Weapons.one_handed_spears_shield_template.attack_meta_data.push_attack = {
--edit--	check this
		penetrating = false,
		arc = 0
	}
	Weapons.one_handed_swords_template_1.attack_meta_data.push_attack = {
		penetrating = false,
--edit--	check this
		arc = 2
	}
	Weapons.flaming_sword_spell_template_1.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 1
	}
	Weapons.one_handed_sword_shield_template_1.attack_meta_data.push_attack = {
--edit--	check this
		penetrating = false,
		arc = 0
	}
	Weapons.one_handed_sword_shield_template_2.attack_meta_data.push_attack = {
--edit--	check this
		penetrating = false,
		arc = 0
	}
	Weapons.flaming_sword_template_1.attack_meta_data.push_attack = {
--edit--	check this
		penetrating = false,
		arc = 2
	}
	Weapons.we_one_hand_sword_template_1.attack_meta_data.push_attack = {
		penetrating = false,
--edit--	check this
		arc = 2
	}
	Weapons.two_handed_axes_template_1.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 1
	}
	Weapons.two_handed_axes_template_2.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 1
	}
	Weapons.two_handed_billhooks_template.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 2
	}
	Weapons.two_handed_cog_hammers_template_1.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 2
	}
	Weapons.two_handed_hammers_template_1.attack_meta_data.push_attack = {
--edit--	check this
		max_range = 3,
		arc = 2,
		penetrating = true
	}
	Weapons.two_handed_heavy_spears_template.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 2
	}
	Weapons.two_handed_picks_template_1.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.two_handed_swords_template_1.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.two_handed_swords_executioner_template_1.attack_meta_data.push_attack = {
--edit--	check this
		-- penetrating = false,
		arc = 2
	}
	Weapons.two_handed_swords_wood_elf_template.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 1
	}
	Weapons.bastard_sword_template.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.dual_wield_axe_falchion_template.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 1
	}
	Weapons.dual_wield_axes_template_1.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.dual_wield_daggers_template_1.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 0
	}
	Weapons.dual_wield_hammer_sword_template.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 1
	}
	Weapons.dual_wield_hammers_template.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 0
	}
	Weapons.dual_wield_hammers_template.attack_meta_data.push_attack = {
--edit--	check this
		penetrating = true,
		arc = 0
	}
	Weapons.dual_wield_sword_dagger_template_1.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.dual_wield_swords_template_1.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.es_deus_01_template.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.fencing_sword_template_1.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 1
	}
	Weapons.two_handed_halberds_template_1.attack_meta_data.push_attack = {
		penetrating = true,
		arc = 0
	}
	Weapons.two_handed_spears_elf_template_1.attack_meta_data.push_attack = {
		penetrating = false,
		arc = 1
	}
--]]
end
mod.post_update_weapon_templates_meta = function()
	--check this
	
	local MeleeBuffTypes = MeleeBuffTypes or {
		MELEE_1H = true,
		MELEE_2H = true
	}
	
	local RangedBuffTypes = RangedBuffTypes or {
		RANGED_ABILITY = true,
		RANGED = true
	}
	
	local WEAPON_DAMAGE_UNIT_LENGTH_EXTENT = 1.919366
	local TAP_ATTACK_BASE_RANGE_OFFSET = 0.6
	local HOLD_ATTACK_BASE_RANGE_OFFSET = 0.65
	
	for item_template_name, item_template in pairs(Weapons) do
		item_template._precalculated_metadata = false
	
		item_template.name = item_template_name
		item_template.crosshair_style = item_template.crosshair_style or "dot"
		local attack_meta_data = item_template.attack_meta_data
		local tap_attack_meta_data = attack_meta_data and attack_meta_data.tap_attack
		local hold_attack_meta_data = attack_meta_data and attack_meta_data.hold_attack
		local set_default_tap_attack_range = tap_attack_meta_data and tap_attack_meta_data.max_range == nil
		local set_default_hold_attack_range = hold_attack_meta_data and hold_attack_meta_data.max_range == nil

		if RangedBuffTypes[item_template.buff_type] and attack_meta_data then
			attack_meta_data.effective_against = attack_meta_data.effective_against or 0
			attack_meta_data.effective_against_charged = attack_meta_data.effective_against_charged or 0
			attack_meta_data.effective_against_alternative = attack_meta_data.effective_against_alternative or nil
			local effective_against_alternative = attack_meta_data.effective_against_alternative or 0
			attack_meta_data.effective_against_combined = bit.bor(attack_meta_data.effective_against, attack_meta_data.effective_against_charged, effective_against_alternative)
		end

		if MeleeBuffTypes[item_template.buff_type] then
			fassert(attack_meta_data, "Missing attack metadata for weapon %s", item_template_name)
			fassert(tap_attack_meta_data, "Missing tap_attack metadata for weapon %s", item_template_name)
			fassert(hold_attack_meta_data, "Missing hold_attack metadata for weapon %s", item_template_name)
			fassert(tap_attack_meta_data.arc, "Missing arc parameter in tap_attack metadata for weapon %s", item_template_name)
			fassert(hold_attack_meta_data.arc, "Missing arc parameter in hold_attack metadata for weapon %s", item_template_name)
		end

		local actions = item_template.actions

		for action_name, sub_actions in pairs(actions) do
			for sub_action_name, sub_action_data in pairs(sub_actions) do
				local lookup_data = {
					item_template_name = item_template_name,
					action_name = action_name,
					sub_action_name = sub_action_name
				}
				sub_action_data.lookup_data = lookup_data
				local action_kind = sub_action_data.kind
				local action_assert_func = ActionAssertFuncs[action_kind]

				if action_assert_func then
					action_assert_func(item_template_name, action_name, sub_action_name, sub_action_data)
				end

				if action_name == "action_one" then
					local range_mod = sub_action_data.range_mod or 1

					if set_default_tap_attack_range and string.find(sub_action_name, "light_attack") then
						local current_attack_range = tap_attack_meta_data.max_range or math.huge
						local tap_attack_range = TAP_ATTACK_BASE_RANGE_OFFSET + WEAPON_DAMAGE_UNIT_LENGTH_EXTENT * range_mod
						tap_attack_meta_data.max_range = math.min(current_attack_range, tap_attack_range)
					elseif set_default_hold_attack_range and string.find(sub_action_name, "heavy_attack") then
						local current_attack_range = hold_attack_meta_data.max_range or math.huge
						local hold_attack_range = HOLD_ATTACK_BASE_RANGE_OFFSET + WEAPON_DAMAGE_UNIT_LENGTH_EXTENT * range_mod
						hold_attack_meta_data.max_range = math.min(current_attack_range, hold_attack_range)
					end
				end

				local impact_data = sub_action_data.impact_data

				if impact_data then
					local pickup_settings = impact_data.pickup_settings

					if pickup_settings then
						local link_hit_zones = pickup_settings.link_hit_zones

						if link_hit_zones then
							for i = 1, #link_hit_zones, 1 do
								local hit_zone_name = link_hit_zones[i]
								link_hit_zones[hit_zone_name] = true
							end
						end
					end
				end
			end
		end
	end
end
