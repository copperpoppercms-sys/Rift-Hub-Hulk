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
	hum.AnimatorAvailable=true
	function hum:FindFirstChildOfClass(class) if class=="Animator" and self.AnimatorAvailable then return animator end end
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
	function char:FindFirstChild(name) if name=="HumanoidRootPart" then return root elseif name=="Animate" then return self.Animate end end
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

local task={spawn=function(fn) fn() end}
local bankCtor=(function()
-- CATALOG
end)()
local nativeCtor=(function()
-- NATIVE
end)()
local effectsCtor=(function()
-- EFFECTS
end)()
local create=(function()
-- HULK LEAP
end)()
local function animFactory(p,u) return nativeCtor(p,u,bankCtor()) end
local function make() return create(Utils,Kit,nil,effectsCtor,animFactory) end
local function step(dt) clock+=dt;run.Heartbeat:Fire(dt) end
local function widget(name)
 for i=#created,1,-1 do if created[i].Name==name and not created[i].Destroyed then return created[i] end end
 error("missing widget "..name)
end
local function touch() return {UserInputType=Enum.UserInputType.Touch,UserInputState=Enum.UserInputState.Begin,Position=Vector3.new(200,200,0)} end
local function land(m)
 player.Character.hum.FloorMaterial=Enum.Material.Air;step(.2)
 player.Character.hum.FloorMaterial=Enum.Material.Concrete;step(.3)
 check(m.Phase=="landing","landing state did not begin")
 step(.4);check(m.Phase=="ready","landing did not recover")
end
local function unchangedJoints(char,originals)
 for i,j in ipairs(char.joints) do check(j.Transform==originals[i],"native mode wrote a local joint pose") end
end
local function activeId(id)
 for _,t in ipairs(animationTracks) do if not t.Destroyed and t.Id==id and t.IsPlaying and t.WeightCurrent==1 then return t end end
end
local function listenerCleanup()
 check(UIS.InputBegan:Count()==0 and UIS.InputEnded:Count()==0 and run.Heartbeat:Count()==0 and logs.MessageOut:Count()==0,"unload leaked listeners")
