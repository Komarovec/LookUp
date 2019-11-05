local mat = Material( "pyro_overloader/diffuse", "noclamp smooth" )
local originPoint = nil
local minsVector = nil
local maxsVector = nil
local setupMode = false

--Rendering hook
hook.Add("PreDrawOpaqueRenderables", "Box", function()
	if(originPoint != nil and minsVector != nil and maxsVector != nil and setupMode == true) then
		render.SetMaterial(mat)
		--[[conDebugVector(originPoint, "Origin Point")
		conDebugVector(minsVector, "Mins")
		conDebugVector(maxsVector, "Maxs")]]
		--render.DrawBox(Vector(0,0,-10000), Angle(0,0,0), Vector(-1000,-1000,-1000), Vector(1000,1000,1000))
		render.DrawBox(originPoint, Angle(0,0,0), minsVector, maxsVector)
	end
end)

--Net
net.Receive("originPoint", function()
	print("Recieved originPoint")
	originPoint = net.ReadVector()
	conDebugVector(originPoint, "Origin Point")
end)

net.Receive("minsVector", function()
	print("Recieved mins")
	minsVector = net.ReadVector()
	conDebugVector(minsVector, "Mins")
end)

net.Receive("maxsVector", function()
	print("Recieved maxs")
	maxsVector = net.ReadVector()
	conDebugVector(maxsVector, "Maxs")
end)

net.Receive("setupMode", function()
	print("Recieved setupMode")
	setupMode = net.ReadBool()
	if(setupMode) then
		print("Setup mode: true")
	else
		print("Setup mode: false")
	end
end)

--Functions
function conDebugVector(vector, name)
	print("Vector "..name.."("..vector.x..","..vector.y..","..vector.z..")")
end