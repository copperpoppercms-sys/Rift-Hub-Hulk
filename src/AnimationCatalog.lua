-- Catalog item metadata checked against Roblox's bundle API on 2026-10-19.
-- These are avatar catalog containers, NOT raw Animation asset IDs.
local items={Idle=90553825422454,Walk=137699728035178,Run=133167141310794,
	Leap=102511523957119,Fall=108019215607685}
return function()
	local cache,status,pending={}, {}, {}
	local stopped=false
	local M={Items=items,Name="Hulk Smash! Animation Pack",Creator="Gentle Blox",
		Source="https://www.roblox.com/bundles/263899055278099/Hulk-Smash-Animation-Pack"}
	function M.Get(label)
		if stopped or not items[label] then return nil,"Original Rift Gamma keyframes" end
		if cache[label] then return cache[label],status[label] end
		if status[label] and not pending[label] then return nil,status[label] end
		if not pending[label] then
			pending[label]=true;status[label]="Resolving catalog item; original motion active"
			task.spawn(function()
				-- Inspect only an Animation object returned by Roblox. Never parent/import
				-- scripts, require modules, or execute model contents.
				local ok,objects=pcall(function() return game:GetObjects("rbxassetid://"..items[label]) end)
				local resolved
				if ok and type(objects)=="table" then
					for _,object in ipairs(objects) do
						pcall(function()
							local animation=object:IsA("Animation") and object or object:FindFirstChildWhichIsA("Animation",true)
							if animation then
								local id=animation.AnimationId:match("%d+")
								if id and tonumber(id)~=items[label] and tonumber(id)>0 then resolved="rbxassetid://"..id end
							end
						end)
						pcall(function() object:Destroy() end)
					end
				end
				if stopped then return end
				pending[label]=nil
				cache[label]=resolved
				status[label]=resolved and "Playable Animation reference resolved; playback unverified" or "Catalog unavailable or no playable Animation; original motion active"
			end)
		end
		return cache[label],status[label]
	end
	function M.IsPending(label) return pending[label]==true end
	function M.Stop() stopped=true;table.clear(cache);table.clear(status);table.clear(pending) end
	return M
end
