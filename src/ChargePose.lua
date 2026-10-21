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
