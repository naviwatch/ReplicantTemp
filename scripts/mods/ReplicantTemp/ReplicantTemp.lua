local mod = get_mod("ReplicantTemp")
local mod_name = mod:get_name()

--Change Logs
--[[
8 May 2023: Fixed bot failing to use the ults of Waystalker, Bounty Hunter and Pyromancer (mainly was me misusing Bit of Bots Improvements mod); made bots don't path to bosses when they are shooting (experimental); made bots also stop chasing globadiers and blightstormers even when unable to shoot; made bots don't melee rush mass elites or bosses, especially when alone; added an option to print bot guard broken message (partly for debug purpose)
5 May 2023: Extended block duration for bots in response to Chaos Spawn's and Minotaur's combo attacks and melee shoves doing damage after attack is ended
4 May 2023: Added hotkeys to teleport bots to host or followed players; reduced tendency of bots auto-teleporting
2 May 2023: Tweaked melee positioning and defense especially when facing monsters
29 Apr 2023: Let bots detect whether they are surrounded by enemies and move away accordingly, weakened the "separation enemy threat" targeting priority as it doesn't fit the more free-form combat style of VT2
28 Apr 2023: Implemented more portions of melee combat logic from VT1 Different Bots / Replicant Bots
27 Apr 2023: Increased threat requirement for Warrior Priest bot's ult, attempted to add considertion to Tower of the Treachery enemies and skulls
26 Apr 2023: More copy-pasted codes (for now) to make bots dodge trash attacks when reloading, using ult and drinking potions
25 Apr 2023: Implemented some more features from Bit Of Bots Improvements - v0.665 and its modular mod structure, added some random lower bound to special detection, let bots dodge while drinking healing draughts
23 Apr 2023: Adjusted weapon attack meta to be more suitable for VT2 bot shooting codes and recent collected data, made bots more eager to use ranged weapons under threat (experimental), made bots shoot ungor archers, tweaked zealot's AI to take damage
22 Apr 2023: Fixed bots ignoring the Chaos Spawn in Skittergate mid-event, let bots dodge Leech grab, let bots dodge while using ranged weapons
21 Apr 2023: Revised weapon attack meta (i.e. how bots use weapons) including some ult abilities, changed packmaster dodge timing, changed boss melee logic, refined defend logic (and fixed a few logical gaps)
20 Apr 2023: Let bots predict and avoid poison globe landing spot
19 Apr 2023: Fixed mod.on_enabled not executed because mod is set to untoggleable
26 Mar 2022: Fixed some bugs (thanks to Stalker) regarding dodging and pushing. Removed unsuccessful bug fixes or tweaks.
19 Jan 2022: Follow positions are now further from the human player. Increase bots' stickiness to melee weapons to prevent snap switching when enemies are knocked back.
24 Nov 2021: Now testing all the ult changes from the Bit Of Bots Improvements mod; stop some bots using ult near unaggroed patrols
17 Nov 2021: Some optimizations for Halescourge / Into the Nest / War Camp lord fights; bots try to attack the disabling projectiles in Halescourge and Drachenfels maps
14 Nov 2021: Adjust bots defense timing against elites to reduce blocking time
11 Nov 2021: Shield bots take risk to push when too many enemies are in push range (likely surrounded); other changes are added in the feature section
4 Nov 2021: Release 1.0
There can be small changes seen from the last update time, but I am not going to put it in change log everytime

==============

This mod includes some features from the VT1 Different Bots (or Xq's bots):
https://steamcommunity.com/sharedfiles/filedetails/?id=2262580549

Also has some new changes specific to VT2 bot codes.

I hooked some functions in Bot Improvements Combat so there can be possible conflicts, but I don't see any negative effects so far.
The Bit Of Bots Improvements mod also hooked some functions here so depending on load order one will overwrite the other for those functionality.

===Features===

- Bots stand on the side and back of the followed human player to avoid blocking fire lines, weaker effect when bots are already engaged in melee combat

- Better Path Learning: In base game bots can already learn human paths (jump spots / drop spots etc.), but fail to learn sometimes when humans don't land on nav mesh. Now a possible path is added to 'pending learning path' and if humans subsequently walk on nav mesh a new path can be added to bot database.

- Bots are less fixated to reach the exact destination to avoid getting stuck
- Increase bot teleport tendency if can't be resolved by current pathing technology
- Bots block on teleport action

- Overhaul bots' target selection; bots with sniper weapons target elites first, and all bots decide to target the bosses or not using more surrounding information
- Stop bots from chasing far-away enemies or certain enemy types; stop bots from meleeing Packmasters
- Allow bots to target / shoot further specials; fix a 'bug' that the special detection system ignores some specials
- Bots don't take cover from Ratling Gunner's line of fire and don't try to dodge it unless within lethal range
- Bots don't shoot in the direction of un-aggroed patrols
- Add area damage checks (gas cloud / barrels etc.) to bot melee action and vent action
- Bots ignore blob and Troll puke etc. since they take more damage from being idle. Lead them away from those threats if you don't want them to take poison damage.
- Increase bot regroup distance when it is targeted by a monster which can do running attack

- Bots aim at head when fighting melee (except for Maulers and a few others); bots aim at Stormfiend's weak spot when flanking it
- Improve the bots' willingness to use ranged weapons
- Improve bot aim accuracy and aim rotation speed with ranged weapons; changed the obstruction check to ignore other enemies and allies
- Change how bots use some ranged weapons (i.e. the attack meta data), e.g. bots shoot at head with sniper type weapons so they do quite well with conservative shooter
- Part of the attack meta change, bots with some ranged weapons will play as backliner and try to maintain distance from enemies
- Bots with certain ranged weapons use ranged against monsters even in melee range, provided that situation is safe

- Bots block while dodging AoE attack, and fix possible dodge input errors (that prevent bots from dodging successfully because of user's dodge settings)
- Improve bot defense decisions against multiple enemies & enemy types
- Improve bot melee aggressiveness against single enemy
- Change bot melee positioning decision
- Slight change to how bots use some melee weapons (i.e. the attack meta data)
- Some defense action tweaks against bosses

- Mercenary, Ranger Veteran, Ironbreaker and Witch Hunter Captain shouldn't use ult near unaggroed patrol
- Zealot doesn't defend against trash unit attack when Heart of Iron is active and Fiery Faith max stack is not achieved

- Prevent bots from traveling too far to pickup items automatically (thus getting stuck in the process)
- Increase bot pickup distance (at which bots can interact with the item) when the bot has pickup order

===Bit Of Bots Improvements===
This mod also experiments on some features in the Bit Of Bots Improvements mod:
https://steamcommunity.com/sharedfiles/filedetails/?id=2577718836

- Prevent bots from automatically picking up tomes
- Pyromancer and Unchained bot won't vent if below 55% overcharge
- Ult decision change and using ult for revive (Sister of the Thorn ult change currently disabled because the bot is getting hits)

===Comments As An User===

- Now I have most settings in Bot Improvements Combat disabled, except the healing changes
- Bots dodge occasionally but they don't know the map geometry so it's possible they just dodge off ledge. Try to stay further away from ledges when fighting melee.
--]]




mod.DEBUG = false

mod:dofile("scripts/mods/"..mod_name.."/components/bt_parallel_node")				--_bt_parallel_node

mod:dofile("scripts/mods/"..mod_name.."/components/utility")						--Utility
mod:dofile("scripts/mods/"..mod_name.."/components/enemy_list")

mod:dofile("scripts/mods/"..mod_name.."/components/enemy_hooks")

mod:dofile("scripts/mods/"..mod_name.."/components/bt_bot_inventory_switch_action")	--_bt_bot_inventory_switch_action
mod:dofile("scripts/mods/"..mod_name.."/components/career_ability_set_state")		--_career_ability_we_shade	--_career_ability_wh_zealot	--_career_ability_dr_slayer	--_career_ability_es_huntsman

mod:dofile("scripts/mods/"..mod_name.."/components/player_bots_settings")			--_player_bots_settings
-- mod:dofile("scripts/mods/"..mod_name.."/components/bt_bot_conditions")			--_bt_bot_conditions	--UNUSED, see function hooks in this file below instead
mod:dofile("scripts/mods/"..mod_name.."/components/bt_bot")							--_bt_bot

mod:dofile("scripts/mods/"..mod_name.."/components/components")						--Components
mod:dofile("scripts/mods/"..mod_name.."/components/ping_enemies")					--PingEnemies
mod:dofile("scripts/mods/"..mod_name.."/components/healing_tweaks")					--HealingTweaks
mod:dofile("scripts/mods/"..mod_name.."/components/line_of_fire_tweaks")			--LineOfFireTweaks
mod:dofile("scripts/mods/"..mod_name.."/components/pickup_tweaks")					--PickupTweaks
-- mod:dofile("scripts/mods/"..mod_name.."/components/targeting_tweaks")			--AggroTweaks	--UNUSED in the Bit of Bots Improvements
mod:dofile("scripts/mods/"..mod_name.."/components/revive_tweaks")					--ImprovedRevive
mod:dofile("scripts/mods/"..mod_name.."/components/reload_vent_tweaks")				--OverchargeTweaks
mod:dofile("scripts/mods/"..mod_name.."/components/melee_selection_tweaks")			--BetterMelee
mod:dofile("scripts/mods/"..mod_name.."/components/ability_activate_conditions")	--RegularActivateAbilityTweaks
mod:dofile("scripts/mods/"..mod_name.."/components/rescue_ability")					--RescueAlliesActivateAbility

mod:dofile("scripts/mods/"..mod_name.."/components/bt_bot_drink_pot_action")		--bt_bot_drink_pot_action	--DrinkingPotions

mod:dofile("scripts/mods/"..mod_name.."/components/weapon_templates_meta")			--_weapon_templates
mod:dofile("scripts/mods/"..mod_name.."/components/ai_bot_group_system")			--_ai_bot_group_system
mod:dofile("scripts/mods/"..mod_name.."/components/player_bot_base")				--_player_bot_base
mod:dofile("scripts/mods/"..mod_name.."/components/bt_bot_shoot_action")			--_bt_bot_shoot_action

mod:dofile("scripts/mods/"..mod_name.."/components/bt_bot_activate_ability_action")	--_bt_bot_activate_ability_action

-- mod:dofile("scripts/mods/"..mod_name.."/components/dynamic_data")
mod:dofile("scripts/mods/"..mod_name.."/components/manual_teleport")



--PlayerBotBase._update_weapon_metadata
--[[
local update_breed_threat_data = function()
	Breeds.skaven_pack_master.bot_opportunity_target_melee_range = 0
	Breeds.skaven_pack_master.bot_opportunity_target_melee_range_while_ranged = 0
	
	BreedActions.skaven_warpfire_thrower.shoot_warpfire_thrower.bot_threat_radius = 5	--5.4
	
	BreedActions.skaven_rat_ogre.melee_slam.bot_threats = {		--attack_slam, attack_slam_2, attack_slam_3, attack_slam_4
		{
			duration = 0.45,
			start_time = 0.1
		}
	}
	BreedActions.skaven_rat_ogre.combo_attack.attacks[1].bot_threats = {	--attack_combo_fwd
		{
			range = 3.5,
			duration = 0.45,
			start_time = 0.3
		},
		{
			range = 3.5,
			duration = 0.45,
			start_time = 1.15
		},
		{
			range = 3.5,
			duration = 0.45,
			start_time = 1.9
		}
	}
	BreedActions.skaven_rat_ogre.melee_shove.running_attacks[1].bot_threats = {		--attack_shove_left_run, attack_shove_right_run
		attack_shove_left_run = {
			{
				collision_type = "cylinder",
				offset_forward = 0,
				radius = 4.5,
				height = 4,
				offset_right = 0,
				offset_up = 0,
				duration = 0.65,
				start_time = 0.1
			}
		},
		attack_shove_right_run = {
			{
				collision_type = "cylinder",
				offset_forward = 0,
				radius = 4.5,
				height = 4,
				offset_right = 0,
				offset_up = 0,
				duration = 0.75,
				start_time = 0.1
			}
		}
	}
	
	-- BreedActions.chaos_troll.melee_sweep.attacks[1].bot_threats = {		--attack_sweep
		-- {
			-- collision_type = "cylinder",
			-- offset_forward = 0,
			-- radius = 3,
			-- height = 3.5,
			-- offset_right = 0,
			-- offset_up = 0,
			-- duration = 0.6666666666666666,
			-- start_time = 0.3333333333333333
		-- }
	-- }
	BreedActions.chaos_troll.melee_sweep.running_attacks[1].bot_threats = {		--attack_move_sweep
		{
			collision_type = "cylinder",
			offset_forward = 2,
			radius = 3,
			height = 3.7,
			offset_right = 0,
			offset_up = 0,
			duration = 0.6666666666666666,
			start_time = 0.3333333333333333
		}
	}
	BreedActions.chaos_troll.melee_shove.attacks[1].bot_threats = {		--attack_shove
		{
			collision_type = "cylinder",
			offset_forward = 0,
			radius = 3,
			height = 3.5,
			offset_right = 0,
			offset_up = 0,
			duration = 0.65,
			start_time = 0.3
		}
	}
	BreedActions.chaos_troll.melee_shove.running_attacks[1].bot_threats = {		--attack_pounce
		{
			collision_type = "cylinder",
			offset_forward = 2,
			radius = 3,
			height = 3.7,
			offset_right = 0,
			offset_up = 0,
			duration = 0.75,
			start_time = 0.3
		}
	}
	-- BreedActions.chaos_troll.attack_cleave.attacks[1].bot_threats = {	--attack_cleave
		-- {
			-- duration = 0.6666666666666666,
			-- start_time = 1
		-- }
	-- }
	BreedActions.chaos_troll.attack_cleave.running_attacks[1].bot_threats = {	--attack_move_cleave
		{
			duration = 0.55,	--0.65
			start_time = 0.85	--0.3
		}
	}
	
	BreedActions.chaos_spawn.combo_attack.attacks[1].damage_done_time = 1.61	--testing, ideally I change the _defend function
	BreedActions.chaos_spawn.combo_attack.attacks[1].bot_threats = {	--attack_melee_combo
		{
			range = 3.5,
			duration = 0.35,
			start_time = 0
		},
		{
			range = 3.5,
			duration = 0.45,
			start_time = 0.35
		},
		{
			range = 3.5,
			duration = 0.45,
			start_time = 0.8
		},
		{
			range = 3.5,
			duration = 0.45,
			start_time = 1.2
		}
	}
	BreedActions.chaos_spawn.combo_attack.attacks[2].damage_done_time = 1.95	--testing, ideally I change the _defend function
	BreedActions.chaos_spawn.combo_attack.attacks[2].bot_threats = {	--attack_melee_combo_2
		{
			range = 3.5,
			duration = 0.45,
			start_time = 0.15
		},
		{
			range = 3.5,
			duration = 0.45,
			start_time = 0.9
		},
		{
			range = 3.5,
			duration = 0.45,
			start_time = 1.55
		}
	}
	BreedActions.chaos_spawn.tentacle_grab.attacks[1].bot_threats = {	--attack_grab
		{
			collision_type = "cylinder",
			offset_forward = 0,
			radius = 4.5,
			height = 4,
			offset_right = 0,
			offset_up = 0,
			duration = 0.85,
			start_time = 0.2
		}
	}
	BreedActions.chaos_spawn.melee_slam.bot_threats = {		--attack_melee_claw
		{
			duration = 0.45,
			start_time = 0.1
		}
	}
	BreedActions.chaos_spawn.melee_shove.attacks[1].damage_done_time = 1.3		--testing, ideally I change the _defend function
	BreedActions.chaos_spawn.melee_shove.attacks[1].bot_threats = {		--attack_melee_sweep
		{
			collision_type = "cylinder",
			offset_forward = 0,
			radius = 4.5,
			height = 4,
			offset_right = 0,
			offset_up = 0,
			duration = 0.9,
			start_time = 0.45
		}
	}
	
	BreedActions.beastmen_minotaur.combo_attack.attacks[1].damage_done_time = 2.33		--testing, ideally I change the _defend function
	BreedActions.beastmen_minotaur.combo_attack.attacks[1].bot_threats = {		--attack_melee_combo
		{
			range = 3.5,
			duration = 0.45,
			start_time = 0.15
		},
		{
			range = 3.5,
			duration = 0.45,
			start_time = 0.75
		},
		{
			range = 3.5,
			duration = 0.45,
			start_time = 0.9
		},
		{
			range = 3.5,
			duration = 0.45,
			start_time = 1.9
		}
	}
	BreedActions.beastmen_minotaur.melee_shove.attacks[1].damage_done_time = {		--testing, ideally I change the _defend function
		attack_right = 0.81,
		attack_left = 0.75
	}
	BreedActions.beastmen_minotaur.melee_shove.attacks[1].bot_threats = {	--attack_left, attack_right
		attack_left = {
			{
				collision_type = "cylinder",
				offset_forward = 0.5,
				radius = 4.5,
				height = 4,
				offset_right = 0,
				offset_up = 0,
				duration = 0.5,
				start_time = 0.25
			}
		},
		attack_right = {
			{
				collision_type = "cylinder",
				offset_forward = 0.5,
				radius = 4.5,
				height = 4,
				offset_right = 0,
				offset_up = 0,
				duration = 0.6,
				start_time = 0.25
			}
		}
	}
	BreedActions.beastmen_minotaur.headbutt_attack.attacks[1].bot_threats = {	--attack_headbutt
		attack_headbutt = {
			{
				collision_type = "cylinder",
				offset_forward = 0.5,
				radius = 4.5,
				height = 4,
				offset_right = 0,
				offset_up = 0,
				duration = 0.5,
				start_time = 0.3
			}
		}
	}
end
--]]
local update_breed_threat_data2 = function()
	Breeds.skaven_pack_master.bot_opportunity_target_melee_range = 0
	Breeds.skaven_pack_master.bot_opportunity_target_melee_range_while_ranged = 0
	
	BreedActions.skaven_warpfire_thrower.shoot_warpfire_thrower.bot_threat_radius = 5	--5.4
	
	BreedActions.skaven_rat_ogre.melee_slam.bot_threats = {		--attack_slam, attack_slam_2, attack_slam_3, attack_slam_4
		{
			duration = 0.55,
			start_time = 0
		}
	}
	BreedActions.skaven_rat_ogre.combo_attack.attacks[1].bot_threats = {	--attack_combo_fwd
		{
			range = 3.5,
			duration = 0.55,
			start_time = 0.2
		},
		{
			range = 3.5,
			duration = 0.55,
			start_time = 1.05
		},
		{
			range = 3.5,
			duration = 0.55,
			start_time = 1.8
		}
	}
	BreedActions.skaven_rat_ogre.melee_shove.running_attacks[1].bot_threats = {		--attack_shove_left_run, attack_shove_right_run
		attack_shove_left_run = {
			{
				collision_type = "cylinder",
				offset_forward = 0,
				radius = 4.5,
				height = 4,
				offset_right = 0,
				offset_up = 0,
				duration = 0.75,
				start_time = 0
			}
		},
		attack_shove_right_run = {
			{
				collision_type = "cylinder",
				offset_forward = 0,
				radius = 4.5,
				height = 4,
				offset_right = 0,
				offset_up = 0,
				duration = 0.85,
				start_time = 0
			}
		}
	}
	
	-- BreedActions.chaos_troll.melee_sweep.attacks[1].bot_threats = {		--attack_sweep
		-- {
			-- collision_type = "cylinder",
			-- offset_forward = 0,
			-- radius = 3,
			-- height = 3.5,
			-- offset_right = 0,
			-- offset_up = 0,
			-- duration = 0.6666666666666666,
			-- start_time = 0.3333333333333333
		-- }
	-- }
	BreedActions.chaos_troll.melee_sweep.running_attacks[1].bot_threats = {		--attack_move_sweep
		{
			collision_type = "cylinder",
			offset_forward = 2,
			radius = 3,
			height = 3.7,
			offset_right = 0,
			offset_up = 0,
			duration = 0.7666666666666666,
			start_time = 0.2333333333333333
		}
	}
	BreedActions.chaos_troll.melee_shove.attacks[1].bot_threats = {		--attack_shove
		{
			collision_type = "cylinder",
			offset_forward = 0,
			radius = 3,
			height = 3.5,
			offset_right = 0,
			offset_up = 0,
			duration = 0.75,
			start_time = 0.2
		}
	}
	BreedActions.chaos_troll.melee_shove.running_attacks[1].bot_threats = {		--attack_pounce
		{
			collision_type = "cylinder",
			offset_forward = 2,
			radius = 3,
			height = 3.7,
			offset_right = 0,
			offset_up = 0,
			duration = 0.85,
			start_time = 0.2
		}
	}
	-- BreedActions.chaos_troll.attack_cleave.attacks[1].bot_threats = {	--attack_cleave
		-- {
			-- duration = 0.6666666666666666,
			-- start_time = 1
		-- }
	-- }
	BreedActions.chaos_troll.attack_cleave.running_attacks[1].bot_threats = {	--attack_move_cleave
		{
			duration = 0.65,	--0.65
			start_time = 0.75	--0.3
		}
	}
	
	-- BreedActions.chaos_spawn.combo_attack.attacks[1].damage_done_time = 1.61	--testing, ideally I change the _defend function
	BreedActions.chaos_spawn.combo_attack.attacks[1].bot_threats = {	--attack_melee_combo
		{
			range = 3.5,
			duration = 0.45,
			start_time = 0
		},
		{
			range = 3.5,
			duration = 0.55,
			start_time = 0.25
		},
		{
			range = 3.5,
			duration = 0.55,
			start_time = 0.7
		},
		{
			range = 3.5,
			duration = 0.55,
			start_time = 1.1
		}
	}
	-- BreedActions.chaos_spawn.combo_attack.attacks[2].damage_done_time = 1.95	--testing, ideally I change the _defend function
	BreedActions.chaos_spawn.combo_attack.attacks[2].bot_threats = {	--attack_melee_combo_2
		{
			range = 3.5,
			duration = 0.55,
			start_time = 0.05
		},
		{
			range = 3.5,
			duration = 0.55,
			start_time = 0.8
		},
		{
			range = 3.5,
			duration = 0.55,
			start_time = 1.45
		}
	}
	BreedActions.chaos_spawn.tentacle_grab.attacks[1].bot_threats = {	--attack_grab
		{
			collision_type = "cylinder",
			offset_forward = 0,
			radius = 4.5,
			height = 4,
			offset_right = 0,
			offset_up = 0,
			duration = 0.95,
			start_time = 0.1
		}
	}
	BreedActions.chaos_spawn.melee_slam.bot_threats = {		--attack_melee_claw
		{
			duration = 0.55,
			start_time = 0
		}
	}
	-- BreedActions.chaos_spawn.melee_shove.attacks[1].damage_done_time = 1.3		--testing, ideally I change the _defend function
	BreedActions.chaos_spawn.melee_shove.attacks[1].bot_threats = {		--attack_melee_sweep
		{
			collision_type = "cylinder",
			offset_forward = 0,
			radius = 4.5,
			height = 4,
			offset_right = 0,
			offset_up = 0,
			duration = 1,
			start_time = 0.35
		}
	}
	
	-- BreedActions.beastmen_minotaur.combo_attack.attacks[1].damage_done_time = 2.33		--testing, ideally I change the _defend function
	BreedActions.beastmen_minotaur.combo_attack.attacks[1].bot_threats = {		--attack_melee_combo
		{
			range = 3.5,
			duration = 0.55,
			start_time = 0.05
		},
		{
			range = 3.5,
			duration = 0.55,
			start_time = 0.65
		},
		{
			range = 3.5,
			duration = 0.55,
			start_time = 0.8
		},
		{
			range = 3.5,
			duration = 0.55,
			start_time = 1.8
		}
	}
	-- BreedActions.beastmen_minotaur.melee_shove.attacks[1].damage_done_time = {		--testing, ideally I change the _defend function
		-- attack_right = 0.81,
		-- attack_left = 0.75
	-- }
	BreedActions.beastmen_minotaur.melee_shove.attacks[1].bot_threats = {	--attack_left, attack_right
		attack_left = {
			{
				collision_type = "cylinder",
				offset_forward = 0.5,
				radius = 4.5,
				height = 4,
				offset_right = 0,
				offset_up = 0,
				duration = 0.6,
				start_time = 0.15
			}
		},
		attack_right = {
			{
				collision_type = "cylinder",
				offset_forward = 0.5,
				radius = 4.5,
				height = 4,
				offset_right = 0,
				offset_up = 0,
				duration = 0.7,
				start_time = 0.15
			}
		}
	}
	BreedActions.beastmen_minotaur.headbutt_attack.attacks[1].bot_threats = {	--attack_headbutt
		attack_headbutt = {
			{
				collision_type = "cylinder",
				offset_forward = 0.5,
				radius = 4.5,
				height = 4,
				offset_right = 0,
				offset_up = 0,
				duration = 0.6,
				start_time = 0.2
			}
		}
	}

	BreedActions.skaven_stormfiend.shoot.bot_threats = nil
end




mod.on_enabled = function(initial_call)
	mod:echo("Replicant Bots 8 May 2023 Enabled")

	mod.update_ranged_weapon_templates_meta()
	mod.update_melee_weapon_templates_meta()
	mod.post_update_weapon_templates_meta()
	update_breed_threat_data2()
	
	Breeds.chaos_corruptor_sorcerer.special = true
	Breeds.chaos_vortex_sorcerer.special = true

	-- BotActions.default.shoot.evaluation_duration = 0.2	--0.5
	-- BotActions.default.shoot.evaluation_duration_without_firing = 0.3	--0.75	--1
	
	-- BotActions.default.fight_melee.engage_range_threat = 4	--3
	-- BotActions.default.fight_melee.engage_range_near_follow_pos_threat = 5	--4
	
	BotNavTransitionManager.TRANSITION_LAYERS.fire_grenade = 1	--1.5
	BotNavTransitionManager.TRANSITION_LAYERS.bot_leap_of_faith = 1
	-- BotNavTransitionManager.NAV_COST_MAP_LAYERS.stormfiend_warpfire = 20	--30
	
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/c0bfbb87d92fb0aa10804260d6f39f4bdda5cb9e/scripts/managers/bot_nav_transition/bot_nav_transition_manager.lua#L25
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/c0bfbb87d92fb0aa10804260d6f39f4bdda5cb9e/scripts/settings/breeds.lua
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/search?q=NAV_COST_MAP_LAYER_ID_MAPPING
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/search?p=1&q=navtag_layer_cost_table
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/6c69aa3488cf7259b6eae5e66f8100d7895df34b/scripts/entity_system/systems/ai/ai_group_system.lua#L672
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/54867e3cd2a1ec152433a090ce9057a3fbd039eb/core/gwnav/lua/runtime/navbotconfiguration.lua#L17
	--https://help.autodesk.com/view/Stingray/ENU/?guid=__lua_ref_obj_stingray_GwNavTagLayerCostTable_html
	
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/c0bfbb87d92fb0aa10804260d6f39f4bdda5cb9e/scripts/unit_extensions/human/ai_player_unit/ai_navigation_extension.lua#L142
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/54867e3cd2a1ec152433a090ce9057a3fbd039eb/scripts/entity_system/systems/volumes/volume_system.lua#L175
	
	BotConstants.default.OPPORTUNITY_TARGET_REACTION_TIMES = {
		normal = {
			max = 0.5,
			min = 0.2
		},
		hard = {
			max = 0.5,
			min = 0.2
		},
		harder = {
			max = 0.5,
			min = 0.2
		},
		hardest = {
			max = 0.5,
			min = 0.2
		},
		cataclysm = {
			max = 0.5,
			min = 0.2
		},
		cataclysm_2 = {
			max = 0.5,
			min = 0.2
		},
		cataclysm_3 = {
			max = 0.5,
			min = 0.2
		}
	--	versus_base = {
		--	max = 0.5,
	--		min = 0.2
	--	}
	}
end
mod.on_disabled = function(initial_call)
	mod:echo("Disable function for Replicant Bots is not properly written!")
	
	Breeds.skaven_pack_master.bot_opportunity_target_melee_range = 5
	Breeds.skaven_pack_master.bot_opportunity_target_melee_range_while_ranged = 4
	
	BreedActions.skaven_warpfire_thrower.shoot_warpfire_thrower.bot_threat_radius = 15
	
	-- BotActions.default.shoot.evaluation_duration = 2
	-- BotActions.default.shoot.evaluation_duration_without_firing = 3
	
	-- BotActions.default.shoot_ability.evaluation_duration = 2
	-- BotActions.default.shoot_ability.evaluation_duration_without_firing = 4
		
	-- BotActions.default.fight_melee.engage_range_threat = 2
	-- BotActions.default.fight_melee.engage_range_near_follow_pos_threat = 3
	
	BotNavTransitionManager.TRANSITION_LAYERS.fire_grenade = 30
	BotNavTransitionManager.TRANSITION_LAYERS.bot_leap_of_faith = 3
	-- BotNavTransitionManager.NAV_COST_MAP_LAYERS.stormfiend_warpfire = 50
	
	BotConstants.default.OPPORTUNITY_TARGET_REACTION_TIMES = {
		normal = {
			max = 20,
			min = 10
		},
		hard = {
			max = 0.65,
			min = 0.2
		},
		harder = {
			max = 0.65,
			min = 0.2
		},
		hardest = {
			max = 0.65,
			min = 0.2
		},
		cataclysm = {
			max = 0.65,
			min = 0.2
		},
		cataclysm_2 = {
			max = 0.65,
			min = 0.2
		},
		cataclysm_3 = {
			max = 0.65,
			min = 0.2
		},
	--	versus_base = {
	--		max = 0.65,
	--		min = 0.2
	--	}
	}
end
mod.update = function(dt)
	--remove bot_poison_wind nav tag volume when expired, check enemy_hooks.lua
	for projectile_unit, data in pairs(mod.bot_poison_wind_prediction_ids) do
		local volume_system = Managers and Managers.state and Managers.state.entity and Managers.state.entity.system and Managers.state.entity:system("volume_system")
		if volume_system and mod.bot_poison_wind_prediction_ids[projectile_unit] and mod.bot_poison_wind_prediction_ids[projectile_unit].expires_at and mod.bot_poison_wind_prediction_ids[projectile_unit].expires_at < Managers.time:time("game") then
			if mod.bot_poison_wind_prediction_ids[projectile_unit].id then
				volume_system:destroy_nav_tag_volume(mod.bot_poison_wind_prediction_ids[projectile_unit].id)
			end
			-- mod.bot_poison_wind_prediction_ids[self.unit] = nil
			mod.bot_poison_wind_prediction_ids[projectile_unit] = nil
		end
	end
end

local RESCUE_ABILITIES = "rescue_allies_active_ability"
local REGULAR_ABILITIES = "regular_active_abilities"
local ABILITIES_TWEAKS = "activate_abilities_tweaks"
mod.on_setting_changed = function(setting_name)
	if setting_name == RESCUE_ABILITIES or setting_name == REGULAR_ABILITIES then
		if mod:get(ABILITIES_TWEAKS) == false and (mod:get(RESCUE_ABILITIES) or mod:get(REGULAR_ABILITIES) ~= mod.bot_abilities_settings.DISABLE_ALL) then
			mod:set(ABILITIES_TWEAKS, true, true)
		elseif mod:get(ABILITIES_TWEAKS) == true and not mod:get(RESCUE_ABILITIES) and mod:get(REGULAR_ABILITIES) == mod.bot_abilities_settings.DISABLE_ALL then
			mod:set(ABILITIES_TWEAKS, false, true)
		end
	end
	
	if mod.components[setting_name] ~= nil then
		mod.components[setting_name]:synchronize()
		if mod.components[setting_name].change_game_data then
			mod.components[setting_name]:change_game_data()
		end
	end
	
	if mod.components.regular_active_abilities.detailed_settings[setting_name] ~= nil then
		mod.components.regular_active_abilities.detailed_settings[setting_name] = mod:get(setting_name)
	end
	
	if mod.components.melee_choices.detailed_settings[setting_name] ~= nil then
		mod.components.melee_choices.detailed_settings[setting_name] = mod:get(setting_name)
	end
end
mod.on_game_state_changed = function(status, state_name)
	if status == "enter" and state_name == "StateSplashScreen" then
		if mod:get(RESCUE_ABILITIES) or mod:get(REGULAR_ABILITIES) ~= mod.bot_abilities_settings.DISABLE_ALL then
			mod:set(ABILITIES_TWEAKS, true, true)
		else
			mod:set(ABILITIES_TWEAKS, false, true)
		end
		
		--[[
		if mod:get("drinking_potions") then
			mod.components.drinking_potions:change_game_data()
		end
		]]
		
		if mod:get("reload_tweaks") then
			mod.components.reload_tweaks:change_game_data()
		end
	end
end




local forced_bot_teleport = function(bot_unit, destination)
	local unit = bot_unit
	local unit_owner = Managers.player:unit_owner(unit)
	if destination and Unit.alive(unit) and unit_owner.bot_player then	-- this function is supposed to teleport only bots
		local blackboard = Unit.get_data(unit, "blackboard")
		local status_extension = ScriptUnit.has_extension(unit, "status_system")
		if status_extension and not status_extension:is_disabled() then
			blackboard.teleport_stuck_loop_counter = nil
			blackboard.teleport_stuck_loop_start_time = nil
			-- teleport
			local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")
			locomotion_extension.teleport_to(locomotion_extension, destination)
			blackboard.has_teleported = true
			blackboard.navigation_extension:teleport(destination)
			blackboard.ai_system_extension:clear_failed_paths()
			blackboard.follow.needs_target_position_refresh = true
		end
	end
	
	return
end




--Stop bots from chasing far-away enemies or certain enemy types, partly copied from Bot Improvements Combat (might affect special sniping)
--gas rat etc. only when out of ammo
--now in player_bot_base.lua
--[[
mod:hook(PlayerBotBase, "_enemy_path_allowed", function (func, self, enemy_unit)
	local breed = Unit.get_data(enemy_unit, "breed")
	local target_unit = enemy_unit
		
	local dont_chase = {
		skaven_ratling_gunner = true,
		skaven_warpfire_thrower = true,
		-- skaven_poison_wind_globadier = true,		--in case of no ammo...
		-- chaos_vortex_sorcerer = true,		--in case of no ammo...
		skaven_explosive_loot_rat = true,
		
		-- melee combat positioning handles bot position when the ogre/Krench gets close enough..
		-- No need for the bots to melee rush an ogre/Krench that approaches from the distance!
		--note that for VT2, bots need to melee monsters to do damage
		skaven_rat_ogre = true,
		skaven_stormfiend = true,	--same as ratling
		chaos_troll = true,
		chaos_spawn = true,
		beastmen_minotaur = true,

		chaos_spawn_exalted_champion_norsca = true,
		skaven_stormfiend_boss = true,	--same as ratling
		
		--lord events are scripted so no horde all the time
		
		-- skaven_storm_vermin_champion = true,
		-- skaven_storm_vermin_warlord = true,
		-- chaos_exalted_sorcerer = true,
		-- chaos_exalted_champion_warcamp = true,
		-- chaos_exalted_champion_norsca = true,
		-- skaven_grey_seer = true,
		-- chaos_exalted_sorcerer_drachenfels = true,
	}
	
	local dont_chase_unless_no_ammo = {
		skaven_poison_wind_globadier = true,
		chaos_vortex_sorcerer = true,
	}
	
	local self_unit = self._unit
	local blackboard = self_unit and BLACKBOARDS[self_unit]
	
	if not self_unit or not blackboard then
		return false
	end
	
	local inventory_extension = blackboard.inventory_extension
	local ammo = inventory_extension:ammo_percentage()
	local ammo_ok = (not mod.heat_weapon[ranged_slot_name] and ammo > 0) or (mod.heat_weapon[ranged_slot_name] and ammo > 0.1)
	
	if breed and (dont_chase[breed.name] or (ammo_ok and dont_chase_unless_no_ammo[breed.name])) then
		return false
	end
	
	local disablers = {		--seems to make bots ignore them? edit: it's a vanilla bug with alive_specials
		skaven_gutter_runner = true,
		skaven_pack_master = true,
		chaos_corruptor_sorcerer = true,
	}
	
	local enemy_pos = POSITION_LOOKUP[enemy_unit]
	local self_pos = POSITION_LOOKUP[self._unit]
	
	if breed and not disablers[breed.name] and Vector3.distance_squared(enemy_pos, self_pos) > 350 then
		return false
	end

	--add exception for halescourge's vortex	--anim == "attack_staff"
	if breed and breed.name == "chaos_exalted_sorcerer" then
		local breed_bb = target_unit and BLACKBOARDS[target_unit]
		local current_time = Managers.time:time("game")
		
		-- if breed_bb and breed_bb.action and breed_bb.action.name == "spawn_boss_vortex" then
		if (breed_bb and breed_bb.action and (breed_bb.action.name == "spawn_boss_vortex" or breed_bb.action.name == "spawn_flower_wave")) or
			(mod.last_halescourege_teleport_time and current_time < mod.last_halescourege_teleport_time + 3.5) then
			
			return false
		end
	end
	
	return func(self, enemy_unit)
end)
--]]




--Make bots ignore line-of-fire threats from gunners (i.e. don't take cover?) unless within lethal range
--try to make shield bots block?
--now in line_of_fire_tweaks.lua
--[[
local TAKE_COVER_TEMP_TABLE = {}
local function line_of_fire_check(from, to, p, width, length)
	local diff = p - from
	local dir = Vector3.normalize(to - from)
	local lateral_dist = Vector3.dot(diff, dir)

	if lateral_dist <= 0 or length < lateral_dist then
		return false
	end

	local direct_dist = Vector3.length(diff - lateral_dist * dir)

	if math.min(lateral_dist, width) < direct_dist then
		return false
	else
		return true
	end
end

--does this affect raksnitt stormfiend's machine gun?

mod:hook_origin(PlayerBotBase, "_in_line_of_fire", function(self, self_unit, self_pos, take_cover_targets, taking_cover_from)
	local changed = false
	local in_line_of_fire = false
	local width = 2.5
	local sticky_width = 6
	local length = 40

	for attacker, victim in pairs(take_cover_targets) do
		local already_in_cover_from = taking_cover_from[attacker]

		if ALIVE[victim] and (victim == self_unit or line_of_fire_check(POSITION_LOOKUP[attacker], POSITION_LOOKUP[victim], self_pos, (already_in_cover_from and sticky_width) or width, length))
				-- and Vector3.distance_squared(POSITION_LOOKUP[attacker], POSITION_LOOKUP[victim]) < 140 then -- added bit
				and Vector3.distance_squared(POSITION_LOOKUP[attacker], POSITION_LOOKUP[victim]) < 140 and mod.check_line_of_sight(self_unit, attacker) then -- added bit
		
			TAKE_COVER_TEMP_TABLE[attacker] = victim
			changed = changed or not already_in_cover_from
			in_line_of_fire = true
		end
	end

	for attacker, victim in pairs(taking_cover_from) do
		if not TAKE_COVER_TEMP_TABLE[attacker] then
			changed = true

			break
		end
	end

	table.clear(taking_cover_from)

	for attacker, victim in pairs(TAKE_COVER_TEMP_TABLE) do
		taking_cover_from[attacker] = victim
	end

	table.clear(TAKE_COVER_TEMP_TABLE)
	
	return in_line_of_fire, changed
end)
--]]








--Override target selection
-- the bot must target something in order for it to defend itself

local is_positioned_between_self_and_ally = function(self_unit, ally_unit, enemy_unit)		-- check if the enemy unit is positioned between self and ally
	if self_unit and ally_unit and enemy_unit then
		local self_pos	= POSITION_LOOKUP[self_unit]
		local ally_pos	= POSITION_LOOKUP[ally_unit]
		local enemy_pos	= POSITION_LOOKUP[enemy_unit]
		if self_pos and ally_pos and enemy_pos then
			local ally_dist = Vector3.distance(self_pos, ally_pos)
			local zone_dist = math.sqrt((ally_dist^2) + (2^2)) + 2
			
			local self_to_enemy_dist = Vector3.distance(self_pos, enemy_pos)
			local ally_to_enemy_dist = Vector3.distance(ally_pos, enemy_pos)
			
			if self_to_enemy_dist < ally_dist and ally_to_enemy_dist < ally_dist and (self_to_enemy_dist + ally_to_enemy_dist) < zone_dist then
				-- the enemy is positioned between self and ally
				return true
			end
		end
	end
	
	return false
end

local assigned_enemies = {}

--somehow the different bots versions below make bots take a lot of damage, use this for now

-- local STICKYNESS_DISTANCE_MODIFIER = -0.2
-- Search "_update_target_enemy" below
--[[
mod:hook_origin(PlayerBotBase, "_update_target_enemy", function(self, dt, t)
	local pos = POSITION_LOOKUP[self._unit]
	local self_pos = pos

	self:_update_slot_target(dt, t, pos)
	self:_update_proximity_target(dt, t, pos)

	local bb = self._blackboard
	local old_target = bb.target_unit
	local slot_enemy = bb.slot_target_enemy
	local prox_enemy = bb.proximity_target_enemy
	local priority_enemy = bb.priority_target_enemy
	local urgent_enemy = bb.urgent_target_enemy
	local opportunity_enemy = bb.opportunity_target_enemy
	
	local STICKYNESS_DISTANCE_MODIFIER = -0.2
	
	-- if bb.shoot and bb.shoot.charging_shot then
		-- STICKYNESS_DISTANCE_MODIFIER = -3	--2
	-- end
	
	local prox_enemy_dist = bb.proximity_target_distance + ((prox_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local prio_enemy_dist = bb.priority_target_distance + ((priority_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local urgent_enemy_dist = bb.urgent_target_distance + ((urgent_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local opp_enemy_dist = bb.opportunity_target_distance + ((opportunity_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local slot_enemy_dist = math.huge

	if slot_enemy then
		slot_enemy_dist = Vector3.length(POSITION_LOOKUP[slot_enemy] - pos) + ((slot_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	end

	local self_unit = self._unit
	local opportunity_los		= mod.check_line_of_sight(self_unit, opportunity_enemy)
	local urgent_flanking		= mod.check_alignment_to_target(self_unit, urgent_enemy)
	local urgent_bb				= BLACKBOARDS[urgent_enemy]
	local urgent_targeting_me	= (urgent_bb and urgent_bb.target_unit == self_unit) or false
	
	local active_bots			= Managers.player:bots()
	local bot_count				= #active_bots
		
	local blackboard			= self._blackboard
	local inventory_extension = blackboard.inventory_extension
	local ranged_slot_data = inventory_extension:get_slot_data("slot_ranged")
	local ranged_slot_template = inventory_extension:get_item_template(ranged_slot_data)
	local ranged_slot_name = ranged_slot_template.name
	local sniper_target_selection = mod.stop_trash_shooting_ranged[ranged_slot_name]
	
	-- reload ranged weapon if idle and reload is needed
	-- if not blackboard.breakable_object then
		-- if mod.heat_weapon[ranged_slot_name] then
			-- vent_bot_ranged_weapon(d, false)
		-- else
			-- reload_bot_ranged_weapon(self_unit, blackboard)
		-- end
	-- end
	
	--switch to melee if needed
	-- if not blackboard.breakable_object then
		-- local ranged_equipped = inventory_extension and inventory_extension:get_wielded_slot_name() == "slot_ranged"
		-- local melee_equipped = inventory_extension and inventory_extension:get_wielded_slot_name() == "slot_melee"
		-- local ally_needs_pickup	= blackboard.target_ally_need_type == "knocked_down" or blackboard.target_ally_need_type == "ledge" or blackboard.target_ally_need_type == "hook"
		-- local may_switch = blackboard.target_unit == nil and (ranged_equipped or melee_equipped) and not ally_needs_pickup
		-- local need_reload = true
		
		-- if mod.heat_weapon[ranged_slot_name] then
			-- local condition_args = {
				-- start_min_percentage = 0.5,
				-- start_max_percentage = 0.99,
				-- stop_percentage = 0.1,
				-- overcharge_limit_type = "threshold"
			-- }
			
			-- need_reload = BTConditions.should_vent_overcharge(blackboard, condition_args)
		-- else
			-- need_reload = BTConditions.should_reload_weapon(blackboard, nil)
		-- end
		
		-- if may_switch and not need_reload and ranged_equipped and not blackboard.reloading then
			-- blackboard.input_extension:wield("slot_melee")
		-- end
	-- end
	
	-- check that the current target exists and is alive
	local target_alive = mod.is_unit_alive(blackboard.target_unit)
	if not target_alive then
		blackboard.target_unit = nil
	end
	
	-- process mod.swarm_projectile_list
	local closest_swarm_projectile = {
		unit = nil,
		distance = math.huge
	}
		
	for loop_unit, _ in pairs(mod.swarm_projectile_list) do
		if not Unit.alive(loop_unit) then
			mod.swarm_projectile_list[loop_unit] = nil
		else
			local loop_locomotion_extension = ScriptUnit.extension(loop_unit, "projectile_locomotion_system")
			-- local loop_pos = Unit.local_position(loop_unit, 0) or POSITION_LOOKUP[loop_unit]
			local loop_pos = (loop_locomotion_extension and loop_locomotion_extension:current_position()) or POSITION_LOOKUP[loop_unit]
			local loop_offset = pos and loop_pos and loop_pos - pos
			local loop_dist	= loop_offset and Vector3.length(loop_offset)
			
			if loop_dist and loop_dist < closest_swarm_projectile.distance then
				closest_swarm_projectile.unit = loop_unit
				closest_swarm_projectile.distance = loop_dist
			end
		end
	end

	local prox_enemies			= mod.get_proximite_enemies(self_unit, 20, 3.8)
	local num_prox_enemies		= #prox_enemies
	local near_enemies			= mod.get_proximite_enemies(self_unit, 5, 3.8)	--4.5
	local num_near_enemies		= #near_enemies
		
	--switch order of urgent_enemy (bosses & lords) and opportunity_enemy (specials)
	if priority_enemy and prio_enemy_dist < 10 then		--4.5	--5		--3
		bb.target_unit = priority_enemy
	elseif closest_swarm_projectile.unit and closest_swarm_projectile.distance < 3 then
		bb.target_unit = closest_swarm_projectile.unit
	elseif opportunity_enemy and opp_enemy_dist < 3 then
		bb.target_unit = opportunity_enemy
	-- elseif urgent_enemy and urgent_enemy_dist < 3 then
		-- bb.target_unit = urgent_enemy
	elseif slot_enemy and slot_enemy_dist < 3 then
		bb.target_unit = slot_enemy
	elseif prox_enemy and prox_enemy_dist < 2 then
		bb.target_unit = prox_enemy
	elseif prox_enemy and bb.proximity_target_is_player and prox_enemy_dist < 10 then	-- seems to be versus mode stuff
		bb.target_unit = prox_enemy
	elseif priority_enemy then
		bb.target_unit = priority_enemy
	elseif opportunity_enemy and opportunity_los then
		bb.target_unit = opportunity_enemy
	elseif urgent_enemy and (num_near_enemies < 3 or (urgent_enemy_dist < 5 and not urgent_flanking) or (urgent_enemy_dist < 7 and urgent_targeting_me)) then
		bb.target_unit = urgent_enemy
	else
		-- elseif slot_enemy then
			-- bb.target_unit = slot_enemy
		-- elseif bb.target_unit then
			-- bb.target_unit = nil
		-- end
		
		local separation_check_units = {}
		local players = Managers.player:players()
		for _, loop_player in pairs(players) do
			local loop_unit	= loop_player.player_unit
			local loop_pos	= POSITION_LOOKUP[loop_unit]
			local loop_dist	= self_pos and loop_pos and Vector3.distance(self_pos, loop_pos)
			-- if loop_dist and loop_dist < 7 and Unit.alive(loop_unit) then
			if loop_dist and loop_dist < 7 and mod.is_unit_alive(loop_unit) then
				table.insert(separation_check_units, loop_unit)
			end
		end

		-- determine the closest trash rat / stormvermin
		local separation_threat	=
		{
			unit = nil,
			distance = math.huge,
			human = false
		}
		local closest_trash	=
		{
			unit = nil,
			distance = math.huge
		}
		local closest_elite =
		{
			unit = nil,
			distance = math.huge
		}
		
		-- check proximite enemies
		for _, loop_unit in pairs(prox_enemies) do
			local loop_breed		= Unit.get_data(loop_unit, "breed")
			local loop_blackboard	= BLACKBOARDS[loop_unit]
			local loop_pos			= POSITION_LOOKUP[loop_unit]
			local loop_offset		= pos and loop_pos and loop_pos - pos
			local loop_dist			= loop_offset and Vector3.length(loop_offset)
			local loop_dist_self	= self_pos and loop_pos and Vector3.distance(self_pos, loop_pos)
			local height_modifier	= (math.abs(loop_offset.z) > 0.2 and math.abs(loop_offset.z)*0.75) or 0
			local loop_is_after_me	= loop_blackboard and (loop_blackboard.target_unit == self_unit or loop_blackboard.attacking_target == self_unit)
			
			-- add some extra to the check distance of enemies that are far away from other players
			-- to encourage the bots not to spread out too wide
			for _,player in pairs(players) do
				local loop2_unit = player.player_unit
				-- if Unit.alive(loop2_unit) then
				if mod.is_unit_alive(loop2_unit) then
					local loop2_pos = POSITION_LOOKUP[loop2_unit]
					local loop2_dist = (loop2_pos and loop_pos and Vector3.length(loop2_pos - loop_pos)) or 0
					loop_dist = loop_dist + math.max((loop2_dist*0.05),0)
				end
			end
			
			if loop_dist and loop_blackboard and loop_blackboard.target_unit then
				if (mod.TRASH_UNITS[loop_breed.name] and (not assigned_enemies[loop_unit] or assigned_enemies[loop_unit] == self_unit or num_prox_enemies < bot_count or loop_is_after_me)) or (loop_breed.name == "skaven_loot_rat" and loop_dist < 5) then
					-- ** trash rats **
					-- if this bot has anti-armor weapon then it should try to avoid unarmored targets if armored ones are close
					-- if self_anti_armor then loop_dist = loop_dist +1 end
					
					-- if the target is above / below past a threashold then it should be less attractive than targets on the same plane.
					loop_dist = loop_dist + height_modifier
					
					if loop_blackboard.attacking_target == self_unit and not loop_blackboard.past_damage_in_attack then
						loop_dist = loop_dist - 0.5		--1
					end
					
					--
					if loop_dist < closest_trash.distance then
						closest_trash.unit		= loop_unit
						closest_trash.distance	= loop_dist
					end
				-- elseif mod.ELITE_UNITS[loop_breed.name] or mod.BERSERKER_UNITS[loop_breed.name] then
				elseif (mod.ELITE_UNITS[loop_breed.name] or mod.BERSERKER_UNITS[loop_breed.name]) and (not assigned_enemies[loop_unit] or assigned_enemies[loop_unit] == self_unit or num_prox_enemies < bot_count or loop_is_after_me) then
					-- ** stormvermin **
					-- if this bot does not have anti-armor weapon then it should try to avoid armored targets if unarmored ones are close
					-- if not self_anti_armor then loop_dist = loop_dist +1 end
					
					-- if the target is above / below past a threashold then it should be less attractive than targets on the same plane.
					loop_dist = loop_dist + height_modifier
					--
					if loop_dist < closest_elite.distance then
						closest_elite.unit		= loop_unit
						closest_elite.distance	= loop_dist
					end
				end	-- specials / ogres are handled separately
			end
				
			-- find group separation threats
			-- separation threat can be any non-boss enemy unit that is positioned between team members
			for _, separation_check_unit in pairs(separation_check_units) do
				if not mod.BOSS_UNITS[loop_breed.name] and not mod.LORD_UNITS[loop_breed.name] and loop_dist_self < separation_threat.distance then
					local is_separation_threat = is_positioned_between_self_and_ally(self_unit, separation_check_unit, loop_unit)
					if is_separation_threat then
						separation_threat.unit		= loop_unit
						separation_threat.distance	= loop_dist_self
					end
				end
			end
		end
		
		-- if not sniper_target_selection and separation_threat.unit then
		if separation_threat.unit and separation_threat.distance < 3.5 then
			blackboard.target_unit = separation_threat.unit
		elseif sniper_target_selection and closest_elite.unit and (closest_trash.distance > 3 or closest_trash.distance > closest_elite.distance) then	--3.5
			blackboard.target_unit = closest_elite.unit
		elseif closest_trash.unit or closest_elite.unit then
			if closest_trash.distance < closest_elite.distance then
				blackboard.target_unit = closest_trash.unit
			else
				blackboard.target_unit = closest_elite.unit
			end
		elseif slot_enemy then
			blackboard.target_unit = slot_enemy
		elseif urgent_enemy then
			blackboard.target_unit = urgent_enemy
		elseif blackboard.target_unit then
			blackboard.target_unit = nil
		end
	end
	
	-- clean assigned enemies table
	-- make sure there is no enemies that are assigned to non-active bots (happens when player joins mid combat)
	for key,assigned_unit in pairs(assigned_enemies) do
		if assigned_unit == self_unit then
			assigned_enemies[key] = nil
		else
			local assigned_to_inactive_bot = true
			for _, loop_owner in pairs(active_bots) do
				local loop_unit			= loop_owner.player_unit
				-- local loop_d			= get_d_data(loop_unit)
				
				-- local loop_is_disabled	= not loop_d or loop_d.disabled
				local status_extension = ScriptUnit.has_extension(loop_unit, "status_system")
				local loop_is_disabled = (status_extension and status_extension:is_disabled()) or false
				
				if assigned_unit == loop_unit and not loop_is_disabled then
					assigned_to_inactive_bot = false
					break
				end
			end
			
			-- the enemy has disabled bot assigned to it >> remove the assignement
			if assigned_to_inactive_bot then
				assigned_enemies[key] = nil
			end
		end
	end
	
	-- assign self to current target enemy
	if blackboard.target_unit then
		assigned_enemies[blackboard.target_unit] = self_unit
	end
end)
--]]




--Increase special detection distance, use mod.get_spawned_specials_and_archers for alive_specials list
--see ai_bot_group_system.lua
--still need this hook to shoot beastmen archers

local FALLBACK_OPPORTUNITY_DISTANCE = 80	--100	--60	--40
local FALLBACK_OPPORTUNITY_DISTANCE_SQ = FALLBACK_OPPORTUNITY_DISTANCE^2
-- local alive_specials_table = {}

mod:hook_origin(AIBotGroupSystem, "_update_opportunity_targets", function(self, dt, t)
	local conflict_director = Managers.state.conflict

	-- table.clear(alive_specials_table)

	-- local alive_specials = conflict_director:alive_specials(alive_specials_table)
	local alive_specials = mod.get_spawned_specials_and_archers()
	local num_alive_specials = #alive_specials
	local Vector3_distance_squared = Vector3.distance_squared
	local bot_ai_data = self._bot_ai_data

	for side_id = 1, #bot_ai_data, 1 do
		local side_bot_data = bot_ai_data[side_id]

		for bot_unit, data in pairs(side_bot_data) do
			local best_utility = -math.huge
			local best_target = nil
			local best_distance = math.huge
			local blackboard = data.blackboard
			local self_pos = POSITION_LOOKUP[bot_unit]
			local old_target = blackboard.opportunity_target_enemy
			local side = blackboard.side

			for i = 1, num_alive_specials, 1 do
				local target_unit = alive_specials[i]
				local opportunity_target_blackboard = BLACKBOARDS[target_unit]
				local ignore_bot_opportunity = opportunity_target_blackboard.breed.ignore_bot_opportunity
				local target_pos = POSITION_LOOKUP[target_unit]

				if not ignore_bot_opportunity and Unit.alive(target_unit) and Vector3_distance_squared(target_pos, self_pos) < FALLBACK_OPPORTUNITY_DISTANCE_SQ then
					local utility, distance = self:_calculate_opportunity_utility(bot_unit, blackboard, self_pos, old_target, target_unit, t, false, true)

					if best_utility < utility then
						best_utility = utility
						best_target = target_unit
						best_distance = distance
					end
				end
			end

			local VALID_ENEMY_TARGETS_PLAYERS_AND_BOTS = side.VALID_ENEMY_TARGETS_PLAYERS_AND_BOTS

			for target_unit, is_valid in pairs(VALID_ENEMY_TARGETS_PLAYERS_AND_BOTS) do
				if is_valid then
					local ghost_mode_ext = ScriptUnit.has_extension(target_unit, "ghost_mode_system")

					if not ghost_mode_ext or not ghost_mode_ext:is_in_ghost_mode() then
						local target_pos = POSITION_LOOKUP[target_unit]

						if Unit.alive(target_unit) and Vector3_distance_squared(target_pos, self_pos) < FALLBACK_OPPORTUNITY_DISTANCE_SQ then
							local utility, distance = self:_calculate_opportunity_utility(bot_unit, blackboard, self_pos, old_target, target_unit, t, false, true)

							if best_utility < utility then
								best_utility = utility
								best_target = target_unit
								best_distance = distance
							end
						end
					end
				end
			end

			blackboard.opportunity_target_enemy = best_target
			blackboard.opportunity_target_distance = best_distance
		end
	end
end)




--Increase boss and lord detection distance, use mod.get_spawned_bosses_and_lords for alive_bosses list
--see ai_bot_group_system.lua
--obsolette?

local BOSS_ENGAGE_DISTANCE = 25		--25		--15
local BOSS_ENGAGE_DISTANCE_SQ = BOSS_ENGAGE_DISTANCE^2

mod:hook_origin(AIBotGroupSystem, "_update_urgent_targets", function(self, dt, t)
	local conflict_director = Managers.state.conflict
	-- local alive_bosses = conflict_director:alive_bosses()
	local alive_bosses = mod.get_spawned_bosses_and_lords()
	local num_alive_bosses = #alive_bosses
	local bot_ai_data = self._bot_ai_data
	local urgent_targets = self._urgent_targets

	for side_id = 1, #bot_ai_data, 1 do
		local side_bot_data = bot_ai_data[side_id]

		for bot_unit, data in pairs(side_bot_data) do
			local best_utility = -math.huge
			local best_target = nil
			local best_distance = math.huge
			local blackboard = data.blackboard
			local self_pos = POSITION_LOOKUP[bot_unit]
			local old_target = blackboard.urgent_target_enemy

			for target_unit, is_target_until in pairs(urgent_targets) do
				local time_left = is_target_until - t

				if time_left > 0 then
					if Unit.alive(target_unit) then
						local utility, distance = self:_calculate_opportunity_utility(bot_unit, blackboard, self_pos, old_target, target_unit, t, false, false)

						if best_utility < utility then
							best_utility = utility
							best_target = target_unit
							best_distance = distance
						end
					else
						urgent_targets[target_unit] = nil
					end
				else
					urgent_targets[target_unit] = nil
				end
			end

			if not best_target then
				for j = 1, num_alive_bosses, 1 do
					local target_unit = alive_bosses[j]
					local pos = POSITION_LOOKUP[target_unit]

					if Unit.alive(target_unit) and not AiUtils.unit_invincible(target_unit) and Vector3.distance_squared(pos, self_pos) < BOSS_ENGAGE_DISTANCE_SQ and not BLACKBOARDS[target_unit].defensive_mode_duration then
						local utility, distance = self:_calculate_opportunity_utility(bot_unit, blackboard, self_pos, old_target, target_unit, t, false, false)

						if best_utility < utility then
							best_utility = utility
							best_target = target_unit
							best_distance = distance
						end
					end
				end
			end

			blackboard.revive_with_urgent_target = best_target and self:_can_revive_with_urgent_target(bot_unit, self_pos, blackboard, best_target, t)
			blackboard.urgent_target_enemy = best_target
			blackboard.urgent_target_distance = best_distance
			local hit_by_projectile = blackboard.hit_by_projectile

			for attacking_unit, _ in pairs(hit_by_projectile) do
				if not Unit.alive(attacking_unit) then
					hit_by_projectile[attacking_unit] = nil
				end
			end
		end
	end
end)




--Bots aim at head when fighting melee

local modify_aim_node_melee = function(self_unit, target_unit, target_breed, aim_node, career_name)
	local modified_aim_node = aim_node
	
	--Override for Chaos Warriors
	if target_breed and target_breed.name == "chaos_warrior" then
		modified_aim_node = "j_head"
	end
	
	--Override for Chaos Trolls
	if target_breed and target_breed.name == "chaos_troll" then
		modified_aim_node = "j_head"
	end
	
	--Override for Maulers
	if target_breed and target_breed.name == "chaos_raider" then
		-- local buff_extension = ScriptUnit.extension(unit, "buff_system")
		-- if career_name == "wh_captain" or (buff_extension and buff_extension:has_buff_type("traits_ranged_replenish_ammo_headshot")) then
		if career_name == "wh_captain" then
			modified_aim_node = "j_head"
		else
			modified_aim_node = "j_spine"
		end
	end

	--Override for Stormfiends and big monsters
	if target_breed and (target_breed.name == "skaven_stormfiend" or target_breed.name == "skaven_stormfiend_boss") then
		-- local self_unit = blackboard.unit
		local _, flanking = mod.check_alignment_to_target(self_unit, target_unit, nil, 90)
		if flanking then
			modified_aim_node = "c_packmaster_sling_02"
		end
	elseif target_breed and mod.BOSS_UNITS[target_breed.name] then
		-- local self_unit = blackboard.unit
		-- local angle = (is_melee and 120) or 160
		local infront_of_target, _ = mod.check_alignment_to_target(self_unit, target_unit, 120, nil)
		if not infront_of_target then
			modified_aim_node = "j_spine"
		end
	end
	
	return modified_aim_node
end

mod:hook_origin(BTBotMeleeAction, "_aim_position", function(self, target_unit, blackboard)
	local node = 0
	local target_unit_blackboard = BLACKBOARDS[target_unit]
	local target_breed = target_unit_blackboard and target_unit_blackboard.breed
	local aim_node = (target_breed and (target_breed.bot_melee_aim_node or "j_head")) or "rp_center"
	
--[[
	--Override for Chaos Warriors
	if target_breed and target_breed.name == "chaos_warrior" then
		aim_node = "j_head"
	end
	
	--Override for Chaos Trolls
	if target_breed and target_breed.name == "chaos_troll" then
		aim_node = "j_head"
	end
	
	--Override for Maulers
	if target_breed and target_breed.name == "chaos_raider" then
		aim_node = "j_spine"
	end

	--Override for Stormfiends and big monsters
	if target_breed and (target_breed.name == "skaven_stormfiend" or target_breed.name == "skaven_stormfiend_boss") then
		local self_unit = blackboard.unit
		local _, flanking = mod.check_alignment_to_target(self_unit, target_unit, nil, 90)
		if flanking then
			aim_node = "c_packmaster_sling_02"
		end
	elseif target_breed and mod.BOSS_UNITS[target_breed.name] then
		local self_unit = blackboard.unit
		local infront_of_target, _ = mod.check_alignment_to_target(self_unit, target_unit, 120, nil)
		if not infront_of_target then
			aim_node = "j_spine"
		end
	end
--]]
	local self_unit = blackboard.unit
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	
	aim_node = modify_aim_node_melee(self_unit, target_unit, target_breed, aim_node, career_name)

	if Unit.has_node(target_unit, aim_node) then
		node = Unit.node(target_unit, aim_node)
	end

	return Unit.world_position(target_unit, node)
end)




--functions for melee disengagement

local disengage_above_nav = 1.5		--0.75	--3
local disengage_below_nav = 1.5		--0.75	--3
--to be used with later updates
--[[
local function check_angle_disengage(d, nav_world, traverse_logic, start_pos, start_direction, angle, distance)
	local direction = Quaternion.rotate(Quaternion(Vector3.up(), angle), start_direction)
	local check_pos = start_pos + direction * distance
	local success, altitude = GwNavQueries.triangle_from_position(nav_world, check_pos, disengage_above_nav, disengage_below_nav)

	if success then
		check_pos.z = altitude
		
		-- return true, check_pos
		
		-- if GwNavQueries.raycango(nav_world, start_pos, check_pos, traverse_logic) then
			-- return true, check_pos
		-- end
		
		if position_is_under_threat(d, check_pos) then
			return true, check_pos
		end
	end
	
	return false
end

local function get_disengage_pos(d, nav_world, traverse_logic, start_pos, disengage_vector, move_distance)
	local disengage_direction = Vector3.normalize(Vector3.flat(disengage_vector))
	local success, pos = check_angle_disengage(d, nav_world, traverse_logic, start_pos, disengage_direction, 0, move_distance)

	if success then
		return pos
	end

	local subdivisions_per_side = 3
	local angle_inc = (math.pi / 2) / subdivisions_per_side

	for i = 1, subdivisions_per_side, 1 do
		local angle = angle_inc * i
		success, pos = check_angle_disengage(d, nav_world, traverse_logic, start_pos, disengage_direction, angle, move_distance)

		if success then
			return pos
		end

		success, pos = check_angle_disengage(d, nav_world, traverse_logic, start_pos, disengage_direction, -angle, move_distance)

		if success then
			return pos
		end
	end

	return nil
end

local function get_disengage_vector(current_pos, enemy_unit, keep_distance, keep_distance_sq)
	if is_unit_alive(enemy_unit) then
		local target_unit_position = POSITION_LOOKUP[enemy_unit]
		local dist_sq = Vector3.distance_squared(current_pos, target_unit_position)
		
		local breed = Unit.get_data(enemy_unit, "breed")
		local breed_name = breed and breed.name
		if bot_settings.lookup.ranged_keep_distance_breed_override[breed_name] then
			keep_distance = math.max(keep_distance, bot_settings.lookup.ranged_keep_distance_breed_override[breed_name])
			keep_distance_sq = keep_distance * keep_distance
		end
		
		if dist_sq < keep_distance_sq and dist_sq > 0 then
			local dist = math.sqrt(dist_sq)

			return (current_pos - target_unit_position) * (keep_distance - dist) / dist
		end
	end

	return nil
end
--]]

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

	for i = 1, subdivisions_per_side do
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

local update_disengage_position_melee = function (unit, defense_data, blackboard, t, keep_distance, move_towards_ally, ally_distance_threshold)
	local first_person_ext = blackboard.first_person_extension
	local self_position = first_person_ext:current_position()
	local melee_bb = blackboard.melee
	local keep_distance_sq = keep_distance * keep_distance
	local num_close_targets = 0
	local num_close_allies = 0
	local disengage_vector = Vector3.zero()
	local ally_vector = Vector3.zero()
	
	local disengage_position, should_stop = nil
	
	for _,loop_unit in pairs(defense_data.prox_enemies) do
		local result = get_disengage_vector(self_position, loop_unit, keep_distance, keep_distance_sq)

		if result then
			num_close_targets = num_close_targets + 1
			disengage_vector = disengage_vector + result
		end
	end
	
	if num_close_targets > 0 then
		disengage_vector = Vector3.divide(disengage_vector, num_close_targets)
		
		if move_towards_ally then
			for _, player in pairs(Managers.player:players()) do
				local loop_unit = player.player_unit
				if loop_unit ~= unit then
					local status_extension = ScriptUnit.has_extension(loop_unit, "status_system")
					local enabled = status_extension and not status_extension:is_disabled()
					if enabled then
						local loop_position = POSITION_LOOKUP[loop_unit]
						local loop_distance = loop_position and Vector3.length(self_position - loop_position)
						if loop_distance and loop_distance < ally_distance_threshold then
							local result = get_disengage_vector(self_position, loop_unit, ally_distance_threshold, ally_distance_threshold * ally_distance_threshold)
							
							if result then
								num_close_allies = num_close_allies + 1
								ally_vector = ally_vector + result
							end
						end
					end
				end
			end
		end
		
		if num_close_allies > 0 then
			ally_vector = Vector3.divide(ally_vector, num_close_allies)
		end

		local nav_world = Managers.state.bot_nav_transition._nav_world
		if nav_world then
			disengage_position = get_disengage_pos(nav_world, self_position, disengage_vector - ally_vector, 1)
		end
		
		-- local nav_world = Managers.state.bot_nav_transition._nav_world
		-- local traverse_logic = Managers.state.bot_nav_transition._traverse_logic
		-- if nav_world and traverse_logic then
			-- disengage_position = get_disengage_pos(d, nav_world, traverse_logic, self_position, disengage_vector - ally_vector, 1)
		-- end
	end

	if disengage_position then
		local override_box = blackboard.navigation_destination_override
		local override_destination = override_box:unbox()
		local disengage_position_set = melee_bb.disengage_position_set

		if not disengage_position_set or Vector3.distance_squared(disengage_position, override_destination) > 0.01 then
			override_box:store(disengage_position)

			melee_bb.disengage_position_set = true
			melee_bb.stop_at_current_position = should_stop
		end
		
		local interval = 0.1 + 0.05 * math.random()
		melee_bb.disengage_update_time = t + interval
	end
end




--Main melee logic

mod:hook_origin(BTBotMeleeAction, "_update_melee", function(self, unit, blackboard, dt, t)
	local action_data = self._tree_node.action_data
	local breakable_target = action_data.destroy_object and blackboard.breakable_object
	local target_unit = breakable_target or blackboard.target_unit
	local target_breed = Unit.get_data(target_unit, "breed")

	if not Unit.alive(target_unit) then
		return true
	end

	if script_data.ai_bots_disable_player_melee_attacks then
		local target_blackboard = BLACKBOARDS[target_unit]

		if target_blackboard and target_blackboard.is_player then
			return false
		end
	end

	local inventory_extension = blackboard.inventory_extension
	if not inventory_extension or inventory_extension:get_wielded_slot_name() ~= "slot_melee" then
		inventory_extension:wield("slot_melee")
		return true
	end
	
	local aim_position = self:_aim_position(target_unit, blackboard)
	local input_ext = blackboard.input_extension

	-- make bots face the follow target if too far, for higher move speed
	-- need a better definition of force regroup
	
	-- if is_aiming then
		-- input_ext:set_aiming(true, true)
	-- else
		-- input_ext:set_aiming(false)
	-- end
	
	-- input_ext:set_aim_position(aim_position)

	local wants_engage, eval_timer = nil
	local current_position = blackboard.first_person_extension:current_position()
	local follow_pos = (blackboard.follow and blackboard.follow.target_position:unbox()) or current_position
	local attack_input, attack_meta_data = self:_choose_attack(blackboard, target_unit)
	local melee_range = self:_calculate_melee_range(target_unit, attack_meta_data)
	
	-- melee_range = math.max(melee_range, 3)
	local melee_range_altered = melee_range
	if target_breed and (mod.BOSS_UNITS[target_breed.name] or mod.LORD_UNITS_LARGE[target_breed.name]) then		--large body requires extending the melee range
		melee_range_altered = math.max(melee_range_altered, 4)
	end
	
	local self_position = POSITION_LOOKUP[unit]
	local target_position = POSITION_LOOKUP[target_unit]
	local target_offset = self_position and target_position and (target_position - self_position)
	local height_offset	= (target_offset and math.abs(target_offset.z)) or math.huge
	
	local aim_upward_factor = 0
	
	if (not SWEEP_ATTACK_HITBOX_TWEAK_ENABLED) and target_breed and target_breed.race ~= "skaven" and (not mod.BOSS_UNITS[target_breed.name]) then
		local target_locomotion_extension = ScriptUnit.has_extension(target_unit, "locomotion_system")
		local target_velocity = target_locomotion_extension and target_locomotion_extension:current_velocity() or Vector3.zero()
		local locomotion_extension = blackboard.locomotion_extension
		local current_velocity = locomotion_extension:current_velocity()
		local relative_velocity = current_velocity - target_velocity
		local time_to_next_attack = math.max(self:_time_to_next_attack(attack_input, blackboard, t) or 0, 0)
		local check_position = current_position + relative_velocity * time_to_next_attack
		
		local aim_target_distance = Vector3.distance(aim_position, check_position)
		local aim_target_distance_percentage = math.clamp(aim_target_distance, 0.25 * melee_range, melee_range) or 1
		aim_upward_factor = math.auto_lerp(0.25 * melee_range, melee_range, 0.15, 0.05, aim_target_distance_percentage)
	end
	
	input_ext:set_aim_position(aim_position + Vector3.up() * aim_upward_factor)
	
	local melee_bb = blackboard.melee
	local already_engaged = melee_bb.engaging

	local should_engage	= self:_is_in_engage_range(unit, target_unit, blackboard.nav_world, action_data, follow_pos)
	local in_melee_range = self:_is_in_melee_range(current_position, aim_position, melee_range_altered, attack_input, t, blackboard, target_unit)
	
	-- local self_position = POSITION_LOOKUP[unit]
	-- local target_position = POSITION_LOOKUP[target_unit]
	-- local target_offset = self_position and target_position and (target_position - self_position)
	-- local height_offset	= (target_offset and math.abs(target_offset.z)) or math.huge
	local in_engage_range = height_offset < 3.8 and should_engage
	
	local target_in_front, _ = mod.check_alignment_to_target(target_unit, unit, 120)
	local defending	= self:_defend(unit, blackboard, target_unit, input_ext, t, true)

	-- Vernon: make bots move away from enemies if surrounded
	-- Vernon TODO: check effectiveness of logic
	local self_owner = Managers.player:unit_owner(unit)
	local defense_data = self_owner.defense_data
	if defense_data and defense_data.is_surrounded then
		if not melee_bb.disengage_update_time then
			melee_bb.disengage_update_time = 0
		end
		
		if melee_bb.disengage_update_time < t then
			local keep_distance = 8		-- Vernon: surrounded check is done with medium radius = 8
			local move_towards_ally = not defense_data.is_boss_target
			local ally_distance_threshold = 7	--3.5
			
			update_disengage_position_melee(unit, defense_data, blackboard, t, keep_distance, move_towards_ally, ally_distance_threshold)
			
			if melee_bb.disengage_position_set then
				-- may_engage = false
				should_engage = false
				in_engage_range = false
			end
		end
	else
		melee_bb.disengage_position_set = false
	end

	local skip_not_to_engage_check = {
		skaven_pack_master = true,
		skaven_gutter_runner = true,
		chaos_corruptor_sorcerer = true,
	}

	if should_engage and target_breed and not skip_not_to_engage_check[target_breed.name] then
		local prox_enemies_target = mod.get_proximite_enemies(target_unit, 2)
		local ally_distance_to_target = math.huge
		
		for _, player in pairs(Managers.player:players()) do
			local loop_unit = player.player_unit
			if loop_unit ~= unit then
				local status_extension = ScriptUnit.has_extension(loop_unit, "status_system")
				local enabled = status_extension and not status_extension:is_disabled()
				if enabled then
					local loop_position = POSITION_LOOKUP[loop_unit]
					local loop_distance = loop_position and target_pos and Vector3.length(target_pos - loop_position)
					if loop_distance and ally_distance_to_target < loop_distance then
						ally_distance_to_target = loop_distance
					end
				end
			end
		end
		
		if (ally_distance_to_target > 2 and #prox_enemies_target > 3) or #prox_enemies_target > 7 then	--4,7	--3, 5
			should_engage = false
			in_engage_range = false
		end
		
		if should_engage then
			local count_danger = 0
			prox_enemies_target = mod.get_proximite_enemies(target_unit, 3)
			
			for _,loop_unit in pairs(prox_enemies_target) do
				local loop_breed = loop_unit and Unit.get_data(loop_unit, "breed")
				if mod.ELITE_UNITS[loop_breed.name] or mod.BERSERKER_UNITS[loop_breed.name] then
					count_danger = count_danger + 1
				elseif mod.BOSS_UNITS[loop_breed.name] or mod.LORD_UNITS_LARGE[loop_breed.name] then
					count_danger = count_danger + 3
				end
			end
			
			if count_danger > 2 then	--3		--5
				should_engage = false
				in_engage_range = false
			end
			
			if should_engage then
				count_danger = 0
				prox_enemies_target = mod.get_proximite_enemies(target_unit, 6)	--5
				
				for _,loop_unit in pairs(prox_enemies_target) do
					local loop_breed = loop_unit and Unit.get_data(loop_unit, "breed")
					if mod.ELITE_UNITS[loop_breed.name] or mod.BERSERKER_UNITS[loop_breed.name] then
						count_danger = count_danger + 1
					elseif mod.BOSS_UNITS[loop_breed.name] or mod.LORD_UNITS_LARGE[loop_breed.name] then
						count_danger = count_danger + 1
					end
				end
				
				if count_danger > 9 then	--9
					should_engage = false
					in_engage_range = false
				end
			end
		end
	end

	--seems to make bots ignore monster attacks
	-- if in_melee_range and not defending and (breakable_target or (target_in_front and target_breed and not (mod.BOSS_UNITS[target_breed.name] or mod.LORD_UNITS[target_breed.name]))) then
	if in_melee_range and not defending then
		self:_attack(attack_input, blackboard)
	end
	
	if in_melee_range and should_engage then
		wants_engage = true
	elseif in_engage_range then
		wants_engage = true
	else
		wants_engage = already_engaged and (t - melee_bb.engage_change_time <= 0)
	end

	-- if self:_is_in_melee_range(current_position, aim_position, melee_range, attack_input, t, blackboard, target_unit) then
		-- if not self:_defend(unit, blackboard, target_unit, input_ext, t, true) then
			-- self:_attack(attack_input, blackboard)
		-- end

		-- wants_engage = blackboard.aggressive_mode or (melee_bb.engaging and t - melee_bb.engage_change_time < 5)
	-- elseif self:_is_in_engage_range(unit, target_unit, blackboard.nav_world, action_data, follow_pos) then
		-- self:_defend(unit, blackboard, target_unit, input_ext, t, false)

		-- wants_engage = true
	-- else
		-- self:_defend(unit, blackboard, target_unit, input_ext, t, false)

		-- wants_engage = melee_bb.engaging and t - melee_bb.engage_change_time <= 0
	-- end

	-- local is_starting_attack = self:_is_starting_attack(blackboard)

	-- if is_starting_attack then
		-- eval_timer = math.huge
	-- end

	eval_timer = 1
	
	local engage = wants_engage and self:_allow_engage(unit, target_unit, blackboard, action_data, already_engaged, aim_position, follow_pos)

	if engage and not already_engaged then
		self:_engage(t, blackboard)

		already_engaged = true
	elseif not engage and already_engaged then
		self:_disengage(unit, t, blackboard)

		already_engaged = false
	end

	if already_engaged and (not melee_bb.engage_update_time or melee_bb.engage_update_time < t) and not action_data.do_not_update_engage_position then
		self:_update_engage_position(unit, target_unit, blackboard, t, melee_range)
	end

	return false, self:_evaluation_timer(blackboard, t, eval_timer)
end)




-- Direct copy from the original
local function check_angle(nav_world, target_position, start_direction, angle, distance)
	local direction = Quaternion.rotate(Quaternion(Vector3.up(), angle), start_direction)
	local check_pos = target_position - direction * distance
	local success, altitude = GwNavQueries.triangle_from_position(nav_world, check_pos, 0.5, 0.5)

	if success then
		check_pos.z = altitude

		return true, check_pos
	else
		return false
	end
end

-- Almost direct copy from the original
local function get_engage_pos(nav_world, target_unit_pos, engage_from, melee_distance)
	local subdivisions_per_side = 6 -- origally 3
	local angle_inc = math.pi / (subdivisions_per_side + 1)
	local start_direction = Vector3.normalize(Vector3.flat(engage_from))
	local success, pos = check_angle(nav_world, target_unit_pos, start_direction, 0, melee_distance)

	if success then
		return pos
	end

	for i = 1, subdivisions_per_side, 1 do
		local angle = angle_inc * i
		success, pos = check_angle(nav_world, target_unit_pos, start_direction, angle, melee_distance)

		if success then
			return pos
		end

		success, pos = check_angle(nav_world, target_unit_pos, start_direction, -angle, melee_distance)

		if success then
			return pos
		end
	end

	success, pos = check_angle(nav_world, target_unit_pos, start_direction, math.pi, melee_distance)

	if success then
		return pos
	end

	return nil
end

--need more tweaks to avoid boss melee slam attacks and chaos spawn tentacle grab
--[[
mod:hook_origin(BTBotMeleeAction, "_update_engage_position", function(self, unit, target_unit, blackboard, t, melee_range)
	local nav_world = blackboard.nav_world
	local self_position = POSITION_LOOKUP[unit]
	local target_unit_position = self:_target_unit_position(self_position, target_unit, nav_world)
	local engage_position, engage_from, should_stop = nil
	local targeting_me, breed = self:_is_targeting_me(unit, target_unit)
	local enemy_offset = target_unit_position - self_position
	local melee_distance = melee_range - 0.5
	-- local melee_distance = (melee_range*0.9) - 0.2
	
	if self._tree_node.action_data.destroy_object then
		melee_distance = math.max(melee_distance, 1.8)
	end
	
	if math.abs(enemy_offset.z) > 3.5 then	--2
		return
	end
	
	-- local target_locomotion_extension = ScriptUnit.has_extension(target_unit, "locomotion_system")
	-- if target_locomotion_extension then
		-- local target_velocity = target_locomotion_extension:current_velocity()
		
		-- if Vector3.dot(target_velocity, Vector3.normalize(enemy_offset)) > 2 then
			-- melee_distance = math.max(melee_distance-1, 0)
		-- end
	-- end
	
	local melee_distance_sq = melee_distance^2

	local bots_flank_while_targeted = {
		skaven_warpfire_thrower = true,
		skaven_ratling_gunner = true,
		
		skaven_stormfiend = true,
		skaven_stormfiend_boss = true,
		chaos_troll = true,
	}

	--(target_breed.name == "skaven_stormfiend" or target_breed.name == "skaven_stormfiend_boss")
	if breed and breed.bots_should_flank then
		--bots flank bosses and elites
		
		local flanking = false
		local enemy_rot = Unit.local_rotation(target_unit, 0)
		local enemy_dir = Quaternion.forward(enemy_rot)
		local flank_cos = Vector3.dot(Vector3.normalize(enemy_dir), Vector3.normalize(enemy_offset))
		if 0.940 < flank_cos then flanking = true end	-- 0.966 = 2x 15deg, 0.940 = 2x 20deg, 0.866 = 2x 30deg deg rear sector
		
		local targeting_boss = false
		if mod.BOSS_UNITS[breed.name] or mod.LORD_UNITS_LARGE[breed.name] then
			melee_distance	= 2.9	-- used only when the bot is flanking a large boss
			targeting_boss	= true
		end
		
		local chaos_spawn_tentacle_grab = false
		if breed.name == "chaos_spawn" then
			local target_bb = target_unit and BLACKBOARDS[target_unit]
			if target_bb and target_bb.action and target_bb.action.name == "tentacle_grab" then
				melee_distance = 6	--can be refined
				chaos_spawn_tentacle_grab = true
			end
		end
		
		local lord_all_direction_attack = false
		if breed.name == "skaven_storm_vermin_warlord" then
			local target_bb = target_unit and BLACKBOARDS[target_unit]
			if target_bb and target_bb.action and (target_bb.action.name == "special_attack_spin" or target_bb.action.name == "defensive_mode_spin") then
				melee_distance = 5.5
				lord_all_direction_attack = true
			end
		end
		
		if breed.name == "chaos_exalted_champion_warcamp" or breed.name == "chaos_exalted_champion_norsca" then
			local target_bb = target_unit and BLACKBOARDS[target_unit]
			if target_bb and target_bb.action and (target_bb.action.name == "special_attack_aoe" or target_bb.action.name == "special_attack_aoe_defensive" or target_bb.action.name == "special_attack_retaliation_aoe") then
				melee_distance = 5.5
				lord_all_direction_attack = true
			end
		end
		
		if breed.name == "skaven_stormfiend_boss" then
			local target_bb = target_unit and BLACKBOARDS[target_unit]
			if target_bb and target_bb.action and target_bb.action.name == "special_attack_aoe" then
				melee_distance = 5.5
				lord_all_direction_attack = true
			end
		end
		
		-- if not targeting_me or breed.bots_flank_while_targeted then
		if false then
			-- either this bot is not being targeted or bots should flank this breed even while targetted
			
			if flanking then
				-- if the bot is already flanking the bot's approach vector to the enemy
				-- is set to the current approach direction
				engage_from = enemy_offset or Vector3(1,0,1)
			else
				-- if the bot is not flanking the target then the angle of the bot's approach vector is tilted so the bot will start to move around the enemy
				local normalized_enemy_dir = Vector3.normalize(Vector3.flat(enemy_dir))
				local normalized_enemy_offset = Vector3.normalize(Vector3.flat(enemy_offset))
				local offset_angle = Vector3.flat_angle(-normalized_enemy_offset, normalized_enemy_dir)
				local new_angle = nil
				
				-- if (mod.BOSS_UNITS[breed.name] or mod.LORD_UNITS_LARGE[breed.name]) and breed.name ~= "chaos_troll" and not chaos_spawn_tentacle_grab then
				if (mod.BOSS_UNITS[breed.name] or mod.LORD_UNITS_LARGE[breed.name]) and not chaos_spawn_tentacle_grab and not lord_all_direction_attack then
					melee_distance = 3.7
				end
				
				if 0 < offset_angle then
					new_angle = offset_angle + math.pi/4
				else
					new_angle = offset_angle - math.pi/4
				end

				local new_rot = Quaternion.multiply(Quaternion(Vector3.up(), -new_angle), enemy_rot)
				engage_from = -Quaternion.forward(new_rot)
			end
			
			-- now that the apporach vector has been resolved and desired distance to the enemy
			-- has been updated as needed, resolve the actual engage position of this iteration
			engage_position = get_engage_pos(nav_world, target_unit_position, engage_from, melee_distance)
			--
		elseif mod._is_attacking_me(unit, target_unit) and targeting_boss and Vector3.length(enemy_offset) < melee_distance+1 then
			-- make the bot targeted by an ogre to back off when the ogre attacks
			engage_position = self_position - (2 * Vector3.normalize(enemy_offset))
		elseif math.abs(Vector3.length(enemy_offset) - melee_distance) < 0.2 then
			-- condition changed so bots that are targeted by an ogre would take a step back if the ogre comes too close
			
			-- if the bot is being targeted by the enemy and is not supposed to flank it while targeted
			-- and the distance to the enemy is already within certain tolerance, set the engage position to current position
			engage_position = self_position
			should_stop = true
		else
			-- if the bot is being targetted, but the distance to the target is not correct, update the engage position
			engage_position = get_engage_pos(nav_world, target_unit_position, enemy_offset, melee_distance)
		end
	else
		-- the bot doesn't need to flank this target
		
		local enemy_distance = Vector3.length(enemy_offset)
		local distance_deviation = enemy_distance - melee_distance
		
		if distance_deviation > 1 then
			if self._tree_node.action_data.destroy_object then
				-- get_engage_pos fails for some breakables due to their height offset being
				-- >0.5 to that of the bot's which causes angle check fails >> use target's position as engage position
				engage_position = target_unit_position
			else
				engage_position = get_engage_pos(nav_world, target_unit_position, enemy_offset, melee_distance)
			end
		elseif distance_deviation > 0 then
			engage_position = target_unit_position
		elseif distance_deviation < -0.1 then
			--maintain distance for easier headshots, safety and better movability / escape route
			engage_position = self_position + Vector3.normalize(self_position - target_unit_position)
		else
			engage_position = self_position
			should_stop = true
		end
	-- else	--halescourge / blood in the darkness / enchanter's lair swarm projectiles, or something else?
		-- local locomotion_extension = ScriptUnit.extension(target_unit, "projectile_locomotion_system")
		-- target_unit_position = (locomotion_extension and locomotion_extension:current_position()) or target_unit_position or POSITION_LOOKUP[target_unit]
		-- enemy_offset = self_position and target_unit_position and target_unit_position - self_position
		-- local distance = enemy_offset and Vector3.length(enemy_offset)
	end

	if engage_position then
		local melee_bb = blackboard.melee
		local override_box = blackboard.navigation_destination_override
		local override_destination = override_box:unbox()
		local engage_pos_set = melee_bb.engage_position_set

		fassert(not engage_pos_set or Vector3.is_valid(override_destination))

		if not engage_pos_set or Vector3.distance_squared(engage_position, override_destination) > 0.01 then
			override_box:store(engage_position)

			melee_bb.engage_position_set = true
			melee_bb.stop_at_current_position = should_stop
		end

		local interval = 0.2	--0.15	--0.2
		melee_bb.engage_update_time = t + interval
	end
end)
--]]

--remove the not unblockable condition
local is_attacking_me = function (self_unit, enemy_unit)
	local bb = BLACKBOARDS[enemy_unit]

	if not bb then
		return false
	end

	local enemy_buff_extension = ScriptUnit.has_extension(enemy_unit, "buff_system")

	if enemy_buff_extension and enemy_buff_extension:has_buff_perk("ai_unblockable") then
		return false
	end

	-- local action = bb.action
	-- local unblockable = action and action.unblockable

	-- return not unblockable and bb.attacking_target == self_unit and not bb.past_damage_in_attack
	return bb.attacking_target == self_unit and not bb.past_damage_in_attack
end

mod:hook_origin(BTBotMeleeAction, "_update_engage_position", function(self, unit, target_unit, blackboard, t, melee_range)
	local nav_world = blackboard.nav_world
	local self_position = POSITION_LOOKUP[unit]
	local target_unit_position = self:_target_unit_position(self_position, target_unit, nav_world)
	local engage_position, engage_from, should_stop = nil
	local targeting_me, breed = self:_is_targeting_me(unit, target_unit)
	local target_bb = target_unit and BLACKBOARDS[target_unit]
	local enemy_offset = target_unit_position - self_position
	local melee_distance = melee_range - 0.5
	-- local melee_distance = (melee_range*0.9) - 0.2
	
	if self._tree_node.action_data.destroy_object then
		melee_distance = math.max(melee_distance, 1.8)
	end
	
	if math.abs(enemy_offset.z) > 3.5 then	--2
		return
	end

	--adjust melee distance for large enemy units
	if target_unit and breed and (mod.LORD_UNITS_LARGE[breed.name] or (breed.name == "chaos_troll")) then		
		local in_front_of_target, flanking_target = mod.check_alignment_to_target(unit, target_unit, 90, 180)
		
		if in_front_of_target then
			melee_distance = math.max(melee_distance - 0.2, 2.8)
		else
			melee_distance = math.max(melee_distance, 2.8)
		end
	-- elseif target_unit and targeting_me and (breed.name == "chaos_spawn" or breed.name == "chaos_spawn_exalted_champion_norsca") then
		--the bot being targeted should hug the chaos spawn
		--https://steamcommunity.com/sharedfiles/filedetails/?id=1723437775
		
		-- local in_front_of_target, flanking_target = mod.check_alignment_to_target(unit, target_unit, 90, 180)
		
		-- if in_front_of_target then
			-- melee_distance = math.max(melee_distance + 0.5, 3)
		-- else
			-- melee_distance = math.max(melee_distance + 1, 3)
		-- end
	elseif target_unit and breed and mod.BOSS_UNITS[breed.name] then
		local in_front_of_target, flanking_target = mod.check_alignment_to_target(unit, target_unit, 90, 180)
		
		if in_front_of_target then
			melee_distance = math.max(melee_distance + 1.5, 4)
		else
			melee_distance = math.max(melee_distance + 1, 3)
		end
	end
	
	--keep distance for defense
	local targeting_boss = false
	if breed and (mod.BOSS_UNITS[breed.name] or mod.LORD_UNITS_LARGE[breed.name]) then
		-- melee_distance	= 2.9	-- used only when the bot is flanking a large boss
		targeting_boss	= true
	end
	
	if breed and (breed.name == "chaos_spawn" or breed.name == "chaos_spawn_exalted_champion_norsca") then
		if target_bb and target_bb.action and target_bb.action.name == "tentacle_grab" then
			local in_front_of_target, flanking_target = mod.check_alignment_to_target(unit, target_unit, nil, 160)
			if not flanking_target then
				melee_distance = 6	--can be refined
			end
		end
	end
	
	if breed and breed.name == "skaven_storm_vermin_warlord" then
		if target_bb and target_bb.action and (target_bb.action.name == "special_attack_spin" or target_bb.action.name == "defensive_mode_spin") then
			melee_distance = 5.5
		end
	end
	
	if breed and (breed.name == "chaos_exalted_champion_warcamp" or breed.name == "chaos_exalted_champion_norsca") then
		if target_bb and target_bb.action and (target_bb.action.name == "special_attack_aoe" or target_bb.action.name == "special_attack_aoe_defensive" or target_bb.action.name == "special_attack_retaliation_aoe") then
			melee_distance = 5.5
		end
	end
	
	if breed and breed.name == "skaven_stormfiend_boss" then
		if target_bb and target_bb.action and target_bb.action.name == "special_attack_aoe" then
			melee_distance = 5.5
		end
	end

	local bots_flank_when_attacked = {
		skaven_warpfire_thrower = true,
		skaven_ratling_gunner = true,
		
		skaven_stormfiend = true,
		skaven_stormfiend_boss = true,
		chaos_troll = true,
	}
	
	-- local engage_update_interval = 0.075 + 0.025 * math.random()
	local in_front_of_target, flanking_target = mod.check_alignment_to_target(unit, target_unit, 160, nil)

	if breed and bots_flank_when_attacked[breed.name] and in_front_of_target and is_attacking_me(unit, target_unit) then
		if targeting_boss and Vector3.length(enemy_offset) < melee_distance+1 then
			-- make the bot targeted by a boss to back off when the boss attacks
			engage_position = self_position - (2 * Vector3.normalize(enemy_offset))
		else
			local enemy_rot = Unit.local_rotation(target_unit, 0)
			local enemy_dir = Quaternion.forward(enemy_rot)
			
			-- if the bot is not flanking the target then the angle of the bot's approach vector is tilted so the bot will start to move around the enemy
			local normalized_enemy_dir = Vector3.normalize(Vector3.flat(enemy_dir))
			local normalized_enemy_offset = Vector3.normalize(Vector3.flat(enemy_offset))
			local offset_angle = Vector3.flat_angle(-normalized_enemy_offset, normalized_enemy_dir)
			local new_angle = nil
			
			if 0 < offset_angle then
				new_angle = offset_angle + math.pi/2
			else
				new_angle = offset_angle - math.pi/2
			end

			local new_rot = Quaternion.multiply(Quaternion(Vector3.up(), -new_angle), enemy_rot)
			engage_from = -Quaternion.forward(new_rot)
			
			-- now that the apporach vector has been resolved and desired distance to the enemy
			-- has been updated as needed, resolve the actual engage position of this iteration
			engage_position = get_engage_pos(nav_world, target_unit_position, engage_from, melee_distance)
		end
	else
		local enemy_distance = Vector3.length(enemy_offset)
		local distance_deviation = enemy_distance - melee_distance
		
		local troll_downed = breed and breed.name == "chaos_troll" and target_bb and target_bb.action and target_bb.action.name == "downed"
		local in_front_of_target, flanking_target = mod.check_alignment_to_target(unit, target_unit, 90, nil)
		
		if troll_downed and not in_front_of_target then
			--copy codes above for franking to make bots walk to the front of downed Chaos Troll
			local enemy_rot = Unit.local_rotation(target_unit, 0)
			local enemy_dir = Quaternion.forward(enemy_rot)
			
			local normalized_enemy_dir = Vector3.normalize(Vector3.flat(enemy_dir))
			local normalized_enemy_offset = Vector3.normalize(Vector3.flat(enemy_offset))
			local offset_angle = Vector3.flat_angle(-normalized_enemy_offset, normalized_enemy_dir)
			local new_angle = nil
			
			if 0 < offset_angle then
				new_angle = offset_angle - math.pi/4
			else
				new_angle = offset_angle + math.pi/4
			end

			local new_rot = Quaternion.multiply(Quaternion(Vector3.up(), -new_angle), enemy_rot)
			engage_from = -Quaternion.forward(new_rot)
			
			-- now that the apporach vector has been resolved and desired distance to the enemy
			-- has been updated as needed, resolve the actual engage position of this iteration
			engage_position = get_engage_pos(nav_world, target_unit_position, engage_from, melee_distance)
		elseif targeting_boss and Vector3.length(enemy_offset) < melee_distance+1 then
			-- make the bot targeted by a boss to back off when the boss attacks
			engage_position = self_position - (2 * Vector3.normalize(enemy_offset))
		elseif distance_deviation > 0 then
			if self._tree_node.action_data.destroy_object then
				-- get_engage_pos fails for some breakables due to their height offset being
				-- >0.5 to that of the bot's which causes angle check fails >> use target's position as engage position
				engage_position = target_unit_position
			else
				engage_position = get_engage_pos(nav_world, target_unit_position, enemy_offset, melee_distance)
				
				if not engage_position then
					engage_position = target_unit_position
				end
			end
		elseif distance_deviation < -1 then	--0.1
			if self._tree_node.action_data.destroy_object then
				-- get_engage_pos fails for some breakables due to their height offset being
				-- >0.5 to that of the bot's which causes angle check fails >> use target's position as engage position
				engage_position = target_unit_position
			else
				engage_position = get_engage_pos(nav_world, target_unit_position, enemy_offset, melee_distance)
				
				if not engage_position then
					engage_position = self_position
					should_stop = true
				end
			end
		else
			engage_position = self_position
			should_stop = true
		end
	-- else	--halescourge / blood in the darkness / enchanter's lair swarm projectiles, or something else?
		-- local locomotion_extension = ScriptUnit.extension(target_unit, "projectile_locomotion_system")
		-- target_unit_position = (locomotion_extension and locomotion_extension:current_position()) or target_unit_position or POSITION_LOOKUP[target_unit]
		-- enemy_offset = self_position and target_unit_position and target_unit_position - self_position
		-- local distance = enemy_offset and Vector3.length(enemy_offset)
	end

	if engage_position then
		local melee_bb = blackboard.melee
		local override_box = blackboard.navigation_destination_override
		local override_destination = override_box:unbox()
		local engage_pos_set = melee_bb.engage_position_set

		fassert(not engage_pos_set or Vector3.is_valid(override_destination))

		if not engage_pos_set or Vector3.distance_squared(engage_position, override_destination) > 0.01 then
			override_box:store(engage_position)

			melee_bb.engage_position_set = true
			melee_bb.stop_at_current_position = should_stop
		end

		local interval = 0.2	--0.15	--0.2
		melee_bb.engage_update_time = t + interval
	end
end)



--Increase regroup distance if targeted by running attack monters, to avoid dragging attack into the team

local FAR_DISTANCE_FROM_FOLLOW_POS_SQ = 64		--25
mod:hook_origin(BTBotMeleeAction, "_is_in_engage_range", function(self, self_unit, target_unit, nav_world, action_data, follow_pos)
	-- local party_danger = AiUtils.get_party_danger()
	-- local engage_range_close = math.lerp(action_data.engage_range_near_follow_pos, action_data.engage_range_near_follow_pos_threat, party_danger)
	-- local engage_range_far = math.lerp(action_data.engage_range, action_data.engage_range_threat, party_danger)
	-- local self_position = POSITION_LOOKUP[self_unit]
	-- local distance_from_follow_t = math.clamp(Vector3.distance_squared(follow_pos, self_position) / FAR_DISTANCE_FROM_FOLLOW_POS_SQ, 0, 1)
	-- local engage_range = math.lerp(engage_range_close, engage_range_far, distance_from_follow_t)
	-- local target_unit_position = self:_target_unit_position(self_position, target_unit, nav_world)

	-- return Vector3.distance_squared(self_position, target_unit_position) < engage_range * engage_range
	
	-- local targeted_by_nearby_running_attack_boss = false
	
	local self_position = POSITION_LOOKUP[self_unit]
	
	local alive_bosses = mod.get_spawned_running_attack_bosses()
	local num_alive_bosses = #alive_bosses
	
	for i = 1, num_alive_bosses, 1 do
		local loop_unit = alive_bosses[i]
		local loop_pos = POSITION_LOOKUP[loop_unit]
		local loop_bb = BLACKBOARDS[loop_unit]

		if mod.is_unit_alive(loop_unit) and loop_bb and loop_bb.target_unit == self_unit and Vector3.distance_squared(loop_pos, self_position) < 36 then
			local engage_range = 15		--18	--15
			local target_unit_position = self:_target_unit_position(self_position, target_unit, nav_world)
			
			return Vector3.distance_squared(self_position, target_unit_position) < engage_range * engage_range
		end
	end
	
	-- return func(self, self_unit, target_unit, nav_world, action_data, follow_pos)
	
	local party_danger = AiUtils.get_party_danger()
	local engage_range_close = math.lerp(action_data.engage_range_near_follow_pos, action_data.engage_range_near_follow_pos_threat, party_danger)
	local engage_range_far = math.lerp(action_data.engage_range, action_data.engage_range_threat, party_danger)
	local self_position = POSITION_LOOKUP[self_unit]
	local distance_from_follow_t = math.clamp(Vector3.distance_squared(follow_pos, self_position) / FAR_DISTANCE_FROM_FOLLOW_POS_SQ, 0, 1)
	-- local engage_range = math.lerp(engage_range_close, engage_range_far, distance_from_follow_t)
	local engage_range = math.lerp(engage_range_far, engage_range_close, distance_from_follow_t)
	local target_unit_position = self:_target_unit_position(self_position, target_unit, nav_world)

	return Vector3.distance_squared(self_position, target_unit_position) < engage_range * engage_range
end)




--Gas cloud / Barrel / Damage AoE check for bot melee action

local is_unit_in_aoe_explosion_threat_area = function(unit)		-- check if the given unit is inside gas / fire patch / triggered barrel effect area
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

mod:hook(BTBotMeleeAction, "_allow_engage", function(func, self, self_unit, target_unit, blackboard, action_data, already_engaged, aim_position, follow_pos)
	local ret = func(self, self_unit, target_unit, blackboard, action_data, already_engaged, aim_position, follow_pos)
	
	local target_ally_unit = blackboard.target_ally_unit
	local follow_unit = (blackboard.target_ally_need_type and target_ally_unit) or blackboard.ai_bot_group_extension.data.follow_unit
	
	return ret and ((not is_unit_in_aoe_explosion_threat_area(target_unit) and not is_unit_in_aoe_explosion_threat_area(self_unit)) or is_unit_in_aoe_explosion_threat_area(follow_unit))
end)




-- In VT1 bots perform a push when switching straight from block to attack.
-- This seems an oversight since it happens due to lingering _defend_held attribute.
-- The condition check below removes this behavior.
-- Need to check this for VT2

-- mod:hook(BTBotMeleeAction, "_attack", function(func, self, attack_input, blackboard)
	-- if blackboard.input_extension and blackboard.input_extension._defend_held then
		-- return
	-- end

	-- func(self, attack_input, blackboard)
-- end)



--Base game codes for calculating stagger

local apply_buffs_to_power_level_on_hit = function (unit, power_level, breed, damage_source, is_critical_strike, armor_override)
	if not Unit.alive(unit) then
		return power_level
	end

	local buff_extension = ScriptUnit.has_extension(unit, "buff_system")

	if not buff_extension then
		return power_level
	end

	local stacked_multiplier = 1

	if damage_source then
		local item_data = rawget(ItemMasterList, damage_source)
		local weapon_template_name = item_data and item_data.template

		if weapon_template_name then
			local power_level_weapon_multiplier = 1
			local weapon_template = Weapons[weapon_template_name]
			local buff_type = weapon_template.buff_type
			local is_melee = MeleeBuffTypes[buff_type]
			local is_ranged = RangedBuffTypes[buff_type]
			local weapon_type = weapon_template.weapon_type

			if is_melee then
				power_level_weapon_multiplier = buff_extension:apply_buffs_to_value(power_level_weapon_multiplier, "power_level_melee")
			elseif is_ranged then
				power_level_weapon_multiplier = buff_extension:apply_buffs_to_value(power_level_weapon_multiplier, "power_level_ranged")
			end

			if weapon_type and weapon_type == "DRAKEFIRE" then
				power_level_weapon_multiplier = buff_extension:apply_buffs_to_value(power_level_weapon_multiplier, "power_level_ranged_drakefire")
			end

			stacked_multiplier = stacked_multiplier + (power_level_weapon_multiplier - 1)
		end
	end

	local armor_power_level_target_multiplier = 1
	local armor_category = armor_override or breed and breed.armor_category or 1

	if armor_category == 2 then
		armor_power_level_target_multiplier = buff_extension:apply_buffs_to_value(armor_power_level_target_multiplier, "power_level_armoured")
	elseif armor_category == 3 then
		armor_power_level_target_multiplier = buff_extension:apply_buffs_to_value(armor_power_level_target_multiplier, "power_level_large")
	elseif armor_category == 5 then
		armor_power_level_target_multiplier = buff_extension:apply_buffs_to_value(armor_power_level_target_multiplier, "power_level_frenzy")
	elseif armor_category == 1 then
		armor_power_level_target_multiplier = buff_extension:apply_buffs_to_value(armor_power_level_target_multiplier, "power_level_unarmoured")
	end

	stacked_multiplier = stacked_multiplier + (armor_power_level_target_multiplier - 1)

	local race_power_level_target_multiplier = 1
	local race = unit_get_data(unit, "race") or breed and breed.race

	if race == "chaos" or race == "beastmen" then
		race_power_level_target_multiplier = buff_extension:apply_buffs_to_value(race_power_level_target_multiplier, "power_level_chaos")
	elseif race == "skaven" then
		race_power_level_target_multiplier = buff_extension:apply_buffs_to_value(race_power_level_target_multiplier, "power_level_skaven")
	end

	stacked_multiplier = stacked_multiplier + (race_power_level_target_multiplier - 1)

	if is_critical_strike then
		local power_level_crit_multiplier = 1

		power_level_crit_multiplier = buff_extension:apply_buffs_to_value(power_level_crit_multiplier, "power_level_critical_strike")
		stacked_multiplier = stacked_multiplier + (power_level_crit_multiplier - 1)
	end

	power_level = power_level * stacked_multiplier

	return power_level
end

local can_stagger = function(unit, power_level, breed, weapon_template, dummy_unit_armor)
	if not unit or not power_level or not breed or not weapon_template then
		return false
	end
	
	local impact_power = apply_buffs_to_power_level_on_hit(unit, power_level, breed, weapon_template, dummy_unit_armor)
	
	local stagger_table = ImpactTypeOutput
	if stagger_table and not breed.stagger_immune then
		local stagger_settings = stagger_table[breed.armor_category or 1]
		local stagger_range = stagger_settings.max - stagger_settings.min
		
		local buff_extension = unit and ScriptUnit.has_extension(unit, "buff_system")
		if buff_extension then
			impact_power = buff_extension:apply_buffs_to_value(impact_power, "push_power")
			--local blackboard_action = (is_player and status_extension:breed_action()) or blackboard.action

			--if blackboard_action and blackboard_action.damage then
			--	impact_power = attacker_buff_extension:apply_buffs_to_value(impact_power, "counter_push_power")
			--end
		end

		if buff_extension then
			impact_power = buff_extension:apply_buffs_to_value(impact_power, "power_level_impact")
		end

		if target_buff_extension then
			impact_power = target_buff_extension:apply_buffs_to_value(impact_power, "impact_vulnerability")
		end

		local percentage = ActionUtils.get_power_level_percentage(impact_power)
		stagger_strength = stagger_range * percentage
		stagger_strength = stagger_settings.min + stagger_strength
		
		--local difficulty_level = Managers.state.difficulty:get_difficulty()
		--mod:echo(difficulty_level)
		local difficulty_rank = Managers.state.difficulty:get_difficulty_rank()
		local buff_type = weapon_template and weapon_template.buff_type
		local is_ranged = buff_type and RangedBuffTypes[buff_type]
		
		local stagger_resistance = (breed.diff_stagger_resist and breed.diff_stagger_resist[difficulty_rank]) or (is_ranged and breed.stagger_resistance_ranged) or breed.stagger_resistance or 2
		
		--mod:echo(difficulty_rank)
		
		--local action_stagger_reduction = enemy_current_action and enemy_current_action.stagger_reduction
		local stagger_reduction = action_stagger_reduction and breed.stagger_reduction

		if stagger_reduction and type(stagger_reduction) == "table" then
			stagger_reduction = stagger_reduction[difficulty_rank]
		end

		if stagger_reduction then
			stagger_strength = math.clamp(stagger_strength - stagger_reduction, 0, stagger_strength)
		end

		local stagger_reduction = breed.stagger_reduction
		
		local stagger_threshold_light = (breed.stagger_threshold_light and breed.stagger_threshold_light * stagger_resistance) or 0.25 * stagger_resistance
		local stagger_threshold_heavy = (breed.stagger_threshold_heavy and breed.stagger_threshold_heavy * stagger_resistance) or 2.5 * stagger_resistance
		
		local first_push = true
		if first_push then
			stagger_threshold_heavy = stagger_threshold_heavy * 2
		end
		
		--mod:echo(stagger_threshold_light)

		if stagger_strength < stagger_threshold_light then
			return false
		end
	end
	
	return not breed.stagger_immune
end


local stagger_types = require("scripts/utils/stagger_types")
local PLAYER_TARGET_ARMOR = 4
local unit_get_data = Unit.get_data
local unit_alive = Unit.alive
local function do_stagger_calculation(stagger_table, breed, blackboard, attacker_unit, target_unit, hit_zone_name, original_power_level, boost_curve_multiplier, is_critical_strike, damage_profile, target_index, blocked, damage_source, range_scalar_multiplier, ai_shield_extension, difficulty_level, shield_user, has_power_boost, override_target_armor)
	if breed == nil then -- this is stupid but idc
		stagger_type = stagger_types.none
		return stagger_type
	end
	
	local target_unit_armor = override_target_armor or breed.stagger_armor_category or breed.armor_category or 1
	local stagger_type = stagger_types.none
	local stagger_strength = 0
	local duration = 1
	local distance = 1
	local attacker_buff_extension = attacker_unit and ScriptUnit.has_extension(attacker_unit, "buff_system")

	if attacker_buff_extension then
		attacker_buff_extension:trigger_procs("stagger_calculation_started", target_unit)
	end

	local target_buff_extension = target_unit and ScriptUnit.has_extension(target_unit, "buff_system")
	local target_settings = damage_profile.targets and damage_profile.targets[target_index] or damage_profile.default_target
	local attack_template_name = target_settings.attack_template
	local attack_template = DamageUtils.get_attack_template(attack_template_name)
	local ai_extension = ScriptUnit.has_extension(target_unit, "ai_system")
	local status_extension = ScriptUnit.has_extension(target_unit, "status_system")
	local is_player = blackboard.is_player and not ai_extension
	local is_ranged
	local optional_modifier_data = FrameTable.alloc_table()

	optional_modifier_data.damage_profile = damage_profile

	if breed then
		local item_data = rawget(ItemMasterList, damage_source)
		local weapon_template_name = item_data and item_data.template

		if weapon_template_name then
			local weapon_template = WeaponUtils.get_weapon_template(weapon_template_name)
			local buff_type = weapon_template and weapon_template.buff_type

			is_ranged = buff_type and RangedBuffTypes[buff_type]
			optional_modifier_data.is_ranged = is_ranged
		end
	end

	optional_modifier_data.is_ranged = is_ranged

	local stagger_count = is_player and status_extension and status_extension:stagger_count() or blackboard.stagger_count or 0

	if hit_zone_name == "weakspot" and stagger_count == 0 and (not blackboard.stagger or blackboard.stagger_anim_done or is_player and not status_extension:accumulated_stagger()) then
		stagger_type = stagger_types.weakspot
	elseif stagger_table and not breed.stagger_immune then
		local stagger_settings = stagger_table[target_unit_armor]
		local stagger_range = stagger_settings.max - stagger_settings.min
		local _, impact_power = ActionUtils.get_power_level_for_target(target_unit, original_power_level, damage_profile, target_index, is_critical_strike, attacker_unit, hit_zone_name, nil, damage_source, breed, range_scalar_multiplier, difficulty_level, target_unit_armor, nil)

		if attacker_unit and unit_alive(attacker_unit) and attacker_buff_extension then
			impact_power = attacker_buff_extension:apply_buffs_to_value(impact_power, "push_power")

			local blackboard_action = is_player and status_extension:breed_action() or blackboard.action

			if blackboard_action and blackboard_action.damage then
				impact_power = attacker_buff_extension:apply_buffs_to_value(impact_power, "counter_push_power")
			end
		end

		if attacker_buff_extension then
			impact_power = attacker_buff_extension:apply_buffs_to_value(impact_power, "power_level_impact")
		end

		if target_buff_extension then
			impact_power = target_buff_extension:apply_buffs_to_value(impact_power, "impact_vulnerability")
		end

		local percentage = ActionUtils.get_power_level_percentage(impact_power)

		stagger_strength = stagger_range * percentage

		local finesse_hit = is_critical_strike or hit_zone_name == "head" or hit_zone_name == "neck"

		stagger_strength = stagger_settings.min + stagger_strength

		if has_power_boost then
			stagger_strength = stagger_strength * 2
		end

		if breed then
			local difficulty_rank = DifficultySettings[difficulty_level].rank
			local stagger_resistance = breed.diff_stagger_resist and (breed.diff_stagger_resist[difficulty_rank] or breed.diff_stagger_resist[2]) or is_ranged and breed.stagger_resistance_ranged or breed.stagger_resistance or 2

			if target_buff_extension then
				stagger_resistance = target_buff_extension:apply_buffs_to_value(stagger_resistance, "stagger_resistance")
			end

			local enemy_current_action = is_player and status_extension:breed_action() or blackboard.action
			local action_stagger_reduction = enemy_current_action and enemy_current_action.stagger_reduction
			local stagger_reduction = not finesse_hit and not damage_profile.ignore_stagger_reduction and (action_stagger_reduction or breed.stagger_reduction)

			if stagger_reduction and type(stagger_reduction) == "table" then
				stagger_reduction = stagger_reduction[difficulty_rank] or stagger_reduction[2]
			end

			if stagger_reduction then
				stagger_strength = math.clamp(stagger_strength - stagger_reduction, 0, stagger_strength)
			end

			local first_push = false

			if blackboard.stagger then
				local stagger_bonus = math.clamp(blackboard.stagger * (breed.stagger_multiplier or 0.5) * stagger_strength, 0, stagger_strength)

				stagger_strength = stagger_strength + stagger_bonus
			elseif is_player and status_extension and status_extension:accumulated_stagger() > 0 then
				local stagger_tmp = status_extension:accumulated_stagger()
				local stagger_bonus = math.clamp(stagger_tmp * (breed.stagger_multiplier or 0.5) * stagger_strength, 0, stagger_strength)

				stagger_strength = stagger_strength + stagger_bonus
			elseif damage_profile.is_push then
				first_push = true
			end

			if stagger_strength > 0 then
				local no_light_threshold = finesse_hit
				local stagger_threshold_light = breed.stagger_threshold_light and breed.stagger_threshold_light * stagger_resistance or 0.25 * stagger_resistance
				local stagger_threshold_medium = breed.stagger_threshold_medium and breed.stagger_threshold_medium * stagger_resistance or 1 * stagger_resistance
				local stagger_threshold_heavy = breed.stagger_threshold_heavy and breed.stagger_threshold_heavy * stagger_resistance or 2.5 * stagger_resistance

				if first_push then
					stagger_threshold_heavy = stagger_threshold_heavy * 2
				end

				local stagger_threshold_explosion = breed.stagger_threshold_explosion and breed.stagger_threshold_explosion * stagger_resistance or 10 * stagger_resistance
				local excessive_force = 0
				local scale
				local impact_modifier = 1

				if stagger_strength < stagger_threshold_light then
					stagger_type = stagger_types.none
				elseif stagger_strength < stagger_threshold_medium then
					stagger_type = stagger_types.weak
					excessive_force = stagger_strength
					scale = excessive_force > 0 and excessive_force / stagger_resistance or 0
					impact_modifier = 0.5 + 0.5 * math.clamp(scale, 0, 1)
				elseif stagger_strength < stagger_threshold_heavy then
					stagger_type = stagger_types.medium
					excessive_force = stagger_strength - stagger_threshold_medium
					scale = excessive_force > 0 and excessive_force / stagger_resistance or 0
					impact_modifier = 0.5 + 0.5 * math.clamp(scale, 0, 1)
				elseif stagger_strength < stagger_threshold_explosion then
					stagger_type = stagger_types.heavy
					excessive_force = stagger_strength - stagger_threshold_heavy
					scale = excessive_force > 0 and excessive_force / stagger_resistance or 0
					impact_modifier = 0.5 + 0.5 * math.clamp(scale, 0, 1)
				elseif damage_profile.is_explosion then
					stagger_type = stagger_types.explosion
				elseif damage_profile.is_pull then
					stagger_type = stagger_types.pulling
				else
					stagger_type = stagger_types.heavy
				end

				if breed.stagger_duration_difficulty_mod then
					local stagger_duration_difficulty_table = breed.stagger_duration_difficulty_mod
					local breed_duration_modifier = stagger_duration_difficulty_table[difficulty_rank] or stagger_duration_difficulty_table[2] or 1

					duration = duration * breed_duration_modifier
				end

				local time_modifier = 0.75 + 0.25 * math.clamp(excessive_force / stagger_resistance, 0, 2)

				duration = duration * time_modifier
				distance = math.clamp(distance * impact_modifier, 0.5, 1)
			end
		end
	end

	if damage_profile.is_pull and stagger_type <= stagger_types.heavy then
		stagger_type = stagger_types.pulling
	end

	if attack_template.ranged_stagger then
		if stagger_type == stagger_types.weak then
			stagger_type = stagger_types.ranged_weak
		elseif stagger_type == stagger_types.medium then
			stagger_type = stagger_types.ranged_medium
		end
	end

	local stagger_value = attack_template and attack_template.stagger_value or 1

	optional_modifier_data.stagger_value = stagger_value

	local skip_block_stagger_override

	if breed.stagger_modifier_function then
		stagger_type, duration, distance, skip_block_stagger_override = breed.stagger_modifier_function(stagger_type, duration, distance, hit_zone_name, blackboard, breed, optional_modifier_data)
	end

	if blocked then
		if ai_shield_extension then
			ai_shield_extension.blocked_previous_attack = true
		end

		if stagger_type == stagger_types.none and not skip_block_stagger_override then
			stagger_type = stagger_types.weak
		elseif stagger_type == stagger_types.heavy and stagger_value == 1 then
			stagger_type = stagger_types.medium
		end
	end

	if breed.boss_staggers and (stagger_type < stagger_types.explosion or stagger_type == stagger_types.pulling) or breed.small_boss_staggers and stagger_type == stagger_types.pulling then
		stagger_type = stagger_types.none
	end

	local action = is_player and status_extension:breed_action() or blackboard.action
	local ignore_staggers = action and action.ignore_staggers

	if ignore_staggers and attacker_buff_extension and attacker_buff_extension:has_buff_type("push_increase") then
		ignore_staggers = false
	end

	if (not attack_template.always_stagger or breed.boss) and ignore_staggers and ignore_staggers[stagger_type] and (not ignore_staggers.allow_push or not attack_template or not attack_template.is_push) then
		return stagger_types.none, 0, 0, 0, 0
	end

	if breed.no_stagger_duration and not attack_template.always_stagger then
		duration = duration * 0.25
	end

	if attacker_buff_extension and attacker_buff_extension:has_buff_perk("explosive_stagger") then
		stagger_type = stagger_types.explosion
	end

	local stagger_duration_modifier = target_settings.stagger_duration_modifier or damage_profile.stagger_duration_modifier or DefaultStaggerDurationModifier
	local stagger_distance_modifier = target_settings.stagger_distance_modifier or damage_profile.stagger_distance_modifier or DefaultStaggerDistanceModifier
	local stagger_duration_table = breed.stagger_duration and breed.stagger_duration[stagger_type] or DefaultStaggerDuration

	duration = duration * stagger_duration_table * stagger_duration_modifier
	distance = distance * stagger_distance_modifier

	if target_buff_extension then
		distance = target_buff_extension:apply_buffs_to_value(distance, "stagger_distance")
	end

	if attacker_buff_extension then
		distance = attacker_buff_extension:apply_buffs_to_value(distance, "applied_stagger_distance")
	end

	if not breed.no_random_stagger_duration then
		duration = math.max(duration + math.random() * 0.25, 0)
	end

	if breed.max_stagger_duration then
		duration = math.min(duration, breed.max_stagger_duration)
	end

	if damage_profile.is_pull and target_unit then
		local target_position = POSITION_LOOKUP[target_unit] or Unit.world_position(target_unit, 0)
		local attacker_position = POSITION_LOOKUP[attacker_unit] or Unit.world_position(attacker_unit, 0)
		local closest_distance = Vector3.length(target_position - attacker_position) - 2.25

		distance = math.max(math.min(distance, closest_distance), 0)
	end

	if attacker_buff_extension then
		attacker_buff_extension:trigger_procs("stagger_calculation_ended", target_unit)
	end

	return stagger_type, duration, distance, stagger_value, stagger_strength
end

--Improve bot defense against multiple enemies & enemy types

local get_default_defense_data = function()
	local defense_data = {}
	defense_data.prox_enemies					= {}
	defense_data.num_prox_enemies				= 0
	defense_data.count = {}
	defense_data.count.trash					= 0
	defense_data.count.aoe_elite				= 0
	defense_data.count.berserker				= 0
	defense_data.count.boss						= 0
	defense_data.closest = {}
	defense_data.closest.aoe_elite				= nil
	defense_data.closest.trash					= nil
	defense_data.threat = {}
	defense_data.threat.running_attack			= false
	defense_data.threat.trash_attacking			= false
	defense_data.threat.trash_outside_push_range	= false
	defense_data.threat.trash_count				= 0
	defense_data.threat.berserker_attacking		= false
	defense_data.threat.aoe_elite				= false
	defense_data.threat.aoe_elite_in_push_range	= false
	defense_data.threat.aoe_elite_outside_push_range	= false
	defense_data.threat.boss					= false
	defense_data.stamina_left					= 0
	defense_data.dodge_count_left				= 0
	defense_data.dodge_reset_time				= 0
	defense_data.defend_token					= false
	defense_data.push_token						= false
	defense_data.dodge_token					= false
	defense_data.last_update					= 0
	defense_data.must_push_gutter				= false
	
	defense_data.is_boss_target					= false
	defense_data.followed_player_is_boss_target	= false
	
	defense_data.check_surrounded_timer			= 0
	defense_data.is_surrounded					= false
	
	return defense_data
end

local DEFAULT_DEFENSE_META_DATA = {
	push = "medium"
}

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

mod._is_attacking_me = function(self, self_unit, enemy_unit)
	local bb = BLACKBOARDS[enemy_unit]

	if not bb then
		return false
	end

	local enemy_buff_extension = ScriptUnit.has_extension(enemy_unit, "buff_system")

	if enemy_buff_extension and enemy_buff_extension:has_buff_perk("ai_unblockable") then
		return false
	end

	local action = bb.action
	local unblockable = action and action.unblockable

	return not unblockable and bb.attacking_target == self_unit and not bb.past_damage_in_attack
end

mod:hook_origin(BTBotMeleeAction, "_defend", function(self, unit, blackboard, target_unit, input_ext, t, in_melee_range)
	local defense_meta_data = blackboard.wielded_item_template.defense_meta_data or DEFAULT_DEFENSE_META_DATA
	local push_type = defense_meta_data.push

	local self_unit				= unit
	local self_owner			= Managers.player:unit_owner(self_unit)
	local prox_enemies			= mod.get_proximite_enemies(self_unit, 8)	--12	--10	--7		--5		--did the alive check already
	local num_enemies			= #prox_enemies
	local push_range_enemies			= mod.get_proximite_enemies(self_unit, 3, 3.8)	--3.5
	local num_push_range_enemies		= #push_range_enemies
	
	local status_extension = unit and ScriptUnit.has_extension(unit, "status_system")
	if not status_extension then return false end
	
	local current_fatigue, max_fatigue = status_extension:current_fatigue_points()
	
	-- local current_time = Managers.time:time("game")
	local current_time = t
	
	local defense_data = get_default_defense_data()
	defense_data.prox_enemies					= prox_enemies
	defense_data.num_prox_enemies					= num_enemies
	defense_data.stamina_left					= max_fatigue - current_fatigue
	defense_data.dodge_count_left				= status_extension.dodge_count - status_extension.dodge_cooldown
	defense_data.dodge_reset_time				= status_extension.dodge_cooldown_delay or current_time + 0.5
	defense_data.last_update					= current_time
	
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	local power_level = career_extension and career_extension:get_career_power_level() or 650
	
	local first_person_extension = blackboard.first_person_extension
	local current_rotation = first_person_extension:current_rotation()
	local current_forward = Quaternion.forward(current_rotation)
	
	local buff_extension = ScriptUnit.extension(self_unit, "buff_system")
	local push_action = blackboard.wielded_item_template.actions.action_one.push or blackboard.wielded_item_template.actions.action_two.push
	local push_half_angle = math.rad(buff_extension:apply_buffs_to_value(push_action.push_angle or 90, "block_angle") * 0.5)
	local outer_push_half_angle = math.rad(buff_extension:apply_buffs_to_value(push_action.outer_push_angle or 0, "block_angle") * 0.5)
	
	local inventory_ext = blackboard.inventory_extension
	local wielded_slot_name = inventory_ext.get_wielded_slot_name(inventory_ext)
	local slot_data = inventory_ext.get_slot_data(inventory_ext, wielded_slot_name)
	local item_data = slot_data.item_data
	local weapon_name = item_data.name
	
	-- initialize the attack awareness table is needed
	if not self_owner.bot_melee_defense_awareness then
		self_owner.bot_melee_defense_awareness = {}
		self_owner.bot_melee_defense_awareness.attacks = {}
		self_owner.bot_melee_defense_awareness.extend_block = {}
		self_owner.bot_melee_defense_awareness.time_last_cleaned = current_time
	end
	
	-- assign local to the awareness data for ease of access
	local awareness = self_owner.bot_melee_defense_awareness
	
	-- clean the awareness data if more than 5s since last cleaning
	if current_time - awareness.time_last_cleaned > 5 then
		for key, data in pairs(awareness.attacks) do
			if not mod.is_unit_alive(key) then
				awareness.attacks[key] = nil
				awareness.extend_block[key] = nil
			end
		end
		awareness.time_last_cleaned = current_time
	end
	
	--https://discord.com/channels/754313446660505600/918202960939479050/1032209605763276871
	-- local surrounded_check_angle = 160
	-- local surrounded_check_angle_radian = surrounded_check_angle * math.pi / 180
	
	local surrounded_check_angle_radian = math.pi
	local first_enemy_angle = nil
	local max_enemy_angle = -7	-- -math.pi * 2		-- Vernon: will be >= 0 when there is at least one enemy to check
	local min_enemy_angle = 7	-- math.pi * 2		-- Vernon: will be <= 0 when there is at least one enemy to check
	
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/03e04b0fc66e8d868a08201718aaa579a771f23d/scripts/entity_system/systems/ai/ai_player_slot_extension.lua#L448
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/03e04b0fc66e8d868a08201718aaa579a771f23d/scripts/entity_system/systems/ai/ai_player_slot_extension.lua#L521
	local slot_extension = ScriptUnit.extension(unit, "ai_slot_system")
	local slot_data_normal_type = slot_extension and slot_extension.all_slots and slot_extension.all_slots["normal"]
	local num_enabled_slots = (slot_data_normal_type and (slot_data_normal_type.total_slots_count - slot_data_normal_type.disabled_slots_count)) or 0
	
	local follow_unit = blackboard.ai_bot_group_extension.data.follow_unit
	local distance_sq_to_followed_target = (follow_unit and Vector3.distance_squared(POSITION_LOOKUP[self_unit], POSITION_LOOKUP[follow_unit])) or 0
	local check_being_surrounded = (defense_data.check_surrounded_timer < current_time) and (num_enabled_slots > 5) and (distance_sq_to_followed_target > 1)
	local check_being_surrounded_done = false
	
	if check_being_surrounded then
		defense_data.check_surrounded_timer = current_time + 0.15 + 0.05 * math.random()
	end
	
	for key, loop_unit in pairs(prox_enemies) do
		local loop_breed = Unit.get_data(loop_unit, "breed")
		local loop_bb = BLACKBOARDS[loop_unit]
		local loop_distance = Vector3.length(POSITION_LOOKUP[self_unit] - POSITION_LOOKUP[loop_unit])
		
		-- Vernon: check if the bot is surrounded by enemies
		if check_being_surrounded and not check_being_surrounded_done then
			local loop_offset_x = POSITION_LOOKUP[loop_unit].x - POSITION_LOOKUP[self_unit].x
			local loop_offset_y = POSITION_LOOKUP[loop_unit].y - POSITION_LOOKUP[self_unit].y
			local loop_angle = math.atan2(loop_offset_y, loop_offset_x)
			
			-- Vernon: make sure "angle 0" is in the interior of enemy cone
			if not first_enemy_angle then
				first_enemy_angle = loop_angle
			end
			loop_angle = loop_angle - first_enemy_angle
			
			if max_enemy_angle < loop_angle then
				max_enemy_angle = loop_angle
			end
			if loop_angle < min_enemy_angle then
				min_enemy_angle = loop_angle
			end
			if (min_enemy_angle <= max_enemy_angle) and (surrounded_check_angle_radian < max_enemy_angle - min_enemy_angle) then
				defense_data.is_surrounded = true
				
				check_being_surrounded_done = true
			end
		end
		
		if loop_bb then
			if mod.TRASH_UNITS_AND_SHIELD_SV[loop_breed.name] then	--single target attack, staggerable
				if mod._is_attacking_me(self_unit, loop_unit) then
					if loop_bb.moving_attack then		--running attack
						if not awareness.attacks[loop_unit] then
							awareness.attacks[loop_unit] = current_time
						elseif loop_distance < 4 and current_time - awareness.attacks[loop_unit] > AGGRESSIVE_MELEE_ALLOWANCE_RUNNING then
							defense_data.threat.running_attack = true
							defense_data.threat.trash_attacking = true
							defense_data.threat.trash_count = defense_data.threat.trash_count + 1
						end
					else		--standing attack / else
						if not awareness.attacks[loop_unit] then
							awareness.attacks[loop_unit] = current_time
						-- elseif current_time - awareness.attacks[loop_unit] > AGGRESSIVE_MELEE_ALLOWANCE_STANDING then
						elseif current_time - awareness.attacks[loop_unit] > AGGRESSIVE_MELEE_ALLOWANCE_STANDING and loop_distance < 5 then		--6
							defense_data.threat.trash_attacking = true
							defense_data.threat.trash_count = defense_data.threat.trash_count + 1
						end
					end
					
					--can refine push angle
					--should add a distance check for enemies in push range?
					local infront_of_self_unit, _ = mod.check_alignment_to_target(loop_unit, self_unit, 160)		--90
					-- if not infront_of_self_unit then
					if not infront_of_self_unit and loop_distance < 5 then
						defense_data.threat.trash_outside_push_range = true
					end
				else
					awareness.attacks[loop_unit] = nil
				end
				defense_data.count.trash = defense_data.count.trash + 1
			elseif loop_breed.name == "skaven_gutter_runner" then
				-- gutter on top of its target (= stabbing its target)
				if loop_bb.target_dist < 0.1 then
					local infront_of_self_unit, _ = mod.check_alignment_to_target(loop_unit, self_unit, 90)
					if loop_distance < 2.5 and infront_of_self_unit then
						defense_data.must_push_gutter = true
					end
				end
			elseif mod.BERSERKER_UNITS[loop_breed.name] then	--single target attack, not staggerable
				local can_stagger = false
				if push_action and current_forward then
					local attack_direction = Vector3.normalize(POSITION_LOOKUP[loop_unit] - POSITION_LOOKUP[self_unit])
					local attack_direction_flat = Vector3.flat(attack_direction)
					local dot = Vector3.dot(attack_direction_flat, current_forward)
					local angle_to_target = math.acos(dot)
					local inner_push = angle_to_target <= push_half_angle
					local outer_push = push_half_angle < angle_to_target and angle_to_target <= outer_push_half_angle
					
					local damage_profile_name = nil
					if inner_push then
						damage_profile_name = push_action.damage_profile_inner
					elseif outer_push then
						damage_profile_name = push_action.damage_profile_outer
					end
					
					local damage_profile = DamageProfileTemplates[damage_profile_name]
					
					if damage_profile then
						local stagger_type = do_stagger_calculation(stagger_table, breed, blackboard, attacker_unit, target_unit, hit_zone_name, original_power_level, boost_curve_multiplier, is_critical_strike, damage_profile, target_index, blocked, damage_source, range_scalar_multiplier, ai_shield_extension, difficulty_level, shield_user, has_power_boost, override_target_armor)
						can_stagger = stagger_type > stagger_types.none
					end
					--mod:echo(can_stagger)
				end
				
				-- if mod._is_attacking_me(self_unit, loop_unit) then
				if mod._is_attacking_me(self_unit, loop_unit) and loop_distance < 5 then	--7
					if loop_bb.moving_attack then
						defense_data.threat.running_attack = true
					end
					defense_data.threat.berserker_attacking = true
					defense_data.threat.can_stagger_berzerker = can_stagger
				end
				defense_data.count.berserker = defense_data.count.berserker + 1
			elseif mod.ELITE_UNITS_AOE[loop_breed.name] then		--aoe attack, need refinement for lords, staggerable by shields
				if loop_bb.attacking_target and not loop_bb.past_damage_in_attack then		--when elites are attacking someone (has attacking_target)
					--can refine the angle if we know hitbox and animation
					-- local infront_of_loop_unit, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, 160, 120)	--120, 120	--90, 120	
					-- if infront_of_loop_unit or (loop_distance < 3 and not flanking_loop_unit) then
						-- if loop_bb.moving_attack then		--running attack
							-- local aggressive_melee_allowance = AGGRESSIVE_MELEE_ALLOWANCE_RUNNING_ELITE
							
							-- if AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name] and loop_bb.action and AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name] and AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name].moving_attack then
								-- aggressive_melee_allowance = AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name].moving_attack
							-- end
							
							-- if not awareness.attacks[loop_unit] then
								-- awareness.attacks[loop_unit] = current_time
							-- elseif current_time - awareness.attacks[loop_unit] > aggressive_melee_allowance then
								-- defense_data.threat.running_attack = true
								-- defense_data.threat.aoe_elite = true
							-- end
						-- elseif loop_distance < 5 then		--4.5	--6	--5		-standing attack / else
							-- local aggressive_melee_allowance = AGGRESSIVE_MELEE_ALLOWANCE_STANDING_ELITE
							
							-- if AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name] and loop_bb.action and AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name] and AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name].default then
								-- aggressive_melee_allowance = AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name].default
							-- end
							
							-- if not awareness.attacks[loop_unit] then
								-- awareness.attacks[loop_unit] = current_time
							-- elseif current_time - awareness.attacks[loop_unit] > aggressive_melee_allowance then
								-- defense_data.threat.aoe_elite = true
							-- end
						-- end
					-- end
					
					local infront_of_loop_unit, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, 120, 120)	--160, 120	--120, 120	--90, 120
					if loop_bb.moving_attack then		--running attack
						local aggressive_melee_allowance = AGGRESSIVE_MELEE_ALLOWANCE_RUNNING_ELITE
						
						if AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name] and loop_bb.action and AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name] and AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name].moving_attack then
							aggressive_melee_allowance = AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name].moving_attack
						end
						
						if not awareness.attacks[loop_unit] then
							awareness.attacks[loop_unit] = loop_bb.mod_elite_aoe_start_t or current_time
						-- elseif current_time - awareness.attacks[loop_unit] > aggressive_melee_allowance and ((infront_of_loop_unit and loop_distance < 5) or (not flanking_loop_unit and loop_distance < 4)) then
						elseif current_time - awareness.attacks[loop_unit] > aggressive_melee_allowance and (infront_of_loop_unit and loop_distance < 5) then
							defense_data.threat.running_attack = true
							defense_data.threat.aoe_elite = true
						end
					else		--standing attack / else
						local aggressive_melee_allowance = AGGRESSIVE_MELEE_ALLOWANCE_STANDING_ELITE
						
						if AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name] and loop_bb.action and AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name] and AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name].default then
							aggressive_melee_allowance = AGGRESSIVE_MELEE_ALLOWANCE[loop_breed.name][loop_bb.action.name].default
						end
						
						if not awareness.attacks[loop_unit] then
							awareness.attacks[loop_unit] = loop_bb.mod_elite_aoe_start_t or current_time
						-- elseif current_time - awareness.attacks[loop_unit] > aggressive_melee_allowance and ((infront_of_loop_unit and loop_distance < 5) or (not flanking_loop_unit and loop_distance < 4)) then
						elseif current_time - awareness.attacks[loop_unit] > aggressive_melee_allowance and (infront_of_loop_unit and loop_distance < 5) then
							defense_data.threat.aoe_elite = true
						end
					end
					
					--can refine the angle if we know the push angle
					local infront_of_self_unit, _ = mod.check_alignment_to_target(loop_unit, self_unit, 90)
					-- if loop_distance < 2.7 and infront_of_self_unit then
					-- if loop_distance < 2.7 and infront_of_self_unit and not (loop_breed.name == "chaos_warrior" and loop_bb.action and loop_bb.action.name == "special_attack_cleave") then
					if loop_distance < 2.7 and infront_of_self_unit then
						-- if not (loop_breed.name == "chaos_warrior" and loop_bb.action and loop_bb.action.name == "special_attack_cleave") then
						if not (loop_breed.name == "chaos_warrior") then
							defense_data.threat.aoe_elite_in_push_range = true
						end
					-- else
					elseif loop_distance < 7 then
						defense_data.threat.aoe_elite_outside_push_range = true
					end
				else
					awareness.attacks[loop_unit] = nil
				end
				defense_data.count.aoe_elite = defense_data.count.aoe_elite + 1
			elseif mod.BOSS_UNITS[loop_breed.name] or mod.LORD_UNITS[loop_breed.name] then		--aoe attack, not staggerable, need refinement for lords (e.g. halescourge has no melee attack)
				-- if not ((loop_breed.name == "chaos_spawn" or loop_breed.name == "chaos_spawn_exalted_champion_norsca") and loop_bb.action and loop_bb.action.name == "tentacle_grab") then	--let bot threat handles chaos spawn grab attack because of delayed attack
					-- if loop_bb.attacking_target and not loop_bb.past_damage_in_attack then
						-- local infront_of_loop_unit, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, 160, 120)
						-- if infront_of_loop_unit or (loop_distance < 4 and not flanking_loop_unit) then
							-- defense_data.threat.boss = true
						-- end
					-- end
				-- end
				
				if loop_distance < 6 and loop_breed.name == "skaven_storm_vermin_warlord" then
					if loop_bb.action and (loop_bb.action.name == "special_attack_spin" or loop_bb.action.name == "defensive_mode_spin") then
						defense_data.threat.boss = true
					end
				end
				
				if loop_distance < 6 and (loop_breed.name == "chaos_exalted_champion_warcamp" or loop_breed.name == "chaos_exalted_champion_norsca") then
					if loop_bb.action and (loop_bb.action.name == "special_attack_aoe" or loop_bb.action.name == "special_attack_aoe_defensive" or loop_bb.action.name == "special_attack_retaliation_aoe") then
						defense_data.threat.boss = true
					end
				end
				
				if loop_distance < 6 and loop_breed.name == "skaven_stormfiend_boss" then
					if loop_bb.action and loop_bb.action.name == "special_attack_aoe" then
						defense_data.threat.boss = true
					end
				end
				
				--deal with some attacks that can deal damage after the attack has ended in the code
				if loop_breed.name == "chaos_spawn" or loop_breed.name == "chaos_spawn_exalted_champion_norsca" then
					if not awareness.extend_block[loop_unit] then
						if loop_bb.action and loop_bb.action.name == "combo_attack" then
							if loop_bb.attack and loop_bb.attack.attack_anim and loop_bb.attack.attack_anim[1] == "attack_melee_combo" then
								awareness.extend_block[loop_unit] = current_time + 1.7	--1.61
							elseif loop_bb.attack and loop_bb.attack.attack_anim and loop_bb.attack.attack_anim[1] == "attack_melee_combo_2" then
								awareness.extend_block[loop_unit] = current_time + 2	--1.95
							end
						elseif loop_bb.action and loop_bb.action.name == "melee_shove" then
							awareness.extend_block[loop_unit] = current_time + 1.35	--1.3
						end
					-- elseif current_time < awareness.extend_block[loop_unit] and (infront_of_loop_unit and loop_distance < 6) then
						-- defense_data.threat.boss = true
					elseif awareness.extend_block[loop_unit] <= current_time then
						awareness.extend_block[loop_unit] = nil
					end
				end
				if loop_breed.name == "beastmen_minotaur" then
					if not awareness.extend_block[loop_unit] then
						if loop_bb.action and loop_bb.action.name == "combo_attack" then
							awareness.extend_block[loop_unit] = current_time + 2.4	--2.33
						elseif loop_bb.action and loop_bb.action.name == "melee_shove" then
							awareness.extend_block[loop_unit] = current_time + 0.85	--0.81
						end
					-- elseif current_time < awareness.extend_block[loop_unit] and (infront_of_loop_unit and loop_distance < 6) then
						-- defense_data.threat.boss = true
					elseif awareness.extend_block[loop_unit] <= current_time then
						awareness.extend_block[loop_unit] = nil
					end
				end
				
				local extended_block = (awareness.extend_block[loop_unit] and current_time < awareness.extend_block[loop_unit]) or false
				
				if loop_bb.attacking_target and not loop_bb.past_damage_in_attack then
					if (loop_breed.name == "chaos_spawn" or loop_breed.name == "chaos_spawn_exalted_champion_norsca") and loop_bb.action and loop_bb.action.name == "tentacle_grab" then		--let bot threat handles chaos spawn grab attack because of delayed attack
						-- if not awareness.attacks[loop_unit] then
							-- awareness.attacks[loop_unit] = current_time
						-- elseif current_time - awareness.attacks[loop_unit] > 0.6 then	--from recording the attack starts about 1 second after attacking_target exists
							-- defense_data.threat.boss = true
						-- end
						
						---------------------------------------------
						
						-- mod:echo(loop_bb.action.name)
						
						-- local _, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, nil, 90)
						-- if loop_distance < 6.5 and not flanking_loop_unit then
							-- defense_data.threat.boss = true
						-- end
					elseif (loop_breed.name == "chaos_spawn" or loop_breed.name == "chaos_spawn_exalted_champion_norsca") and loop_bb.action and loop_bb.action.name == "attack_grabbed_chew" then	--not attacking nearby bots
					elseif loop_breed.name == "skaven_stormfiend" and loop_bb.action and loop_bb.action.name == "shoot" then	--no need to defend, also check PlayerBotInput._update_movement for the AoE detection
					elseif loop_breed.name == "chaos_troll" and loop_bb.action and loop_bb.action.name == "vomit" then		--no need to defend, also check PlayerBotInput._update_movement for the AoE detection
					-- elseif loop_breed.name == "skaven_storm_vermin_warlord" and loop_bb.action and loop_bb.action.name == "special_attack_spin" then		--all direction attack
					-- elseif loop_breed.name == "skaven_storm_vermin_warlord" and loop_bb.action and loop_bb.action.name == "defensive_mode_spin" then		--all direction attack
					else	--regular boss melee attacks
						local infront_of_loop_unit, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, 160, 120)
						local check_range = 5	--6
						
						-- if loop_breed.name == "chaos_exalted_sorcerer_drachenfels" and loop_bb.action and loop_bb.action.name == "swing_floating" then
							-- check_range = 6.5
						-- end
						
						-- if (loop_distance < check_range and infront_of_loop_unit) or (loop_distance < 3 and not flanking_loop_unit) then	--4.5	--4
						if loop_distance < check_range and infront_of_loop_unit then
							defense_data.threat.boss = true
						end
					end
				elseif extended_block then
					local infront_of_loop_unit, _ = mod.check_alignment_to_target(self_unit, loop_unit, 160, nil)
					if infront_of_loop_unit and loop_distance < 6 then
						defense_data.threat.boss = true
					end
				end
				
				--check this
				-- if (loop_breed.name == "chaos_spawn" or loop_breed.name == "chaos_spawn_exalted_champion_norsca") and loop_bb.action and loop_bb.action.name == "tentacle_grab" then
					-- local _, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, nil, 90)
					-- if loop_distance < 6.5 and not flanking_loop_unit then
						-- defense_data.threat.boss = true
					-- end
				-- end
			end
		end
	end
	
	if defense_data.check_surrounded_timer + 5 < current_time then
		defense_data.is_surrounded = false
	end
	
	defense_data.is_boss_target = false
	defense_data.followed_player_is_boss_target = false
	
	local alive_bosses = mod.get_spawned_bosses_and_lords()
	for _,loop_unit in pairs(alive_bosses) do
		local loop_bb = Unit.get_data(loop_unit, "blackboard")
		
		if loop_bb and loop_bb.target_unit == self_unit then
			defense_data.is_boss_target = true
		end
		
		if loop_bb and loop_bb.target_unit == follow_unit then
			defense_data.followed_player_is_boss_target = true
		end
	end
	
	--tweak for Zealot
	--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/95f497c2ad65b1a3454a2f9531dd868856ec7878/scripts/unit_extensions/default_player_unit/buffs/buff_function_templates.lua#L2378
	local zealot_no_defense = false
	local zealot_death_resist_active = false
	
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	
	if career_name == "wh_zealot" then
		local health_extension = self_unit and ScriptUnit.has_extension(self_unit, "health_system")
		local chunk_size = 25
		local damage_taken = health_extension and health_extension:get_damage_taken("uncursed_max_health")
		local uncursed_max_health = health_extension and health_extension:get_uncursed_max_health()
		local max_stacks = math.min(math.floor(uncursed_max_health / chunk_size) - 1, 6)
		local health_chunks = math.floor(damage_taken / chunk_size)
		local num_chunks = math.min(max_stacks, health_chunks)
		
		-- local talent_extension = self_unit and ScriptUnit.has_extension(self_unit, "talent_system")
		-- local resist_death_active = talent_extension and talent_extension:has_talent("victor_zealot_gain_invulnerability_on_lethal_damage_taken")
		
		local buff_extension = self_unit and ScriptUnit.has_extension(self_unit, "buff_system")
		zealot_death_resist_active = buff_extension and buff_extension:has_buff_type("victor_zealot_gain_invulnerability_on_lethal_damage_taken")
		
		if num_chunks < max_stacks and zealot_death_resist_active then
			zealot_no_defense = true
		end
	end
	
	self_owner.defense_data = defense_data
	
	--[[
	--note that vanilla bots can detect elite aoe attacks already, using the threat zone system
	if defense_data.must_push_gutter and defense_data.stamina_left >= 1 then
		self:_clear_pending_attack(blackboard)
		
		input_ext:melee_push()
		
		return true
	-- if defense_data.threat.boss or defense_data.threat.berserker_attacking then
	elseif defense_data.threat.boss or defense_data.threat.berserker_attacking then
		self:_clear_pending_attack(blackboard)
		
		input_ext:defend()
		if defense_data.dodge_count_left >= 0 then
			input_ext:dodge()
		end
		
		return true
	-- elseif defense_data.threat.aoe_elite_in_push_range and not defense_data.threat.aoe_elite_outside_push_range and not defense_data.threat.trash_outside_push_range and defense_data.stamina_left >= 1 and push_type == "heavy" then
	-- elseif defense_data.threat.aoe_elite_in_push_range and ((not defense_data.threat.aoe_elite_outside_push_range and not defense_data.threat.trash_outside_push_range) or num_push_range_enemies > 5) and defense_data.stamina_left >= 1 and push_type == "heavy" then
		--shield bots take risk to push if too many enemies are close
		-- self:_clear_pending_attack(blackboard)
		
		-- input_ext:melee_push()
		
		-- return true
	elseif zealot_no_defense then
		return false
	elseif defense_data.threat.aoe_elite then
		self:_clear_pending_attack(blackboard)
		
		input_ext:defend()
		if defense_data.dodge_count_left >= 0 then
			input_ext:dodge()
		end
		
		return true
	--no aoe elites, berserkers or bosses are attacking this bot from this point onward
	-- elseif zealot_no_defense then
		-- return true		--this stops zealot bot from attacking
	elseif defense_data.threat.trash_count > 1 and not defense_data.threat.trash_outside_push_range and defense_data.stamina_left >= 1 then
		--push for teammates as well? check newer versions of xq's bots
		--also shield bots should push elites
		self:_clear_pending_attack(blackboard)
		
		input_ext:melee_push()
		
		return true
	--let's hope the bot can dodge one trash attack
	elseif defense_data.threat.trash_attacking and defense_data.dodge_count_left >= 2 then
		input_ext:dodge()
		
		return false
	elseif defense_data.threat.trash_attacking and defense_data.stamina_left >= 1 then
		self:_clear_pending_attack(blackboard)
		
		input_ext:defend()
		
		return true
	end
	--if out of stamina, attack instead and hope for stamina regen or gaining hurt stamina
	
	-- blackboard.revive_with_urgent_target = not defense_data.threat.boss
	
	return false
	--]]
	
	local do_push = false
	local do_block = false
	local do_dodge = false
	local defending = false
	
	--note that vanilla bots can detect elite aoe attacks already, using the threat zone system
	if defense_data.must_push_gutter and defense_data.stamina_left >= 1 then
		do_push = true
	end
	
	if defense_data.threat.boss then
		do_block = true
		--test whether the vanilla threat box system is good enough
		-- if defense_data.dodge_count_left >= 0 then
			-- do_dodge = true
		-- end
	end
	
	-- if defense_data.is_surrounded then
		-- do_push = true
	-- end
	
	--handle zealot's special case
	if zealot_no_defense then
		if do_push or do_block then
			defending = true
			
			if do_push then
				self:_clear_pending_attack(blackboard)
				input_ext:melee_push()
				input_ext:defend()
			elseif do_block then
				self:_clear_pending_attack(blackboard)
				input_ext:defend()
			end
		end
		if do_dodge then
			input_ext:dodge()
		end
		
		return defending
	end
	
	-- if defense_data.threat.aoe_elite or defense_data.threat.berserker_attacking then
		-- do_block = true
		-- if defense_data.dodge_count_left >= 0 then
			-- do_dodge = true
		-- end
	-- end
	
	if defense_data.threat.berserker_attacking then
		if defense_data.threat.can_stagger_berzerker and defense_data.stamina_left >= 1 then
			do_push = true
		else
			do_block = true
			if defense_data.dodge_count_left >= 0 then
				do_dodge = true
			end
		end
	end
	
	if defense_data.threat.aoe_elite then
		do_block = true
		--test whether the vanilla threat box system is good enough
		-- if defense_data.dodge_count_left >= 0 then
			-- do_dodge = true
		-- end
	end
	
	if defense_data.threat.trash_attacking then
		if defense_data.dodge_count_left >= 2 then
			do_dodge = true
		else
			do_block = true
		end
		
		if defense_data.threat.trash_count > 3 then
			do_push = true
		end
		if defense_data.threat.trash_count > 2 then
			do_block = true
		end
	end
	
	if do_push or do_block then
		defending = true
		
		if do_push then
			self:_clear_pending_attack(blackboard)
			input_ext:melee_push()
			input_ext:defend()
		elseif do_block then
			self:_clear_pending_attack(blackboard)
			input_ext:defend()
		end
	end
	
	if do_dodge then
		input_ext:dodge()
	end
	
	return defending
