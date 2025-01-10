local mod = get_mod("ReplicantTemp")

mod.components = {
	ping_enemies = {}, --
	aggro_tweaks = {}, --
	activate_abilities_tweaks = {},
	rescue_allies_active_ability = {}, --
	regular_active_abilities = {}, --
	self_heal_threshold = {}, --
	self_heal_threshold_nb = {}, --
	self_heal_threshold_zealot = {}, --
	others_heal_threshold = {}, --
	others_heal_threshold_zealot = {}, --
	improved_revive = {}, --
	pickup_tweaks = {}, --
	ignore_lof = {}, --
	stop_chasing = {}, --
	ignore_bosses = {}, --
	overcharge_tweaks = {}, --
	drinking_potions = {}, --
	zealot_bot_six_stacks = {}, --
	melee_choices = {}, --
	reload_tweaks = {}, --
	
	bot_info_guard_break = {}, --
}

for component, data in pairs(mod.components) do
	data.name = component
	data.value = mod:get(component)
	data.synchronize = function(self)
		self.value = mod:get(self.name)
	end
end

mod.components.regular_active_abilities.detailed_settings = {
	es_mercenary = true,
	es_huntsman = true,
	es_knight = true,
	es_questingknight = true,
	dr_ranger = true,
	dr_ironbreaker = true,
	dr_slayer = true,
	dr_engineer = true,
	we_waywatcher = true,
	we_maidenguard = true,
	we_shade = true,
	we_thornsister = true,
	wh_captain = true,
	wh_bountyhunter = true,
	wh_zealot = true,
	wh_priest = true,
	bw_adept = true,
	bw_scholar = true,
	bw_unchained = true
}

mod.components.regular_active_abilities.synchronize = function(self)
	self.value = mod:get(self.name)
	
	if self.value == mod.bot_abilities_settings.DISABLE_ALL then
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = false
		end
	elseif self.value == mod.bot_abilities_settings.MANUAL_SETTING then
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = mod:get(career_name)
		end
	else
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = true
		end
	end
end

mod.components.regular_active_abilities:synchronize()

mod.components_data = {}

local ON = true
local OFF = false

local copy_data = mod.utility.copy_data

mod.components.melee_choices.detailed_settings = {
	es_mercenary_m = 3,
	es_huntsman_m = 3,
	es_knight_m = 3,
	es_questingknight_m = 3,
	dr_ranger_m = 3,
	dr_ironbreaker_m = 3,
	dr_slayer_m = 3,
	dr_engineer_m = 3,
	we_waywatcher_m = 3,
	we_maidenguard_m = 3,
	we_shade_m = 3,
	we_thornsister_m = 3,
	wh_captain_m = 3,
	wh_bountyhunter_m = 3,
	wh_zealot_m = 3,
	wh_priest_m = 3,
	bw_adept_m = 3,
	bw_scholar_m = 3,
	bw_unchained_m = 3
}

mod.components.melee_choices.synchronize = function(self)
	self.value = mod:get(self.name)
	
	if self.value == mod.melee_settings.default then
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = 1
		end
	elseif self.value == mod.melee_settings.as_in_BI_C then
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = 2
		end
	elseif self.value == mod.melee_settings.my_settings then
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = 3
		end
	else
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = mod:get(career_name)
		end
	end
end

mod.components.melee_choices:synchronize()

mod.components_data.reload_tweaks = {
	modded = {
		ammo_percentage_threshold = 0.99
	},
	unmodded = {
		ammo_percentage_threshold = 0.2
	}
}

mod.components.reload_tweaks.change_game_data = function(self)
	if self.value == ON then
		local drinking_potions_was_added = (mod.components.drinking_potions.value == ON)
		local branch_index = drinking_potions_was_added and 19 or 18
		--BotBehaviors.default[branch_index][3][7].condition_args.ammo_percentage_threshold = mod.components_data.reload_tweaks.modded.ammo_percentage_threshold
	else
		local drinking_potions_was_added = (mod.components.drinking_potions.value == ON)
		local branch_index = drinking_potions_was_added and 19 or 18
		--BotBehaviors.default[branch_index][3][7].condition_args.ammo_percentage_threshold = mod.components_data.reload_tweaks.unmodded.ammo_percentage_threshold
	end
end

