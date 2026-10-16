local AfflictionLoader = NTCS.AfflictionsLoader("NTCS Eyes")
local AfflictionBuilder = NTCS.AfflictionPrefabBuilder()

-- Pressure Damage calculation
local function PressureDamageCalculation(character, pressureDamageValue)
	-- if the character is not enabled, return 0 (fixes load time pressure eye damage issues)
	if not character.Enabled then
		return 0
	end

	-- this may be redundant, not a big deal tho
	local pressureDamage = pressureDamageValue

	-- check if there is a pressureDamage value, if not set it 0
	if pressureDamage == nil then
		pressureDamage = 0
	end

	-- return the damage value
	return (
		(character.InWater and character.InPressure and not (character.IsProtectedFromPressure or character.IsImmuneToPressure))
		and pressureDamage
	) or 0
end

-- Remove eye upon death on passive check
local function PassiveEyeRemoval(C, Identifier, Limb, biological)
	local character = C.Human
	local strength = C:GetAfflictionStrength(Identifier)

	--check if damage is above 80 and if there are 2 eyes
	if
		strength >= 80
		and (
			not (C:GetAfflictionStrength("mc_deadeye") > 0)
			and not (C:GetAfflictionStrength("sr_removedeye") > 0)
			and not (C:GetAfflictionStrength("mc_mismatch") >= 1)
		)
	then
		--at a chance every tick, remove the eye
		local removalChance = (strength / 800) --for mercy, every tick has a damage/8 (10% at 80 damage) chance to remove the eye
		if NTCS.HF.Chance(removalChance) then
			--remove the dead eye's damage from total eye health
			C:SetAffliction(Identifier, strength - 50)

			--biological eyes get dead eye, non-biological ones get removedeye
			--this is important for retinopathy checks
			if biological then
				NTCS.HF.SetAfflictionLimb(character, "mc_deadeye", Limb, 100)
			else
				NTCS.HF.SetAfflictionLimb(character, "sr_removedeye", Limb, 100)
			end
		end
	elseif --check the status of the other eye if only 1 of the same type can be found
		(strength >= 45)
		and (
			(C:GetAfflictionStrength("mc_deadeye") >= 1)
			or (C:GetAfflictionStrength("sr_removedeye") >= 1)
			or (C:GetAfflictionStrength("mc_mismatch") >= 1) --character may have 2 eyes of different types
		)
	then
		local removalChance = (strength / 800) --for mercy (again), every tick has a damage/10 (4.5% at 45 damage) chance to remove the eye
		if NTCS.HF.Chance(removalChance) then
			--remove the eye damage
			C:SetAffliction(Identifier, 0)
			--check for the eye again, then remove it
			local base = Identifier:match("^dm_(.+)$")
			if base then
				NTCS.HF.SetAfflictionLimb(character, "vi_" .. base, Limb, 0)
				NTCS.HF.SetAfflictionLimb(character, "dm_" .. base, Limb, 0)
			end
			--remove the mismatch if there is one
			if C:GetAfflictionStrength("mc_mismatch") >= 1 then
				--if there is a mismatch, remove only the damaged eye and leave the other as is
				local base = Identifier:match("^dm_(.+)$")
				if base then
					NTCS.HF.SetAfflictionLimb(character, "vi_" .. base, Limb, 0)
					NTCS.HF.SetAfflictionLimb(character, "dm_" .. base, Limb, 0)
				end
				--dead or removed eye depending on if it is biological
				if biological then
					NTCS.HF.SetAfflictionLimb(character, "mc_deadeye", Limb, 100)
				else
					NTCS.HF.SetAfflictionLimb(character, "sr_removedeye", Limb, 100)
				end
				NTCS.HF.SetAfflictionLimb(character, "mc_mismatch", Limb, 0)
			else --if no mismatch, kill the remaining eye
				NTCS_Eyes.NukeEyeAfflictions(character)
				--dead or removed eye depending on if it is biological
				if biological then
					NTCS.HF.SetAfflictionLimb(character, "mc_deadeyes", Limb, 100)
				else
					NTCS.HF.SetAfflictionLimb(character, "sr_removedeyes", Limb, 100)
				end
			end
		end
	else
		--I do not remember what this does (could be something important, too lazy to check rn, too afraid to delete)
		--I am adding these comments 3 months after writing the inital code lmao
		C:SetAffliction(Identifier, NTCS.HF.Clamp(strength, 0, 100))
	end
