local starterGui = game:GetService("StarterGui")

script.Parent:WaitForChild("Notification").OnClientEvent:Connect(function(info)
	starterGui:SetCore("SendNotification", info)
end)

return true;
