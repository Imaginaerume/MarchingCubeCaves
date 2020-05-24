--Preemptively adds triangles to the world and reuses them to reduce load
local buffer = 5000
local TriStorage = {}
local tris = {}

local container = Instance.new("Model", workspace)
container.Name = "triBinContainer"

function TriStorage.add(tri)
	if not tri then
		tri = Instance.new("WedgePart")
	end
	
	tri.Anchored = true
	tri.CanCollide = true
	tri.TopSurface = 0
	tri.BottomSurface = 0
	tri.Size = Vector3.new(5, 5, 5)
	tri.CFrame = CFrame.new(0, -500, 0)
	tri.Parent = container
	
	tris[#tris+1] = tri
end

function TriStorage.get()
	local tri = tris[1]
	table.remove(tris, 1)
	
	if #tris == 0 then
		fillBuffer()
	end
	
	return tri
end

function TriStorage.recycle(tri)
	tri.Transparency = 0
	tri.Material = "SmoothPlastic"
	
	TriStorage.add(tri)
end

function fillBuffer()
	for i = #tris, buffer do
		TriStorage.add()
	end
end

fillBuffer()

return TriStorage