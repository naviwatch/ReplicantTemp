local mod = get_mod("ReplicantTemp")
local math = math

--[[
	lua-polynomials is a Lua module created by piqey
	(John Kushmer) for finding the roots of second-,
	third- and fourth- degree polynomials.
--]]

--module("polynomials")

--[[
	Just decorating our package for any programmers
	that might possibly be snooping around in here;
	you know, trying to understand and harness the
	potential of all the black magic that's been
	packed in here (you can thank Cardano's formula
	and Ferrari's method for all of that).
--]]

--[[
__VERSION = "1.0.0" -- https://semver.org/
__DESCRIPTION = "Methods for finding the roots of traditional- and higher-degree polynomials (2nd to 4th)."
__URL = "https://github.com/piqey/lua-polynomials"
__LICENSE = "GNU General Public License, version 3"
--]]

-- Utility functions

local eps = 1e-9 -- definitely small enough

-- checks if d is close enough to 0 to be considered 0 (for our purposes)
local function isZero(d)
	return (d > -eps and d < eps)
end

-- fixes an issue with math.pow that returns nan when the result should be a real number
local function cuberoot(x)
	return (x > 0) and math.pow(x, (1 / 3)) or -math.pow(math.abs(x), (1 / 3))
end

--[[
	solveQuadric(number a, number b, number c)
	returns number s0, number s1
	Will return nil for roots that do not exist.
	Solves for the roots of quadric/quadratic polynomials of the following form:
	ax^2 + bx + c = 0
--]]

local function solveQuadric(c0, c1, c2)
	local s0, s1
	
	local p, q, D
	
	-- x^2 + 2px + q = 0
	p = c1 / (2 * c0)
	q = c2 / c0

	D = p * p - q

	if isZero(D) then
		s0 = -p
		return s0
	elseif (D < 0) then
		return
	else -- if (D > 0)
		local sqrt_D = math.sqrt(D)

		s0 = sqrt_D - p
		s1 = -sqrt_D - p
		return s0, s1
	end
end

--[[
	solveCubic(number a, number b, number c, number d)
	returns number s0, number s1, number s2
	Will return nil for roots that do not exist.
	Solves for the roots of cubic polynomials of the following form:
	ax^3 + bx^2 + cx + d = 0
--]]

local function solveCubic(c0, c1, c2, c3)
	local s0, s1, s2

	local num, sub
	local A, B, C
	local sq_A, p, q
	local cb_p, D

	-- normal form: x^3 + Ax^2 + Bx + C = 0
	A = c1 / c0
	B = c2 / c0
	C = c3 / c0

	-- substitute x = y - A/3 to eliminate quadric term: x^3 + px + q = 0
	sq_A = A * A
	p = (1 / 3) * (-(1 / 3) * sq_A + B)
	q = 0.5 * ((2 / 27) * A * sq_A - (1 / 3) * A * B + C)

	-- use Cardano's formula
	cb_p = p * p * p
	D = q * q + cb_p

	if isZero(D) then
		if isZero(q) then -- one triple solution
			s0 = 0
			num = 1
			--return s0
		else -- one single and one double solution
			local u = cuberoot(-q)
			s0 = 2 * u
			s1 = -u
			num = 2
			--return s0, s1
		end
	elseif (D < 0) then -- Casus irreducibilis: three real solutions
		local phi = (1 / 3) * math.acos(-q / math.sqrt(-cb_p))
		local t = 2 * math.sqrt(-p)

		s0 = t * math.cos(phi)
		s1 = -t * math.cos(phi + math.pi / 3)
		s2 = -t * math.cos(phi - math.pi / 3)
		num = 3
		--return s0, s1, s2
	else -- one real solution
		local sqrt_D = math.sqrt(D)
		local u = cuberoot(sqrt_D - q)
		local v = -cuberoot(sqrt_D + q)

		s0 = u + v
		num = 1

		--return s0
	end

	-- resubstitute
	sub = (1 / 3) * A

	if (num > 0) then s0 = s0 - sub end
	if (num > 1) then s1 = s1 - sub end
	if (num > 2) then s2 = s2 - sub end

	return s0, s1, s2
end

--[[
	solveQuartic(number a, number b, number c, number d, number e)
	returns number s0, number s1, number s2, number s3
	Will return nil for roots that do not exist.
	Solves for the roots of quartic polynomials of the form:
	ax^4 + bx^3 + cx^2 + dx + e = 0
--]]

local function solveQuartic(c0, c1, c2, c3, c4)
	local s0, s1, s2, s3

	local coeffs = {}
	local z, u, v, sub
	local A, B, C, D
	local sq_A, p, q, r
	local num

	-- normal form: x^4 + Ax^3 + Bx^2 + Cx + D = 0
	A = c1 / c0
	B = c2 / c0
	C = c3 / c0
	D = c4 / c0
	
	if isZero(A) and isZero(C) then
		local u1, u2 = solveQuadric(1, B, D)
		
		if not u1 then
		elseif isZero(u1) then
			s0 = 0
			s1 = 0
		elseif u1 > 0 then
			s0 = math.sqrt(u1)
			s1 = -s0
		end
		
		if not u2 then
		elseif isZero(u2) then
			s2 = 0
			s3 = 0
		elseif u2 > 0 then
			s2 = math.sqrt(u2)
			s3 = -s2
		end
		
		return s0, s1, s2, s3
	end

	-- substitute x = y - A/4 to eliminate cubic term: x^4 + px^2 + qx + r = 0
	sq_A = A * A
	p = -0.375 * sq_A + B
	q = 0.125 * sq_A * A - 0.5 * A * B + C
	r = -(3 / 256) * sq_A * sq_A + 0.0625 * sq_A * B - 0.25 * A * C + D
	
	if isZero(r) then
		-- no absolute term: y(y^3 + py + q) = 0
		coeffs[3] = q
		coeffs[2] = p
		coeffs[1] = 0
		coeffs[0] = 1

		local results = {solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])}
		num = #results
		s0, s1, s2 = results[1], results[2], results[3]
	else
		-- solve the resolvent cubic …
		coeffs[3] = 0.5 * r * p - 0.125 * q * q
		coeffs[2] = -r
		coeffs[1] = -0.5 * p
		coeffs[0] = 1

		local solutions = {solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])}
		
		local z
		-- … and take the one real solution …
		for i = 1, 3, 1 do
			local s = solutions[i]
			
			-- … to build two quadric equations
			u = s * s - r
			v = 2 * s - p
			
			local found = true
			
			if isZero(u) then
				u = 0
			elseif (u > 0) then
				u = math.sqrt(u)
			else
				found = false
			end

			if isZero(v) then
				v = 0
			elseif (v > 0) then
				v = math.sqrt(v)
			else
				found = false
			end
			
			if found then
				z = s
				break
			end
		end
		
		if not z then
			return
		end

		coeffs[2] = z - u
		coeffs[1] = q < 0 and -v or v
		coeffs[0] = 1
		
		s0, s1, s2, s3 = nil, nil, nil, nil
		
		do
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = #results
			s0, s1 = results[1], results[2]
		end

		coeffs[2] = z + u
		coeffs[1] = q < 0 and v or -v
		coeffs[0] = 1

		if (num == 0) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s0, s1 = results[1], results[2]
		end

		if (num == 1) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s1, s2 = results[1], results[2]
		end

		if (num == 2) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s2, s3 = results[1], results[2]
		end
	end

	-- resubstitute
	sub = 0.25 * A

	if (num > 0) then s0 = s0 - sub end
	if (num > 1) then s1 = s1 - sub end
	if (num > 2) then s2 = s2 - sub end
	if (num > 3) then s3 = s3 - sub end
	
	return s0, s1, s2, s3
