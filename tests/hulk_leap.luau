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
function CFrame.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,Angle=0},cf) end
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
	local hum={RigType=rig or Enum.HumanoidRigType.R15,Health=100,FloorMaterial=Enum.Material.Concrete,PlatformStand=false,Sit=false,WalkSpeed=24,MoveDirection=Vector3.zero}
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
local UIS={InputEnded=signal(),InputChanged=signal(),WindowFocusReleased=signal()}
local run={Heartbeat=signal(),PreAnimation=signal(),PreSimulation=signal()}
local logs={MessageOut=signal()}
local workspace={CurrentCamera={ViewportSize=Vector3.new(390,844,0)}}
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
local create=(function()
-- HULK LEAP
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
check(squat.Id=="rbxassetid://99086193071059" and squat.IsPlaying,"wrong squat animation")
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
check(not squat.IsPlaying and animationTracks[2].Id=="rbxassetid://74095507765093","launch animation missing")
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
check(m.AnimationIds.Idle=="rbxassetid://180435571" and m.AnimationIds.CS_Leap==m.Config.LeapAnimation
 and m.AnimationIds.Walk=="rbxassetid://180426354" and m.AnimationIds.Fall=="rbxassetid://180436148"
 and m.AnimationIds.CS_Downslam=="rbxassetid://113926956994381" and m.AnimationIds.KS_ChaseSlam=="rbxassetid://107995270438202","supplied animation references lost")
logs.MessageOut:Fire("Failed to load animation rbxassetid://74095507765093")
check(m.AssetErrors.Leap and m.AssetErrors.Leap:find("74095507765093",1,true),"new leap asset error was not captured")
check(m.Diagnostics():find("Leap rbxassetid://74095507765093:",1,true),"report showed old leap ID")
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
check(r6.AnimationMode=="Built-in","pose toggle failed")
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
logs.MessageOut:Fire("Failed to load animation rbxassetid://99086193071059: asset permission denied")
check(warming.AssetErrors.Crouch and warming.AssetErrors.Crouch:find("permission denied",1,true),"Roblox asset error not captured")
logs.MessageOut:Fire("Rift Hub / Hulk / 1.2\nRoblox crouch error: 99086193071059")
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
-- Execute the generated standalone, including its own minimal UI kit and logo fallback.
local standaloneEnv={}
local getgenv=function() return standaloneEnv end
local task={spawn=function(fn) fn() end}
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
