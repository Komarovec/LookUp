AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include('shared.lua')
 
function ENT:Initialize()
 
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
 
    local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:OnTakeDamage(data)
    if(!data:GetAttacker():IsPlayer()) then return end
    givePowerup(data:GetAttacker())
    self:EmitSound( "ambient/explosions/explode_" .. math.random( 1, 9 ) .. ".wav" )
    self:Remove()
end

function ENT:OnRemove()
    local vPoint = self:GetPos()
    local effectdata = EffectData()
    effectdata:SetOrigin( vPoint )
    util.Effect( "Explosion", effectdata )
end