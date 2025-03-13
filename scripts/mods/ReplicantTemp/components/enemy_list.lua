local mod = get_mod("ReplicantTemp")

mod.TRASH_UNITS = {
	skaven_slave = true,
	skaven_clan_rat = true,
	skaven_clan_rat_with_shield = true,
	chaos_fanatic = true,
	chaos_marauder = true,
	chaos_marauder_with_shield = true,
	skaven_dummy_clan_rat = true, -- Dutch, unbreakable shield marauder
	beastmen_gor = true,
	beastmen_ungor = true,
	beastmen_ungor_archer = true,

	chaos_zombie = true,
	
	ethereal_skeleton_with_hammer = true,
	ethereal_skeleton_with_shield = true,
}
mod.TRASH_UNITS_EXCEPT_ARCHERS = {
	skaven_slave = true,
	skaven_clan_rat = true,
	skaven_clan_rat_with_shield = true,
	chaos_fanatic = true,
	chaos_marauder = true,
	chaos_marauder_with_shield = true,
	skaven_dummy_clan_rat = true, -- Dutch, unbreakable shield marauder
	beastmen_gor = true,
	beastmen_ungor = true,
	-- beastmen_ungor_archer = true,

	chaos_zombie = true,
	
	ethereal_skeleton_with_hammer = true,
	ethereal_skeleton_with_shield = true,
}
mod.TRASH_UNITS_AND_SHIELD_SV = {
	skaven_slave = true,
	skaven_clan_rat = true,
	skaven_clan_rat_with_shield = true,
	chaos_fanatic = true,
	chaos_marauder = true,
	chaos_marauder_with_shield = true,
	skaven_dummy_clan_rat = true, -- Dutch, unbreakable shield marauder
	beastmen_gor = true,
	beastmen_ungor = true,
	beastmen_ungor_archer = true,

	skaven_storm_vermin_with_shield = true,
	
	chaos_zombie = true,
	
	ethereal_skeleton_with_hammer = true,
	ethereal_skeleton_with_shield = true,
}
mod.TRASH_UNITS_AND_SHIELD_SV_EXCEPT_ARCHERS = {
	skaven_slave = true,
	skaven_clan_rat = true,
	skaven_clan_rat_with_shield = true,
	chaos_fanatic = true,
	chaos_marauder = true,
	chaos_marauder_with_shield = true,
	skaven_dummy_clan_rat = true, -- Dutch, unbreakable shield marauder
	beastmen_gor = true,
	beastmen_ungor = true,
	-- beastmen_ungor_archer = true,

	skaven_storm_vermin_with_shield = true,
	
	chaos_zombie = true,
	
	ethereal_skeleton_with_hammer = true,
	ethereal_skeleton_with_shield = true,
}
mod.ELITE_UNITS = {
	skaven_storm_vermin = true,
	skaven_storm_vermin_commander = true,
	skaven_storm_vermin_with_shield = true,
	chaos_raider = true,
	chaos_warrior = true,
	beastmen_bestigor = true,
	skaven_dummy_slave = true, -- Dutch, super-armor shielded SV
	chaos_marauder_tutorial = true, -- Dutch, armored zerker
	chaos_raider_tutorial = true, -- Dutch, weird raider 
	
	beastmen_standard_bearer = true,
}
mod.ELITE_UNITS_AOE = {
	skaven_storm_vermin = true,
	skaven_storm_vermin_commander = true,
	-- skaven_storm_vermin_with_shield = true,
	chaos_raider = true,
	chaos_warrior = true,
	beastmen_bestigor = true,
	
	beastmen_standard_bearer = true,
	
	-- ethereal_skeleton_with_hammer = true,
}
mod.BERSERKER_UNITS = {
	skaven_plague_monk = true,
	chaos_berzerker = true,
	chaos_marauder_tutorial = true, -- Dutch, armored zerker
}
mod.SPECIAL_UNITS = {
	skaven_warpfire_thrower = true,
	skaven_ratling_gunner = true,
	skaven_pack_master = true,
	skaven_gutter_runner = true,
	skaven_poison_wind_globadier = true,
	chaos_vortex_sorcerer = true,
	chaos_corruptor_sorcerer = true,
	
	-- beastmen_standard_bearer = true,		--would make bots shoot it, check later

	skaven_explosive_loot_rat = true,

	curse_mutator_sorcerer = true,
	
	chaos_plague_wave_spawner = true,
}
mod.SPECIAL_UNITS_AND_ARCHERS = {
	skaven_warpfire_thrower = true,
	skaven_ratling_gunner = true,
	skaven_pack_master = true,
	skaven_gutter_runner = true,
	skaven_poison_wind_globadier = true,
	chaos_vortex_sorcerer = true,
	chaos_corruptor_sorcerer = true,
	
	beastmen_ungor_archer = true,
	-- beastmen_standard_bearer = true,		--would make bots shoot it, check later

	skaven_explosive_loot_rat = true,

	curse_mutator_sorcerer = true,
	chaos_plague_wave_spawner = true,
}
mod.BOSS_UNITS = {
	skaven_rat_ogre = true,
	skaven_stormfiend = true,
	chaos_troll = true,
	chaos_spawn = true,
	beastmen_minotaur = true,

	chaos_spawn_exalted_champion_norsca = true,
	skaven_stormfiend_boss = true,
}
mod.LORD_UNITS = {
	-- skaven_storm_vermin_champion = true,
	skaven_storm_vermin_warlord = true,
	chaos_exalted_sorcerer = true,
	
	chaos_exalted_champion_warcamp = true,
	chaos_exalted_champion_norsca = true,
	chaos_spawn_exalted_champion_norsca = true,
	skaven_grey_seer = true,
	skaven_stormfiend_boss = true,
	chaos_exalted_sorcerer_drachenfels = true,
}
mod.LORD_UNITS_LARGE = {	--mostly for calculating engage position
	-- skaven_storm_vermin_champion = true,
	skaven_storm_vermin_warlord = true,
	chaos_exalted_champion_warcamp = true,
	chaos_exalted_champion_norsca = true,
	-- chaos_spawn_exalted_champion_norsca = true,
	-- skaven_stormfiend_boss = true,
}
mod.BOSS_AND_LORD_UNITS = {
	skaven_rat_ogre = true,
	skaven_stormfiend = true,
	chaos_troll = true,
	chaos_spawn = true,
	beastmen_minotaur = true,
	
	-- skaven_storm_vermin_champion = true,
	skaven_storm_vermin_warlord = true,
	chaos_exalted_sorcerer = true,
	chaos_exalted_champion_warcamp = true,
	chaos_exalted_champion_norsca = true,
	chaos_spawn_exalted_champion_norsca = true,
	skaven_grey_seer = true,
	skaven_stormfiend_boss = true,
	chaos_exalted_sorcerer_drachenfels = true,
}
mod.BOSS_UNITS_WITH_RUNNING_ATTACK = {
	skaven_rat_ogre = true,
	chaos_troll = true,
	chaos_spawn = true,
	chaos_spawn_exalted_champion_norsca = true,
	beastmen_minotaur = true,
}
mod.CRITTER_UNITS = {
	critter_rat = true,
	critter_pig = true,
	skaven_loot_rat = true,

	chaos_greed_pinata = true,
}
mod.FRIENDS = {
	pet_skeleton = true,
	pet_skeleton_armored = true,
	pet_skeleton_dual_wield = true,
	pet_skeleton_with_shield = true
}

