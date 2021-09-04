local StarterGui = game:GetService("StarterGui")
local BadgeService3 = script.Parent

local NotificationEvent: RemoteEvent = BadgeService3:WaitForChild("Notification")

return NotificationEvent.OnClientEvent:Connect(function(notificationData)
	StarterGui:SetCore("SendNotification", notificationData)
end)