--[[mod.components_data.revive_action = {
	"BTBotInteractAction",
	name = "do_revive",
	action_data = BotActions.default.revive
}

mod.components_data.revive_ability_action = {
	"BTBotActivateAbilityAction",
	name = "use_ability",
	condition = "can_activate_ability_revive",
	condition_args = {
		"activate_ability"
	},
	action_data = BotActions.default.use_ability
}

mod.components.improved_revive.change_game_data = function(self)
	if self.value == ON then
		BotBehaviors.default[3][3] = revive_ability_action
		BotBehaviors.default[3][4] = revive_action
	else
		BotBehaviors.default[3][3] = revive_action
		BotBehaviors.default[3][4] = nil
	end
end--]]

--[[
mod.components = {
	ping_enemies = {}, --
	aggro_tweaks = {}, --
	activate_abilities_tweaks = {},
	rescue_allies_active_ability = {}, --
	regular_active_abilities = {}, --
	self_heal_threshold = {}, --
	self_heal_threshold_nb = {}, --
	self_heal_threshold_zealot = {}, --
	others_heal_threshold = {}, --
	others_heal_threshold_zealot = {}, --
	improved_revive = {}, --
	pickup_tweaks = {}, --
	ignore_lof = {}, --
	stop_chasing = {}, --
	ignore_bosses = {}, --
	overcharge_tweaks = {}, --
	drinking_potions = {}, --
	zealot_bot_six_stacks = {}, --
	melee_choices = {}, --
	reload_tweaks = {} --
}

for component, data in pairs(mod.components) do
	data.name = component
	data.value = mod:get(component)
	data.synchronize = function(self)
		self.value = mod:get(self.name)
	end
end

mod.components.regular_active_abilities.detailed_settings = {
	es_mercenary = true,
	es_huntsman = true,
	es_knight = true,
	es_questingknight = true,
	dr_ranger = true,
	dr_ironbreaker = true,
	dr_slayer = true,
	we_waywatcher = true,
	we_maidenguard = true,
	we_shade = true,
	we_thornsister = true,
	wh_captain = true,
	wh_bountyhunter = true,
	wh_zealot = true,
	bw_adept = true,
	bw_scholar = true,
	bw_unchained = true
}

mod.components.regular_active_abilities.synchronize = function(self)
	self.value = mod:get(self.name)
	
	if self.value == mod.bot_abilities_settings.DISABLE_ALL then
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = false
		end
	elseif self.value == mod.bot_abilities_settings.MANUAL_SETTING then
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = mod:get(career_name)
		end
	else
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = true
		end
	end
end

mod.components.regular_active_abilities:synchronize()

mod.components_data = {}

local ON = true
local OFF = false

local copy_data = mod.utility.copy_data

mod.components_data.use_ability_unmodded = {
	dr_ironbreaker = {
		activation = {},
		wait_action = {
			input = "defend"
		},
		end_condition = {
			buffs = {
				"bardin_ironbreaker_activated_ability",
				"bardin_ironbreaker_activated_ability_duration"
			}
		}
	},
	dr_slayer = {
		activation = {
			action = "aim_at_target"
		}
	},
	dr_ranger = {
		activation = {},
		end_condition = {
			is_slot_not_wielded = {
				"slot_career_skill_weapon"
			}
		}
	},
	dr_engineer = {
		activation = {},
		end_condition = {}
	},
	es_mercenary = {
		activation = {}
	},
	es_huntsman = {
		activation = {},
		end_condition = {
			done_when_arriving_at_destination = true,
			buffs = {
				"markus_huntsman_activated_ability"
			}
		}
	},
	es_knight = {
		activation = {
			action = "aim_at_target"
		}
	},
	es_questingknight = {
		activation = {
			max_distance_sq = 20,
			move_to_target_unit = true,
			dynamic_target_unit = true,
			action = "aim_at_target"
		},
		end_condition = {
			is_slot_not_wielded = {
				"slot_career_skill_weapon"
			}
		}
	},
	we_waywatcher = {},
	we_maidenguard = {
		activation = {
			action = "aim_at_target"
		}
	},
	we_thornsister = {
		activation = {
			action = "aim_at_target",
			fast_aim = true
		}
	},
	wh_captain = {
		activation = {}
	},
	wh_bountyhunter = {},
	wh_zealot = {
		activation = {
			action = "aim_at_target"
		}
	},
	we_shade = {
		activation = {},
		end_condition = {
			done_when_arriving_at_destination = true,
			buffs = {
				"kerillian_shade_activated_ability",
				"kerillian_shade_activated_ability_duration"
			}
		}
	},
	bw_adept = {
		activation = {
			action = "aim_at_target",
			min_hold_time = 0.2
		}
	},
	bw_scholar = {},
	bw_unchained = {
		activation = {}
	},
	name = "use_ability",
	considerations = UtilityConsiderations["player_bot_default_use_ability"] or nil
}

mod.components_data.use_ability_modded = {
	dr_ironbreaker = {
		activation = {}
	},
	dr_slayer = {
		activation = {
			action = "aim_at_target"
		}
	},
	dr_ranger = {
		activation = {},
		end_condition = {
			is_slot_not_wielded = {
				"slot_career_skill_weapon"
			}
		}
	},
	dr_engineer = {
		activation = {},
		end_condition = {}
	},
	es_mercenary = {
		activation = {}
	},
	es_huntsman = {
		activation = {},
		end_condition = {
			done_when_arriving_at_destination = true,
			buffs = {
				"markus_huntsman_activated_ability"
			}
		}
	},
	es_knight = {
		activation = {
			action = "aim_at_target"
		},
		end_condition = {
			stop_when_destination_reached = true
		}
	},
	es_questingknight = {
		activation = {
			max_distance_sq = 20,
			move_to_target_unit = true,
			dynamic_target_unit = true,
			action = "aim_at_target",
			fast_aim = true
		},
		end_condition = {
			is_slot_not_wielded = {
				"slot_career_skill_weapon"
			}
		}
	},
	we_waywatcher = {
		activation = {},
		end_condition = {
			is_slot_not_wielded = {
				"slot_career_skill_weapon"
			}
		}
	},
	we_maidenguard = {
		activation = {
			action = "aim_at_target"
		},
		end_condition = {
			stop_when_destination_reached = true
		}
	},
	we_shade = {
		activation = {
			move_to_target_unit = true,
			dynamic_target_unit = true
		},
		end_condition = {
			done_when_arriving_at_destination = true,
			buffs = {
				"kerillian_shade_activated_ability",
				"kerillian_shade_activated_ability_duration"
			}
		}
		-- default = {
			-- activation = {
				-- max_distance_sq = 25,
				-- move_to_target_unit = true,
				-- dynamic_target_unit = true,
				-- action = "aim_at_target",
				-- fast_aim = true
			-- },
			-- end_condition = {
				-- buffs = {
					-- "kerillian_shade_activated_ability",
					-- "kerillian_shade_activated_ability_duration"
				-- }
			-- }
		-- },
		-- kerillian_shade_activated_stealth_combo = {
			-- activation = {
				-- max_distance_sq = 25,
				-- move_to_target_unit = true,
				-- dynamic_target_unit = true,
				-- action = "aim_at_target",
				-- fast_aim = true
			-- },
			-- end_condition = {
				-- buffs = {
					-- "kerillian_shade_activated_ability",
					-- "kerillian_shade_activated_ability_duration"
				-- }
			-- }
		-- },
		-- kerillian_shade_activated_ability_phasing = {
			-- activation = {
				-- max_distance_sq = 25,
				-- move_to_target_unit = true,
				-- dynamic_target_unit = true,
				-- action = "aim_at_target",
				-- fast_aim = true
			-- },
			-- end_condition = {
				-- buffs = {
					-- "kerillian_shade_activated_ability",
					-- "kerillian_shade_activated_ability_duration"
				-- }
			-- }
		-- },
		-- kerillian_shade_activated_ability_restealth = {
			-- activation = {
				-- max_distance_sq = 25,
				-- move_to_target_unit = true,
				-- dynamic_target_unit = true,
				-- action = "aim_at_target",
				-- fast_aim = true
			-- },
			-- end_condition = {
				-- buffs = {
					-- "kerillian_shade_activated_ability",
					-- "kerillian_shade_activated_ability_duration"
				-- }
			-- }
		-- },
		-- talent_difference = true
	},
	we_thornsister = {
		activation = {
			action = "aim_at_target",
			fast_aim = true
		}
	},
	wh_captain = {
		activation = {
			move_to_target_unit = true,
			dynamic_target_unit = true,
		},
		end_condition = {
			done_when_arriving_at_destination = true,
			buffs = {
				"victor_witchhunter_activated_ability_crit_buff",
				"victor_witchhunter_activated_ability_guaranteed_crit_self_buff"
			}
		}
	},
	wh_bountyhunter = {
		activation = {},
		end_condition = {
			is_slot_not_wielded = {
				"slot_career_skill_weapon"
			}
		}
	},
	wh_zealot = {
		activation = {
			action = "aim_at_target"
		},
		end_condition = {
			stop_when_destination_reached = true
		}
	},
	bw_adept = {
		activation = {
			action = "aim_at_target",
			min_hold_time = 0.2
		}
	},
	bw_scholar = {
		activation = {},
		end_condition = {
			is_slot_not_wielded = {
				"slot_career_skill_weapon"
			}
		}
	},
	bw_unchained = {
		activation = {}
	},
	name = "use_ability",
	considerations = UtilityConsiderations["player_bot_default_use_ability"] or nil
}

mod.components_data.shoot_ability = {
	modded = {
		evaluation_duration = 0.2,
		evaluation_duration_without_firing = 0.3
	},
	unmodded = {
		evaluation_duration = 2,
		evaluation_duration_without_firing = 4
	}
}

mod.components.activate_abilities_tweaks.change_game_data = function(self)
	if self.value == ON then
		copy_data(mod.components_data.use_ability_modded, BotActions.default.use_ability)
		BotActions.default.shoot_ability.evaluation_duration = mod.components_data.shoot_ability.modded.evaluation_duration
		BotActions.default.shoot_ability.evaluation_duration_without_firing = mod.components_data.shoot_ability.modded.evaluation_duration_without_firing
	else
		copy_data(mod.components_data.use_ability_unmodded, BotActions.default.use_ability)
		BotActions.default.shoot_ability.evaluation_duration = mod.components_data.shoot_ability.unmodded.evaluation_duration
		BotActions.default.shoot_ability.evaluation_duration_without_firing = mod.components_data.shoot_ability.unmodded.evaluation_duration_without_firing
	end
end

mod.components_data.switch_potion = {
	modded = {
		action_weight = 1
	},
	unmodded = {
		action_weight = nil
	}
}

mod.components_data.drink_potion_action = {
	"BTSelector",
	{
		"BTBotInventorySwitchAction",
		name = "switch_potion",
		condition = "is_slot_not_wielded",
		condition_args = {
			"slot_potion"
		},
		action_data = BotActions.default.switch_potion
	},
	{
		"BTBotDrinkPotAction",
		name = "drink_potion"
	},
	condition = "bot_should_drink_buff_potion",
	name = "drink_buff_potion"
}

mod.components.drinking_potions.change_game_data = function(self)
	if self.value == ON then
		table.insert(BotBehaviors.default, 14, mod.components_data.drink_potion_action)
		BotActions.default.switch_potion.action_weight = mod.components_data.switch_potion.modded.action_weight
	else
		table.remove(BotBehaviors.default, 14)
		BotActions.default.switch_potion.action_weight = mod.components_data.switch_potion.unmodded.action_weight
	end
end

mod.components.melee_choices.detailed_settings = {
	es_mercenary_m = 3,
	es_huntsman_m = 3,
	es_knight_m = 3,
	es_questingknight_m = 3,
	dr_ranger_m = 3,
	dr_ironbreaker_m = 3,
	dr_slayer_m = 3,
	we_waywatcher_m = 3,
	we_maidenguard_m = 3,
	we_shade_m = 3,
	we_thornsister_m = 3,
	wh_captain_m = 3,
	wh_bountyhunter_m = 3,
	wh_zealot_m = 3,
	wh_priest_m = 3,
	bw_adept_m = 3,
	bw_scholar_m = 3,
	bw_unchained_m = 3
}

mod.components.melee_choices.synchronize = function(self)
	self.value = mod:get(self.name)
	
	if self.value == mod.melee_settings.default then
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = 1
		end
	elseif self.value == mod.melee_settings.as_in_BI_C then
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = 2
		end
	elseif self.value == mod.melee_settings.my_settings then
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = 3
		end
	else
		for career_name, _ in pairs(self.detailed_settings) do
			self.detailed_settings[career_name] = mod:get(career_name)
		end
	end
end

mod.components.melee_choices:synchronize()

mod.components_data.reload_tweaks = {
	modded = {
		ammo_percentage_threshold = 0.99
	},
	unmodded = {
		ammo_percentage_threshold = 0.2
	}
}

mod.components.reload_tweaks.change_game_data = function(self)
	if self.value == ON then
		local drinking_potions_was_added = (mod.components.drinking_potions.value == ON)
		local branch_index = drinking_potions_was_added and 19 or 18
		BotBehaviors.default[branch_index][3][7].condition_args.ammo_percentage_threshold = mod.components_data.reload_tweaks.modded.ammo_percentage_threshold
	else
		local drinking_potions_was_added = (mod.components.drinking_potions.value == ON)
		local branch_index = drinking_potions_was_added and 19 or 18
		BotBehaviors.default[branch_index][3][7].condition_args.ammo_percentage_threshold = mod.components_data.reload_tweaks.unmodded.ammo_percentage_threshold
	end
end
--]]