end)

--let's see if this is related to engage position
mod:hook(BTBotMeleeAction, "_evaluation_timer", function(func, self, blackboard, t, timer_value)
	local self_unit 		= blackboard.unit
	local self_position		= POSITION_LOOKUP[self_unit]
	local follow_position	= nil
	local follow_unit		= nil
	if blackboard and blackboard.ai_bot_group_extension and blackboard.ai_bot_group_extension.data then
		follow_position	= blackboard.ai_bot_group_extension.data.follow_position
		follow_unit		= blackboard.ai_bot_group_extension.data.follow_unit
	end
	local distance_squared = 0
	if self_position and follow_position and follow_unit then
		distance_squared = Vector3.distance_squared(self_position, follow_position)
	end
	
	-- if timer_value < 4 then
	if timer_value < 4 or distance_squared > 49 then
		--looks like if the node is evaluated, bots will end the melee positioning and start the follow pathing, so this makes the bot move faster if too far from follow unit
		
		return func(self, blackboard, t, 1)
	end
	
	return func(self, blackboard, t, timer_value)
end)

-- mod:hook(BTBotMeleeAction, "_evaluation_timer", function(func, self, blackboard, t, timer_value)
	-- return func(self, blackboard, t, 1)
-- end)




--Make bot vent earlier, add area threat check, health check and enemy threat check; for full version refine enemy threat check
--now in reload_vent_tweaks.lua
--[[
mod:hook(BTConditions, "should_vent_overcharge", function(func, blackboard, args)
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	
	local original_start_min_percentage = args.start_min_percentage
	local original_stop_percentage = args.stop_percentage
	
	if career_name == "bw_scholar" or career_name == "bw_unchained" then
		args.start_min_percentage = 0.75
		args.stop_percentage = 0.55
	else
		args.start_min_percentage = 0.5		--0.2		--check if this interferes with shooting
		args.stop_percentage = 0.075		--0.05		--0.1
	end
	
	local ret = func(blackboard, args)
	
	args.start_min_percentage = original_start_min_percentage
	args.stop_percentage = original_stop_percentage
	
	local self_unit = blackboard.unit
	local health_extension	= ScriptUnit.has_extension(unit, "health_system")
	local current_hp		= health_extension and health_extension:current_health()
	
	local prox_enemies = mod.get_proximite_enemies(self_unit, 5)
	local num_enemies = #prox_enemies
	
	return ret and (not current_hp or (current_hp > 20)) and not is_unit_in_aoe_explosion_threat_area(self_unit) and (num_enemies < 1)
end)
--]]




