-- Main scripts
include("shared.lua")

--Vars
local count = 1 -- Pocitani zprav pro enterovani.
local points = 0
local timerTime = "0"
local text = ""

local Shape = vgui.Create("DShape")
Shape:SetType("Rect")
Shape:SetPos(ScrW()/2 - 50, -20)
Shape:SetSize(100,80)
Shape.Paint = function(s, w ,h)
	draw.RoundedBox(20, 0, 0, w, h, Color(255, 255, 255))
	draw.SimpleTextOutlined(timerTime, "CloseCaption_Normal", 50, 62, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, Color(100, 100, 100,255))
	draw.SimpleTextOutlined(tostring(points), "CloseCaption_Normal", 50, 32, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, Color(100, 100, 100,255))
end

local textFrame = vgui.Create("DShape")
textFrame:SetVisible(false)
textFrame:SetSize(ScrW(),ScrH())
textFrame:SetPos(0,0)
textFrame.Paint = function(s, w, h)
	draw.SimpleTextOutlined(text, "CloseCaption_Bold", ScrW()/2, 100, Color(60, 60, 60, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, Color(255, 255, 255,255))
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