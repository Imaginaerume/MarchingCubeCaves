--horrible demo code for throwing lights, digging, and grappling
local UIS = game:GetService("UserInputService")
UIS.MouseIconEnabled = false

repeat wait() until game.Players.LocalPlayer.Character 

local Mouse = game.Players.LocalPlayer:GetMouse()
local Character = game.Players.LocalPlayer.Character

local explode = require(script.Parent.Marching)

local light = Instance.new("PointLight", Character.HumanoidRootPart)
light.Color = Color3.new(0.5, 0.5, 0.9)
light.Range = 15
light.Brightness = 0.35

local function fireProjectile(start, velocity, range, stopOnTouch)
	local projectile = Instance.new("Part", workspace)
	projectile.Shape = "Ball"
	projectile.Size = Vector3.new(1.5, 1.5, 1.5)
	projectile.TopSurface = 0
	projectile.BottomSurface = 0
	projectile.Color = Color3.fromHSV(Random.new():NextNumber(0,1), 0.9, 0.9)
	projectile.Material = "Neon"
	projectile.CFrame = CFrame.new(start)
	projectile.CanCollide = false
	projectile.Velocity = (Mouse.Hit.p-start).unit*velocity
	
	local light = Instance.new("PointLight", projectile)
	light.Color = projectile.Color
	light.Range = range
	
	wait()
	
	projectile.CanCollide = true
	
	if stopOnTouch then
		projectile.Touched:connect(function()
			projectile.Anchored = true
		end)
	end
end

local rope
local shouldReel = false

UIS.InputBegan:connect(function(input)
	local character = game.Players.LocalPlayer.Character
	local start = (character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)).p
		
	if input.KeyCode == Enum.KeyCode.E then
		fireProjectile(start, 180, 30, false)
	elseif input.KeyCode == Enum.KeyCode.Q then
		fireProjectile(start, 360, 60, true)
	elseif input.KeyCode == Enum.KeyCode.Space and rope then
		rope:Destroy()
		rope = nil
		shouldReel = false
	elseif input.KeyCode == Enum.KeyCode.G and not rope then
		local a1 = Instance.new("Attachment", Character.HumanoidRootPart)
		local a2 = Instance.new("Attachment", workspace.Terrain)
		a2.Position = Mouse.Hit.p
		
		rope = Instance.new("RopeConstraint", Character)
		rope.Length = (a1.WorldPosition-a2.WorldPosition).magnitude+1
		rope.Attachment0 = a2
		rope.Attachment1 = a1
		rope.Visible = true
		
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		shouldReel = true
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		explode(Mouse.Hit.p, 1)
	end
end)

UIS.InputEnded:connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		shouldReel = false
	end
end)

game:GetService("RunService").Heartbeat:connect(function()
	if rope and rope.Length > 5 and shouldReel then
		rope.Length = rope.Length - 0.15
	end
end)