--Allow bots to dodge backwards if they try to dodge while standing still

mod:hook(CharacterStateHelper, "check_to_start_dodge", function(func, unit, input_extension, status_extension, t)
	local unit_owner = Managers.player:unit_owner(unit)
	local is_bot = false
	if unit_owner and unit_owner.bot_player then
		is_bot = true
	end
	
	local toggle_stationary_dodge_save = false
	if is_bot then
		toggle_stationary_dodge_save = Application.user_setting("toggle_stationary_dodge")
		Application.set_user_setting("toggle_stationary_dodge", true)
	end
	
	local start_dodge, dodge_direction = func(unit, input_extension, status_extension, t)
	
	if is_bot then
		Application.set_user_setting("toggle_stationary_dodge", toggle_stationary_dodge_save)
	end
	
	return start_dodge, dodge_direction
end)




--melee range decides whether bots have melee weapons out

mod:hook_origin(BTConditions, "bot_in_melee_range", function(blackboard)
	local self_unit = blackboard.unit
	local self_owner = Managers.player:unit_owner(self_unit)
	
	local target_unit = blackboard.target_unit
	-- local self_pos = POSITION_LOOKUP[self_unit]
	-- local target_pos = POSITION_LOOKUP[target_unit]
	-- local distance_to_target = (target_pos and self_pos and Vector3.length(target_pos-self_pos)) or math.huge
	
	if not ALIVE[target_unit] then
		self_owner.last_melee_range_check = false
		return false
	end
	
	local breed = Unit.get_data(target_unit, "breed")
	
	if not breed then	--this includes halescourge / blood in the darkness / enchanter's lair boss swarm projectiles, use default function
		-- self_owner.last_melee_range_check = false
		-- return false
		
		local melee_range = 4	--3.5		--3
		local offset = POSITION_LOOKUP[target_unit] - POSITION_LOOKUP[self_unit]
		local distance_squared = Vector3.length_squared(offset)
		local in_range = distance_squared < melee_range^2
		-- local z_offset = offset.z
		-- local ret = in_range and z_offset > -1.5 and z_offset < 2
		local ret = in_range

		self_owner.last_melee_range_check = ret
		return ret
	end
	
	local breed_name = breed.name
	local inventory_extension = blackboard.inventory_extension
	local ranged_slot_data = inventory_extension:get_slot_data("slot_ranged")
	local ranged_slot_template = inventory_extension:get_item_template(ranged_slot_data)
	local ranged_slot_name = ranged_slot_template.name
	local ranged_slot_buff_type = ranged_slot_template and ranged_slot_template.buff_type
	local is_ranged = RangedBuffTypes[ranged_slot_buff_type]
	local effective_target = false

	if is_ranged then
		effective_target = AiUtils.has_breed_categories(breed.category_mask, ranged_slot_template.attack_meta_data.effective_against_combined)
	end
	
	--add exception for halescourge's vortex	--anim == "attack_staff"
	if breed_name == "chaos_exalted_sorcerer" then
		local breed_bb = target_unit and BLACKBOARDS[target_unit]
		local current_time = Managers.time:time("game")
		
		-- mod:echo("chaos_exalted_sorcerer")
		-- if breed_bb and breed_bb.action then
			-- mod:echo(breed_bb.action.name)
		-- end
		
		if (breed_bb and breed_bb.action and (breed_bb.action.name == "spawn_boss_vortex" or breed_bb.action.name == "spawn_flower_wave")) or
			(mod.last_halescourege_teleport_time and current_time < mod.last_halescourege_teleport_time + 3.5) then
			
			self_owner.last_melee_range_check = false
			return false
		end
	end
	
	if blackboard.melee_combat_preferred then
		return true
	end
	
	--TODO: check this and bt_bot_conditions.lua
	-- if (mod.stop_trash_shooting_ranged[ranged_slot_name] and mod.TRASH_UNITS[breed_name]) or not effective_target then
	-- if (mod.stop_trash_shooting_ranged[ranged_slot_name] and mod.TRASH_UNITS_EXCEPT_ARCHERS[breed_name]) or not effective_target then
		-- self_owner.last_melee_range_check = true
		-- return true
	-- end
	
	-- if the target is priority target (gutter / packmaster that has disabled an ally) then check line of sight
	if blackboard.priority_target_enemy == target_unit then
		-- check line of sight to priority target unit as that is not checked in target selection
		-- if priority target is not in line of sight then don't force bot the use ranged (melee out instead)
		local los = mod.check_line_of_sight(self_unit, target_unit)
		if not los then
			-- if there is no line of sight then the bot should pull out melee and chase the enemy
			self_owner.last_melee_range_check = true
			return true
		end
	end
	
	local breed_melee_range = {
		-- skaven_slave = true,
		-- skaven_clan_rat = true,
		-- skaven_clan_rat_with_shield = true,
		-- chaos_fanatic = true,
		-- chaos_marauder = true,
		-- chaos_marauder_with_shield = true,
		-- beastmen_gor = true,
		-- beastmen_ungor = true,
		-- beastmen_ungor_archer = true,
		-- skaven_storm_vermin = true,
		-- skaven_storm_vermin_commander = true,
		-- skaven_storm_vermin_with_shield = true,
		-- chaos_raider = true,
		-- chaos_warrior = true,
		-- beastmen_bestigor = true,
		-- beastmen_standard_bearer = true,
		-- skaven_plague_monk = true,
		-- chaos_berzerker = true,
		skaven_warpfire_thrower = 2,
		skaven_ratling_gunner = 2,
		skaven_pack_master = 6,	--1?	-- -1
		-- skaven_gutter_runner = true,
		-- skaven_poison_wind_globadier = true,
		-- chaos_vortex_sorcerer = true,
		-- chaos_corruptor_sorcerer = true,
		skaven_explosive_loot_rat = -1,
		-- curse_mutator_sorcerer = true,
		-- chaos_plague_sorcerer = true,
		-- chaos_plague_wave_spawner = true,
		-- chaos_tentacle_sorcerer = true,
		-- skaven_rat_ogre = true,
		-- skaven_stormfiend = true,
		-- chaos_troll = true,
		-- chaos_spawn = true,
		-- beastmen_minotaur = true,
		-- skaven_stormfiend_boss = true,
		-- skaven_storm_vermin_warlord = true,
		chaos_exalted_sorcerer = 5,		--6		--10	--20	--12
		-- chaos_exalted_champion_warcamp = true,
		-- chaos_exalted_champion_norsca = true,
		skaven_grey_seer = 5,	--12
		-- skaven_stormfiend_boss = true,
		chaos_exalted_sorcerer_drachenfels = 4,	--3		--12
		-- critter_rat = true,
		-- critter_pig = true,
		-- skaven_loot_rat = true,
	}
	
	local party_danger = AiUtils.get_party_danger()
	-- local melee_range = math.lerp(12, 5, party_danger)		--bot_settings.default.melee_range.default
	local melee_range = 5	--12

	--TODO: check this and bt_bot_conditions.lua
	--ranged weapon ammo check
	--[[
	local ammo = inventory_extension:ammo_percentage()
	local ammo_threshold = 0.5	--bot_settings.ammo_threshold.default
	local heat_threshold = 0.5	--bot_settings.heat_threshold.default
	if	blackboard.urgent_target_enemy		== target_unit or
		blackboard.opportunity_target_enemy	== target_unit or
		blackboard.priority_target_enemy	== target_unit then
		--
		ammo_threshold = 0		--bot_settings.ammo_threshold.special
		heat_threshold = 0.9	--bot_settings.heat_threshold.special
	end
	local ammo_ok = (not mod.heat_weapon[ranged_slot_name] and ammo > ammo_threshold) or (mod.heat_weapon[ranged_slot_name] and ammo > (1-heat_threshold))
	
	--check for moon bow
	if not ammo_ok then
		-- no ammo >> no ranged attacks
		-- EchoConsole("no ammo: " .. tostring(ammo) .. " | " .. tostring(has_heat_weapon))
		
		--check if target is Ratling or Fire Ratling
		if breed_name ~= "skaven_ratling_gunner" and breed_name ~= "skaven_warpfire_thrower" then
			self_owner.last_melee_range_check = true
			return true
		end
	end
	--]]
	
	-- if mod.TRASH_UNITS[breed_name] or mod.BERSERKER_UNITS[breed_name] then
	if mod.TRASH_UNITS[breed_name] then
		melee_range = 6		--3

		-- local follow_bb			= blackboard.follow
		-- local follow_position	= nil
		-- local follow_unit		= nil
		-- if blackboard and blackboard.ai_bot_group_extension and blackboard.ai_bot_group_extension.data then
			-- follow_position	= blackboard.ai_bot_group_extension.data.follow_position
			-- follow_unit		= blackboard.ai_bot_group_extension.data.follow_unit
		-- end
		
		-- local career_extension = blackboard.career_extension
		-- local career_name = career_extension:career_name()
	
	elseif mod.ELITE_UNITS[breed_name] or mod.BERSERKER_UNITS[breed_name] then
		melee_range = 6		--4
	elseif mod.SPECIAL_UNITS[breed_name] then
		melee_range = 2		--3
	elseif mod.BOSS_UNITS[breed_name] then
		melee_range = 6		--3		--make bots melee bosses
	elseif mod.LORD_UNITS[breed_name] then
		melee_range = 6		--3		--make bots melee bosses
	end
	
	if breed_melee_range[breed_name] then
		melee_range = breed_melee_range[breed_name]
	end
	
	-- local aoe_threat = true
	-- if self_owner.defense_data then
		-- if (not self_owner.defense_data.threat.boss) and (not self_owner.defense_data.threat.aoe_elite) then
			-- aoe_threat = false
		-- end
	-- end
	
	local aoe_threat = false
	if self_owner.defense_data then
		if self_owner.defense_data.threat.boss or self_owner.defense_data.threat.aoe_elite then
			aoe_threat = true
		end
	end
	
	
	if mod.TRASH_UNITS[breed_name] or mod.ELITE_UNITS[breed_name] or mod.BERSERKER_UNITS[breed_name] then
		--pull out melee weapons to defend sooner in case of aoe threat
		if aoe_threat then
			-- melee_range = 5	--TODO: check this
		end
	-- elseif mod.BOSS_UNITS[breed_name] or mod.LORD_UNITS[breed_name] then
	elseif mod.BOSS_UNITS[breed_name] then
		local flank_angle = (self_owner.last_melee_range_check and 90) or 120
		local in_front, flanking = mod.check_alignment_to_target(self_unit, target_unit, 90, flank_angle)
		-- if not flanking then
			-- melee_range = 6
		-- end
		if flanking then
			local career_extension = blackboard.career_extension
			local career_name = career_extension:career_name()
			
			if mod.monster_dps_ranged[ranged_slot_name] or
				(ranged_slot_name == "shortbow_hagbane_template_1" and career_name == "we_waywatcher") or
				(ranged_slot_name == "staff_spark_spear_template_1" and career_name == "bw_adept") then
				
				melee_range = 0
			end
		end
	end
	
	--add exception for halescourge's vortex	--anim == "attack_staff"
	-- if breed_name == "chaos_exalted_sorcerer" then
			-- local breed_bb = target_unit and BLACKBOARDS[target_unit]
			
			-- if breed_bb and breed_bb.action and breed_bb.action.name == "spawn_boss_vortex" then
				-- melee_range = 0
			-- end
		
		-- local breed_bb = target_unit and BLACKBOARDS[target_unit]
		-- local current_time = Managers.time:time("game")
		
		-- if (breed_bb and breed_bb.action and breed_bb.action.name == "spawn_boss_vortex") or (mod.last_halescourege_teleport_time and current_time < mod.last_halescourege_teleport_time + 3) then
			-- melee_range = 0
		-- end
	-- end
	
	--stickiness to melee when enemies got knocked back (conditions can be improved but generally only trash units get huge knockback)
	--also add some stickiness
	local wielded_slot = blackboard.inventory_extension:equipment().wielded_slot
	if mod.TRASH_UNITS[breed_name] and wielded_slot == "slot_melee" then
		-- melee_range = 5
		melee_range = math.max(melee_range, 6)
	elseif wielded_slot == "slot_melee" then
		melee_range = melee_range + 1
	end
	
	-- local check_range = math.min(melee_range, 3.5)
	
--[[
	local target_aim_position = nil
	local override_aim_node_name = breed.bot_melee_aim_node

	--Override for Chaos Warriors
	if breed_name == "chaos_warrior" then
		override_aim_node_name = "j_head"
	end
	
	--Override for Chaos Trolls
	if breed_name == "chaos_troll" then
		override_aim_node_name = "j_head"
	end
	
	--Override for Maulers
	if breed_name == "chaos_raider" then
		override_aim_node_name = "j_spine"
	end
	
	if override_aim_node_name then
		local override_aim_node = Unit.node(target_unit, override_aim_node_name)
		target_aim_position = Unit.world_position(target_unit, override_aim_node)
	else
		target_aim_position = POSITION_LOOKUP[target_unit]
	end
--]]
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	local aim_node = (breed and (breed.bot_melee_aim_node or "j_head")) or "rp_center"
	local target_aim_position = nil
	
	aim_node = modify_aim_node_melee(self_unit, target_unit, breed, aim_node, career_name)
	
	if aim_node then
		local override_aim_node = Unit.node(target_unit, aim_node)
		target_aim_position = Unit.world_position(target_unit, override_aim_node)
	else
		target_aim_position = POSITION_LOOKUP[target_unit]
	end
	
	if blackboard.ranged_combat_preferred then
		melee_range = 0
	end
	
	local offset = target_aim_position - POSITION_LOOKUP[self_unit]
	local z_offset = offset.z
	
	-- if z_offset < -1.5 or 2 < z_offset then
	if z_offset < -1.5 or 3.5 < z_offset then
		return false
	end
	
	local distance_squared = Vector3.length_squared(offset)
	-- local use_melee = distance_squared < check_range^2
	local use_melee = distance_squared < melee_range^2
	
	-- if self_owner.defense_data and self_owner.defense_data.threat.trash_attacking then
		-- use_melee = true
	-- end
	
	-- local prox_enemies = get_proximite_enemies(self_unit, check_range, 3)
	-- for _,loop_unit in pairs(prox_enemies) do
		-- local is_my_target = loop_unit == target_unit
		-- local is_boss = breed.boss
		-- local boss_threat = self_owner.defense_data and self_owner.defense_data.threat.boss
		
		-- if (is_my_target and is_boss) or boss_threat then
			-- use_melee = true
		-- end
	-- end
	
	-- TODO: needs work
	-- local prox_enemies = mod.get_proximite_enemies(self_unit, check_range, 3)
	-- local prox_enemy_count = 0
	-- for _,loop_unit in pairs(prox_enemies) do
		-- if not use_melee then
			-- local loop_pos = POSITION_LOOKUP[loop_unit]
			-- local loop_offset = self_pos and loop_pos and self_pos - loop_pos
			-- if loop_offset and math.abs(loop_offset.z) < 3 then
				-- use_melee = true
			-- end
		-- end
		
		-- local is_my_target = loop_unit == target_unit
		-- local is_boss = breed.boss
		-- local boss_threat = self_owner.defense_data and self_owner.defense_data.threat.boss
		
		-- if not (loop_unit == target_unit and (breed.boss or breed.special)) then
			-- prox_enemy_count = prox_enemy_count+1
		-- end
		
		-- if (is_my_target and is_boss) or boss_threat then
			-- use_melee = true
		-- end
	-- end
	
	--meh, i will just copy the whole _defend function for now
	local prox_enemies = mod.get_proximite_enemies(self_unit, 8, 3.8)	--7, 3.8	--7, 3
	for key, loop_unit in pairs(prox_enemies) do
		local loop_breed = Unit.get_data(loop_unit, "breed")
		local loop_bb = BLACKBOARDS[loop_unit]
		local loop_distance = Vector3.length(POSITION_LOOKUP[self_unit] - POSITION_LOOKUP[loop_unit])
		
		if loop_bb then
			-- if mod.TRASH_UNITS[loop_breed.name] or mod.BERSERKER_UNITS[loop_breed.name] then
			if mod.BERSERKER_UNITS[loop_breed.name] then
				-- if loop_bb.attacking_target == self_unit and not loop_bb.past_damage_in_attack then
				if loop_bb.attacking_target == self_unit and not loop_bb.past_damage_in_attack and loop_distance < 4.5 then
					use_melee = true
				end
			elseif mod.ELITE_UNITS_AOE[loop_breed.name] then
				if loop_bb.attacking_target and not loop_bb.past_damage_in_attack then
					--can refine the angle if we know hitbox and animation
					local infront_of_loop_unit, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, 160, 120)	--160, 120	--120, 120	--90, 120
					if infront_of_loop_unit or (loop_distance < 3 and not flanking_loop_unit) then
						if loop_bb.moving_attack then
							-- aoe_threat = true
						elseif loop_distance < 5 then	--6	--5
							aoe_threat = true
						end
					end
				end
			elseif mod.BOSS_UNITS[loop_breed.name] or mod.LORD_UNITS[loop_breed.name] then
				--TODO: change this after fixing _defend for bosses
				if loop_bb.attacking_target and not loop_bb.past_damage_in_attack then
					local infront_of_loop_unit, flanking_loop_unit = mod.check_alignment_to_target(self_unit, loop_unit, 160, 120)
					-- if infront_of_loop_unit or (loop_distance < 4.5 and not flanking_loop_unit) then	--4
					if infront_of_loop_unit and loop_distance < 4.5 then
						-- aoe_threat = true
					end
				end
			end
		end
	end
	
	local ret = use_melee or aoe_threat
	-- local ret = use_melee or aoe_threat or (prox_enemy_count > 0)
	self_owner.last_melee_range_check = ret
	
	return ret