end

-- Add cataracts if applicable
local function CauseCataracts(C, Identifier, Limb)
	local character = C.Human
	local strength = C:GetAfflictionStrength(Identifier)

	--check if damage is above 60 and if there are 2 eyes
	if
		strength >= 60
		and (
			not (C:GetAfflictionStrength("mc_deadeye") > 0)
			and not (C:GetAfflictionStrength("sr_removedeye") > 0)
			and not (C:GetAfflictionStrength("mc_mismatch") >= 1)
		)
	then
		--get cataractChance from config
		local cataractChance = 0.03 * NTCS.Config.Get("NTEYE_cataractChanceMultiplier", 1) -- 0.03% chance to cause cataracts on default
		if NTCS.HF.Chance(cataractChance) then
			if NTCS_Eyes.HasEyes(character) then
				NTCS.HF.AddAfflictionLimb(character, "mc_cataract", Limb, 1)
			end
		end
	elseif --check the status of the other eye if only 1 of the same type can be found
		(strength >= 30)
		and (
			(C:GetAfflictionStrength("mc_deadeye") >= 1)
			or (C:GetAfflictionStrength("sr_removedeye") >= 1)
			or (C:GetAfflictionStrength("mc_mismatch") >= 1) --character may have 2 eyes of different types
		)
	then
		--get cataractChance from config
		local cataractChance = 0.06 * NTCS.Config.Get("NTEYE_cataractChanceMultiplier", 1)
		if NTCS.HF.Chance(cataractChance) then
			if NTCS_Eyes.HasEyes(character) then
				NTCS.HF.AddAfflictionLimb(character, "mc_cataract", Limb, 1)
			end
		end
	end
end

local function CauseParasites(C, Identifier, Limb)
	local character = C.Human
	local strength = C:GetAfflictionStrength(Identifier)

	--check if damage is above 60 and if there are 2 eyes
	if
		strength >= 60
		and (
			not (C:GetAfflictionStrength("mc_deadeye") > 0)
			and not (C:GetAfflictionStrength("sr_removedeye") > 0)
			and not (C:GetAfflictionStrength("mc_mismatch") >= 1)
		)
	then
		--at a chance every tick, cause parasites
		local parasiteChance = (strength / 600)
		if NTCS.HF.Chance(parasiteChance) then
			if NTCS_Eyes.HasEyes(character) then
				NTCS.HF.AddAfflictionLimb(character, "hud_parasite1", Limb, 100)
			end
		end
	elseif --check the status of the other eye if only 1 of the same type can be found
		(strength >= 30)
		and (
			(C:GetAfflictionStrength("mc_deadeye") >= 1)
			or (C:GetAfflictionStrength("sr_removedeye") >= 1)
			or (C:GetAfflictionStrength("mc_mismatch") >= 1) --character may have 2 eyes of different types
		)
	then
		--at a chance every tick, cause parasites
		local parasiteChance = (strength / 600)
		if NTCS.HF.Chance(parasiteChance) then
			if NTCS_Eyes.HasEyes(character) then
				NTCS.HF.AddAfflictionLimb(character, "hud_parasite1", Limb, 100)
			end
		end
	end
end

local function SetEyeIndicatorStrength(C, Identifier)
	local character = C.Human
	--check if held lid is present, if so make affliction visible if it is already present
	if C:GetAfflictionStrength(Identifier) > 0 then
		if NTCS.HF.HasAffliction(character, "sr_heldlid") then
			if
				NTCS.HF.HasAffliction(character, "sr_removedeye")
				or NTCS.HF.HasAffliction(character, "mc_deadeye")
				or NTCS.HF.HasAffliction(character, "mc_mismatch")
			then
				--one eye is this type
				C:SetAffliction(Identifier, 1)
			else
				--two eyes are this type
				C:SetAffliction(Identifier, 2)
			end
		else
			--hide eye type
			C:SetAffliction(Identifier, 0.5)
		end
	end
end

