-- Native AnimationTrack playback only. No Motor6D/Bone/constraint Transform writes.
return function(player, Utils, bank)
	local tracks, assets, errors, connections = {}, {}, {}, {}
	local character, humanoid, animator, current, stopped
	local M={Enabled=true,Status="Waiting for character Animator",Stage="None"}
	local function destroySlot(slot)
		if slot.Track then pcall(function() slot.Track:Stop(.12);slot.Track:Destroy() end) end
		if slot.Asset then slot.Asset:Destroy() end
	end
	function M.StopAll()
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
	function M.Update(phase,power)
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
			local ok,err=pcall(function() track:Play(.12,1,1);track:AdjustWeight(1,.12) end)
			if not ok then errors[label]=tostring(err);bank.Fail(slot.Id,tostring(err));M.Status="Playback failed: "..label;return M.Status end
		end
		if track.Length<=0 then M.Status="Loading native "..label.."; no local pose substitute";return M.Status end
		if not track.IsPlaying and not track.Looped then M.Status=label.." native clip finished";return M.Status end
		if not track.IsPlaying then pcall(function() track:Play(.12,1,1);track:AdjustWeight(1,.12) end) end
		if phase=="charging" then pcall(function() track:AdjustSpeed(.4+.4*math.clamp(power or 0,0,1)) end) end
		M.Status=label.." native track · "..tostring(slot.Source)
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
