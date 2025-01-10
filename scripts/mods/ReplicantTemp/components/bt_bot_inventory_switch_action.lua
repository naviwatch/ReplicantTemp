local mod = get_mod("ReplicantTemp")

local has_hold_ability_action = function(blackboard) -- this should work +- ok for any careers, even future, but didn't check it too properly
	local career_extension = blackboard.career_extension
	local activated_ability_data = career_extension:get_activated_ability_data()
	local action_name = activated_ability_data.action_name
	
	local action_template = ActionTemplates[action_name]
	local action_on_wield = action_template and action_template.default.action_on_wield
	
	if action_on_wield then
		return action_on_wield.action == "action_career_hold"
	end
	
	return false
end

local is_engineer = function(blackboard) -- this should work for current careers, only engineer can swap his career weapon without canceling ability
	return blackboard.career_extension:career_name() == "dr_engineer"
end

mod:hook_origin(BTBotInventorySwitchAction, "run", function (self, unit, blackboard, t, dt)
	local wanted_slot = blackboard.wanted_slot
	local inventory_ext = blackboard.inventory_extension
	local input_extension = blackboard.input_extension
	
	local wielded_slot = inventory_ext:equipment().wielded_slot
	
	if wielded_slot == wanted_slot then
		return "done"
	end
	
	if 	wielded_slot == "slot_career_skill_weapon" -- if not then cancel_ability is not needed
		and not is_engineer(blackboard) then -- instead of *not is_engineer(blackboard)* can use *has_hold_ability_action(blackboard.career_extension, inventory_ext)*
		
		input_extension:cancel_ability()
	end
	
	--if wielded_slot == wanted_slot then
		--return "done"
	if t > blackboard.node_timer + 0.3 then -- elseif
		blackboard.node_timer = t

		return "running", "evaluate"
	else
		input_extension:wield(wanted_slot)

		return "running"
	end
end)