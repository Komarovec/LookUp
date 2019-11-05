-- Main script
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_setupBox.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Other scripts
AddCSLuaFile("round_controller/sv_round_controller.lua")
include("round_controller/sv_round_controller.lua")

AddCSLuaFile("prop_rain/sv_prop_rain.lua")
include("prop_rain/sv_prop_rain.lua")

AddCSLuaFile("entities/powerup/init.lua")

-- Gamemode type
DeriveGamemode("base")

-- Network Att
util.AddNetworkString("ChatText")
util.AddNetworkString("ScreenText")
util.AddNetworkString("ScreenTextWinner")
util.AddNetworkString("Sound")
util.AddNetworkString("WaveType")
util.AddNetworkString("PropChange")
util.AddNetworkString("PointTable")
util.AddNetworkString("GameplayersTable")
util.AddNetworkString("SpectatorsTable")
util.AddNetworkString("tables")
util.AddNetworkString("originPoint")
util.AddNetworkString("minsVector")
util.AddNetworkString("maxsVector")
util.AddNetworkString("setupMode")

-- Settings
pushMultiplier = 2000

-- Map Check
mapName = game.GetMap();
if(mapName == "gm_flatgrass") then
	propsSpawnpoint = Vector(0, 0, -12287)
	deathLine = -12400
elseif(mapName == "gm_construct") then
	propsSpawnpoint = Vector(-458, 265, -84)
	deathLine = -12400
elseif(mapName == "lu_canals") then
	propsSpawnpoint = Vector(0, 0, 0)
	deathLine = -400
else
	propsSpawnpoint = Vector(0, 0, 0)
	deathLine = 0
	mapName = "UNSUP"
end

-- Vars
local spectators = {}
local queue = {}
local dead = {}
local remove = {}
local respawn = {}
local reminder = 0
local spawnNormal
local stargate = true
local spawnPoints = {}
local pos1 = nil
local pos2 = nil

ultraPush = {}
gamePlayers = {}