local function SetEyeAfflictionStrength(C, Identifier, maxStrength)
	--check if held lid is present, if so make affliction visible if it is already present
	if C:GetAfflictionStrength(Identifier) > 0 then
		if NTCS.HF.HasAffliction(C.Human, "sr_heldlid") then
			--show affliction
			C:SetAffliction(Identifier, maxStrength)
		else
			--hide affliction
			C:SetAffliction(Identifier, 0.5)
		end
	end
end

-- Afflictions with no update logic
local UpdateLessBehaviour = {
	"sr_heldlid",
	"sr_poppedeye",
	"sr_eyeconnector",
	"sr_corneaincision",
	"sr_emulsification",
	"mc_correctives",
	"mc_pinkeye",
}

for _, Id in ipairs(UpdateLessBehaviour) do
	AfflictionLoader:Register(AfflictionBuilder:New(Id):Build())
end

-- Removed Eyes
local RemovedEyes = AfflictionBuilder:New("sr_removedeyes"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	SetEyeAfflictionStrength(C, Identifier, 2)
end):Build()

AfflictionLoader:Register(RemovedEyes)

-- Removed Eye
local RemovedEye = AfflictionBuilder:New("sr_removedeye"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	SetEyeAfflictionStrength(C, Identifier, 1)
end):Build()

AfflictionLoader:Register(RemovedEye)

-- Eye damage types that eyedrops / laser surgery can heal (only organics!).
local EyeDamageNames = {
	"human",
	"enhanced",
	"crawler",
	"mudraptor",
	"hammerhead",
	"watcher",
	"husk",
	"latcher",
	"terror",
}

-- No need to repeat the same function twice
local function HealEyeDamage(C, Rate, DeltaT)
	-- If in stasis, end early
	if C:GetBoolStat("stasis") then return end

	for _, Name in ipairs(EyeDamageNames) do
		if C:GetAfflictionStrength("vi_" .. Name) > 0 then
			local DamageId = "dm_" .. Name
			local Current = C:GetAfflictionStrength(DamageId)

			if Current > 0 then
				C:SetAffliction(DamageId, math.max(0, Current - Rate * DeltaT))
			end
		end
	end
end

-- Eye Drops
-- Increases eye health
local EyeDrops = AfflictionBuilder:New("sr_eyedrops"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

	if C:GetAfflictionStrength(Identifier) <= 0 then return end

	HealEyeDamage(C, 0.015, DeltaT)

end):Build()

AfflictionLoader:Register(EyeDrops)

-- Laser Eye Surgery
-- Increases eye health more
local LaserSurgery = AfflictionBuilder:New("sr_lasersurgery"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

	if C:GetAfflictionStrength(Identifier) <= 0 then return end

	HealEyeDamage(C, 0.05, DeltaT)

end):Build()

AfflictionLoader:Register(LaserSurgery)

-- Dead Eyes
local DeadEyes = AfflictionBuilder:New("mc_deadeyes"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	SetEyeAfflictionStrength(C, Identifier, 2)
end):Build()

AfflictionLoader:Register(DeadEyes)

-- Dead Eye
--causes retinopathy at a chance
local DeadEye = AfflictionBuilder:New("mc_deadeye"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	local character = C.Human
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--give retinopathy if it is enabled and there is a dead eye
	if C:GetAfflictionStrength(Identifier) > 0 and not NTCS.Config.Get("NTEYE_disableRetinopathy", false) then
		if NTCS.HF.Chance(0.007) then -- 0.7% chance to cause retinopathy
			NTCS.HF.AddAfflictionLimb(character, "mc_retinopathy", LimbType.Head, 1)
		end
	end
	SetEyeAfflictionStrength(C, Identifier, 1)
	if NTCS.HF.HasAffliction(character, "mc_deadeyes") or NTCS.HF.HasAffliction(character, "sr_removedeyes") then
		C:SetAffliction(Identifier, 0)
	end
end):Build()

AfflictionLoader:Register(DeadEye)

-- Retinopathy
local Retinopathy = AfflictionBuilder:New("mc_retinopathy"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	if C:GetAfflictionStrength(Identifier) <= 0 then return end
	--remove retinopathy if immunity is below 10%
	if C:GetAfflictionStrength("immunity") < 11 then
		C:SetAffliction(Identifier, 0)
	end
end):Build()

AfflictionLoader:Register(Retinopathy)

