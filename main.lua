-- RiftHub-Entry: hulk-character
-- Rift Hub / Hulk / 4.2 | native animations and character physics
-- Native movement tracks, local charge crouch and character physics. Observer replication is unverified.
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
local CatalogCtor=(function()
-- Hulk catalog containers plus Roblox-documented, type-24 native fallbacks.
local items={Idle=90553825422454,Walk=137699728035178,Run=133167141310794,
 Leap=102511523957119,Fall=108019215607685,Emote=131436996931059}
local aliases={Crouch="Idle",Slam="Emote"}
-- Roblox's Werewolf set is a hunched creature fallback, not a claimed Hulk asset.
local fallback={Idle="1083195517",Walk="1083178339",Run="1083216690",Leap="1083218792",Fall="1083189019",Emote="1099492820"}
local gameSlots={Idle="idle",Walk="walk",Run="run",Leap="jump",Fall="fall"}
return function()
 local cache,status,pending,failed={}, {}, {}, {}
 local stopped=false
 local M={Items=items,Name="Hulk native animation bank",Creator="Gentle Blox / Roblox",
  Source="https://www.roblox.com/bundles/263899055278099/Hulk-Smash-Animation-Pack"}
 local function request(label)
  if stopped or not items[label] or pending[label] or status[label] then return end
  pending[label]=true;status[label]="Resolving Hulk catalog reference"
  task.spawn(function()
   local ok,objects=pcall(function() return game:GetObjects("rbxassetid://"..items[label]) end)
   local resolved
   if ok and type(objects)=="table" then
    for _,object in ipairs(objects) do
     pcall(function()
      local animation=object:IsA("Animation") and object or object:FindFirstChildWhichIsA("Animation",true)
      if animation then
       local id=animation.AnimationId:match("%d+")
       if id and tonumber(id)>0 and tonumber(id)~=items[label] then resolved="rbxassetid://"..id end
      end
     end)
     pcall(function() object:Destroy() end)
    end
   end
   if stopped then return end
   pending[label]=nil;cache[label]=resolved
   status[label]=resolved and "Hulk catalog native reference" or "Hulk catalog unavailable"
  end)
 end
 function M.Get(requested,rig,char)
  local label=aliases[requested] or requested
  if stopped then return nil,"Animation bank stopped" end
  if tostring(rig):find("R6",1,true) then
   -- Keep R6 clips tied to the actual game's rig; never play an R15 pack on it.
   local animate=char and char:FindFirstChild("Animate")
   local folder=animate and gameSlots[label] and animate:FindFirstChild(gameSlots[label])
   local animation=folder and folder:FindFirstChildWhichIsA("Animation",true)
   local id=animation and animation.AnimationId
   if type(id)=="string" and id:match("%d+") and not failed[id] then return id,"Existing game R6 animation" end
   return nil,"No native R6 "..requested.." clip available"
  end
  request(label)
  local primary=cache[label]
  if primary and not failed[primary] then return primary,"Hulk catalog" end
  local raw=fallback[label]
  local backup=raw and "rbxassetid://"..raw
  if backup and not failed[backup] then return backup,"Roblox Werewolf fallback" end
  return nil,pending[label] and "Resolving Hulk animation; no playable fallback" or "Native "..requested.." unavailable; game animation retained"
 end
 function M.Fail(id,reason) failed[id]=reason or true end
 function M.IsPending(label) return pending[aliases[label] or label]==true end
 function M.Stop() stopped=true;table.clear(cache);table.clear(status);table.clear(pending);table.clear(failed) end
 return M
end

end)()
local ChargeCtor=(function()
-- Authored charge-only local crouch. Native tracks still handle movement in the air.
-- Applied after Animator evaluation; no HipHeight, controls or root physics changes.
return function()
 local RunService=game:GetService("RunService")
 local M={Status="Inactive",Count=0}
 local character,connection,power
 local joints={}
 local function restore()
  for _,entry in ipairs(joints) do
   pcall(function() if entry.Joint.Transform==entry.Applied then entry.Joint.Transform=entry.Base end end)
  end
 end
 function M.Clear()
  if connection then connection:Disconnect();connection=nil end
  restore();table.clear(joints);character=nil;M.Count=0;M.Status="Inactive"
 end
 local function apply()
  local amount=.2+.8*math.clamp(power or 0,0,1)
  for _,entry in ipairs(joints) do
   pcall(function()
    local current=entry.Joint.Transform
    local base=current==entry.Applied and entry.Base or current
    local offset=CFrame.new(0,entry.Drop*amount,0)*CFrame.Angles(math.rad(entry.Angle*amount),0,0)
    entry.Base=base;entry.Applied=base*offset;entry.Joint.Transform=entry.Applied
   end)
  end
 end
 function M.Update(char,value)
  if character~=char then
   M.Clear();character=char
   if not char then return end
   for _,joint in ipairs(char:GetDescendants()) do
    local kind=joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") or joint:IsA("Bone")
    if kind then
     local name=joint.Name:lower():gsub("[%s_%-]","")
     local angle,drop=0,0
     if name=="root" or name=="rootjoint" then drop=-.8
     elseif name:find("knee",1,true) then angle=-95
     elseif name:find("hip",1,true) then angle=48
     elseif name:find("ankle",1,true) then angle=44
     elseif name=="waist" then angle=-25
     elseif name:find("shoulder",1,true) then angle=-18
     elseif name:find("elbow",1,true) then angle=65 end
     if angle~=0 or drop~=0 then table.insert(joints,{Joint=joint,Angle=angle,Drop=drop}) end
    end
   end
   M.Count=#joints
   M.Status=M.Count>0 and "Local charge crouch" or "No supported crouch joints; native stance retained"
   connection=RunService.PreSimulation:Connect(apply)
  end
  power=value;apply()
 end
 return M
end

end)()
local NativeCtor=(function()
-- Native movement tracks with an isolated authored charge-crouch helper.
return function(player, Utils, bank, ChargeCtor)
	local crouch=ChargeCtor and ChargeCtor()
	local tracks, assets, errors, connections = {}, {}, {}, {}
	local character, humanoid, animator, current, stopped
	local M={Enabled=true,Status="Waiting for character Animator",Stage="None"}
	local function destroySlot(slot)
		if slot.Track then pcall(function() slot.Track:Stop(.12);slot.Track:Destroy() end) end
		if slot.Asset then slot.Asset:Destroy() end
	end
	function M.StopAll()
		if crouch then crouch.Clear() end
		for _,slot in pairs(tracks) do
			if slot.Track and slot.Track.IsPlaying then pcall(function() slot.Track:Stop(.12) end) end
		end
		current=nil
	end
	function M.Clear()
		M.StopAll()
		for _,slot in pairs(tracks) do destroySlot(slot) end
		table.clear(tracks);table.clear(assets);table.clear(errors)
		character,humanoid,animator=nil,nil,nil
	end
	local function bind()
		local char=Utils.GetCharacter(player)
		local hum=char and char:FindFirstChildOfClass("Humanoid")
		local found=hum and hum:FindFirstChildOfClass("Animator")
		if char~=character or hum~=humanoid or found~=animator then
			M.Clear();character,humanoid,animator=char,hum,found
		end
		if not animator then M.Status="Waiting for existing character Animator";return false end
		return hum and hum.Health>0
	end
	local function getTrack(label)
		local id,source=bank.Get(label,humanoid.RigType,character)
		if not id then M.Status=source or "Native animation unavailable";return nil end
		local slot=tracks[label]
		if slot and slot.Id~=id then destroySlot(slot);tracks[label]=nil;slot=nil end
		if not slot then
			local asset=Instance.new("Animation");asset.AnimationId=id
			local ok,track=pcall(function() return animator:LoadAnimation(asset) end)
			if not ok then
				asset:Destroy();errors[label]=tostring(track);bank.Fail(id,tostring(track));M.Status="Animation denied: "..label;return nil
			end
			local ground=label=="Idle" or label=="Walk" or label=="Run"
			track.Priority=ground and Enum.AnimationPriority.Movement or Enum.AnimationPriority.Action4
			track.Looped=ground or label=="Crouch" or label=="Fall"
			errors[label]=nil
			slot={Id=id,Source=source,Track=track,Asset=asset,Started=os.clock(),Label=label}
			tracks[label]=slot
		end
		if errors[label] and slot.Track.Length<=0 then
			bank.Fail(slot.Id,errors[label]);M.Status="Animation failed: "..label;return nil
		end
		if slot.Track.Length<=0 and os.clock()-slot.Started>3 then
			errors[label]="No clip data after 3 seconds"
			bank.Fail(slot.Id,errors[label]);M.Status="Animation unavailable: "..label;return nil
		end
		return slot
	end
	function M.Prepare()
		if stopped or not M.Enabled or not bind() then return end
		for _,label in ipairs({"Idle","Walk","Run","Crouch","Leap","Fall","Slam","Emote"}) do
			local slot=getTrack(label)
			if slot and not slot.Primed then
				slot.Primed=true
				pcall(function() slot.Track:Play(0,0,1) end)
			end
			if slot and current~=slot and slot.Primed and slot.Track.IsPlaying and slot.Track.Length>0 then
				pcall(function() slot.Track:Stop(0) end)
			end
		end
	end
	local function updateNative(phase,power)
		if stopped or not M.Enabled then M.StopAll();M.Status="Native animations off";return M.Status end
		if not bind() then return M.Status end
		local root=character:FindFirstChild("HumanoidRootPart")
		if not root then M.StopAll();M.Status="Waiting for character root";return M.Status end
		local label
		if phase=="charging" then label="Crouch"
		elseif phase=="slamming" then label="Slam"
		elseif phase=="roaring" then label="Emote"
		elseif phase=="airborne" then label=root.AssemblyLinearVelocity.Y < -12 and "Fall" or "Leap"
		elseif phase=="ready" then
			if humanoid.FloorMaterial==Enum.Material.Air or humanoid.PlatformStand or humanoid.Sit
				or character:GetAttribute("busy")==true or character:GetAttribute("canRun")==false
				or character:GetAttribute("LOCKED_INPUTS")==true or character:GetAttribute("cutsceneLock")==true
				or character:GetAttribute("state")=="attacking" or character:GetAttribute("state")=="skill"
				or character:FindFirstChildOfClass("Tool") then
				M.StopAll();M.Status="Game controls own the current animation";return M.Status
			end
			label=humanoid.MoveDirection.Magnitude>.1 and (root.AssemblyLinearVelocity.Magnitude>18 and "Run" or "Walk") or "Idle"
		else M.StopAll();M.Status="Using game landing animation";return M.Status end
		M.Stage=label
		local slot=getTrack(label)
		if not slot then M.StopAll();return M.Status end
		local track=slot.Track
		if current~=slot then
			M.StopAll();current=slot
			local ok,err=pcall(function() track:Play(label=="Leap" and .06 or .16,1,1);track:AdjustWeight(1,.16) end)
			if not ok then errors[label]=tostring(err);bank.Fail(slot.Id,tostring(err));M.Status="Playback failed: "..label;return M.Status end
		end
		if track.Length<=0 then M.Status="Loading native "..label.."; no local pose substitute";return M.Status end
		if not track.IsPlaying and not track.Looped then M.Status=label.." native clip finished";return M.Status end
		if not track.IsPlaying then pcall(function() track:Play(label=="Leap" and .06 or .16,1,1);track:AdjustWeight(1,.16) end) end
		local speed=1
		if phase=="charging" then speed=.35+.5*math.clamp(power or 0,0,1)
		elseif label=="Slam" then speed=1.3
		elseif label=="Leap" then speed=.85
		elseif label=="Run" or label=="Walk" then
			local velocity=root.AssemblyLinearVelocity
			speed=math.clamp(Vector3.new(velocity.X,0,velocity.Z).Magnitude/(label=="Run" and 24 or 12),.7,1.5)
		end
		pcall(function() track:AdjustSpeed(speed) end)
		M.Status=label.." native track · "..tostring(slot.Source)..(phase=="charging" and crouch and " / "..crouch.Status or "")
		return M.Status
	end
	function M.Update(phase,power)
		local status=updateNative(phase,power)
		if crouch then
			local char=Utils.GetCharacter(player)
			local hum=char and char:FindFirstChildOfClass("Humanoid")
			if not stopped and M.Enabled and phase=="charging" and hum and hum.Health>0 then crouch.Update(char,power)
			else crouch.Clear() end
		end
		if phase=="charging" and crouch then M.Status=status.." / "..crouch.Status.." ("..crouch.Count.." joints)" end
		return M.Status
	end
	function M.SetEnabled(on)
		M.Enabled=on==true
		if not M.Enabled then M.StopAll() end
	end
	function M.Diagnostics()
		local lines={"Native animation status: "..M.Status,"Animator: "..tostring(animator and "Existing character Animator; server origin unverified" or "Missing"),
			"Observer replication: unverified; requires a second player/client test"}
		for _,label in ipairs({"Idle","Walk","Run","Crouch","Leap","Fall","Slam","Emote"}) do
			local slot=tracks[label]
			table.insert(lines,label..": "..(slot and (slot.Id.." | "..tostring(slot.Source).." | playing="..tostring(slot.Track.IsPlaying).." | length="..tostring(slot.Track.Length)) or "not loaded").." | error="..tostring(errors[label]))
		end
		return table.concat(lines,"\n")
	end
	local ok,log=pcall(function() return game:GetService("LogService") end)
	if ok and log.MessageOut then
		table.insert(connections,log.MessageOut:Connect(function(message)
			if stopped or type(message)~="string" or message:find("Rift Hub / Hulk",1,true) then return end
			local lower=message:lower()
			if not(lower:find("fail",1,true) or lower:find("error",1,true) or lower:find("permission",1,true) or lower:find("not authorized",1,true)) then return end
			for label,slot in pairs(tracks) do
				local id=slot.Id:match("%d+")
				if id and message:find(id,1,true) then errors[label]=message:sub(1,400);bank.Fail(slot.Id,errors[label]) end
			end
		end))
	end
	function M.Destroy()
		if stopped then return end
		M.Clear();stopped=true;bank.Stop()
		for _,c in ipairs(connections) do c:Disconnect() end
		table.clear(connections)
	end
	return M
end

end)()
local function AnimationsCtor(player,Utils) return NativeCtor(player,Utils,CatalogCtor(),ChargeCtor) end
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
return function(Utils, Kit, Brand, EffectsCtor, AnimationsCtor)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local player = Players.LocalPlayer
	local native=AnimationsCtor(player,Utils)
	local M = {
		Enabled = false, Phase = "off", Power = 0, LastError = nil, AnimationMode = "Native",
		EffectsEnabled = true, Bounds = 0, Slams = 0, Landings = 0, AirSteers = 0,
		ButtonPresses=0, Releases=0, Launches=0, LastInput="None", Motion={Status="No launch requested"},
		Config = { ChargeSeconds = 2.2, MinUp = 55, MaxUp = 140, MinForward = 40, MaxForward = 125,
			FullChargeUp = 180, FullChargeForward = 300,
			BoundForward = 105, BoundUp = 85, SlamDown = 180,
			AirAcceleration = 85, LandingSeconds = 0.38 },
	}
	local stopped, connections = false, {}
	local dockScale
	local gui, dock, leapButton, fill, percent, caption, boundButton, slamButton, roarButton
	local activeInput, chargeStart, activeChar, activeRoot, activeHum
	local flightStart, seenAir, animationNote = 0, false, nil
	local landingStart, launchSpeed, peakDown = 0, 0, 0
	local roarStart = 0
	local speedOwner,speedBase,speedApplied,speedUntil
	local glideUntil=0
	M.SpeedMode="Off"
	local function stopSpeed()
		if speedOwner and speedOwner.WalkSpeed==speedApplied then speedOwner.WalkSpeed=speedBase end
		speedOwner,speedBase,speedApplied,speedUntil=nil,nil,nil,nil;M.SpeedMode="Off"
	end
	local cooldowns, abilityButtons = {}, {}
	local airBoostUsed = false
	M.AbilityUses = {}
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
		native.StopAll();seenAir=false;airBoostUsed=false;glideUntil=0
		if not preserveEffects then fx("Clear") end
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
	local function updateAnimation()
		local ok,status=pcall(native.Update,M.Phase,M.Power)
		if not ok then M.LastAnimationError=tostring(status);animationNote="Native animation error · Copy report"
		else animationNote=status end
	end
	local function prepareAnimations() native.Prepare() end

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
		stopSpeed()
		activeInput, chargeStart = input, os.clock()
		activeChar, activeHum, activeRoot = char, hum, root
		M.LastError, M.Power, M.Phase = nil, 0, "charging"
		updateAnimation()
		paint(animationNote)
	end
	local function launch(power, quick)
		local char, hum, root=body()
		local reason=blocked(char,hum,root,true)
		if reason then M.LastError=reason;paint(reason);return false,reason end
		stopSpeed()
		activeChar,activeHum,activeRoot=char,hum,root
		activeInput,chargeStart=nil,nil
		M.Power=power
		native.StopAll()
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
		if quick=="sky" then forward,upward=18,155
		elseif quick then forward,upward=M.Config.BoundForward,M.Config.BoundUp end
		local targetVelocity=direction*forward+Vector3.new(0,upward,0)
		local ok,err=pcall(function()
			local mass=root.AssemblyMass
			assert(mass>0 and mass<math.huge,"Character assembly cannot move")
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			root:ApplyImpulse((targetVelocity-root.AssemblyLinearVelocity)*mass)
		end)
		if not ok then M.LastError=tostring(err);cancel("Leap could not launch");return false,M.LastError end
		M.LastError=nil;M.Launches+=1
		if quick==true then M.Bounds+=1;boundAt=os.clock() end
		M.Motion={Status="Impulse applied; observing travel",Root=root,Origin=root.Position,Started=os.clock(),Requested=targetVelocity,Power=power,Peak=0,Latest=0}
		flightStart,seenAir,launchSpeed,peakDown=os.clock(),false,forward,0
		airBoostUsed=false
		M.Phase="airborne"
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
		M.Phase="roaring";roarStart=os.clock()
		updateAnimation();paint("Hulk emote · move to cancel")
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
	-- Every action is a single character impulse, never a heartbeat speed/teleport loop.
	local function available(id)
		return math.max(0,(cooldowns[id] or 0)-os.clock())
	end
	function M.Cooldown(id) return available(id) end
	local function used(id,seconds)
		cooldowns[id]=os.clock()+seconds
		M.AbilityUses[id]=(M.AbilityUses[id] or 0)+1
	end
	local function facing(root)
		local cam=workspace.CurrentCamera
		local v=(cam and cam.CFrame and cam.CFrame.LookVector) or root.CFrame.LookVector
		local flat=Vector3.new(v.X,0,v.Z)
		return flat.Magnitude>.01 and flat.Unit or Vector3.new(0,0,-1)
	end
	local function impulse(root,velocity)
		local ok,err=pcall(function()
			local mass=root.AssemblyMass
			assert(mass>0 and mass<math.huge,"Character assembly cannot move")
			root:ApplyImpulse((velocity-root.AssemblyLinearVelocity)*mass)
		end)
		if not ok then M.LastError=tostring(err);paint("Move unavailable");return false end
		M.LastError=nil
		M.Motion={Status="Impulse applied; observing travel",Root=root,Origin=root.Position,Started=os.clock(),Requested=velocity,Peak=0,Latest=0}
		return true
	end
	function M.SkyLeap()
		if stopped or not M.Enabled or M.Phase~="ready" or available("SkyLeap")>0 then return false end
		local ok=launch(.65,"sky")
		if ok then used("SkyLeap",1.2);paint("SKY LEAP") end
		return ok
	end
	local function startSpeed(mode,speed,duration)
		if stopped or not M.Enabled or M.Phase~="ready" then return false end
		local char,hum,root=body()
		local reason=blocked(char,hum,root,false)
		if reason then paint(reason);return false end
		if speedOwner and (speedOwner~=hum or hum.WalkSpeed~=speedApplied) then stopSpeed() end
		if not speedOwner then speedOwner=hum;speedBase=hum.WalkSpeed end
		speedApplied=math.max(speedBase,speed);hum.WalkSpeed=speedApplied
		speedUntil=duration and os.clock()+duration or nil;M.SpeedMode=mode
		paint(mode.." · use your joystick")
		return true
	end
	function M.Sprint()
		if M.SpeedMode~="Off" then stopSpeed();paint("Normal speed");return true end
		return startSpeed("Sprint",52,nil)
	end
	function M.Overdrive()
		if available("Overdrive")>0 then return false end
		if not startSpeed("Overdrive",90,3) then return false end
		used("Overdrive",8);return true
	end
	function M.FeatherFall()
		if stopped or not M.Enabled or M.Phase~="airborne" or available("FeatherFall")>0 then return false end
		local char,hum,root=body()
		if char~=activeChar or hum~=activeHum or root~=activeRoot or blocked(char,hum,root,false) or hum.FloorMaterial~=Enum.Material.Air then return false end
		glideUntil=os.clock()+4;used("FeatherFall",6);paint("FEATHER FALL · steer with joystick")
		return true
	end
	function M.AirBoost()
		if stopped or not M.Enabled or M.Phase~="airborne" or airBoostUsed then return false end
		local char,hum,root=body()
		if char~=activeChar or hum~=activeHum or root~=activeRoot or blocked(char,hum,root,false) or hum.FloorMaterial~=Enum.Material.Air then return false end
		local velocity=root.AssemblyLinearVelocity
		local target=facing(root)*math.min(math.max(launchSpeed,110),170)+Vector3.new(0,math.max(velocity.Y,45),0)
		if not impulse(root,target) then return false end
		airBoostUsed=true;launchSpeed=Vector3.new(target.X,0,target.Z).Magnitude
		used("AirBoost",0);native.StopAll();updateAnimation();fx("Pulse",root.Position,.65,false,char);paint("AIR SURGE · once per leap")
		return true
	end
	function M.AirBrake()
		if stopped or not M.Enabled or M.Phase~="airborne" or available("AirBrake")>0 then return false end
		local char,hum,root=body()
		if char~=activeChar or hum~=activeHum or root~=activeRoot or blocked(char,hum,root,false) or hum.FloorMaterial~=Enum.Material.Air then return false end
		local velocity=root.AssemblyLinearVelocity
		if not impulse(root,Vector3.new(velocity.X*.18,velocity.Y,velocity.Z*.18)) then return false end
		used("AirBrake",.8);paint("AIR BRAKE · vertical speed preserved")
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
		local scale=math.clamp(math.min(1,(viewport.Y-64)/408,(viewport.X-16)/216),.35,1)
		if dockScale then dockScale.Scale=scale end
		local width, height = 216*scale, 408*scale
		dock.Position = UDim2.fromOffset(math.clamp(x, math.min(width + 8, viewport.X - 8), math.max(width + 8, viewport.X - 8)),
			math.clamp(y, math.min(height + 8, viewport.Y - 45), math.max(height + 8, viewport.Y - 45)))
	end
	local function makeGui()
		if gui then gui.Enabled = true; return end
		table.clear(buttonMotion);table.clear(abilityButtons)
		gui = Kit.create("ScreenGui", { Name = "RiftHulkLeap", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 910 })
		local parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
		local ok = pcall(function() gui.Parent = parent end)
		if not ok then gui.Parent = player:WaitForChild("PlayerGui") end
		dock = Kit.create("Frame", { Name = "HulkLeapDock", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -22, 1, -100),
			Size = UDim2.fromOffset(216, 408), BackgroundColor3 = Color3.fromRGB(15, 23, 18), BorderSizePixel = 0 }, gui)
		dockScale=Kit.create("UIScale",{Scale=1},dock)
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
			Text = "HULK / NATIVE · 4.2", TextXAlignment = Enum.TextXAlignment.Left }, grip)
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
		Kit.create("UIGradient",{Rotation=0,Color=ColorSequence.new(Color3.fromRGB(51,155,78),Color3.fromRGB(178,255,132))},fill)
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
		roarButton=actionButton("GammaRoar","HULK EMOTE",12)
		roarButton.Position=UDim2.fromOffset(12,180);roarButton.Size=UDim2.fromOffset(192,28)
		local function animateButton(button,pressed)
			local scale=Kit.create("UIScale",{Scale=1},button)
			local motion={Scale=scale,Pressed=pressed,Hover=false}
			table.insert(buttonMotion,motion)
			if button.MouseEnter then connect(button.MouseEnter,function() motion.Hover=true end) end
			if button.MouseLeave then connect(button.MouseLeave,function() motion.Hover=false end) end
		end
		local moves={
			{"Sprint","SUPER SPEED",M.Sprint,"Sprint"},
			{"Overdrive","OVERDRIVE",M.Overdrive,"Overdrive"},
			{"SkyLeap","SKY LEAP",M.SkyLeap,"SkyLeap"},
			{"AirBoost","AIR SURGE",M.AirBoost,"AirBoost"},
			{"AirBrake","AIR BRAKE",M.AirBrake,"AirBrake"},
			{"FeatherFall","FEATHER FALL",M.FeatherFall,"FeatherFall"},
		}
		for i,move in ipairs(moves) do
			local button=actionButton(move[1],move[2],12)
			button.Position=UDim2.fromOffset(12+((i-1)%2)*98,214+math.floor((i-1)/2)*34)
			button.Size=UDim2.fromOffset(94,30);button.TextSize=10
			local descriptor={Button=button,Id=move[1],Text=move[2],Cooldown=move[4],PressedAt=-math.huge}
			table.insert(abilityButtons,descriptor)
			animateButton(button,function() return os.clock()-descriptor.PressedAt<.16 end)
			connect(button.Activated,function()
				if move[3]() then descriptor.PressedAt=os.clock() end
			end,"Ability "..move[1])
		end
		local credit=Kit.create("TextLabel",{Position=UDim2.fromOffset(12,316),Size=UDim2.fromOffset(192,30),BackgroundTransparency=1,
			Text="N0VA_0100",TextSize=10,TextColor3=Kit.SUB,FontFace=Kit.face("BuilderSans")},dock)
		animateButton(leapButton,function() return M.Phase=="charging" end)
		animateButton(boundButton,function() return os.clock()-boundAt<.14 end)
		animateButton(slamButton,function() return os.clock()-smashAt<.14 end)
		animateButton(roarButton,function() return M.Phase=="roaring" end)
		connect(boundButton.Activated,M.Bound,"Quick bound")
		connect(slamButton.Activated,M.Slam,"Downward smash")
		connect(roarButton.Activated,M.Roar,"Gamma roar")
		local fxButton=Kit.create("TextButton",{Name="EffectsToggle",Position=UDim2.fromOffset(112,357),Size=UDim2.fromOffset(92,20),
			BackgroundTransparency=1,Text="Effects: On",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		connect(fxButton.Activated,function()
			M.EffectsEnabled=not M.EffectsEnabled
			fx("SetEnabled",M.EffectsEnabled);fxButton.Text=M.EffectsEnabled and "Effects: On" or "Effects: Off"
		end)
		local modeButton=Kit.create("TextButton",{Name="AnimationMode",Position=UDim2.fromOffset(10,357),Size=UDim2.new(.5,-12,0,20),BackgroundTransparency=1,Text="Animations: On",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		local reportButton=Kit.create("TextButton",{Name="CopyAnimationReport",Position=UDim2.fromOffset(10,383),Size=UDim2.new(1,-20,0,18),BackgroundTransparency=1,Text="Copy animation report",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		connect(modeButton.Activated,function()
			M.AnimationMode=M.AnimationMode=="Native" and "Off" or "Native"
			native.SetEnabled(M.AnimationMode=="Native")
			modeButton.Text=M.AnimationMode=="Native" and "Animations: On" or "Animations: Off"
			updateAnimation();paint(animationNote)
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
			M.Enabled = false; stopSpeed();cancel();native.Clear(); dragInput = nil
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
		elseif input.KeyCode==Enum.KeyCode.R then M.Roar()
		elseif input.KeyCode==Enum.KeyCode.V then M.Sprint()
		elseif input.KeyCode==Enum.KeyCode.B then M.Overdrive()
		elseif input.KeyCode==Enum.KeyCode.G then M.SkyLeap()
		elseif input.KeyCode==Enum.KeyCode.T then M.AirBoost()
		elseif input.KeyCode==Enum.KeyCode.Y then M.AirBrake()
		elseif input.KeyCode==Enum.KeyCode.H then M.FeatherFall() end
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
		stopSpeed();cancel("Respawning…");native.Clear()
	end)
	local lastViewport
	connect(RunService.Heartbeat, function(dt)
		if stopped or not M.Enabled then return end
		for _,motion in ipairs(buttonMotion) do
			local target=motion.Pressed() and .95 or motion.Hover and 1.025 or 1
			motion.Scale.Scale+=(target-motion.Scale.Scale)*(1-math.exp(-18*math.clamp(dt or 1/60,0,.1)))
		end
		for _,entry in ipairs(abilityButtons) do
			local remaining=available(entry.Cooldown)
			local air=entry.Id=="AirBoost" or entry.Id=="AirBrake" or entry.Id=="FeatherFall"
			local enabled=air and M.Phase=="airborne" or not air and M.Phase=="ready"
			if entry.Id=="AirBoost" and airBoostUsed then enabled=false end
			entry.Button.Text=entry.Id=="Sprint" and (M.SpeedMode~="Off" and "SPEED: "..M.SpeedMode:upper() or "SUPER SPEED") or remaining>.05 and string.format("%s %.1f",entry.Text,remaining) or entry.Text
			entry.Button.TextColor3=enabled and remaining<=.05 and Kit.INK or Kit.SUB
		end
		local char, hum, root = body()
		if speedOwner then
			if hum~=speedOwner or blocked(char,hum,root,false) or M.Phase~="ready" or hum.WalkSpeed~=speedApplied then
				stopSpeed()
			elseif speedUntil and os.clock()>=speedUntil then stopSpeed() end
		end
		observeMotion()
		fx("Update",M.Phase,char,hum,root,M.Power,dt)
		local camera = workspace.CurrentCamera
		if camera and camera.ViewportSize ~= lastViewport then lastViewport = camera.ViewportSize; clampDock() end
		if M.Phase == "ready" then
			prepareAnimations()
			updateAnimation();paint(animationNote)
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
				if M.Phase=="airborne" and os.clock()<glideUntil and root.AssemblyLinearVelocity.Y < -25 then
					local velocity=root.AssemblyLinearVelocity
					impulse(root,Vector3.new(velocity.X,-25,velocity.Z))
				end
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
		return table.concat({"Rift Hub / Hulk / 4.2", "Phase: " .. M.Phase .. " | animations: " .. M.AnimationMode,
			"Rig: " .. (hum and tostring(hum.RigType) or "none"),
			"Moves: bounds="..M.Bounds.." | smashes="..M.Slams.." | landings="..M.Landings.." | steering steps="..M.AirSteers,
			"Speed mode: "..M.SpeedMode.." | speed="..safeText(function() return hum.WalkSpeed end),
			"Effects: "..tostring(M.EffectsEnabled).." | last effect error="..tostring(M.LastEffectError),
			"Inputs: presses=" .. M.ButtonPresses .. " | releases=" .. M.Releases .. " | launches=" .. M.Launches .. " | last=" .. M.LastInput,
			"Character: " .. safeText(function() return char:GetFullName() end),
			"Body: health=" .. safeText(function() return hum.Health end) .. " | floor=" .. safeText(function() return hum.FloorMaterial end)
				.. " | anchored=" .. safeText(function() return root.Anchored end) .. " | PlatformStand=" .. safeText(function() return hum.PlatformStand end),
			"Locks: canRun=" .. safeText(function() return char:GetAttribute("canRun") end) .. " | LOCKED_INPUTS=" .. safeText(function() return char:GetAttribute("LOCKED_INPUTS") end)
				.. " | cutsceneLock=" .. safeText(function() return char:GetAttribute("cutsceneLock") end),
			native.Diagnostics(),
			"Current animation: " .. tostring(animationNote), "Last movement error: " .. tostring(M.LastError),
			"Last runtime error: " .. tostring(M.LastRuntimeError),
			"Movement observation: " .. M.Motion.Status .. " | peak travel=" .. string.format("%.2f",M.Motion.Peak or 0) .. " studs",
			"Requested launch velocity: " .. tostring(M.Motion.Requested),
			"Launch charge: " .. string.format("%.1f%%", (M.Motion.Power or 0) * 100),
			"Last native animation error: "..tostring(M.LastAnimationError),
			"Rig binding, asset access, and playback are client observations; server movement acceptance is unverified."}, "\n")
	end
	function M.Panic() M.SetEnabled(false) end
	function M.Stop()
		if stopped then return end
		M.Panic();native.Destroy();fx("Destroy");stopped = true
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections)
		if gui then gui:Destroy(); gui = nil end
		M.Gui = nil
	end
	return M
end

end)()
local brand=BrandCtor("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/assets/rift_logo.jpg")
local api=LeapCtor(Utils,Kit,brand,EffectsCtor,AnimationsCtor)
api.Game="Hulk"
api.Version="4.2"
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