end)



-- Vernon: Let bots dodge while drinking draught
mod:hook(BTBotHealAction, "run", function(func, self, unit, blackboard, t, dt)
	local ret = func(self, unit, blackboard, t, dt)

	--Vernon: Let bots dodge while using ranged weapons (3rd copy...)
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
	
	return ret
end)

-- Vernon: Let bots dodge while reloading
mod:hook(BTBotReloadAction, "run", function(func, self, unit, blackboard, t, dt)
	local ret1, ret2 = func(self, unit, blackboard, t, dt)
	
	--Vernon: Let bots dodge while using ranged weapons (3rd copy...)
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

	return ret1, ret2
end)




--Maximum distance doubled and added line of sight check
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blame/b38754a3bd61983118215359845d5b4fe5005014/scripts/entity_system/systems/behaviour/nodes/bot/bt_bot_conditions.lua#L738
mod:hook_origin(BTConditions, "has_priority_or_opportunity_target", function(blackboard)
	-- local self_unit		= blackboard.unit
	-- local self_owner	= Managers.player:unit_owner(self_unit)
	-- local d				= get_d_data(self_unit)
	
	-- if not d then
		-- return func(blackboard)
	-- end
	
	-- local target = d.melee.target_unit

	-- if not ALIVE[target] then
		-- return false
	-- end

	-- local distance_ok		= d.melee.target_distance < 80
	-- local has_line_of_sight	= d.melee.has_line_of_sight
	-- local result = (target == blackboard.priority_target_enemy or target == blackboard.urgent_target_enemy or target == blackboard.opportunity_target_enemy) and distance_ok and has_line_of_sight

	-- return result
	
	local target = blackboard.target_unit

	if not ALIVE[target] then
		return false
	end

	local dist = 80		--40
	local has_line_of_sight	= mod.check_line_of_sight(blackboard.unit, target)
	
	local inventory_extension = blackboard.inventory_extension
	local ranged_slot_data = inventory_extension:get_slot_data("slot_ranged")
	local ranged_slot_template = inventory_extension:get_item_template(ranged_slot_data)
	local ranged_slot_name = ranged_slot_template.name
	local charge_ranged_before_line_of_sight = mod.pre_charge_ranged[ranged_slot_name]
	
	local result = (target == blackboard.priority_target_enemy and blackboard.priority_target_distance < dist) or
					-- (target == blackboard.urgent_target_enemy and blackboard.urgent_target_distance < dist) or
					(not blackboard.revive_with_urgent_target and target == blackboard.urgent_target_enemy and blackboard.urgent_target_distance < dist) or
					(target == blackboard.opportunity_target_enemy and blackboard.opportunity_target_distance < dist)

	-- return result
	-- return result and has_line_of_sight
	return result and (has_line_of_sight or charge_ranged_before_line_of_sight)
end)