-- Hooks
hook.Add("PlayerSay", "ChatCommands", function(ply, text, team)
	if(string.sub(text, 1, 11) == "!beginRound" || string.sub(text, 1, 11) == "!roundBegin" ) then -- Begin new round -- All users, voting system?
		initializeRound()
	elseif(string.sub(text, 1, 11) == "!difficulty") then -- Change difficulty --> only admins
		if(ply:IsAdmin()) then
			if(string.sub(text, 13, 13) == "1") then
				changeDifficulty(1)
				broadcastMess("Game difficulty changed to 1 (default)!")
			elseif(string.sub(text, 13, 13) == "2") then
				changeDifficulty(2)
				broadcastMess("Game difficulty changed to 2!")
			else
				sendMess("None or incorrect setting entered! Choose between 1 - (default) or 2 - (2x harder).", ply)
			end
		else
			sendMess("Only admins can change difficulty!", ply)
		end
	elseif(string.sub(text, 1, 6) == "!stats") then -- Prints information about points, positions
		status(ply)
	elseif(string.sub(text, 1, 9) == "!forceEnd") then -- Force end the game --> only admins
		if(ply:IsAdmin()) then
			forceEnd()
		else
			sendMess("Only admins can use  this command!", ply)
		end
	elseif(string.sub(text, 1, 7) == "!points") then -- Debug functions
		printPoints(ply)
	elseif(string.sub(text, 1, 11) == "!playersAll") then -- Debug functions
		sendMess("--- Printing game players:", ply)
		for k, v in pairs(getGamePlayers()) do
			sendMess(k.." "..v:Nick(), ply)
		end
		sendMess("--- Printing dead players:", ply)
		for k, v in pairs(getDeadPlayers()) do
			sendMess(k.." "..v:Nick(), ply)
		end
		sendMess("--- Printing spectators:", ply)
		for k, v in pairs(getSpectators()) do
			sendMess(k.." "..v:Nick(), ply)
		end
		sendMess("--- Printing queue:", ply)
		for k, v in pairs(getQueue()) do
			sendMess(k.." "..v, ply)
		end
	elseif(string.sub(text, 1, 5) == "!help") then -- Shows all commands
		sendMess("List of Commands:", ply)
		sendMess("!beginRound -- Start a round", ply)
		sendMess("!difficulty <1-2> -- Change difficulty", ply)
		sendMess("!stats -- Shows players points", ply)
		sendMess("- Debug Commands -", ply)
		sendMess("!forceEnd -- Forces end of the game", ply)
		sendMess("!points -- Prints point table", ply)
		sendMess("!playersAll -- Prints every player table", ply)
	elseif(string.match( text, "!setup")) then --Set server to setup mode and stop currently running game
		if(ply:IsAdmin()) then
			if(getRoundStatus() == 1) then
				forceEnd()
			end
			if(!getSetupStatus()) then
				changeSetupMode(true, ply)
				broadcastBoolValue("setupMode", true)
				print("Sent setupMode value")
			else
				sendMess("Server is already in setup mode", ply)
			end
		else
			sendMess("You must be admin to setup a map", ply)
		end
	elseif(string.match( text, "!stopSetup")) then --Stop setup mode
		if(ply:IsAdmin()) then
			if(getSetupStatus()) then
				changeSetupMode(false, ply)
				broadcastBoolValue("setupMode", false)
			else
				sendMess("Server is not in setup mode right now", ply)
			end
		else
			sendMess("Only admin can change this", ply)
		end
	elseif(string.match( text, "!pos1")) then --Add spawn area's first point
		if(ply:IsAdmin()) then
			if(getSetupStatus()) then
				pos1 = ply:GetPos()	
				pos1.z = 1000
				local prop = ents.Create("prop_physics")
				prop:SetModel("models/props_lab/monitor02.mdl")
				prop:SetPos(pos1)
				prop:SetAngles(Angle(0,0,0))
				prop:SetMoveType(MOVETYPE_NONE)
				prop:Spawn()
				conDebugVector(pos1, "POS1")
				sendMess("Position 1 set", ply)
			else
				sendMess("Server must be in setup mode to configure the gamemode!", ply)
			end
		else
			sendMess("You can't use this command if you are not admin!", ply)
		end
	elseif(string.match( text, "!pos2")) then --Add spawn area's second point
		if(ply:IsAdmin()) then
			if(getSetupStatus()) then
				if(pos1 != nil) then
					pos2 = ply:GetPos()
					pos2.z = 1000
					local prop2 = ents.Create("prop_physics")
					prop2:SetModel("models/props_lab/monitor02.mdl")
					prop2:SetPos(pos2)
					prop2:SetAngles(Angle(0,0,0))
					prop2:SetMoveType(MOVETYPE_NONE)
					prop2:Spawn()
					conDebugVector(pos2, "POS2")
					sendMess("Position 2 set", ply)
					local diameterVector = subtractVectors(pos1, pos2) / 2
					conDebugVector(diameterVector, "Diameter")
					local originPoint = pos1
					conDebugVector(originPoint, "Origin point")
					local minsVector = pos1
					minsVector.z = 1000
					conDebugVector(minsVector, "Mins vector")
					local maxsVector = pos2
					maxsVector.z = 1000
					conDebugVector(maxsVector, "Maxs vector")
					broadcastNetVector("originPoint", originPoint)
					broadcastNetVector("minsVector", minsVector)
					broadcastNetVector("maxsVector", maxsVector)
				else
					sendMess("You must set !pos1 first!", ply)
				end
			else
				sendMess("Server must be in setup mode to configure the gamemode!", ply)
			end
		else
			sendMess("You can't use this command if you are not admin!", ply)
		end
	end
end)

hook.Add("Think", "MapLimiter", function() -- Limit the map by height limit; Kills every player below limit
	if(mapName == "UNSUP") then return end
	for k, v in pairs(player.GetAll()) do
		if(v:GetPos().z < deathLine) then -- If player is spectator/dead --> do not kill
			for k1, v1 in pairs(spectators) do
				if(v1 == v) then return end
			end
			for k1, v1 in pairs(dead) do
				if(v1 == v) then return end
			end
			v:Kill()
		end
	end
end)

hook.Add("Think", "NoPlayerEnd", function() -- End the round if no players left
	if(table.Count(getGamePlayers()) == (table.Count(spectators)+table.Count(dead)) && getRoundStatus() == 1) then
		endRound()
	end
end)

hook.Add("Think", "Reminder", function() -- Remind to start a round, when no round
	if(getRoundStatus() == -1 && reminder < RealTime()) then
		broadcastScrMess("To start a round type !beginRound")
		reminder = RealTime() + 60
	end
end)

