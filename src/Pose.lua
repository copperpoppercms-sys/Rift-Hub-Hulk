-- Local joint poses for standard R6/R15 rigs. C0, movement controls and Animate stay unchanged.
local RunService = game:GetService("RunService")
return function(character)
	local joints, connections = {}, {}
	local phase, power, destroyed = nil, 0, false
	local M = { Count = 0, Rig = "Custom" }
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then M.Rig = tostring(hum.RigType):match("R%d+") or "Custom" end
	local roles = { rootjoint="root", root="root", waist="waist", neck="neck",
		lefthip="hip", righthip="hip", leftknee="knee", rightknee="knee",
		leftankle="ankle", rightankle="ankle", leftshoulder="shoulder", rightshoulder="shoulder",
		leftelbow="elbow", rightelbow="elbow" }
	for _, joint in ipairs(character:GetDescendants()) do
		if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
			local role = roles[joint.Name:lower():gsub("[%s_]", "")]
			if not role and joint.Part0.Name == "HumanoidRootPart" then role = "root" end
			if role then table.insert(joints, { Joint=joint, Role=role }); M.Count += 1 end
		end
	end
	function M.Restore()
		for _, entry in ipairs(joints) do
			if entry.Base then
				pcall(function()
					-- Preserve a different transform written by the game since our last pose.
					if entry.Joint.Parent and entry.Joint.Transform == entry.Applied then entry.Joint.Transform = entry.Base end
				end)
				entry.Base, entry.Applied = nil, nil
			end
		end
	end
	function M.Set(nextPhase, amount)
		phase, power = nextPhase, math.clamp(amount or 0, 0, 1)
		if not phase then M.Restore() end
	end
	local function apply()
		if destroyed then return end
		M.Restore()
		if not phase then return end
		local crouching = phase == "charging"
		local alpha = crouching and power or 1
		local angles = crouching and { root=-10, waist=-10, neck=12, hip=45, knee=-85, ankle=40, shoulder=35, elbow=-35 }
			or { root=-12, waist=-8, neck=15, hip=25, knee=-50, ankle=25, shoulder=145, elbow=-25 }
		for _, entry in ipairs(joints) do
			pcall(function()
				local joint = entry.Joint
				if not joint.Parent then return end
				local down = crouching and entry.Role == "root" and -(M.Rig == "R6" and 0.55 or 0.9) * alpha or 0
				local rotation = joint.C0.Rotation
				local delta = rotation:Inverse() * CFrame.new(0, down, 0)
					* CFrame.Angles(math.rad(angles[entry.Role] or 0) * alpha, 0, 0) * rotation
				entry.Base = joint.Transform
				entry.Applied = delta * entry.Base
				joint.Transform = entry.Applied
			end)
		end
	end
	-- Restore before Animator evaluates, and apply after its joint writes.
	if RunService.PreAnimation then table.insert(connections, RunService.PreAnimation:Connect(M.Restore)) end
	table.insert(connections, (RunService.PreSimulation or RunService.Stepped):Connect(apply))
	function M.Destroy()
		if destroyed then return end
		destroyed = true; phase = nil; M.Restore()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections); table.clear(joints)
	end
	return M
end