-- Xq: Print out info text when a bot gets a guard break
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/29a60871b08662e2ff66bd09c3d6642c276ca330/scripts/entity_system/systems/ai/ai_bot_group_system.lua#L2794
mod:hook(GenericStatusExtension, "set_block_broken", function(func, self, block_broken, t, ...)
	if mod.components.bot_info_guard_break.value ~= mod.guard_break_settings.none then 
		local unit = self.unit
		local owner = unit and Managers.player:unit_owner(unit)
		
		if owner and owner.bot_player and block_broken then
			-- local bot_name = owner.character_name
			-- local message_string = tostring(bot_name) .. ": guard break"
			-- local message_string = "guard broken"
			
			local message_string = mod:localize("bot_info_guard_break_msg")
			local localize = false		--true
			local localize_parameters = true
			local localization_parameters = FrameTable.alloc_table()
			
			-- if mod.components.bot_info_guard_break.value == mod.guard_break_settings.global then
			if mod.components.bot_info_guard_break.value then
				local channel_id = 1
				local message_target = nil
				
				local mechanism = Managers.mechanism:game_mechanism()

				if mechanism.get_chat_channel then
					local local_player = Managers.player:local_player()
					channel_id, message_target = mechanism:get_chat_channel(owner, false)
				end
				
				Managers.chat:send_chat_message(channel_id, owner:local_player_id(), message_string, localize, localization_parameters, localize_parameters, nil, message_target)
			-- elseif mod.components.bot_info_guard_break.value == mod.guard_break_settings.host then
				-- mod:echo(message_string)	--Irc.PRIVATE_MSG
			end
		end
	end
	
	func(self, block_broken, t, ...)
end)




