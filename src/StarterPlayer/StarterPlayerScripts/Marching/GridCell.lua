local GenerationConfig = require(script.Parent.GenerationConfig)
local MarchTables = require(script.Parent.MarchTables)
local createTriangle = require(script.Parent.createTriangle)
local TriStorage = require(script.Parent.TriStorage)
local CellStyles = require(script.Parent.CellStyles)

local OresCounter
if GenerationConfig.oreCounterEnabled then
	local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	OresCounter = PlayerGui.ScreenGui.Ores
end

--Marching cubes tables
local TRIANGULATION = MarchTables.triangulation
local CORNER_INDEX_A_FROM_EDGE = MarchTables.cornerIndexAFromEdge
local CORNER_INDEX_B_FROM_EDGE = MarchTables.cornerIndexBFromEdge

local WORLD_SCALE = GenerationConfig.worldScale
local CELLS_PER_AXIS = GenerationConfig.cellsPerAxis
local ISO_LEVEL = GenerationConfig.isoLevel

--Helper functions
local function renderTriangle(posA, posB, posC) 
	return createTriangle(posA*WORLD_SCALE, posB*WORLD_SCALE, posC*WORLD_SCALE)
end

local function interpolateVerts(v1,  v2) 
    local t = (ISO_LEVEL - v1.w) / (v2.w - v1.w) 
    return Vector3.new(v1.x, v1.y, v1.z):Lerp(Vector3.new(v2.x, v2.y, v2.z), t)
end

local worldModel = Instance.new("Model", workspace)
worldModel.Name = "MarchingCubesWorld"

--Grid cell class
local GridCell = {}

function GridCell.new(x,y,z, w)
	local cell = {
		x = x,
		y = y,
		z = z,
		w = w,
		tris = {},
	}
	
	setmetatable(cell, {__index = GridCell})
	
	return cell
end

function GridCell:destroy(dontUpdate)
	if self.w ~= 0 and self.cellType ~= "worldBorder" then
		self.w = 0
		
		if GenerationConfig.oreCounterEnabled and OresCounter:FindFirstChild(self.cellType) then
			OresCounter[self.cellType].Quantity.Text = tonumber(OresCounter[self.cellType].Quantity.Text) + 1
		end
		
		if not dontUpdate then
			self:updateAdjacent()
		end
	end
end

function GridCell:updateAdjacent()
	for _, cell in pairs(self:getAdjacent()) do
		cell:update()
	end
end

function GridCell:getAdjacent(facesOnly)
	local grid = self.grid
	local adjacent = {}
	
	if not facesOnly then
		for x = self.x-1, self.x+1 do
			for y = self.y-1, self.y+1 do
				for z = self.z-1, self.y+1 do
					table.insert(adjacent, grid[x][y][z])
				end
			end
		end
	else
		local x,y,z = self.x, self.y, self.z
		
		table.insert(adjacent, grid[x][y][z])
		table.insert(adjacent, grid[x+1][y][z])
		table.insert(adjacent, grid[x][y][z+1])
		table.insert(adjacent, grid[x][y+1][z])
		table.insert(adjacent, grid[x-1][y][z])
		table.insert(adjacent, grid[x][y][z-1])
		table.insert(adjacent, grid[x][y-1][z])
	end
	
	return adjacent
end

function GridCell:getCellsInRadius(radius)
	local grid = self.grid
	local cells = {}
	
	for x = self.x - radius, self.x + radius do
		for y = self.y - radius, self.y + radius do
			for z = self.z - radius, self.z + radius do
				if grid[x][y][z] and (Vector3.new(self.x, self.y, self.z) - Vector3.new(x, y, z)).magnitude <= radius then
					table.insert(cells, grid[x][y][z])
				end
			end
		end
	end
	
	return cells
end

function GridCell:getCellsInRange(range)
	local grid = self.grid
	local cells = {}
	
	for x = self.x - range, self.x + range do
		for y = self.y - range, self.y + range do
			for z = self.z - range, self.z + range do
				table.insert(cells, grid[x][y][z])
			end
		end
	end
	
	return cells