-- Cataracts
-- triggers vision debuffs upon having cataracts
local Cataract = AfflictionBuilder:New("mc_cataract"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--give blurred vision symptom
	if C:GetAfflictionStrength(Identifier) >= 60 then
		C:SetSymptomTrue("blurredvision", 10)
	end
end):Build()

AfflictionLoader:Register(Cataract)

-- Vision Sickness
-- used for blur after surgery
local VisionSickness = AfflictionBuilder:New("mc_visionsickness"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	if C:GetAfflictionStrength(Identifier) >= 20 then
		C:SetSymptomTrue("confusion", 10)
	end
	if C:GetAfflictionStrength(Identifier) >= 50 then
		C:SetSymptomTrue("headache", 10)
	end
end):Build()

AfflictionLoader:Register(VisionSickness)

-- Mismatch
-- used when character has incompatible eyes
local Mismatch = AfflictionBuilder:New("mc_mismatch"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end
	if C:GetAfflictionStrength(Identifier) <= 0 then return end
	--glasses prevent the negative effects of mismatch
	if C:GetAfflictionStrength("mc_correctives") > 0 then return end

	C:SetSymptomTrue("headache", 10)
	if NTCS.HF.Chance(0.1) then
		C:SetSymptomTrue("nausea", 10)
	end

	SetEyeAfflictionStrength(C, Identifier, 2)
end):Build()

AfflictionLoader:Register(Mismatch)

-- Human Eye Damage
local DmHuman = AfflictionBuilder:New("dm_human"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	local character = C.Human

	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_human") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--variable declaration for gain
	--divided by; higher value, less damage
	local hypoxemiaResistance = 200
	local strokeResistance = 0.1
	local sepsisResistance = 0.4
	local retinopathyResistance = 10
	--set by; lower value, less damage
	local pressureDamage = 3 * NTCS.Config.Get("NTEYE_pressureDamageMultiplier", 1)

	local regenRate = -0.1 --inverse for passive healing
	--set if the eye is biological or not
	local biological = true
	--set the config multiplier
	local configMultiplier = NTCS.Config.Get("NTEYE_eyeDamageMultiplier", 1)

	--sets biological damage gain for eyes (can be negative or positive)
	local gain = (
		regenRate * C:GetFloatStat("healingrate") -- passive regen
		+ C:GetAfflictionStrength("hypoxemia") / hypoxemiaResistance -- from hypoxemia
		+ NTCS.HF.Clamp(C:GetAfflictionStrength("stroke"), 0, 20) * strokeResistance -- from stroke
		+ C:GetAfflictionStrength("sepsis") / 100 * sepsisResistance -- from sepsis
		+ C:GetAfflictionStrength("mc_retinopathy") / retinopathyResistance --from retinopathy
		+ PressureDamageCalculation(character, pressureDamage) -- from pressure
	) * DeltaT

	if gain > 0 then
		gain = gain * configMultiplier -- Config multiplier
	end
	C:SetAffliction(Identifier, C:GetAfflictionStrength(Identifier) + gain)

	--function to cause cataracts
	CauseCataracts(C, Identifier, LimbType.Head)
	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)
end):Build()

AfflictionLoader:Register(DmHuman)

-- Cybernetic Eye Damage
local DmCyber = AfflictionBuilder:New("dm_cyber"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_cyber") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--set if the eye is biological or not
	local biological = false
	--cyber eyes won't receive biological damage

	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)

	--cause parasites on screen if damage is too high
	CauseParasites(C, Identifier, LimbType.Head)
end):Build()

AfflictionLoader:Register(DmCyber)

