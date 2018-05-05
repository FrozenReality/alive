if SERVER then
 
   -- Add download file
   AddCSLuaFile()

end

ENT.Type = "entity"
ENT.Base = "base_entity"

function ENT:Initialize()
 
 	if SERVER then
		self:SetModel( "models/props_interiors/BathTub01a.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )      -- Make us work with physics,
		self:SetMoveType( MOVETYPE_VPHYSICS )   -- after all, gmod is a physics
		self:SetSolid( SOLID_VPHYSICS )         -- Toolbox
	 
	        local phys = self:GetPhysicsObject()
		if (phys:IsValid()) then
			phys:Wake()
		end
	end
end
