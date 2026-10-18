-- Rift Hub / Hulk / 1.1 | standalone hold-to-charge leap
-- All controller code is embedded here; only the user logo is downloaded.
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
local PoseCtor=(function()
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

end)()
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
local LeapCtor=(function()
-- Hold-to-charge character leap. One impulse on release, no teleport or forced flight.
return function(Utils, Kit, PoseCtor, Brand)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local player = Players.LocalPlayer
	local M = {
		Enabled = false, Phase = "off", Power = 0, LastError = nil, AnimationMode = "Auto",
		AnimationStatus = { Crouch="Not requested", Leap="Not requested" },
		Config = { ChargeSeconds = 2.2, MinUp = 55, MaxUp = 140, MinForward = 40, MaxForward = 125,
			CrouchAnimation = "rbxassetid://99086193071059", LeapAnimation = "rbxassetid://74116059836265",
			CrouchPoseFraction = 0.5 },
	}
	local stopped, connections, tracks = false, {}, {}
	local gui, dock, leapButton, fill, percent, caption
	local activeInput, chargeStart, activeChar, activeRoot, activeHum, animator
	local trackChar, crouch, jump, crouchAttempted, jumpAttempted
	local pose, poseChar, assets, clipSlots = nil, nil, {}, {}
	local lastPoseAttempt = -math.huge
	local flightStart, seenAir, animationNote = 0, false, nil
	local dragInput, dragStart, dragPosition
	local function connect(signal, callback)
		local connection = signal:Connect(callback)
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
		if track then pcall(function() track:Stop(0.1) end) end
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
		for _, asset in ipairs(assets) do asset:Destroy() end
		table.clear(assets); table.clear(clipSlots)
		clearPose()
		M.AnimationStatus = { Crouch="Not requested", Leap="Not requested" }
		trackChar, animator, crouch, jump = nil, nil, nil, nil
		crouchAttempted, jumpAttempted, animationNote = false, false, nil
	end
	local function paint(text)
		if not gui then return end
		fill.Size = UDim2.fromScale(1, M.Power)
		percent.Text = tostring(math.floor(M.Power * 100 + 0.5)) .. "%"
		leapButton.Text = M.Phase == "charging" and (M.Power >= 1 and "RELEASE\nTO LEAP" or "CHARGING")
			or M.Phase == "airborne" and "LEAPING" or "HOLD\nLEAP"
		leapButton.BackgroundColor3 = M.Phase == "charging" and Color3.fromRGB(55, 132, 73) or Color3.fromRGB(34, 71, 45)
		caption.Text = text or (M.Phase == "charging" and "Release to launch" or M.Phase == "airborne" and "In the air" or "Hold to charge · release to leap")
	end
	local function cancel(text)
		activeInput, chargeStart = nil, nil
		activeChar, activeRoot, activeHum = nil, nil, nil
		stopTrack(crouch)
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
		if trackChar ~= char then
			clearTracks(); trackChar = char
			animator = hum:FindFirstChildOfClass("Animator")
			if not animator then animator = Instance.new("Animator"); animator.Parent = hum end
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		table.insert(assets, animation) -- retain the asset while Roblox loads its track
		local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
		if not ok then
			M.AnimationStatus[label] = "Load failed: " .. tostring(track)
			return nil
		end
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = false
		table.insert(tracks, track)
		clipSlots[track] = { Label=label, Started=os.clock(), Disabled=false }
		M.AnimationStatus[label] = "Loading"
		return track
	end
	local function compatible(track, char, hum)
		local slot = clipSlots[track]
		if not slot or slot.Disabled then return false end
		if M.AnimationMode == "Built-in" then
			M.AnimationStatus[slot.Label] = "Built-in poses selected"
			return false
		end
		if track.Length <= 0 then
			if os.clock() - slot.Started > 1.5 then
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
			elseif targetR6 or targetR15 then slot.Binding = "Compatible body targets"
			else slot.Binding = "Binding unverified" end
		end
		if slot.Binding ~= "Compatible body targets" then
			M.AnimationStatus[slot.Label] = slot.Binding .. "; using built-in pose"
			return false
		end
		M.AnimationStatus[slot.Label] = "Clip ready, length=" .. string.format("%.3f",track.Length)
		return true
	end
	local function ensurePose(char)
		if not PoseCtor then return end
		if poseChar ~= char or (pose and pose.Count == 0 and os.clock()-lastPoseAttempt > 1) then
			clearPose()
			lastPoseAttempt=os.clock()
			local ok, result = pcall(PoseCtor, char)
			if ok then pose, poseChar = result, char
			else animationNote = "Pose unavailable: " .. tostring(result) end
		end
	end
	local function updateAnimation()
		local char, hum = body()
		if not char or not hum then return end
		local charging = M.Phase == "charging"
		local track = charging and crouch or jump
		local label = charging and "Crouch" or "Leap"
		ensurePose(char)
		local useClip = track and compatible(track, char, hum)
		if useClip and not charging and not track.IsPlaying then useClip=false end
		if useClip then
			local ok, err = pcall(function()
				if not track.IsPlaying and charging then track:Play(0.1, 1, 1) end
				if charging then
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
		if pose then
			if useClip then pose.Set(nil)
			else
				if track and track.Length > 0 then stopTrack(track) end
				pose.Set(charging and "charging" or "airborne", M.Power)
			end
		end
		animationNote = useClip and "Animation clip" or pose and pose.Count > 0 and "Built-in pose" or "No compatible body joints"
	end
	local function prepareAnimations()
		local char, hum, root=body()
		if not char or not hum or not root or hum.Health <= 0 then return end
		if trackChar and trackChar~=char then clearTracks() end
		if not crouchAttempted then
			crouch=loadTrack(char,hum,M.Config.CrouchAnimation,"Crouch");crouchAttempted=true
			if crouch then pcall(function() crouch:Play(0,0,1) end) end
		end
		if not jumpAttempted then
			jump=loadTrack(char,hum,M.Config.LeapAnimation,"Leap");jumpAttempted=true
			if jump then pcall(function() jump:Play(0,0,1) end) end
		end
	end
	local function begin(input)
		if stopped or not M.Enabled or M.Phase ~= "ready" or activeInput then return end
		local char, hum, root = body()
		local reason = blocked(char, hum, root, true)
		if reason then M.LastError = reason; paint(reason); return end
		if trackChar ~= char then clearTracks() end
		if not crouchAttempted then
			crouch = loadTrack(char, hum, M.Config.CrouchAnimation, "Crouch")
			crouchAttempted = true
		end
		activeInput, chargeStart = input, os.clock()
		activeChar, activeHum, activeRoot = char, hum, root
		M.LastError, M.Power, M.Phase = nil, 0, "charging"
		if crouch then
			local ok = pcall(function() crouch:Play(0.12, 1, 1); crouch.TimePosition = 0 end)
			if not ok then animationNote = "Animation unavailable" end
		end
		updateAnimation()
		paint(animationNote)
	end
	local function release()
		if M.Phase ~= "charging" or not activeInput then return end
		local char, hum, root = body()
		local reason = blocked(char, hum, root, true)
		if char ~= activeChar or root ~= activeRoot or hum ~= activeHum then reason = "Character changed; charge cancelled" end
		if reason then M.LastError = reason; cancel(reason); return end
		M.Power = math.clamp((os.clock() - chargeStart) / math.max(0.2, M.Config.ChargeSeconds), 0, 1)
		local power = M.Power
		activeInput, chargeStart = nil, nil
		stopTrack(crouch)
		local move = hum.MoveDirection
		local direction = Vector3.new(move.X, 0, move.Z)
		if direction.Magnitude < 0.1 then
			local facing = root.CFrame.LookVector
			direction = Vector3.new(facing.X, 0, facing.Z)
		end
		if direction.Magnitude < 0.01 then direction = Vector3.new(0, 0, -1) end
		direction = direction.Unit
		local upward = M.Config.MinUp + (M.Config.MaxUp - M.Config.MinUp) * power
		local forward = M.Config.MinForward + (M.Config.MaxForward - M.Config.MinForward) * power
		local targetVelocity = direction * forward + Vector3.new(0, upward, 0)
		local ok, err = pcall(function()
			local mass = root.AssemblyMass
			assert(mass > 0 and mass < math.huge, "Character assembly cannot move")
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			root:ApplyImpulse((targetVelocity - root.AssemblyLinearVelocity) * mass)
		end)
		if not ok then M.LastError = tostring(err); cancel("Leap could not launch"); return end
		if not jumpAttempted then jump = loadTrack(char, hum, M.Config.LeapAnimation, "Leap"); jumpAttempted = true end
		if jump then
			local played = pcall(function() jump:Play(0.05, 1, 1); jump.TimePosition=0 end)
			if not played then animationNote = "Animation unavailable" end
		end
		flightStart, seenAir = os.clock(), false
		M.Phase = "airborne"
		updateAnimation()
		paint(animationNote)
	end
	local function clampDock()
		if not dock or not workspace.CurrentCamera then return end
		local viewport = workspace.CurrentCamera.ViewportSize
		local x = dock.Position.X.Scale * viewport.X + dock.Position.X.Offset
		local y = dock.Position.Y.Scale * viewport.Y + dock.Position.Y.Offset
		local width, height = 192, 194
		dock.Position = UDim2.fromOffset(math.clamp(x, math.min(width + 8, viewport.X - 8), math.max(width + 8, viewport.X - 8)),
			math.clamp(y, math.min(height + 8, viewport.Y - 45), math.max(height + 8, viewport.Y - 45)))
	end
	local function makeGui()
		if gui then gui.Enabled = true; return end
		gui = Kit.create("ScreenGui", { Name = "RiftHulkLeap", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 910 })
		local parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
		local ok = pcall(function() gui.Parent = parent end)
		if not ok then gui.Parent = player:WaitForChild("PlayerGui") end
		dock = Kit.create("Frame", { Name = "HulkLeapDock", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -22, 1, -100),
			Size = UDim2.fromOffset(192, 194), BackgroundColor3 = Color3.fromRGB(15, 23, 18), BorderSizePixel = 0 }, gui)
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
			Text = "HULK / LEAP", TextXAlignment = Enum.TextXAlignment.Left }, grip)
		local close = Kit.create("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(28, 26),
			BackgroundTransparency = 1, Text = "×", TextSize = 20, TextColor3 = Kit.SUB }, dock)
		leapButton = Kit.create("TextButton", { Name = "HoldLeap", Position = UDim2.fromOffset(12, 36), Size = UDim2.fromOffset(118, 82),
			BackgroundColor3 = Color3.fromRGB(34, 71, 45), BorderSizePixel = 0, AutoButtonColor = false, Active = true,
			Text = "HOLD\nLEAP", TextSize = 18, FontFace = Kit.face("BuilderSans", Enum.FontWeight.Bold), TextColor3 = Kit.INK }, dock)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 10) }, leapButton)
		local bar = Kit.create("Frame", { Name = "PowerBar", Position = UDim2.fromOffset(140, 36), Size = UDim2.fromOffset(16, 82),
			BackgroundColor3 = Color3.fromRGB(29, 42, 33), BorderSizePixel = 0, ClipsDescendants = true }, dock)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 5) }, bar)
		fill = Kit.create("Frame", { Name = "PowerFill", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.fromRGB(99, 217, 124), BorderSizePixel = 0 }, bar)
		percent = Kit.create("TextLabel", { Position = UDim2.fromOffset(158, 61), Size = UDim2.fromOffset(32, 26), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Bold), TextSize = 10, TextColor3 = Kit.INK, Text = "0%" }, dock)
		caption = Kit.create("TextLabel", { Position = UDim2.fromOffset(10, 125), Size = UDim2.new(1, -20, 0, 23), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans"), TextSize = 10, TextColor3 = Kit.SUB, TextWrapped = true, Text = "Hold to charge · release to leap" }, dock)

		local modeButton=Kit.create("TextButton",{Name="AnimationMode",Position=UDim2.fromOffset(10,151),Size=UDim2.new(1,-20,0,18),BackgroundTransparency=1,Text="Pose: Auto",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		local reportButton=Kit.create("TextButton",{Name="CopyAnimationReport",Position=UDim2.fromOffset(10,171),Size=UDim2.new(1,-20,0,18),BackgroundTransparency=1,Text="Copy animation report",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		connect(modeButton.Activated,function()
			M.AnimationMode=M.AnimationMode=="Auto" and "Built-in" or "Auto"
			modeButton.Text="Pose: " .. M.AnimationMode
			if M.Phase=="charging" or M.Phase=="airborne" then updateAnimation();paint(animationNote) end
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
		pcall(prepareAnimations)
		paint()
		if M.OnEnabledChanged then pcall(M.OnEnabledChanged, true) end
		return true
	end
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
	local lastViewport
	connect(RunService.Heartbeat, function()
		if stopped or not M.Enabled then return end
		local char, hum, root = body()
		local camera = workspace.CurrentCamera
		if camera and camera.ViewportSize ~= lastViewport then lastViewport = camera.ViewportSize; clampDock() end
		if trackChar and trackChar ~= char then clearTracks() end
		if M.Phase == "ready" then
			prepareAnimations()
			stopTrack(crouch); stopTrack(jump)
		elseif M.Phase == "charging" then
			local reason = blocked(char, hum, root, true)
			if char ~= activeChar or hum ~= activeHum or root ~= activeRoot then reason = "Character changed; charge cancelled" end
			if reason then cancel(reason); return end
			M.Power = math.clamp((os.clock() - chargeStart) / math.max(0.2, M.Config.ChargeSeconds), 0, 1)
			updateAnimation()
			paint(animationNote)
		elseif M.Phase == "airborne" then
			if char ~= activeChar or not root or not hum or hum.Health <= 0 then cancel("Wait for your character"); stopTrack(jump); return end
			updateAnimation()
			if hum.FloorMaterial == Enum.Material.Air then seenAir = true end
			local elapsed = os.clock() - flightStart
			if hum.FloorMaterial ~= Enum.Material.Air and elapsed > 0.15 and (seenAir or elapsed > 0.5) then
				stopTrack(jump); cancel()
			elseif elapsed > 8 then stopTrack(jump); cancel() end
		end
	end)
	function M.Diagnostics()
		local char,hum=body()
		return table.concat({"Rift Hub / Hulk / 1.1", "Phase: " .. M.Phase .. " | pose mode: " .. M.AnimationMode,
			"Rig: " .. (hum and tostring(hum.RigType) or "none"),
			"Crouch 99086193071059: " .. M.AnimationStatus.Crouch,
			"Leap 74116059836265: " .. M.AnimationStatus.Leap,
			"Built-in joints: " .. tostring(pose and pose.Count or 0),
			"Current animation: " .. tostring(animationNote), "Last movement error: " .. tostring(M.LastError),
			"Rig binding, asset access, and playback are client observations; server movement acceptance is unverified."}, "\n")
	end
	function M.Panic() M.SetEnabled(false); clearTracks() end
	function M.Stop()
		if stopped then return end
		M.Panic(); stopped = true
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections)
		if gui then gui:Destroy(); gui = nil end
		M.Gui = nil
	end
	return M
end

end)()
local brand=BrandCtor("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/assets/rift_logo.jpg")
local api=LeapCtor(Utils,Kit,PoseCtor,brand)
api.Game="Hulk"
api.Version="1.1"
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
