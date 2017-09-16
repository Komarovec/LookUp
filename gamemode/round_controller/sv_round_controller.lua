-- Settings
roundTime = 60
roundCooldown = 15

-- Vars
local round_status = -1 -- 0 = pozastaveno , 1 = aktivní, -1 = neběži
local roundTimer = 0
local timerA = false
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
util.AddNetworkString("Points")
util.AddNetworkString("Timer")

-- Hooks
hook.Add("Think", "TimeDelay", function()
	if(RealTime() < roundTimer || timerA == false) then return end
		timerA = false
		if(round_status == 1) then
			endRound()
		else
			beginRound()
		end
 end)

hook.Add("Think", "updateTimer", function()
	if(getRoundStatus() == -1) then 
		updateTimer(0)
		return
	end
	updateTimer(math.Round(-(RealTime() - roundTimer)))
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
	Round()
end

function Round()
	roundTimer = RealTime() + roundTime
	timerA = true
	difficulty = difficulty + 1
	initializeProps(difficulty)
	playSound("ding.mp3")
	broadcastScrMess("Props are falling from the sky! Round: "..difficulty..", Spawning "..getMaxProps().." props each wave!")
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
	if(difficulty >= 10) then
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
			broadcastScrMess("Starting in "..roundCooldown.." seconds!") 
			roundTimer = RealTime() + roundCooldown
			timerA = true
		else
			broadcastScrWinner(winner:Nick().." has won the game with "..getPoints(winner).." points!")
			playSoundPly("winner.mp3", winner)
			round_status = -1
			setRoundReminder(10)
			timerA = false
			roundTimer = 0
			resetPoints()
			spawnQueue()
		end
		return
	else
		broadcastScrMess("Round has ended! New round in "..roundCooldown.." seconds.")
		roundTimer = RealTime() + roundCooldown
		timerA = true
	end
end

function getRoundStatus()
	return round_status
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
			net.Start("Points")
				net.WriteInt(getPoints(ply), 16)
			net.Send(ply)
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
	net.Start("Points")
			net.WriteInt(0, 16)
	net.Broadcast()
end

function forceEnd()
	broadcastScrMess("--- FORCING END OF THE GAME ---")
	round_status = -1
	deleteProps()
	respawnSpectators()
	timerA = false
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

function updateTimer(time)
	net.Start("Timer")
		net.WriteInt(time, 16)
	net.Broadcast()
end