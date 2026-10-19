-- Hulk traversal: charged leap, quick bound, air steering and downward smash.
return function(Utils, Kit, PoseCtor, Brand, EffectsCtor)
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local player = Players.LocalPlayer
	local animationIds = {
		Idle = "rbxassetid://180435571", CS_Leap = "rbxassetid://74095507765093",
		Walk = "rbxassetid://180426354", Fall = "rbxassetid://180436148",
		CS_Downslam = "rbxassetid://113926956994381", KS_ChaseSlam = "rbxassetid://107995270438202",
	}
	local M = {
		Enabled = false, Phase = "off", Power = 0, LastError = nil, AnimationMode = "Auto",
		AnimationIds = animationIds, EffectsEnabled = true, Bounds = 0, Slams = 0, Landings = 0, AirSteers = 0,
		AnimationStatus = { Crouch="Not requested", Leap="Not requested" },
		AssetErrors = {}, ButtonPresses=0, Releases=0, Launches=0, LastInput="None", Motion={Status="No launch requested"},
		Config = { ChargeSeconds = 2.2, MinUp = 55, MaxUp = 140, MinForward = 40, MaxForward = 125,
			FullChargeUp = 180, FullChargeForward = 300,
			CrouchAnimation = "rbxassetid://99086193071059", LeapAnimation = animationIds.CS_Leap,
			CrouchPoseFraction = 0.5, BoundForward = 105, BoundUp = 85, SlamDown = 180,
			AirAcceleration = 85, LandingSeconds = 0.22 },
	}
	local stopped, connections, tracks = false, {}, {}
	local gui, dock, leapButton, fill, percent, caption, boundButton, slamButton
	local activeInput, chargeStart, activeChar, activeRoot, activeHum, animator
	local trackChar, crouch, jump, crouchAttempted, jumpAttempted
	local pose, poseChar, assets, clipSlots = nil, nil, {}, {}
	local lastPoseAttempt = -math.huge
	local flightStart, seenAir, animationNote = 0, false, nil
	local landingStart, launchSpeed, peakDown = 0, 0, 0
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
		percent.Text = tostring(math.floor(M.Power * 100)) .. "%"
		leapButton.Text = M.Phase == "charging" and (M.Power >= 1 and "RELEASE\nLONG LEAP" or "CHARGING")
			or M.Phase == "airborne" and "LEAPING" or M.Phase == "slamming" and "SMASHING" or M.Phase == "landing" and "IMPACT" or "HOLD\nLEAP"
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
			actionTracks[label]=track or false
			if track then track.Looped=looped==true end
		end
		return track
	end
	local function updateAnimation()
		local char, hum, root = body()
		if not char or not hum then return end
		local charging = M.Phase == "charging"
		local label,track="Leap",jump
		if charging then label,track="Crouch",crouch
		elseif M.Phase=="slamming" then label="Slam";track=chooseAction(char,hum,label,M.AnimationIds.CS_Downslam,false)
		elseif M.Phase=="landing" then label="Land";track=chooseAction(char,hum,label,M.AnimationIds.KS_ChaseSlam,false)
		elseif root and root.AssemblyLinearVelocity.Y < -12 and seenAir then
			label="Fall";track=chooseAction(char,hum,label,M.AnimationIds.Fall,true)
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
		local posePhase=charging and "charging" or M.Phase=="slamming" and "slamming" or M.Phase=="landing" and "landing" or "airborne"
		if pose then
			if useClip then
				if charging then pose.Set(nil) else pose.Set(posePhase.."-arms") end
			else
				if track and track.Length > 0 then stopTrack(track) end
				pose.Set(posePhase, M.Power)
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
			crouch=loadTrack(char,hum,M.Config.CrouchAnimation,"Crouch");crouchAttempted=true
			if crouch then pcall(function() crouch:Play(0,0,1) end) end
		end
		if not jumpAttempted then
			jump=loadTrack(char,hum,M.Config.LeapAnimation,"Leap");jumpAttempted=true
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
			crouchAttempted = true
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
		local width, height = 216, 246
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
			Size = UDim2.fromOffset(216, 246), BackgroundColor3 = Color3.fromRGB(15, 23, 18), BorderSizePixel = 0 }, gui)
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
			Text = "HULK / RAGE · 2.0", TextXAlignment = Enum.TextXAlignment.Left }, grip)
		local close = Kit.create("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 4), Size = UDim2.fromOffset(28, 26),
			BackgroundTransparency = 1, Text = "×", TextSize = 20, TextColor3 = Kit.SUB }, dock)
		leapButton = Kit.create("TextButton", { Name = "HoldLeap", Position = UDim2.fromOffset(12, 36), Size = UDim2.fromOffset(132, 82),
			BackgroundColor3 = Color3.fromRGB(34, 71, 45), BorderSizePixel = 0, AutoButtonColor = false, Active = true,
			Text = "HOLD\nLEAP", TextSize = 18, FontFace = Kit.face("BuilderSans", Enum.FontWeight.Bold), TextColor3 = Kit.INK }, dock)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 10) }, leapButton)
		local bar = Kit.create("Frame", { Name = "PowerBar", Position = UDim2.fromOffset(154, 36), Size = UDim2.fromOffset(16, 82),
			BackgroundColor3 = Color3.fromRGB(29, 42, 33), BorderSizePixel = 0, ClipsDescendants = true }, dock)
		Kit.create("UICorner", { CornerRadius = UDim.new(0, 5) }, bar)
		fill = Kit.create("Frame", { Name = "PowerFill", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.fromRGB(99, 217, 124), BorderSizePixel = 0 }, bar)
		percent = Kit.create("TextLabel", { Name = "ChargePercent", Position = UDim2.fromOffset(175, 61), Size = UDim2.fromOffset(32, 26), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans", Enum.FontWeight.Bold), TextSize = 10, TextColor3 = Kit.INK, Text = "0%" }, dock)
		caption = Kit.create("TextLabel", { Position = UDim2.fromOffset(10, 163), Size = UDim2.new(1, -20, 0, 23), BackgroundTransparency = 1,
			FontFace = Kit.face("BuilderSans"), TextSize = 10, TextColor3 = Kit.SUB, TextWrapped = true, Text = "Hold to charge · release to leap" }, dock)

		local function actionButton(name,text,x)
			local button=Kit.create("TextButton",{Name=name,Position=UDim2.fromOffset(x,127),Size=UDim2.fromOffset(92,32),
				BackgroundColor3=Color3.fromRGB(35,57,38),AutoButtonColor=true,Text=text,TextSize=12,
				FontFace=Kit.face("BuilderSans",Enum.FontWeight.Bold),TextColor3=Kit.INK,BorderSizePixel=0},dock)
			Kit.create("UICorner",{CornerRadius=UDim.new(0,8)},button)
			return button
		end
		boundButton=actionButton("QuickBound","BOUND",12)
		slamButton=actionButton("DownSlam","SMASH",112)
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
		connect(boundButton.Activated,M.Bound,"Quick bound")
		connect(slamButton.Activated,M.Slam,"Downward smash")
		local fxButton=Kit.create("TextButton",{Name="EffectsToggle",Position=UDim2.fromOffset(112,192),Size=UDim2.fromOffset(92,20),
			BackgroundTransparency=1,Text="Effects: On",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		connect(fxButton.Activated,function()
			M.EffectsEnabled=not M.EffectsEnabled
			fx("SetEnabled",M.EffectsEnabled);fxButton.Text=M.EffectsEnabled and "Effects: On" or "Effects: Off"
		end)
		local modeButton=Kit.create("TextButton",{Name="AnimationMode",Position=UDim2.fromOffset(10,192),Size=UDim2.new(.5,-12,0,20),BackgroundTransparency=1,Text="Pose: Auto",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		local reportButton=Kit.create("TextButton",{Name="CopyAnimationReport",Position=UDim2.fromOffset(10,218),Size=UDim2.new(1,-20,0,18),BackgroundTransparency=1,Text="Copy animation report",TextSize=10,FontFace=Kit.face("BuilderSans"),TextColor3=Kit.SUB},dock)
		connect(modeButton.Activated,function()
			M.AnimationMode=M.AnimationMode=="Auto" and "Built-in" or "Auto"
			modeButton.Text="Pose: " .. M.AnimationMode
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
		elseif input.KeyCode==Enum.KeyCode.C then M.Slam() end
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
			for label,asset in pairs({Crouch=M.Config.CrouchAnimation,Leap=M.Config.LeapAnimation,Fall=M.AnimationIds.Fall,Slam=M.AnimationIds.CS_Downslam,Land=M.AnimationIds.KS_ChaseSlam}) do
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
		return table.concat({"Rift Hub / Hulk / 2.0", "Phase: " .. M.Phase .. " | pose mode: " .. M.AnimationMode,
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
			"Crouch " .. M.Config.CrouchAnimation .. ": " .. M.AnimationStatus.Crouch,
			"Leap " .. M.Config.LeapAnimation .. ": " .. M.AnimationStatus.Leap,
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
		M.Panic();fx("Destroy"); stopped = true
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections)
		if gui then gui:Destroy(); gui = nil end
		M.Gui = nil
	end
	return M
end