--TODO: add push attack input
PlayerBotInput.melee_push_attack = function (self)
	self._melee_push_attack = true
end

--[[
mod:hook(PlayerBotInput, "_update_actions", function(func, self)
	local input = self._input
	
	if self._melee_push_attack then
		self._melee_push_attack = false

		if self._push_attack_defend_held then
			input.action_one = true
			input.action_one_hold = true
		else
			self._push_attack_defend_held = true
			self.push_attack_time = t
		
			input.action_two = true
		end

		input.action_two_hold = true
	elseif self._push_attack_defend_held and self.push_attack_time and self.push_attack_time + 0.65 < t then	--i think longest time in chain action is 0.2 push + 0.4 push attack
		self._push_attack_defend_held = false
		self.push_attack_time = nil
		
		input.action_one_release = true
		input.action_two_release = true
	end

	func(self)

	-- local input = self._input

	-- if self._fire_hold then
		-- self._fire_hold = false
		-- input.action_one_hold = true

		-- if not self._fire_held then
			-- input.action_one = true
			-- self._fire_held = true
		-- end
	-- elseif self._fire_held then
		-- self._fire_held = false
		-- input.action_one_release = true
	-- elseif self._fire then
		-- self._fire = false
		-- input.action_one = true
	-- end

	-- if self._melee_push then
		-- self._melee_push = false
		-- self._defend = false

		-- if self._defend_held then
			-- input.action_one = true
		-- else
			-- self._defend_held = true
			-- input.action_two = true
		-- end

		-- input.action_two_hold = true
	-- elseif self._defend then
		-- self._defend = false

		-- if not self._defend_held then
			-- self._defend_held = true
			-- input.action_two = true
		-- end

		-- input.action_two_hold = true
	-- elseif self._defend_held then
		-- self._defend_held = false
		-- input.action_two_release = true
	-- end

	-- if self._cancel_held_ability then
		-- self._cancel_held_ability = false
		-- self._activate_ability = false
		-- self._activate_ability_held = false
		-- input.action_two = true
	-- end

	-- if self._activate_ability then
		-- self._activate_ability = false

		-- if not self._activate_ability_held then
			-- self._activate_ability_held = true
			-- input.action_career = true
		-- end

		-- input.action_career_hold = true
	-- elseif self._activate_ability_held then
		-- self._activate_ability_held = false
		-- input.action_career_release = true
	-- end

	-- if self._weapon_reload then
		-- self._weapon_reload = false
		-- input.weapon_reload = true
		-- input.weapon_reload_hold = true
	-- end

	-- if self._hold_attack then
		-- input.action_one = true
		-- input.action_one_hold = true
		-- self._hold_attack = false
		-- self._attack_held = true
	-- elseif self._attack_held then
		-- self._attack_held = false
		-- input.action_one_release = true
	-- elseif not self._tap_attack_released then
		-- self._tap_attack_released = true
		-- input.action_one_release = true
	-- elseif self._tap_attack then
		-- self._tap_attack_released = false
		-- self._tap_attack = false
		-- input.action_one = true
	-- end

	-- if self._charge_shot then
		-- self._charge_shot = false
		-- input.action_two_hold = true

		-- if not self._charge_shot_held then
			-- input.action_two = true
			-- self._charge_shot_held = true
		-- end
	-- elseif self._charge_shot_held then
		-- self._charge_shot_held = false
		-- input.action_two_release = true
	-- end

	-- if self._interact then
		-- self._interact = false

		-- if not self._interact_held then
			-- self._interact_held = true
			-- input.interact = true
		-- end

		-- input.interacting = true
	-- elseif self._interact_held then
		-- self._interact_held = false
	-- end

	-- local slot_to_wield = self._slot_to_wield

	-- if slot_to_wield then
		-- self._slot_to_wield = nil
		-- local slots = InventorySettings.slots
		-- local num_slots = #slots
		-- local wield_input = nil

		-- for i = 1, num_slots, 1 do
			-- local slot_data = slots[i]

			-- if slot_data.name == slot_to_wield then
				-- wield_input = slot_data.wield_input
			-- end
		-- end

		-- input[wield_input] = true
	-- end

	-- if self._dodge then
		-- input.dodge = true
		-- input.dodge_hold = true
		-- self._dodge = false
	-- end
end)
--]]

--[[
mod:hook_origin(PlayerBotInput, "update", function(self, unit, input, dt, context, t)
	table.clear(self._input)
	
	local self_unit = unit
	local blackboard = BLACKBOARDS[self_unit]
	local shoot_blackboard = blackboard.shoot
	local fire_shot_token = (shoot_blackboard and shoot_blackboard.fire_shot_token) or false
	
	if fire_shot_token then
		-- blackboard.shoot.fire_shot_token = false
		
		-- blackboard.shoot.charging_shot = false
		-- blackboard.shoot.charge_start_time = nil
		-- blackboard.shoot.fired = true
		
		-- self._fire = true
		
		shoot_blackboard.fire_shot_token = false
		
		shoot_blackboard.fired = true
		shoot_blackboard.stop_fire_t = t + shoot_blackboard.stop_fire_delay

		if shoot_blackboard.fire_input and shoot_blackboard.fire_input ~= "none" then
			local input = shoot_blackboard.fire_input

			self[input](self)
		end

		if shoot_blackboard.charge_shot_delay then
			shoot_blackboard.next_charge_shot_t = t + shoot_blackboard.charge_shot_delay
		end
	end
	
	self:_update_movement(dt, t)
	self:_update_actions()
end)
--]]




--Better path learning & Improved bot responsiveness when it comes to following human players

local transition_init_extra = {
	unit	= false,
	to		= false,
	
	_valid	= false,
	validate = function(self)
		self._valid = true
	end,
	invalidate = function(self)
		self._valid = false
	end,
	is_valid = function(self)
		return self._valid
	end,
}

local pending_timeout		= 1.5
local pending_transitions	= {}
local force_move_target_update =

mod:hook(PlayerWhereaboutsExtension, "_check_bot_nav_transition", function(func, self, nav_world, input, current_position)
	
	-- clean invalid pending transitions
	local t = Managers.time:time("game")
	for unit, stored_transition in pairs(pending_transitions) do
		if not Unit.alive(unit) or t > stored_transition.expires or t-stored_transition.expires < -pending_timeout then
			-- if the pending transition in no longer valid >> delete it
			-- EchoConsole("deleted invalid pending transition")
			pending_transitions[unit] = nil
		end
	end
	
	local stored_transition = pending_transitions[self.unit]
	if stored_transition then
		-- if there is a pending transition for this "teacher" unit..
			
		-- check if current position is now on navmesh
		local found_nav_mesh, _ = GwNavQueries.triangle_from_position(stored_transition.nav_world, current_position, 0.1, 0.3, stored_transition.traverse_logic)
		
		if found_nav_mesh then
			-- the "teacher" is now on navmesh >> try to create the transition now and remove the pending transition
			-- check that we won't be creating a huge drop here
			local from = stored_transition.from:unbox()
			local via = stored_transition.via:unbox()
			local to = current_position
			-- local transition_drop = to.z - from.z
			-- if transition_drop < -6.5 then
				Managers.state.bot_nav_transition:create_transition(from, via, to, stored_transition.player_jumped)
				-- EchoConsole("resolved pending transition")
			-- else
				-- EchoConsole("too long drop")
			-- end
			pending_transitions[self.unit] = nil
		end
	end
	
	transition_init_extra.unit = self.unit
	transition_init_extra.to = current_position
	transition_init_extra:validate()
	func(self, nav_world, input, current_position)
end)

local new_transition_time = 0

mod:hook(BotNavTransitionManager, "create_transition", function(func, self, from, via, wanted_to, player_jumped, make_permanent, drawer)
	local transition_drop = wanted_to.z - from.z
	-- if transition_drop < -6.5 then
		-- EchoConsole("too long drop, stopped creating transition")
		-- return false
	-- end
	
	local success = false
	local transition_unit = nil
	local current_time = Managers.time:time("game")
	
	local nav_world = self._nav_world
	-- local found_nav_mesh, _ = GwNavQueries.triangle_from_position(nav_world, wanted_to, 0.1, 0.3, self._layerless_traverse_logic)
	local found_nav_mesh, _ = GwNavQueries.triangle_from_position(nav_world, wanted_to, 0.3, 0.3, self._layerless_traverse_logic)
	if not found_nav_mesh and transition_init_extra:is_valid() and wanted_to == transition_init_extra.to then
		pending_transitions[transition_init_extra.unit] =
		{
			from = Vector3Box(from),
			via = Vector3Box(via),
			player_jumped = player_jumped,
			make_permanent = make_permanent,
			nav_world = nav_world,
			traverse_logic = self._layerless_traverse_logic,
			
			expires = current_time + pending_timeout,
		}
		transition_init_extra:invalidate()
		-- EchoConsole("created new pending transition")
	end
	
	success, transition_unit = func(self, from, via, wanted_to, player_jumped, make_permanent, drawer)
	if success then
		new_transition_time = current_time
	end
	return success, transition_unit
end)

--now in player_bot_base.lua
--[[
mod:hook(PlayerBotBase, "_update_movement_target", function(func, self, dt, t)
	func(self, dt, t)
	
	local self_unit			= self._unit
	local self_pos			= POSITION_LOOKUP[self_unit]
	local blackboard		= self._blackboard
	local follow_bb			= blackboard.follow
	-- local target_pos		= follow_bb.target_position:unbox()
	local follow_position	= nil
	local follow_unit		= nil
	if blackboard and blackboard.ai_bot_group_extension and blackboard.ai_bot_group_extension.data then
		follow_position	= blackboard.ai_bot_group_extension.data.follow_position
		follow_unit		= blackboard.ai_bot_group_extension.data.follow_unit
	end
	-- if self_pos and target_pos and follow_position then
	local navigation_extension = blackboard.navigation_extension
	if self_pos and follow_position and follow_unit and navigation_extension then
		local max_follow_timer	= math.huge
		local follow_distance	= Vector3.distance(follow_position, self_pos)
		local close_to_follow	= follow_distance < 4
		if t - new_transition_time < 0.5 then
			max_follow_timer	= 0.15
			-- EchoConsole("Newly created transition >> follow timer max = 0.15s")
		elseif (close_to_follow or navigation_extension:destination_reached()) then
			max_follow_timer	= 0.333
			-- EchoConsole("Close to follow pos >> follow timer max = 0.333s")
		end
		
		if follow_bb.follow_timer > max_follow_timer then
			follow_bb.follow_timer = max_follow_timer
		end
		
	end
end)
--]]

mod:hook(PlayerBotNavigation, "_goal_reached", function(func, self, position, goal, previous_goal, t)
	local goal_reached	= func(self, position, goal, previous_goal, t)
	
	if position and goal and previous_goal then
		local path_segment	= goal - previous_goal
		local pos_to_goal	= goal - position
		if Vector3.length(path_segment) > 0.01 and Vector3.length(pos_to_goal) > 0.01 then
			local path_segment_unit	= Vector3.normalize(path_segment)
			local pos_to_goal_unit	= Vector3.normalize(pos_to_goal)
			
			local goal_distance_flat = Vector3.length(Vector3.flat(pos_to_goal))
			local goal_cos = Vector3.dot(path_segment_unit, pos_to_goal_unit)	-- 1 = straight ahead, -1 = directly behind
			
			if goal_cos < 0.174 or goal_distance_flat < 0.2 then	-- check for ~80deg angle, original checks for 90deg angle, also 0.2 is sufficient for positional accuracy
				self._close_to_goal_time	= nil
				goal_reached				= true
			end
		end
	end
	
	return goal_reached
end)




--Force bots to jump if they are too far away for more than 2 seconds without moving or attacking (looks like this is in PlayerBotInput._obstacle_check already)
--[[
mod:hook(BTBotFollowAction, "run", function(func, self, unit, blackboard, t, dt)
	local bot	= Managers.player:unit_owner(unit)
	
	local running, evaluate = func(self, unit, blackboard, t, dt)
	
	local follow_pos	= nil
	local follow_unit		= nil
	if blackboard and blackboard.ai_bot_group_extension and blackboard.ai_bot_group_extension.data then
		follow_pos		= blackboard.ai_bot_group_extension.data.follow_position
		follow_unit		= blackboard.ai_bot_group_extension.data.follow_unit
	end
	
	if follow_unit and follow_pos and bot.bot_player then
		local self_pos					= POSITION_LOOKUP[unit]
		local distance_to_follow_unit	= Vector3.length(follow_pos - self_pos)
		
		if distance_to_follow_unit > 7 then		-- d.regroup.distance_threshold
			local time_passed = t - d.unstuck_data.last_update
			local old_pos = d.unstuck_data.last_position:unbox()
			local distance_travelled = Vector3.length(old_pos-self_pos)
			if time_passed > 2 then
				if distance_travelled < 1.333 then
					if t - d.unstuck_data.last_attack > 2 then
						-- jump only if the bot is not actively attacking
						-- d.token.jump = true
						
						self._input.jump = true
					end
					d.unstuck_data.is_stuck		= true
					--
				else
					d.unstuck_data.is_stuck		= false
				end
				d.unstuck_data.last_update		= t
				d.unstuck_data.last_position	= Vector3Box(d.position)
			end
		else
			d.unstuck_data.is_stuck			= false
			d.unstuck_data.last_position	= Vector3Box(d.position)
			d.unstuck_data.last_update		= t
		end
	end
	
	return running, evaluate
end)
--]]





-- Improve the bots' willingness to use ranged weapons (WIP)
--search "has_target_and_ammo_greater_than" below
local is_secondary_within_cone = function(self_unit, target_unit, secondary_unit, cone_angle_deg)	-- check if a secondary target unit is within the specified cone centered to the line from self to target
	local ret = false
	if Unit.alive(self_unit) and Unit.alive(target_unit) and Unit.alive(secondary_unit) then
		local self_pos = POSITION_LOOKUP[self_unit]
		local target_pos = POSITION_LOOKUP[target_unit]
		local secondary_pos = POSITION_LOOKUP[secondary_unit]
		local target_vector = target_pos - self_pos
		local secondary_vector = secondary_pos - self_pos
		
		if Vector3.length(target_vector) > 0 and Vector3.length(secondary_vector) > 0 then
			-- essentially, calculate the dot product of normalized self-target, self-secondary vectors = cosine of the angle between those two vectors
			local secondary_deviation_angle_cos = Vector3.dot(Vector3.normalize(target_vector), Vector3.normalize(secondary_vector))
			-- then get the actual angle from the cosine and convert it into degrees
			local secondary_deviation_angle_deg = (math.acos(secondary_deviation_angle_cos) / math.pi) * 180
			
			-- "cone_angle_deg/2" because secondary_deviation_angle_deg equals half of the opening angle of the cone inside which the secondary currently is
			if secondary_deviation_angle_deg <= (cone_angle_deg/2) then
				ret = true
			end
		end
	end
	
	return ret
end

--[[
mod:hook_origin(BTConditions, "has_target_and_ammo_greater_than", function(blackboard, args)
	local target_unit = blackboard.target_unit

	if not ALIVE[target_unit] then
		return false
	end

	local breed = Unit.get_data(target_unit, "breed")

	if breed == nil then
		return false
	end

	local inventory_extension = blackboard.inventory_extension
	local ranged_slot_data = inventory_extension:get_slot_data("slot_ranged")
	local ranged_slot_template = inventory_extension:get_item_template(ranged_slot_data)
	local ranged_slot_buff_type = ranged_slot_template and ranged_slot_template.buff_type
	local is_ranged = RangedBuffTypes[ranged_slot_buff_type]

	if not is_ranged then
		return false
	end

	local target_buff_extension = ScriptUnit.has_extension(target_unit, "buff_system")

	if target_buff_extension and target_buff_extension:has_buff_perk("invulnerable_ranged") then
		return false
	end
	
	local current, max = inventory_extension:current_ammo_status("slot_ranged")
	local ammo_ok = not current or args.ammo_percentage < current / max
	local overcharge_extension = blackboard.overcharge_extension
	local overcharge_limit_type = args.overcharge_limit_type
	local current_oc, threshold_oc, max_oc = overcharge_extension:current_overcharge_status()
	local overcharge_ok = current_oc == 0 or (overcharge_limit_type == "threshold" and current_oc / threshold_oc < args.overcharge_limit) or (overcharge_limit_type == "maximum" and current_oc / max_oc < args.overcharge_limit)
	local obstruction = blackboard.ranged_obstruction_by_static
	local t = Managers.time:time("game")
	local obstructed = obstruction and obstruction.unit == blackboard.target_unit and t <= obstruction.timer + 0.2	--0.5	--1	--3
	local effective_target = AiUtils.has_breed_categories(breed.category_mask, ranged_slot_template.attack_meta_data.effective_against_combined)
	
	local ret = ammo_ok and overcharge_ok and not obstructed and effective_target
	local patrol_in_firing_cone = false
		
	if ret then
		-- check that there is no patrol rats marching on the background
		
		local ai_group_system = Managers.state.entity:system("ai_group_system")
		local self_unit = blackboard.unit
		local self_pos = POSITION_LOOKUP[self_unit]
		
		if ai_group_system.groups_to_update then
			for id, group in pairs(ai_group_system.groups_to_update) do
				if group.group_type == "spline_patrol" and group.members then
					for patrol_unit, extension in pairs(group.members) do
						local patrol_blackboard	= patrol_unit and BLACKBOARDS[patrol_unit]
						local patrol_target		= patrol_blackboard and patrol_blackboard.target_unit
						local patrol_pos		= POSITION_LOOKUP[patrol_unit]
						local patrol_dist		= self_pos and patrol_pos and Vector3.length(patrol_pos - self_pos)
						-- local patrol_has_target	= patrol_target and Unit.alive(patrol_target)
						local patrol_has_target	= patrol_target and mod.is_unit_alive(patrol_target)
						
						if patrol_dist and patrol_dist < 60 and is_secondary_within_cone(self_unit, target_unit, patrol_unit, 20) and not patrol_has_target then
							patrol_in_firing_cone = true
						end
					end
				end
			end
		end
	end

	return ret and not patrol_in_firing_cone
end)
--]]




--Increase bot teleport tendency

local FOLLOW_TELEPORT_DISTANCE_SQ = 1600	--1225	--900	--625	--1600		--reduce out of range distance from 40 to 25
local FOLLOW_TELEPORT_DISTANCE_SQ_REDUCED = 625		--400	--625	--225

mod:hook_origin(BTConditions, "should_teleport", function(blackboard)
	local follow_unit = blackboard.ai_bot_group_extension.data.follow_unit

	if not ALIVE[follow_unit] or blackboard.has_teleported then
		return false
	end

	local self_unit = blackboard.unit
	local level_settings = LevelHelper:current_level_settings()
	local disable_bot_main_path_teleport_check = level_settings.disable_bot_main_path_teleport_check

	-- if not disable_bot_main_path_teleport_check then
		-- local conflict_director = Managers.state.conflict
		-- local self_segment = conflict_director:get_player_unit_segment(self_unit) or 1
		-- local target_segment = conflict_director:get_player_unit_segment(follow_unit)
		
		-- if not target_segment or target_segment < self_segment then
		-- if not target_segment or (target_segment+1) < self_segment then				-- allowance increased here to allow the bots to teleport to the same sector where they currently are instead of only forward
			-- return false
		-- end
	-- end

	local has_priority_target = blackboard.target_unit and blackboard.target_unit == blackboard.priority_target_enemy

	if blackboard.target_ally_need_type or has_priority_target then
		return false
	end

	local bot_whereabouts_extension = ScriptUnit.extension(self_unit, "whereabouts_system")
	local follow_unit_whereabouts_extension = ScriptUnit.extension(follow_unit, "whereabouts_system")
	local self_position = bot_whereabouts_extension:last_position_on_navmesh()
	local follow_unit_position = follow_unit_whereabouts_extension:last_position_on_navmesh()

	if not self_position or not follow_unit_position then
		return false
	end

	local distance_squared = Vector3.distance_squared(self_position, follow_unit_position)

	-- return FOLLOW_TELEPORT_DISTANCE_SQ <= distance_squared
	
	-- local prox_enemies = mod.get_proximite_enemies(self_unit, 10)	--4
	-- local enemy_threat = false
	-- local num_prox_enemies = 0
	-- for _, loop_unit in pairs(prox_enemies) do
		-- local breed = loop_unit and Unit.get_data(loop_unit, "breed")
		-- if breed and (mod.BOSS_UNITS[breed.name] or mod.LORD_UNITS[breed.name]) then
			-- enemy_threat = true
			
			-- break
		-- end
		
		-- local loop_distance = loop_unit and Vector3.length(POSITION_LOOKUP[self_unit] - POSITION_LOOKUP[loop_unit])
		-- if loop_distance and loop_distance < 5 then
			-- num_prox_enemies = num_prox_enemies + 1
			
			-- if num_prox_enemies > 3 then
				-- enemy_threat = true
				
				-- break
			-- end
		-- end
	-- end
	
	-- if not enemy_threat then
		-- return FOLLOW_TELEPORT_DISTANCE_SQ_REDUCED <= distance_squared
	-- end
	
	return FOLLOW_TELEPORT_DISTANCE_SQ <= distance_squared
end)