-- Enhanced Eye Damage
local DmEnhanced = AfflictionBuilder:New("dm_enhanced"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	local character = C.Human

	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_enhanced") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--variable declaration for gain
	--divided by; higher value, less damage
	local hypoxemiaResistance = 250
	local strokeResistance = 0.08
	local sepsisResistance = 0.3
	--set by; lower value, less damage
	local pressureDamage = 2.5 * NTCS.Config.Get("NTEYE_pressureDamageMultiplier", 1)
	local regenRate = -0.1 --inverse for passive healing
	--set if the eye is biological or not
	local biological = true
	--set the config multiplier
	local configMultiplier = NTCS.Config.Get("NTEYE_eyeDamageMultiplier", 1)
	--sets biological damage gain for eyes (can be negative or positive)
	local gain = (
		regenRate * C:GetFloatStat("healingrate") -- passive regen
		+ C:GetAfflictionStrength("hypoxemia") / hypoxemiaResistance -- from hypoxemia
		+ NTCS.HF.Clamp(C:GetAfflictionStrength("stroke"), 0, 20) * strokeResistance -- from stroke
		+ C:GetAfflictionStrength("sepsis") / 100 * sepsisResistance -- from sepsis
		+ PressureDamageCalculation(character, pressureDamage) -- from pressure
	) * DeltaT

	if gain > 0 then
		gain = gain * configMultiplier -- Config multiplier
	end
	C:SetAffliction(Identifier, C:GetAfflictionStrength(Identifier) + gain)

	--function to cause cataracts
	CauseCataracts(C, Identifier, LimbType.Head)
	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)
end):Build()

AfflictionLoader:Register(DmEnhanced)

-- Plastic Eye Damage
local DmPlastic = AfflictionBuilder:New("dm_plastic"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_plastic") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--set if the eye is biological or not
	local biological = false
	--plastic eyes won't receive biological damage

	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)
end):Build()

AfflictionLoader:Register(DmPlastic)

-- Crawler Eye Damage
local DmCrawler = AfflictionBuilder:New("dm_crawler"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	local character = C.Human

	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_crawler") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--variable declaration for gain
	--divided by; higher value, less damage
	local hypoxemiaResistance = 100
	local strokeResistance = 0.1
	local sepsisResistance = 0.4
	--set by; lower value, less damage
	local pressureDamage = 0
	local regenRate = -0.1 --inverse for passive healing
	--set if the eye is biological or not
	local biological = true
	--set the config multiplier
	local configMultiplier = NTCS.Config.Get("NTEYE_eyeDamageMultiplier", 1)
	--sets biological damage gain for eyes (can be negative or positive)
	local gain = (
		regenRate * C:GetFloatStat("healingrate") -- passive regen
		+ C:GetAfflictionStrength("hypoxemia") / hypoxemiaResistance -- from hypoxemia
		+ NTCS.HF.Clamp(C:GetAfflictionStrength("stroke"), 0, 20) * strokeResistance -- from stroke
		+ C:GetAfflictionStrength("sepsis") / 100 * sepsisResistance -- from sepsis
		+ PressureDamageCalculation(character, pressureDamage) -- from pressure
	) * DeltaT

	if gain > 0 then
		gain = gain * configMultiplier -- Config multiplier
	end
	C:SetAffliction(Identifier, C:GetAfflictionStrength(Identifier) + gain)

	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)
end):Build()

AfflictionLoader:Register(DmCrawler)

-- Mudraptor Eye Damage
local DmMudraptor = AfflictionBuilder:New("dm_mudraptor"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	local character = C.Human

	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_mudraptor") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--variable declaration for gain
	--divided by; higher value, less damage
	local hypoxemiaResistance = 100
	local strokeResistance = 0.1
	local sepsisResistance = 0.4
	--set by; lower value, less damage
	local pressureDamage = 0
	local regenRate = -0.1 --inverse for passive healing
	--set if the eye is biological or not
	local biological = true
	--set the config multiplier
	local configMultiplier = NTCS.Config.Get("NTEYE_eyeDamageMultiplier", 1)
	--sets biological damage gain for eyes (can be negative or positive)
	local gain = (
		regenRate * C:GetFloatStat("healingrate") -- passive regen
		+ C:GetAfflictionStrength("hypoxemia") / hypoxemiaResistance -- from hypoxemia
		+ NTCS.HF.Clamp(C:GetAfflictionStrength("stroke"), 0, 20) * strokeResistance -- from stroke
		+ C:GetAfflictionStrength("sepsis") / 100 * sepsisResistance -- from sepsis
		+ PressureDamageCalculation(character, pressureDamage) -- from pressure
	) * DeltaT

	if gain > 0 then
		gain = gain * configMultiplier -- Config multiplier
	end
	C:SetAffliction(Identifier, C:GetAfflictionStrength(Identifier) + gain)

	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)
end):Build()

AfflictionLoader:Register(DmMudraptor)