end

function GridCell:update()
	local grid = self.grid	
	local cell = self
	local w = cell.w
	
	if cell.x >= CELLS_PER_AXIS or cell.y >= CELLS_PER_AXIS or cell.z >= CELLS_PER_AXIS then
       return
    end
	
    local cubeCorners = {
		grid[cell.x][cell.y][cell.z],
        grid[cell.x+1][cell.y][cell.z],
        grid[cell.x+1][cell.y][cell.z+1],
        grid[cell.x][cell.y][cell.z+1],
        grid[cell.x][cell.y+1][cell.z],
        grid[cell.x+1][cell.y+1][cell.z],
        grid[cell.x+1][cell.y+1][cell.z+1],
        grid[cell.x][cell.y+1][cell.z+1]
    }

    local cubeIndex = 0;
	for i = 0, 7 do
		if cubeCorners[i+1] and cubeCorners[i+1].w < ISO_LEVEL then
			cubeIndex = bit32.bor(cubeIndex, bit32.lshift(1, i))
		end
	end
	
	cubeIndex = cubeIndex + 1
	
	if cell.lastCubeIndex and cell.lastCubeIndex == cubeIndex then
		return
	end
	
	cell.lastCubeIndex = cubeIndex
	
	local newTris = {}
	
	local i = 1
	while TRIANGULATION[cubeIndex][i] ~= -1 do
        local a0 = CORNER_INDEX_A_FROM_EDGE[TRIANGULATION[cubeIndex][i]+1]
        local b0 = CORNER_INDEX_B_FROM_EDGE[TRIANGULATION[cubeIndex][i]+1]

        local a1 = CORNER_INDEX_A_FROM_EDGE[TRIANGULATION[cubeIndex][i+1]+1]
        local b1 = CORNER_INDEX_B_FROM_EDGE[TRIANGULATION[cubeIndex][i+1]+1]

        local a2 = CORNER_INDEX_A_FROM_EDGE[TRIANGULATION[cubeIndex][i+2]+1]
        local b2 = CORNER_INDEX_B_FROM_EDGE[TRIANGULATION[cubeIndex][i+2]+1]
		
		local t1, t2 = renderTriangle(
			interpolateVerts(cubeCorners[a0+1], cubeCorners[b0+1]),
			interpolateVerts(cubeCorners[a1+1], cubeCorners[b1+1]),
			interpolateVerts(cubeCorners[a2+1], cubeCorners[b2+1])
		)
		
		local style = CellStyles[cell.cellType]
		for prop, val in pairs(style) do
			if prop ~= "Children" and prop ~= "MaterialStrength" then
				if not style.MaterialStrength or (prop ~= "Material")  then
					t1[prop] = val
					t2[prop] = val
				end
			end
		end
		
		--Material strength affects how visible the material is by making a translucent copy that layers on top of a smooth, opaque part
		if style.MaterialStrength then
			local base1 = t1:Clone()
			base1.Transparency = style.MaterialStrength
			base1.Material = style.Material
			table.insert(newTris, base1)
			
			local base2 = t2:Clone()
			base2.Transparency = style.MaterialStrength
			base2.Material = style.Material
			table.insert(newTris, base2)
			
			t1.Transparency = 0
			t2.Transparency = 0
		end
		
		if style.Children then
			for _, childData in pairs(style.Children) do
				local child = Instance.new(childData.class)
				for prop, value in pairs(childData.props) do
					child[prop] = value
				end
				child.Parent = t1
				child:Clone().Parent = t2
			end
		end
		
		i = i + 3
		
		table.insert(newTris, t1)
		table.insert(newTris, t2)
    end
	
	--clear old tris
	for _, tri in pairs(self.tris) do
		TriStorage.recycle(tri)
	end
	
	--render new tris
	for _, tri in pairs(newTris) do
		tri.Parent = worldModel
	end
	
	self.tris = newTris
end

return GridCell
