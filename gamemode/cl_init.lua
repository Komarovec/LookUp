-- Main scripts
include("shared.lua")

--Vars
local count = 1 -- Pocitani zprav pro enterovani.
local points = 0
local timerTime = "0"
local text = ""
local curRound = "0"
font = "CloseCaption_Normal"

-- UI Odpocet + PointCounter
local Shape = vgui.Create("DShape")
local screenRatio = ScrW()/ScrH();
if(screenRatio < 1.8 && screenRatio > 1.7) then
	widthIndex = ScrW()/1920
	heightIndex = ScrH()/1080
else
	widthIndex = 1
	heightIndex = 1
end
Shape:SetType("Rect")
Shape:SetPos(ScrW()/2 - (50*widthIndex), -(20*heightIndex))
Shape:SetSize(100*widthIndex,80*heightIndex)
Shape.Paint = function(s, w ,h)
	draw.RoundedBox(20*widthIndex, 0, 0, w, h, Color(255, 255, 255, 128))
	Shape:SetPos(ScrW()/2 - (50*widthIndex), -(20*heightIndex))
	font = "CloseCaption_Normal"
	if(widthIndex >= 1.5 || heightIndex >= 1.5) then font = "DermaLarge" end
	if(widthIndex < 0.9 || heightIndex < 0.9) then font = "Trebuchet18" end
	draw.SimpleTextOutlined(timerTime, font, 50*widthIndex, 62*heightIndex, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
	draw.SimpleTextOutlined(tostring(points), font, 50*widthIndex, 32*heightIndex, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
end

-- UI ScreenMess
local textFrame = vgui.Create("DShape")
textFrame:SetVisible(false)
textFrame:SetSize(ScrW(),ScrH())
textFrame:SetPos(0,0)
textFrame.Paint = function(s, w, h)
	draw.SimpleTextOutlined(text, "DermaLarge", ScrW()/2, 100*heightIndex, Color(60, 60, 60, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, Color(255, 255, 255,255))
end

-- WaveIcons
local WaveIcon = vgui.Create("DSprite")
local sizeBG = 150
local sizeIcon = 2/3*sizeBG
local offset = 25
WaveIconSprite = "vgui/wait.png"
WaveIcon:SetMaterial(Material(WaveIconSprite))
WaveIcon:SetColor( Color( 255, 255, 255 ) )
WaveIcon:SetPos(ScrW()-((sizeBG/2)*widthIndex)-(offset*widthIndex),((sizeBG/2)*heightIndex)+(offset*heightIndex))
WaveIcon:SetSize(sizeIcon*widthIndex,sizeIcon*heightIndex)
WaveIcon:SetZPos(10)

-- WaveIconBackGround
local WaveIconBG = vgui.Create("DShape")
WaveIconBG:SetType("Rect")
WaveIconBG:SetPos((ScrW()-sizeBG*widthIndex)-(offset*widthIndex),offset*heightIndex)
WaveIconBG:SetSize(sizeBG*widthIndex,sizeBG*heightIndex)
WaveIconBG:SetZPos(1)
WaveIconBG.Paint = function(s, w ,h)
	draw.RoundedBox(sizeBG*widthIndex, 0, 0, w, h, Color(255, 255, 255, 128))
end

-- RoundCounterBG
local RoundCounter = vgui.Create("DShape")
local RCw = 125
local RCh = 50
RoundCounter:SetType("Rect")
RoundCounter:SetPos(ScrW()-(((sizeBG/2)+offset)*widthIndex)-(RCw/2)*widthIndex,((sizeBG+offset)*heightIndex)+offset*heightIndex)
RoundCounter:SetSize(RCw*widthIndex,RCh*heightIndex)
RoundCounter:SetZPos(-1)
RoundCounter.Paint = function(s, w ,h)
	draw.RoundedBox(20*widthIndex, 0, 0, w, h, Color(255, 255, 255, 128))	
	draw.SimpleTextOutlined("Round: "..curRound.."/10", font, (RCw/2)*widthIndex, (RCh/2)*heightIndex, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
end

net.Receive("Points", function()
	points = net.ReadInt(16)
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
	textFrame:SetVisible(true)
	timer.Simple( 3, function()
		textFrame:SetVisible(false)
	end)
end)

net.Receive("ScreenTextWinner", function()
	text = net.ReadString()
	textFrame:SetVisible(true)
	timer.Simple( 4, function()
		textFrame:SetVisible(false)
	end)
end)

net.Receive("Sound", function()
	local soundPath = net.ReadString()
	surface.PlaySound(soundPath)
end)

net.Receive("Timer", function()
	local timerTimePure
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
	local curWave = net.ReadString()
	WaveIconSprite = "vgui/"..curWave..".png"
	WaveIcon:SetMaterial(Material(WaveIconSprite))
end)

net.Receive("RoundChange", function()
	curRound = net.ReadString()
end)

local rendered = false