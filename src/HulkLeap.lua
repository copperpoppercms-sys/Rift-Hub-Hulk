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
	local roarStart, dodgeStart = 0, 0
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
		native.StopAll();seenAir=false;airBoostUsed=false
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
	function M.Dodge(kind)
		if stopped or not M.Enabled or M.Phase~="ready" or available("Dodge")>0 then return false end
		if kind~="Left" and kind~="Right" and kind~="Back" and kind~="Rush" then return false end
		local char,hum,root=body()
		local reason=blocked(char,hum,root,true)
		if reason then M.LastError=reason;paint(reason);return false end
		local forward=facing(root)
		local right=Vector3.new(-forward.Z,0,forward.X)
		local direction=kind=="Left" and right*-1 or kind=="Right" and right or kind=="Back" and forward*-1 or forward
		local speed=kind=="Rush" and 100 or 76
		if not impulse(root,direction*speed+Vector3.new(0,root.AssemblyLinearVelocity.Y,0)) then return false end
		activeChar,activeHum,activeRoot=char,hum,root
		M.Phase="dodging";dodgeStart=os.clock();used("Dodge",.65);used(kind,0)
		fx("Pulse",root.Position,.3,false,char);updateAnimation();paint(kind=="Rush" and "GAMMA RUSH" or kind:upper().." DODGE")
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
			Text = "HULK / NATIVE · 4.1", TextXAlignment = Enum.TextXAlignment.Left }, grip)
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
			{"Left","SIDESTEP L",function() return M.Dodge("Left") end,"Dodge"},
			{"Right","SIDESTEP R",function() return M.Dodge("Right") end,"Dodge"},
			{"Back","BACKSTEP",function() return M.Dodge("Back") end,"Dodge"},
			{"Rush","GAMMA RUSH",function() return M.Dodge("Rush") end,"Dodge"},
			{"SkyLeap","SKY LEAP",M.SkyLeap,"SkyLeap"},
			{"AirBoost","AIR SURGE",M.AirBoost,"AirBoost"},
			{"AirBrake","AIR BRAKE",M.AirBrake,"AirBrake"},
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
		local credit=Kit.create("TextLabel",{Position=UDim2.fromOffset(110,316),Size=UDim2.fromOffset(94,30),BackgroundTransparency=1,
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
			M.Enabled = false; cancel();native.Clear(); dragInput = nil
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
		elseif input.KeyCode==Enum.KeyCode.V then M.Dodge("Rush")
		elseif input.KeyCode==Enum.KeyCode.B then M.Dodge("Back")
		elseif input.KeyCode==Enum.KeyCode.G then M.SkyLeap()
		elseif input.KeyCode==Enum.KeyCode.T then M.AirBoost()
		elseif input.KeyCode==Enum.KeyCode.Y then M.AirBrake() end
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
		cancel("Respawning…");native.Clear()
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
			local air=entry.Id=="AirBoost" or entry.Id=="AirBrake"
			local enabled=air and M.Phase=="airborne" or not air and M.Phase=="ready"
			if entry.Id=="AirBoost" and airBoostUsed then enabled=false end
			entry.Button.Text=remaining>.05 and string.format("%s %.1f",entry.Text,remaining) or entry.Text
			entry.Button.TextColor3=enabled and remaining<=.05 and Kit.INK or Kit.SUB
		end
		local char, hum, root = body()
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
				if M.Phase=="airborne" and os.clock()-flightStart>.08 then steer(hum,root,dt) end
			end
			updateAnimation()
			local elapsed=os.clock()-flightStart
			if hum.FloorMaterial~=Enum.Material.Air and elapsed>.15 and seenAir then
				land(char,hum,root)
			elseif hum.FloorMaterial~=Enum.Material.Air and elapsed>.5 and not seenAir then cancel("Launch stopped on the ground")
			elseif elapsed>12 then cancel("Leap ended") end
		elseif M.Phase=="dodging" then
			if char~=activeChar or hum~=activeHum or root~=activeRoot or blocked(char,hum,root,false) then cancel();return end
			if os.clock()-dodgeStart>=.28 then cancel(nil,true) else updateAnimation() end
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
		return table.concat({"Rift Hub / Hulk / 4.1", "Phase: " .. M.Phase .. " | animations: " .. M.AnimationMode,
			"Rig: " .. (hum and tostring(hum.RigType) or "none"),
			"Moves: bounds="..M.Bounds.." | smashes="..M.Slams.." | landings="..M.Landings.." | steering steps="..M.AirSteers,
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
