-- Main scripts
include("shared.lua")

-- Other scripts
include("round_controller/cl_round_controller.lua")

--Vars
local count = 1 -- Pocitani zprav pro enterovani.
local points = 0

local Shape = vgui.Create("DShape")
Shape:SetType("Rect")
Shape:SetPos(ScrW()/2 - 50, -20)
Shape:SetSize(100,50)
Shape.Paint = function(s, w ,h)
	draw.RoundedBox(20, 0, 0, w, h, Color(255, 255, 255))
	draw.SimpleTextOutlined(tostring(points), "CloseCaption_Normal", 50, 32, Color(100, 100, 100, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, Color(100, 100, 100,255))
end

-- Network Att
net.Receive("OpenWeaponry", function()
	local frame = vgui.Create("DFrame")
	frame:SetSize(300, 600)
	frame:SetVisible(true)
	frame:Center()
	frame:SetTitle("Choose your weapon:")
	frame:MakePopup()

	local b_357 = vgui.Create("DButton",frame)
	b_357:SetText("357 Magnum")
	b_357:SetSize(250, 30)
	b_357:SetPos(25, 50)

	local b_smg = vgui.Create("DButton",frame)
	b_smg:SetText("SMG")
	b_smg:SetSize(250, 30)
	b_smg:SetPos(25, 80)

	local b_ar2 = vgui.Create("DButton",frame)
	b_ar2:SetText("AR2")
	b_ar2:SetSize(250, 30)
	b_ar2:SetPos(25, 110)

	local b_crowbar = vgui.Create("DButton",frame)
	b_crowbar:SetText("CROWBAR")
	b_crowbar:SetSize(250, 30)
	b_crowbar:SetPos(25, 140)

	b_357.DoClick = function()
		frame:Close()
		net.Start("GiveWeapon")
			net.WriteString("weapon_357")
		net.SendToServer()
	end

	b_smg.DoClick = function()
		frame:Close()
		net.Start("GiveWeapon")
			net.WriteString("weapon_smg1")
		net.SendToServer()
	end

	b_ar2.DoClick = function()
		frame:Close()
		net.Start("GiveWeapon")
			net.WriteString("weapon_ar2")
		net.SendToServer()
	end

	b_crowbar.DoClick = function()
		frame:Close()
		net.Start("GiveWeapon")
			net.WriteString("weapon_crowbar")
		net.SendToServer()
	end
end)

net.Receive("Points", function()
	points = net.ReadInt(16)
end)

net.Receive("ChatText", function()
	mess = net.ReadString()
	chat.AddText(mess)
end)

net.Receive("ScreenText", function()
	local text = net.ReadString()
	local textFrame = vgui.Create("DShape")
	textFrame:SetVisible(true)
	textFrame:SetSize(ScrW(),ScrH())
	textFrame:SetPos(0,0)
	textFrame.Paint = function(s, w, h)
		draw.SimpleTextOutlined(text, "CloseCaption_Bold", ScrW()/2, 100, Color(60, 60, 60, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 0.5, Color(255, 255, 255,255))
	end
	timer.Simple( 3, function()
		textFrame:SetVisible(false)
		wait = false
	end)
end)