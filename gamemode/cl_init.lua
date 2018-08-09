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
	extended = false,
	size = 20*widthIndex,
	weight = 250*widthIndex,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
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
local Shape = vgui.Create("DShape")
Shape:SetType("Rect")
Shape:SetPos(ScrW()/2 - (50*widthIndex), -(20*heightIndex))
Shape:SetSize(100*widthIndex,80*heightIndex)
Shape.Paint = function(s, w ,h)
	if(timerTimePure < 6) then timerColor = Color(200,0,0,255)
	else timerColor = Color(100,100,100,255) end
	draw.RoundedBox(20*widthIndex, 0, 0, w, h, Color(255, 255, 255,128))
	Shape:SetPos(ScrW()/2 - (50*widthIndex), -(20*heightIndex))
	draw.SimpleTextOutlined(timerTime, Ifont, 50*widthIndex, 62*heightIndex, timerColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, timerColor)
	draw.SimpleTextOutlined(tostring(points), Ifont, 50*widthIndex, 32*heightIndex, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
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
	if(curWave == "normal") then waveBGColor = Color(255, 255, 255, 128)
	elseif(curWave == "explosive") then waveBGColor = Color(255,0,0,128)
	elseif(curWave == "vending") then waveBGColor = Color(0,0,255,128)
	elseif(curWave == "cargo") then waveBGColor = Color(255,128,0,128)
	else waveBGColor = Color(255, 255, 255, 128) end
	draw.RoundedBox(sizeBG*widthIndex, 0, 0, w, h, waveBGColor)
end

-- RoundAndProp Counter
local RoundCounter = vgui.Create("DShape")
local RCw = 125
local RCh = 75
RoundCounter:SetType("Rect")
RoundCounter:SetPos(ScrW()-(((sizeBG/2)+offset)*widthIndex)-(RCw/2)*widthIndex,((sizeBG+offset)*heightIndex)+offset*heightIndex)
RoundCounter:SetSize(RCw*widthIndex,RCh*heightIndex)
RoundCounter:SetZPos(-1)
RoundCounter.Paint = function(s, w ,h)
	draw.RoundedBox(20*widthIndex, 0, 0, w, h, Color(255, 255, 255, 128))	

	-- RoundCounter
	if(tonumber(curRound) > 10) then
		draw.SimpleTextOutlined("OT Round: "..tostring((tonumber(curRound)-10)), Ifont, (RCw/2)*widthIndex, (RCh/3)*heightIndex, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
	else
		draw.SimpleTextOutlined("Round: "..curRound.."/10", Ifont, (RCw/2)*widthIndex, (RCh/3)*heightIndex, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
	end

	-- PropCounter
	if(tonumber(propsFalling) < 40) then propColor = Color(0,150,0,255)
	elseif(tonumber(propsFalling) < 70) then propColor = Color(255,150,0,255)
	else propColor = Color(200,0,0,255) end
	draw.SimpleTextOutlined("Props: "..propsFalling, Ifont, (RCw/2)*widthIndex, (RCh*(2/3))*heightIndex, propColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.1, Color(100, 100, 100,255))
end

-- Funkce
function notify(txt)
	if(isNot) then
		table.insert(notQueue, 1, txt)
	else
		isNot = true
		NotifyText = vgui.Create("DLabel", DNotify)
		NotifyText:Dock(FILL)
		NotifyText:SetPos(0,0)
		NotifyText:SetText(txt)
		NotifyText:SetFont(Mfont)
		NotifyText:SetColor(Color(200,200,200))
		NotifyText:Center()
		NotifyText:SetDark(false)

		surface.SetFont(Mfont)
		local wText, hText = surface.GetTextSize(txt)

		NotifyPanel = vgui.Create("DNotify")
		NotifyPanel:SetPos(ScrW()/2-(wText/2),100*heightIndex)
		NotifyPanel:SetSize(ScrW(),hText)
		NotifyPanel:SetLife(4)
		timer.Simple(4, function()
			isNot = false;
			if(notQueue[1] != nil) then
				notify(notQueue[1])
				table.remove(notQueue,1)
			end
		end)

		NotifyPanel:AddItem(NotifyText)
	end
end

-- Nets
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