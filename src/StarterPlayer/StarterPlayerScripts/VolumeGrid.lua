--Generates a table type that can be indexed in 3 dimensions by creating a new table if one doesn't exist for the x and y dimensions
local VolumeGrid = {}

function VolumeGrid.new()
	return setmetatable({}, {
		__index = function(grid, x)
			--return the grid class method if it exists
			if VolumeGrid[x] then
				return VolumeGrid[x]
			end
			
			local row = {}		
			grid[x] = row
			
			setmetatable(row, {
				__index = function(_, y)
					local column = {}
					row[y] = column
					
					return column
				end
			})
			
			return row
		end
	})
end

function VolumeGrid:addCell(x,y,z, cell)
	cell.grid = self
	self[x][y][z] = cell
end

return VolumeGrid