hook.Add("Think", "StargateDelter", function() -- Delete stargate; This is quite useless but a use stargate alot :P
	if(stargate == true) then
		stargate = false
		deleteStargate()
	end
end)

hook.Add("PostPlayerDeath", "DeathMessage", function(ply) -- Start timer to respawn player, if player is spectator, remove him from spectators
	for k, v in pairs(spectators) do
		if(ply == v) then 
			table.RemoveByValue(spectators, ply)
		end
	end

	timer.Simple(3, function()
		for k,v in pairs(dead) do
			if(v == ply) then
				ply:Spawn() 
			end
		end 
    end) 

	for k, v in pairs(dead) do
		if(ply == v) then
			broadcastMess("Bug found!! DEBUG CODE: PPD01")
			return
		end
	end
	table.insert(dead, ply)
end)

-- Functions
function GM:PlayerConnect(name, ip) -- If game is running add players to queue, else nothing
	if(getRoundStatus() >= 0) then
		table.insert(queue, name)
	end
end

function GM:PlayerDisconnected(ply) -- Deletes plys records
	deleteStats(ply)
	broadcastMess(ply:Nick().." has left the server." )
end

function GM:PlayerSpawn(ply)
	self.BaseClass:PlayerSpawn(ply)
	ply:SetModel("models/player/Police.mdl") -- player model

	if(getRoundStatus() >= 0 && queue[1] != nil) then -- If players just connected and is in queue, add him to tables and the game
		for k, v in pairs(player.GetAll()) do
			for k1, v1 in pairs(queue) do
				if(v:Nick() == v1) then
					table.insert(gamePlayers, v)
					table.insert(points, 0)
					table.RemoveByValue(queue, v1)
				end
			end
		end
		broadcastTables()
	end

	if(getRoundStatus() == 1) then -- If players respawned while prop_fall, spectate --> no points
		ply:Spectate(6)
		table.RemoveByValue(dead, ply)
		for k, v in pairs(spectators) do
			if(ply == v) then return end
		end
		broadcastMess(ply:Nick().." has been added to spectators!")
		table.insert(spectators, ply)

	elseif(getRoundStatus() == 0 || getRoundStatus() == -1) then  -- Regular respawn while, timeout or no game
		table.RemoveByValue(dead, ply)
		table.RemoveByValue(spectators, ply)
		ply:Give("weapon_crowbar", true)

	else
		broadcastMess("Something went wrong, player: "..ply:Nick().." has found a bug! Debug code: SPAWN01")
	end
end

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo ) -- Push other players when hit with crowbar
	scaleDmg = 1
	for k, v in pairs(player.GetAll()) do
		if(dmginfo:GetAttacker() == v) then 
			scaleDmg = 0
			if(dmginfo:GetAttacker():GetActiveWeapon():GetPrintName() == "#HL2_Crowbar") then
				pushPlayer(dmginfo:GetAttacker(), ply)
			end
		end
	end
	dmginfo:ScaleDamage(scaleDmg)
end

--[[ Extremely dangerous function --> gives weapons and ammo
function giveAmmo(ply)
	ply:GiveAmmo( 200, "Pistol", true )
	ply:GiveAmmo( 200, "AR2", true )
	ply:GiveAmmo( 6, "AR2AltFire", true )
	ply:GiveAmmo( 200, "SMG1", true )
	ply:GiveAmmo( 4, "SMG1_Granade", true )
	ply:GiveAmmo( 30, "357", true )
	ply:GiveAmmo( 60, "Buckshot", true )
end
]]

function initializeRound() -- New game; starting with 0 points and 0 round; easiest difficulty
	if(mapName == "UNSUP") then
		broadcastScrMess("Unsupported map!")
		return;
	end
	gamePlayers = player.GetAll()
	initializePoints()
	setDifficulty(0)
	beginRound()
end

function broadcastScrMess(mess) -- Broadcast screen message to all players
	net.Start("ScreenText")
		net.WriteString(mess)
	net.Broadcast()
end

function broadcastScrWinner(mess) -- Broadcast winner message to all players
	net.Start("ScreenTextWinner")
		net.WriteString(mess)
	net.Broadcast()
end

function sendScrMess(mess, ply) -- Send screen message to one player
	net.Start("ScreenText")
		net.WriteString(mess)
	net.Send(ply)
end