mod.get_spawned_rats_by_breed = function(breed_name)
    local spawn_table = Managers.state.conflict:spawned_units_by_breed(breed_name)
    
    return spawn_table
end
mod.get_spawned_specials = function()
	local ret = {}
	local spawns = {}
	for breed_name,_ in pairs(mod.SPECIAL_UNITS) do
		spawns = mod.get_spawned_rats_by_breed(breed_name)
		for _,unit in pairs(spawns) do ret[#ret+1] = unit end
	end
	
	return ret
end
mod.get_spawned_specials_and_archers = function()
	local ret = {}
	local spawns = {}
	for breed_name,_ in pairs(mod.SPECIAL_UNITS_AND_ARCHERS) do
		spawns = mod.get_spawned_rats_by_breed(breed_name)
		for _,unit in pairs(spawns) do ret[#ret+1] = unit end
	end
	
	return ret
end
mod.get_spawned_bosses_and_lords = function()
	local ret = {}
	local spawns = {}
	for breed_name,_ in pairs(mod.BOSS_AND_LORD_UNITS) do
		spawns = mod.get_spawned_rats_by_breed(breed_name)
		for _,unit in pairs(spawns) do ret[#ret+1] = unit end
	end
	
	return ret
end
mod.get_spawned_running_attack_bosses = function()
	local ret = {}
	local spawns = {}
	for breed_name,_ in pairs(mod.BOSS_UNITS_WITH_RUNNING_ATTACK) do
		spawns = mod.get_spawned_rats_by_breed(breed_name)
		for _,unit in pairs(spawns) do ret[#ret+1] = unit end
	end
	
	return ret
end
mod.get_spawned_friendly_skeletons = function ()
	local ret = {}
	local spawns = {}
	for breed_name,_ in pairs(mod.FRIENDS) do
		spawns = mod.get_spawned_rats_by_breed(breed_name)
		for _,unit in pairs(spawns) do ret[#ret+1] = unit end
	end
	
	return ret
end