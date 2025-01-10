local mod = get_mod("ReplicantTemp")

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

mod:hook(PlayerBotBase, "ranged_attack_started", function (func, self, attacking_unit, victim_unit, attack_type)
	if not mod.components.ignore_lof.value then
		return func(self, attacking_unit, victim_unit, attack_type)
	end
	
	local blackboard = self._blackboard

	if attack_type == "ratling_gun_fire" or attack_type == "warpfire_thrower_fire" then
		local targets = blackboard.taking_cover.threats
		targets[attacking_unit] = victim_unit
	end
end)

mod:hook(PlayerBotBase, "ranged_attack_ended", function (func, self, attacking_unit, victim_unit, attack_type)
	if not mod.components.ignore_lof.value then
		return func(self, attacking_unit, victim_unit, attack_type)
	end
	
	local blackboard = self._blackboard

	if attack_type == "ratling_gun_fire" or attack_type == "warpfire_thrower_fire" then
		local targets = blackboard.taking_cover.threats
		targets[attacking_unit] = nil
	end
end)

mod:hook(PlayerBotBase, "_in_line_of_fire", function(func, self, self_unit, self_pos, take_cover_targets, taking_cover_from)
	if not mod.components.ignore_lof.value then
		return func(self, self_unit, self_pos, take_cover_targets, taking_cover_from)
	end

	local changed = false
	local in_line_of_fire = false
	local width = 2.5
	local sticky_width = 6
	local length = 40

	for attacker, victim in pairs(take_cover_targets) do
		local already_in_cover_from = taking_cover_from[attacker]

		if ALIVE[victim] and (victim == self_unit or line_of_fire_check(POSITION_LOOKUP[attacker], POSITION_LOOKUP[victim], self_pos, (already_in_cover_from and sticky_width) or width, length))
		and Vector3.distance_squared(POSITION_LOOKUP[attacker], POSITION_LOOKUP[victim]) < 64
		and mod.check_line_of_sight(self_unit, attacker) then
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
	
	self._blackboard.in_line_of_fire = in_line_of_fire
	
	return in_line_of_fire, changed
end)
