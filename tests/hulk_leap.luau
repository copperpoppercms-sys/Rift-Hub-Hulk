-- Lifecycle/input fixture. Does not simulate Roblox physics, animation access, or server rules.
local checks=0
local function check(value,why) assert(value,why);checks+=1 end
local function near(actual,expected) check(math.abs(actual-expected)<.00001,tostring(actual).." differs from "..tostring(expected)) end
local function signal()
	local s={connections={}}
	function s:Connect(fn)
		local c={Connected=true,fn=fn};function c:Disconnect() self.Connected=false end
		table.insert(self.connections,c);return c
	end
	function s:Fire(...) for _,c in ipairs(self.connections) do if c.Connected then c.fn(...) end end end
	function s:Count() local n=0;for _,c in ipairs(self.connections) do if c.Connected then n+=1 end end;return n end
	return s
end
local Enum=setmetatable({},{__index=function(t,k)
	local child=setmetatable({},{__index=function(_,v) return k.."."..v end});rawset(t,k,child);return child
end})
local vector={}
local Vector3={}
function Vector3.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vector) end
Vector3.zero=Vector3.new()
vector.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vector.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vector.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vector.__index=function(a,key)
	if key=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
	if key=="Unit" then return Vector3.new(a.X/a.Magnitude,a.Y/a.Magnitude,a.Z/a.Magnitude) end
end
local Vector2={new=function(x,y) return Vector3.new(x,y,0) end}
local UDim2={new=function(xs,xo,ys,yo) return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}} end}
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
local UDim={new=function(...) return {...} end}
local Color3={fromRGB=function(...) return {...} end}
local cf={}
local CFrame={}
function CFrame.new(x,y,z) if type(x)=="table" then x,y,z=x.X,x.Y,x.Z end;return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,Angle=0},cf) end
function CFrame.Angles(x,y,z) local c=CFrame.new();c.Angle=x or 0;return c end
cf.__index=function(c,key)
 if key=="Rotation" then return CFrame.Angles(c.Angle,0,0) end
 if key=="Inverse" then return function(self) local v=CFrame.new(-self.X,-self.Y,-self.Z);v.Angle=-self.Angle;return v end end
end
cf.__mul=function(a,b) local c=CFrame.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z);c.Angle=a.Angle+b.Angle;return c end
local clipboard
local setclipboard=function(value) clipboard=value end
local created,failClass={},nil
local function object(class,props,parent)
	if class==failClass then error("simulated UI failure") end
	local o={ClassName=class,children={},InputBegan=signal(),Activated=signal(),Parent=parent}
	for key,value in pairs(props or {}) do o[key]=value end
	if parent and parent.children then table.insert(parent.children,o) end
	function o:Play() self.IsPlaying=true end
	function o:Stop() self.IsPlaying=false end
	function o:IsA(kind) return self.ClassName==kind or (kind=="BasePart" and self.ClassName=="Part") end
	function o:Destroy() for _,child in ipairs(self.children) do child:Destroy() end;self.Parent=nil;self.Destroyed=true end
	table.insert(created,o);return o
end
local Instance={new=function(class) return object(class) end}
local animationTracks,animationFailure,animationLength,targetNames={},false,2,{"UpperTorso","LeftUpperArm"}
local function character(rig)
	local animator={}
	function animator:LoadAnimation(animation)
		if animationFailure then error("animation access denied") end
		local t={Id=animation.AnimationId,Length=animationLength,IsPlaying=false,TimePosition=0,Destroyed=false}
		function t:Play(_,weight,speed)
			-- Simulate a warm track whose existing weight is retained when Play is called again.
			if not self.IsPlaying then self.WeightCurrent=weight end
			self.IsPlaying=true;self.Speed=speed
		end
		function t:AdjustWeight(weight) self.WeightCurrent=weight end
		function t:GetTargetNames() return targetNames end
		function t:AdjustSpeed(speed) self.Speed=speed end
		function t:Stop() self.IsPlaying=false;self.StopCalls=(self.StopCalls or 0)+1 end
		function t:Destroy() self.Destroyed=true end
		table.insert(animationTracks,t);return t
	end
	local root={Parent={},Anchored=false,AssemblyMass=10,AssemblyLinearVelocity=Vector3.zero,Position=Vector3.zero,CFrame={LookVector=Vector3.new(0,0,-1)},impulses=0}
	function root:ApplyImpulse(impulse) self.impulses+=1;self.AssemblyLinearVelocity=self.AssemblyLinearVelocity+impulse*(1/self.AssemblyMass) end
	local hum={RigType=rig or Enum.HumanoidRigType.R15,Health=100,FloorMaterial=Enum.Material.Concrete,PlatformStand=false,Sit=false,WalkSpeed=24,CameraOffset=Vector3.zero,MoveDirection=Vector3.zero}
	function hum:FindFirstChildOfClass(class) if class=="Animator" then return animator end end
	function hum:ChangeState(state) self.LastState=state end
	local char={root=root,hum=hum,attributes={},joints={}}
	local names=rig==Enum.HumanoidRigType.R6 and {"RootJoint","Left Hip","Right Hip","Left Shoulder","Right Shoulder"} or {"Root","Waist","LeftHip","RightHip","LeftKnee","RightKnee","LeftShoulder","RightShoulder"}
	for _,name in ipairs(names) do
	 local joint={Name=name,Parent={},Part0={Name=name=="Root" and "HumanoidRootPart" or "Torso"},Part1={},C0=CFrame.new(),Transform=CFrame.new()}
	 function joint:IsA(class) return class=="Motor6D" end
	 table.insert(char.joints,joint)
	end
	function char:GetDescendants() return self.joints end
	function char:FindFirstChildOfClass(class) if class=="Humanoid" then return hum end end
	function char:FindFirstChild(name) if name=="HumanoidRootPart" then return root end end
	function char:GetAttribute(key) return self.attributes[key] end
	return char