mod:hook_origin(BTConditions, "cant_reach_ally", function(blackboard)
	local follow_unit = blackboard.ai_bot_group_extension.data.follow_unit

	if not ALIVE[follow_unit] or blackboard.has_teleported then
		return false
	end

	local self_unit = blackboard.unit
	local level_settings = LevelHelper:current_level_settings()
	local disable_bot_main_path_teleport_check = level_settings.disable_bot_main_path_teleport_check
	local is_forwards = nil

	if not disable_bot_main_path_teleport_check then
		local conflict_director = Managers.state.conflict
		local self_segment = conflict_director:get_player_unit_segment(self_unit)
		local target_segment = conflict_director:get_player_unit_segment(follow_unit)

		if not self_segment or not target_segment then
			return false
		end

		-- local is_backwards = target_segment < self_segment
		-- local is_backwards = (target_segment+1) < self_segment

		-- if is_backwards then
			-- return false
		-- end

		-- is_forwards = self_segment < target_segment
		is_forwards = self_segment < (target_segment+1)
	end

	local bot_whereabouts_extension = ScriptUnit.extension(self_unit, "whereabouts_system")
	local follow_unit_whereabouts_extension = ScriptUnit.extension(follow_unit, "whereabouts_system")
	local self_position = bot_whereabouts_extension:last_position_on_navmesh()
	local follow_unit_position = follow_unit_whereabouts_extension:last_position_on_navmesh()

	if not self_position or not follow_unit_position then
		return false
	end

	local t = Managers.time:time("game")
	local navigation_extension = blackboard.navigation_extension
	local fails, last_success = navigation_extension:successive_failed_paths()

	-- return blackboard.moving_toward_follow_position and fails > (((disable_bot_main_path_teleport_check or is_forwards) and 1) or 5) and t - last_success > 5
	return blackboard.moving_toward_follow_position and fails > (((disable_bot_main_path_teleport_check or is_forwards) and 1) or 3) and t - last_success > 3
end)




-- updated to use tokens instead of direct commands as the latter
-- causes bots to fail to fire charged shots in certain situations
--[[
mod:hook_origin(BTBotShootAction, "_fire_shot", function(self, shoot_blackboard, action_data, input_extension, t)
	-- shoot_blackboard.fired = true
	-- shoot_blackboard.stop_fire_t = t + shoot_blackboard.stop_fire_delay

	-- if action_data.fire_input ~= "none" then
		-- local input = action_data.fire_input or shoot_blackboard.fire_input

		-- input_extension[input](input_extension)
	-- end

	-- if shoot_blackboard.charge_shot_delay then
		-- shoot_blackboard.next_charge_shot_t = t + shoot_blackboard.charge_shot_delay
	-- end
	
	-----------------------------------
	
	-- if action_data.fire_input ~= "none" then
		-- shoot_blackboard.fire_input = action_data.fire_input
	-- end
	
	shoot_blackboard.fire_input = action_data.fire_input
	
	shoot_blackboard.fire_shot_token = true
end)
--]]



-- Improves bot aim speed
-- note: this function's execuition is tied to FPS (each character once per frame)
--now in bt_bot_shoot_action.lua
--[[
mod:hook_origin(BTBotShootAction, "_calculate_aim_speed", function(self, self_unit, dt, current_yaw, current_pitch, wanted_yaw, wanted_pitch, current_yaw_speed, current_pitch_speed)
	local pi = math.pi
	local yaw_offset = (wanted_yaw - current_yaw + pi)%(pi*2) - pi
	local pitch_offset = wanted_pitch - current_pitch
	local yaw_offset_sign = math.sign(yaw_offset)
	local yaw_speed_sign = math.sign(current_yaw_speed)
	
	local offset_multiplier = 8*100*dt	--mainly nerf bots sniping speed here, if it does anything noticeable
	
	local new_yaw_speed = 0
	if yaw_offset >= 0 then
		new_yaw_speed = math.sqrt(yaw_offset)*offset_multiplier
	else
		new_yaw_speed = -math.sqrt(-yaw_offset)*offset_multiplier
	end
	
	local new_pitch_speed = 0
	if pitch_offset >= 0 then
		new_pitch_speed = math.sqrt(pitch_offset)*offset_multiplier
	else
		new_pitch_speed = -math.sqrt(-pitch_offset)*offset_multiplier
	end
	
	if math.abs(new_pitch_speed)*dt	> math.abs(pitch_offset)	then new_pitch_speed	= pitch_offset/dt end
	if math.abs(new_yaw_speed)*dt	> math.abs(yaw_offset)		then new_yaw_speed		= yaw_offset/dt end
	
	return new_yaw_speed, new_pitch_speed
end)
--]]

--Improve bot accuracy with ranged weapons

local function dprint(...)
	if script_data.ai_bots_weapon_debug and script_data.debug_unit == THIS_UNIT then
		print(...)
	end
end

--now in bt_bot_shoot_action.lua
--[[
mod:hook_origin(BTBotShootAction, "_aim_good_enough", function(self, dt, t, shoot_blackboard, yaw_offset, pitch_offset)
	local bb = shoot_blackboard
	
	local fuzzyness = 1
	if bb.ability_shot then
		local career_extension = bb.career_extension
		local career_name = career_extension:career_name()
		local talent_extension = bb.talent_extension
		local has_piercing_shot_ult = talent_extension:has_talent("kerillian_waywatcher_activated_ability_piercing_shot")
		
		if (career_name == "we_waywatcher" and not has_piercing_shot_ult) or career_name == "bw_scholar" then
			fuzzyness = 40 * 100
		end
	end
	
	if not bb.reevaluate_aim_time then
		bb.reevaluate_aim_time = 0
	end

	if bb.reevaluate_aim_time < t then
		local aim_data = (bb.charging_shot and bb.aim_data_charged) or bb.aim_data
		local offset = math.sqrt(pitch_offset * pitch_offset + yaw_offset * yaw_offset)

		local in_line_of_fire = bb.in_line_of_fire
		local aim_max_radius = ((in_line_of_fire and not bb.ability_shot) and aim_data.max_radius * 2) or (aim_data.max_radius / 50 * fuzzyness)
		
		if aim_max_radius < offset then
			bb.aim_good_enough = false

			dprint("bad aim - offset:", offset)
		else
			local success = nil
			local num_rolls = bb.num_aim_rolls + 1

			if offset < aim_data.min_radius then
				success = Math.random() < aim_data.min_radius_pseudo_random_c * num_rolls
			else
				local prob = math.auto_lerp(aim_data.min_radius, aim_data.max_radius, aim_data.min_radius_pseudo_random_c, aim_data.max_radius_pseudo_random_c, offset) * num_rolls
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

		bb.reevaluate_aim_time = t + 0.1
	end

	return bb.aim_good_enough
end)
--]]



--change aim node for Stormfiends
--now in bt_bot_shoot_action.lua

--[[
mod:hook(BTBotShootAction, "_wanted_aim_rotation", function(func, self, self_unit, target_unit, current_position, projectile_info, projectile_speed, aim_at_node)
	--Override for Stormfiends
	local target_unit_blackboard = BLACKBOARDS[target_unit]
	local target_breed = target_unit_blackboard and target_unit_blackboard.breed
	
	if target_breed and (target_breed.name == "skaven_stormfiend" or target_breed.name == "skaven_stormfiend_boss") then
		local _, flanking = mod.check_alignment_to_target(self_unit, target_unit, nil, 90)
		if flanking then
			aim_at_node = "c_packmaster_sling_02"
		end
	end
	
	return func(self, self_unit, target_unit, current_position, projectile_info, projectile_speed, aim_at_node)
end)
--]]



--Changed the obstruction check to ignore other players
--now in bt_bot_shoot_action.lua

--[[
mod:hook(BTBotShootAction, "_update_collision_filter", function(func, self, target_unit, shoot_blackboard, priority_target_enemy, target_ally_unit, target_ally_needs_aid, need_type)
	func(self, target_unit, shoot_blackboard, priority_target_enemy, target_ally_unit, target_ally_needs_aid, need_type)
	
	if shoot_blackboard.collision_filter == "filter_bot_ranged_line_of_sight_no_enemies" then
		shoot_blackboard.collision_filter = "filter_bot_ranged_line_of_sight_no_allies_no_enemies"
	end
	
	if shoot_blackboard.collision_filter == "filter_bot_ranged_line_of_sight" then
		shoot_blackboard.collision_filter = "filter_bot_ranged_line_of_sight_no_allies"		--filter_bot_ranged_line_of_sight_no_allies_no_enemies	--filter_bot_ranged_line_of_sight_no_allies
	end
	
	if shoot_blackboard.collision_filter_charged == "filter_bot_ranged_line_of_sight_no_enemies" then
		shoot_blackboard.collision_filter_charged = "filter_bot_ranged_line_of_sight_no_allies_no_enemies"
	end
	
	if shoot_blackboard.collision_filter_charged == "filter_bot_ranged_line_of_sight" then
		shoot_blackboard.collision_filter_charged = "filter_bot_ranged_line_of_sight_no_allies"		--filter_bot_ranged_line_of_sight_no_allies_no_enemies	--filter_bot_ranged_line_of_sight_no_allies
	end
end)
--]]




--Follow positions

local generate_points = function(ai_bot_group_system, player)
	-- debug_print_variables("***************")
	local points = nil

	local validate_point = function(point)
		local alt_offsets =
		{
			Vector3(0,-1,0),
			Vector3(-0.5,-0.866,0),
			Vector3(-0.866,-0.5,0),
			Vector3(-1,0,0),
			Vector3(-0.866,0.5,0),
			Vector3(-0.5,0.866,0),
			Vector3(0,1,0),
			Vector3(0.5,0.866,0),
			Vector3(0.866,0.5,0),
			Vector3(1,0,0),
			Vector3(0.866,-0.5,0),
			Vector3(0.5,-0.866,0),
			
			Vector3(0,-0.5,0),
			Vector3(-0.25,-0.433,0),
			Vector3(-0.433,-0.25,0),
			Vector3(-0.5,0,0),
			Vector3(-0.433,0.25,0),
			Vector3(-0.25,0.433,0),
			Vector3(0,0.5,0),
			Vector3(0.25,0.433,0),
			Vector3(0.433,0.25,0),
			Vector3(0.5,0,0),
			Vector3(0.433,-0.25,0),
			Vector3(0.25,-0.433,0),
		}
		local ret = point
		if ret then
			ret = Vector3.copy(point)
			local nav_world	= Managers.state.bot_nav_transition._nav_world
			local above		= 2.5
			local below		= 2.5
			
			local success, z = GwNavQueries.triangle_from_position(nav_world, ret, above, below)
			
			if success then
				ret.z = z
			else
				local z_diff = math.huge
				local result = false
				for _,offset in pairs(alt_offsets) do
					local try = Vector3.copy(ret) + offset * 2.5	--1.5
					local success, z = GwNavQueries.triangle_from_position(nav_world, try, above, below)
					if success then
						local diff = math.abs(z-ret.z)
						if diff < z_diff then
							z_diff = diff
							result = Vector3.copy(try)
							result.z = z
						end
					end
				end
				if result then
					-- debug_print_variables(result)
					ret = result
				end
			end
		end
		return ret
	end
	
	-- Collect data
	local player_unit = player.player_unit
	local player_pos = POSITION_LOOKUP[player_unit]
	local player_pos_nav = (player_pos and validate_point(player_pos)) or false
	-- debug_print_variables(player_pos, player_pos_nav)
	player_pos = player_pos_nav or Vector3(0, 0, -1000)
	-- local num_bots = ai_bot_group_system._num_bots
	local num_bots = ai_bot_group_system._total_num_bots
	local nav_world = Managers.state.bot_nav_transition._nav_world -- Managers.state.entity:system("ai_system"):nav_world()
	local traverse_logic = Managers.state.bot_nav_transition._traverse_logic
	
	--  no mission specific standing ponts needed >> assign points as per normal routine
	local disallowed_at_pos, current_mapping = ai_bot_group_system:_selected_unit_is_in_disallowed_nav_tag_volume(nav_world, player_pos)
	if disallowed_at_pos then
		local origin_point = ai_bot_group_system:_find_origin(nav_world, player_unit)

		points = ai_bot_group_system:_find_destination_points_outside_volume(nav_world, player_pos, current_mapping, origin_point, num_bots)
	else

		points = {}
		local player_rotation			= Unit.local_rotation(player_unit, 0)
		local player_forward			= Quaternion.forward(player_rotation)
		local first_person_extension	= ScriptUnit.has_extension(player_unit, "first_person_system")
		local camera_rotation			= first_person_extension and first_person_extension:current_rotation()
		local camera_forward			= (camera_rotation and Quaternion.forward(camera_rotation)) or player_forward
		local forward_angle_offset		= Vector3.flat_angle(Vector3(1,0,0), Vector3.normalize(Vector3.flat(camera_forward))) + math.pi
		-- local stand_distance			= 2
		-- local angle_offset_rad			= (-30 * math.pi/180) - forward_angle_offset
		-- local base_angle_offset_rad		= 120 * math.pi/180
		-- local stand_v1 = Vector3(math.sin(base_angle_offset_rad * 0 + angle_offset_rad),	math.cos(base_angle_offset_rad * 0 + angle_offset_rad),	0)
		-- local stand_v2 = Vector3(math.sin(base_angle_offset_rad * 1 + angle_offset_rad),	math.cos(base_angle_offset_rad * 1 + angle_offset_rad),	0)
		-- local stand_v3 = Vector3(math.sin(base_angle_offset_rad * 2 + angle_offset_rad),	math.cos(base_angle_offset_rad * 2 + angle_offset_rad),	0)
		local stand_distance			= 2.5
		local angle_offset_rad			= (90 * math.pi/180) - forward_angle_offset
		local base_angle_offset_rad		= 60 * math.pi/180
		local stand_v1 = Vector3(math.sin(base_angle_offset_rad * 0 + angle_offset_rad),	math.cos(base_angle_offset_rad * 0 + angle_offset_rad),	0)
		local stand_v2 = Vector3(math.sin(base_angle_offset_rad * 1 + angle_offset_rad),	math.cos(base_angle_offset_rad * 1 + angle_offset_rad),	0)
		local stand_v3 = Vector3(math.sin(base_angle_offset_rad * (-1) + angle_offset_rad),	math.cos(base_angle_offset_rad * (-1) + angle_offset_rad),	0)
		table.insert(points,player_pos + stand_v1 * stand_distance)
		table.insert(points,player_pos + stand_v2 * stand_distance)
		table.insert(points,player_pos + stand_v3 * stand_distance)
		
		local points_nav =
		{
			validate_point(points[1]),
			validate_point(points[2]),
			validate_point(points[3]),
		}
		
		points[1] = points_nav[1] or points_nav[2] or points_nav[3] or player_pos
		points[2] = points_nav[2] or points_nav[3] or points_nav[1] or player_pos
		points[3] = points_nav[3] or points_nav[1] or points_nav[2] or player_pos
		-- debug_print_variables(points_nav[1], points_nav[2], points_nav[3], player_pos)
		-- local check_points =
		-- {
			-- player_pos =
			-- {
				-- Vector3(player_pos.x, player_pos.y, player_pos.z + 0.5),
				-- Vector3(player_pos.x, player_pos.y, player_pos.z + 1.25),
				-- Vector3(player_pos.x, player_pos.y, player_pos.z + 2.5),
			-- },
			-- points = 
			-- {
				-- Vector3(points[1].x, points[1].y, points[1].z + 1.5),
				-- Vector3(points[2].x, points[2].y, points[2].z + 1.5),
				-- Vector3(points[3].x, points[3].y, points[3].z + 1.5),
			-- },
		-- }
		
		
		local check1 =	-- mod.check_line_of_sight(false, false, check_points.player_pos[1],	check_points.points[1]) and 
						-- mod.check_line_of_sight(false, false, check_points.player_pos[2],	check_points.points[1]) and
						-- mod.check_line_of_sight(false, false, check_points.player_pos[3],	check_points.points[1]) and
						GwNavQueries.raycango(nav_world, points[1], player_pos, traverse_logic)
						
		local check2 =	-- mod.check_line_of_sight(false, false, check_points.player_pos[1],	check_points.points[2]) and 
						-- mod.check_line_of_sight(false, false, check_points.player_pos[2],	check_points.points[2]) and
						-- mod.check_line_of_sight(false, false, check_points.player_pos[3],	check_points.points[2]) and
						GwNavQueries.raycango(nav_world, points[2], player_pos, traverse_logic)
						
		local check3 =	-- mod.check_line_of_sight(false, false, check_points.player_pos[1],	check_points.points[3]) and 
						-- mod.check_line_of_sight(false, false, check_points.player_pos[2],	check_points.points[3]) and
						-- mod.check_line_of_sight(false, false, check_points.player_pos[3],	check_points.points[3]) and
						GwNavQueries.raycango(nav_world, points[3], player_pos, traverse_logic)
						
		-- debug_print_variables(check1, check2, check3)
		-- if not (check1 or check2 or check3) then
			-- points[1] = player_pos
			-- points[2] = player_pos
			-- points[3] = player_pos
		-- else
			points[1] = (check1 and points[1]) or (check2 and points[2]) or (check3 and points[3]) or player_pos
			points[2] = (check2 and points[2]) or (check3 and points[3]) or (check1 and points[1]) or player_pos
			points[3] = (check3 and points[3]) or (check1 and points[1]) or (check2 and points[2]) or player_pos
			
		-- end
		
		-- for _,point in pairs(points) do
			-- local max_height_offset = 2.5
			-- local success, altitude = GwNavQueries.triangle_from_position(nav_world, point, max_height_offset, max_height_offset)
			-- if success then
				-- point.z = altitude
			-- end
		-- end
		
	end

	return points
end

local old_follow_position = {}

mod:hook(AIBotGroupSystem, "_assign_destination_points", function(func, self, bot_ai_data, points, follow_unit, follow_unit_table)
	func(self, bot_ai_data, points, follow_unit, follow_unit_table)

	local follow_host = false
	
	local follow_owner = false
	
	if follow_host then
		follow_owner = Managers.player:local_player()
	else
		follow_owner = Managers.player:unit_owner(follow_unit)
	end
	
	if not follow_owner then return end
	
	local player					= follow_owner
	local player_unit				= player.player_unit
	local player_position			= POSITION_LOOKUP[player_unit]
	local player_status_extension	= ScriptUnit.has_extension(player.player_unit, "status_system")
	local may_follow_player			= player_status_extension and not player_status_extension:is_disabled() -- if the player is disabled, let the default routine assing the points -- (player_status_extension:is_dead() or player_status_extension:is_ready_for_assisted_respawn())
	
	-- if follow_unit and me.player_is_enabled(player) or follow_unit_table and table.has_item(follow_unit_table, player_unit) then
	if (follow_unit and may_follow_player) or (follow_unit_table and table.has_item(follow_unit_table, player_unit)) then
		local destination_points	= generate_points(self, player)
		local inventory_extension	= ScriptUnit.has_extension(player_unit,"inventory_system")
		local slot_name				= inventory_extension and inventory_extension:get_wielded_slot_name()
		local player_moved			= player_position and old_follow_position[player_unit] and Vector3.length(old_follow_position[player_unit]:unbox() - player_position) > 0.001
		local repositioning_denied	= not player_moved and (not slot_name or slot_name == "slot_healthkit" or slot_name == "slot_potion" or slot_name == "slot_grenade")
		
		if destination_points then
			local i = 1
			local used_points = {}
			-- Update bots with new positions
			for unit, data in pairs(bot_ai_data) do
				local loop_pos		= POSITION_LOOKUP[unit]
				if loop_pos then
					local best_distance	= math.huge
					local best_point	= false
					for _,point in pairs(destination_points) do
						if not used_points[point] then
							local distance = Vector3.length(loop_pos - point)
							if distance < best_distance then
								if best_point then used_points[best_point] = nil end
								used_points[point] = true
								best_point		= point
								best_distance	= distance
							end
						end
					end
					
					
					data.follow_unit = player_unit
					
					best_point = best_point or destination_points[1]
					local old_position = (old_follow_position[unit] and old_follow_position[unit]:unbox()) or false
					if old_position then
						if not repositioning_denied and Vector3.length(old_position - best_point) > 0.5 then
							data.follow_position = best_point
							old_follow_position[unit] = Vector3Box(best_point)
						else
							data.follow_position = old_position
						end
					else
						data.follow_position = best_point
						old_follow_position[unit] = Vector3Box(best_point)
					end
				end
				i = i + 1
			end
		end
		
		if player_position then
			old_follow_position[player_unit] = Vector3Box(player_position)
		end
	end
	
	-- clear garbage data out from the old follow position table
	for key,data in pairs(old_follow_position) do
		if not Unit.alive(key) then
			old_follow_position[key] = nil
		end
	end

	return
end)




--Increase bot pickup distance (when there is pickup order)

mod:hook_origin(BTConditions, "can_loot", function(blackboard)
	local play_go_system = Managers.state.entity:system("play_go_tutorial_system")

	if play_go_system and not play_go_system:bot_loot_enabled() then
		return false
	end

	local self_unit = blackboard.unit
	local ai_bot_group_system = Managers.state.entity:system("ai_bot_group_system")
	local has_ammo_pickup_order = ai_bot_group_system:get_ammo_pickup_order_unit(self_unit) ~= nil
	local has_pickup_order = has_ammo_pickup_order or ai_bot_group_system:has_pending_pickup_order(self_unit)
	
	-- local max_dist = (has_pickup_order and 10) or 3.5		--7	--3.2
	local max_dist = (has_pickup_order and 12) or 5		--7	--3.2
	local is_forced_pickup = blackboard.forced_pickup_unit == blackboard.interaction_unit
	local loot_health = blackboard.health_pickup and blackboard.allowed_to_take_health_pickup and blackboard.health_pickup == blackboard.interaction_unit and (is_forced_pickup or blackboard.health_dist < max_dist)
	local loot_ammo = blackboard.ammo_pickup and blackboard.has_ammo_missing and blackboard.ammo_pickup == blackboard.interaction_unit and (is_forced_pickup or blackboard.ammo_dist < max_dist)
	local loot_mule = blackboard.mule_pickup and blackboard.mule_pickup == blackboard.interaction_unit and (is_forced_pickup or blackboard.mule_pickup_dist_squared < max_dist^2)

	return loot_health or loot_ammo or loot_mule
end)




-- ## Bots Block on Path Search - Teleport to Ally Action ##
-- Start blocking as the teleport action begins
-- Xq: initialize teleport loop stuck detection data

local bot_teleport_manual_block = function(unit, blackboard, should_block, t)
	if unit and Unit.alive(unit) and blackboard and blackboard.input_extension then
		local input_extension = blackboard.input_extension
		
		if should_block then
			input_extension:wield("slot_melee")
			input_extension._defend = true
			blackboard._block_start_time_BIE = t
			
		elseif t > (blackboard._block_start_time_BIE + 1) then
			input_extension._defend = false
			blackboard._block_start_time_BIE = nil
		end
	end
end

mod:hook(BTBotTeleportToAllyAction, "enter", function(func, self, unit, blackboard, t)
	bot_teleport_manual_block(unit, blackboard, true, t)
	
	-- initialize loop counter and record start time for teleport loop stuck detection (="watchdog" timer / counter)
	if not blackboard.teleport_stuck_loop_start_time then
		blackboard.teleport_stuck_loop_counter = 0
		blackboard.teleport_stuck_loop_start_time = t
	end
	
	return func(self, unit, blackboard, t)
end)

--[[
local is_teleport_denied_to_position = function(self_unit, pos)
	local self_owner	= Managers.player:unit_owner(self_unit)
	local d				= get_d_data(self_unit)
	
	if not d then
		return true
	end

	local level_id = LevelHelper:current_level_settings().level_id
	
	if #d.defense.threat_boss > 0 then
		-- the bots shouldn't try to teleport when a boss is posing an immediate threat to them
		return true
	end
	
	-- add level spesific teleport denial zones to prevent bots from teleporting inside walls / past closed mission gates / such
	
	if level_id == "dlc_dwarf_interior" then
		if	pos.x > -120 and pos.x < -108 and
			pos.y > -8 and pos.y < 4 and
			pos.z > 7 and pos.z < 11 then
			-- Khazid Kro, behind the boiler room gates
			return true
		end
		
	elseif level_id == "dlc_castle" then
		if	pos.x > 49 and pos.x < 54 and
			pos.y > 146 and pos.y < 170 and
			pos.z > 0 and pos.z < 4 then
			-- Castle Drachenfels, behind a wall near grim #2
			return true
		end
		
	end
	
	return false
end
--]]

-- Continue blocking as the teleport action runs
mod:hook(BTBotTeleportToAllyAction, "run", function(func, self, unit, blackboard, t, dt)
	bot_teleport_manual_block(unit, blackboard, true, t)
	
	-- Xq: make sure the bot teleports to its follow target if their current target is not disabled
	-- (disabled = dead or pounced or knocked down or packmastered or hanging on ledge or hanging on hook or needs rescue)
	local current_time = Managers.time:time("game")
	local follow_unit = blackboard.ai_bot_group_extension.data.follow_unit
	local target_unit = blackboard.target_ally_unit
	local target_status_extension = ScriptUnit.has_extension(target_unit, "status_system")
	if target_unit and follow_unit and target_status_extension and not target_status_extension:is_disabled() then
		blackboard.target_ally_unit = follow_unit
	end
	
	return func(self, unit, blackboard, t, dt)
end)

-- Cancel blocking when the teleport action ends
mod:hook(BTBotTeleportToAllyAction, "leave", function(func, self, unit, blackboard, t, reason, destroy)
	-- local self_unit		= unit
	-- local self_owner	= Managers.player:unit_owner(self_unit)
	-- local d				= get_d_data(self_unit)
	
	-- if not d or not d.settings.bot_file_enabled then 
		-- return func(self, unit, blackboard, t)
	-- end
	
	-- Original Function
	local result = func(self, unit, blackboard, t, reason, destroy)
	
	bot_teleport_manual_block(unit, blackboard, false, t)
	
	-- Xq: check if teleport loop is stuck (=has been restarted > 100 times or has been running for more than 5s)	--changed to 2.5s
	-- if so force the bot to teleport to the target's current coordinate
	if blackboard.teleport_stuck_loop_start_time then
		if (t - blackboard.teleport_stuck_loop_start_time) > 2.5 and blackboard.teleport_stuck_loop_counter > 100 then
			local follow_unit = blackboard.ai_bot_group_extension.data.follow_unit
			local destination = POSITION_LOOKUP[follow_unit]
			local status_extension = ScriptUnit.has_extension(unit, "status_system")
			if status_extension and not status_extension:is_disabled() then	-- still don't teleport on top of disabled player
				blackboard.teleport_stuck_loop_counter = nil
				blackboard.teleport_stuck_loop_start_time = nil
				-- teleport
				local locomotion_extension = ScriptUnit.extension(unit, "locomotion_system")
				locomotion_extension.teleport_to(locomotion_extension, destination)
				blackboard.has_teleported = true
				blackboard.navigation_extension:teleport(destination)
				-- blackboard.ai_system_extension:clear_failed_paths()
				blackboard.ai_extension:clear_failed_paths()	--from VT2 source code
				blackboard.follow.needs_target_position_refresh = true
				
				-- EchoConsole("Teleport loop stuck - forced teleport to follow target")
			end
		else
			blackboard.teleport_stuck_loop_counter = blackboard.teleport_stuck_loop_counter+1
		end
	end
	-- d.unstuck_data.is_stuck = false
	
	return result
end)




-- ## Bots Block on Path Search - Nil Action ##
-- Start blocking when the nil action ends, and hold the block until the game decides to release it
--[[
Mods.hook.set(mod_name, "BTNilAction.leave", function (func, self, unit, blackboard, t)
	profiler_data:add("BTNilAction.leave")
	
	if get(me.SETTINGS.FILE_ENABLED) then 
		bot_teleport_manual_block(unit, blackboard, true, t)
	end
	
	-- Original Function
	return func(self, unit, blackboard, t)
end)
--]]

mod:hook(BTNilAction, "run", function(func, self, unit, blackboard, t, dt, bt_name)
	self.nil_action_unit = unit
	self.nil_action_blackboard = blackboard
	
	return func(self, unit, blackboard, t, dt, bt_name)
end)

mod:hook(BTNilAction, "leave", function(func, self)
	bot_teleport_manual_block(self.nil_action_unit, self.nil_action_blackboard, true, t)

	return func(self)
end)




-- Xq: bots hold block while in elevator
-- probably need defend tokens, later
--[[
mod:hook(LinkerTransportationExtension, "_link_transported_unit", function(func, self, unit_to_link, teleport_on_enter)
	local unit			= unit_to_link
	local owner			= Managers.player:owner(unit)
	local blackboard	= BLACKBOARDS[unit]
	
	if owner.bot_player then
		blackboard.input_extension:wield("slot_melee")	-- make sure the melee slot is active
		blackboard.input_extension:defend()
	end
	
	return func(self, unit_to_link, teleport_on_enter)
end)

-- Xq: and likewise, bots can stop blocking when they exit the elevator
mod:hook(LinkerTransportationExtension, "_unlink_transported_unit", function(func, self, unit_to_unlink)
	local unit			= unit_to_unlink
	local owner			= Managers.player:owner(unit)
	local blackboard	= BLACKBOARDS[unit]
	
	if owner.bot_player then	-- check is needed because the player is also "unlinked"
		bot_teleport_manual_block(unit, blackboard, false, t)
	end
	
	return func(self, unit_to_unlink)
end)
--]]




-------------
--New Hooks--
-------------

--Block while dodging AoE threat & Fix possible dodge input error
mod:hook(PlayerBotInput, "_update_movement", function(func, self, dt, t)
	local ai_bot_group_extension = self._ai_bot_group_extension
	local threat_data = ai_bot_group_extension.data.aoe_threat
	self._avoiding_aoe_threat_save = t < threat_data.expires

	func(self, dt, t)
	
	local blackboard = self.unit and BLACKBOARDS[self.unit]
	if self._avoiding_aoe_threat_save then
		--effectively call BTBotMeleeAction._clear_pending_attack() below
		local best_defensive_slot = "slot_melee"
		if blackboard then
			local inventory_extension = blackboard.inventory_extension
			local _, right_hand_weapon_extension, left_hand_weapon_extension = CharacterStateHelper.get_item_data_and_weapon_extensions(inventory_extension)
			local _, current_action_extension, _ = CharacterStateHelper.get_current_action_data(left_hand_weapon_extension, right_hand_weapon_extension)
			local weapon_extension = current_action_extension or right_hand_weapon_extension or left_hand_weapon_extension
			
			if weapon_extension then
				weapon_extension:clear_bot_attack_request()
			end
			
			best_defensive_slot = BTConditions.get_best_defensive_slot(blackboard)
			blackboard._avoiding_aoe_threat_ = true
		end
		
		-- self:wield(best_defensive_slot)
		-- self:defend()
		
		--[[
		-- self.move.y = math.max(self.move.y, 0)
		-- if self.move.y == 0 and self.move.x == 0 then
			-- if Math.random(1, 2) == 1 then
				-- self.move.x = 1
			-- else
				-- self.move.x = -1
			-- end
		-- end
		
		-- self:dodge_movement_fix()
		--]]
	else
		if blackboard then
			blackboard._avoiding_aoe_threat_ = false
		end
	end
	
	if self._dodge then
		self:dodge_movement_fix()
	end
end)

PlayerBotInput.dodge_movement_fix = function (self)
	self.move.y = math.min(self.move.y, 0)
	if self.move.y == 0 and self.move.x == 0 then
		if math.random() < 0.5 then
			self.move.x = 1
		else
			self.move.x = -1
		end
	end
end




--Remove delay on bot threat dodge
mod:hook_origin(AiUtils, "calculate_bot_threat_time", function (bot_threat)
	return bot_threat.start_time, bot_threat.duration
end)