-- Hammerhead Eye Damage
local DmHammerhead = AfflictionBuilder:New("dm_hammerhead"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	local character = C.Human

	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_hammerhead") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--variable declaration for gain
	--divided by; higher value, less damage
	local hypoxemiaResistance = 100
	local strokeResistance = 0.1
	local sepsisResistance = 0.4
	--set by; lower value, less damage
	local pressureDamage = 0
	local regenRate = -0.1 --inverse for passive healing
	--set if the eye is biological or not
	local biological = true
	--set the config multiplier
	local configMultiplier = NTCS.Config.Get("NTEYE_eyeDamageMultiplier", 1)
	--sets biological damage gain for eyes (can be negative or positive)
	local gain = (
		regenRate * C:GetFloatStat("healingrate") -- passive regen
		+ C:GetAfflictionStrength("hypoxemia") / hypoxemiaResistance -- from hypoxemia
		+ NTCS.HF.Clamp(C:GetAfflictionStrength("stroke"), 0, 20) * strokeResistance -- from stroke
		+ C:GetAfflictionStrength("sepsis") / 100 * sepsisResistance -- from sepsis
		+ PressureDamageCalculation(character, pressureDamage) -- from pressure
	) * DeltaT

	if gain > 0 then
		gain = gain * configMultiplier
	end
	C:SetAffliction(Identifier, C:GetAfflictionStrength(Identifier) + gain)

	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)
end):Build()

AfflictionLoader:Register(DmHammerhead)

-- Watcher Eye Damage
local DmWatcher = AfflictionBuilder:New("dm_watcher"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	local character = C.Human

	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_watcher") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--variable declaration for gain
	--divided by; higher value, less damage
	local hypoxemiaResistance = 100
	local strokeResistance = 0.1
	local sepsisResistance = 0.4
	--set by; lower value, less damage
	local pressureDamage = 0
	local regenRate = -0.1 --inverse for passive healing
	--set if the eye is biological or not
	local biological = true
	--set the config multiplier
	local configMultiplier = NTCS.Config.Get("NTEYE_eyeDamageMultiplier", 1)
	--sets biological damage gain for eyes (can be negative or positive)
	local gain = (
		regenRate * C:GetFloatStat("healingrate") -- passive regen
		+ C:GetAfflictionStrength("hypoxemia") / hypoxemiaResistance -- from hypoxemia
		+ NTCS.HF.Clamp(C:GetAfflictionStrength("stroke"), 0, 20) * strokeResistance -- from stroke
		+ C:GetAfflictionStrength("sepsis") / 100 * sepsisResistance -- from sepsis
		+ PressureDamageCalculation(character, pressureDamage) -- from pressure
	) * DeltaT -- original multiplied by configMultiplier here by mistake

	if gain > 0 then
		gain = gain * configMultiplier -- Config multiplier
	end
	C:SetAffliction(Identifier, C:GetAfflictionStrength(Identifier) + gain)

	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)
end):Build()

AfflictionLoader:Register(DmWatcher)

-- Husk Eye Damage
local DmHusk = AfflictionBuilder:New("dm_husk"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	local character = C.Human

	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_husk") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--variable declaration for gain
	--divided by; higher value, less damage
	local hypoxemiaResistance = 1000
	local strokeResistance = 0.03
	local sepsisResistance = 0.03
	--set by; lower value, less damage
	local pressureDamage = 0
	local regenRate = -0.2 --inverse for passive healing
	--set if the eye is biological or not
	local biological = true
	--set the config multiplier
	local configMultiplier = NTCS.Config.Get("NTEYE_eyeDamageMultiplier", 1)
	--sets biological damage gain for eyes (can be negative or positive)
	local gain = (
		regenRate * C:GetFloatStat("healingrate") -- passive regen
		+ C:GetAfflictionStrength("hypoxemia") / hypoxemiaResistance -- from hypoxemia
		+ NTCS.HF.Clamp(C:GetAfflictionStrength("stroke"), 0, 20) * strokeResistance -- from stroke
		+ C:GetAfflictionStrength("sepsis") / 100 * sepsisResistance -- from sepsis
		+ PressureDamageCalculation(character, pressureDamage) -- from pressure
	) * DeltaT

	if gain > 0 then
		gain = gain * configMultiplier -- Config multiplier
	end
	C:SetAffliction(Identifier, C:GetAfflictionStrength(Identifier) + gain)

	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)