end
local player={Character=character(),CharacterRemoving=signal()}
function player:WaitForChild() return {} end
local UIS={InputBegan=signal(),InputEnded=signal(),InputChanged=signal(),WindowFocusReleased=signal()}
local run={Heartbeat=signal(),PreAnimation=signal(),PreSimulation=signal()}
local logs={MessageOut=signal()}
local workspace={CurrentCamera={ViewportSize=Vector3.new(390,844,0),FieldOfView=70}}
local RaycastParams={new=function() return {} end}
local rayHit=nil
function workspace:Raycast() return rayHit end
local function typeof(value) return getmetatable(value)==vector and "Vector3" or type(value) end
local game={GetService=function(_,name)
	if name=="Players" then return {LocalPlayer=player} elseif name=="RunService" then return run elseif name=="UserInputService" then return UIS elseif name=="LogService" then return logs else return {} end
end}
local Kit={create=object,face=function() return "font" end,SUB="sub",INK="ink"}
local Utils={GetCharacter=function() return player.Character end}
local clock=0
local os={clock=function() return clock end}
local createPose=(function()
-- POSE
end)()
local createEffects=(function()
-- EFFECTS
end)()
local createRaw=(function()
-- HULK LEAP
end)()
-- Clip-path fixtures use explicit test assets; the published default is Original with no clip IDs.
local function create(...)
 local m=createRaw(...)
 m.AnimationMode="Auto"
 m.Config.CrouchAnimation="rbxassetid://90000000000001"
 m.Config.LeapAnimation="rbxassetid://90000000000002"
 m.Config.FallAnimation="rbxassetid://90000000000003"
 m.Config.SlamAnimation="rbxassetid://90000000000004"
 m.Config.LandAnimation="rbxassetid://90000000000005"
 return m
end
local motion=(function()
-- MOTION
end)()
local task={spawn=function(fn) fn() end}
local catalogCtor=(function()
-- CATALOG
end)()
local function step(dt) clock+=dt;run.PreAnimation:Fire();run.PreSimulation:Fire();run.Heartbeat:Fire(dt) end
local function widget(name)
	for i=#created,1,-1 do if created[i].Name==name and not created[i].Destroyed then return created[i] end end
	error("missing widget "..name)
end
local function touch() return {UserInputType=Enum.UserInputType.Touch,UserInputState=Enum.UserInputState.Begin,Position=Vector3.new(200,200,0)} end
local function mouse() return {UserInputType=Enum.UserInputType.MouseButton1,UserInputState=Enum.UserInputState.Begin,Position=Vector3.new(200,200,0)} end
local function land(m)
	player.Character.hum.FloorMaterial=Enum.Material.Air;step(.2)
	player.Character.hum.FloorMaterial=Enum.Material.Concrete;step(.4)
	check(m.Phase=="landing","touchdown did not enter the Hulk landing pose")
	step(.39)
	check(m.Phase=="ready","landing did not reset the charge")
end
local m=create(Utils,Kit,createPose)
check(not m.Enabled and m.Phase=="off","leap enabled itself")
check(m.SetEnabled(true),"control could not open")
local button=widget("HoldLeap")
local a,b=touch(),touch()
button.InputBegan:Fire(a);step(1.1)
near(m.Power,.5);check(m.Phase=="charging","hold did not charge")
local squat=animationTracks[1]
check(squat.Id=="rbxassetid://90000000000001" and squat.IsPlaying,"wrong squat animation")
near(squat.TimePosition,.5);near(squat.Speed,0);near(squat.WeightCurrent,1)
UIS.InputEnded:Fire(b)
check(m.Phase=="charging" and player.Character.root.impulses==0,"other finger released the charge")
button.InputBegan:Fire(b);step(5)
near(m.Power,1);near(squat.TimePosition,1)
check(player.Character.root.impulses==0,"full charge launched while still held")
check(m.SetEnabled(true) and m.Phase=="charging","opening existing controls reset an active charge")
UIS.InputEnded:Fire(a)
check(m.Phase=="airborne" and player.Character.root.impulses==1,"release did not launch exactly once")
near(player.Character.root.AssemblyLinearVelocity.Y,180);near(player.Character.root.AssemblyLinearVelocity.Z,-300)
check(not squat.IsPlaying and animationTracks[2].Id=="rbxassetid://90000000000002","launch animation missing")
UIS.InputEnded:Fire(a);button.InputBegan:Fire(b)
check(player.Character.root.impulses==1 and m.Phase=="airborne","repeated release or midair input launched twice")
land(m)
-- Partial charge respects the current movement direction and does not accumulate old velocity.
player.Character.hum.MoveDirection=Vector3.new(1,0,0)
local c=mouse();button.InputBegan:Fire(c);step(1.1);UIS.InputEnded:Fire(mouse())
near(player.Character.root.AssemblyLinearVelocity.X,82.5);near(player.Character.root.AssemblyLinearVelocity.Y,97.5);near(player.Character.root.AssemblyLinearVelocity.Z,0)
near(player.Character.hum.WalkSpeed,24)
land(m)
-- Strong launch builds smoothly at the top of the bar, is capped, and displays honest percentages.
local previousForward,previousUp=0,0
for _,power in ipairs({0.8,0.9,0.999,1,2}) do
 button.InputBegan:Fire(a);step(2.2*power)
 local charge=math.clamp(power,0,1)
 near(m.Power,charge)
 -- Clock subtraction can differ by an ulp at the exact boundary.
 if power==0.999 then check(widget("ChargePercent").Text=="99%","bar showed full power before full charge") end
 local before=player.Character.root.impulses
 UIS.InputEnded:Fire(a)
 local velocity=player.Character.root.AssemblyLinearVelocity
 check(player.Character.root.impulses==before+1,"long leap did not use one impulse")
 check(velocity.X>=previousForward-.00001 and velocity.Y>=previousUp-.00001,"top charge strength was not monotonic")
 if power==0.8 then near(velocity.X,108);near(velocity.Y,123) end
 if power==0.9 then near(velocity.X,204);near(velocity.Y,151.5) end
 if power>=1 then near(velocity.X,300);near(velocity.Y,180) end
 previousForward,previousUp=velocity.X,velocity.Y
 land(m)
