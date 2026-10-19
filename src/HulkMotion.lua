-- Original Rift Gamma keyframes, authored here rather than copied from a game clip.
-- Angles are parent-body axes in degrees; root Y is a visual joint offset only.
local function pose(values) return values end
local clips = {
	idle={Loop=2.4,Frames={
		{0,pose({root={-4,0,0,-.04},waist={-8,0,0},neck={8,0,0},hip={3,0,4},knee={-6,0,0},shoulder={7,0,18},elbow={28,0,0},wrist={-5,0,0}})},
		{1.2,pose({root={-3,0,0,0},waist={-5,0,0},neck={6,0,0},hip={2,0,4},knee={-4,0,0},shoulder={10,0,20},elbow={32,0,0},wrist={-5,0,0}})},
		{2.4,pose({root={-4,0,0,-.04},waist={-8,0,0},neck={8,0,0},hip={3,0,4},knee={-6,0,0},shoulder={7,0,18},elbow={28,0,0},wrist={-5,0,0}})},
	}},
	charging={Frames={
		{0,pose({root={-4,0,0,0},waist={-8,0,0},neck={8,0,0},hip={5,0,5},knee={-10,0,0},ankle={5,0,0},shoulder={8,0,18},elbow={30,0,0}})},
		{.55,pose({root={-9,0,0,-.44},waist={-20,0,0},neck={18,0,0},hip={30,0,8},knee={-60,0,0},ankle={30,0,0},shoulder={-12,0,23},elbow={65,0,0}})},
		{1,pose({root={-12,0,0,-.9},waist={-28,0,0},neck={24,0,0},hip={52,0,10},knee={-100,0,0},ankle={48,0,0},shoulder={-20,0,25},elbow={80,0,0},wrist={-8,0,0}})},
	}},
	launching={Frames={
		{0,pose({root={-12,0,0,-.18},waist={-22,0,0},neck={20,0,0},hip={28,0,8},knee={-55,0,0},ankle={25,0,0},shoulder={35,0,18},elbow={65,0,0}})},
		{.12,pose({root={-14,0,0,0},waist={-10,0,0},neck={13,0,0},hip={-8,0,5},knee={-10,0,0},ankle={16,0,0},shoulder={100,0,15},elbow={25,0,0}})},
		{.32,pose({root={-12,0,0,0},waist={-8,0,0},neck={15,0,0},hip={25,0,7},knee={-50,0,0},ankle={25,0,0},shoulder={105,0,14},elbow={20,0,0},wrist={0,0,0}})},
	}},
	airborne={Frames={{0,pose({root={-12,0,0,0},waist={-8,0,0},neck={15,0,0},hip={25,0,7},knee={-50,0,0},ankle={25,0,0},shoulder={105,0,14},elbow={20,0,0},wrist={0,0,0}})}}},
	falling={Frames={{0,pose({root={-6,0,0,0},waist={-14,0,0},neck={20,0,0},hip={42,0,10},knee={-72,0,0},ankle={30,0,0},shoulder={62,0,28},elbow={42,0,0},wrist={0,0,0}})}}},
	slamming={Frames={
		{0,pose({root={-8,0,0,0},waist={-8,0,0},neck={15,0,0},hip={25,0,10},knee={-45,0,0},shoulder={105,0,14},elbow={30,0,0}})},
		{.16,pose({root={-22,0,0,0},waist={-25,0,0},neck={22,0,0},hip={10,0,7},knee={-20,0,0},ankle={15,0,0},shoulder={150,0,7},elbow={28,0,0}})},
	}},
	landing={Frames={
		{0,pose({root={-16,0,0,-.65},waist={-32,0,0},neck={28,0,0},hip={50,0,10},knee={-95,0,0},ankle={45,0,0},shoulder={42,0,10},elbow={20,0,0}})},
		{.09,pose({root={-18,0,0,-.9},waist={-38,0,0},neck={32,0,0},hip={60,0,12},knee={-110,0,0},ankle={50,0,0},shoulder={45,0,12},elbow={16,0,0}})},
		{.38,pose({root={-4,0,0,-.04},waist={-8,0,0},neck={8,0,0},hip={3,0,4},knee={-6,0,0},shoulder={7,0,18},elbow={28,0,0}})},
	}},
	roaring={Frames={
		{0,pose({root={-4,0,0,-.04},waist={-8,0,0},neck={8,0,0},hip={4,0,8},knee={-8,0,0},shoulder={8,0,20},elbow={30,0,0}})},
		{.3,pose({root={-7,0,0,-.15},waist={-18,0,0},neck={18,0,0},hip={8,0,10},knee={-18,0,0},shoulder={55,0,22},elbow={75,0,0}})},
		{.6,pose({root={3,0,0,0},waist={8,0,0},neck={-12,0,0},hip={3,0,10},knee={-6,0,0},shoulder={-8,0,40},elbow={50,0,0}})},
		{1.05,pose({root={0,0,0,0},waist={4,0,0},neck={-8,0,0},hip={4,0,8},knee={-8,0,0},shoulder={-4,0,32},elbow={40,0,0}})},
		{1.35,pose({root={-4,0,0,-.04},waist={-8,0,0},neck={8,0,0},hip={4,0,8},knee={-8,0,0},shoulder={8,0,20},elbow={30,0,0}})},
	}},
}
local M = {Name="Rift Gamma / original Hulk motion",Version=1}
function M.Sample(phase, elapsed, power, side, speed)
	phase=phase:gsub("%-arms$","")
	side=side or 1
	if phase=="walk" or phase=="run" then
		local running=phase=="run"
		local rate=running and 8 or 5.5
		local wave=math.sin(elapsed*rate+(side<0 and math.pi or 0))
		local stride=(running and 38 or 22)*wave
		return {root={running and -13 or -6,0,0,-math.abs(math.sin(elapsed*rate))* .065},
			waist={running and -17 or -9,0,0},neck={running and 17 or 10,0,0},
			hip={stride,0,7},knee={-8-math.max(0,-wave)*(running and 65 or 38),0,0},ankle={-stride*.3,0,0},
			shoulder={10-stride*.65,0,side*20},elbow={running and 50 or 30,0,0},wrist={-5,0,0}}
	end
	local clip=clips[phase] or clips.airborne
	local time=phase=="charging" and math.clamp(power or 0,0,1) or math.max(0,elapsed or 0)
	if clip.Loop then time%=clip.Loop end
	local frames=clip.Frames
	local a,b=frames[1],frames[#frames]
	for i=1,#frames-1 do if time<=frames[i+1][1] then a,b=frames[i],frames[i+1];break end end
	local alpha=a==b and 0 or math.clamp((time-a[1])/math.max(.001,b[1]-a[1]),0,1)
	alpha=alpha*alpha*(3-2*alpha)
	local result={}
	for _,role in ipairs({"root","waist","neck","hip","knee","ankle","shoulder","elbow","wrist"}) do
		local from,to=a[2][role] or {0,0,0,0},b[2][role] or {0,0,0,0}
		local value={}
		for axis=1,4 do value[axis]=(from[axis] or 0)+((to[axis] or 0)-(from[axis] or 0))*alpha end
		if role=="shoulder" or role=="hip" then value[3]*=side end
		result[role]=value
	end
	return result
end
return M
