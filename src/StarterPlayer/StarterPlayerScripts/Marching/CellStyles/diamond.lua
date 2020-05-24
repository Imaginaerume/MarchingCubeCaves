return {
	Color = Color3.fromRGB(63, 126, 165),
	Material = "Neon",
	MaterialStrength = 0.7,
	Children = {
		{
			class = "PointLight",
			props = {
				Color = Color3.fromRGB(86, 120, 255),
				Brightness = 0.225,
				Range = 4,
			}
		}
	}
}