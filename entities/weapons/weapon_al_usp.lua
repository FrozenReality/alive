if SERVER then
 
   -- Add download file
   AddCSLuaFile()

   -- Weapon information
   SWEP.AutoSwitchTo = false
   SWEP.AutoSwitchFrom = false
 
elseif CLIENT then
 
   -- Weapon information
   SWEP.PrintName = "USP"
   SWEP.Slot = 1
   SWEP.SlotPos = 1
   SWEP.DrawAmmo = false
   SWEP.DrawCrosshair = true
   SWEP.ViewModelFlip = true
   SWEP.CSMuzzleFlashes = true
end

SWEP.Base = "weapon_al_base"

-- Weapon information
SWEP.Author = 'Fishcake'
SWEP.Weight = 5

-- Primary fire information
SWEP.Primary.ClipSize = 15
SWEP.Primary.DefaultClip = 15
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"

SWEP.Primary.Damage = 10
SWEP.Primary.Recoil = 0.9
SWEP.Primary.Cone = 0.05
SWEP.Primary.ConeCrouch = 0.02
SWEP.Primary.Delay = 0.15

SWEP.Primary.Sound= Sound("Weapon_USP.Single")

SWEP.ViewModel = "models/weapons/v_pist_usp.mdl"
SWEP.WorldModel = "models/weapons/w_pist_usp.mdl"