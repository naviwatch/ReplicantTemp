local mod = get_mod("ReplicantTemp")

BotActions = BotActions or {}

BotActions.default = {
	follow = {
		action_weight = 1
	},
	successful_follow = {
		action_weight = 1
	},
	goto_transport = {
		name = "goto_transport",
		move_anim = "move_start_fwd",
		goal_selection = "new_goal_in_transport",
		action_weight = 1,
		considerations = UtilityConsiderations.follow
	},
	shoot = {
		evaluation_duration = 1,
		maximum_obstruction_reevaluation_time = 0.3,
		evaluation_duration_without_firing = 2,
		minimum_obstruction_reevaluation_time = 0.2,
		action_weight = 1
	},
	shoot_ability = {
		charge_input = "activate_ability",
		fire_input = "activate_ability",
		abort_input = "cancel_ability",
		minimum_obstruction_reevaluation_time = 0.025,
		maximum_obstruction_reevaluation_time = 0.050,
		evaluation_duration = 1,
		evaluation_duration_without_firing = 2,
		action_weight = 1,
		slot_name = "slot_career_skill_weapon"
	},
	switch_melee = {
		wanted_slot = "slot_melee",
		action_weight = 1
	},
	switch_ranged = {
		wanted_slot = "slot_ranged",
		action_weight = 1
	},
	switch_heal = {
		wanted_slot = "slot_healthkit",
		action_weight = 1
	},
	switch_potion = {
		wanted_slot = "slot_potion",
		action_weight = 1
	},
	switch_grenade = {
		wanted_slot = "slot_grenade"
	},
	fight_melee_priority_target = {
		engage_range = math.huge,	--20?
		engage_range_threat = math.huge,	--20?
		engage_range_near_follow_pos = math.huge,	--20?
		engage_range_near_follow_pos_threat = math.huge,	--20?
		override_engage_range_to_follow_pos = math.huge,
		override_engage_range_to_follow_pos_threat = math.huge
	},
	fight_melee = {
		engage_range_threat = 4,
		override_engage_range_to_follow_pos = 10,
		engage_range = 6,
		override_engage_range_to_follow_pos_threat = 3,
		engage_range_near_follow_pos_threat = 5,
		engage_range_near_follow_pos = 10
	},
	destroy_object_melee = {
		destroy_object = true,
		do_not_update_engage_position = true,
		engage_range = math.huge,
		engage_range_threat = math.huge,
		engage_range_near_follow_pos = math.huge,
		engage_range_near_follow_pos_threat = math.huge,
		override_engage_range_to_follow_pos = math.huge,
		override_engage_range_to_follow_pos_threat = math.huge
	},
	combat = {
		action_weight = 1
	},
	revive = {
		aim_node = "j_head",
		use_block_interaction = true
	},
	use_heal_on_player = {
		aim_node = "j_head",
		input = "charge_shot"
	},
	do_give_grenade = {
		aim_node = "j_head",
		input = "defend"
	},
	do_give_potion = {
		aim_node = "j_head",
		input = "defend"
	},
	do_give_heal_item = {
		aim_node = "j_head",
		input = "defend"
	},
	rescue_hanging_from_hook = {
		aim_node = "j_hips",
		use_block_interaction = true
	},
	rescue_ledge_hanging = {
		aim_node = "j_head",
		use_block_interaction = true
	},
	use_ability = {
		dr_ironbreaker = {
			activation = {}
		},
		dr_slayer = {
			activation = {
				action = "aim_at_target"
			},
			post_effects = {
				"move_to_target_unit",
				end_condition = {
					ability_buffs = {}
				}
			}
		},
		dr_ranger = {
			activation = {},
			end_condition = {
				is_slot_not_wielded = {
					"slot_career_skill_weapon"
				}
			},
			post_effects = {
				"ranged_combat_preferred",
				"enhanced_target_choice",
				end_condition = {
					duration = 10,
					ability_buffs = {}
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
			post_effects = {
				"ranged_combat_preferred",
				"enhanced_target_choice",
				end_condition = {
					ability_buffs = {}
				}
			}
		},
		es_knight = {
			activation = {
				action = "aim_at_target"
			},
			end_condition = {
				stop_when_destination_reached = {
					max_duration = 1.5,
					max_distance = 12
				}
			}
		},
		es_questingknight = {
			activation = {
				max_distance_sq = 20,
				move_to_target_unit = true,
				dynamic_target_unit = true,
				action = "aim_at_target",
				fast_aim = true,
				defend_while_aiming = true
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
				stop_when_destination_reached = {
					max_duration = 0.65,
					max_distance = 12
				}
			}
		},
		we_shade = {
			activation = {},
			post_effects = {
				"melee_combat_preferred",
				"move_to_target_unit",
				"enhanced_target_choice",
				end_condition = {
					ability_buffs = {}
				}
			}
		},
		we_thornsister = {
			activation = {
				action = "aim_at_target",
				fast_aim = true
			}
		},
		wh_captain = {
			activation = {},
			post_effects = {
				"melee_combat_preferred",
				"move_to_target_unit",
				end_condition = {
					ability_buffs = {
						"victor_witchhunter_activated_ability_crit_buff",
						"victor_witchhunter_activated_ability_guaranteed_crit_self_buff"
					}
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
				stop_when_destination_reached = {
					max_duration = 0.75,
					max_distance = 12
				}
			},
			post_effects = {
				"move_to_target_unit",
				end_condition = {
					ability_buffs = {}
				}
			}
		},
		wh_priest = {
			activation = {
				action = "aim_at_target",
				min_hold_time = 0.2
			},
			end_condition = {
				is_slot_not_wielded = {
					"slot_career_skill_weapon"
				}
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
		}
	}
}

for category_name, category_table in pairs(BotActions) do
	for action_name, action_table in pairs(category_table) do
		action_table.name = action_name
		action_table.considerations = UtilityConsiderations["player_bot_" .. category_name .. "_" .. action_name] or nil
	end
end

for career_name, data in pairs(BotActions.default.use_ability) do
	local post_effects = data.post_effects
	
	if post_effects and #post_effects > 0 and post_effects.end_condition then
		local duration = post_effects.end_condition.duration
		
		if not duration then
			data.post_effects.end_condition.duration = 0.05
		end
	elseif post_effects then
		data.post_effects = nil
	end
end