-- Settings
roundTime = 60
roundCooldown = 15

-- Vars
local round_status = -1 -- 0 = pozastaveno , 1 = aktivni, -1 = nebìži
local roundTimer = 0
local timer = false
local Rand = 0
local difficulty = 0
local maxPoints = -10000
local winner
local sameScores = {}
local PlayersForWin = {}
local overTimePlayers = {}
local overTime = false
local insertWinner
local willDie = false 
local noReward
points = {}

-- Network Att
util.AddNetworkString("UpdateRoundStatus")

-- Hooks
hook.Add("Think", "TimeDelay", function()
	if(RealTime() < roundTimer || timer == false) then return end
		timer = false
		if(round_status == 1) then
			endRound()
		else
			beginRound()
		end
 end)

-- Functions
function beginRound()
	round_status = 1
	for k, v in pairs(getGamePlayers()) do
		v:SetHealth(100)
	end
	if(difficulty < 10) then overTime = false end
	if(overTime == true) then
		for k, v in pairs(getGamePlayers()) do
			willDie = true
			for k1, v1 in pairs(overTimePlayers) do
				if(v == v1) then
					willDie = false
				end
			end
			if(willDie == true) then v:Kill() end
		end
	end
	updateClientRoundStatus()
	Round()
end

function Round()
	roundTimer = RealTime() + roundTime
	timer = true
	difficulty = difficulty + 1
	initializeProps(difficulty)
	broadcastMess("Props are falling from the sky! Round: "..difficulty..", Spawning "..getMaxProps().." props each wave!")
end

function endRound()
	round_status = 0
	for k, v in pairs(getGamePlayers()) do
		noReward = false
		for k1, v1 in pairs(getDeadPlayers()) do
			if(v == v1) then noReward = true end
		end
		if(noReward == false) then addPoints(v, 100) end
	end
	deleteProps()
	respawnSpectators()
	updateClientRoundStatus()
	if(difficulty >= 10) then
		broadcastMess("The game has ended!")
		maxPoints = -10000
		insertWinner = true
		sameScores = {}
		PlayersForWin = {}
		if(overTime == true) then
			PlayersForWin = overTimePlayers
			overTimePlayers = {}
		else
			PlayersForWin = getGamePlayers()
		end
		for k, v in pairs(PlayersForWin) do
			if(getPoints(v) == maxPoints) then
				table.insert(sameScores, v)
				for k1, v1 in pairs(sameScores) do
					if(winner == v1) then 
						insertWinner = false 
					end
				end
				if(insertWinner == true) then table.insert(sameScores, winner) end
			elseif(getPoints(v) > maxPoints) then
				sameScores = {}
				insertWinner = true
				winner = v
				maxPoints = getPoints(v)
			end
		end
		if(table.Count(sameScores) > 0) then
			overTime = true
			broadcastMess("Overtime round! Players:")
			for k, v in pairs(sameScores) do
				broadcastMess(v:Nick())
				table.insert(overTimePlayers, v)
			end
			broadcastMess("Starting in "..roundCooldown.." seconds!")
			roundTimer = RealTime() + roundCooldown
			timer = true
		else 
			broadcastMess(winner:Nick().." has won the game with "..getPoints(winner).." points!") 
			round_status = -1
			updateClientRoundStatus()
			timer = false
			roundTimer = 0
			resetPoints()
			spawnQueue()
		end
		return
	else
		broadcastMess("Round has ended! New round in "..roundCooldown.." seconds.")
		roundTimer = RealTime() + roundCooldown
		timer = true
	end
end

function getRoundStatus()
	return round_status
end

function updateClientRoundStatus()
	net.Start("UpdateRoundStatus")
		net.WriteInt(round_status, 4)
	net.Broadcast()
end

function setDifficulty(diff)
	difficulty = diff
end

function initializePoints()
	resetPoints()
	for k, v in pairs(getGamePlayers()) do
		table.insert(points, k, 0)
	end
end

function addPoints(ply, ps)
	if(table.Count(points) != table.Count(getGamePlayers())) then
		broadcastMess("Inconsistency in points table detected! / !forceEnd / recommeded!")
	end
	psPlus = ps + getPoints(ply)
	for k, v in pairs(getGamePlayers()) do
		if(ply == v) then
			points[k]=psPlus 
			sendMess("You have earned "..ps.." points! Now you have "..getPoints(ply).." points!", ply)
		end
	end
end

function getPoints(ply)
	for k, v in pairs(getGamePlayers()) do
		if(ply == v) then
			for k1, v1 in pairs(points) do
				if(k == k1) then
					return v1	
				end
			end
		end
	end
end
	
function resetPoints()
	points = {}
end

function forceEnd()
	broadcastMess("--- FORCING END OF THE GAME ---")
	round_status = -1
	deleteProps()
	respawnSpectators()
	updateClientRoundStatus()
	timer = false
	roundTimer = 0
	resetPoints()
	spawnQueue()
end

function printPoints(ply)
	sendMess("--- Printing points table:",ply)
	for k, v in pairs(points) do
		sendMess(k.." "..v, ply)
	end
end