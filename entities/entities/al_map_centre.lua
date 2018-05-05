if SERVER then
 
   -- Add download file
   AddCSLuaFile()

end

ENT.Type = "point"
ENT.Base = "base_point"

function ENT:Initialize()
end

function ENT:KeyValue( key, value )
	-- Store the start and end vars
	if key == "start" then
		self.startDistance = value
	end
	if key == "end" then
		self.endDistance = value
	end
end