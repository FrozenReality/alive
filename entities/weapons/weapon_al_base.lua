if SERVER then
 
   -- Add download file
   AddCSLuaFile()

   -- Weapon information
   SWEP.AutoSwitchTo = false
   SWEP.AutoSwitchFrom = false
 
elseif CLIENT then
 
   -- Weapon information
   SWEP.PrintName = "Base"
   SWEP.Slot = 1
   SWEP.SlotPos = 1
   SWEP.DrawAmmo = false
   SWEP.DrawCrosshair = true
   SWEP.ViewModelFlip = true
   SWEP.CSMuzzleFlashes = true
end

-- Weapon information
SWEP.Author = 'Fishcake'
SWEP.Weight = 1

-- Primary fire information
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Primary.Damage = 1
SWEP.Primary.Recoil = 0
SWEP.Primary.Cone = 0
SWEP.Primary.Delay = 0

SWEP.Primary.Sound = Sound("Weapon_Pistol.Empty")
SWEP.Primary.SoundEmpty = Sound("Weapon_Pistol.Empty")
SWEP.Primary.SoundLevel = 140

-- Secondary fire information
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.PrimaryAnim = ACT_VM_PRIMARYATTACK
SWEP.ReloadAnim = ACT_VM_RELOAD

-- Function runs when weapon is deployed
function SWEP:Deploy()

   -- Run animation
   self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
   
   -- Slow down animation by 0.2
   self:SetPlaybackRate(0.8)
end

-- Function run when weapon is fired with left click
function SWEP:PrimaryAttack(worldsnd)

   --  Set weapon next fire time
   self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

   -- Make sure we have the ammo to fire...
   if not self:CanPrimaryAttack() then return end

   if not worldsnd then
      -- Play client sound
      self:EmitSound(self.Primary.Sound, self.Primary.SoundLevel)
   elseif SERVER then
      -- Play server sound
      sound.Play(self.Primary.Sound, self:GetPos(), self.Primary.SoundLevel)
   end

   -- Accuracy based on crouching
   local calculatedCone = ternary((self.Owner:Crouching() and self.Primary.ConeCrouch), self.Primary.ConeCrouch, self.Primary.Cone)

   -- Shoot a bullet
   self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, calculatedConee)

   -- Take 1 from primary ammo
   self:TakePrimaryAmmo(1)

   local owner = self.Owner
   if not IsValid(owner) or owner:IsNPC() or (not owner.ViewPunch) then return end

end

function SWEP:SecondaryAttack(worldsnd)
end

-- Function to fire a bullet
function SWEP:ShootBullet(damage, recoil, count, cone)

   -- Send fire animation
   self:SendWeaponAnim(self.PrimaryAnim)

   -- Player animations
   self.Owner:MuzzleFlash()
   self.Owner:SetAnimation( PLAYER_ATTACK1 )

   if not IsFirstTimePredicted() then return end

   -- Arg defaults
   count = count or 1
   cone = cone   or 0.01

   -- Bullet definition 
   local bullet = {}
   bullet.Num = count
   bullet.Src = self.Owner:GetShootPos()
   bullet.Dir = self.Owner:GetAimVector()
   bullet.Spread = Vector(cone, cone, 0)
   bullet.Tracer = 4
   bullet.TracerName = self.Tracer or "Tracer"
   bullet.Force  = 10
   bullet.Damage = damage

   -- Fire bullets from weapon
   self.Owner:FireBullets(bullet)

   -- Owner can die after firebullets
   if (not IsValid(self.Owner)) or (not self.Owner:Alive()) or self.Owner:IsNPC() then return end

   -- If this is the client and fist time predicted
   if CLIENT and IsFirstTimePredicted() then

      -- Get owner eye angles and pitch them slighly for recoil
      local eyeang = self.Owner:EyeAngles()
      eyeang.pitch = eyeang.pitch - recoil
      self.Owner:SetEyeAngles( eyeang )
   end

end


function SWEP:CanPrimaryAttack()
   -- If the owner isnt valid, perhaps dead?
   if not IsValid(self.Owner) then return end

   -- Check clip size
   if self:Clip1() <= 0 then

      -- If client, emit dry fire sound
      if CLIENT and LocalPlayer() == self.Owner then
         self:EmitSound(self.Primary.SoundEmpty)
      end

      -- User not allowed to primary fire
      return false
   end

   -- User can primary fire
   return true
end

-- Ternary
function ternary(condition, if_true, if_false)
  if condition then return if_true else return if_false end
end