end

polynomials = { solveQuadric = solveQuadric, solveCubic = solveCubic, solveQuartic = solveQuartic }

return polynomials

--[[

-- original prediction function from ProjectileTemplates.trajectory_templates.throw_trajectory
local original_prediction_function = function (speed, gravity, initial_position, target_position, target_velocity)
	local t = 0
	local angle = nil
	local EPSILON = 0.01
	local ITERATIONS = 10
	
	assert(gravity > 0, "Can't solve for <=0 gravity, use different projectile template")
	
	local estimated_target_position = target_position
	
	for i = 1, ITERATIONS, 1 do
		estimated_target_position = target_position + t * target_velocity
		local height = estimated_target_position.z - initial_position.z
		local speed_squared = speed^2
		local flat_distance = Vector3.length(Vector3.flat(estimated_target_position - initial_position))
		
		if flat_distance < EPSILON then
			return 0, estimated_target_position
		end
		
		local sqrt_val = speed_squared^2 - gravity * (gravity * flat_distance^2 + 2 * height * speed_squared)
		
		if sqrt_val <= 0 then
			return nil, estimated_target_position
		end
		
		local second_degree_component = math.sqrt(sqrt_val)
		local angle1 = math.atan((speed_squared + second_degree_component) / (gravity * flat_distance))
		local angle2 = math.atan((speed_squared - second_degree_component) / (gravity * flat_distance))
		angle = math.min(angle1, angle2)
		
		local flat_distance = Vector3.length(Vector3.flat(estimated_target_position - initial_position))
		t = flat_distance / (speed * math.cos(angle))
	end
	
	return angle, estimated_target_position
end

local function get_best_real_time(times)
	local t = math.huge
	local assigned = false
	
	for i = 1, #times, 1 do
		if times[i] and times[i] >= 0 and times[i] < t then
			t = times[i]
			
			assigned = true
		end
	end
	
	return assigned and t or nil
end

local polynomials = require ("scripts/mods/"..mod:get_name().."/_polynomial_equations")

local prediction_function__moving_target_const_projectile_speed = function (speed, gravity, player_position, target_position, target_velocity)
	local P = target_position - player_position
	local G = Vector3(0, 0, gravity)
	local V = target_velocity
	local s = speed
	
	local c0 = Vector3.dot(G, G) / 4
	local c1 = Vector3.dot(V, G)
	local c2 = Vector3.dot(P, G) + Vector3.dot(V, V) - s^2
	local c3 = 2 * Vector3.dot(P, V)
	local c4 = Vector3.dot(P, P)
	
	local t1, t2, t3, t4 = polynomials.solveQuartic(c0, c1, c2, c3, c4)
	
	local t = get_best_real_time({ t1, t2, t3, t4 })
	
	if not t then
		return nil, nil
	end
	
	local aim_P = P + V * t + G * t^2 / 2
	local angle = math.asin(aim_P.z / Vector3.length(aim_P))
	
	local estimated_target_position = target_position + V * t
	
	return angle, estimated_target_position
end

local solve_moving_eq_const_speed = function (c0, c1, c2, c3, c4)
	local t1, t2, t3, t4 = polynomials.solveQuartic(c0, c1, c2, c3, c4)
	
	return get_best_real_time({ t1, t2, t3, t4 })
end

local solve_moving_eq_dampening_speed = function(c0, c1, c2, c3, c4, init_s, dampening)
	local t
	local old_t
	local s = init_s
	local k = dampening - 1
	
	for i = 1, 30, 1 do
		t = solve_moving_eq_const_speed(c0, c1, c2 - s^2, c3, c4)
		
		if not t then
			t = old_t
			break
		elseif old_t and math.abs(t - old_t) <= 0.000000001 then
			mod:echo(math.abs(t - old_t))
			break
		end
		
		s = init_s * (math.exp(k * t) - 1) / (t * k)
		old_t = t
	end
	
	return t
end

-- it should be changed to predict aim more properly, especially for javelins which have linear dampening
-- all my attempts to do that were absolutely futile
mod:hook_origin(ProjectileTemplates.trajectory_templates.throw_trajectory, "prediction_function", function(speed, dampening, gravity, player_position, target_position, target_velocity)
	local P = target_position - player_position
	local G = Vector3(0, 0, gravity)
	local V = target_velocity
	local s = speed
	
	local c0 = Vector3.dot(G, G) / 4
	local c1 = Vector3.dot(V, G)
	local c2_base = Vector3.dot(P, G) + Vector3.dot(V, V)
	local c3 = 2 * Vector3.dot(P, V)
	local c4 = Vector3.dot(P, P)
	
	local t
	
	if dampening then
		t = solve_moving_eq_dampening_speed(c0, c1, c2_base, c3, c4, s, dampening)
	else
		t = solve_moving_eq_const_speed(c0, c1, c2_base - s^2, c3, c4)
	end
	
	if not t then
		return nil, nil
	end
	
	local aim_P = P + V * t + G * t^2 / 2
	local angle = math.asin(aim_P.z / Vector3.length(aim_P))
	
	local estimated_target_position = target_position + V * t
	
	return angle, estimated_target_position
end)

ProjectileTemplates.trajectory_templates.geiser_trajectory = {
	prediction_function = function(speed, dampening, gravity, player_position, target_position, target_velocity)
		local P = target_position - player_position
		local P = P - 1 * Vector3.normalize(Vector3.flat(P)) -- center geiser on target
		local G = Vector3(0, 0, gravity)
		local s = speed
		
		mod:echo(G)
		
		local c0 = Vector3.dot(G, G) / 4
		local c1 = Vector3.dot(P, G) - s^2
		local c2 = Vector3.dot(P, P)
		
		local u1, u2 = polynomials.solveQuadric(c0, c1, c2) -- u = t^2
		
		local u = get_best_real_time({ u1, u2 })
		
		if not u then
			return nil, nil
		end
		
		local aim_P = P + G * u / 2
		local angle = math.asin(aim_P.z / Vector3.length(aim_P))
		
		return angle, target_position
	end
}
--]]