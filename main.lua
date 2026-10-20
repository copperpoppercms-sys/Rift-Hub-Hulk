-- RiftHub-Entry: hulk-character
-- Rift Hub / Hulk / 3.0 | Rift Gamma original Hulk motion
-- Original motion and controller code are embedded. Catalog playback is optional.
local env = type(getgenv) == "function" and getgenv() or _G
local existing = env.RiftHulkCharacter
if type(existing) == "table" and type(existing.Unload) == "function" then pcall(existing.Unload) end
local player = game:GetService("Players").LocalPlayer
assert(player, "Run Rift Hulk from a Roblox client")
local Utils = { GetCharacter = function(plr) return (plr or player).Character end }
local Kit = { INK=Color3.fromRGB(239,240,247), SUB=Color3.fromRGB(171,175,191) }
function Kit.face(name, weight)
 local ok,font=pcall(Font.fromName,name,weight or Enum.FontWeight.Regular,Enum.FontStyle.Normal)
 return ok and font or Font.fromEnum(Enum.Font.Gotham)
end
function Kit.create(class,props,parent)
 local obj=Instance.new(class)
 for key,value in pairs(props) do obj[key]=value end
 if parent then obj.Parent=parent end
 return obj
end
local HulkMotion=(function()
-- Original Rift Gamma keyframes, authored here rather than copied from a game clip.
-- Angles are parent-body axes in degrees; root Y is a visual joint offset only.
local function pose(values) return values end
local clips = {
	idle={Loop=2.4,Frames={
		{0,pose({root={-4,0,0,-.04},waist={-8,0,0},neck={8,0,0},hip={3,0,4},knee={-6,0,0},shoulder={7,0,18},elbow={28,0,0},wrist={-5,0,0}})},
		{1.2,pose({root={-3,0,0,0},waist={-5,0,0},neck={6,0,0},hip={2,0,4},knee={-4,0,0},shoulder={10,0,20},elbow={32,0,0},wrist={-5,0,0}})},
		{2.4,pose({root={-4,0,0,-.04},waist={-8,0,0},neck={8,0,0},hip={3,0,4},knee={-6,0,0},shoulder={7,0,18},elbow={28,0,0},wrist={-5,0,0}})},
	}},
	charging={Frames={
		{0,pose({root={-4,0,0,0},waist={-8,0,0},neck={8,0,0},hip={5,0,5},knee={-10,0,0},ankle={5,0,0},shoulder={8,0,18},elbow={30,0,0}})},
		{.55,pose({root={-9,0,0,-.44},waist={-20,0,0},neck={18,0,0},hip={30,0,8},knee={-60,0,0},ankle={30,0,0},shoulder={-12,0,23},elbow={65,0,0}})},
		{1,pose({root={-12,0,0,-.9},waist={-28,0,0},neck={24,0,0},hip={52,0,10},knee={-100,0,0},ankle={48,0,0},shoulder={-20,0,25},elbow={80,0,0},wrist={-8,0,0}})},
	}},
	launching={Frames={
		{0,pose({root={-12,0,0,-.18},waist={-22,0,0},neck={20,0,0},hip={28,0,8},knee={-55,0,0},ankle={25,0,0},shoulder={35,0,18},elbow={65,0,0}})},
		{.12,pose({root={-14,0,0,0},waist={-10,0,0},neck={13,0,0},hip={-8,0,5},knee={-10,0,0},ankle={16,0,0},shoulder={100,0,15},elbow={25,0,0}})},
		{.32,pose({root={-12,0,0,0},waist={-8,0,0},neck={15,0,0},hip={25,0,7},knee={-50,0,0},ankle={25,0,0},shoulder={105,0,14},elbow={20,0,0},wrist={0,0,0}})},
	}},
	airborne={Frames={{0,pose({root={-12,0,0,0},waist={-8,0,0},neck={15,0,0},hip={25,0,7},knee={-50,0,0},ankle={25,0,0},shoulder={105,0,14},elbow={20,0,0},wrist={0,0,0}})}}},
	falling={Frames={{0,pose({root={-6,0,0,0},waist={-14,0,0},neck={20,0,0},hip={42,0,10},knee={-72,0,0},ankle={30,0,0},shoulder={62,0,28},elbow={42,0,0},wrist={0,0,0}})}}},
	slamming={Frames={
		{0,pose({root={-8,0,0,0},waist={-8,0,0},neck={15,0,0},hip={25,0,10},knee={-45,0,0},shoulder={105,0,14},elbow={30,0,0}})},
		{.16,pose({root={-22,0,0,0},waist={-25,0,0},neck={22,0,0},hip={10,0,7},knee={-20,0,0},ankle={15,0,0},shoulder={150,0,7},elbow={28,0,0}})},
	}},
	landing={Frames={
		{0,pose({root={-16,0,0,-.65},waist={-32,0,0},neck={28,0,0},hip={50,0,10},knee={-95,0,0},ankle={45,0,0},shoulder={42,0,10},elbow={20,0,0}})},
		{.09,pose({root={-18,0,0,-.9},waist={-38,0,0},neck={32,0,0},hip={60,0,12},knee={-110,0,0},ankle={50,0,0},shoulder={45,0,12},elbow={16,0,0}})},
		{.38,pose({root={-4,0,0,-.04},waist={-8,0,0},neck={8,0,0},hip={3,0,4},knee={-6,0,0},shoulder={7,0,18},elbow={28,0,0}})},
	}},
	roaring={Frames={
		{0,pose({root={-4,0,0,-.04},waist={-8,0,0},neck={8,0,0},hip={4,0,8},knee={-8,0,0},shoulder={8,0,20},elbow={30,0,0}})},
		{.3,pose({root={-7,0,0,-.15},waist={-18,0,0},neck={18,0,0},hip={8,0,10},knee={-18,0,0},shoulder={55,0,22},elbow={75,0,0}})},
		{.6,pose({root={3,0,0,0},waist={8,0,0},neck={-12,0,0},hip={3,0,10},knee={-6,0,0},shoulder={-8,0,40},elbow={50,0,0}})},
		{1.05,pose({root={0,0,0,0},waist={4,0,0},neck={-8,0,0},hip={4,0,8},knee={-8,0,0},shoulder={-4,0,32},elbow={40,0,0}})},
		{1.35,pose({root={-4,0,0,-.04},waist={-8,0,0},neck={8,0,0},hip={4,0,8},knee={-8,0,0},shoulder={8,0,20},elbow={30,0,0}})},
	}},
}
local M = {Name="Rift Gamma / original Hulk motion",Version=1}
function M.Sample(phase, elapsed, power, side, speed)
	phase=phase:gsub("%-arms$","")
	side=side or 1
	if phase=="walk" or phase=="run" then
		local running=phase=="run"
		local rate=running and 8 or 5.5
		local wave=math.sin(elapsed*rate+(side<0 and math.pi or 0))
		local stride=(running and 38 or 22)*wave
		return {root={running and -13 or -6,0,0,-math.abs(math.sin(elapsed*rate))* .065},
			waist={running and -17 or -9,0,0},neck={running and 17 or 10,0,0},
			hip={stride,0,7},knee={-8-math.max(0,-wave)*(running and 65 or 38),0,0},ankle={-stride*.3,0,0},
			shoulder={10-stride*.65,0,side*20},elbow={running and 50 or 30,0,0},wrist={-5,0,0}}
	end
	local clip=clips[phase] or clips.airborne
	local time=phase=="charging" and math.clamp(power or 0,0,1) or math.max(0,elapsed or 0)
	if clip.Loop then time%=clip.Loop end
	local frames=clip.Frames
	local a,b=frames[1],frames[#frames]
	for i=1,#frames-1 do if time<=frames[i+1][1] then a,b=frames[i],frames[i+1];break end end
	local alpha=a==b and 0 or math.clamp((time-a[1])/math.max(.001,b[1]-a[1]),0,1)
	alpha=alpha*alpha*(3-2*alpha)
	local result={}
	for _,role in ipairs({"root","waist","neck","hip","knee","ankle","shoulder","elbow","wrist"}) do
		local from,to=a[2][role] or {0,0,0,0},b[2][role] or {0,0,0,0}
		local value={}
		for axis=1,4 do value[axis]=(from[axis] or 0)+((to[axis] or 0)-(from[axis] or 0))*alpha end
		if role=="shoulder" or role=="hip" then value[3]*=side end
		result[role]=value
	end
	return result
end
return M

end)()
local CatalogCtor=(function()
-- Catalog item metadata checked against Roblox's bundle API on 2026-10-19.
-- These are avatar catalog containers, NOT raw Animation asset IDs.
local items={Idle=90553825422454,Walk=137699728035178,Run=133167141310794,
	Leap=102511523957119,Fall=108019215607685}
return function()
	local cache,status,pending={}, {}, {}
	local stopped=false
	local M={Items=items,Name="Hulk Smash! Animation Pack",Creator="Gentle Blox",
		Source="https://www.roblox.com/bundles/263899055278099/Hulk-Smash-Animation-Pack"}
	function M.Get(label)
		if stopped or not items[label] then return nil,"Original Rift Gamma keyframes" end
		if cache[label] then return cache[label],status[label] end
		if status[label] and not pending[label] then return nil,status[label] end
		if not pending[label] then
			pending[label]=true;status[label]="Resolving catalog item; original motion active"
			task.spawn(function()
				-- Inspect only an Animation object returned by Roblox. Never parent/import
				-- scripts, require modules, or execute model contents.
				local ok,objects=pcall(function() return game:GetObjects("rbxassetid://"..items[label]) end)
				local resolved
				if ok and type(objects)=="table" then
					for _,object in ipairs(objects) do
						pcall(function()
							local animation=object:IsA("Animation") and object or object:FindFirstChildWhichIsA("Animation",true)
							if animation then
								local id=animation.AnimationId:match("%d+")
								if id and tonumber(id)~=items[label] and tonumber(id)>0 then resolved="rbxassetid://"..id end
							end
						end)
						pcall(function() object:Destroy() end)
					end
				end
				if stopped then return end
				pending[label]=nil
				cache[label]=resolved
				status[label]=resolved and "Playable Animation reference resolved; playback unverified" or "Catalog unavailable or no playable Animation; original motion active"
			end)
		end
		return cache[label],status[label]
	end
	function M.IsPending(label) return pending[label]==true end
	function M.Stop() stopped=true;table.clear(cache);table.clear(status);table.clear(pending) end
	return M
end

end)()
local PoseModule=(function()
-- Local poses for Motor6D, AnimationConstraint and skinned Bone rigs.
-- Only Transform is written; bind frames, attachments and movement controls are unchanged.
local RunService = game:GetService("RunService")
return function(character, Motion)
	local joints, connections = {}, {}
	local phase, power, destroyed = nil, 0, false
	local phaseSince, motionSpeed = os.clock(), 0
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
		local sideName=(tostring(joint.Name).." "..tostring(read(a0,"Name")).." "..tostring(read(part1,"Name"))):lower()
		local side=sideName:find("left",1,true) and -1 or 1
		local entry={Joint=joint,Role=role,Kind=kind,Rest=rest,Side=side}
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
	function M.Set(nextPhase, amount, speed)
		if phase~=nextPhase then phaseSince=os.clock() end
		phase,power=nextPhase,math.clamp(amount or 0,0,1)
		motionSpeed=speed or 0
		if not phase then M.Restore();M.AppliedCount=0 end
	end
	local function apply()
		if destroyed then return end
		M.Restore();M.AppliedCount=0
		if not phase then return end
		local crouching=phase=="charging"
		local armsOnly=phase:find("-arms",1,true)~=nil
		local slamming=phase:find("slamming",1,true)~=nil
		local landing=phase:find("landing",1,true)~=nil
		local alpha=crouching and power or 1
		local angles=slamming and {root=-18,waist=-20,neck=15,hip=15,knee=-25,ankle=10,shoulder=155,elbow=25,wrist=0}
			or landing and {root=-8,waist=-20,neck=15,hip=55,knee=-95,ankle=35,shoulder=45,elbow=30,wrist=0}
			or crouching and {root=-10,waist=-10,neck=12,hip=45,knee=-85,ankle=40,shoulder=35,elbow=-35}
			or {root=-12,waist=-8,neck=15,hip=25,knee=-50,ankle=25,shoulder=105,elbow=20,wrist=0}
		for _,entry in ipairs(joints) do
			local ok,err=pcall(function()
				local joint=entry.Joint
				if not joint.Parent then return end
				local arm=entry.Role=="shoulder" or entry.Role=="elbow" or entry.Role=="wrist"
				if armsOnly and not arm then return end
				local down=(crouching or landing) and entry.Role=="root" and -(M.Rig=="R6" and .55 or .9)*alpha or 0
				local x,y,z=math.rad(angles[entry.Role] or 0)*alpha,0,0
				if Motion then
					local sample=Motion.Sample(phase,os.clock()-phaseSince,power,entry.Side,motionSpeed)
					local value=sample[entry.Role] or {}
					x,y,z=math.rad(value[1] or 0),math.rad(value[2] or 0),math.rad(value[3] or 0)
					down=entry.Role=="root" and (value[4] or 0)*(M.Rig=="R6" and .61 or 1) or 0
				end
				local rotation=entry.Rest().Rotation
				local delta=rotation:Inverse()*CFrame.new(0,down,0)*CFrame.Angles(x,y,z)*rotation
				entry.Base=joint.Transform
				-- Use a rest-relative arm pose while airborne. Adding it to the clip's
				-- shoulder/elbow motion can bend arms behind the body or fold them twice.
				entry.Applied=(Motion or (not crouching and arm)) and delta or delta*entry.Base
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

end)()
local function PoseCtor(char) return PoseModule(char,HulkMotion) end
local BrandCtor=(function()
-- Exact user-supplied Rift logo. Normalized clipping stays centered after texture resizing.
-- One asynchronous download per script; failed image loading leaves the text fallback usable.
return function(url)
	local M={}
	local asset,started=nil,false
	local targets=setmetatable({},{__mode="k"})
	local function paint(image,fallback)
		if not image.Parent or not image.Parent.Parent or not asset then return end
		image.Image=asset; image.Visible=true
		if fallback and fallback.Parent then fallback.Text="" end
	end
	function M.Apply(image,fallback)
		local viewport=Instance.new("Frame")
		viewport.Name="RiftLogoViewport"; viewport.BackgroundTransparency=1; viewport.BorderSizePixel=0; viewport.ClipsDescendants=true
		viewport.Position=image.Position; viewport.Size=image.Size; viewport.AnchorPoint=image.AnchorPoint
		viewport.LayoutOrder=image.LayoutOrder; viewport.ZIndex=image.ZIndex; viewport.Parent=image.Parent
		image.Parent=viewport; image.AnchorPoint=Vector2.new()
		image.Position=UDim2.fromScale(-374/520,-298/520); image.Size=UDim2.fromScale(1254/520,1254/520)
		image.Name="RiftLogo"; image.ImageRectOffset=Vector2.new(); image.ImageRectSize=Vector2.new()
		image.ImageColor3=Color3.new(1,1,1); image.ScaleType=Enum.ScaleType.Stretch; image.Visible=false
		targets[image]=fallback or false
		if asset then paint(image,fallback); return end
		if started then return end; started=true
		task.spawn(function()
			local ok,result=pcall(function()
				local customAsset=type(getcustomasset)=="function" and getcustomasset or type(getsynasset)=="function" and getsynasset
				assert(customAsset and type(writefile)=="function" and type(isfile)=="function","Custom images unavailable")
				local path="RiftHub/rift-logo-92145dc6000c.jpg"
				if type(isfolder)=="function" and type(makefolder)=="function" and not isfolder("RiftHub") then makefolder("RiftHub") end
				if not isfile(path) then
					local bytes=game:HttpGet(url)
					assert(type(bytes)=="string" and bytes:sub(1,3)==string.char(255,216,255),"Invalid Rift logo")
					writefile(path,bytes)
				end
				local content=customAsset(path)
				assert(type(content)=="string" and content~="","Image registration failed")
				return content
			end)
			if not ok then return end
			asset=result
			for image,fallback in pairs(targets) do paint(image,fallback) end
			table.clear(targets)
		end)
	end
	return M
end

end)()
local EffectsCtor=(function()
-- Bounded local movement effects. No camera type/subject or world gravity changes.
return function(Kit)
	local M = { Enabled=true, LastError=nil }
	local pieces = {}
	local cameraOwner, cameraBase, cameraApplied
	local offsetHum, offsetBase, offsetApplied
	local pulse, shake, stopped = 0, 0, false
	local function restoreCamera()
		if cameraOwner and cameraApplied and cameraOwner.FieldOfView==cameraApplied then cameraOwner.FieldOfView=cameraBase end
		cameraOwner,cameraBase,cameraApplied=nil,nil,nil
	end
	local function restoreOffset()
		if offsetHum and offsetApplied and offsetHum.CameraOffset==offsetApplied then offsetHum.CameraOffset=offsetBase end
		offsetHum,offsetBase,offsetApplied=nil,nil,nil
	end
	function M.Clear()
		restoreCamera();restoreOffset()
		for _,p in ipairs(pieces) do p.Part:Destroy() end
		table.clear(pieces)
		pulse,shake=0,0
	end
	function M.SetEnabled(on)
		M.Enabled=on==true
		if not M.Enabled then M.Clear() end
	end
	function M.Pulse(position, strength, impact, character)
		if stopped or not M.Enabled then return end
		strength=math.clamp(strength or .5,0,1)
		pulse=math.max(pulse,impact and 5 or 3)
		shake=math.max(shake,impact and (.08+.1*strength) or .045)
		local origin=position
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances=character and {character} or {}
		params.IgnoreWater=true
		local hit=workspace:Raycast(position+Vector3.new(0,2,0),Vector3.new(0,-14,0),params)
		if not hit or hit.Normal.Y<.5 then return end
		origin=hit.Position+Vector3.new(0,.12,0)
		-- At most two small effect bursts live at once, regardless of button spam.
		while #pieces>18 do local p=table.remove(pieces,1);p.Part:Destroy() end
		for i=1,2 do
			local p=Kit.create("Part",{Name="RiftHulkShockwave",Shape=Enum.PartType.Cylinder,Anchored=true,
				CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Material=Enum.Material.Neon,
				Color=Color3.fromRGB(93,175,87),Transparency=.7,Size=Vector3.new(.08,2,2),
				CFrame=CFrame.new(origin)*CFrame.Angles(0,0,math.pi/2)},workspace)
			table.insert(pieces,{Part=p,Age=0,Life=.45+i*.12,Origin=origin,Radius=(impact and 20 or 10)*(0.5+strength),Ring=true})
		end
		if impact then
			for i=1,8 do
				local angle=i*math.pi/4
				local direction=Vector3.new(math.cos(angle),0,math.sin(angle))
				local p=Kit.create("Part",{Name="RiftHulkDebris",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,
					CastShadow=false,Material=hit.Material,Color=hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.Color or Color3.fromRGB(100,104,87),
					Size=Vector3.new(.8, .5, 1)*(0.8+strength),Position=origin,Transparency=.1},workspace)
				table.insert(pieces,{Part=p,Age=0,Life=.65,Origin=origin,Direction=direction,Radius=5+9*strength})
			end
		end
	end
	function M.Update(phase, char, hum, root, power, dt)
		if stopped or not M.Enabled then return end
		dt=math.clamp(dt or 1/60,0,.1)
		for i=#pieces,1,-1 do
			local p=pieces[i];p.Age+=dt
			if p.Age>=p.Life then p.Part:Destroy();table.remove(pieces,i)
			else
				local t=p.Age/p.Life
				p.Part.Transparency=.65+.35*t
				if p.Ring then local diameter=2+p.Radius*t;p.Part.Size=Vector3.new(.08,diameter,diameter)
				else p.Part.CFrame=CFrame.new(p.Origin+p.Direction*(p.Radius*t)+Vector3.new(0,math.sin(t*math.pi)*(1+power*3),0))*CFrame.Angles(t*2,t*3,t) end
			end
		end
		pulse=math.max(0,pulse-dt*12);shake=math.max(0,shake-dt*.45)
		local airborne=phase=="airborne" or phase=="slamming"
		local speed=root and root.AssemblyLinearVelocity.Magnitude or 0
		local amount=(phase=="charging" and power*7 or airborne and math.clamp(speed/300,0,1)*12 or 0)+pulse
		local camera=workspace.CurrentCamera
		if camera~=cameraOwner then restoreCamera();cameraOwner=camera;if camera then cameraBase=camera.FieldOfView end end
		if camera and type(cameraBase)=="number" then
			if cameraApplied and camera.FieldOfView~=cameraApplied then cameraBase=camera.FieldOfView end
			local target=math.clamp(cameraBase+amount,30,110)
			cameraApplied=camera.FieldOfView+(target-camera.FieldOfView)*(1-math.exp(-dt*9))
			camera.FieldOfView=cameraApplied
			if amount==0 and math.abs(cameraApplied-cameraBase)<.01 then restoreCamera() end
		end
		restoreOffset()
		if hum and shake>0 and typeof(hum.CameraOffset)=="Vector3" then
			offsetHum,offsetBase=hum,hum.CameraOffset
			offsetApplied=offsetBase+Vector3.new(math.sin(os.clock()*57)*shake,math.cos(os.clock()*43)*shake*.6,0)
			hum.CameraOffset=offsetApplied
		end
	end
	function M.Destroy() if stopped then return end;M.Clear();stopped=true end
	return M
end

end)()
local LeapCtor=(function()
-- Hulk traversal: charged leap, quick bound, air steering and downward smash.
return function(Utils, Kit, PoseCtor, Brand, EffectsCtor, CatalogCtor)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local player = Players.LocalPlayer
	local catalog=CatalogCtor and CatalogCtor()
	local animationIds=catalog and catalog.Items or {}
	local M = {
		Enabled = false, Phase = "off", Power = 0, LastError = nil, AnimationMode = "Original",
		AnimationIds = animationIds, EffectsEnabled = true, Bounds = 0, Slams = 0, Landings = 0, AirSteers = 0,
		ResolvedIds={}, CatalogSource=catalog and catalog.Source,
		AnimationStatus = { Crouch="Not requested", Leap="Not requested" },
		AssetErrors = {}, ButtonPresses=0, Releases=0, Launches=0, LastInput="None", Motion={Status="No launch requested"},
		Config = { ChargeSeconds = 2.2, MinUp = 55, MaxUp = 140, MinForward = 40, MaxForward = 125,
			FullChargeUp = 180, FullChargeForward = 300,
			CrouchAnimation = nil, LeapAnimation = nil,
			CrouchPoseFraction = 0.5, BoundForward = 105, BoundUp = 85, SlamDown = 180,
			AirAcceleration = 85, LandingSeconds = 0.38 },
	}
	local stopped, connections, tracks = false, {}, {}
	local gui, dock, leapButton, fill, percent, caption, boundButton, slamButton, roarButton
	local activeInput, chargeStart, activeChar, activeRoot, activeHum, animator
	local trackChar, crouch, jump, crouchAttempted, jumpAttempted
	local pose, poseChar, assets, clipSlots = nil, nil, {}, {}
	local lastPoseAttempt = -math.huge
	local flightStart, seenAir, animationNote = 0, false, nil
	local landingStart, launchSpeed, peakDown = 0, 0, 0
	local roarStart = 0
	local actionTracks, activeAction = {}, nil
	local buttonMotion, boundAt, smashAt = {}, -math.huge, -math.huge
	local effects = EffectsCtor and EffectsCtor(Kit)
	local function fx(method, ...)
		if not effects then return end
		local ok,err=pcall(effects[method], ...)
		if not ok then M.LastEffectError=tostring(err);pcall(effects.Clear) end
	end
	local dragInput, dragStart, dragPosition
	local cancel
	local function connect(signal, callback, label)
		local connection = signal:Connect(function(...)
			if stopped then return end
			local ok, err = pcall(callback, ...)
			if not ok then
				M.LastRuntimeError = (label or "Event callback") .. ": " .. tostring(err)
				M.LastError = M.LastRuntimeError
				if cancel then pcall(cancel, "Issue detected · Copy report") end
			end
		end)
		table.insert(connections, connection)
		return connection
	end
	local function body()
		local char = Utils.GetCharacter(player)
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		return char, hum, root
	end
	local function stopTrack(track)
		if track then pcall(function() if track.IsPlaying then track:Stop(0.1) end end) end
	end
	local function clearPose()
		if pose then pose:Destroy(); pose = nil end
		poseChar = nil
	end
	local function clearTracks()
		for _, track in ipairs(tracks) do
			pcall(function() track:Stop(0); track:Destroy() end)
		end
		table.clear(tracks)
		table.clear(actionTracks);activeAction=nil
		table.clear(M.ResolvedIds)
		for _, asset in ipairs(assets) do asset:Destroy() end
		table.clear(assets); table.clear(clipSlots)
		clearPose()
		M.AnimationStatus = { Crouch="Not requested", Leap="Not requested" }
		trackChar, animator, crouch, jump = nil, nil, nil, nil
		crouchAttempted, jumpAttempted, animationNote = false, false, nil
	end
	local function paint(text)
		if not gui then return end
		fill.Size = UDim2.fromScale(M.Power, 1)
		percent.Text = tostring(math.floor(M.Power * 100)) .. "%"
		leapButton.Text = M.Phase == "charging" and (M.Power >= 1 and "RELEASE\nLONG LEAP" or "CHARGING")
			or M.Phase == "airborne" and "LEAPING" or M.Phase == "slamming" and "SMASHING" or M.Phase == "landing" and "IMPACT" or "POWER\nLEAP"
		leapButton.BackgroundColor3 = M.Phase == "charging" and Color3.fromRGB(55, 132, 73) or Color3.fromRGB(34, 71, 45)
		if boundButton then boundButton.TextColor3=M.Phase=="ready" and Kit.INK or Kit.SUB end
		if slamButton then slamButton.TextColor3=M.Phase=="airborne" and Color3.fromRGB(158,237,126) or Kit.SUB end
		caption.Text = text or (M.Phase == "charging" and (M.Power >= 1 and "Maximum power · release!" or "Release to launch") or M.Phase == "airborne" and "In the air" or "Hold to charge · release to leap")
	end
	cancel = function(text, preserveEffects)
		activeInput, chargeStart = nil, nil
		activeChar, activeRoot, activeHum = nil, nil, nil
		stopTrack(crouch);stopTrack(jump)
		for _,track in pairs(actionTracks) do stopTrack(track) end
		activeAction=nil;seenAir=false
		if not preserveEffects then fx("Clear") end
		if pose then pose.Set(nil) end
		M.Power = 0
		M.Phase = M.Enabled and "ready" or "off"
		paint(text)
	end
	local function blocked(char, hum, root, requireGround)
		if not char or not hum or not root or not root.Parent or hum.Health <= 0 then return "Wait for your character" end
		if root.Anchored or hum.PlatformStand or hum.Sit then return "Character cannot leap right now" end
		if char:GetAttribute("LOCKED_INPUTS") == true or char:GetAttribute("cutsceneLock") == true or char:GetAttribute("canRun") == false then
			return "Wait for the game movement lock"
		end
		if M.CanUse then
			local ok, allowed, reason = pcall(M.CanUse)
			if not ok or not allowed then return reason or "Another movement mode is active" end
		end
		if requireGround and hum.FloorMaterial == Enum.Material.Air then return "Land before charging" end
		return nil
	end
	local function loadTrack(char, hum, id, label)
		if M.AnimationMode~="Auto" then M.AnimationStatus[label]="Original Rift Gamma keyframes";return nil end
		if not id and catalog then id,M.AnimationStatus[label]=catalog.Get(label) end
		if not id then M.AnimationStatus[label]=M.AnimationStatus[label] or "Original Rift Gamma keyframes";return nil end
		if trackChar ~= char then
			clearTracks(); trackChar = char
			animator = hum:FindFirstChildOfClass("Animator")
			if not animator then animator = Instance.new("Animator"); animator.Parent = hum end
		end
		M.ResolvedIds[label]=id
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		table.insert(assets, animation) -- retain the asset while Roblox loads its track
		local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
		if not ok then
			M.AnimationStatus[label] = "Load failed: " .. tostring(track)
			return nil
		end
		track.Priority = (label=="Idle" or label=="Walk" or label=="Run") and Enum.AnimationPriority.Movement or Enum.AnimationPriority.Action4
		track.Looped = false
		table.insert(tracks, track)
		clipSlots[track] = { Label=label, Started=os.clock(), Disabled=false, Warmed=label~="Crouch" and label~="Leap" }
		M.AnimationStatus[label] = "Loading"
		return track
	end
	local function compatible(track, char, hum)
		local slot = clipSlots[track]
		if not slot or slot.Disabled then return false end
		if M.AnimationMode ~= "Auto" then
			M.AnimationStatus[slot.Label] = "Built-in poses selected"
			return false
		end
		if track.Length <= 0 then
			if M.AssetErrors[slot.Label] then
				M.AnimationStatus[slot.Label] = "Roblox: " .. M.AssetErrors[slot.Label]
			elseif os.clock() - slot.Started > 1.5 then
				M.AnimationStatus[slot.Label] = "No clip data after 1.5s; asset access or load failure possible"
			else M.AnimationStatus[slot.Label] = "Loading; built-in pose active" end
			return false
		end
		if slot.Binding == nil then
			local ok, names = pcall(function() return track:GetTargetNames() end)
			local targetR6, targetR15 = false, false
			if ok and type(names) == "table" then
				for _, name in ipairs(names) do
					if name == "Torso" or name == "Left Arm" or name == "Right Arm" then targetR6=true end
					if name == "UpperTorso" or name == "LowerTorso" or name:find("UpperLeg",1,true) or name:find("UpperArm",1,true) then targetR15=true end
				end
			end
			local rig = tostring(hum.RigType)
			if (targetR6 and rig:find("R15",1,true)) or (targetR15 and rig:find("R6",1,true)) then
				slot.Binding = "Rig mismatch"
			elseif targetR6 or targetR15 then
				slot.Binding = "Compatible body targets"
			else
				-- An unavailable target list does not prove a rig mismatch. Try the loaded clip.
				slot.Binding = "Unverified target list"
			end
		end
		if slot.Binding == "Rig mismatch" then
			M.AnimationStatus[slot.Label] = slot.Binding .. "; using built-in pose"
			return false
		end
		M.AnimationStatus[slot.Label] = "Clip ready (" .. slot.Binding .. "), length=" .. string.format("%.3f", track.Length)
		return true
	end
	local function ensurePose(char)
		if not PoseCtor then return end
		if poseChar ~= char or (pose and os.clock()-lastPoseAttempt > 1 and (pose.Count == 0 or (pose.NeedsRefresh and pose.NeedsRefresh()))) then
			clearPose()
			lastPoseAttempt=os.clock()
			local ok, result = pcall(PoseCtor, char)
			if ok then pose, poseChar = result, char
			else M.LastPoseError = tostring(result); animationNote = "Pose unavailable: " .. tostring(result) end
		end
	end
	local function chooseAction(char,hum,label,id,looped)
		local track=actionTracks[label]
		if track==nil then
			track=loadTrack(char,hum,id,label)
			if track then actionTracks[label]=track
			elseif catalog and catalog.IsPending(label) then actionTracks[label]=nil
			else actionTracks[label]=false end
			if track then track.Looped=looped==true end
		end
		return track
	end
	local function updateAnimation()
		local char, hum, root = body()
		if not char or not hum then return end
		local charging = M.Phase == "charging"
		local label,track="Leap",jump
		local grounded=M.Phase=="ready"
		local groundPhase="idle"
		if grounded then
			local reason=blocked(char,hum,root,true)
			local tools=char:FindFirstChildOfClass("Tool")
			if reason or tools or char:GetAttribute("busy")==true or char:GetAttribute("state")=="attacking" or char:GetAttribute("state")=="skill" then
				for _,other in pairs(actionTracks) do stopTrack(other) end
				activeAction=nil;if pose then pose.Set(nil) end;return
			end
			local moving=hum.MoveDirection and hum.MoveDirection.Magnitude>.1
			groundPhase=moving and (root.AssemblyLinearVelocity.Magnitude>18 and "run" or "walk") or "idle"
			label=groundPhase=="idle" and "Idle" or groundPhase=="run" and "Run" or "Walk"
			track=chooseAction(char,hum,label,nil,true)
		end
		if grounded then -- ground clip/pose selected above
		elseif charging then label,track="Crouch",crouch
		elseif M.Phase=="roaring" then label,track="Roar",nil;M.AnimationStatus.Roar="Original Rift Gamma keyframes"
		elseif M.Phase=="slamming" then label="Slam";track=chooseAction(char,hum,label,M.Config.SlamAnimation,false)
		elseif M.Phase=="landing" then label="Land";track=chooseAction(char,hum,label,M.Config.LandAnimation,false)
		elseif root and root.AssemblyLinearVelocity.Y < -12 and seenAir then
			label="Fall";track=chooseAction(char,hum,label,M.Config.FallAnimation,true)
		end
		if activeAction~=label then
			for _,other in pairs(actionTracks) do if other~=track then stopTrack(other) end end
			if track~=jump then stopTrack(jump) end
			if track and not charging and label~="Leap" then
				pcall(function() track:Play(.12,1,1);track:AdjustWeight(1,.1);track.TimePosition=0 end)
			end
			activeAction=label
		end
		ensurePose(char)
		local useClip = track and compatible(track, char, hum)
		if useClip and not charging and not track.IsPlaying then useClip=false end
		if useClip then
			local ok, err = pcall(function()
				if not track.IsPlaying and charging then track:Play(0.1, 1, 1) end
				if charging then
					track:AdjustWeight(1, 0.05)
					local stopAt = math.max(0, track.Length - 1/60)
					track.TimePosition = math.min(stopAt, track.Length * math.clamp(M.Config.CrouchPoseFraction,0,1) * M.Power)
					track:AdjustSpeed(0)
				end
			end)
			if not ok then
				clipSlots[track].Disabled = true
				M.AnimationStatus[label] = "Playback failed: " .. tostring(err)
				useClip = false
			end
		end
		local posePhase=grounded and groundPhase or charging and "charging" or M.Phase=="roaring" and "roaring" or M.Phase=="slamming" and "slamming" or M.Phase=="landing" and "landing" or (root and root.AssemblyLinearVelocity.Y < -12 and seenAir) and "falling" or os.clock()-flightStart<.32 and "launching" or "airborne"
		if pose then
			if useClip then
				if charging or grounded then pose.Set(nil) else pose.Set(posePhase.."-arms") end
			else
				if track and track.Length > 0 then stopTrack(track) end
				pose.Set(posePhase, M.Power,root and root.AssemblyLinearVelocity.Magnitude or 0)
			end
		end
		M.LastPoseError = pose and pose.LastError or M.LastPoseError
		animationNote = useClip and (charging and "Animation clip" or label.." clip · Hulk arms") or M.LastPoseError and "Pose error · Copy report" or pose and pose.Count > 0 and "Built-in Hulk pose" or "No compatible body joints"
	end
	local function prepareAnimations()
		local char, hum, root=body()
		if not char or not hum or not root or hum.Health <= 0 then return end
		if trackChar and trackChar~=char then clearTracks() end
		if not crouchAttempted then
			crouch=loadTrack(char,hum,M.Config.CrouchAnimation,"Crouch");crouchAttempted=not(catalog and catalog.IsPending("Crouch"))
			if crouch then pcall(function() crouch:Play(0,0,1) end) end
		end
		if not jumpAttempted then
			jump=loadTrack(char,hum,M.Config.LeapAnimation,"Leap");jumpAttempted=not(catalog and catalog.IsPending("Leap"))
			if jump then pcall(function() jump:Play(0,0,1) end) end
		end
		pcall(ensurePose, char) -- so the joint count is already known before the first charge, not just reported as 0
	end
	local function finishWarmup()
		for track, slot in pairs(clipSlots) do
			if not slot.Warmed then
				if track.Length > 0 then
					slot.Warmed = true; stopTrack(track)
					M.AnimationStatus[slot.Label] = "Clip loaded; waiting for use"
				elseif os.clock()-slot.Started >= 3 then
					slot.Warmed = true; stopTrack(track)
					M.AnimationStatus[slot.Label] = M.AssetErrors[slot.Label] or "No clip data after 3s; built-in pose available"
				end
			end
		end
	end
	local function observeMotion()
		local motion=M.Motion
		if not motion.Root or motion.Done or not motion.Origin then return end
		if not motion.Root.Parent then motion.Done=true;motion.Status="Character changed before observation finished";return end
		local distance=(motion.Root.Position-motion.Origin).Magnitude
		motion.Peak=math.max(motion.Peak,distance);motion.Latest=distance
		local elapsed=os.clock()-motion.Started
		if elapsed >= 0.25 then
			motion.Status=motion.Peak >= 0.5 and "Local travel observed; server acceptance unverified" or "No local travel observed yet"
			if motion.Peak >= 3 and distance < 1 then motion.Status="Returned near start; cause unverified" end
		end
		if elapsed >= 0.8 then motion.Done=true end
	end
	local function begin(input)
		M.ButtonPresses += 1; M.LastInput=tostring(input.UserInputType) .. " begin"
		if stopped or not M.Enabled or M.Phase ~= "ready" or activeInput then return end
		local char, hum, root = body()
		local reason = blocked(char, hum, root, true)
		if reason then M.LastError = reason; paint(reason); return end
		if trackChar ~= char then clearTracks() end
		if not crouchAttempted then
			crouch = loadTrack(char, hum, M.Config.CrouchAnimation, "Crouch")
			crouchAttempted = not(catalog and catalog.IsPending("Crouch"))
		end
		activeInput, chargeStart = input, os.clock()
		activeChar, activeHum, activeRoot = char, hum, root
		M.LastError, M.Power, M.Phase = nil, 0, "charging"
		if crouch then
			local ok = pcall(function() crouch:Play(0.12, 1, 1); crouch:AdjustWeight(1, 0.12); crouch.TimePosition = 0 end)
			if not ok then animationNote = "Animation unavailable" end
		end
		updateAnimation()
		paint(animationNote)
	end
	local function launch(power, quick)
		local char, hum, root=body()
		local reason=blocked(char,hum,root,true)
		if reason then M.LastError=reason;paint(reason);return false,reason end
		activeChar,activeHum,activeRoot=char,hum,root
		activeInput,chargeStart=nil,nil
		M.Power=power
		stopTrack(crouch)
		local move=hum.MoveDirection
		local direction=Vector3.new(move.X,0,move.Z)
		if direction.Magnitude<.1 then
			local camera=workspace.CurrentCamera
			local facing=(camera and camera.CFrame and camera.CFrame.LookVector) or root.CFrame.LookVector
			direction=Vector3.new(facing.X,0,facing.Z)
		end
		if direction.Magnitude<.01 then
			local facing=root.CFrame.LookVector;direction=Vector3.new(facing.X,0,facing.Z)
		end
		if direction.Magnitude<.01 then direction=Vector3.new(0,0,-1) end
		direction=direction.Unit
		local upward=M.Config.MinUp+(M.Config.MaxUp-M.Config.MinUp)*power
		local forward=M.Config.MinForward+(M.Config.MaxForward-M.Config.MinForward)*power
		local boost=math.clamp((power-.8)/.2,0,1);boost=boost*boost*(3-2*boost)
		upward+=math.max(0,M.Config.FullChargeUp-M.Config.MaxUp)*boost
		forward+=math.max(0,M.Config.FullChargeForward-M.Config.MaxForward)*boost
		if quick then forward,upward=M.Config.BoundForward,M.Config.BoundUp end
		local targetVelocity=direction*forward+Vector3.new(0,upward,0)
		local ok,err=pcall(function()
			local mass=root.AssemblyMass
			assert(mass>0 and mass<math.huge,"Character assembly cannot move")
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			root:ApplyImpulse((targetVelocity-root.AssemblyLinearVelocity)*mass)
		end)
		if not ok then M.LastError=tostring(err);cancel("Leap could not launch");return false,M.LastError end
		M.LastError=nil;M.Launches+=1
		if quick then M.Bounds+=1;boundAt=os.clock() end
		M.Motion={Status="Impulse applied; observing travel",Root=root,Origin=root.Position,Started=os.clock(),Requested=targetVelocity,Power=power,Peak=0,Latest=0}
		if not jumpAttempted then jump=loadTrack(char,hum,M.Config.LeapAnimation,"Leap");jumpAttempted=true end
		if jump then pcall(function() jump:Play(.05,1,1);jump:AdjustWeight(1,.05);jump.TimePosition=0 end) end
		flightStart,seenAir,launchSpeed,peakDown=os.clock(),false,forward,0
		M.Phase="airborne";activeAction=nil
		fx("Pulse",root.Position,power,false,char)
		updateAnimation();paint()
		return true
	end
	local function release()
		if M.Phase~="charging" or not activeInput then return end
		M.Releases+=1;M.LastInput=tostring(activeInput.UserInputType).." release"
		local char,hum,root=body()
		local reason=blocked(char,hum,root,true)
		if char~=activeChar or root~=activeRoot or hum~=activeHum then reason="Character changed; charge cancelled" end
		if reason then M.LastError=reason;cancel(reason);return end
		local power=math.clamp((os.clock()-chargeStart)/math.max(.2,M.Config.ChargeSeconds),0,1)
		launch(power,false)
	end
	function M.Bound()
		if stopped or not M.Enabled or M.Phase~="ready" then return false end
		return launch(.35,true)
	end
	function M.Roar()
		if stopped or not M.Enabled or M.Phase~="ready" then return false end
		local char,hum,root=body()
		local reason=blocked(char,hum,root,true)
		if reason then M.LastError=reason;paint(reason);return false end
		activeChar,activeHum,activeRoot=char,hum,root
		M.Phase="roaring";roarStart=os.clock();activeAction=nil
		updateAnimation();paint("GAMMA ROAR · move to cancel")
		return true
	end
	function M.Slam()
		if stopped or not M.Enabled or M.Phase~="airborne" then return false end
		local char,hum,root=body()
		local reason=blocked(char,hum,root,false)
		if reason or char~=activeChar or root~=activeRoot or hum~=activeHum or hum.FloorMaterial~=Enum.Material.Air then
			M.LastError=reason or "Get airborne before smashing";paint(M.LastError);return false
		end
		local velocity=root.AssemblyLinearVelocity
		local target=Vector3.new(velocity.X*.22,-M.Config.SlamDown,velocity.Z*.22)
		local ok,err=pcall(function()
			local mass=root.AssemblyMass;assert(mass>0 and mass<math.huge,"Character assembly cannot move")
			root:ApplyImpulse((target-velocity)*mass)
		end)
		if not ok then M.LastError=tostring(err);return false end
		M.LastError=nil;M.Slams+=1;M.Phase="slamming";seenAir=true;smashAt=os.clock()
		updateAnimation();paint("HULK SMASH")
		return true
	end
	local function steer(hum,root,dt)
		local move=hum.MoveDirection
		local input=Vector3.new(move.X,0,move.Z)
		if input.Magnitude<.1 then return end
		local velocity=root.AssemblyLinearVelocity
		local horizontal=Vector3.new(velocity.X,0,velocity.Z)
		local speed=horizontal.Magnitude
		if speed<1 then return end
		-- Turn existing momentum; never add upward velocity or accumulate forward boosts.
		local target=input.Unit*math.min(speed,launchSpeed)
		local delta=target-horizontal
		local cap=M.Config.AirAcceleration*math.clamp(dt or 1/60,0,.05)
		if delta.Magnitude>cap and delta.Magnitude>0 then delta=delta.Unit*cap end
		if delta.Magnitude>.001 then root:ApplyImpulse(delta*root.AssemblyMass);M.AirSteers+=1 end
	end
	local function land(char,hum,root)
		M.Landings+=1
		M.Phase="landing";landingStart=os.clock()
		fx("Pulse",root.Position,math.clamp(math.max(peakDown/180,M.Power),.15,1),true,char)
		updateAnimation();paint("Heavy landing")
	end
	local function clampDock()
		if not dock or not workspace.CurrentCamera then return end
		local viewport = workspace.CurrentCamera.ViewportSize
		local x = dock.Position.X.Scale * viewport.X + dock.Position.X.Offset
		local y = dock.Position.Y.Scale * viewport.Y + dock.Position.Y.Offset
		local width, height = 216, 264
		dock.Position = UDim2.fromOffset(math.clamp(x, math.min(width + 8, viewport.X - 8), math.max(width + 8, viewport.X - 8)),
			math.clamp(y, math.min(height + 8, viewport.Y - 45), math.max(height + 8, viewport.Y - 45)))
	end
	local function makeGui()
		if gui then gui.Enabled = true; return end
		table.clear(buttonMotion)
		gui = Kit.create("ScreenGui", { Name = "RiftHulkLeap", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 910 })
		local parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
		local ok = pcall(function() gui.Parent = parent end)
		if not ok then gui.Parent = player:WaitForChild("PlayerGui") end
		dock = Kit.create("Frame", { Name = "HulkLeapDock", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -22, 1, -100),
			Size = UDim2.fromOffset(216, 264), BackgroundColor3 = Color3.fromRGB(15, 23, 18), BorderSizePixel = 0 }, gui)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 12) }, dock)
		Kit.create("UIStroke", { Color = Color3.fromRGB(64, 115, 76), Transparency = 0.2, Thickness = 1 }, dock)
		local grip = Kit.create("Frame", { Size = UDim2.new(1, -36, 0, 30), BackgroundTransparency = 1, Active = true }, dock)
		if Brand then
			local mark=Kit.create("ImageLabel",{Position=UDim2.fromOffset(10,6),Size=UDim2.fromOffset(18,18),BackgroundTransparency=1},grip)
			local fallback=Kit.create("TextLabel",{Position=UDim2.fromOffset(10,6),Size=UDim2.fromOffset(18,18),BackgroundTransparency=1,Text="R",TextSize=14,TextColor3=Kit.INK},grip)
			Brand.Apply(mark,fallback)
		end
		Kit.create("TextLabel", { Position = UDim2.fromOffset(Brand and 34 or 12, 0), Size = UDim2.new(1, Brand and -34 or -12, 1, 0), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Bold), TextSize = 11, TextColor3 = Color3.fromRGB(152, 221, 164),
			Text = "RIFT / GAMMA · 3.0", TextXAlignment = Enum.TextXAlignment.Left }, grip)
		local close = Kit.create("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(28, 26),
			BackgroundTransparency = 1, Text = "×", TextSize = 20, TextColor3 = Kit.SUB }, dock)
		leapButton = Kit.create("TextButton", { Name = "HoldLeap", Position = UDim2.fromOffset(12, 36), Size = UDim2.fromOffset(132, 90),
			BackgroundColor3 = Color3.fromRGB(34, 71, 45), BorderSizePixel = 0, AutoButtonColor = false, Active = true,
			Text = "HOLD\nLEAP", TextSize = 18, FontFace = Kit.face("BuilderSans", Enum.FontWeight.Bold), TextColor3 = Kit.INK }, dock)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 10) }, leapButton)
		local bar = Kit.create("Frame", { Name = "PowerBar", Position = UDim2.fromOffset(12, 136), Size = UDim2.fromOffset(192, 8),
			BackgroundColor3 = Color3.fromRGB(29, 42, 33), BorderSizePixel = 0, ClipsDescendants = true }, dock)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 5) }, bar)
		fill = Kit.create("Frame", { Name = "PowerFill", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.fromRGB(99, 217, 124), BorderSizePixel = 0 }, bar)
		percent = Kit.create("TextLabel", { Name = "ChargePercent", Position = UDim2.fromOffset(170, 149), Size = UDim2.fromOffset(32, 26), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Bold), TextSize = 10, TextColor3 = Kit.INK, Text = "0%" }, dock)
		caption = Kit.create("TextLabel", { Position = UDim2.fromOffset(12, 149), Size = UDim2.fromOffset(154, 26), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans"), TextSize = 10, TextColor3 = Kit.SUB, TextWrapped = true, Text = "Hold to charge · release to leap" }, dock)

		local function actionButton(name,text,x)
			local button=Kit.create("TextButton",{Name=name,Position=UDim2.fromOffset(x,127),Size=UDim2.fromOffset(92,32),
				BackgroundColor3=Color3.fromRGB(35,57,38),AutoButtonColor=true,Text=text,TextSize=12,
				FontFace=Kit.face("BuilderSans",Enum.FontWeight.Bold),TextColor3=Kit.INK,BorderSizePixel=0},dock)
			Kit.create("UICorner",{CornerRadius=UDim.new(0,8)},button)
			return button
		end
		boundButton=actionButton("QuickBound","BOUND",150)
		boundButton.Position=UDim2.fromOffset(150,36);boundButton.Size=UDim2.fromOffset(54,40)
		slamButton=actionButton("DownSlam","METEOR",150)
		slamButton.Position=UDim2.fromOffset(150,82);slamButton.Size=UDim2.fromOffset(54,44);slamButton.TextSize=10
		roarButton=actionButton("GammaRoar","GAMMA ROAR",12)
		roarButton.Position=UDim2.fromOffset(12,180);roarButton.Size=UDim2.fromOffset(192,28)
		local function animateButton(button,pressed)
			local scale=Kit.create("UIScale",{Scale=1},button)
			local motion={Scale=scale,Pressed=pressed,Hover=false}
			table.insert(buttonMotion,motion)
			if button.MouseEnter then connect(button.MouseEnter,function() motion.Hover=true end) end
			if button.MouseLeave then connect(button.MouseLeave,function() motion.Hover=false end) end
		end
		animateButton(leapButton,function() return M.Phase=="charging" end)
		animateButton(boundButton,function() return os.clock()-boundAt<.14 end)
		animateButton(slamButton,function() return os.clock()-smashAt<.14 end)
		animateButton(roarButton,function() return M.Phase=="roaring" end)
		connect(boundButton.Activated,M.Bound,"Quick bound")
		connect(slamButton.Activated,M.Slam,"Downward smash")
		connect(roarButton.Activated,M.Roar,"Gamma roar")
		local fxButton=Kit.create("TextButton",{Name="EffectsToggle",Position=UDim2.fromOffset(112,215),Size=UDim2.fromOffset(92,20),
			BackgroundTransparency=1,Text="Effects: On",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		connect(fxButton.Activated,function()
			M.EffectsEnabled=not M.EffectsEnabled
			fx("SetEnabled",M.EffectsEnabled);fxButton.Text=M.EffectsEnabled and "Effects: On" or "Effects: Off"
		end)
		local modeButton=Kit.create("TextButton",{Name="AnimationMode",Position=UDim2.fromOffset(10,215),Size=UDim2.new(.5,-12,0,20),BackgroundTransparency=1,Text="Motion: Original",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		local reportButton=Kit.create("TextButton",{Name="CopyAnimationReport",Position=UDim2.fromOffset(10,241),Size=UDim2.new(1,-20,0,18),BackgroundTransparency=1,Text="Copy animation report",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		connect(modeButton.Activated,function()
			M.AnimationMode=M.AnimationMode=="Auto" and "Original" or "Auto"
			clearTracks();prepareAnimations()
			modeButton.Text=M.AnimationMode=="Auto" and "Motion: Catalog" or "Motion: Original"
			if M.Phase~="ready" and M.Phase~="off" then updateAnimation();paint(animationNote) end
		end)
		connect(reportButton.Activated,function()
			local copy=setclipboard or toclipboard
			local ok=type(copy)=="function" and pcall(copy,M.Diagnostics())
			caption.Text=ok and "Animation report copied" or "Clipboard unavailable; report in console"
			if not ok then print(M.Diagnostics()) end
		end)

		connect(close.Activated, function() if M.OnClose then M.OnClose() else M.SetEnabled(false) end end)
		connect(leapButton.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then begin(input) end
		end)
		connect(grip.InputBegan, function(input)
			if activeInput then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragInput, dragStart, dragPosition = input, input.Position, dock.Position
			end
		end)
		clampDock()
	end
	function M.SetEnabled(on)
		if stopped then return false end
		if not on then
			M.Enabled = false; cancel(); stopTrack(jump); dragInput = nil
			if gui then gui.Enabled = false end
			if M.OnEnabledChanged then pcall(M.OnEnabledChanged, false) end
			return true
		end
		if M.Enabled and gui then gui.Enabled = true; return true end
		local priorConnections = #connections
		local ok, err = pcall(makeGui)
		if not ok then
			M.LastError = tostring(err)
			for index = #connections, priorConnections + 1, -1 do connections[index]:Disconnect(); table.remove(connections, index) end
			if gui then gui:Destroy(); gui = nil end
			M.Enabled = false; return false, M.LastError
		end
		M.Enabled, M.Phase = true, "ready"; M.Power = 0
		M.Gui = gui
		local prepared, prepareError=pcall(prepareAnimations)
		if not prepared then M.LastRuntimeError="Animation preparation: " .. tostring(prepareError) end
		paint()
		if M.OnEnabledChanged then pcall(M.OnEnabledChanged, true) end
		return true
	end
	if UIS.InputBegan then connect(UIS.InputBegan,function(input,processed)
		if processed or not M.Enabled or (UIS.GetFocusedTextBox and UIS:GetFocusedTextBox()) then return end
		if input.KeyCode==Enum.KeyCode.Z then begin(input)
		elseif input.KeyCode==Enum.KeyCode.X then M.Bound()
		elseif input.KeyCode==Enum.KeyCode.C then M.Slam()
		elseif input.KeyCode==Enum.KeyCode.R then M.Roar() end
	end,"Keyboard control") end
	connect(UIS.InputEnded, function(input)
		if activeInput and (input == activeInput or (input.UserInputType == Enum.UserInputType.MouseButton1 and activeInput.UserInputType == Enum.UserInputType.MouseButton1)) then
			if input.UserInputState == Enum.UserInputState.Cancel then cancel("Charge cancelled") else release() end
		end
		if dragInput and (input == dragInput or (input.UserInputType == Enum.UserInputType.MouseButton1 and dragInput.UserInputType == Enum.UserInputType.MouseButton1)) then dragInput = nil end
	end)
	connect(UIS.InputChanged, function(input)
		if not M.Enabled or not dragInput or not dock then return end
		if (dragInput.UserInputType == Enum.UserInputType.Touch and input ~= dragInput) or
			(dragInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end
		local delta = input.Position - dragStart
		dock.Position = UDim2.new(dragPosition.X.Scale, dragPosition.X.Offset + delta.X, dragPosition.Y.Scale, dragPosition.Y.Offset + delta.Y)
		clampDock()
	end)
	connect(UIS.WindowFocusReleased, function() dragInput = nil; if activeInput then cancel("Charge cancelled") end end)
	connect(player.CharacterRemoving, function()
		cancel("Respawning…"); stopTrack(jump); clearTracks()
	end)
	local logOk, logService=pcall(function() return game:GetService("LogService") end)
	if logOk and logService.MessageOut then
		connect(logService.MessageOut,function(message)
			if type(message)~="string" or message:find("Rift Hub / Hulk",1,true) then return end
			local lower=message:lower()
			if not (lower:find("fail",1,true) or lower:find("error",1,true) or lower:find("permission",1,true) or lower:find("not authorized",1,true)) then return end
			for label,asset in pairs(M.ResolvedIds) do
				local id = asset:match("%d+")
				if id and message:find(id,1,true) then M.AssetErrors[label]=message:gsub("[%c]"," "):sub(1,500) end
			end
		end,"Animation log observer")
	end
	local lastViewport
	connect(RunService.Heartbeat, function(dt)
		if stopped or not M.Enabled then return end
		for _,motion in ipairs(buttonMotion) do
			local target=motion.Pressed() and .95 or motion.Hover and 1.025 or 1
			motion.Scale.Scale+=(target-motion.Scale.Scale)*(1-math.exp(-18*math.clamp(dt or 1/60,0,.1)))
		end
		local char, hum, root = body()
		observeMotion()
		fx("Update",M.Phase,char,hum,root,M.Power,dt)
		local camera = workspace.CurrentCamera
		if camera and camera.ViewportSize ~= lastViewport then lastViewport = camera.ViewportSize; clampDock() end
		if trackChar and trackChar ~= char then clearTracks() end
		if M.Phase == "ready" then
			prepareAnimations()
			finishWarmup()
			if M.AnimationMode=="Original" or catalog then updateAnimation() end
		elseif M.Phase == "charging" then
			local reason = blocked(char, hum, root, true)
			if char ~= activeChar or hum ~= activeHum or root ~= activeRoot then reason = "Character changed; charge cancelled" end
			if reason then cancel(reason); return end
			M.Power = math.clamp((os.clock() - chargeStart) / math.max(0.2, M.Config.ChargeSeconds), 0, 1)
			updateAnimation()
			paint(animationNote)
		elseif M.Phase == "airborne" or M.Phase=="slamming" then
			if char~=activeChar or root~=activeRoot or hum~=activeHum or not hum or hum.Health<=0 then cancel("Wait for your character");return end
			local reason=blocked(char,hum,root,false)
			if reason then cancel(reason);return end
			if hum.FloorMaterial==Enum.Material.Air then
				seenAir=true;peakDown=math.max(peakDown,-root.AssemblyLinearVelocity.Y)
				if M.Phase=="airborne" and os.clock()-flightStart>.08 then steer(hum,root,dt) end
			end
			updateAnimation()
			local elapsed=os.clock()-flightStart
			if hum.FloorMaterial~=Enum.Material.Air and elapsed>.15 and seenAir then
				land(char,hum,root)
			elseif hum.FloorMaterial~=Enum.Material.Air and elapsed>.5 and not seenAir then cancel("Launch stopped on the ground")
			elseif elapsed>12 then cancel("Leap ended") end
		elseif M.Phase=="roaring" then
			if char~=activeChar or hum~=activeHum or root~=activeRoot or blocked(char,hum,root,true) then cancel();return end
			if hum.MoveDirection.Magnitude>.1 or os.clock()-roarStart>=1.35 then cancel(nil,true)
			else updateAnimation() end
		elseif M.Phase=="landing" then
			if char~=activeChar or hum~=activeHum or root~=activeRoot or not hum or hum.Health<=0 then cancel();return end
			local reason=blocked(char,hum,root,false)
			if reason then cancel(reason);return end
			if os.clock()-landingStart>=M.Config.LandingSeconds then
				-- Effects finish fading while normal controls and the next charge become available.
				cancel(nil,true)
			else updateAnimation() end
		end
	end)
	function M.Diagnostics()
		local char,hum,root=body()
		local function safeText(get)
			local ok,value=pcall(get);return ok and tostring(value) or "unavailable"
		end
		return table.concat({"Rift Hub / Hulk / 3.0", "Phase: " .. M.Phase .. " | pose mode: " .. M.AnimationMode,
			"Rig: " .. (hum and tostring(hum.RigType) or "none"),
			"Moves: bounds="..M.Bounds.." | smashes="..M.Slams.." | landings="..M.Landings.." | steering steps="..M.AirSteers,
			"Effects: "..tostring(M.EffectsEnabled).." | last effect error="..tostring(M.LastEffectError),
			"Other animations: Fall="..tostring(M.AnimationStatus.Fall).." | Smash="..tostring(M.AnimationStatus.Slam).." | Landing="..tostring(M.AnimationStatus.Land),
			"Inputs: presses=" .. M.ButtonPresses .. " | releases=" .. M.Releases .. " | launches=" .. M.Launches .. " | last=" .. M.LastInput,
			"Character: " .. safeText(function() return char:GetFullName() end),
			"Body: health=" .. safeText(function() return hum.Health end) .. " | floor=" .. safeText(function() return hum.FloorMaterial end)
				.. " | anchored=" .. safeText(function() return root.Anchored end) .. " | PlatformStand=" .. safeText(function() return hum.PlatformStand end),
			"Locks: canRun=" .. safeText(function() return char:GetAttribute("canRun") end) .. " | LOCKED_INPUTS=" .. safeText(function() return char:GetAttribute("LOCKED_INPUTS") end)
				.. " | cutsceneLock=" .. safeText(function() return char:GetAttribute("cutsceneLock") end),
			"Crouch source: " .. tostring(M.ResolvedIds.Crouch or "Original Rift Gamma") .. " | " .. M.AnimationStatus.Crouch,
			"Leap source: " .. tostring(M.ResolvedIds.Leap or "Original Rift Gamma") .. " | " .. M.AnimationStatus.Leap,
			"Crouch playback: playing=" .. safeText(function() return crouch.IsPlaying end) .. " | length=" .. safeText(function() return crouch.Length end)
				.. " | weight=" .. safeText(function() return crouch.WeightCurrent end) .. " | time=" .. safeText(function() return crouch.TimePosition end),
			"Leap playback: playing=" .. safeText(function() return jump.IsPlaying end) .. " | length=" .. safeText(function() return jump.Length end)
				.. " | weight=" .. safeText(function() return jump.WeightCurrent end) .. " | time=" .. safeText(function() return jump.TimePosition end),
			"Built-in joints: " .. tostring(pose and pose.Count or 0) .. " (" .. (pose and pose.Describe and pose.Describe() or "pose not initialized yet") .. ")",
			"Pose writes: " .. tostring(pose and pose.AppliedCount or 0) .. " | last pose error=" .. tostring(M.LastPoseError or (pose and pose.LastError)),
			"Current animation: " .. tostring(animationNote), "Last movement error: " .. tostring(M.LastError),
			"Last runtime error: " .. tostring(M.LastRuntimeError),
			"Movement observation: " .. M.Motion.Status .. " | peak travel=" .. string.format("%.2f",M.Motion.Peak or 0) .. " studs",
			"Requested launch velocity: " .. tostring(M.Motion.Requested),
			"Launch charge: " .. string.format("%.1f%%", (M.Motion.Power or 0) * 100),
			"Roblox crouch error: " .. tostring(M.AssetErrors.Crouch), "Roblox leap error: " .. tostring(M.AssetErrors.Leap),
			"Rig binding, asset access, and playback are client observations; server movement acceptance is unverified."}, "\n")
	end
	function M.Panic() M.SetEnabled(false); clearTracks() end
	function M.Stop()
		if stopped then return end
		M.Panic();fx("Destroy");if catalog then catalog.Stop() end; stopped = true
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections)
		if gui then gui:Destroy(); gui = nil end
		M.Gui = nil
	end
	return M
end

end)()
local brand=BrandCtor("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/assets/rift_logo.jpg")
local api=LeapCtor(Utils,Kit,PoseCtor,brand,EffectsCtor,CatalogCtor)
api.Game="Hulk"
api.Version="3.0"
local stop=api.Stop
function api.Unload()
 stop()
 if env.RiftHulkCharacter==api then env.RiftHulkCharacter=nil end
end
api.OnClose=api.Unload
local ok,err=api.SetEnabled(true)
if not ok then api.Unload();error("Rift Hulk could not open: " .. tostring(err)) end
env.RiftHulkCharacter=api
return api
