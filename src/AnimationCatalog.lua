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
