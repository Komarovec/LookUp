-- Main script
AddCSLuaFile("cl_init.lua")
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
ultraPush = {}
gamePlayers = {}

-- Hooks
hook.Add("PlayerSay", "ChatCommands", function(ply, text, team)
	if(string.sub(text, 1, 11) == "!beginRound" || string.sub(text, 1, 11) == "!roundBegin" ) then
		initializeRound()
	elseif(string.sub(text, 1, 11) == "!difficulty") then
		if(string.sub(text, 13, 13) == "1") then
			changeDifficulty(1)
			broadcastMess("Game difficulty changed to 1 (default)!")
		elseif(string.sub(text, 13, 13) == "2") then
			changeDifficulty(2)
			broadcastMess("Game difficulty changed to 2!")
		else
			sendMess("None or incorrect setting entered! Choose between 1 - (default) or 2 - (2x harder).", ply)
		end
	elseif(string.sub(text, 1, 6) == "!stats") then
		status(ply)
	elseif(string.sub(text, 1, 9) == "!forceEnd") then
		forceEnd()
	elseif(string.sub(text, 1, 7) == "!points") then
		printPoints(ply)
	elseif(string.sub(text, 1, 11) == "!playersAll") then
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
	elseif(string.sub(text, 1, 5) == "!help") then
		sendMess("List of Commands:", ply)
		sendMess("!beginRound -- Start a round", ply)
		sendMess("!difficulty <1-2> -- Change difficulty", ply)
		sendMess("!stats -- Shows players points", ply)
		sendMess("- Debug Commands -", ply)
		sendMess("!forceEnd -- Forces end of the game", ply)
		sendMess("!points -- Prints point table", ply)
		sendMess("!playersAll -- Prints every player table", ply)
	end
end)

hook.Add("Think", "MapLimiter", function()
	if(mapName == "UNSUP") then return end
	for k, v in pairs(player.GetAll()) do
		if(v:GetPos().z < deathLine) then
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

hook.Add("Think", "NoPlayerEnd", function()
	if(table.Count(getGamePlayers()) == (table.Count(spectators)+table.Count(dead)) && getRoundStatus() == 1) then
		endRound()
	end
end)

hook.Add("Think", "Reminder", function()
	if(getRoundStatus() == -1 && reminder < RealTime()) then
		broadcastScrMess("To start a round type !beginRound")
		reminder = RealTime() + 60
	end
end)

hook.Add("Think", "StargateDelter", function()
	if(stargate == true) then
		stargate = false
		deleteStargate()
	end
end)

hook.Add("PostPlayerDeath", "DeathMessage", function(ply)
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
function GM:PlayerConnect(name, ip)
	if(getRoundStatus() >= 0) then
		table.insert(queue, name)
	end
end

function GM:PlayerDisconnected(ply)
	deleteStats(ply)
	broadcastMess(ply:Nick().." has left the server." )
end

function GM:PlayerSpawn(ply)
	self.BaseClass:PlayerSpawn(ply)
	ply:SetModel("models/player/Police.mdl") -- player model

	if(getRoundStatus() >= 0 && queue[1] != nil) then
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

	if(getRoundStatus() == 1) then 
		ply:Spectate(6)
		table.RemoveByValue(dead, ply)
		for k, v in pairs(spectators) do
			if(ply == v) then return end
		end
		broadcastMess(ply:Nick().." has been added to spectators!")
		table.insert(spectators, ply)

	elseif(getRoundStatus() == 0 || getRoundStatus() == -1) then 
		table.RemoveByValue(dead, ply)
		table.RemoveByValue(spectators, ply)
		ply:Give("weapon_crowbar", true)

	else
		broadcastMess("Shit... something went wrong, player: "..ply:Nick().." has found a bug! Debug code: SPAWN01")
	end
end

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )
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

function giveAmmo(ply)
	ply:GiveAmmo( 200, "Pistol", true )
	ply:GiveAmmo( 200, "AR2", true )
	ply:GiveAmmo( 6, "AR2AltFire", true )
	ply:GiveAmmo( 200, "SMG1", true )
	ply:GiveAmmo( 4, "SMG1_Granade", true )
	ply:GiveAmmo( 30, "357", true )
	ply:GiveAmmo( 60, "Buckshot", true )
end

function initializeRound()
	if(mapName == "UNSUP") then
		broadcastScrMess("Unsupported map!")
		return;
	end
	gamePlayers = player.GetAll()
	initializePoints()
	setDifficulty(0)
	beginRound()
end

function broadcastScrMess(mess)
	net.Start("ScreenText")
		net.WriteString(mess)
	net.Broadcast()
end

function broadcastScrWinner(mess)
	net.Start("ScreenTextWinner")
		net.WriteString(mess)
	net.Broadcast()
end

function sendScrMess(mess, ply)
	net.Start("ScreenText")
		net.WriteString(mess)
	net.Send(ply)
end

function broadcastMess(mess)
	net.Start("ChatText")
		net.WriteString(mess)
	net.Broadcast()
end

function broadcastTables()
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

function sendMess(mess, ply)
	net.Start("ChatText")
		net.WriteString(mess)
	net.Send(ply)
end

net.Receive("ReloadAll", function(ln, ply)
	local weapon = net.ReadString()
	ply:Give(weapon, false)
end)

net.Receive("tables", function(ln, ply)
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

function respawnSpectators()
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

function deleteStargate()
	StarGate.GateSpawner.Block = true
	for k, v in pairs(ents.FindByClass("stargate*")) do	 
		v:Remove() 
	end
end

function status(ply)
	sendMess("-- All players stats:", ply)
	for k, v in pairs(getGamePlayers()) do
		if(v == nil) then break end
		sendMess("Player ("..v:Nick()..") has "..getPoints(v).." points.", ply)
	end
end

function deleteStats(ply)
	for k, v in pairs(getGamePlayers()) do
		if(ply == v) then
			table.remove(points, k)
		end
	end
	table.RemoveByValue(gamePlayers, ply)
	table.RemoveByValue(dead, ply)
	table.RemoveByValue(spectators, ply)
end

function pushPlayer(pusher, pushed)
	local power = 1
	for k, v in pairs(ultraPush) do
		if(v == pusher) then power = 10 end
	end
	pushed:SetVelocity(Vector(pusher:GetAimVector().x,pusher:GetAimVector().y,0)*pushMultiplier*power)
end

function playSound(cesta)
	net.Start("Sound")
		net.WriteString(cesta)
	net.Broadcast()
end

function playSoundPly(cesta, ply)
	net.Start("Sound")
		net.WriteString(cesta)
	net.Send(ply)
end

function setRoundReminder(delayR)
	reminder = RealTime() + delayR
end

function givePowerup(ply)
	local r = math.random(1,2)
	if(r == 1) then
		sendScrMess("pu-100", ply)
		addPoints(ply, 100)
	elseif(r == 2) then
		sendScrMess("pu-power", ply)
		table.insert(ultraPush, ply)
	end
end

function resetPowerups()
	ultraPush = {}
end