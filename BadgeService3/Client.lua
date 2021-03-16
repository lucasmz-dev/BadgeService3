local starterGui = game:GetService("StarterGui")

script.Parent:WaitForChild("Notification").OnClientEvent:Connect(function(info)
	starterGui:SetCore("SendNotification", {
		Title = "Badge Awarded!";
		Text = 'You have been awarded "'.. info.Name..'"!';
		Icon = "rbxassetid://6170641771";
		Duration = 5;
	})
end)

return true;