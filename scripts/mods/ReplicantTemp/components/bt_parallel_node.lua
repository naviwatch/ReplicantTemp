local mod = get_mod("ReplicantTemp")

-- look BTNode for details of node methods 
-- look BehaviorTree for details of BTs execution
-- the base functionlaity of my class was borrowed from BTSelector, but then changed a lot
-- the idea of my class is ability to execute in parallel several tasks, not interrupting one another - like revive and using ability, f.e.
BTParallelNode = class(BTParallelNode, BTNode)

BTParallelNode.init = function (self, ...)
	BTParallelNode.super.init(self, ...)

	self._children = {} -- as in BTSelector
end

BTParallelNode.name = "BTParallelNode" -- cannot say anyhing about importance of this name - but the name of Every Node In The Behaviour Tree is VERY important -
									   -- it will become the _identifier with the help of which we can get status of node (like blackboard.running_nodes[self._identifier])
									   -- the example is here:			
																	--	{
																	--		"BTParallelNode", -- class name, most common global classes for player bots BTs are BTSelector and BTUtilityNode,
																	--						  -- and for every single action exits its own class (like BTBotInventorySwitchAction)
																	--		{
																	--			*node 1*				-- for example here can be BTBotInventorySwitchAction node, as a child of our BTParallelNode
																	--			...,
																	--          name = "switch_melee"	-- THIS is the name of the inner *node 1*, as I mentioned it is important for Every node
																	--		},
																	--		...,
																	--		{
																	--			*node N*
																	--		},
																	--		name = "safe_revive", 	-- THIS is the name of the whole node, required!!!
																	--		condition = ..., 		-- optional, if not it will automatically set like "always_true"
																	--		condition_args = ..., 	-- optional, only for condition
																	--		action_data  			-- optinal, but very important for BTUtilityNode, determines its execution in fact
																	--	}

------------------------------------------------------------------------------------------------------------------------------------------------------

BTParallelNode.enter = function (self, unit, blackboard, t) -- initializes the empty table ({}) for future running nodes
															-- by default blackboard.running_nodes[identifier] can be only single node or nil
	local identifier = self._identifier
	
	blackboard.running_nodes[identifier] = {}
end

BTParallelNode.leave = function (self, unit, blackboard, t, reason) --  stop children and clear blackboard.running_nodes[identifier]
	self:leave_all_nodes(unit, blackboard, t, reason)
	
	blackboard.running_nodes[self._identifier] = nil
end

------------------------------------------------------------------------------------------------------------------------------------------------------

BTParallelNode.set_running_child = function (self, unit, blackboard, t, node, reason, destroy) -- for outer requests, shouldn't do anything
	--mod:echo("set_running_child "..(node and node.name).." "..reason)
	return
end

BTParallelNode.current_running_child = nil -- deleted

BTParallelNode.current_running_childs = function (self, blackboard) -- the same as default "current_running_child", just more suitable name
	local identifier = self._identifier
	
	return blackboard.running_nodes[identifier]
end

-- deprecated
--[[BTParallelNode.set_running_child = function (self, unit, blackboard, t, node, reason, destroy) -- for outer requests (and leave method too), should stops all children and clears all the data
	local identifier = self._identifier
	local current_nodes = blackboard.running_nodes[identifier]
	
	if current_nodes and current_nodes[node] then
		return
	end
	
	if node == nil then		
		if current_nodes then
			for current_node, _ in pairs(current_nodes) do
				
				current_node:set_running_child(unit, blackboard, t, nil, reason, destroy)
				current_node:leave(unit, blackboard, t, reason, destroy)
			end
		end
		
		blackboard.running_nodes[identifier] = nil
	end
	
	if node then
		if self._parent ~= nil then
			self._parent:set_running_child(unit, blackboard, t, self, "aborted", destroy)
		end
		
		-- shouldn't do smth, just skip
	end
end--]]

-- deprecated
--[[BTParallelNode.set_running_child_inner = function (self, unit, blackboard, t, node, reason, destroy) -- for inner requests, starts and stops single nodes
	local identifier = self._identifier
	local current_nodes = blackboard.running_nodes[identifier]
	
	if current_nodes and current_nodes[node] then
		if destroy then
			current_nodes[node] = nil
			
			node:set_running_child(unit, blackboard, t, nil, reason, destroy)
			node:leave(unit, blackboard, t, reason, destroy)
		end
		
		return
	end
	
	if self._parent ~= nil and node ~= nil and not destroy then
		self._parent:set_running_child(unit, blackboard, t, self, "aborted", destroy)
	end
	
	if node and not destroy then
		current_nodes[node] = true
		
		node:enter(unit, blackboard, t)
	end
end--]]

BTParallelNode.enter_node = function(self, unit, blackboard, t, node)
	local current_nodes = self:current_running_childs(blackboard)
	
	if current_nodes[node] then
		return
	end
	
	current_nodes[node] = true
	
	if self._parent ~= nil then
		self._parent:set_running_child(unit, blackboard, t, self, "aborted")
	end
	
	node:enter(unit, blackboard, t)
end

BTParallelNode.leave_node = function(self, unit, blackboard, t, node, reason)
	local current_nodes = self:current_running_childs(blackboard)
	
	if not current_nodes[node] then
		return
	end
	
	current_nodes[node] = nil
		
	node:set_running_child(unit, blackboard, t, nil, reason)
		
	node:leave(unit, blackboard, t, reason)
end

BTParallelNode.leave_all_nodes = function(self, unit, blackboard, t, reason)
	local current_nodes = self:current_running_childs(blackboard)
	
	for node, _ in pairs(current_nodes) do
		
		current_nodes[node] = nil
		
		node:set_running_child(unit, blackboard, t, nil, reason)
		
		node:leave(unit, blackboard, t, reason)
	end
end

local RESULT_PRIORITIES = { ["running"] = 3, ["aborted"] = 2, ["failed"] = 1 }

local update_result = function(current_result, new_result) -- function which defines status of main node - "BTParallelNode" - collecting statuses of its children
	current_result_value = current_result and RESULT_PRIORITIES[current_result] or 0
	new_result_value = new_result and RESULT_PRIORITIES[new_result] or 0
	
	return current_result_value < new_result_value and new_result or current_result
end

BTParallelNode.run = function (self, unit, blackboard, t, dt)
	local childs_running = self:current_running_childs(blackboard)

	local self_result = "failed"
	local self_evaluate = true
	
	for index, node in ipairs(self._children) do
		if node:condition(blackboard) then
			self:enter_node(unit, blackboard, t, node) -- 'enter' node or do nothing if already running
			
			local result, evaluate = node:run(unit, blackboard, t, dt) -- 'run' node
			
			if result ~= "running" then
				self:leave_node(unit, blackboard, t, node, result) -- 'leave' node if it was failed or aborted
			end
			
			self_result = update_result(self_result, result) -- update self status
			self_evaluate = self_evaluate and evaluate
			
		elseif childs_running and childs_running[node] then
			self:leave_node(unit, blackboard, t, node, "failed") -- 'leave' node if it is already running but condition was not met
		end
	end
	
	return self_result, self_evaluate
end

------------------------------------------------------------------------------------------------------------------------------------------------------

BTParallelNode.add_child = function (self, node) -- taken from BTSelector, used in BehaviorTree
	self._children[#self._children + 1] = node
end