function broadcastMess(mess) -- Send chat message to all players
	net.Start("ChatText")
		net.WriteString(mess)
	net.Broadcast()
end

function broadcastTables() -- Broadcast Point tables etc.. --> scoreboard update
	net.Start("PointTable")
		net.WriteTable(points)
	net.Broadcast()

	net.Start("GameplayersTable")
		net.WriteTable(getGamePlayers())
	net.Broadcast()

	net.Start("SpectatorsTable")
		net.WriteTable(getSpectators())
	net.Broadcast()
end

function sendMess(mess, ply) -- Send chat message to one player
	net.Start("ChatText")
		net.WriteString(mess)
	net.Send(ply)
end

net.Receive("ReloadAll", function(ln, ply) -- Give weapon to player
	local weapon = net.ReadString()
	ply:Give(weapon, false)
end)

net.Receive("tables", function(ln, ply) -- Receive table update from players
	net.Start("PointTable")
		net.WriteTable(points)
	net.Send(ply)

	net.Start("GameplayersTable")
		net.WriteTable(getGamePlayers())
	net.Send(ply)

	net.Start("SpectatorsTable")
		net.WriteTable(getSpectators())
	net.Send(ply)
end)

function respawnSpectators() -- Respawn spectators, remove the from spectators table
	respawn = {}
	for k, v in pairs(spectators) do
		table.insert(respawn, v)
	end
	for k, v in pairs(respawn) do
		v:UnSpectate()
		v:Spawn()
	end
	respawn = {}
end

function getGamePlayers()
	return gamePlayers
end

function getDeadPlayers()
	return dead
end

function getSpectators()
	return spectators
end

function getQueue()
	return queue
end

function deleteStargate() -- Removes all stargate objects
	StarGate.GateSpawner.Block = true
	for k, v in pairs(ents.FindByClass("stargate*")) do	 
		v:Remove() 
	end
end

function status(ply) -- Prints all players points
	sendMess("-- All players stats:", ply)
	for k, v in pairs(getGamePlayers()) do
		if(v == nil) then break end
		sendMess("Player ("..v:Nick()..") has "..getPoints(v).." points.", ply)
	end
end

function deleteStats(ply) -- Deletes all points
	for k, v in pairs(getGamePlayers()) do
		if(ply == v) then
			table.remove(points, k)
		end
	end
	table.RemoveByValue(gamePlayers, ply)
	table.RemoveByValue(dead, ply)
	table.RemoveByValue(spectators, ply)
end

function pushPlayer(pusher, pushed) -- Pushes player, global power x Powerup
	local power = 1
	for k, v in pairs(ultraPush) do -- If power up, stronger push
		if(v == pusher) then power = 10 end
	end
	pushed:SetVelocity(Vector(pusher:GetAimVector().x,pusher:GetAimVector().y,0)*pushMultiplier*power)
end

function playSound(pwd) -- Play sound from path to all players
	net.Start("Sound")
		net.WriteString(pwd)
	net.Broadcast()
end

function playSoundPly(pwd, ply) -- Play sound from path to one player
	net.Start("Sound")
		net.WriteString(pwd)
	net.Send(ply)
end

function setRoundReminder(delayR)
	reminder = RealTime() + delayR
end

function givePowerup(ply) -- Get random powerup
	local r = math.random(1,2)
	if(r == 1) then
		sendScrMess("pu-100", ply)
		addPoints(ply, 100)
	elseif(r == 2) then
		sendScrMess("pu-power", ply)
		table.insert(ultraPush, ply)
	end
end

function resetPowerups() -- Reset powerups table
	ultraPush = {}
end

function broadcastNetVector(name, vector)
	net.Start(name)
	net.WriteVector(vector)
	net.Broadcast()
end

function broadcastBoolValue(name, value)
	net.Start(name)
	net.WriteBool(value)
	net.Broadcast()
end

function conDebugVector(vector, name)
	print("Vector "..name.."("..vector.x..","..vector.y..","..vector.z..")")
end

--Subtracts two vectors
function subtractVectors(u, v)
	return Vector(v.x - u.x, v.y - u.y, v.z - u.z)
end

--Adds two vectors
function addVectors(u,v)
	return Vector(u.x + v.x, u.y + v.y, u.z + v.z)
end

function multiplyVectors(u, v)
	return Vector(u.x * v.x, u.y * v.y, u.z * v.z)
end