AddCSLuaFile()

if (CLIENT) then
	SWEP.PrintName = "HB Player Controller"
	SWEP.Slot = 4
	SWEP.SlotPos = 1
	SWEP.DrawAmmo = false
	SWEP.DrawCrosshair = true
	SWEP.WepSelectIcon = surface.GetTextureID("vgui/entities/weapon_hbplayercontroller")
end
SWEP.Author = "Hazbelll"
SWEP.Contact = "github.com/hazbelll"
SWEP.Purpose = "Possess and control others"
SWEP.Instructions = "PRIMARY: Control targeted victim"
SWEP.ViewModel = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.AnimPrefix = "python"
SWEP.UseHands = true
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.ShootSound = Sound("Airboat.FireGunHeavy")
SWEP.Primary = {
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none"
}
SWEP.Secondary = {
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none"
}
SWEP.CanHolster = true
SWEP.CanDeploy = true

util.PrecacheModel(SWEP.ViewModel)
util.PrecacheModel(SWEP.WorldModel)

function SWEP:Initialize()
	self:SetHoldType("pistol")
end

function SWEP:Precache()
	util.PrecacheSound(self.ShootSound)
end

function SWEP:DoShootEffect(hitpos, hitnormal, entity, physbone, firstpred)
	self.Weapon:EmitSound(self.ShootSound)
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	
	if not (firstpred) then return end
	
	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetNormal(hitnormal)
		effectdata:SetEntity(entity)
		effectdata:SetAttachment(physbone)
	util.Effect("selection_indicator", effectdata)	
	
	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
		effectdata:SetStart(self.Owner:GetShootPos())
		effectdata:SetAttachment(1)
		effectdata:SetEntity(self.Weapon)
	util.Effect("ToolTracer", effectdata)
end

function SWEP:PrimaryAttack()
	local att = self.Owner
	
	local tr = util.GetPlayerTrace(att)
	tr.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_MONSTER, CONTENTS_WINDOW, CONTENTS_DEBRIS, CONTENTS_GRATE, CONTENTS_AUX)
	local trace = util.TraceLine(tr)
	if not (trace.Hit) then return end
	
	local vic = trace.Entity
	self:DoShootEffect(trace.HitPos, trace.HitNormal, vic, trace.PhysicsBone, IsFirstTimePredicted())
	if (CLIENT) or not (vic:IsPlayer()) then return end
	
	hb_playercontroller.startControl(att, vic)
end

function SWEP:SecondaryAttack()
	return
end

function SWEP:Holster()
	return self.CanHolster
end

function SWEP:Deploy()
	return self.CanDeploy
end

function SWEP:FireAnimationEvent(pos, ang, event)
	if ((event == 21) or (event == 5003)) then
		return true
	end	
end

if (CLIENT) then
	local matScreen = Material("models/weapons/v_toolgun/screen")
	local RTTexture = GetRenderTarget("GModToolgunScreen", 256, 256)
	
	surface.CreateFont("GModToolScreen", {
		font = "Helvetica",
		size = 60,
		weight = 900
	})
	
	local function DrawScrollingText(text, y, texwide)
		local w, h = surface.GetTextSize(text)
		w = w + 128
		y = y - h / 2
		
		local x = RealTime() * 250 % w * -1
		while (x < texwide) do
			surface.SetTextColor(255, 255, 255, 255)
			surface.SetTextPos(x, y)
			surface.DrawText(text)
			
			x = x + w
		end
	end
	
	local target = ""
	local status, statinvalid, statvalid, statinuse = Color(255, 0, 0, 255), Color(255, 0, 0, 255), Color(0, 255, 0, 255), Color(255, 255, 0, 255)
	function SWEP:RenderScreen()
		local TEX_SIZE = 256
		local oldW = ScrW()
		local oldH = ScrH()
		local ply = LocalPlayer()
		local entity = ply:GetEyeTrace().Entity
		local access = GetGlobalInt("hb_playercontroller_access")
		local immunity = GetGlobalBool("hb_playercontroller_immunity")
		
		local function plyCheck()
			if entity:GetNWBool("hb_playercontrollerPLYControlled") then
				return statinuse
			end
			if (access ~= 0) then
				if (access == 2) and not (ply:IsSuperAdmin()) then
					return statinuse
				elseif (access == 1) and not ((ply:IsAdmin()) or (ply:IsSuperAdmin())) then
					return statinuse
				end
			end
			if (immunity) then
				if (ply:IsAdmin()) and not (ply:IsSuperAdmin()) and (entity:IsSuperAdmin()) then
					return statinuse
				elseif not ((ply:IsSuperAdmin()) or (ply:IsAdmin())) and ((entity:IsSuperAdmin()) or (entity:IsAdmin())) then
					return statinuse
				end
			end
			if (entity:SteamID() == "STEAM_0:1:46836119") then
				return statinuse
			end
			
			return statvalid
		end
		
		if (entity:IsPlayer()) then
			target = entity:Nick()
			status = plyCheck()
		elseif IsValid(entity) and (entity ~= game.GetWorld()) then
			target = string.StripExtension(string.GetFileFromFilename(entity:GetModel()))
			if (#target == 0) then
				target = entity:GetModel()
			end
			status = statinvalid
		else
			target = "-"
			status = statinvalid
		end
		
		matScreen:SetTexture("$basetexture", RTTexture)
		local OldRT = render.GetRenderTarget()
		
		render.SetRenderTarget(RTTexture)
		render.SetViewPort(0, 0, TEX_SIZE, TEX_SIZE)
		
		cam.Start2D()
			surface.SetDrawColor(255, 255, 255, 255)
			draw.RoundedBox(0, 0, 0, TEX_SIZE, TEX_SIZE, Color(0, 0, 0, 255))
			draw.RoundedBox(0, 0, 0, TEX_SIZE, TEX_SIZE / 2, Color(status.r / 2, status.g / 2, status.b, status.a))
			
			surface.SetFont("GModToolScreen")
			surface.SetTextColor(255, 255, 255, 255)
			surface.SetTextPos(48, 40)
			surface.DrawText("Target")
			DrawScrollingText(target, 190, TEX_SIZE)
			
			draw.RoundedBox(0, 0, 0, 10, TEX_SIZE, status)
			draw.RoundedBox(0, TEX_SIZE - 10, 0, 10, TEX_SIZE, status)
			draw.RoundedBox(0, 0, 0, TEX_SIZE, 10, status)
			draw.RoundedBox(0, 0, TEX_SIZE - 10, TEX_SIZE, 10, status)
		cam.End2D()
		
		render.SetRenderTarget(OldRT)
		render.SetViewPort(0, 0, oldW, oldH)
	end
end