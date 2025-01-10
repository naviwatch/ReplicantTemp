local mod = get_mod("ReplicantTemp")

mod.heal_constants = {
	IS_OK = 0,
	HURT = 1,
	SERIOUSLY_HURT = 2,
	WOUNDED = 3,
	WOUNDED_AND_LOW = 4,
	EXTRA_HEAL_AVAILABLE = 5,
	WAIT_HEAL_FROM_OTHERS = 6,
	NO_HEAL = 7,
	AS_OTHERS = -1,
	ITEM_DEPENDENT = 0.5,
}

mod.bot_abilities_settings = {
	DISABLE_ALL = -1,
	MANUAL_SETTING = 0,
	ENABLE_ALL = 1
}

mod.melee_settings = {
	default = 1,
	as_in_BI_C = 2,
	my_settings = 3,
	MANUAL_SETTING = 4
}

mod.guard_break_settings = {
	none = 1,
	host = 2,
	global = 3,
}

return {
	name = "Replicant Bots - Different Bots Experimental Branch",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "melee_choices",
				type = "dropdown",
				tooltip = "melee_settings_description",
				options = {
					{text = "default", value = mod.melee_settings.default},
					{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
					{text = "my_settings", value = mod.melee_settings.my_settings},
					{text = "manual_setting", value = mod.melee_settings.MANUAL_SETTING, show_widgets = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }},
				},
				sub_widgets = {
					{
						setting_id = "es_mercenary_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "es_huntsman_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "es_knight_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "es_questingknight_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "dr_ranger_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "dr_ironbreaker_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "dr_slayer_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "dr_engineer_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "we_waywatcher_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "we_maidenguard_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "we_shade_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "we_thornsister_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "wh_captain_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "wh_bountyhunter_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "wh_zealot_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "wh_priest_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "bw_adept_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "bw_scholar_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					},
					{
						setting_id = "bw_unchained_m",
						type = "dropdown",
						options = {
							{text = "default", value = mod.melee_settings.default},
							{text = "as_in_BI_C", value = mod.melee_settings.as_in_BI_C},
							{text = "my_settings", value = mod.melee_settings.my_settings},
						},
						default_value = mod.melee_settings.my_settings
					}
				},
				default_value = mod.melee_settings.my_settings
			},
			{
				setting_id = "self_healing_settings",
				type = "group",
				sub_widgets = {
					{
						setting_id = "self_heal_threshold",
						type = "dropdown",
						tooltip = "self_heal_threshold_description",
						options = {
							{text = "item_dependent_default", value = mod.heal_constants.ITEM_DEPENDENT},
							{text = "when_hurt", value = mod.heal_constants.HURT},
							{text = "when_seriously_hurt", value = mod.heal_constants.SERIOUSLY_HURT},
							{text = "when_wounded", value = mod.heal_constants.WOUNDED},
							{text = "when_wounded_and_low", value = mod.heal_constants.WOUNDED_AND_LOW},
							{text = "extra_heals_available", value = mod.heal_constants.EXTRA_HEAL_AVAILABLE},
							{text = "no_heal", value = mod.heal_constants.NO_HEAL}
						},
						default_value = mod.heal_constants.SERIOUSLY_HURT
					},
					{
						setting_id = "self_heal_threshold_nb",
						type = "dropdown",
						tooltip = "self_heal_threshold_nb_description",
						options = {
							{text = "item_dependent", value = mod.heal_constants.ITEM_DEPENDENT},
							{text = "when_hurt", value = mod.heal_constants.HURT},
							{text = "when_seriously_hurt", value = mod.heal_constants.SERIOUSLY_HURT},
							{text = "when_wounded_default", value = mod.heal_constants.WOUNDED},
							{text = "when_wounded_and_low", value = mod.heal_constants.WOUNDED_AND_LOW},
							{text = "wait_heal_from_others", value = mod.heal_constants.WAIT_HEAL_FROM_OTHERS},
							{text = "no_heal", value = mod.heal_constants.NO_HEAL}
						},
						default_value = mod.heal_constants.WOUNDED
					},
					{
						setting_id = "self_heal_threshold_zealot",
						type = "dropdown",
						tooltip = "self_heal_threshold_zealot_description",
						options = {
							{text = "as_others_default", value = mod.heal_constants.AS_OTHERS},
							{text = "when_wounded", value = mod.heal_constants.WOUNDED},
							{text = "when_wounded_and_low", value = mod.heal_constants.WOUNDED_AND_LOW},
							{text = "no_heal", value = mod.heal_constants.NO_HEAL}
						},
						default_value = mod.heal_constants.WOUNDED_AND_LOW
					},
				},
			},
			{
				setting_id = "others_healing_settings",
				type = "group",
				sub_widgets = {
					{
						setting_id = "others_heal_threshold",
						type = "dropdown",
						tooltip = "others_heal_threshold_description",
						options = {
							{text = "when_hurt", value = mod.heal_constants.HURT},
							{text = "when_seriously_hurt_default", value = mod.heal_constants.SERIOUSLY_HURT},
							{text = "when_wounded", value = mod.heal_constants.WOUNDED},
							{text = "when_wounded_and_low", value = mod.heal_constants.WOUNDED_AND_LOW},
							{text = "no_heal", value = mod.heal_constants.NO_HEAL}
						},
						default_value = mod.heal_constants.SERIOUSLY_HURT
					},
					{
						setting_id = "others_heal_threshold_zealot",
						type = "dropdown",
						tooltip = "others_heal_threshold_zealot_description",
						options = {
							{text = "as_others_default", value = mod.heal_constants.AS_OTHERS},
							{text = "when_wounded", value = mod.heal_constants.WOUNDED},
							{text = "when_wounded_and_low", value = mod.heal_constants.WOUNDED_AND_LOW},
							{text = "no_heal", value = mod.heal_constants.NO_HEAL}
						},
						default_value = mod.heal_constants.WOUNDED_AND_LOW
					},
				},
			},
			{
				setting_id = "activate_abilities_tweaks",
				type = "group",
				sub_widgets = {
					{
						setting_id = "rescue_allies_active_ability",
						type = "checkbox",
						tooltip = "rescue_allies_active_ability_description",
						default_value = true
					},
					{
						setting_id = "regular_active_abilities",
						type = "dropdown",
						tooltip = "regular_active_abilities_description",
						options = {
							{text = "disable_all", value = mod.bot_abilities_settings.DISABLE_ALL},
							{text = "manual_setting", value = mod.bot_abilities_settings.MANUAL_SETTING, show_widgets = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }},
							{text = "enable_all", value = mod.bot_abilities_settings.ENABLE_ALL},
						},
						sub_widgets = {
							{
								setting_id = "es_mercenary",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "es_huntsman",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "es_knight",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "es_questingknight",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "dr_ranger",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "dr_ironbreaker",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "dr_slayer",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "dr_engineer",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "we_waywatcher",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "we_maidenguard",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "we_shade",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "we_thornsister",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "wh_captain",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "wh_bountyhunter",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "wh_zealot",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "wh_priest",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "bw_adept",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "bw_scholar",
								type = "checkbox",
								default_value = true
							},
							{
								setting_id = "bw_unchained",
								type = "checkbox",
								default_value = true
							}
						},
						default_value = mod.bot_abilities_settings.ENABLE_ALL
					},
				},
			},
			{
				setting_id = "improved_revive",
				type = "checkbox",
				tooltip = "improved_revive_description",
				default_value = true
			},
			{
				setting_id = "ping_enemies",
				type = "checkbox",
				tooltip = "ping_enemies_description",
				default_value = true
			},
			{
				setting_id = "overcharge_tweaks",
				type = "checkbox",
				tooltip = "overcharge_tweaks_description",
				default_value = true
			},
			{
				setting_id = "reload_tweaks",
				type = "checkbox",
				tooltip = "reload_tweaks_description",
				default_value = true
			},
			{
				setting_id = "pickup_tweaks",
				type = "checkbox",
				tooltip = "pickup_tweaks_description",
				default_value = true
			},
			{
				setting_id = "drinking_potions",
				type = "checkbox",
				tooltip = "drinking_potions_description",
				default_value = false
			},
			{
				setting_id = "stop_chasing",
				type = "checkbox",
				tooltip = "stop_chasing_description",
				default_value = true
			},
			{
				setting_id = "ignore_lof",
				type = "checkbox",
				tooltip = "ignore_lof_description",
				default_value = true
			},
			{
				setting_id = "ignore_bosses",
				type = "checkbox",
				tooltip = "ignore_bosses_description",
				default_value = true
			},
			-- {
				-- setting_id = "aggro_tweaks",
				-- type = "checkbox",
				-- tooltip = "aggro_tweaks_description",
				-- default_value = true
			-- },
			-- {
				-- setting_id = "zealot_bot_six_stacks",
				-- type = "checkbox",
				-- tooltip = "zealot_bot_six_stacks_description",
				-- default_value = true
			-- },
			-- {
				-- setting_id = "bot_info_guard_break",
				-- type = "dropdown",
				-- tooltip = "bot_info_guard_break_description",
				-- options = {
					-- {text = "bot_info_guard_break_none", value = mod.guard_break_settings.none},
					-- {text = "bot_info_guard_break_host", value = mod.guard_break_settings.host},
					-- {text = "bot_info_guard_break_global", value = mod.guard_break_settings.global},
				-- },
				-- default_value = mod.guard_break_settings.none
			-- },
			{
				setting_id = "bot_info_guard_break",
				type = "checkbox",
				tooltip = "bot_info_guard_break_description",
				default_value = true
			},
			{
				setting_id = "bot_teleport_to_host_key",
				type = "keybind",
				tooltip = "bot_teleport_to_host_key_description",
				default_value = {},
				keybind_global = false,
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "bot_teleport_to_host",
			},
			{
				setting_id = "bot_teleport_to_follow_unit_key",
				type = "keybind",
				tooltip = "bot_teleport_to_follow_unit_key_description",
				default_value = {},
				keybind_global = false,
				keybind_trigger = "pressed",
				keybind_type = "function_call",
				function_name = "bot_teleport_to_follow_unit",
			},
		},
	},
}