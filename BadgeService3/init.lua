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

local function clearTable(Table)
	for index, value in pairs(Table) do
		if typeof(value) == "table" then
			clearTable(value)
		end
		Table[index] = nil
	end
end --// IDK, table.clear() says it's supposed to be used for stuff that should be reused. IN this case it woudn't.

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


function profileFunctions.AwardBadge(self, badgeId)
	if badges[badgeId] then
		if self.Data and (not (self.Data[badgeId])) then
			self.Data[badgeId] = true
			if not GlobalSettings.isNotificationsDisabled then
				notificationRemote:FireClient(self.Player, getNotificationInfo(badgeId))
			end
			self.Connectors.onBadgeAwarded:Fire(badgeId)
		end
	else
		error('[BadgeService3]:  No badge named: "'.. badgeId.. '" was found. Have you typed it correctly?')
	end
	self.Connectors.onUpdate:Fire(self)
end

function profileFunctions.RemoveBadge(self, badgeId)
	if badges[badgeId] then
		if self.Data[badgeId] then
			self.Data[badgeId] = nil
		end
	else
		error('[BadgeService3]:  No badge named: "'.. badgeId.. '" was found. Have you typed it correctly?')
	end
	self.Connectors.onUpdate:Fire(self)
end

function profileFunctions.GetOwnedBadges(self)
	local owned = {}
	for badgeId, owns in pairs(self.Data) do
		if owns == true then
			table.insert(owned, badgeId)
		end
	end
	return owned
end

function profileFunctions.OwnsBadge(self, badgeId)
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


function profileFunctions.Optimize(self)
	for index, owns in pairs(self.Data) do
		if typeof(owns) ~= "boolean" then
			self.Data[index] = true
		end
		if not badges[index] then
			self.Data[index] = nil
		end
	end 
	self.Connectors.onUpdate:Fire(self)
end

function profileFunctions.onUpdate(self, givenFunction)
	local connection = self.Connectors.onUpdate:Connect(givenFunction)
	table.insert(self._connections, connection)
	return connection
end

function profileFunctions.onBadgeAwarded(self, givenFunction)
	local connection = self.Connectors.onBadgeAwarded:Connect(givenFunction)
	table.insert(self._connections, connection)
	return connection
end

function profileFunctions.Delete(self)
	if profiles[self.Player] then
		for _, connection in pairs(self._connections) do
			connection:Disconnect()
		end
		for _, connector in pairs(self.Connectors) do
			connector:Destroy()
		end
		clearTable(self)
		if profiles[self.Player] ~= nil then
			profiles[self.Player] = nil
		end
		self = nil; --// idek if this does anything but whatever GARBAGE COLLECT IT 100% OK? now shut up.
	end
end

local module = {}

function module:LoadProfile(plr: Instance, profileData: table)
	if profiles[plr] then return profiles[plr] end
	assert(plr:IsA("Player"), "[BadgeService3]: You need to give a player object!")

	local profile = {
		Data = profileData;
		Player = plr;
		_connections = {};
		Connectors = {
			onUpdate = Signal.new();
			onBadgeAwarded = Signal.new();
		};
	}
	setmetatable(profile, {
		__index = function(_, index)
			return profileFunctions[index]
		end;
	})
	profiles[plr] = profile
	return profile
end

function module:WaitForProfile(plr: Instance)
	if profiles[plr] then return profiles[plr] end
	repeat
		game:GetService("RunService").Heartbeat:Wait()
	until profiles[plr] or plr.Parent == nil or (not (plr:IsDescendantOf(game.Players)))
	return profiles[plr]
end

function module:FindFirstProfile(plr: Instance)
	assert(plr:IsA("Player"), "You need to give a player object!")
	return profiles[plr]
end

function module:GetBadges()
	return badges, self:GetBadgeAmount()
end

function module:GetBadgeAmount()
	local quantity = 0
	for _, badge in pairs(badges) do
		quantity += 1
	end
	return quantity
end

function module:SetGlobalSettings(input: table)
	for settingId, newValue in pairs(input) do
		if GlobalSettings[settingId] ~= nil then
			if typeof(GlobalSettings[settingId]) == typeof(newValue) then
				GlobalSettings[settingId] = newValue
			end
		end
	end
end

local function onPlayerRemoved(plr)
	coroutine.wrap(function()
		wait(GlobalSettings.autoGarbageCollectProfileTime)
		local badgeProfile = module:FindFirstProfile(plr)
		if badgeProfile then
			badgeProfile:Delete()
		end
	end)()
end

game.Players.PlayerRemoving:Connect(onPlayerRemoved)

if false then
	return module
elseif runService:IsRunning() then
	--// prevents glitches from happening while on the console, or
	--   if the script editor gets mad because of this.
	--   this works just fine in-game, and you shoudn't worry about this.

	game:BindToClose(function()
		if not runService:IsStudio() then
			for _, plr in ipairs(game.Players:GetPlayers()) do
				onPlayerRemoved(plr)
			end
		end
	end)
end

return module
