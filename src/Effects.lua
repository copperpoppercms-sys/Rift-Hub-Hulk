-- Bounded local movement effects. No camera type/subject or world gravity changes.
return function(Kit)
	local M = { Enabled=true, LastError=nil }
	local pieces = {}
	local cameraOwner, cameraBase, cameraApplied
	local offsetHum, offsetBase, offsetApplied
	local pulse, shake, stopped = 0, 0, false
	local function restoreCamera()
		if cameraOwner and cameraApplied and cameraOwner.FieldOfView==cameraApplied then cameraOwner.FieldOfView=cameraBase end
		cameraOwner,cameraBase,cameraApplied=nil,nil,nil
	end
	local function restoreOffset()
		if offsetHum and offsetApplied and offsetHum.CameraOffset==offsetApplied then offsetHum.CameraOffset=offsetBase end
		offsetHum,offsetBase,offsetApplied=nil,nil,nil
	end
	function M.Clear()
		restoreCamera();restoreOffset()
		for _,p in ipairs(pieces) do p.Part:Destroy() end
		table.clear(pieces)
		pulse,shake=0,0
	end
	function M.SetEnabled(on)
		M.Enabled=on==true
		if not M.Enabled then M.Clear() end
	end
	function M.Pulse(position, strength, impact, character)
		if stopped or not M.Enabled then return end
		strength=math.clamp(strength or .5,0,1)
		pulse=math.max(pulse,impact and 5 or 3)
		shake=math.max(shake,impact and (.08+.1*strength) or .045)
		local origin=position
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances=character and {character} or {}
		params.IgnoreWater=true
		local hit=workspace:Raycast(position+Vector3.new(0,2,0),Vector3.new(0,-14,0),params)
		if not hit or hit.Normal.Y<.5 then return end
		origin=hit.Position+Vector3.new(0,.12,0)
		-- At most two small effect bursts live at once, regardless of button spam.
		while #pieces>18 do local p=table.remove(pieces,1);p.Part:Destroy() end
		for i=1,2 do
			local p=Kit.create("Part",{Name="RiftHulkShockwave",Shape=Enum.PartType.Cylinder,Anchored=true,
				CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Material=Enum.Material.Neon,
				Color=Color3.fromRGB(93,175,87),Transparency=.7,Size=Vector3.new(.08,2,2),
				CFrame=CFrame.new(origin)*CFrame.Angles(0,0,math.pi/2)},workspace)
			table.insert(pieces,{Part=p,Age=0,Life=.45+i*.12,Origin=origin,Radius=(impact and 20 or 10)*(0.5+strength),Ring=true})
		end
		if impact then
			for i=1,8 do
				local angle=i*math.pi/4
				local direction=Vector3.new(math.cos(angle),0,math.sin(angle))
				local p=Kit.create("Part",{Name="RiftHulkDebris",Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,
					CastShadow=false,Material=hit.Material,Color=hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.Color or Color3.fromRGB(100,104,87),
					Size=Vector3.new(.8, .5, 1)*(0.8+strength),Position=origin,Transparency=.1},workspace)
				table.insert(pieces,{Part=p,Age=0,Life=.65,Origin=origin,Direction=direction,Radius=5+9*strength})
			end
		end
	end
	function M.Update(phase, char, hum, root, power, dt)
		if stopped or not M.Enabled then return end
		dt=math.clamp(dt or 1/60,0,.1)
		for i=#pieces,1,-1 do
			local p=pieces[i];p.Age+=dt
			if p.Age>=p.Life then p.Part:Destroy();table.remove(pieces,i)
			else
				local t=p.Age/p.Life
				p.Part.Transparency=.65+.35*t
				if p.Ring then local diameter=2+p.Radius*t;p.Part.Size=Vector3.new(.08,diameter,diameter)
				else p.Part.CFrame=CFrame.new(p.Origin+p.Direction*(p.Radius*t)+Vector3.new(0,math.sin(t*math.pi)*(1+power*3),0))*CFrame.Angles(t*2,t*3,t) end
			end
		end
		pulse=math.max(0,pulse-dt*12);shake=math.max(0,shake-dt*.45)
		local airborne=phase=="airborne" or phase=="slamming"
		local speed=root and root.AssemblyLinearVelocity.Magnitude or 0
		local amount=(phase=="charging" and power*7 or airborne and math.clamp(speed/300,0,1)*12 or 0)+pulse
		local camera=workspace.CurrentCamera
		if camera~=cameraOwner then restoreCamera();cameraOwner=camera;if camera then cameraBase=camera.FieldOfView end end
		if camera and type(cameraBase)=="number" then
			if cameraApplied and camera.FieldOfView~=cameraApplied then cameraBase=camera.FieldOfView end
			local target=math.clamp(cameraBase+amount,30,110)
			cameraApplied=camera.FieldOfView+(target-camera.FieldOfView)*(1-math.exp(-dt*9))
			camera.FieldOfView=cameraApplied
			if amount==0 and math.abs(cameraApplied-cameraBase)<.01 then restoreCamera() end
		end
		restoreOffset()
		if hum and shake>0 and typeof(hum.CameraOffset)=="Vector3" then
			offsetHum,offsetBase=hum,hum.CameraOffset
			offsetApplied=offsetBase+Vector3.new(math.sin(os.clock()*57)*shake,math.cos(os.clock()*43)*shake*.6,0)
			hum.CameraOffset=offsetApplied
		end
	end
	function M.Destroy() if stopped then return end;M.Clear();stopped=true end
	return M
end
