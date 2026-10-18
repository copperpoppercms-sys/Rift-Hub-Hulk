-- Local poses for Motor6D, AnimationConstraint and skinned Bone rigs.
-- Only Transform is written; bind frames, attachments and movement controls are unchanged.
local RunService = game:GetService("RunService")
return function(character)
	local joints, connections = {}, {}
	local phase, power, destroyed = nil, 0, false
	local M = { Count=0, Rig="Custom", AppliedCount=0, LastError=nil,
		Inventory={Motor6D=0,AnimationConstraint=0,Bone=0}, ScanNotes={}, PendingBindings=0 }
	local function read(object, key)
		if not object then return nil end
		local ok, value=pcall(function() return object[key] end)
		return ok and value or nil
	end
	local function isa(object, kind)
		return object and object:IsA(kind)
	end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then M.Rig=tostring(hum.RigType):match("R%d+") or "Custom" end
	local exactRoles = { rootjoint="root", root="root", pelvis="root", hips="root", waist="waist", neck="neck",
		lefthip="hip", righthip="hip", leftknee="knee", rightknee="knee", leftankle="ankle", rightankle="ankle",
		leftshoulder="shoulder", rightshoulder="shoulder", leftelbow="elbow", rightelbow="elbow",
		leftwrist="wrist", rightwrist="wrist" }
	local function roleFromName(name)
		local key=tostring(name or ""):lower():gsub("[%s_%-]", ""):gsub("rigattachment$", ""):gsub("attachment$", "")
		if exactRoles[key] then return exactRoles[key] end
		for _,role in ipairs({"shoulder","elbow","wrist","hip","knee","ankle","waist","neck","root"}) do
			if key:find(role,1,true) then return role end
		end
		if key:find("spine",1,true) then return "waist" end
		return nil
	end
	local function fromLimb(part)
		local key=tostring(read(part,"Name") or ""):lower():gsub("[%s_%-]", "")
		if key:find("hand",1,true) then return "wrist" end
		if key:find("lowerarm",1,true) or key:find("forearm",1,true) then return "elbow" end
		if key:find("arm",1,true) then return "shoulder" end
		if key:find("foot",1,true) then return "ankle" end
		if key:find("lowerleg",1,true) or key:find("shin",1,true) or key:find("calf",1,true) then return "knee" end
		if key:find("leg",1,true) or key:find("thigh",1,true) then return "hip" end
		if key:find("head",1,true) then return "neck" end
		if key:find("torso",1,true) or key:find("spine",1,true) then return "waist" end
		return nil
	end
	local function inAccessory(node)
		local ok, ancestor=pcall(function() return node:FindFirstAncestorOfClass("Accessory") or node:FindFirstAncestorOfClass("Tool") end)
		return ok and ancestor~=nil
	end
	local rigid, bones = {}, {}
	local function add(joint, kind)
		M.Inventory[kind] += 1
		if inAccessory(joint) then return end
		local part0, part1, a0, a1, rest
		if kind=="AnimationConstraint" then
			a0,a1=read(joint,"Attachment0"),read(joint,"Attachment1")
			part0,part1=read(a0,"Parent") or read(joint,"Part0"),read(a1,"Parent") or read(joint,"Part1")
			rest=function() return a0 and a0.CFrame or joint.C0 end
		elseif kind=="Bone" then
			part0,part1=read(joint,"Parent"),joint
			rest=function() return joint.CFrame end
		else
			part0,part1=read(joint,"Part0"),read(joint,"Part1")
			rest=function() return joint.C0 end
		end
		local role=roleFromName(joint.Name) or roleFromName(read(a0,"Name")) or roleFromName(read(a1,"Name"))
		if not role and read(part0,"Name")=="HumanoidRootPart" then role="root" end
		if not role then role=fromLimb(part1) end
		if not part0 or not part1 or not role then
			if not part0 or not part1 then M.PendingBindings += 1 end
			if #M.ScanNotes<12 then table.insert(M.ScanNotes,joint.Name.."["..kind.."] "..(not role and "role unknown" or "binding incomplete")) end
			return
		end
		local entry={Joint=joint,Role=role,Kind=kind,Rest=rest}
		table.insert(kind=="Bone" and bones or rigid,entry)
	end
	for _, joint in ipairs(character:GetDescendants()) do
		if isa(joint,"Motor6D") then add(joint,"Motor6D")
		elseif isa(joint,"AnimationConstraint") then add(joint,"AnimationConstraint")
		elseif isa(joint,"Bone") then add(joint,"Bone") end
	end
	local rigidLimbs, rootFound=0,false
	for _,entry in ipairs(rigid) do
		if entry.Role=="root" then rootFound=true else rigidLimbs+=1 end
	end
	-- A skinned body can have a rigid root plus bones. Do not pose both skin bones
	-- and physical limb joints when they represent the same limbs.
	if rigidLimbs>0 or #bones==0 then joints=rigid
	else
		for _,entry in ipairs(rigid) do if entry.Role=="root" then table.insert(joints,entry) end end
		for _,entry in ipairs(bones) do if not (rootFound and entry.Role=="root") then table.insert(joints,entry) end end
	end
	M.Count=#joints
	function M.NeedsRefresh()
		if M.PendingBindings>0 then return true end
		local counts={Motor6D=0,AnimationConstraint=0,Bone=0}
		for _,node in ipairs(character:GetDescendants()) do
			if isa(node,"Motor6D") then counts.Motor6D+=1
			elseif isa(node,"AnimationConstraint") then counts.AnimationConstraint+=1
			elseif isa(node,"Bone") then counts.Bone+=1 end
		end
		return counts.Motor6D~=M.Inventory.Motor6D or counts.AnimationConstraint~=M.Inventory.AnimationConstraint or counts.Bone~=M.Inventory.Bone
	end
	function M.Describe()
		local inventory=string.format("found Motor6D=%d, AnimationConstraint=%d, Bone=%d",M.Inventory.Motor6D,M.Inventory.AnimationConstraint,M.Inventory.Bone)
		local details={}
		for i,entry in ipairs(joints) do
			if i>20 then table.insert(details,"more joints omitted");break end
			table.insert(details,entry.Joint.Name.."["..entry.Kind.."]:"..entry.Role)
		end
		if #details==0 then table.insert(details,"no usable joints; "..table.concat(M.ScanNotes,", ")) end
		return inventory.." | "..table.concat(details,", ")
	end
	function M.Restore()
		for _,entry in ipairs(joints) do
			if entry.Base then
				local ok,err=pcall(function()
					if entry.Joint.Parent and entry.Joint.Transform==entry.Applied then entry.Joint.Transform=entry.Base end
				end)
				if not ok then M.LastError=entry.Joint.Name.." restore: "..tostring(err) end
				entry.Base,entry.Applied=nil,nil
			end
		end
	end
	function M.Set(nextPhase, amount)
		phase,power=nextPhase,math.clamp(amount or 0,0,1)
		if not phase then M.Restore();M.AppliedCount=0 end
	end
	local function apply()
		if destroyed then return end
		M.Restore();M.AppliedCount=0
		if not phase then return end
		local crouching=phase=="charging"
		local alpha=crouching and power or 1
		local angles=crouching and {root=-10,waist=-10,neck=12,hip=45,knee=-85,ankle=40,shoulder=35,elbow=-35}
			or {root=-12,waist=-8,neck=15,hip=25,knee=-50,ankle=25,shoulder=145,elbow=-25}
		for _,entry in ipairs(joints) do
			local ok,err=pcall(function()
				local joint=entry.Joint
				if not joint.Parent then return end
				local down=crouching and entry.Role=="root" and -(M.Rig=="R6" and .55 or .9)*alpha or 0
				local rotation=entry.Rest().Rotation
				local delta=rotation:Inverse()*CFrame.new(0,down,0)*CFrame.Angles(math.rad(angles[entry.Role] or 0)*alpha,0,0)*rotation
				entry.Base=joint.Transform;entry.Applied=delta*entry.Base
				joint.Transform=entry.Applied;M.AppliedCount+=1
			end)
			if not ok then M.LastError=entry.Joint.Name..": "..tostring(err) end
		end
	end
	if RunService.PreAnimation then table.insert(connections,RunService.PreAnimation:Connect(M.Restore)) end
	table.insert(connections,(RunService.PreSimulation or RunService.Stepped):Connect(apply))
	function M.Destroy()
		if destroyed then return end
		destroyed=true;phase=nil;M.Restore()
		for _,connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections);table.clear(joints)
	end
	return M
end
