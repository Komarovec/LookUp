local mat = Material( "models/effects/comball_sphere", "noclamp smooth" )
local originPoint = nil
local minsVector = nil
local maxsVector = nil

--Rendering hook
hook.Add("PreDrawOpaqueRenderables", "Box", function()
	if(originPoint != nil and minsVector != nil and maxsvector != nil) then
		render.SetMaterial(mat)
		conDebugVector(originPoint, "Origin Point")
		conDebugVector(minsVector, "Mins")
		conDebugVector(maxsVector, "Maxs")
		--render.DrawBox(Vector(0,0,-10000), Angle(0,0,0), Vector(-1000,-1000,-1000), Vector(1000,1000,1000))
		render.DrawBox(originPoint, Angle(0,0,0), minsVector, maxsVector)
	end
end)

--Net
net.Receive("originPoint", function()
	print("Recieved originPoint")
    originPoint = net.ReadVector()
end)

net.Receive("minsVector", function()
	print("Recieved mins")
    minsVector = net.ReadVector()
end)

net.Receive("maxsVector", function()
	print("Recieved maxs")
    maxsVector = net.ReadVector()
end)

--Functions
function conDebugVector(vector, name)
	print("Vector "..name.."("..vector.x..","..vector.y..","..vector.z..")")
end