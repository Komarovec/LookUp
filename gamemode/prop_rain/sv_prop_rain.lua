-- Settings
hardnessMultiplier = 1
propsSpawnpoint = Vector(31, -9, -12287) -- Depens on map, working only on flatgrass!
WaveTime = 5

-- Vars
local Props = {}
local SpawningProps = false
local WaveTimer = false
local WaveTimeFinal = 0
local Rand = 0
local spawnedProps = 0
local maxSpawned = 0
local funWave = 0

-- Hooks
hook.Add("Think", "PropSpawnTimer", function()
	if(spawnedProps >= maxSpawned || SpawningProps == false) then return end
	spawnProps()
end)

hook.Add("Think", "NextWaveTimer", function()
	if(RealTime() < WaveTimeFinal || SpawningProps == false) then return end
	for k, v in pairs(ents.FindByClass("prop_physics")) do
		v:Remove()
	end
	funWave = 0
	if(math.random(1,5) == 5) then
		funWave = math.random(1,3)
		if(funWave == 1) then broadcastMess("Vending wave!")
		elseif(funWave == 2) then broadcastMess("Explosive wave!")
		elseif(funWave == 3) then broadcastMess("Cargo wave!") end
	end
	WaveTimeFinal = RealTime() + WaveTime
	spawnedProps = 0
end)

-- Functions
function initializeProps(diff)
	spawnedProps = 0
	Props = {}
	if(hardnessMultiplier > 2 || hardnessMultiplier < 0.1) then
		print("Incorrect hardness settings! 1 or 2 !! Using default..")
		hardnessMultiplier = 1
	end
	if(diff < 1) then
		maxSpawned = 15 * hardnessMultiplier
		setDifficulty(1)
	elseif(diff == 1) then
		maxSpawned = 15 * hardnessMultiplier
	elseif(diff == 2) then
		maxSpawned = 20 * hardnessMultiplier
	elseif(diff == 3) then
		maxSpawned = 30 * hardnessMultiplier
	elseif(diff == 4) then
		maxSpawned = 40 * hardnessMultiplier
	elseif(diff == 5) then
		maxSpawned = 50 * hardnessMultiplier
	elseif(diff == 6) then
		maxSpawned = 60 * hardnessMultiplier
	elseif(diff == 7) then
		maxSpawned = 70 * hardnessMultiplier
	elseif(diff == 8) then
		maxSpawned = 80 * hardnessMultiplier
	elseif(diff == 9) then
		maxSpawned = 90 * hardnessMultiplier
	elseif(diff == 10) then
		maxSpawned = 100 * hardnessMultiplier
	elseif(diff > 10) then
		maxSpawned = 100 * hardnessMultiplier
	end
	funWave = 0
	WaveTimeFinal = RealTime() + WaveTime
	SpawningProps = true
end

function spawnProps()
	spawnProp(propsSpawnpoint + Vector(math.Rand(-1000,1000), math.Rand(-1000,1000), 2000))
	spawnedProps = spawnedProps + 1
end

function spawnProp(pos)	
	barrel=ents.Create("prop_physics")
	if(funWave == 0) then
		Rand = math.random(1,15)
		if(Rand == 1) then barrel:SetModel("models/props_c17/furnitureStove001a.mdl")
			elseif(Rand == 2) then barrel:SetModel("models/props_c17/oildrum001.mdl")
			elseif(Rand == 3) then barrel:SetModel("models/props_c17/display_cooler01a.mdl")
			elseif(Rand == 4) then barrel:SetModel("models/props_interiors/VendingMachineSoda01a.mdl")
			elseif(Rand == 5) then barrel:SetModel("models/props_c17/FurnitureFridge001a.mdl")
			elseif(Rand == 6) then barrel:SetModel("models/props_c17/FurnitureWashingmachine001a.mdl")
			elseif(Rand == 7) then barrel:SetModel("models/props_junk/TrashBin01a.mdl")
			elseif(Rand == 8) then barrel:SetModel("models/props_c17/FurnitureCouch001a.mdl")
			elseif(Rand == 9) then barrel:SetModel("models/props_interiors/BathTub01a.mdl")
			elseif(Rand == 10) then barrel:SetModel("models/props_lab/monitor02.mdl") 
			elseif(Rand == 11) then barrel:SetModel("models/props_junk/TrashDumpster01a.mdl") 
			elseif(Rand == 12) then 
				barrel:SetModel("models/props_c17/oildrum001_explosive.mdl")
				if(math.random(1,2) == 2) then barrel:Ignite(20) end
			elseif(Rand == 13) then barrel:SetModel("models/props_wasteland/kitchen_counter001c.mdl") 
			elseif(Rand == 14) then barrel:SetModel("models/props_junk/CinderBlock01a.mdl") 
			elseif(Rand == 15) then barrel:SetModel("models/props_wasteland/wheel03b.mdl") 
		end
	elseif(funWave == 1) then barrel:SetModel("models/props_interiors/VendingMachineSoda01a.mdl")
	elseif(funWave == 2) then 
		barrel:SetModel("models/props_c17/oildrum001_explosive.mdl") 
		barrel:Ignite(20)
	elseif(funWave == 3) then barrel:SetModel("models/props_wasteland/cargo_container01.mdl") end
	barrel:SetPos(pos)
	barrel:SetAngles(Angle(math.Rand(0,360),math.Rand(0,360),math.Rand(0,360)))
	barrel:Spawn()
end

function deleteProps()
	SpawningProps = false
	for k, v in pairs(ents.FindByClass("prop_physics")) do
		v:Remove()
	end
end

function changeDifficulty(difficulty)
	hardnessMultiplier = difficulty
end

function getMaxProps()
	return maxSpawned
end