local mod = get_mod("ReplicantTemp")

--Note: POSITION_LOOKUP is not updated here, unlike when running the codes in ExecLua

mod.bot_teleport_to_host = function()
	-- mod:echo("number of bots = " .. tostring(#Managers.player:bots()))
	local teleport_success = false
	
	-- Check for hosting status
	if not Managers.player or not Managers.player.is_server then
		mod:echo("No player manager or not the host!")
		return
	end
	
	-- Check for existing player unit to be teleport destination
	local local_player = Managers.player:local_player()
	local local_player_unit = local_player.player_unit
	if not Unit.alive(local_player_unit) then
		mod:echo("No teleport destination!")
		return
	end
	
	-- Take player position as teleport destination
	local player_position = Unit.world_position(local_player_unit, 0)	--POSITION_LOOKUP[local_player_unit]	--Unit.local_position(local_player_unit, 0)
	-- POSITION_LOOKUP[local_player_unit] = player_position
	
	-- Teleport all living bot units --
	for _, bot_player in pairs(Managers.player:bots()) do
		local bot_unit = bot_player.player_unit
		if Unit.alive(bot_unit) then
			local blackboard = BLACKBOARDS[bot_unit]
			if blackboard and blackboard.status_extension and blackboard.locomotion_extension and not blackboard.locomotion_extension.disabled then
				local status_extension = blackboard.status_extension
				local navigation_extension = blackboard.navigation_extension
				local locomotion_extension = blackboard.locomotion_extension
				
				-- Check bot status for knockdown or death etc.
				if not status_extension.knocked_down and
					not status_extension.dead and
					not status_extension.catapulted and
					not status_extension.pounced_down and
					not status_extension.is_ledge_hanging and
					not status_extension.pulled_up and
					not status_extension.overpowered and
					not status_extension.block_broken and
					not status_extension.pushed and
					not status_extension.charged and
					not status_extension.grabbed_by_tentacle and
					not status_extension.grabbed_by_chaos_spawn and
					not status_extension.in_vortex then
					--
					blackboard.teleport_stuck_loop_counter = nil
					blackboard.teleport_stuck_loop_start_time = nil

					POSITION_LOOKUP[bot_unit] = Unit.world_position(bot_unit, 0)	--Unit.local_position(bot_unit, 0)
					locomotion_extension:teleport_to(player_position)	--will not execute without updating POSITION_LOOKUP

					status_extension:set_falling_height(true, player_position.z)
					status_extension:set_ignore_next_fall_damage(true)

					blackboard.has_teleported = true
					
					navigation_extension:teleport(player_position)
					blackboard.ai_extension:clear_failed_paths()
					
					blackboard.follow.needs_target_position_refresh = true
					
					teleport_success = true
				end
			end
		end
	end
	
	if teleport_success then
		mod:echo("Forced bots to teleport to host.")
	else
		mod:echo("Forced bot teleport failed.")
	end
end

mod.bot_teleport_to_follow_unit = function()
	local teleport_success = false
	
	-- Check for hosting status
	if not Managers.player or not Managers.player.is_server then
		mod:echo("No player manager or not the host!")
		return
	end
	
	-- Teleport all living bot units --
	for _, bot_player in pairs(Managers.player:bots()) do
		local bot_unit = bot_player.player_unit
		if Unit.alive(bot_unit) then
			local blackboard = BLACKBOARDS[bot_unit]
			if blackboard and blackboard.status_extension and blackboard.locomotion_extension and not blackboard.locomotion_extension.disabled and
				blackboard.ai_bot_group_extension and blackboard.ai_bot_group_extension.data and
				blackboard.ai_bot_group_extension.data.follow_unit and
				Unit.alive(blackboard.ai_bot_group_extension.data.follow_unit) then
				--
				local status_extension = blackboard.status_extension
				local navigation_extension = blackboard.navigation_extension
				local locomotion_extension = blackboard.locomotion_extension
				
				if ScriptUnit.has_extension(bot_unit, "status_system") then
					local status_extension = ScriptUnit.extension(bot_unit, "status_system")
				
					-- Check bot status for knockdown or death etc.
					if not status_extension.knocked_down and
						not status_extension.dead and
						not status_extension.catapulted and
						not status_extension.pounced_down and
						not status_extension.is_ledge_hanging and
						not status_extension.pulled_up and
						not status_extension.overpowered and
						not status_extension.block_broken and
						not status_extension.pushed and
						not status_extension.charged and
						not status_extension.grabbed_by_tentacle and
						not status_extension.grabbed_by_chaos_spawn and
						not status_extension.in_vortex then
						--
						local player_position = Unit.world_position(blackboard.ai_bot_group_extension.data.follow_unit, 0)		--Unit.local_position(blackboard.ai_bot_group_extension.data.follow_unit, 0)
						--POSITION_LOOKUP[blackboard.ai_bot_group_extension.data.follow_unit] = player_position
						
						blackboard.teleport_stuck_loop_counter = nil
						blackboard.teleport_stuck_loop_start_time = nil

						POSITION_LOOKUP[bot_unit] = Unit.world_position(bot_unit, 0)	--Unit.local_position(bot_unit, 0)
						locomotion_extension:teleport_to(player_position)	--will not execute without updating POSITION_LOOKUP

						status_extension:set_falling_height(true, player_position.z)
						status_extension:set_ignore_next_fall_damage(true)
						
						blackboard.has_teleported = true
						
						navigation_extension:teleport(player_position)
						blackboard.ai_extension:clear_failed_paths()
						
						blackboard.follow.needs_target_position_refresh = true

						teleport_success = true
					end
				end
			else
				-- mod:echo("Followed unit not found.")
			end
		end
	end
	
	if teleport_success then
		mod:echo("Forced bots to teleport to the followed unit (if there is one).")
	else
		mod:echo("Forced bot teleport failed.")
	end
end