end
check(m.Config.CrouchAnimation=="rbxassetid://90000000000001" and m.Config.LeapAnimation=="rbxassetid://90000000000002","test clip configuration lost")
logs.MessageOut:Fire("Failed to load animation rbxassetid://90000000000002")
check(m.AssetErrors.Leap and m.AssetErrors.Leap:find("90000000000002",1,true),"new leap asset error was not captured")
check(m.Diagnostics():find("Leap source: rbxassetid://90000000000002",1,true),"report showed old leap ID")
local count=player.Character.root.impulses
button.InputBegan:Fire(a);step(.3);UIS.WindowFocusReleased:Fire();UIS.InputEnded:Fire(a)
check(m.Phase=="ready" and player.Character.root.impulses==count,"focus loss launched instead of cancelling")
button.InputBegan:Fire(a);a.UserInputState=Enum.UserInputState.Cancel;UIS.InputEnded:Fire(a);a.UserInputState=Enum.UserInputState.Begin
check(m.Phase=="ready" and player.Character.root.impulses==count,"cancelled touch launched")
player.Character.root.Anchored=true;button.InputBegan:Fire(a)
check(m.Phase=="ready","anchored body charged")
player.Character.root.Anchored=false;player.Character.hum.FloorMaterial=Enum.Material.Air;button.InputBegan:Fire(a)
check(m.Phase=="ready","midair body charged")
player.Character.hum.FloorMaterial=Enum.Material.Concrete
player.Character.attributes.LOCKED_INPUTS=true;button.InputBegan:Fire(a)
check(m.Phase=="ready","game input lock was bypassed")
player.Character.attributes.LOCKED_INPUTS=false
button.InputBegan:Fire(a);player.Character.attributes.canRun=false;step(.1);UIS.InputEnded:Fire(a)
check(m.Phase=="ready" and player.Character.root.impulses==count,"movement lock during hold still launched")
player.Character.attributes.canRun=true
m.CanUse=function() return false,"Flight active" end;button.InputBegan:Fire(a)
check(m.Phase=="ready","flight conflict was ignored")
m.CanUse=nil
button.InputBegan:Fire(a);step(.2);m.SetEnabled(false);UIS.InputEnded:Fire(a)
check(not m.Enabled and player.Character.root.impulses==count,"disabling while held launched")
m.SetEnabled(true);button.InputBegan:Fire(a);step(.2);player.CharacterRemoving:Fire(player.Character)
local old=player.Character;player.Character=character();UIS.InputEnded:Fire(a)
check(old.root.impulses==count and player.Character.root.impulses==0,"respawn released an old charge")
check(squat.Destroyed,"respawn leaked the old animation")
-- Animation permission errors must not crash charging or the physics request.
animationFailure=true
button.InputBegan:Fire(a);step(.5);UIS.InputEnded:Fire(a)
check(m.Phase=="airborne" and player.Character.root.impulses==1,"animation failure broke the leap")
land(m)
-- New-character death cancels without releasing an impulse.
button.InputBegan:Fire(a);player.Character.hum.Health=0;step(.1);UIS.InputEnded:Fire(a)
check(player.Character.root.impulses==1,"death launched the character")
m.Stop();m.Stop()
check(UIS.InputEnded:Count()==0 and UIS.InputChanged:Count()==0 and UIS.WindowFocusReleased:Count()==0 and run.Heartbeat:Count()==0 and player.CharacterRemoving:Count()==0,"unload leaked an input or frame listener")
check(not m.SetEnabled(true),"stopped feature reopened")
-- A partially built control must not block a later attempt.
player.Character=character();animationFailure=false
local retry=create(Utils,Kit,createPose);failClass="TextButton"
check(not retry.SetEnabled(true) and not retry.Enabled,"failed UI setup left the feature enabled")
failClass=nil;check(retry.SetEnabled(true),"UI failure prevented retry")
retry.Stop()
check(run.Heartbeat:Count()==0 and UIS.InputEnded:Count()==0,"retry cleanup leaked listeners")
-- No clip data: fallback crouch must deepen and then restore exactly.
player.Character=character();animationLength=0
local fallback=create(Utils,Kit,createPose);fallback.SetEnabled(true)
local zero=player.Character.joints[1].Transform
local c0=player.Character.joints[1].C0
local cb=widget("HoldLeap");cb.InputBegan:Fire(touch());step(1.1);step(0)
local shallow=player.Character.joints[1].Transform
check(shallow~=zero and shallow.Y<0,"missing clip data produced no crouch")
step(1.1);step(0)
local deep=player.Character.joints[1].Transform
check(deep.Y<shallow.Y,"fallback crouch did not deepen with charge")
step(.1)
near(player.Character.joints[1].Transform.Y,deep.Y)
check(player.Character.joints[1].C0==c0,"fallback changed the rig bind pose")
check(fallback.Diagnostics():find("No clip data after",1,true),"zero-length failure was hidden")
widget("CopyAnimationReport").Activated:Fire();check(clipboard and clipboard:find("Built-in joints: 8",1,true),"animation report missing joint details")
fallback.SetEnabled(false)
check(player.Character.joints[1].Transform==zero,"disable did not restore pose")
fallback.Stop()
-- Clips that load late can switch from fallback to a verified matching track.
player.Character=character();animationLength=0
local delayed=create(Utils,Kit,createPose);delayed.SetEnabled(true)
local firstIndex=#animationTracks-1
widget("HoldLeap").InputBegan:Fire(touch());step(.5);step(0)
check(player.Character.joints[1].Transform.Y<0,"late-load fallback missing")
animationTracks[firstIndex].Length=2
step(.1)
check(player.Character.joints[1].Transform.Y==0 and delayed.AnimationStatus.Crouch:find("Clip ready",1,true),"ready clip did not replace fallback cleanly")
delayed.Stop()
-- R6 clips on an R15 character must use the fallback even if Length is nonzero.
player.Character=character();animationLength=2;targetNames={"Torso","Left Arm"}
local mismatch=create(Utils,Kit,createPose);mismatch.SetEnabled(true)
widget("HoldLeap").InputBegan:Fire(touch());step(.5);step(0)
check(mismatch.AnimationStatus.Crouch:find("Rig mismatch",1,true),"rig mismatch not detected")
check(player.Character.joints[1].Transform.Y<0,"mismatched rig did not crouch")
mismatch.Stop()
-- Built-in poses also support R6 and preserve changes made by another animation.
player.Character=character(Enum.HumanoidRigType.R6);animationLength=2;targetNames={"Torso","Left Arm"}
local r6=create(Utils,Kit,createPose);r6.SetEnabled(true)
widget("AnimationMode").Activated:Fire()
check(r6.AnimationMode=="Original","pose toggle failed")
widget("HoldLeap").InputBegan:Fire(touch());step(1);step(0)
check(player.Character.joints[1].Transform.Y<0,"R6 fallback did not crouch")
local external=CFrame.new(0,4,0);player.Character.joints[1].Transform=external
r6.SetEnabled(false)
check(player.Character.joints[1].Transform==external,"cleanup overwrote another animation")
r6.Stop()
check(run.PreAnimation:Count()==0 and run.PreSimulation:Count()==0,"pose frame callbacks leaked")
-- Keep zero-length primed tracks alive during their loading window.
player.Character=character();animationLength=0;targetNames={"UpperTorso"}
local warming=create(Utils,Kit,createPose);warming.SetEnabled(true)
local warmCrouch=animationTracks[#animationTracks-1]
step(.1)
check(warmCrouch.IsPlaying and (warmCrouch.StopCalls or 0)==0,"warmup stopped before clip data could load")
logs.MessageOut:Fire("Failed to load animation rbxassetid://90000000000001: asset permission denied")
check(warming.AssetErrors.Crouch and warming.AssetErrors.Crouch:find("permission denied",1,true),"Roblox asset error not captured")
logs.MessageOut:Fire("Rift Hub / Hulk / 1.2\nRoblox crouch error: 90000000000001")
check(warming.AssetErrors.Crouch:find("permission denied",1,true),"copying the report overwrote asset evidence")
widget("HoldLeap").InputBegan:Fire(touch());step(.5)
check(warming.AnimationStatus.Crouch:find("permission denied",1,true),"reported asset failure was hidden")
warming.Stop()
-- Unknown custom targets must remain eligible for real clip playback (preserve upstream fix).
player.Character=character();animationLength=2;targetNames={"CustomHeroChest"}
local custom=create(Utils,Kit,createPose);custom.SetEnabled(true)
local customTouch=touch();widget("HoldLeap").InputBegan:Fire(customTouch);step(.4)
check(custom.AnimationStatus.Crouch:find("Unverified target list",1,true),"custom-rig clip rejected")
check(animationTracks[#animationTracks-1].WeightCurrent==1,"warm clip remained invisible at zero weight")
-- Event errors must remain visible in diagnostics rather than silently leaving a stuck charge.
player.Character.hum.MoveDirection=nil
local releaseOk=pcall(function() UIS.InputEnded:Fire(customTouch) end)
check(releaseOk and custom.LastRuntimeError and custom.Phase=="ready","input error escaped without recovery")
check(custom.Diagnostics():find("Inputs: presses=1",1,true),"diagnostics lost input stage")
custom.Stop()
-- Failed joint writes are observable, not falsely reported as successful poses.
player.Character=character();animationLength=0
local poseFailure=create(Utils,Kit,createPose);poseFailure.SetEnabled(true)
widget("HoldLeap").InputBegan:Fire(touch());step(.5)
player.Character.joints[1].C0=false
step(.1);step(.1)
check(poseFailure.Diagnostics():find("last pose error=Root:",1,true),"pose write failure was swallowed")
poseFailure.Stop()
check(logs.MessageOut:Count()==0,"animation log listener leaked")
-- R15 AnimationConstraint rigs have no Motor6D joints; use attachment bindings and Transform.
player.Character=character();player.Character.joints={};animationLength=0
local lowerTorso={Name="LowerTorso"};local hrp={Name="HumanoidRootPart"}
local function constraint(attachmentName,part0,part1)
 local rest=CFrame.new()
 local node={Name="AnimationConstraint",ClassName="AnimationConstraint",Parent={},Transform=CFrame.new(),C0=false,
  Attachment0={Name=attachmentName,Parent=part0,CFrame=rest},Attachment1={Name=attachmentName,Parent=part1,CFrame=CFrame.new()}}
 function node:IsA(name) return name=="AnimationConstraint" end
 return node
end
local acRoot=constraint("RootRigAttachment",hrp,lowerTorso)
local acHip=constraint("LeftHipRigAttachment",lowerTorso,{Name="LeftUpperLeg"})
local acKnee=constraint("LeftKneeRigAttachment",{Name="LeftUpperLeg"},{Name="LeftLowerLeg"})
player.Character.joints={acRoot,acHip,acKnee}
local constraintBase=acRoot.Transform
local constraintPose=createPose(player.Character)
check(constraintPose.Count==3 and constraintPose.Inventory.Motor6D==0 and constraintPose.Inventory.AnimationConstraint==3,"animation constraints were not discovered")
constraintPose.Set("charging",.5);step(0)
near(acRoot.Transform.Y,-.45)
check(constraintPose.AppliedCount==3 and constraintPose.LastError==nil,"constraint pose failed to apply")
constraintPose.Set("charging",1);step(0)
near(acRoot.Transform.Y,-.9)
check(acRoot.C0==false and acRoot.Attachment0.CFrame.Y==0,"constraint posing changed rest attachments")
constraintPose.Set(nil)
check(acRoot.Transform==constraintBase,"constraint transform did not restore")
constraintPose.Destroy()
-- Exercise the complete controller with this Motor6D-free rig and denied animation data.
local constraintControl=create(Utils,Kit,createPose);constraintControl.SetEnabled(true)
local acTouch=touch();widget("HoldLeap").InputBegan:Fire(acTouch);step(1.1);step(0)
check(acRoot.Transform.Y<0 and constraintControl.Diagnostics():find("AnimationConstraint=3",1,true),"full controller did not use constraint fallback")
UIS.InputEnded:Fire(acTouch)
check(constraintControl.Phase=="airborne" and player.Character.root.impulses==1,"constraint rig did not leap")
constraintControl.Stop()
check(acRoot.Transform==constraintBase,"controller stop did not restore constraints")
-- Binding completion or new rig joints trigger a rescan after warmup.
player.Character.joints={acRoot}
local loadedPartial=create(Utils,Kit,createPose);loadedPartial.SetEnabled(true)
check(loadedPartial.Diagnostics():find("Built-in joints: 1",1,true),"initial partial rig was not observed")
player.Character.joints={acRoot,acHip,acKnee};step(1.1)
check(loadedPartial.Diagnostics():find("Built-in joints: 3",1,true),"newly loaded joints were not rescanned")
loadedPartial.Stop()
local incomplete=constraint("RightHipRigAttachment",lowerTorso,{Name="RightUpperLeg"})
incomplete.Attachment1=nil
player.Character.joints={acRoot,incomplete}
local pending=createPose(player.Character)
check(pending.Count==1 and pending.NeedsRefresh(),"incomplete attachment binding was treated as final")
pending.Destroy()
-- Skinned bodies use Bone.Transform and Bone.CFrame rather than Part0/Part1/C0.
player.Character=character();player.Character.joints={}
local mesh={Name="BodyMesh"}
local function bone(name,parent)
 local node={Name=name,ClassName="Bone",Parent=parent,Transform=CFrame.new(),CFrame=CFrame.new()}
 function node:IsA(kind) return kind=="Bone" or kind=="Attachment" end
 return node
end
local boneRoot=bone("Root",mesh)
local boneHip=bone("LeftHip",boneRoot)
local boneKnee=bone("LeftKnee",boneHip)
player.Character.joints={boneRoot,boneHip,boneKnee}
local boneBase=boneRoot.Transform
local bonePose=createPose(player.Character)
check(bonePose.Count==3 and bonePose.Inventory.Bone==3,"bones not discovered")
bonePose.Set("charging",1);step(0)
near(boneRoot.Transform.Y,-.9)
check(bonePose.AppliedCount==3 and bonePose.LastError==nil,"bone transforms did not apply")
bonePose.Destroy()
check(boneRoot.Transform==boneBase,"bone transforms not restored")
-- Do not apply a second copy of a pose to skin bones when physical limb joints exist.
player.Character.joints={acRoot,acHip,acKnee,boneRoot,boneHip,boneKnee}
local mixed=createPose(player.Character)
check(mixed.Count==3 and mixed.Inventory.Bone==3,"mixed representations were posed twice")
mixed.Destroy()
check(run.PreAnimation:Count()==0 and run.PreSimulation:Count()==0,"new rig representations leaked callbacks")
-- A playing leap clip keeps its body animation, but cannot fold the arms backward.
player.Character=character();animationLength=2;targetNames={"UpperTorso","LeftUpperArm"}
local function motorArm(name,angle)
 local node={Name=name,Parent={},Part0={Name="UpperTorso"},Part1={},C0=CFrame.new(),Transform=CFrame.Angles(angle,0,0)}
 function node:IsA(kind) return kind=="Motor6D" end
 return node
end
local shoulder=motorArm("LeftShoulder",-1.2)
local elbow=motorArm("LeftElbow",-.9)
local wrist=motorArm("LeftWrist",.8)
-- Replace the preexisting left shoulder; do not give the same limb two joints.
for i,joint in ipairs(player.Character.joints) do
 if joint.Name=="LeftShoulder" then player.Character.joints[i]=shoulder end
end
table.insert(player.Character.joints,elbow);table.insert(player.Character.joints,wrist)
local clipArms=create(Utils,Kit,createPose);clipArms.SetEnabled(true)
local armTouch=touch();widget("HoldLeap").InputBegan:Fire(armTouch);step(.7)
near(shoulder.Transform.Angle,-1.2) -- crouch clip still owns the arms
UIS.InputEnded:Fire(armTouch)
local bodyRoot=player.Character.joints[1]
local bodyHip=player.Character.joints[3]
local rootAnimation=CFrame.Angles(.32,0,0);local hipAnimation=CFrame.Angles(.42,0,0)
bodyRoot.Transform=rootAnimation;bodyHip.Transform=hipAnimation
step(0)
near(shoulder.Transform.Angle,math.rad(105));near(elbow.Transform.Angle,math.rad(20));near(wrist.Transform.Angle,0)
check(bodyRoot.Transform==rootAnimation and bodyHip.Transform==hipAnimation,"airborne arm correction replaced the clip body pose")
check(animationTracks[#animationTracks].IsPlaying,"arm correction stopped CS_Leap")
-- Simulate fresh Animator output each frame; corrections do not add to the animated arms.
run.PreAnimation:Fire()
local freshShoulder=CFrame.Angles(-2.4,0,0);local freshElbow=CFrame.Angles(-1.4,0,0)
shoulder.Transform=freshShoulder;elbow.Transform=freshElbow
run.PreSimulation:Fire()
near(shoulder.Transform.Angle,math.rad(105));near(elbow.Transform.Angle,math.rad(20))
step(.1);near(shoulder.Transform.Angle,math.rad(105))
-- If the clip ends in midair, fallback arms retain the same forward pose.
animationTracks[#animationTracks].IsPlaying=false
step(.1);step(0)
near(shoulder.Transform.Angle,math.rad(105));near(elbow.Transform.Angle,math.rad(20))
land(clipArms)
check(shoulder.Transform==freshShoulder and elbow.Transform==freshElbow,"landing left the corrected arms stuck")
clipArms.Stop()
-- Every supported rig representation uses rest-relative arms and restores ownership.
for _,kind in ipairs({"Motor6D","AnimationConstraint","Bone"}) do
 player.Character=character(kind=="Motor6D" and Enum.HumanoidRigType.R6 or nil)
 local parent={Name="UpperTorso"}
 local arm,forearm,hand
 if kind=="Motor6D" then
  arm=motorArm("Left Shoulder",-1.3);forearm=motorArm("LeftElbow",-1);hand=motorArm("LeftWrist",.8)
 elseif kind=="AnimationConstraint" then
  arm=constraint("LeftShoulderRigAttachment",parent,{Name="LeftUpperArm"})
  forearm=constraint("LeftElbowRigAttachment",{Name="LeftUpperArm"},{Name="LeftLowerArm"})
  hand=constraint("LeftWristRigAttachment",{Name="LeftLowerArm"},{Name="LeftHand"})
 else
  arm=bone("LeftShoulder",parent);forearm=bone("LeftElbow",arm);hand=bone("LeftWrist",forearm)
 end
 arm.Transform=CFrame.Angles(-1.3,0,0);forearm.Transform=CFrame.Angles(-1,0,0);hand.Transform=CFrame.Angles(.8,0,0)
 local originalArm,originalForearm,originalHand=arm.Transform,forearm.Transform,hand.Transform
 player.Character.joints={arm,forearm,hand}
 local p=createPose(player.Character)
 p.Set("airborne-arms",1);step(0)
 near(arm.Transform.Angle,math.rad(105));near(forearm.Transform.Angle,math.rad(20));near(hand.Transform.Angle,0)
 step(.1);near(arm.Transform.Angle,math.rad(105))
 p.Set("airborne",1);step(0)
 near(arm.Transform.Angle,math.rad(105));near(forearm.Transform.Angle,math.rad(20))
 p.Set(nil)
 check(arm.Transform==originalArm and forearm.Transform==originalForearm and hand.Transform==originalHand,"arm pose did not restore "..kind)
 p.Set("airborne-arms",1);step(0)
 local externalArm=CFrame.Angles(.6,0,0);arm.Transform=externalArm
 p.Destroy()
 check(arm.Transform==externalArm and forearm.Transform==originalForearm,"arm cleanup overwrote another owner on "..kind)
end
check(run.PreAnimation:Count()==0 and run.PreSimulation:Count()==0,"airborne arm fix leaked callbacks")
-- Full Hulk traversal: camera-directed bound, bounded air steering, smash and recovery.
player.Character=character();animationLength=2;targetNames={"UpperTorso","LeftUpperArm"}
workspace.CurrentCamera.CFrame={LookVector=Vector3.new(1,0,0)}
workspace.Gravity=196.2
local traversal=create(Utils,Kit,createPose,nil,createEffects);traversal.SetEnabled(true)
check(not traversal.Slam(),"smash launched from the ground")
widget("QuickBound").Activated:Fire()
check(traversal.Phase=="airborne" and traversal.Bounds==1,"bound button did not launch")
near(player.Character.root.AssemblyLinearVelocity.X,105);near(player.Character.root.AssemblyLinearVelocity.Y,85)
check(not traversal.Bound(),"bound stacked in midair")
player.Character.hum.FloorMaterial=Enum.Material.Air
player.Character.hum.MoveDirection=Vector3.new(0,0,-1)
local initial=player.Character.root.AssemblyLinearVelocity
step(.1)
local steered=player.Character.root.AssemblyLinearVelocity
check((steered-initial).Magnitude<=85*.05+.00001,"air steering exceeded acceleration cap")
near(steered.Y,initial.Y)
check(steered.Z<0 and traversal.AirSteers==1,"joystick did not steer the leap")
local horizontal=Vector3.new(steered.X,0,steered.Z).Magnitude
check(horizontal<=105,"air steering accumulated speed")
player.Character.hum.MoveDirection=Vector3.zero
local coast=player.Character.root.AssemblyLinearVelocity
step(.1)
check(player.Character.root.AssemblyLinearVelocity==coast,"no-input flight did not preserve momentum")
player.Character.root.AssemblyLinearVelocity=Vector3.new(coast.X,-20,coast.Z);step(.1)
check(animationTracks[#animationTracks].Id=="rbxassetid://90000000000003" and animationTracks[#animationTracks].IsPlaying,"fall animation was not selected")
local beforeSmash=player.Character.root.impulses
widget("DownSlam").Activated:Fire()
check(traversal.Phase=="slamming" and traversal.Slams==1,"smash button did not dive")
near(player.Character.root.AssemblyLinearVelocity.Y,-180)
check(animationTracks[#animationTracks].Id=="rbxassetid://90000000000004","smash clip was not selected")
check(not traversal.Slam() and player.Character.root.impulses==beforeSmash+1,"smash stacked repeatedly")
player.Character.hum.MoveDirection=Vector3.new(-1,0,0)
local diving=player.Character.root.AssemblyLinearVelocity
step(.05)
check(player.Character.root.AssemblyLinearVelocity==diving,"steering overrode the downward smash")
player.Character.hum.FloorMaterial=Enum.Material.Concrete;step(.1)
check(traversal.Phase=="landing" and traversal.Landings==1,"smash did not land once")
check(animationTracks[#animationTracks].Id=="rbxassetid://90000000000005","landing clip was not selected")
check(not traversal.Bound(),"bound interrupted touchdown recovery")
step(.39)
check(traversal.Phase=="ready" and traversal.Landings==1,"touchdown did not recover")
check(player.Character.hum.WalkSpeed==24 and workspace.Gravity==196.2,"traversal changed normal movement or gravity")
check(not traversal.LastRuntimeError and not traversal.LastEffectError,"traversal/effects raised an error")
widget("EffectsToggle").Activated:Fire()
check(not traversal.EffectsEnabled and workspace.CurrentCamera.FieldOfView==70,"effects toggle did not restore FOV")
-- Keyboard is opt-in per unprocessed press and leaves focused text input alone.
local key={UserInputType=Enum.UserInputType.Keyboard,UserInputState=Enum.UserInputState.Begin,KeyCode=Enum.KeyCode.Z}
UIS.InputBegan:Fire(key,true);check(traversal.Phase=="ready","processed key started a charge")
UIS.GetFocusedTextBox=function() return {} end
UIS.InputBegan:Fire(key,false);check(traversal.Phase=="ready","text input started a charge")
UIS.GetFocusedTextBox=function() return nil end
UIS.InputBegan:Fire(key,false);step(.5)
check(traversal.Phase=="charging","keyboard charge did not begin")
UIS.InputEnded:Fire(key);check(traversal.Phase=="airborne","keyboard charge did not release")
player.Character.hum.FloorMaterial=Enum.Material.Air
player.Character.attributes.LOCKED_INPUTS=true;local lockedCount=player.Character.root.impulses;step(.1)
check(traversal.Phase=="ready" and player.Character.root.impulses==lockedCount,"air steering ignored a game movement lock")
traversal.Stop()
check(UIS.InputBegan:Count()==0,"keyboard listener leaked")
workspace.CurrentCamera.CFrame=nil
-- Missing action clips are attempted once per rig, then use fallback without blocking movement.
player.Character=character();animationFailure=true
local denied=create(Utils,Kit,createPose);denied.SetEnabled(true);check(denied.Bound(),"denied leap clip blocked bound")
player.Character.hum.FloorMaterial=Enum.Material.Air
check(denied.Slam(),"denied smash clip blocked movement")
local assetsBefore=#created;step(.1);step(.1)
check(#created==assetsBefore and denied.AnimationStatus.Slam:find("Load failed",1,true),"failed smash clip retried every frame")
denied.SetEnabled(false);check(denied.Phase=="off","disable did not end smash");denied.Stop();animationFailure=false
-- Local impact effects are capped, fade, and restore only values still owned by this script.
player.Character=character();workspace.CurrentCamera.FieldOfView=76
local ground=object("Part",{Color=Color3.fromRGB(95,100,80)})
rayHit={Position=Vector3.zero,Normal=Vector3.new(0,1,0),Material=Enum.Material.Concrete,Instance=ground}
local function liveFX()
 local n=0;for _,o in ipairs(created) do if not o.Destroyed and (o.Name=="RiftHulkShockwave" or o.Name=="RiftHulkDebris") then n+=1 end end
 return n
end
local effects=createEffects(Kit)
for _=1,6 do effects.Pulse(Vector3.zero,1,true,player.Character) end
check(liveFX()<=28,"impact debris grew without a bound")
local cameraOffset=player.Character.hum.CameraOffset
player.Character.root.AssemblyLinearVelocity=Vector3.new(250,40,0)
effects.Update("airborne",player.Character,player.Character.hum,player.Character.root,1,.1)
check(workspace.CurrentCamera.FieldOfView>76 and workspace.CurrentCamera.FieldOfView<=110,"speed FOV did not respond within bounds")

check(player.Character.hum.CameraOffset~=cameraOffset,"impact camera response was missing")

local oldCamera=workspace.CurrentCamera
workspace.CurrentCamera={FieldOfView=82,ViewportSize=oldCamera.ViewportSize}
effects.Update("airborne",player.Character,player.Character.hum,player.Character.root,1,.1)
near(oldCamera.FieldOfView,76)
for _=1,12 do effects.Update("ready",player.Character,player.Character.hum,player.Character.root,0,.1) end
check(liveFX()==0,"impact objects did not expire")
effects.Clear();near(workspace.CurrentCamera.FieldOfView,82)
check(player.Character.hum.CameraOffset==cameraOffset,"camera offset did not restore")
effects.Pulse(Vector3.zero,1,true,player.Character)
effects.Update("airborne",player.Character,player.Character.hum,player.Character.root,1,.1)
workspace.CurrentCamera.FieldOfView=91
local externalOffset=Vector3.new(2,0,0);player.Character.hum.CameraOffset=externalOffset
effects.SetEnabled(false)
check(workspace.CurrentCamera.FieldOfView==91 and player.Character.hum.CameraOffset==externalOffset,"effect cleanup overwrote external camera changes")
check(liveFX()==0,"disabled effects leaked objects")
effects.Destroy();effects.Destroy();rayHit=nil
-- Original authored motion has breathing, asymmetric strides and continuous charge/takeoff.
local breatheA=motion.Sample("idle",0,0,1)
local breatheB=motion.Sample("idle",1.2,0,1)
check(breatheA.waist[1]~=breatheB.waist[1] and breatheA.root[4]~=breatheB.root[4],"original idle did not breathe")
local left=motion.Sample("run",.15,0,-1)
local right=motion.Sample("run",.15,0,1)
near(left.hip[1],-right.hip[1]);near(left.shoulder[3],-right.shoulder[3])
local middle=motion.Sample("charging",0,.55,1)
local full=motion.Sample("charging",0,1,1)
check(full.root[4]<middle.root[4] and full.knee[1]<middle.knee[1],"original charge did not deepen")
local takeoff=motion.Sample("launching",.12,1,1)
check(takeoff.hip[1]<0 and takeoff.shoulder[1]>80,"takeoff did not extend into a leap")
check(motion.Sample("roaring",.6,0,1).shoulder[3]>30,"roar did not spread the arms")
local compress=motion.Sample("landing",.09,1,1)
local recover=motion.Sample("landing",.38,1,1)
check(compress.root[4]<recover.root[4] and compress.knee[1]<recover.knee[1],"landing did not compress and recover")
-- Test the actual published Original configuration, with no test clip overrides.
player.Character=character();workspace.CurrentCamera.CFrame=nil
local original=function(c) return createPose(c,motion) end
local originalControl=createRaw(Utils,Kit,original,nil,createEffects,catalogCtor)
local originalClipCount=#animationTracks
check(originalControl.AnimationMode=="Original" and not originalControl.Config.LeapAnimation,"default still requested a reused animation")
originalControl.SetEnabled(true);step(.1);step(0)
check(player.Character.joints[1].Transform.Y<0 and #animationTracks==originalClipCount,"original stance required an animation asset")
check(originalControl.Roar() and originalControl.Phase=="roaring","Gamma Roar did not start")
step(.35);step(0)
check(player.Character.joints[7].Transform.Angle>0,"roar did not pose shoulders")
player.Character.hum.MoveDirection=Vector3.new(1,0,0);step(.05)
check(originalControl.Phase=="ready","moving did not cancel the roar")
player.Character.hum.MoveDirection=Vector3.zero
local originalTouch=touch();widget("HoldLeap").InputBegan:Fire(originalTouch);step(2.3);step(0)
near(player.Character.joints[1].Transform.Y,-.9)
UIS.InputEnded:Fire(originalTouch)
check(originalControl.Phase=="airborne" and #animationTracks==originalClipCount,"original leap required a reused clip")
player.Character.hum.FloorMaterial=Enum.Material.Air;step(.4);step(0)
near(player.Character.joints[7].Transform.Angle,math.rad(105))
check(originalControl.Slam(),"original meteor did not launch")
step(.2);step(0)
near(player.Character.joints[7].Transform.Angle,math.rad(150))
land(originalControl)
check(not originalControl.LastRuntimeError and not originalControl.LastEffectError,"original movement raised an error")
originalControl.Stop()
check(run.PreAnimation:Count()==0 and run.PreSimulation:Count()==0,"original motion callbacks leaked")
-- Resolve catalog containers asynchronously, never feed their wrapper IDs to LoadAnimation.
local pendingTasks={}
local oldSpawn=task.spawn
task.spawn=function(fn) table.insert(pendingTasks,fn) end
local getObjectsCalls=0
local returnedObjects={}
function game:GetObjects(url)
 getObjectsCalls+=1
 if url:find("90553825422454",1,true) then error("catalog access denied") end
 local animation=object("Animation",{AnimationId="rbxassetid://90000000000022"})
 if url:find("133167141310794",1,true) then animation.AnimationId="rbxassetid://133167141310794" end
 local container=object("Model",{},nil)
 function container:FindFirstChildWhichIsA(kind) return kind=="Animation" and animation or nil end
 table.insert(container.children,animation);table.insert(returnedObjects,container)
 return {container}
end
local cat=catalogCtor()
check(cat.Items.Leap==102511523957119 and cat.Items.Fall==108019215607685,"researched Hulk catalog IDs lost")
local pendingId=cat.Get("Leap")
check(not pendingId and cat.IsPending("Leap") and getObjectsCalls==0,"catalog lookup blocked the caller")
cat.Get("Leap");check(#pendingTasks==1,"catalog request duplicated while pending")
table.remove(pendingTasks,1)()
local actualId=cat.Get("Leap")
check(actualId=="rbxassetid://90000000000022" and not cat.IsPending("Leap"),"catalog did not resolve the contained animation")
check(returnedObjects[1].Destroyed and returnedObjects[1].children[1].Destroyed,"catalog resolution leaked imported contents")
cat.Get("Idle");table.remove(pendingTasks,1)()
local deniedId,deniedStatus=cat.Get("Idle")
check(not deniedId and deniedStatus:find("unavailable",1,true),"denied catalog did not fall back")
local oldCalls=getObjectsCalls;cat.Get("Idle");check(getObjectsCalls==oldCalls and #pendingTasks==0,"denied catalog retried repeatedly")
cat.Get("Run");table.remove(pendingTasks,1)()
check(not cat.Get("Run"),"catalog wrapper was mistaken for a raw animation")
cat.Get("Walk");cat.Stop();table.remove(pendingTasks,1)()
check(not cat.Get("Walk"),"a lookup completed after unload")
task.spawn=oldSpawn
-- Optional Catalog mode can use a resolved clip, and return to Original cleanly.
player.Character=character();animationLength=2;targetNames={"UpperTorso"}
local hybrid=createRaw(Utils,Kit,original,nil,nil,catalogCtor);hybrid.SetEnabled(true)
widget("AnimationMode").Activated:Fire();step(.05)
check(hybrid.AnimationMode=="Auto","catalog toggle failed")
check(hybrid.Bound(),"catalog leap could not launch")
check(animationTracks[#animationTracks].Id=="rbxassetid://90000000000022","catalog container ID reached LoadAnimation")
widget("AnimationMode").Activated:Fire()
check(hybrid.AnimationMode=="Original" and next(hybrid.ResolvedIds)==nil,"Original mode retained catalog state")
hybrid.Stop()
game.GetObjects=nil
-- Execute the generated standalone, including its own minimal UI kit and logo fallback.
local standaloneEnv={}
local getgenv=function() return standaloneEnv end
local Font={fromName=function() return "font" end,fromEnum=function() return "font" end}
Color3.new=function(...) return {...} end
local standalone=(function()
-- STANDALONE
end)()
check(standalone.Game=="Hulk" and standalone.Enabled and standalone.Gui and standalone.Gui.Parent,"standalone did not publish a usable window")
check(standaloneEnv.RiftHulkCharacter==standalone,"standalone API not published")
standalone.Unload()
check(standaloneEnv.RiftHulkCharacter==nil and not standalone.Gui,"standalone unload left a global or window")
check(UIS.InputEnded:Count()==0 and run.Heartbeat:Count()==0,"standalone leaked its controls")
print("PASS: "..checks.." Hulk leap checks for charge scaling, animation IDs, release, touch ownership, physics request, cancellation, locks, landing, respawn, failures and cleanup.")
