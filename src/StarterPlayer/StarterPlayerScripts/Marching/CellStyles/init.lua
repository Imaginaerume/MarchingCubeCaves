local CellStyles = {}

for _, style in pairs(script:GetChildren()) do
	CellStyles[style.Name] = require(style)
end

return CellStyles