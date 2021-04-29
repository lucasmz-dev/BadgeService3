local profiles = {}
local badges = require(script:WaitForChild("Badges"))
local Signal = require(script:WaitForChild("Signal"))

local notificationRemote = script:FindFirstChild("Notification") or Instance.new("RemoteEvent")
notificationRemote.Name = "Notification"
notificationRemote.Parent = script
--// Create Notification RemoteEvent;

local profileFunctions = {}
local runService = game:GetService("RunService")

local GlobalSettings = {
	["usesBadgeImageForNotifications"] = false;
	["isNotificationsDisabled"] = false;
	["usesGoldBadgeNotification"] = false;
	["defaultBadgeNotificationImage"] = "rbxassetid://6170641771";
	["notificationDuration"] = 5;
	["autoGarbageCollectProfileTime"] = 5;
	["NotificationDescription"] = 'You have been awarded "%s"!';
	["NotificationTitle"] = "Badge Awarded!"
}

local function deepCopy(t)
	if typeof(t) ~= "table" then return t end
	local copy = {}
	for index, value in pairs(t) do
		copy[index] = deepCopy(value)
	end
	return copy
end

local function getNotificationInfo(badgeId)
	if not badges[badgeId] then return end

	local title = GlobalSettings.NotificationTitle;
	local description = GlobalSettings.NotificationDescription;
	local image;

	if badges[badgeId].Image and GlobalSettings.usesBadgeImageForNotifications then
		if tonumber(badges[badgeId].Image) then
			image = "rbxassetid://"..badges[badgeId].Image
		else
			image = badges[badgeId].Image
		end
	elseif GlobalSettings.usesGoldBadgeNotification then
		image = 'rbxassetid://206410289'
	elseif GlobalSettings.defaultBadgeNotificationImage then
		image = GlobalSettings.defaultBadgeNotificationImage
	end

	description = string.format(description, badges[badgeId].Name)

	return {
		Title = title;
		Text = description;
		Icon = image;
		Duration = GlobalSettings.notificationDuration;
	}
end


function profileFunctions:AwardBadge(badgeId)
	if badges[badgeId] then
		if self.Data and (not (self.Data[badgeId])) then
			self.Data[badgeId] = true
			if not GlobalSettings.isNotificationsDisabled then
				notificationRemote:FireClient(self.Player, getNotificationInfo(badgeId))
			end
			self.onBadgeAwarded:Fire(badgeId)
		end
	else
		error('[BadgeService3]:  No badge named: "'.. badgeId.. '" was found. Have you typed it correctly?')
	end
	self.onUpdate:Fire(deepCopy(self.Data))
end

function profileFunctions:RemoveBadge(badgeId)
	if badges[badgeId] then
		if self.Data[badgeId] then
			self.Data[badgeId] = nil
		end
	else
		error('[BadgeService3]:  No badge named: "'.. badgeId.. '" was found. Have you typed it correctly?')
	end
	self.onUpdate:Fire(deepCopy(self.Data))
end

function profileFunctions:GetOwnedBadges()
	local owned = {}
	for badgeId, owns in pairs(self.Data) do
		if owns == true then
			table.insert(owned, badgeId)
		end
	end
	return owned
end

function profileFunctions:OwnsBadge(badgeId)
	if badges[badgeId] then
		if self.Data[badgeId] then
			return true
		else
			return false
		end
	else
		error('[BadgeService3]:  No badge named: "'.. badgeId.. '" was found. Have you typed it correctly?')
	end
end


function profileFunctions:Optimize()
	for index, owns in pairs(self.Data) do
		if typeof(owns) ~= "boolean" then
			self.Data[index] = true
		end
		if not badges[index] then
			self.Data[index] = nil
		end
	end 
	self.onUpdate:Fire(deepCopy(self.Data))
end

function profileFunctions:Destroy()
	if profiles[self.Player] then
		self.onUpdate:Destroy()
		self.onBadgeAwarded:Destroy()
		
		profiles[self.Player] = nil;
	end
end

function profileFunctions:Delete()
	return self:Destroy()
end

local module = {}

function module:LoadProfile(plr: Player, profileData: table)
	if profiles[plr] then return profiles[plr] end
	assert(plr:IsA("Player"), "[BadgeService3]: You need to give a player object!")

	local profile = {
		Data = profileData;
		Player = plr;
		onUpdate = Signal.new();
		onBadgeAwarded = Signal.new();
	}
	setmetatable(profile, {
		__index = function(_, index)
			return profileFunctions[index]
		end;
	})
	profiles[plr] = profile
	return profile
end

function module:WaitForProfile(plr: Player)
	if profiles[plr] then return profiles[plr] end
	repeat
		runService.Heartbeat:Wait()
	until profiles[plr] or plr.Parent == nil or not plr:IsDescendantOf(game.Players)
	return profiles[plr]
end

function module:FindFirstProfile(plr: Player)
	return profiles[plr]
end

function module:GetBadges()
	return badges, self:GetBadgeAmount()
end

function module:GetBadgeAmount()
	local quantity = 0
	for _ in pairs(badges) do
		quantity += 1
	end
	return quantity
end

function module:SetGlobalSettings(input)
	for settingId, newValue in pairs(input) do
		if GlobalSettings[settingId] ~= nil then
			if typeof(GlobalSettings[settingId]) == typeof(newValue) then
				GlobalSettings[settingId] = newValue
			end
		end
	end
end

local function onPlayerRemoved(plr)
	wait(GlobalSettings.autoGarbageCollectProfileTime)
	local badgeProfile = module:FindFirstProfile(plr)
	if badgeProfile then
		badgeProfile:Delete()
	end
end

game.Players.PlayerRemoving:Connect(onPlayerRemoved)

game:BindToClose(function()
	if not runService:IsStudio() then
		for _, plr in ipairs(game.Players:GetPlayers()) do
			coroutine.wrap(onPlayerRemoved)(plr)
		end
	end
end)


return module