end
-- Native clips use an existing Animator; physics and touch ownership remain intact.
local originals={};for i,j in ipairs(player.Character.joints) do originals[i]=j.Transform end
local m=make();m.SetEnabled(true);step(.1)
check(m.AnimationMode=="Native" and activeId("rbxassetid://1083195517"),"native idle did not play on default startup")
check(run.PreAnimation:Count()==0 and run.PreSimulation:Count()==0,"local pose callbacks were installed")
local a,b=touch(),touch()
widget("HoldLeap").InputBegan:Fire(a);step(1.1)
near(m.Power,.5)
local charge=activeId("rbxassetid://1083195517")
check(charge and charge.Looped,"charge native track missing")
charge.TimePosition=.73;step(.1);near(charge.TimePosition,.73)
UIS.InputEnded:Fire(b);check(m.Phase=="charging" and player.Character.root.impulses==0,"joystick finger released the charge")
step(2);near(m.Power,1)
UIS.InputEnded:Fire(a)
check(m.Phase=="airborne" and player.Character.root.impulses==1,"charged leap did not apply one physics impulse")
near(player.Character.root.AssemblyLinearVelocity.Y,180);near(player.Character.root.AssemblyLinearVelocity.Z,-300)
check(activeId("rbxassetid://1083218792"),"native jump clip missing")
UIS.InputEnded:Fire(a);widget("HoldLeap").InputBegan:Fire(b)
check(player.Character.root.impulses==1,"repeat input stacked a launch")
player.Character.hum.FloorMaterial=Enum.Material.Air;player.Character.hum.MoveDirection=Vector3.new(1,0,0)
local before=player.Character.root.AssemblyLinearVelocity;step(.1)
local after=player.Character.root.AssemblyLinearVelocity
near(after.Y,before.Y);check((after-before).Magnitude<=85*.05+.00001 and after.X>0,"air steering exceeded its cap or did not turn")
player.Character.hum.MoveDirection=Vector3.zero
player.Character.root.AssemblyLinearVelocity=Vector3.new(after.X,-20,after.Z);step(.1)
check(activeId("rbxassetid://1083189019"),"native fall clip missing")
check(m.Slam() and m.Phase=="slamming","meteor did not apply downward movement")
near(player.Character.root.AssemblyLinearVelocity.Y,-180)
check(activeId("rbxassetid://1099492820"),"native slam/emote clip missing")
local count=player.Character.root.impulses;check(not m.Slam() and player.Character.root.impulses==count,"repeated meteor stacked")
land(m);unchangedJoints(player.Character,originals)
check(m.Roar() and activeId("rbxassetid://1099492820"),"native emote did not play")
player.Character.hum.MoveDirection=Vector3.new(1,0,0);step(.05)
check(m.Phase=="ready","moving did not cancel the emote")
widget("AnimationMode").Activated:Fire();check(m.AnimationMode=="Off","native toggle failed")
check(not activeId("rbxassetid://1099492820"),"animation toggle left an owned clip playing")
check(m.Bound(),"bound failed with animations disabled")
near(player.Character.root.AssemblyLinearVelocity.X,105);near(player.Character.root.AssemblyLinearVelocity.Y,85)
land(m)
check(m.Diagnostics():find("Observer replication: unverified",1,true),"report claimed observer replication")
check(player.Character.hum.WalkSpeed==24 and not player.Character.root.Anchored,"normal movement controls were changed")
check(not m.LastRuntimeError and not m.LastEffectError and not m.LastAnimationError,"native default path raised an error")
m.Stop();m.Stop();listenerCleanup()
-- No Animator: no client-side substitute is created, and movement still works.
player.Character=character();player.Character.hum.AnimatorAvailable=false
local beforeObjects=#created
local waiting=make();waiting.SetEnabled(true);step(.1)
check(waiting.Diagnostics():find("Waiting for existing character Animator",1,true),"missing Animator was hidden")
for i=beforeObjects+1,#created do check(created[i].ClassName~="Animator","a client-only Animator was created") end
check(waiting.Bound(),"missing Animator prevented character physics")
player.Character.hum.AnimatorAvailable=true;player.Character.hum.FloorMaterial=Enum.Material.Air;step(.1)
check(activeId("rbxassetid://1083218792"),"existing Animator was not picked up when it appeared")
waiting.Stop();listenerCleanup()
-- Failed or empty native clips must not be replaced by local joint poses.
player.Character=character();animationFailure=true
local denied=make();denied.SetEnabled(true)
check(denied.Bound(),"denied animation blocked movement")
check(denied.Diagnostics():find("unavailable",1,true) or denied.Diagnostics():find("denied",1,true),"native denial was not reported")
check(run.PreAnimation:Count()==0 and run.PreSimulation:Count()==0,"denied native animation installed a fake pose")
denied.Stop();animationFailure=false;listenerCleanup()
player.Character=character();animationLength=0
local empty=make();empty.SetEnabled(true)
step(3.2);step(.1);step(3.2)
local loadedCount=#animationTracks
step(10);step(10)
check(#animationTracks==loadedCount,"unavailable clips retried without a bound")
check(empty.Diagnostics():find("No clip data after 3 seconds",1,true),"empty animation load was hidden")
empty.Stop();animationLength=2;listenerCleanup()
-- Catalog references resolve asynchronously; a raw catalog container never reaches LoadAnimation.
local pending={};local originalSpawn=task.spawn;task.spawn=function(fn) table.insert(pending,fn) end
local imports,requests={},0
function game:GetObjects(url)
 requests+=1
 local animation=object("Animation",{AnimationId="rbxassetid://90000000000022"})
 local model=object("Model")
 function model:FindFirstChildWhichIsA(kind) return kind=="Animation" and animation or nil end
 table.insert(model.children,animation);table.insert(imports,model)
 return {model}
end
local bank=bankCtor()
local fallbackId=bank.Get("Leap",Enum.HumanoidRigType.R15,player.Character)
check(fallbackId=="rbxassetid://1083218792" and requests==0 and #pending==1,"catalog resolution blocked native fallback")
bank.Get("Leap",Enum.HumanoidRigType.R15,player.Character);check(#pending==1,"pending resolution duplicated")
table.remove(pending,1)()
local primary=bank.Get("Leap",Enum.HumanoidRigType.R15,player.Character)
check(primary=="rbxassetid://90000000000022" and imports[1].Destroyed and imports[1].children[1].Destroyed,"catalog contents did not resolve/clean up")
bank.Fail(primary,"permission denied")
check(bank.Get("Leap",Enum.HumanoidRigType.R15,player.Character)==fallbackId,"denied Hulk clip did not select native fallback")
bank.Stop();task.spawn=originalSpawn
-- Live load-error messages trigger fallback while default game tracks remain untouched.
player.Character=character();local n=nativeCtor(player,Utils,bankCtor())
n.Update("airborne",1)
check(activeId("rbxassetid://90000000000022"),"resolved Hulk native clip was not played")
logs.MessageOut:Fire("Failed to load animation rbxassetid://90000000000022: permission denied")
n.Update("airborne",1)
check(activeId("rbxassetid://1083218792"),"live denial did not switch to documented native fallback")
n.Destroy();listenerCleanup();game.GetObjects=nil
-- R6 uses the game's own compatible clips rather than an R15 asset.
player.Character=character(Enum.HumanoidRigType.R6)
player.Character.Animate={FindFirstChild=function(_,slot)
 return {FindFirstChildWhichIsA=function() return {AnimationId="rbxassetid://90000000000006"} end}
end}
local r6=nativeCtor(player,Utils,bankCtor());r6.Update("airborne",1)
check(activeId("rbxassetid://90000000000006"),"R6 game animation was not selected")
r6.Destroy();listenerCleanup()
-- Focus loss, locks, respawn and death cancel movement; keyboard respects text entry.
player.Character=character();local safe=make();safe.SetEnabled(true)
local k={UserInputType=Enum.UserInputType.Keyboard,UserInputState=Enum.UserInputState.Begin,KeyCode=Enum.KeyCode.Z}
UIS.InputBegan:Fire(k,true);check(safe.Phase=="ready","processed key charged")
UIS.GetFocusedTextBox=function() return {} end
UIS.InputBegan:Fire(k,false);check(safe.Phase=="ready","focused text input charged")
UIS.GetFocusedTextBox=function() return nil end
UIS.InputBegan:Fire(k,false);step(.3);UIS.WindowFocusReleased:Fire();UIS.InputEnded:Fire(k)
check(safe.Phase=="ready" and player.Character.root.impulses==0,"focus loss launched")
player.Character.attributes.LOCKED_INPUTS=true
check(not safe.Bound(),"native physics bypassed a game input lock")
player.Character.attributes.LOCKED_INPUTS=false;check(safe.Bound(),"bound failed after lock ended")
player.Character.hum.FloorMaterial=Enum.Material.Air;player.Character.hum.Health=0;step(.1)
check(safe.Phase=="ready","death did not end movement")
player.CharacterRemoving:Fire();player.Character=character();step(.1)
check(safe.Phase=="ready","respawn did not reset movement")
safe.Stop();listenerCleanup()
-- Execute the actual standalone bundle and exercise a native leap and unload.
local standaloneEnv={}
local getgenv=function() return standaloneEnv end
local Font={fromName=function() return "font" end,fromEnum=function() return "font" end}
Color3.new=function(...) return {...} end
local standalone=(function()
-- STANDALONE
end)()
check(standalone.Game=="Hulk" and standalone.Version=="4.0" and standalone.Gui.Parent,"standalone native entry failed")
check(standalone.Bound(),"standalone did not apply real character movement")
check(activeId("rbxassetid://1083218792"),"standalone native jump missing")
standalone.Unload()
check(not standaloneEnv.RiftHulkCharacter and not standalone.Gui,"standalone unload left a global/window")
listenerCleanup()
print("PASS: "..checks.." native animation, character physics, fallback, touch ownership, cleanup and standalone checks.")