--How to make bots don't stand inside Stormfiend fire wall?
--testing: disable blob, troll puke etc. to interfere bot navigation
--now in player_bot_base.lua
--[[
mod:hook(AreaDamageSystem, "is_position_in_liquid", function(func, self, position, nav_cost_map_table)
	-- local liquid_extensions = self.liquid_extensions
	-- local num_liquid_extensions = self.num_liquid_extensions
	-- local result = false

	-- for i = 1, num_liquid_extensions, 1 do
		-- local extension = liquid_extensions[i]
		-- result = extension:is_position_inside(position, nav_cost_map_table)

		-- if result then
			-- break
		-- end
	-- end

	-- return result
	
	local ret = func(self, position, nav_cost_map_table)
	
	return false
end)

--GenericStatusExtension.is_in_liquid

mod:hook(PlayerBotBase, "_update_liquid_escape", function(func, self)
	-- local unit = self._unit
	-- local blackboard = self._blackboard
	-- local status_extension = self._status_extension
	-- local in_liquid = status_extension:is_in_liquid()
	-- local use_liquid_escape_destination = blackboard.use_liquid_escape_destination
	-- local navigation_extension = blackboard.navigation_extension
	-- local is_disabled = status_extension:is_disabled()

	-- if in_liquid and not is_disabled and (not use_liquid_escape_destination or navigation_extension:destination_reached()) then
		-- local liquid_unit = status_extension.in_liquid_unit
		-- local liquid_extension = ScriptUnit.extension(liquid_unit, "area_damage_system")
		-- local rim_nodes, is_array = liquid_extension:get_rim_nodes()
		-- local bot_position = POSITION_LOOKUP[unit]
		-- local best_distance_sq = math.huge
		-- local best_position = nil

		-- if is_array then
			-- local num_nodes = #rim_nodes

			-- for i = 1, num_nodes, 1 do
				-- local position = rim_nodes[i]:unbox()
				-- local distance_sq = Vector3.distance_squared(bot_position, position)

				-- if distance_sq < best_distance_sq then
					-- best_position = position
					-- best_distance_sq = distance_sq
				-- end
			-- end
		-- else
			-- for _, node in pairs(rim_nodes) do
				-- local position = node.position:unbox()
				-- local distance_sq = Vector3.distance_squared(bot_position, position)

				-- if distance_sq < best_distance_sq then
					-- best_position = position
					-- best_distance_sq = distance_sq
				-- end
			-- end
		-- end

		-- if best_position then
			-- blackboard.navigation_liquid_escape_destination_override:store(best_position)

			-- blackboard.use_liquid_escape_destination = true
		-- end
	-- elseif use_liquid_escape_destination and (is_disabled or not in_liquid) then
		-- blackboard.use_liquid_escape_destination = false
	-- end
	
	func(self)
	
	local blackboard = self._blackboard
	blackboard.use_liquid_escape_destination = false
end)
--]]




--Stop bots from dodging crank gun bullets
mod:hook_origin(ActionCareerDREngineer, "_update_bot_avoidance", function (self, t)
	return
end)




--Bots don't pickup tomes automatically, from Bits of Bot Improvements
--Reduce pickup check range so bots don't randomly run off

local MAX_PICKUP_RANGE_SQ = 49		--16	--49

mod:hook(AIBotGroupSystem, "_update_health_pickups", function(func, self, dt, t)
	func(self, dt, t)
	
	local bot_ai_data = self._bot_ai_data
	
	for side_id = 1, #bot_ai_data, 1 do
		local side_bot_data = bot_ai_data[side_id]
	
		for unit, data in pairs(side_bot_data) do
			local blackboard = BLACKBOARDS[unit]
			if blackboard.allowed_to_take_health_pickup then
				local pickup_pos = POSITION_LOOKUP[blackboard.health_pickup]
				local follow_unit = data.follow_unit
				local out_of_range = follow_unit and (Vector3.distance_squared(POSITION_LOOKUP[follow_unit], pickup_pos) > MAX_PICKUP_RANGE_SQ)
				if out_of_range then
					blackboard.allowed_to_take_health_pickup = false
				end
			end
		end
	end
end)

mod:hook(AIBotGroupSystem, "_update_mule_pickups", function(func, self, dt, t)
	func(self, dt, t)
	
	local bot_ai_data = self._bot_ai_data
	
	for side_id = 1, #bot_ai_data, 1 do
		local side_bot_data = bot_ai_data[side_id]
		
		for unit, data in pairs(side_bot_data) do
			local blackboard = BLACKBOARDS[unit]
			if blackboard.mule_pickup then
				local pickup_pos = POSITION_LOOKUP[blackboard.mule_pickup]
				local follow_unit = data.follow_unit
				local out_of_range = follow_unit and (Vector3.distance_squared(POSITION_LOOKUP[follow_unit], pickup_pos) > MAX_PICKUP_RANGE_SQ)
				if out_of_range then
					blackboard.mule_pickup = nil
				end
			end
		end
	end
end)

--now in pickup_tweaks.lua
--[[
local PICKUP_CHECK_RANGE = 5	--10	--5	--15
local PICKUP_FETCH_RESULTS = {}

mod:hook_origin(AIBotGroupSystem, "_update_pickups_near_player", function (self, player_unit, t)
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
	local all_players_have_ammo = true
	-- local valid_until = t + 5
	local valid_until = t + 3
	local ammo_stickiness = 2.5
	local allowed_distance_to_self = 5
	-- local allowed_distance_to_follow_pos = 15
	local allowed_distance_to_follow_pos = 7
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

			-- if pickup_name == "healing_draught" or pickup_name == "first_aid_kit" or pickup_name == "tome" then
			if pickup_name == "healing_draught" or pickup_name == "first_aid_kit" then
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
			elseif pickup_data.bots_mule_pickup then
				local slot_name = pickup_data.slot_name
				mule_pickups[slot_name][pickup_unit] = valid_until
			elseif pickup_data.type == "ammo" then
				if check_player_ammo then
					local PLAYER_UNITS = side.PLAYER_UNITS
					local num_human_players = #PLAYER_UNITS

					for i = 1, num_human_players, 1 do
						local player_unit = PLAYER_UNITS[i]

						if Unit.alive(player_unit) then
							local inventory_ext = ScriptUnit.extension(player_unit, "inventory_system")
							local ammo_percentage = inventory_ext:ammo_percentage()

							if ammo_percentage < 1 then
								all_players_have_ammo = false

								break
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
							allowed_to_take_ammo = (pickup_ammo_kind == "thrown" and true) or (bb.has_ammo_missing and (not pickup_data.only_once or (bb.needs_ammo and all_players_have_ammo)))
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
--]]




--for testing stormfiend boss
--just enable Onslaught+
-- mod:hook_origin(AiBreedSnippets, "on_stormfiend_boss_spawn", function (unit, blackboard)
	-- AiBreedSnippets.on_stormfiend_spawn(unit, blackboard)

	-- local hp = ScriptUnit.extension(blackboard.unit, "health_system"):current_health_percent()
	-- blackboard.hp_at_mounted = hp
	-- local health_extension = ScriptUnit.extension(unit, "health_system")
	-- health_extension.is_invincible = true
	-- blackboard.current_phase = 1
-- end)




--PlayerBotBase.update
--https://github.com/Aussiemon/Vermintide-2-Source-Code/blob/54867e3cd2a1ec152433a090ce9057a3fbd039eb/scripts/unit_extensions/human/player_bot_unit/player_bot_base.lua#L315












-----------------------------
--Bits of Bot Improvements --
-----------------------------

mod.utility.obstructed_path = function(world, player_unit, target_unit, player_position, target_position)
	local INDEX_POSITION = 1
	local INDEX_DISTANCE = 2
	local INDEX_NORMAL = 3
	local INDEX_ACTOR = 4

	local player_unit_pos = player_position
	local target_unit_pos = target_position

	if player_unit_pos == nil then
		player_unit_pos = Unit.world_position(player_unit, 0)
		player_unit_pos.z = player_unit_pos.z + 1.5
	end
	
	if target_unit_pos == nil then
		target_unit_pos = Unit.world_position(target_unit, 0)
		target_unit_pos.z = target_unit_pos.z + 1.3
	end

	local physics_world = World.get_data(world, "physics_world")
	local max_distance = Vector3.length(target_unit_pos - player_unit_pos)

	local direction = target_unit_pos - player_unit_pos
	local length = Vector3.length(direction)
	direction = Vector3.normalize(direction)
	local collision_filter = "filter_player_ray_projectile"

	PhysicsWorld.prepare_actors_for_raycast(physics_world, player_unit_pos, direction, 0.01, 10, max_distance*max_distance)

	local raycast_hits = PhysicsWorld.immediate_raycast(physics_world, player_unit_pos, direction, max_distance, "all", "collision_filter", collision_filter)

	if raycast_hits then
		local num_hits = #raycast_hits

		for i = 1, num_hits, 1 do
			local hit = raycast_hits[i]
			local hit_actor = hit[INDEX_ACTOR]
			local hit_unit = Actor.unit(hit_actor)

			if hit_unit == target_unit then
				return false
			elseif hit_unit ~= player_unit then
				local obstructed_by_static = Actor.is_static(hit_actor)

				if obstructed_by_static then
					return obstructed_by_static
				end
			end
		end
	end

	return false
end




local function is_shade_in_invis(career_name, self_unit)
	if career_name == "we_shade" then
		local buff_extension = ScriptUnit.extension(self_unit, "buff_system")
		local ability_buff = nil
		
		local shade_buffs = {
			"kerillian_shade_activated_ability",
			"kerillian_shade_activated_ability_duration"
		}
		local num_buffs = #shade_buffs
		
		for i = 1, num_buffs, 1 do
			local buff_name = shade_buffs[i]
			ability_buff = buff_extension:get_non_stacking_buff(buff_name)
			
			if ability_buff then
				break
			end
		end
		
		if not ability_buff then
			ability_buff = buff_extension:get_buff_type("kerillian_shade_ult_invis") or buff_extension:get_buff_type("kerillian_shade_activated_ability_restealth")
		end
		
		if ability_buff then
			return true
		end
	end
	
	return false
end

--now in player_bot_base.lua
--[[
local max_shot_time = 1
mod:hook_origin(PlayerBotBase, "_update_target_enemy", function(self, dt, t)
	local bb = self._blackboard
	local self_unit = self._unit
	local career_extension = bb.career_extension
	local is_using_ability = bb.activate_ability_data.is_using_ability
	local career_name = career_extension:career_name()
	local ability_check_category_name = "shoot_ability"
	local ability_check_category = BTConditions.ability_check_categories[ability_check_category_name]
	
	local near_enemies			= mod.get_proximite_enemies(self_unit, 5, 3.8)	--4.5
	local num_near_enemies		= #near_enemies
	
	local cannot_change_target = false
	if ability_check_category and ability_check_category[career_name] and is_using_ability then
		local target = bb.target_unit
		
		if target and mod.is_unit_alive(target) and Unit.has_data(target, "breed") and mod.check_line_of_sight(self_unit, target) then
			cannot_change_target = true
			
			local shot_start_time = bb.time_when_shoot_ability_started or 0
	
			if near_enemies and num_near_enemies > 2 and t > shot_start_time + max_shot_time * (num_near_enemies < 4 and 1.5 or 1) then
				cannot_change_target = false
			end
		end
	end
	
	if cannot_change_target then
		if mod.components.ping_enemies.value then
			mod.components.ping_enemies.attempt_ping_enemy(self._blackboard)
		end
		
		return
	end
	
	local pos = POSITION_LOOKUP[self._unit]
	local self_pos = pos

	self:_update_slot_target(dt, t, pos)
	self:_update_proximity_target(dt, t, pos)
	
	local old_target = bb.target_unit
	local slot_enemy = bb.slot_target_enemy
	local prox_enemy = bb.proximity_target_enemy
	local priority_enemy = bb.priority_target_enemy
	local urgent_enemy = bb.urgent_target_enemy
	local opportunity_enemy = bb.opportunity_target_enemy
	
	local STICKYNESS_DISTANCE_MODIFIER = -0.2
	
	-- if bb.shoot and bb.shoot.charging_shot then
		-- STICKYNESS_DISTANCE_MODIFIER = -3	--2
	-- end
	
	local prox_enemy_dist = bb.proximity_target_distance + ((prox_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local prio_enemy_dist = bb.priority_target_distance + ((priority_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local urgent_enemy_dist = bb.urgent_target_distance + ((urgent_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local opp_enemy_dist = bb.opportunity_target_distance + ((opportunity_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	local slot_enemy_dist = math.huge

	if slot_enemy then
		slot_enemy_dist = Vector3.length(POSITION_LOOKUP[slot_enemy] - pos) + ((slot_enemy == old_target and STICKYNESS_DISTANCE_MODIFIER) or 0)
	end
	
	local opportunity_los		= mod.check_line_of_sight(self_unit, opportunity_enemy)
	local urgent_flanking		= mod.check_alignment_to_target(self_unit, urgent_enemy)
	local urgent_bb				= BLACKBOARDS[urgent_enemy]
	local urgent_targeting_me	= (urgent_bb and urgent_bb.target_unit == self_unit) or false
	
	local active_bots			= Managers.player:bots()
	local bot_count				= #active_bots
		
	local blackboard			= self._blackboard
	local inventory_extension = blackboard.inventory_extension
	local ranged_slot_data = inventory_extension:get_slot_data("slot_ranged")
	local ranged_slot_template = inventory_extension:get_item_template(ranged_slot_data)
	local ranged_slot_name = ranged_slot_template.name
	-- local sniper_target_selection = mod.stop_trash_shooting_ranged[ranged_slot_name]
	local sniper_target_selection = mod.sniper_selection_ranged[ranged_slot_name]
	
	-- reload ranged weapon if idle and reload is needed
	-- if not blackboard.breakable_object then
		-- if mod.heat_weapon[ranged_slot_name] then
			-- vent_bot_ranged_weapon(d, false)
		-- else
			-- reload_bot_ranged_weapon(self_unit, blackboard)
		-- end
	-- end
	
	--switch to melee if needed
	-- if not blackboard.breakable_object then
		-- local ranged_equipped = inventory_extension and inventory_extension:get_wielded_slot_name() == "slot_ranged"
		-- local melee_equipped = inventory_extension and inventory_extension:get_wielded_slot_name() == "slot_melee"
		-- local ally_needs_pickup	= blackboard.target_ally_need_type == "knocked_down" or blackboard.target_ally_need_type == "ledge" or blackboard.target_ally_need_type == "hook"
		-- local may_switch = blackboard.target_unit == nil and (ranged_equipped or melee_equipped) and not ally_needs_pickup
		-- local need_reload = true
		
		-- if mod.heat_weapon[ranged_slot_name] then
			-- local condition_args = {
				-- start_min_percentage = 0.5,
				-- start_max_percentage = 0.99,
				-- stop_percentage = 0.1,
				-- overcharge_limit_type = "threshold"
			-- }
			
			-- need_reload = BTConditions.should_vent_overcharge(blackboard, condition_args)
		-- else
			-- need_reload = BTConditions.should_reload_weapon(blackboard, nil)
		-- end
		
		-- if may_switch and not need_reload and ranged_equipped and not blackboard.reloading then
			-- blackboard.input_extension:wield("slot_melee")
		-- end
	-- end
	
	-- check that the current target exists and is alive
	local target_alive = mod.is_unit_alive(blackboard.target_unit)
	if not target_alive then
		blackboard.target_unit = nil
	end
	
	-- process mod.swarm_projectile_list
	local closest_swarm_projectile = {
		unit = nil,
		distance = math.huge
	}
		
	for loop_unit, _ in pairs(mod.swarm_projectile_list) do
		if not Unit.alive(loop_unit) then
			mod.swarm_projectile_list[loop_unit] = nil
		else
			local loop_locomotion_extension = ScriptUnit.extension(loop_unit, "projectile_locomotion_system")
			-- local loop_pos = Unit.local_position(loop_unit, 0) or POSITION_LOOKUP[loop_unit]
			local loop_pos = (loop_locomotion_extension and loop_locomotion_extension:current_position()) or POSITION_LOOKUP[loop_unit]
			local loop_offset = pos and loop_pos and loop_pos - pos
			local loop_dist	= loop_offset and Vector3.length(loop_offset)
			
			if loop_dist and loop_dist < closest_swarm_projectile.distance then
				closest_swarm_projectile.unit = loop_unit
				closest_swarm_projectile.distance = loop_dist
			end
		end
	end

	local prox_enemies			= mod.get_proximite_enemies(self_unit, 20, 3.8)
	local num_prox_enemies		= #prox_enemies
	-- near_enemies
	
	local is_shade_in_invis = is_shade_in_invis(career_name, self_unit)
	local furhter_logic = false
	if is_shade_in_invis then
		local has_urgent_boss = urgent_enemy and Unit.get_data(urgent_enemy, "breed") and Unit.get_data(urgent_enemy, "breed").boss
		
		if has_urgent_boss and urgent_enemy_dist < 10 then
			bb.target_unit = urgent_enemy
		elseif priority_enemy and prio_enemy_dist < 10 then		--4.5	--5		--3
			bb.target_unit = priority_enemy
		else
			furhter_logic = true
		end
		
		goto choose_nice_target
	end
	
	--switch order of urgent_enemy (bosses & lords) and opportunity_enemy (specials)
	if priority_enemy and prio_enemy_dist < 10 then		--4.5	--5		--3
		bb.target_unit = priority_enemy
	elseif closest_swarm_projectile.unit and closest_swarm_projectile.distance < 3 then
		bb.target_unit = closest_swarm_projectile.unit
	elseif opportunity_enemy and opp_enemy_dist < 3 then
		bb.target_unit = opportunity_enemy
	-- elseif urgent_enemy and urgent_enemy_dist < 3 then
		-- bb.target_unit = urgent_enemy
	elseif slot_enemy and slot_enemy_dist < 3 then
		bb.target_unit = slot_enemy
	elseif prox_enemy and prox_enemy_dist < 2 then
		bb.target_unit = prox_enemy
	elseif prox_enemy and bb.proximity_target_is_player and prox_enemy_dist < 10 then	-- seems to be versus mode stuff
		bb.target_unit = prox_enemy
	elseif priority_enemy then
		bb.target_unit = priority_enemy
	elseif opportunity_enemy and opportunity_los then
		bb.target_unit = opportunity_enemy
	elseif urgent_enemy and (num_near_enemies < 3 or (urgent_enemy_dist < 5 and not urgent_flanking) or (urgent_enemy_dist < 7 and urgent_targeting_me)) then
		bb.target_unit = urgent_enemy
	else
		furhter_logic = true
	end
	
	::choose_nice_target::
	
	if furhter_logic then
		-- elseif slot_enemy then
			-- bb.target_unit = slot_enemy
		-- elseif bb.target_unit then
			-- bb.target_unit = nil
		-- end
		
		local separation_check_units = {}
		local players = Managers.player:players()
		for _, loop_player in pairs(players) do
			local loop_unit	= loop_player.player_unit
			local loop_pos	= POSITION_LOOKUP[loop_unit]
			local loop_dist	= self_pos and loop_pos and Vector3.distance(self_pos, loop_pos)
			-- if loop_dist and loop_dist < 7 and Unit.alive(loop_unit) then
			if loop_dist and loop_dist < 7 and mod.is_unit_alive(loop_unit) then
				table.insert(separation_check_units, loop_unit)
			end
		end

		-- determine the closest trash rat / stormvermin
		local separation_threat	=
		{
			unit = nil,
			distance = math.huge,
			human = false
		}
		local closest_trash	=
		{
			unit = nil,
			distance = math.huge
		}
		local closest_elite =
		{
			unit = nil,
			distance = math.huge
		}
		
		-- check proximite enemies
		for _, loop_unit in pairs(prox_enemies) do
			local loop_breed		= Unit.get_data(loop_unit, "breed")
			local loop_blackboard	= BLACKBOARDS[loop_unit]
			local loop_pos			= POSITION_LOOKUP[loop_unit]
			local loop_offset		= pos and loop_pos and loop_pos - pos
			local loop_dist			= loop_offset and Vector3.length(loop_offset)
			local loop_dist_self	= self_pos and loop_pos and Vector3.distance(self_pos, loop_pos)
			local height_modifier	= (math.abs(loop_offset.z) > 0.2 and math.abs(loop_offset.z)*0.75) or 0
			local loop_is_after_me	= loop_blackboard and (loop_blackboard.target_unit == self_unit or loop_blackboard.attacking_target == self_unit or is_shade_in_invis)
			
			-- add some extra to the check distance of enemies that are far away from other players
			-- to encourage the bots not to spread out too wide
			for _,player in pairs(players) do
				local loop2_unit = player.player_unit
				-- if Unit.alive(loop2_unit) then
				if mod.is_unit_alive(loop2_unit) then
					local loop2_pos = POSITION_LOOKUP[loop2_unit]
					local loop2_dist = (loop2_pos and loop_pos and Vector3.length(loop2_pos - loop_pos)) or 0
					loop_dist = loop_dist + math.max((loop2_dist*0.05),0)
				end
			end
			
			if loop_dist and loop_blackboard and loop_blackboard.target_unit then
				if (mod.TRASH_UNITS[loop_breed.name] and (not assigned_enemies[loop_unit] or assigned_enemies[loop_unit] == self_unit or num_prox_enemies < bot_count or loop_is_after_me)) or (loop_breed.name == "skaven_loot_rat" and loop_dist < 5) then
					-- ** trash rats **
					-- if this bot has anti-armor weapon then it should try to avoid unarmored targets if armored ones are close
					-- if self_anti_armor then loop_dist = loop_dist +1 end
					
					-- if the target is above / below past a threashold then it should be less attractive than targets on the same plane.
					loop_dist = loop_dist + height_modifier
					
					if loop_blackboard.attacking_target == self_unit and not loop_blackboard.past_damage_in_attack then
						loop_dist = loop_dist - 0.5		--1
					end
					
					--
					if loop_dist < closest_trash.distance then
						closest_trash.unit		= loop_unit
						closest_trash.distance	= loop_dist
					end
				-- elseif mod.ELITE_UNITS[loop_breed.name] or mod.BERSERKER_UNITS[loop_breed.name] then
				elseif (mod.ELITE_UNITS[loop_breed.name] or mod.BERSERKER_UNITS[loop_breed.name]) and (not assigned_enemies[loop_unit] or assigned_enemies[loop_unit] == self_unit or num_prox_enemies < bot_count or loop_is_after_me) then
					-- ** stormvermin **
					-- if this bot does not have anti-armor weapon then it should try to avoid armored targets if unarmored ones are close
					-- if not self_anti_armor then loop_dist = loop_dist +1 end
					
					-- if the target is above / below past a threashold then it should be less attractive than targets on the same plane.
					loop_dist = loop_dist + height_modifier
					--
					if loop_dist < closest_elite.distance then
						closest_elite.unit		= loop_unit
						closest_elite.distance	= loop_dist
					end
				end	-- specials / ogres are handled separately
			end
				
			-- find group separation threats
			-- separation threat can be any non-boss enemy unit that is positioned between team members
			for _, separation_check_unit in pairs(separation_check_units) do
				if (not mod.BOSS_UNITS[loop_breed.name]) and (not mod.LORD_UNITS[loop_breed.name]) and loop_dist_self < separation_threat.distance then
					local is_separation_threat = is_positioned_between_self_and_ally(self_unit, separation_check_unit, loop_unit)
					if is_separation_threat then
						separation_threat.unit		= loop_unit
						separation_threat.distance	= loop_dist_self
					end
				end
			end
		end
		
		-- if not sniper_target_selection and separation_threat.unit then
		if not is_shade_in_invis then 
			if separation_threat.unit and separation_threat.distance < 3.5 then
				blackboard.target_unit = separation_threat.unit
			elseif sniper_target_selection and closest_elite.unit and (closest_trash.distance > 3 or closest_trash.distance > closest_elite.distance) then	--3.5
				blackboard.target_unit = closest_elite.unit
			elseif closest_trash.unit or closest_elite.unit then
				if closest_trash.distance < closest_elite.distance then
					blackboard.target_unit = closest_trash.unit
				else
					blackboard.target_unit = closest_elite.unit
				end
			elseif slot_enemy then
				blackboard.target_unit = slot_enemy
			elseif urgent_enemy then
				blackboard.target_unit = urgent_enemy
			elseif blackboard.target_unit then
				blackboard.target_unit = nil
			end
		else
			local closest_elite_is_cw = closest_elite.unit and Unit.get_data(closest_elite.unit, "breed") and Unit.get_data(closest_elite.unit, "breed").name == "chaos_warrior"
			
			if closest_elite_is_cw and closest_elite.distance < 10 then
				blackboard.target_unit = closest_elite.unit
			elseif opportunity_enemy and opp_enemy_dist < 8 then
				blackboard.target_unit = opportunity_enemy
			elseif closest_elite.unit and closest_elite.distance < 8 then
				blackboard.target_unit = closest_elite.unit
			elseif separation_threat.unit and separation_threat.distance < 3.5 then
				blackboard.target_unit = separation_threat.unit
			elseif urgent_enemy and urgent_enemy_dist < 10 then
				blackboard.target_unit = urgent_enemy
			elseif closest_trash.unit or closest_elite.unit then
				if closest_trash.distance < closest_elite.distance then
					blackboard.target_unit = closest_trash.unit
				else
					blackboard.target_unit = closest_elite.unit
				end
			elseif slot_enemy then
				blackboard.target_unit = slot_enemy
			elseif urgent_enemy then
				blackboard.target_unit = urgent_enemy
			elseif blackboard.target_unit then
				blackboard.target_unit = nil
			end
		end
	end
	
	-- clean assigned enemies table
	-- make sure there is no enemies that are assigned to non-active bots (happens when player joins mid combat)
	for key,assigned_unit in pairs(assigned_enemies) do
		if assigned_unit == self_unit then
			assigned_enemies[key] = nil
		else
			local assigned_to_inactive_bot = true
			for _, loop_owner in pairs(active_bots) do
				local loop_unit			= loop_owner.player_unit
				-- local loop_d			= get_d_data(loop_unit)
				
				-- local loop_is_disabled	= not loop_d or loop_d.disabled
				local status_extension = ScriptUnit.has_extension(loop_unit, "status_system")
				local loop_is_disabled = (status_extension and status_extension:is_disabled()) or false
				
				if assigned_unit == loop_unit and not loop_is_disabled then
					assigned_to_inactive_bot = false
					break
				end
			end
			
			-- the enemy has disabled bot assigned to it >> remove the assignement
			if assigned_to_inactive_bot then
				assigned_enemies[key] = nil
			end
		end
	end
	
	-- assign self to current target enemy
	if blackboard.target_unit then
		assigned_enemies[blackboard.target_unit] = self_unit
	end
	
	-- added a bit
	if mod.components.ping_enemies.value then
		mod.components.ping_enemies.attempt_ping_enemy(self._blackboard)
	end
end)
--]]



mod:hook_origin(SimpleInventoryExtension, "current_ammo_status", function (self, slot_name)
	local slot_data = self._equipment.slots[slot_name]

	if not slot_data then
		return
	end

	local item_data = slot_data.item_data
	local item_template = slot_data.item_template or BackendUtils.get_item_template(item_data)
	local ammo_data = item_template.ammo_data

	if ammo_data then
		local right_unit = slot_data.right_unit_1p
		local left_unit = slot_data.left_unit_1p
		local ammo_extension = GearUtils.get_ammo_extension(right_unit, left_unit)

		if ammo_extension then
			local remaining_ammo = ammo_extension:total_remaining_ammo()
			local max_ammo = ammo_extension:max_ammo()
			local ammo_in_clip = ammo_extension:ammo_count()
			local clip_size = ammo_extension:clip_size()
			
			return remaining_ammo, max_ammo, ammo_in_clip, clip_size
		end
	end
end)

mod:hook(BTConditions, "has_target_and_ammo_greater_than", function(func, blackboard, args)
	local career_extension = blackboard.career_extension
	local career_name = career_extension:career_name()
	local target_unit = blackboard.target_unit

	if not ALIVE[target_unit] then
		return false
	end

	local breed = Unit.get_data(target_unit, "breed")

	if breed == nil then
		return false
	end

	local inventory_extension = blackboard.inventory_extension
	local ranged_slot_data = inventory_extension:get_slot_data("slot_ranged")
	local ranged_slot_template = inventory_extension:get_item_template(ranged_slot_data)
	local ranged_slot_name = ranged_slot_template.name
	local ranged_slot_buff_type = ranged_slot_template and ranged_slot_template.buff_type
	local is_ranged = RangedBuffTypes[ranged_slot_buff_type]

	if not is_ranged then
		return false
	end

	local target_buff_extension = ScriptUnit.has_extension(target_unit, "buff_system")

	if target_buff_extension and target_buff_extension:has_buff_perk("invulnerable_ranged") then
		return false
	end
	
	if blackboard.ranged_combat_preferred then
		return true
	end
	
	if mod.stop_trash_shooting_ranged[ranged_slot_name] and mod.TRASH_UNITS_EXCEPT_ARCHERS[breed.name] and not blackboard.ranged_combat_preferred then
		return false
	end
	
	local current, max = inventory_extension:current_ammo_status("slot_ranged")
	local ammo_ok = not current or args.ammo_percentage < current / max
	local overcharge_extension = blackboard.overcharge_extension
	local overcharge_limit_type = args.overcharge_limit_type
	local current_oc, threshold_oc, max_oc = overcharge_extension:current_overcharge_status()
	local overcharge_ok = current_oc == 0 or (overcharge_limit_type == "threshold" and current_oc / threshold_oc < args.overcharge_limit) or (overcharge_limit_type == "maximum" and current_oc / max_oc < args.overcharge_limit)
	local obstruction = blackboard.ranged_obstruction_by_static
	local t = Managers.time:time("game")
	local obstructed = obstruction and obstruction.unit == blackboard.target_unit and t <= obstruction.timer + 0.3	--0.2	--0.5	--1	--3
	local effective_target = AiUtils.has_breed_categories(breed.category_mask, ranged_slot_template.attack_meta_data.effective_against_combined)
	
	-- local ret = ammo_ok and overcharge_ok and not obstructed and effective_target
	local ret = ammo_ok and overcharge_ok and not obstructed and (effective_target or blackboard.ranged_combat_preferred)
	
	if career_name == "we_waywatcher" then
		--mod:echo(current and current / max or nil)
	end
	
	local patrol_in_firing_cone = false
	
	if ret then
		-- check that there is no patrol rats marching on the background
		
		local ai_group_system = Managers.state.entity:system("ai_group_system")
		local self_unit = blackboard.unit
		local self_pos = POSITION_LOOKUP[self_unit]
		
		if ai_group_system.groups_to_update then
			for id, group in pairs(ai_group_system.groups_to_update) do
				if group.group_type == "spline_patrol" and group.members then
					for patrol_unit, extension in pairs(group.members) do
						local patrol_blackboard	= patrol_unit and BLACKBOARDS[patrol_unit]
						local patrol_target		= patrol_blackboard and patrol_blackboard.target_unit
						local patrol_pos		= POSITION_LOOKUP[patrol_unit]
						local patrol_dist		= self_pos and patrol_pos and Vector3.length(patrol_pos - self_pos)
						-- local patrol_has_target	= patrol_target and Unit.alive(patrol_target)
						local patrol_has_target	= patrol_target and mod.is_unit_alive(patrol_target)
						
						if patrol_dist and patrol_dist < 50 and is_secondary_within_cone(self_unit, target_unit, patrol_unit, 5) and not patrol_has_target then	--80, 15	--60, 20
							patrol_in_firing_cone = true
							break
						end
					end
				end
			end
		end
	end
	
	--if career_name == "bw_adept" and not ret then
		--mod:echo("not allowed")
	--end
	
	return ret and not patrol_in_firing_cone
end)




--[[
BotActions.default.shoot_ability.charge_input = "defend"
BotActions.default.shoot_ability.fire_input = "activate_ability"

local switch_melee = {
	"BTBotInventorySwitchAction",
	name = "switch_melee",
	condition = "is_slot_not_wielded",
	condition_args = {
		"slot_melee",
		"slot_career_skill_weapon"
	},
	action_data = BotActions.default.switch_melee
}

local weapon_swap = {
	"BTSelector",
	{
		"BTBotInventorySwitchAction",
		name = "switch_alt_melee",
		condition = "has_better_alt_weapon",
		condition_args = {
			"slot_melee",
			"slot_ranged"
		},
		action_data = BotActions.default.switch_ranged
	},
	{
		"BTBotInventorySwitchAction",
		name = "switch_melee",
		condition = "is_slot_not_wielded",
		condition_args = {
			"slot_melee"
		},
		action_data = BotActions.default.switch_melee
	},
	name = "pick_weapon_slot",
	condition = "needs_weapon_swap",
	condition_args = {
		"slot_melee",
		"slot_ranged"
	}
}

local drinking_potions_was_added = (mod.components.drinking_potions.value == ON)
local branch_index_ability_shoot = drinking_potions_was_added and 16 or 15
table.insert(BotBehaviors.default[branch_index_ability_shoot], 2, switch_melee)

local copy_data = mod.utility.copy_data
local branch_index_swap_melee = drinking_potions_was_added and 17 or 16
copy_data(BotBehaviors.default[branch_index_swap_melee][3][2], weapon_swap)
--]]




