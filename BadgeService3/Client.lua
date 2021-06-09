local StarterGui = game:GetService("StarterGui")

script.Parent
	:WaitForChild("Notification")
	.OnClientEvent:Connect(function(info)
		StarterGui:SetCore("SendNotification", info)
	end)

return true;
