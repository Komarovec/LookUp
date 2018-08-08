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

net.Receive("ReloadAll", function()
	local weapon = net.ReadString()
	ply:Give(weapon, false)
end)

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
			sendMess(k.." "..v:Nick(), ply)
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
			for k1, v1 in pairs(queue) do
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
	if(table.Count(player.GetAll()) == table.Count(dead) && getRoundStatus() == 1) then
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
		if(ply == v) then return end
	end
	for k, v in pairs(queue) do
		if(ply == v) then return end
	end
	for k, v in pairs(dead) do
		if(ply == v) then return end
	end
	table.insert(dead, ply)
	timer.Simple(3, function()  
        ply:Spawn()  
    end) 
end)

-- Functions
function GM:PlayerConnect(name, ip)
	broadcastMess(name.." has connected to the server!")
end

function GM:PlayerDisconnected(ply)
	deleteStats(ply)
	broadcastMess(ply:Nick().." has left the server." )
end

function GM:PlayerSpawn(ply)
	spawnNormal = false
	if(getRoundStatus() >= 0) then
		for k, v in pairs(gamePlayers) do
			if(ply == v) then spawnNormal = true end
		end
	end

	self.BaseClass:PlayerSpawn(ply)
	ply:SetModel("models/player/Police.mdl") -- player model

	if(getRoundStatus() >= 0 && spawnNormal == false) then
		ply:Spectate(6)
		for k, v in pairs(queue) do
			if(ply == v) then return end
		end
		broadcastMess(ply:Nick().." has been added to the queue!")
		table.insert(queue, ply)

	elseif(getRoundStatus() == 1 && spawnNormal == true) then 
		ply:Spectate(6)
		for k, v in pairs(spectators) do
			if(ply == v) then return end
		end
		broadcastMess(ply:Nick().." has been added to spectators!")
		table.insert(spectators, ply)

	elseif(getRoundStatus() == 0 || getRoundStatus() == -1) then 
		table.RemoveByValue(dead, ply)
		table.RemoveByValue(spectators, ply)
		table.RemoveByValue(queue, ply)
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

function sendMess(mess, ply)
	net.Start("ChatText")
		net.WriteString(mess)
	net.Send(ply)
end

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

function spawnQueue()
	respawn = {}
	for k, v in pairs(getQueue()) do
		table.insert(respawn, v)
	end
	for k, v in pairs(respawn) do
		v:UnSpectate()
		v:Spawn()
	end
	respawn = {}
	queue = {}
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
	table.RemoveByValue(gamePlayers, v)
	table.RemoveByValue(points, v)
	table.RemoveByValue(dead, v)
	table.RemoveByValue(spectators, v)
	table.RemoveByValue(queue, v)
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