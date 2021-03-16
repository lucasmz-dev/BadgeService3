local profiles = {}
local badges = require(script:WaitForChild("Badges"))
local Signal = require(script:WaitForChild("Signal"))
local profileFunctions = {}
local runService = game:GetService("RunService")

local function clearTable(Table)
	for index, value in pairs(Table) do
		if typeof(value) == "table" then
			clearTable(value)
		end
		Table[index] = nil
	end
end --// IDK, table.clear() says it's supposed to be used for stuff that should be reused. IN this case it woudn't.


function profileFunctions.AwardBadge(self, badgeId)
	if badges[badgeId] then
		if self.Data and (not (self.Data[badgeId])) then
			self.Data[badgeId] = true
			script:WaitForChild("Notification"):FireClient(self.Player, badges[badgeId])
		end
	else
		error('[BadgeService3]:  No badge named: "'.. badgeId.. '" was found. Have you typed it correctly?')
	end
	self.Connector:Fire(self)
end

function profileFunctions.RemoveBadge(self, badgeId)
	if badges[badgeId] then
		if self.Data[badgeId] then
			self.Data[badgeId] = nil
		end
	else
		error('[BadgeService3]:  No badge named: "'.. badgeId.. '" was found. Have you typed it correctly?')
	end
	self.Connector:Fire(self)
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
	self.Connector:Fire(self)
end

function profileFunctions.onUpdate(self, givenFunction)
	local connection = self.Connector:Connect(givenFunction)
	table.insert(self._connections, connection)
	return connection
end

function profileFunctions.Delete(self)
	if profiles[self.Player] then
		for _, connection in pairs(self._connections) do
			connection:Disconnect()
		end
		self.Connector:Destroy()
		clearTable(self)
		if profiles[self.Player] ~= nil then
			profiles[self.Player] = nil
		end
		self = nil; --// idek if this does anything but whatever
	end
end

local module = {}

function module:LoadProfile(plr: Instance, profileData: table)
	if false then
		return {
			Data = {};
			onUpdate = {
				Connect = function(self)
					return {
						Disconnect = function() end;
					}
				end;
			};
			AwardBadge = function(self) end;
			RemoveBadge = function(self) end;
			Optimize = function(self) end;
			Delete = function(self) end;
			OwnsBadge = function(self) end;
			GetOwnedBadges = function(self) end;
		}
	end

	if profiles[plr] then return profiles[plr] end
	assert(plr:IsA("Player"), "[BadgeService3]: You need to give a player object!")

	local profile = {
		Data = profileData;
		Player = plr;
		_connections = {};
		Connector = Signal.new();
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
	return badges
end

local function onPlayerRemoved(plr)
	coroutine.wrap(function()
		wait(5)
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
