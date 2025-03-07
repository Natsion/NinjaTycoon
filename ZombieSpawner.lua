local level = 5
while true do
	print(#workspace.Zombies:GetChildren())
	if #workspace.Zombies:GetChildren() <= 100 then
		local z = game.ServerStorage.Zombie:Clone()
		z.Parent = workspace.Zombies
		z:MoveTo(Vector3.new(math.random(-350, 350), 500, math.random(-350, 350)))
	end
	task.wait(1)
end
