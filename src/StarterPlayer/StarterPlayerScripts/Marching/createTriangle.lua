local TriStorage = require(script.Parent.TriStorage)
local getTri = TriStorage.get
local thickness = 0

local function cfFromAxes(p, x, y, z)
	return CFrame.new(
		p.x, p.y, p.z,
		x.x, y.x, z.x,
		x.y, y.y, z.y,
		x.z, y.z, z.z
	)
end

return function(a, b, c)
	local ab, ac, bc = b - a, c - a, c - b
	local abl, acl, bcl = ab.magnitude, ac.magnitude, bc.magnitude
	
	if abl > bcl and abl > acl then
		c, a = a, c
	elseif acl > bcl and acl > abl then
		a, b = b, a
	end
	
	ab, ac, bc = b - a, c - a, c - b
	
	local t1 = getTri()
	local t2 = getTri()
	
	local out = ac:Cross(ab).unit	
	local biDir = bc:Cross(out).unit
	local biLength = math.abs(ab:Dot(biDir))
	local bcLength = bc.magnitude
	
	t1.Size = Vector3.new(thickness, math.abs(ab:Dot(bc))/bcLength, biLength)
	t2.Size = Vector3.new(thickness, biLength, math.abs(ac:Dot(bc))/bcLength)
	
	bc = -bc.unit
	t1.CFrame = cfFromAxes((a+b)/2, -out, bc, -biDir)
	t2.CFrame = cfFromAxes((a+c)/2, -out, biDir, bc)
	
	return t1, t2
end