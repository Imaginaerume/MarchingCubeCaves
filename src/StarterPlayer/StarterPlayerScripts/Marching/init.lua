--Dependencies
local GenerationConfig = require(script.GenerationConfig)
local VolumeGrid = require(script.Parent:WaitForChild("VolumeGrid"))
local GridCell = require(script.GridCell)

--Config values
local WORLD_SCALE = GenerationConfig.worldScale
local CELLS_PER_AXIS = GenerationConfig.cellsPerAxis
local ISO_LEVEL = GenerationConfig.isoLevel
	
local TERRAIN_AMPLITUDE = GenerationConfig.terrainAmplitude
local TERRAIN_FREQUENCY = GenerationConfig.terrainFrequency
local ORE_AMPLITUDE = GenerationConfig.oreAmplitude
local ORE_FREQUENCY = GenerationConfig.oreFrequency

--Randomizes the perlin noise grid
local NOISE_OFFSET = Random.new():NextNumber(-(10^8), 10^8)
local grid = VolumeGrid.new()

--Generate cell grid
for x = 1, CELLS_PER_AXIS do
	for y = 1, CELLS_PER_AXIS do
		for z = 1, CELLS_PER_AXIS do
			local noise = math.clamp(math.noise(
				(NOISE_OFFSET+x*TERRAIN_FREQUENCY)/TERRAIN_AMPLITUDE,
				(NOISE_OFFSET+y*TERRAIN_FREQUENCY)/TERRAIN_AMPLITUDE,
				(NOISE_OFFSET+z*TERRAIN_FREQUENCY)/TERRAIN_AMPLITUDE
			), -0.5, 0.5)
			
			local oreNoise = math.clamp(math.noise(
				(NOISE_OFFSET+y*ORE_FREQUENCY)/ORE_AMPLITUDE,
				(NOISE_OFFSET+x*ORE_FREQUENCY)/ORE_AMPLITUDE,
				(NOISE_OFFSET+z*ORE_FREQUENCY)/ORE_AMPLITUDE
			), -0.5, 0.5)
			
			local cell = GridCell.new(x,y,z, noise + 0.5)
			
			if oreNoise < 0.4 then
				cell.cellType = "rock"
			elseif oreNoise < 0.4999 then
				cell.cellType = "lightRock"
			elseif oreNoise >= 0.4999 then
				cell.cellType = "diamond"
			end
			
			if x == 1 or y == 1 or z == 1 or x == CELLS_PER_AXIS or y == CELLS_PER_AXIS or z == CELLS_PER_AXIS then
				cell.cellType = "worldBorder"
			end
			
			grid:addCell(x,y,z, cell)
		end
	end
end

--seal the edges
for x = 1, CELLS_PER_AXIS do
	for y = 1, CELLS_PER_AXIS do
		grid[x][y][1].w = 1
		grid[x][y][CELLS_PER_AXIS].w = 1
	end
end

for z = 1, CELLS_PER_AXIS do
	for y = 1, CELLS_PER_AXIS do
		grid[1][y][z].w = 1
		grid[CELLS_PER_AXIS][y][z].w = 1
	end
end

for x = 1, CELLS_PER_AXIS do
	for z = 1, CELLS_PER_AXIS do
		grid[x][1][z].w = 1
		grid[x][CELLS_PER_AXIS][z].w = 1
	end
end

--render the grid
for x, row in pairs(grid) do
	for y, column in pairs(row) do
		for z, cell in pairs(column) do
			cell:update()
		end
	end
end

--Digging, explosions
function explosion(position, radius)
	--format position
	local position = position / WORLD_SCALE
	local roundedPos = Vector3.new(math.floor(position.x+0.5), math.floor(position.y+0.5), math.floor(position.z+0.5))
	
	local origin = grid[roundedPos.x][roundedPos.y][roundedPos.z]
	
	if origin then
		local inRadius = origin:getCellsInRadius(radius)
		
		--Set the cell to non-existent, but don't update until all cells have been destroyed to reduce duplicate checks
		for _, cell in pairs(inRadius) do
			cell:destroy(true)
		end
		
		--Check all cells surrounding the explosion once
		local alreadyUpdated = {}
		
		for _, adjacent in pairs(origin:getCellsInRadius(radius+2)) do
			if not alreadyUpdated[adjacent] then
				adjacent:update()
				alreadyUpdated[adjacent] = true
			end
		end
	end
end

--Place the player in an open area
local player = game.Players.LocalPlayer
local character = player.Character or (player.CharacterAdded:wait() and player.Character)
local emptyAbove = 8

for x, row in pairs(grid) do
	for y, column in pairs(row) do
		for z, cell in pairs(column) do
			local isEmptyAbove = true
			
			for y2 = 1, emptyAbove do
				if not grid[x][y+y2][z] or grid[x][y+y2][z].w >= ISO_LEVEL then
					isEmptyAbove = false
				end
			end
			
			if cell.w > ISO_LEVEL and isEmptyAbove then
				character.HumanoidRootPart.CFrame = CFrame.new(Vector3.new(cell.x, cell.y + 4, cell.z)*WORLD_SCALE)
				break
			end
		end
	end
end

return explosion
