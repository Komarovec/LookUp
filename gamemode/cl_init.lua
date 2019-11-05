-- Main scripts
include("shared.lua")

--Vars
local count = 1 -- Pocitani zprav pro enterovani.
local points = 0
local timerTime = "0"
local timerTimePure = 0
local text = ""
local curRound = "0"
local curWave = "normal"
local propsFalling = "0"
local isNot = false
local notQueue = {}

-- Game Tables
pointTable = {}
gamePlayers = {}
spectators = {}

--Aplhacanal pro notifikace
local alpha = 0
local alphaBG = 0

font = "CloseCaption_Normal"

-- Screen Scaling
local screenRatio = ScrW()/ScrH();
if(screenRatio < 1.8 && screenRatio > 1.7) then
	widthIndex = ScrW()/1920
	heightIndex = ScrH()/1080
else
	widthIndex = 1
	heightIndex = 1
end

-- Fonts
surface.CreateFont( "InfoFont", {
	font = "DermaLarge",
	extended = true,
	size = 21*widthIndex,
	weight = 250*widthIndex,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = true,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

surface.CreateFont( "MessFont", {
	font = "CloseCaption_Bold",
	extended = true,
	size = 40*widthIndex,
	weight = 250*widthIndex,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = true,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
})

Ifont = "InfoFont"
Mfont = "MessFont"

-- UI Odpocet + PointCounter
WhiteBoxColor = Color(220, 220, 220,220)

local Shape = vgui.Create("DShape")
Shape:SetType("Rect")
Shape:SetPos(ScrW()/2 - (50*widthIndex), -(20*heightIndex))
Shape:SetSize(100*widthIndex,80*heightIndex)
Shape.Paint = function(s, w ,h)
	if(timerTimePure < 6) then timerColor = Color(160,0,0,255)
	else timerColor = Color(100,100,100,255) end
	draw.RoundedBox(20*widthIndex, 0, 0, w, h, WhiteBoxColor)
	Shape:SetPos(ScrW()/2 - (50*widthIndex), -(20*heightIndex))
	draw.SimpleTextOutlined(timerTime, Ifont, 50*widthIndex, 62*heightIndex, timerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, timerColor)
	draw.SimpleTextOutlined(tostring(points), Ifont, 50*widthIndex, 32*heightIndex, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
end

-- WaveIcons
local WaveIcon = vgui.Create("DSprite")
local sizeBG = 150
local sizeCBG = 120
local sizeIcon = 2/3*sizeBG
local offset = 25
WaveIconSprite = "vgui/wait.png"
WaveIcon:SetMaterial(Material(WaveIconSprite))
WaveIcon:SetColor( Color( 255, 255, 255 ) )
WaveIcon:SetPos(ScrW()-((sizeBG/2)*widthIndex)-(offset*widthIndex),((sizeBG/2)*heightIndex)+(offset*heightIndex))
WaveIcon:SetSize(sizeIcon*widthIndex,sizeIcon*heightIndex)
WaveIcon:SetZPos(10)

-- WaveIconBackGround
hook.Add( "HUDPaint", "WaveIcon", function()
	if(curWave == "explosive") then waveBGColor = Color(255,0,0,180)
	elseif(curWave == "vending") then waveBGColor = Color(0,0,255,180)
	elseif(curWave == "cargo") then waveBGColor = Color(255,128,0,180)
	else waveBGColor = Color(255,255,255,200) end
	-- WhiteBG
	draw.RoundedBox(sizeBG*widthIndex, ScrW()-((sizeBG+offset)*widthIndex), offset*heightIndex, sizeBG*widthIndex, sizeBG*heightIndex, waveBGColor)
	-- ColoredBG
	draw.RoundedBox(sizeCBG*widthIndex, ScrW()-((sizeCBG/2+sizeBG/2+offset)*widthIndex), (offset+(sizeBG-sizeCBG)/2)*heightIndex, sizeCBG*widthIndex, sizeCBG*heightIndex, WhiteBoxColor)
end)

-- RoundAndProp Counter
local RoundCounter = vgui.Create("DShape")
local RCw = 125
local RCh = 75
RoundCounter:SetType("Rect")
RoundCounter:SetPos(ScrW()-(((sizeBG/2)+offset)*widthIndex)-(RCw/2)*widthIndex,((sizeBG+offset)*heightIndex)+offset*heightIndex)
RoundCounter:SetSize(RCw*widthIndex,RCh*heightIndex)
RoundCounter:SetZPos(-1)
RoundCounter.Paint = function(s, w ,h)
	draw.RoundedBox(20*widthIndex, 0, 0, w, h, WhiteBoxColor)	

	-- RoundCounter
	if(tonumber(curRound) > 10) then
		draw.SimpleTextOutlined("OT Round: "..tostring((tonumber(curRound)-10)), Ifont, (RCw/2)*widthIndex, (RCh/3)*heightIndex, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
	else
		draw.SimpleTextOutlined("Round: "..curRound.."/10", Ifont, (RCw/2)*widthIndex, (RCh/3)*heightIndex, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
	end

	-- PropCounter
	if(tonumber(propsFalling) < 40) then propColor = Color(0,100,0,220)
	elseif(tonumber(propsFalling) < 70) then propColor = Color(190,100,0,255)
	else propColor = Color(160,0,0,255) end
	draw.SimpleTextOutlined("Props: "..propsFalling, Ifont, (RCw/2)*widthIndex, (RCh*(2/3))*heightIndex, propColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
end

-- Scoreboard
scoreboard = {}

function scoreboard:show()
	--Create the scoreboard here, with an base like DPanel, you can use an DListView for the rows.
	getTables()
	local scorePanel = vgui.Create( "DPanel" )
	scorePanel:SetSize( 600*widthIndex, 500*heightIndex)
	scorePanel:Center()


	local plyList = vgui.Create( "DListView", scorePanel)
	plyList:Dock( FILL )
	plyList:SetMultiSelect( false )
	plyList:AddColumn( "Player" )
	plyList:AddColumn( "Points" )
	plyList:AddColumn( "Rank" )

	if(pointTable[1] == nil) then
		for k,v in pairs(player.GetAll()) do
			plyList:AddLine( v:Nick(), "0", "#1")	
		end
	else
		local change = false;
		local pom, pomPly;
		repeat
			max = 0
			change = false
			for k,v in pairs(pointTable) do
				if(v < max) then
					pom = v
					pointTable[k] = max
					pointTable[k-1] = pom

					pomPly = gamePlayers[k]
					gamePlayers[k] = gamePlayers[k-1]
					gamePlayers[k-1] = pomPly
					change = true
				else
					max = v
				end
			end
		until(!change)

		for k,v in pairs(table.Reverse(gamePlayers)) do
			plyList:AddLine( v:Nick(), table.Reverse(pointTable)[k], "#"..k)
		end
	end

	scorePanel:SetVisible(true)

	function scoreboard:hide()
		scorePanel:SetVisible(false)
	end
end

function GM:ScoreboardShow()
	scoreboard:show()
end

function GM:ScoreboardHide()
	scoreboard:hide()
end

-- Funkce
function notify(txt)
	if(isNot) then
		if(table.Count(notQueue) > 2) then notQueue = {} end
		table.insert(notQueue, 1, txt)
	else
		isNot = true

		surface.SetFont(Mfont)
		local wText, hText = surface.GetTextSize(txt)

		-- Zobrazeni notifikace 
		hook.Add( "HUDPaint", "Notification", function()
			-- Smooth fade in-out
			if(isNot && alpha < 255) then
				alpha = alpha + 2000*FrameTime()
			elseif(!isNot && alpha > 0) then
				alpha = alpha - 2000*FrameTime()
			end

			if(isNot && alphaBG < 200) then
				alphaBG = alphaBG + 2000*FrameTime()
			elseif(!isNot && alphaBG > 0) then
				alphaBG = alphaBG - 2000*FrameTime()
			end

			local boxColor = Color(60,60,60,alphaBG)
			local textColor = Color(220,220,220,alpha)
			local textOutColor = Color(100, 100, 100,alpha)
			local boxW = wText+15*widthIndex
			local boxH = hText+10*heightIndex
			draw.RoundedBox(10*heightIndex, ScrW()/2-boxW/2, 100*heightIndex, boxW, boxH, boxColor)
			draw.SimpleTextOutlined(txt, Mfont, ScrW()/2, 100*heightIndex+boxH/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, textOutColor)
		end)

		-- 1 Sekunda mezera pro zmizení
		timer.Simple(3, function()
			isNot = false;
		end)

		timer.Simple(4, function()
			if(notQueue[1] != nil) then
				notify(notQueue[1])
				table.remove(notQueue,1)
			end
		end)

	end
end

function getTables()
	net.Start("tables")
		net.WriteString("all")
	net.SendToServer()
end

-- Nets
net.Receive("Points", function()
	points = net.ReadInt(16)
end)

net.Receive("PointTable", function()
	pointTable = net.ReadTable()
end)

net.Receive("GameplayersTable", function()
	gamePlayers = net.ReadTable()
end)

net.Receive("SpectatorsTable", function()
	spectators = net.ReadTable()
end)

net.Receive("ChatText", function()
	mess = net.ReadString()
	chat.AddText(mess)
end)

net.Receive("ScreenText", function()
	text = net.ReadString()
	if(text == "pu-100") then
		text = "+100 POINTS"
	elseif(text == "pu-power") then
		text = "ULTRAPUNCH"
	end

	notify(text)
end)

net.Receive("ScreenTextWinner", function()
	text = net.ReadString()
	notify(text)
end)

net.Receive("Sound", function()
	local soundPath = net.ReadString()
	surface.PlaySound(soundPath)
end)

net.Receive("Timer", function()
	timerTimePure = net.ReadInt(16)
	if(timerTimePure >= 60) then
		timerTime = "1:00"
	elseif(timerTimePure >= 10) then
		timerTime = "0:"..tostring(timerTimePure)
	else
		timerTime = "0:0"..tostring(timerTimePure)
	end
end)

net.Receive("WaveType", function()
	curWave = net.ReadString()
	WaveIconSprite = "vgui/"..curWave..".png"
	WaveIcon:SetMaterial(Material(WaveIconSprite))
end)

net.Receive("RoundChange", function()
	curRound = net.ReadString()
	if(curRound == "0") then propsFalling = "0" end
end)

net.Receive("PropChange", function()
	propsFalling = net.ReadString()
end)