end):Build()

AfflictionLoader:Register(DmHusk)

-- Latcher Eye Damage
local DmLatcher = AfflictionBuilder:New("dm_latcher"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	local character = C.Human

	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_latcher") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--variable declaration for gain
	--divided by; higher value, less damage
	local hypoxemiaResistance = 250
	local strokeResistance = 0.08
	local sepsisResistance = 0.2
	--set by; lower value, less damage
	local pressureDamage = 0
	local regenRate = -0.1 --inverse for passive healing
	--set if the eye is biological or not
	local biological = true
	--set the config multiplier
	local configMultiplier = NTCS.Config.Get("NTEYE_eyeDamageMultiplier", 1)
	--sets biological damage gain for eyes (can be negative or positive)
	local gain = (
		regenRate * C:GetFloatStat("healingrate") -- passive regen
		+ C:GetAfflictionStrength("hypoxemia") / hypoxemiaResistance -- from hypoxemia
		+ NTCS.HF.Clamp(C:GetAfflictionStrength("stroke"), 0, 20) * strokeResistance -- from stroke
		+ C:GetAfflictionStrength("sepsis") / 100 * sepsisResistance -- from sepsis
		+ PressureDamageCalculation(character, pressureDamage) -- from pressure
	) * DeltaT

	if gain > 0 then
		gain = gain * configMultiplier -- Config multiplier
	end
	C:SetAffliction(Identifier, C:GetAfflictionStrength(Identifier) + gain)

	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)
end):Build()

AfflictionLoader:Register(DmLatcher)

-- Terror Eye Damage
local DmTerror = AfflictionBuilder:New("dm_terror"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	--check if the correct eye type
	if not (C:GetAfflictionStrength("vi_terror") > 0) then return end
	-- Stasis Check
	if C:GetBoolStat("stasis") then return end

	--set if the eye is biological or not
	local biological = false --very cool lore reasons I promise
	--set the config multiplier
	local configMultiplier = NTCS.Config.Get("NTEYE_eyeDamageMultiplier", 1)

	--terror eyes do not receive biological damage and heal really fast
	local gain = (
		-0.3 * C:GetFloatStat("healingrate") -- passive regen
	) * DeltaT

	if gain > 0 then
		gain = gain * configMultiplier -- Config multiplier
	end
	C:SetAffliction(Identifier, C:GetAfflictionStrength(Identifier) + gain)

	--function to check for eye death
	PassiveEyeRemoval(C, Identifier, LimbType.Head, biological)
end):Build()

AfflictionLoader:Register(DmTerror)

-- Lens Afflictions
for _, Id in ipairs({ "lt_medical", "lt_electrical", "lt_night", "lt_thermal" }) do
	AfflictionLoader:Register(AfflictionBuilder:New(Id):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
		SetEyeAfflictionStrength(C, Identifier, 2)
	end):Build())
end

-- Human Eye Indicator
--add eye if no eye afflictions // works like the blood pressure from NT
local ViHuman = AfflictionBuilder:New("vi_human"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
	local character = C.Human
	local afflictionTags = {
		"vi_type",
		"eye_type",
		"eye_surgery",
		"eye_mechanic",
	}

	SetEyeIndicatorStrength(C, Identifier)

	--check if character has any eye afflictions
	for _, affliction in ipairs(afflictionTags) do
		if character.CharacterHealth.GetAfflictionOfType(affliction) ~= nil then
			return
		end
	end
	--if no eye afflictions, give default eye indicator (human)
	NTCS.HF.SetAfflictionLimb(character, "vi_human", LimbType.Head, 0.5)
end):Build()

AfflictionLoader:Register(ViHuman)

-- Register the Visual Indicator afflictions with nothing special
for _, Name in ipairs({
	"cyber",
	"enhanced",
	"plastic",
	"crawler",
	"mudraptor",
	"hammerhead",
	"watcher",
	"husk",
	"latcher",
	"terror",
}) do
	AfflictionLoader:Register(AfflictionBuilder:New("vi_" .. Name):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
		SetEyeIndicatorStrength(C, Identifier)
	end):Build())
end