local itemLoader = NTCS.ItemFunctionLoader("NTCS_Cybernetics")

NTCS_Cybernetics.OrganConfigDatas = {
	kidney = {
		limb = LimbType.Torso,
		damageAffliction = "kidneydamage",
		removedAffliction = "kidneyremoved",
		swapAffliction = "kidneyswap",
		cyberAffliction = "ntc_cyberkidney",
		secondarySkillName = "mechanical",
		surgerySkillRemoval = 30,
		curedAfflictions = {},
		tier2Item = "augmentedkidney",
		tier3Item = "cyberkidney",
	},
	liver = {
		limb = LimbType.Torso,
		damageAffliction = "liverdamage",
		removedAffliction = "liverremoved",
		swapAffliction = "liverswap",
		cyberAffliction = "ntc_cyberliver",
		secondarySkillName = "mechanical",
		surgerySkillRemoval = 40,
		curedAfflictions = {},
		tier2Item = "augmentedliver",
		tier3Item = "cyberliver",
	},
	lung = {
		limb = LimbType.Torso,
		damageAffliction = "lungdamage",
		removedAffliction = "lungremoved",
		empAffliction = "incrementalstun",
		swapAffliction = "lungswap",
		cyberAffliction = "ntc_cyberlung",
		secondarySkillName = "mechanical",
		surgerySkillRemoval = 50,
		curedAfflictions = { "pneumothorax", "needlec", "respiratoryarrest", "hyperventilation", "hypoventilation" },
		tier2Item = "augmentedlung",
		tier3Item = "cyberlung",
	},
	heart = {
		limb = LimbType.Torso,
		damageAffliction = "heartdamage",
		removedAffliction = "heartremoved",
		swapAffliction = "heartswap",
		cyberAffliction = "ntc_cyberheart",
		secondarySkillName = "mechanical",
		surgerySkillRemoval = 60,
		curedAfflictions = {
			"tamponade",
			"heartattack",
			"cardiacarrest",
			"fibrillation",
			"tachycardia",
			"t_arterialcut",
		},
		tier2Item = "augmentedheart",
		tier3Item = "cyberheart",
	},
	brain = {
		limb = LimbType.Head,
		damageAffliction = nil,
		removedAffliction = nil,
		empAffliction = "incrementalstun",
		cyberAffliction = "ntc_cyberbrain",
		secondarySkillName = "electrical",
		surgerySkillRemoval = 70,
		curedAfflictions = {},
		tier2Item = "augmentedbrain",
		tier3Item = "cyberbrain",
	},
}

local function damageOrgan(targetCharacter, organName, damage, usingCharacter)
	if organName == "brain" then
		HF.AddAffliction(targetCharacter, "cerebralhypoxia", damage, usingCharacter)
	else
		HF.AddAffliction(targetCharacter, organName .. "damage", damage, usingCharacter) -- eg. "liverdamage"
	end
end

local function forceSyncAfflictions(character)
	if Game.IsSingleplayer then return end
	-- force sync afflictions, as normally they aren't synced for dead characters
	Networking.CreateEntityEvent(character, Character.CharacterStatusEventData.__new(true))
end

-- ========================================== REPAIR FUNCTIONS ==========================================
-- Damaged Electronics
NTCS_Cybernetics.RepairDamagedElectronics = function(item, usingCharacter, targetCharacter, limb, maxHeal, maxMaterialLoss)
	
    -- CyberLimb check
    local limbtype = NTCS.HF.NormalizeLimbType(limb.type)
	if not NTCS_Cybernetics.HF.LimbIsCyber(targetCharacter, limbtype) then return end

    -- Damage Check
	local limbDamage = NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "ntc_damagedelectronics", 0)
	if limbDamage < 0.1 then return end

    -- Amount to repair, decrease condition appropriately
	local amountHealed = math.min(limbDamage, maxHeal, (item.Condition / maxMaterialLoss) * maxHeal)
	item.Condition = item.Condition - math.min(item.Condition, 100 * (amountHealed / maxHeal) * (maxMaterialLoss / 100))

	if not NTCS.HF.GetSkillRequirementMet(usingCharacter, "electrical", 40) then amountHealed = amountHealed / 2 end

    -- Repair + grant experience
	NTCS.HF.AddAfflictionLimb(targetCharacter, "ntc_damagedelectronics", limbtype, -amountHealed)
	forceSyncAfflictions(targetCharacter)
	NTCS.HF.GiveSkillScaled(usingCharacter, "electrical", amountHealed * 2)
	NTCS.HF.GiveSkillScaled(usingCharacter, "medical", amountHealed)

	NTCS.HF.GiveItem(targetCharacter, "ntcsfx_screwdriver")

    -- Delete item if at 0 condition
	if item.Condition <= 0 then NTCS.HF.RemoveItem(item) end
end

-- Material Loss
NTCS_Cybernetics.RepairMaterialLoss = function(item, usingCharacter, targetCharacter, limb, maxHeal, maxMaterialLoss)
	
    -- CyberLimb check
    local limbtype = NTCS.HF.NormalizeLimbType(limb.type)
	if not NTCS_Cybernetics.HF.LimbIsCyber(targetCharacter, limbtype) then return end

    -- Damage Check
	local limbDamage = NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "ntc_materialloss", 0)
	if limbDamage < 0.1 then return end

    -- Amount to repair, decrease condition appropriately
	local amountHealed = math.min(limbDamage, maxHeal, (item.Condition / maxMaterialLoss) * maxHeal)
	item.Condition = item.Condition - math.min(item.Condition, 100 * (amountHealed / maxHeal) * (maxMaterialLoss / 100))

	if not NTCS.HF.GetSkillRequirementMet(usingCharacter, "mechanical", 60) then amountHealed = amountHealed / 2 end

    -- Repair + grant experience
	NTCS.HF.AddAfflictionLimb(targetCharacter, "ntc_materialloss", limbtype, -amountHealed)
	forceSyncAfflictions(targetCharacter)
	NTCS.HF.GiveSkillScaled(usingCharacter, "mechanical", amountHealed * 2)
	NTCS.HF.GiveSkillScaled(usingCharacter, "medical", amountHealed)

    -- Play a different noise occasionally
	if math.random() < 0.5 then
		NTCS.HF.GiveItem(targetCharacter, "ntcsfx_screwdriver")
	else
		NTCS.HF.GiveItem(targetCharacter, "ntcsfx_welding")
	end

    -- Delete item if at 0 condition
	if item.Condition <= 0 then NTCS.HF.RemoveItem(item) end
end

-- Bent Metal
NTCS_Cybernetics.RepairBentMetal = function(item, usingCharacter, targetCharacter, limb, maxHeal, maxMaterialLoss)
	
    -- CyberLimb check
    local limbtype = NTCS.HF.NormalizeLimbType(limb.type)
	if not NTCS_Cybernetics.HF.LimbIsCyber(targetCharacter, limbtype) then return end

    -- Damage Check
	local limbDamage = NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "ntc_bentmetal", 0)
	if limbDamage < 0.1 then return end

    -- Amount to repair, decrease condition appropriately
	local amountHealed = math.min(limbDamage, maxHeal, (item.Condition / maxMaterialLoss) * maxHeal)
	item.Condition = item.Condition - math.min(item.Condition, 100 * (amountHealed / maxHeal) * (maxMaterialLoss / 100))

	if not NTCS.HF.GetSkillRequirementMet(usingCharacter, "mechanical", 50) then amountHealed = amountHealed / 2 end

    -- Repair + grant experience + damage if need be
	local oldCyberDamages = NTCS_Cybernetics.HF.GetAllCyberDamages(targetCharacter, limbtype) -- some mods (eg. EK) make welding torch hurt limbs, so lets record and undo any damage done this frame
	Timer.Wait(function()
		NTCS_Cybernetics.ConvertDamageTypes(targetCharacter, limbtype)
		NTCS_Cybernetics.HF.SetAllCyberDamages(targetCharacter, limbtype, oldCyberDamages)
		NTCS.HF.AddAfflictionLimb(targetCharacter, "ntc_bentmetal", limbtype, -amountHealed)
		forceSyncAfflictions(targetCharacter)
	end, 1)
	NTCS.HF.GiveSkillScaled(usingCharacter, "mechanical", amountHealed * 2)
	NTCS.HF.GiveSkillScaled(usingCharacter, "medical", amountHealed)

	NTCS.HF.GiveItem(targetCharacter, "ntcsfx_welding")

    -- Delete item if at 0 condition
	if item.Condition <= 0 then NTCS.HF.RemoveItem(item) end
end

-- ========================================== ITEM INITIALIZATION ==========================================
-- ==================== Tool Usage ====================
-- Crowbar
local Crowbar = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    -- Cyberlimb Check
    local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)
	if not NTCS_Cybernetics.HF.LimbIsCyber(targetCharacter, limbtype) then return end

    -- Condition Check
	local isWaterproof = NTCS.HF.HasAfflictionLimb(targetCharacter, "ntc_waterproof", limbtype, 99)
	local isGoodCondition = not NTCS.HF.HasAfflictionLimb(targetCharacter, "ntc_materialloss", limbtype, 20)
		and not NTCS.HF.HasAfflictionLimb(targetCharacter, "ntc_damagedelectronics", limbtype, 20)
		and not NTCS.HF.HasAfflictionLimb(targetCharacter, "ntc_bentmetal", limbtype, 20)

	if
		isGoodCondition
		and (
			NTCS.HF.GetSkillRequirementMet(usingCharacter, "mechanical", 50)
			or NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", 70)
		)
	then
		NTCS_Cybernetics.UncyberifyLimb(targetCharacter, limbtype)
		NTCS.HF.GiveItem(targetCharacter, "ntcsfx_cyberdeath")
		if not NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", 50) then
			NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", LimbType.Torso, NTCS.HF.RandomRange(10, 40))
			NTCS.HF.GiveItem(targetCharacter, "ntsfx_slash")
		else
			NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", LimbType.Torso, NTCS.HF.RandomRange(5, 10))
		end

		NTCS.HF.SurgicallyAmputateLimb(targetCharacter, limbtype)
		local limbItem
		if limbtype == LimbType.LeftLeg or limbtype == LimbType.RightLeg then
			if isWaterproof then
				limbItem = "waterproofcyberleg"
			else
				limbItem = "cyberleg"
			end
		elseif limbtype == LimbType.LeftArm or limbtype == LimbType.RightArm then
			if isWaterproof then
				limbItem = "waterproofcyberarm"
			else
				limbItem = "cyberarm"
			end
		end
		if limbItem ~= nil then
			NTCS.HF.GiveItem(usingCharacter, limbItem)
			NTCS.HF.GiveSkillScaled(usingCharacter, "mechanical", 200)
		end
	elseif NTCS.HF.GetSkillRequirementMet(usingCharacter, "weapons", 50) then
		NTCS.HF.AddAfflictionLimb(targetCharacter, "ntc_materialloss", limbtype, 20)
	else
		NTCS.HF.AddAfflictionLimb(targetCharacter, "ntc_materialloss", limbtype, 10)
	end

	forceSyncAfflictions(targetCharacter)

	NTCS.HF.GiveItem(targetCharacter, "ntcsfx_cyberblunt")
end

itemLoader:Register("crowbar", Crowbar)

-- Screwdriver
local Screwdriver = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    local limbtype = targetLimb.type

	-- fix up minor cyber-organ damage
	for organ, organConfig in pairs(NTCS_Cybernetics.OrganConfigDatas) do
		-- todo: allow full repairing organs in fab, and then limit the screwdriver to only minor repairs
		if
			limbtype == organConfig.limb
			and NTCS.HF.HasAffliction(targetCharacter, "ntc_cyber" .. organ, 1)
			and NTCS.HF.HasAffliction(targetCharacter, organConfig.damageAffliction, 1)
			and NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
		then
			if NTCS.HF.GetSkillRequirementMet(usingCharacter, organConfig.secondarySkillName, 50) then
				damageOrgan(targetCharacter, organ, -20, usingCharacter) -- heal "liverdamage"
				NTCS.HF.GiveSkill(usingCharacter, organConfig.secondarySkillName, 0.125)
			else
				damageOrgan(targetCharacter, organ, -5, usingCharacter)
			end
			NTCS.HF.GiveItem(targetCharacter, "ntcsfx_screwdriver")

			-- possibly damage surroundings if not medically skilled
			if NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter, 50) then
				NTCS.HF.GiveSurgerySkill(usingCharacter, 0.25)
			else
				NTCS.HF.AddAfflictionLimb(targetCharacter, "internalbleeding", limbtype, HF.RandomRange(0, 10))
				NTCS.HF.GiveItem(targetCharacter, "ntsfx_slash")
			end
			return -- one organ at a time
		end
	end

	if not NTCS_Cybernetics.HF.LimbIsCyber(targetCharacter, limbtype) then return end
	if NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "ntc_loosescrews", 0) < 0.1 then return end

	if NTCS.HF.GetSkillRequirementMet(usingCharacter, "mechanical", 40) then
		NTCS.HF.AddAfflictionLimb(targetCharacter, "ntc_loosescrews", limbtype, -20)
	else
		NTCS.HF.AddAfflictionLimb(targetCharacter, "ntc_loosescrews", limbtype, -5)
	end
	forceSyncAfflictions(targetCharacter)

	NTCS.HF.GiveItem(targetCharacter, "ntcsfx_screwdriver")
end

itemLoader:Register("screwdriver", Screwdriver)

-- TO DO
-- ADD THE REPAIR PACKS SCREWDRIVER FUNCTIONALITY
-- TO DO

-- FPGA Circuit
local FPGACircuit = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    NTCS_Cybernetics.RepairDamagedElectronics(item, usingCharacter, targetCharacter, targetLimb, 50, 100)
end

itemLoader:Register("fpgacircuit", FPGACircuit)

-- Steel Bars
local SteelBar = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    NTCS_Cybernetics.RepairMaterialLoss(item, usingCharacter, targetCharacter, targetLimb, 50, 100)
end

itemLoader:Register("steel", SteelBar)

-- Welding Tool
local WeldingTool = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    local containedItem = item.OwnInventory.GetItemAt(0)
	if containedItem == nil then return end

	-- weldingfuel is for Immersive Repairs WeldingTorch, mobilebattery is for EK Mods's ArcWelder
	local hasFuel = (
		containedItem.HasTag("weldingtoolfuel")
		or containedItem.HasTag("weldingfuel")
		or containedItem.HasTag("mobilebattery")
	) and containedItem.Condition > 0
	if not hasFuel then return end

	local fuelUsed = 2
	local identifier = containedItem.Prefab.Identifier.Value
	if identifier == "fulguriumbatterycell" then fuelUsed = 1 end

	NTCS_Cybernetics.RepairBentMetal(containedItem, usingCharacter, targetCharacter, targetLimb, 20, fuelUsed)
end

itemLoader:Register("weldingtool", WeldingTool)

-- ==================== Tool Usage - EK Mod Compatibility ====================
-- Hull Repair Kit
local HullRepairKit = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    local containedItem = item.OwnInventory.GetItemAt(0)
	if containedItem == nil then return end

	local identifier = containedItem.Prefab.Identifier.Value
	local hasFuel = identifier == "steel" and containedItem.Condition > 0
	if not hasFuel then return end

    NTCS_Cybernetics.RepairMaterialLoss(containedItem, usingCharacter, targetCharacter, targetLimb, 25, 50)
end

itemLoader:Register("ekutility_hullrepairkit", HullRepairKit)

-- Metal Foam Gun
local MetalFoamGun = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local target = d.target.Human
    local targetLimb = d.targetLimb

    local containedItem = item.OwnInventory.GetItemAt(0)
	if containedItem == nil then return end

	local identifier = containedItem.Prefab.Identifier.Value
	local hasFuel = identifier == "ekutility_metalfoam_tank" and containedItem.Condition > 0
	if not hasFuel then return end

    NTCS_Cybernetics.RepairMaterialLoss(item, usingCharacter, target, targetLimb, 50, 10)
end

itemLoader:Register("ekutility_metalfoam_gun", MetalFoamGun)

-- Arc Welder
itemLoader:Register("ekutility_arcwelder", WeldingTool)

-- Dementonite Welding Tool
itemLoader:Register("tadementoniteweldingtool", WeldingTool)

-- ==================== Tool Usage - Immersive Repairs Compatibility ====================
-- Welding Stinger
itemLoader:Register("weldingstinger", WeldingTool)

-- Halligan Tool
itemLoader:Register("halligantool", Crowbar)

-- ==================== CyberLimbs ====================
-- CyberArm
local CyberArm = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)

    -- Can't make a limb cybernetic if it already is!
	if NTCS_Cybernetics.HF.LimbIsCyber(targetCharacter, limbtype) then return end
	
    -- Surgery check
    if
		not (
			NTCS.HF.LimbIsSurgicallyAmputated(targetCharacter, limbtype)
			or NTCS.HF.HasAfflictionLimb(targetCharacter, "sawedbones", limbtype, 99)
		)
	then
		return
	end

    -- Only attaches to arms
	if limbtype ~= LimbType.LeftArm and limbtype ~= LimbType.RightArm then return end

    -- Skill check
	if NTCS.HF.GetSkillRequirementMet(usingCharacter, "mechanical", 70) then
		if not NTCS.HF.LimbIsAmputated(targetCharacter, limbtype) then
			NTCS.HF.SurgicallyAmputateLimbAndGenerateItem(usingCharacter, targetCharacter, limbtype)
		end
		NTCS_Cybernetics.CyberifyLimb(targetCharacter, limbtype, false)
		NTCS.HF.RemoveItem(item)
	else
		NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, NTCS.HF.RandomRange(15, 50))
		NTCS.HF.GiveItem(targetCharacter, "ntsfx_slash")
	end
end

itemLoader:Register("cyberarm", CyberArm)

-- Waterproof CyberArm
local CyberArmWaterproof = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

        local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)

    -- Can't make a limb cybernetic if it already is!
	if NTCS_Cybernetics.HF.LimbIsCyber(targetCharacter, limbtype) then return end
	
    -- Surgery check
    if
		not (
			NTCS.HF.LimbIsSurgicallyAmputated(targetCharacter, limbtype)
			or NTCS.HF.HasAfflictionLimb(targetCharacter, "sawedbones", limbtype, 99)
		)
	then
		return
	end

    -- Only attaches to arms
	if limbtype ~= LimbType.LeftArm and limbtype ~= LimbType.RightArm then return end

    -- Skill check
	if NTCS.HF.GetSkillRequirementMet(usingCharacter, "mechanical", 70) then
		if not NTCS.HF.LimbIsAmputated(targetCharacter, limbtype) then
			NTCS.HF.SurgicallyAmputateLimbAndGenerateItem(usingCharacter, targetCharacter, limbtype)
		end
		NTCS_Cybernetics.CyberifyLimb(targetCharacter, limbtype, true)
		NTCS.HF.RemoveItem(item)
	else
		NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, NTCS.HF.RandomRange(15, 50))
		NTCS.HF.GiveItem(targetCharacter, "ntsfx_slash")
	end
end

itemLoader:Register("waterproofcyberarm", CyberArmWaterproof)

-- CyberLeg
local CyberLeg = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)

    -- Can't make a limb cybernetic if it already is!
	if NTCS_Cybernetics.HF.LimbIsCyber(targetCharacter, limbtype) then return end
	
    -- Surgery check
    if
		not (
			NTCS.HF.LimbIsSurgicallyAmputated(targetCharacter, limbtype)
			or NTCS.HF.HasAfflictionLimb(targetCharacter, "sawedbones", limbtype, 99)
		)
	then
		return
	end

    -- Only attaches to legs
	if limbtype ~= LimbType.LeftLeg and limbtype ~= LimbType.RightLeg then return end

    -- Skill check
	if NTCS.HF.GetSkillRequirementMet(usingCharacter, "mechanical", 70) then
		if not NTCS.HF.LimbIsAmputated(targetCharacter, limbtype) then
			NTCS.HF.SurgicallyAmputateLimbAndGenerateItem(usingCharacter, targetCharacter, limbtype)
		end
		NTCS_Cybernetics.CyberifyLimb(targetCharacter, limbtype, false)
		NTCS.HF.RemoveItem(item)
	else
		NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, NTCS.HF.RandomRange(15, 50))
		NTCS.HF.GiveItem(targetCharacter, "ntsfx_slash")
	end
end

itemLoader:Register("cyberleg", CyberLeg)

-- Waterproof CyberLeg
local CyberLegWaterproof = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)

    -- Can't make a limb cybernetic if it already is!
	if NTCS_Cybernetics.HF.LimbIsCyber(targetCharacter, limbtype) then return end
	
    -- Surgery check
    if
		not (
			NTCS.HF.LimbIsSurgicallyAmputated(targetCharacter, limbtype)
			or NTCS.HF.HasAfflictionLimb(targetCharacter, "sawedbones", limbtype, 99)
		)
	then
		return
	end

    -- Only attaches to legs
	if limbtype ~= LimbType.LeftLeg and limbtype ~= LimbType.RightLeg then return end

    -- Skill check
	if NTCS.HF.GetSkillRequirementMet(usingCharacter, "mechanical", 70) then
		if not NTCS.HF.LimbIsAmputated(targetCharacter, limbtype) then
			NTCS.HF.SurgicallyAmputateLimbAndGenerateItem(usingCharacter, targetCharacter, limbtype)
		end
		NTCS_Cybernetics.CyberifyLimb(targetCharacter, limbtype, true)
		NTCS.HF.RemoveItem(item)
	else
		NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, NTCS.HF.RandomRange(15, 50))
		NTCS.HF.GiveItem(targetCharacter, "ntsfx_slash")
	end
end

itemLoader:Register("waterproofcyberleg", CyberLegWaterproof)

-- ==================== CyberOrgans ====================
-- Helper functions for implantOrgan
local function possiblyRejectOrgan(targetCharacter, usingCharacter, organName)
	local rejectionchance = NTCS.HF.Clamp(
		(NTCS.HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
			/ 150
			* NTCS.NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
		0,
		1
	)
	if
		NTCS.HF.Chance(rejectionchance)
		and NTCS.NTConfig.Get("NT_organRejection", false)
		and not NTCS.HF.HasAfflictionLimb(targetCharacter, "ntc_cyberkidney", LimbType.Torso, 0.1)
	then
		damageOrgan(targetCharacter, organName, 100, usingCharacter)
	end
end

local function giveOrganic(item, usingCharacter, targetCharacter, damage, organName)
	-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
	local function postSpawnFunc(args)
		local tags = {}

		if args.acidosis > 0 then
			table.insert(tags, "acid:" .. tostring(NTCS.HF.Round(args.acidosis)))
		elseif args.alkalosis > 0 then
			table.insert(tags, "alkal:" .. tostring(NTCS.HF.Round(args.alkalosis)))
		end
		if args.sepsis > 10 then table.insert(tags, "sepsis") end

		local tagstring = ""
		for index, value in ipairs(tags) do
			tagstring = tagstring .. value
			if index < #tags then tagstring = tagstring .. "," end
		end

		args.item.Tags = tagstring
		args.item.Condition = args.condition
	end
	local params = {
		acidosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "acidosis"),
		alkalosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
		sepsis = NTCS.HF.GetAfflictionStrength(targetCharacter, "sepsis"),
		condition = 100 - damage,
	}
	local parentInventory = item.ParentInventory
	local inventorySpot = nil
	if parentInventory ~= nil then inventorySpot = parentInventory.FindIndex(item) end
	local transplantidentifier = organName .. "transplant_q1"

	if NTCS.NTC.HasTag(usingCharacter, "organssellforfull") then transplantidentifier = organName .. "transplant" end

	if string.find(item.Prefab.Identifier.Value, "kidney") then
		local container = usingCharacter.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
		if container == nil or container.OwnInventory == nil or container.OwnInventory.IsFull() then
			container = usingCharacter.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)
		end
		if container ~= nil and container.OwnInventory ~= nil and container.OwnInventory.IsFull() == false then
			NTCS.HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, container.OwnInventory)
		else
			NTCS.HF.GiveItemPlusFunction(transplantidentifier, postSpawnFunc, params, usingCharacter)
		end
	else
		NTCS.HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
	end
end

local function giveCyber(item, usingCharacter, targetCharacter, damage, organName, cyberStrength)
	local function postSpawnFunc(args)
		local tags = {}

		if args.acidosis > 0 then
			table.insert(tags, "acid:" .. tostring(NTCS.HF.Round(args.acidosis)))
		elseif args.alkalosis > 0 then
			table.insert(tags, "alkal:" .. tostring(NTCS.HF.Round(args.alkalosis)))
		end
		if args.sepsis > 10 then table.insert(tags, "sepsis") end

		local tagstring = ""
		for index, value in ipairs(tags) do
			tagstring = tagstring .. value
			if index < #tags then tagstring = tagstring .. "," end
		end

		args.item.Tags = tagstring
		args.item.Condition = args.condition
	end
	local params = {
		acidosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "acidosis"),
		alkalosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
		sepsis = NTCS.HF.GetAfflictionStrength(targetCharacter, "sepsis"),
		condition = 100 - damage,
	}
	local inventorySpot = nil
	local parentInventory = item.ParentInventory
	if parentInventory then inventorySpot = parentInventory.FindIndex(item) end
	-- augmented
	local transplantidentifier = NTCS_Cybernetics.OrganConfigDatas[organName].tier2Item
	if cyberStrength > 50 then
		-- cybernetic
		transplantidentifier = NTCS_Cybernetics.OrganConfigDatas[organName].tier3Item
	end
	NTCS.HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
end

-- Let's allow this to swap between cyber and regular organs for once and for all... hopefully
local ImplantOrgan = function (d)

    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

	local organName
	for organ, _ in pairs(NTCS_Cybernetics.OrganConfigDatas) do
		if string.find(item.Prefab.Identifier.Value, organ) then
			organName = organ
			break
		end
	end
	if organName == nil then
		print("NT Cybernetics: Unknown organ " .. tostring(item.Prefab.Identifier.Value))
		return
	end
	local limbtype = targetLimb.type
	local isArtificial = string.find(item.Prefab.Identifier.Value, "cyber")
		or string.find(item.Prefab.Identifier.Value, "augmented")
	local patientHasArtificial = NTCS.HF.HasAfflictionLimb(targetCharacter, "ntc_cyber" .. organName, limbtype, 1)
	if not isArtificial and not patientHasArtificial then
		-- If using a regular organ on a patient with regular organ, use base method
		NTCS_Cybernetics.OrganConfigDatas[organName].baseImplantMethod(item, usingCharacter, targetCharacter, targetLimb)
		return
	end
	local conditionmodifier = 0
	if not NTCS.HF.GetSkillRequirementMet(usingCharacter, NTCS_Cybernetics.OrganConfigDatas[organName].secondarySkillName, 60) then
		conditionmodifier = conditionmodifier - 20
	end

	local workcondition = NTCS.HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		(
			NTCS.HF.HasAffliction(targetCharacter, organName .. "removed", 1)
			or NTCS.HF.HasAffliction(targetCharacter, organName .. "swap", 1)
		)
		and limbtype == LimbType.Torso
		and NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
		-- possibly damage surroundings if not medically skilled
		if NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter, 70) then
			NTCS.HF.GiveSurgerySkill(usingCharacter, 0.4)
		else
			NTCS.HF.AddAfflictionLimb(targetCharacter, "internalbleeding", limbtype, NTCS.HF.RandomRange(0, 10))
			NTCS.HF.GiveItem(targetCharacter, "ntsfx_slash")
		end

		local cyberStrength = NTCS.HF.GetAfflictionStrength(targetCharacter, "ntc_cyber" .. organName)
		local damage = NTCS.HF.GetAfflictionStrength(targetCharacter, organName .. "damage", 0)
		local newdamage = NTCS.HF.Clamp((100 - damage) - workcondition, -100, 100) -- define organdamage swap as the default newdamage

		NTCS.HF.RemoveItem(item)
		if organName == "kidney" then
			if isArtificial then
				if patientHasArtificial then
					-- artificial to artificial kidney replacement, give and place artificial organs, no timer for swap/removed status removal
					giveCyber(item, usingCharacter, targetCharacter, damage, organName, cyberStrength)
				elseif damage > 45 and damage < 95 then
					-- organic to artificial kidney replacement, place artificial organ and give one organic kidney
					giveOrganic(item, usingCharacter, targetCharacter, damage - 50, organName)
				elseif damage < 45 then
					-- give two organic kidneys
					giveOrganic(item, usingCharacter, targetCharacter, damage * 2, organName)
					giveOrganic(item, usingCharacter, targetCharacter, 0, organName)
				end
				if damage > 95 then
					newdamage = -workcondition
					damageOrgan(targetCharacter, organName, -workcondition, usingCharacter)
				else
					NTCS.HF.SetAffliction(targetCharacter, organName .. "damage", 100 - workcondition, targetCharacter)
				end
				NTCS.HF.SetAfflictionLimb(
					targetCharacter,
					"ntc_cyber" .. organName,
					limbtype,
					string.find(item.Prefab.Identifier.Value, "augmented") and 50 or 100
				) -- add "ntc_cyberliver", at 50% strength if its Augmented (tier 2), 100% if Cyber (tier 3)
				for _, affliction in ipairs(NTCS_Cybernetics.OrganConfigDatas[organName].curedAfflictions) do
					NTCS.HF.SetAffliction(targetCharacter, affliction, 0, usingCharacter)
				end
				NTCS.HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)
			elseif patientHasArtificial then
				-- artificial to organic kidney replacement, place one organic kidney and give artificial, add timer for swap/removed status removal
				newdamage = NTCS.HF.Clamp(((100 - damage) - workcondition) / 2, -100, 100)
				NTCS.HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)
				NTCS.HF.SetAffliction(targetCharacter, organName .. "damage", 100 - workcondition / 2, targetCharacter)
				giveCyber(item, usingCharacter, targetCharacter, damage, organName, cyberStrength)
				NTCS.HF.SetAfflictionLimb(targetCharacter, "ntc_cyber" .. organName, limbtype, -999)
				Timer.Wait(function()
					NTCS.HF.SetAffliction(targetCharacter, organName .. "removed", 0, usingCharacter)
					NTCS.HF.SetAffliction(targetCharacter, organName .. "swap", 0, usingCharacter)
				end, 3000)
				return
			end

			NTCS.HF.SetAffliction(targetCharacter, organName .. "removed", 0, usingCharacter)
			NTCS.HF.SetAffliction(targetCharacter, organName .. "swap", 0, usingCharacter)
			return
		end
		if damage == 100 then
			if isArtificial then
				-- in place of destroyed one, insert artificial organ
				damageOrgan(targetCharacter, organName, -workcondition, usingCharacter)
				NTCS.HF.SetAfflictionLimb(
					targetCharacter,
					"ntc_cyber" .. organName,
					limbtype,
					string.find(item.Prefab.Identifier.Value, "augmented") and 50 or 100
				) -- add "ntc_cyberliver", at 50% strength if its Augmented (tier 2), 100% if Cyber (tier 3)
				for _, affliction in ipairs(NTCS_Cybernetics.OrganConfigDatas[organName].curedAfflictions) do
					NTCS.HF.SetAffliction(targetCharacter, affliction, 0, usingCharacter)
				end
				NTCS.HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			else
				-- insert the organic
				NTCS.HF.SetAffliction(targetCharacter, organName .. "damage", 100 - workcondition, targetCharacter)
				damageOrgan(targetCharacter, organName, -workcondition, usingCharacter)
				NTCS.HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
				NTCS.HF.SetAfflictionLimb(targetCharacter, "ntc_cyber" .. organName, limbtype, -999)
			end
		elseif isArtificial then
			if patientHasArtificial then
				-- artificial to artificial organ replacement, give and place artificial organs
				NTCS.HF.SetAffliction(targetCharacter, organName .. "damage", 100 - workcondition, targetCharacter)
				NTCS.HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)
				giveCyber(item, usingCharacter, targetCharacter, damage, organName, cyberStrength)
				NTCS.HF.SetAfflictionLimb(
					targetCharacter,
					"ntc_cyber" .. organName,
					limbtype,
					string.find(item.Prefab.Identifier.Value, "augmented") and 50 or 100
				) -- add "ntc_cyberliver", at 50% strength if its Augmented (tier 2), 100% if Cyber (tier 3)
			else
				-- organic to artificial organ replacement, give organic and place artificial organ
				NTCS.HF.SetAffliction(targetCharacter, organName .. "damage", 100 - workcondition, targetCharacter)
				NTCS.HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)
				giveOrganic(item, usingCharacter, targetCharacter, damage, organName)
				NTCS.HF.SetAfflictionLimb(
					targetCharacter,
					"ntc_cyber" .. organName,
					limbtype,
					string.find(item.Prefab.Identifier.Value, "augmented") and 50 or 100
				) -- add "ntc_cyberliver", at 50% strength if its Augmented (tier 2), 100% if Cyber (tier 3)
			end
		else
			-- artificial to organic organ replacement, give artificial and place organic organ
			NTCS.HF.SetAffliction(targetCharacter, organName .. "damage", 100 - workcondition, targetCharacter)
			NTCS.HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)
			giveCyber(item, usingCharacter, targetCharacter, damage, organName, cyberStrength)
			NTCS.HF.SetAfflictionLimb(targetCharacter, "ntc_cyber" .. organName, limbtype, -999)
		end
		NTCS.HF.SetAffliction(targetCharacter, organName .. "removed", 0, usingCharacter)
		NTCS.HF.SetAffliction(targetCharacter, organName .. "swap", 0, usingCharacter)
	end
end

itemLoader:Register("augmentedliver", ImplantOrgan)
itemLoader:Register("cyberliver", ImplantOrgan)

itemLoader:Register("augmentedkidney", ImplantOrgan)
itemLoader:Register("cyberkidney", ImplantOrgan)

itemLoader:Register("augmentedheart", ImplantOrgan)
itemLoader:Register("cyberheart", ImplantOrgan)

itemLoader:Register("augmentedlung", ImplantOrgan)
itemLoader:Register("cyberlung", ImplantOrgan)

itemLoader:Override("lungtransplant", ImplantOrgan)
itemLoader:Override("livertransplant", ImplantOrgan)
itemLoader:Override("kidneytransplant", ImplantOrgan)
itemLoader:Override("hearttransplant", ImplantOrgan)

local ImplantBrain = function (d)

    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

	local organName = "brain"

	local limbtype = targetLimb.type
	local conditionmodifier = 0
	if not NTCS.HF.GetSkillRequirementMet(usingCharacter, NTCS_Cybernetics.OrganConfigDatas[organName].secondarySkillName, 60) then
		conditionmodifier = conditionmodifier - 20
	end

	local workcondition = NTCS.HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	-- brain implants are chips inserted during surgery into the meat, so the brain must still be there
	if
		not NTCS.HF.HasAffliction(targetCharacter, organName .. "removed", 1)
		and limbtype == LimbType.Head
		and NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
		-- possibly damage surroundings if not medically skilled
		if NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter, 80) then
			NTCS.HF.GiveSurgerySkill(usingCharacter, 0.4)
		else
			NTCS.HF.AddAfflictionLimb(targetCharacter, "internalbleeding", limbtype, NTCS.HF.RandomRange(0, 15))
			NTCS.HF.GiveItem(targetCharacter, "ntsfx_slash")
		end
		damageOrgan(targetCharacter, organName, -workcondition, usingCharacter) -- heal NTCS
		NTCS.HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter) -- heal a bit of vanilla organ damage
		NTCS.HF.SetAfflictionLimb(
			targetCharacter,
			"ntc_cyber" .. organName,
			limbtype,
			string.find(item.Prefab.Identifier.Value, "augmented") and 50 or 100
		) -- add "ntc_cyberliver", at 50% strength if its Augmented (tier 2), 100% if Cyber (tier 3)
		NTCS.HF.RemoveItem(item)

		possiblyRejectOrgan(targetCharacter, usingCharacter, organName)
	end
end

itemLoader:Register("augmentedbrain", ImplantBrain)
itemLoader:Register("cyberbrain", ImplantBrain)

-- ==================== Medicines ====================

local ImmunoSuppressantInhaler = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    if NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", 15) then
		NTCS.HF.AddAffliction(targetCharacter, "immunosuppressantinhaler", 100, usingCharacter)
	else
		NTCS.HF.AddAffliction(targetCharacter, "immunosuppressantinhaler", 50, usingCharacter)
	end

	item.Condition = item.Condition - 25
	if item.Condition <= 0 then NTCS.HF.RemoveItem(item) end

	NTCS.HF.GiveItem(targetCharacter, "ntsfx_syringe")
end

itemLoader:Register("immunosuppressantinhaler", ImmunoSuppressantInhaler)
NTCS.NTC.AddHematologyAffliction("immunosuppressantinhaler")

-- ==================== Surgery ====================

-- TO DO
-- RE-ADD POST-MORTEM SURGERY
-- TO DO

local function RemoveCyberOrgan(item, usingCharacter, targetCharacter, targetLimb, organConfig)
    if organConfig == nil then
        print("NT Cybernetics: Unknown organscalpel: " .. tostring(item.Prefab.Identifier.Value))
        organConfig.baseMethod(item, usingCharacter, targetCharacter, targetLimb)
        return
    end

    local limbtype = targetLimb.type
    if limbtype ~= organConfig.targetLimb or not HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1) then
        return
    end
    local procureready = NTCS.HF.GetAfflictionStrength(targetCharacter, organConfig.removedAffliction, 0) <= 0
        and NTCS.HF.GetAfflictionStrength(targetCharacter, organConfig.swapAffliction, 0) >= 0.1
    if not procureready then
        if NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter, organConfig.surgerySkillRemoval) then
            if NTCS.HF.GetAfflictionStrength(targetCharacter, organConfig.damageAffliction, 0) >= 100 then
                NTCS.HF.SetAffliction(targetCharacter, organConfig.removedAffliction, 100, usingCharacter)
            else
                NTCS.HF.SetAffliction(targetCharacter, organConfig.swapAffliction, 100, usingCharacter)
            end
        else
            NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 15, usingCharacter)
            NTCS.HF.AddAfflictionLimb(targetCharacter, "organdamage", limbtype, 5, usingCharacter)
            NTCS.HF.AddAffliction(targetCharacter, organConfig.damageAffliction, 20, usingCharacter)
        end
    elseif NTCS.HF.HasAfflictionLimb(targetCharacter, organConfig.cyberAffliction, limbtype) then
        local damage = NTCS.HF.GetAfflictionStrength(targetCharacter, organConfig.damageAffliction, 0)
        local removed = NTCS.HF.GetAfflictionStrength(targetCharacter, organConfig.removedAffliction, 0)
        if removed <= 0 then
            NTCS.HF.SetAffliction(targetCharacter, organConfig.removedAffliction, 100, usingCharacter)
            NTCS.HF.SetAffliction(targetCharacter, organConfig.swapAffliction, 0, usingCharacter)
        end

        if NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter, organConfig.surgerySkillRemoval) then
            if organConfig.removedAffliction ~= nil then
                NTCS.HF.SetAffliction(targetCharacter, organConfig.removedAffliction, 100, usingCharacter)
            end
            if organConfig.damageAffliction ~= nil then
                NTCS.HF.SetAffliction(targetCharacter, organConfig.damageAffliction, 100, usingCharacter)
            end

            for _, affliction in ipairs(organConfig.curedAfflictions) do
                if NTCS.HF.HasAffliction(targetCharacter, affliction) then
                    NTCS.HF.SetAffliction(targetCharacter, affliction, 0, usingCharacter)
                end
            end
            local container = usingCharacter.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
            if container == nil or container.OwnInventory == nil or container.OwnInventory.IsFull() then
                container = usingCharacter.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)
            end
            local toContainer = container ~= nil
                and container.OwnInventory ~= nil
                and not container.OwnInventory.IsFull()
            local function postSpawnFunc(args)
                local tags = {}

                if args.acidosis > 0 then
                    table.insert(tags, "acid:" .. tostring(NTCS.HF.Round(args.acidosis)))
                elseif args.alkalosis > 0 then
                    table.insert(tags, "alkal:" .. tostring(NTCS.HF.Round(args.alkalosis)))
                end
                if args.sepsis > 10 then table.insert(tags, "sepsis") end

                local tagstring = ""
                for index, value in ipairs(tags) do
                    tagstring = tagstring .. value
                    if index < #tags then tagstring = tagstring .. "," end
                end

                args.item.Tags = tagstring
                args.item.Condition = args.condition
            end
            local params = {
                acidosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "acidosis"),
                alkalosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
                sepsis = NTCS.HF.GetAfflictionStrength(targetCharacter, "sepsis"),
                condition = 100 - damage,
            }
            if organConfig.cyberAffliction == "ntc_cyberbrain" then
                -- tier 2 and 3 brains are both synthetic implants
                if NTCS.HF.HasAfflictionLimb(targetCharacter, organConfig.cyberAffliction, limbtype, 99) then
                    if toContainer then
                        NTCS.HF.SpawnItemPlusFunction(organConfig.tier3Item, nil, nil, container.OwnInventory)
                    else
                        NTCS.HF.GiveItem(usingCharacter, organConfig.tier3Item, 100)
                    end
                else
                    if toContainer then
                        NTCS.HF.SpawnItemPlusFunction(organConfig.tier2Item, nil, nil, container.OwnInventory)
                    else
                        NTCS.HF.GiveItem(usingCharacter, organConfig.tier2Item, 100)
                    end
                end
            elseif NTCS.HF.HasAfflictionLimb(targetCharacter, organConfig.cyberAffliction, limbtype, 99) then
                -- cybernetic
                if toContainer then
                    NTCS.HF.SpawnItemPlusFunction(organConfig.tier3Item, postSpawnFunc, params, container.OwnInventory)
                else
                    NTCS.HF.GiveItem(usingCharacter, organConfig.tier3Item, NTCS.HF.Clamp(100 - damage, 1, 100))
                end
            else
                -- augmented
                if toContainer then
                    NTCS.HF.SpawnItemPlusFunction(organConfig.tier2Item, postSpawnFunc, params, container.OwnInventory)
                else
                    NTCS.HF.GiveItemPlusFunction(organConfig.tier2Item, postSpawnFunc, params, usingCharacter)
                end
            end
            NTCS.HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, usingCharacter)
            NTCS.HF.SetAfflictionLimb(targetCharacter, organConfig.cyberAffliction, limbtype, 0, usingCharacter)
        else
            NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 15, usingCharacter)
            NTCS.HF.AddAfflictionLimb(targetCharacter, "organdamage", limbtype, 5, usingCharacter)
            NTCS.HF.AddAffliction(targetCharacter, organConfig.damageAffliction, 20, usingCharacter)
        end
        if targetCharacter.IsDead then forceSyncAfflictions(targetCharacter) end

        NTCS.HF.GiveItem(targetCharacter, "ntsfx_slash")
    elseif not targetCharacter.IsDead then
        organConfig.baseMethod(item, usingCharacter, targetCharacter, targetLimb)
    end
end

-- Kidneys
local RemoveKidney = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    RemoveCyberOrgan(item, usingCharacter, targetCharacter, targetLimb, NTCS_Cybernetics.OrganConfigDatas["kidney"])
end

itemLoader:Override("organscalpel_kidneys", RemoveKidney)

-- Liver
local RemoveLiver = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    RemoveCyberOrgan(item, usingCharacter, targetCharacter, targetLimb, NTCS_Cybernetics.OrganConfigDatas["liver"])
end

itemLoader:Override("organscalpel_liver", RemoveLiver)

-- Lungs
local RemoveLungs = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    RemoveCyberOrgan(item, usingCharacter, targetCharacter, targetLimb, NTCS_Cybernetics.OrganConfigDatas["lung"])
end

itemLoader:Override("organscalpel_lungs", RemoveLungs)

-- Heart
local RemoveHeart = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    RemoveCyberOrgan(item, usingCharacter, targetCharacter, targetLimb, NTCS_Cybernetics.OrganConfigDatas["heart"])
end

itemLoader:Override("organscalpel_heart", RemoveHeart)

-- Brain
local RemoveBrain = function (d)
    
    local item = d.item
    local usingCharacter = d.user.Human
    local targetCharacter = d.target.Human
    local targetLimb = d.targetLimb

    RemoveCyberOrgan(item, usingCharacter, targetCharacter, targetLimb, NTCS_Cybernetics.OrganConfigDatas["brain"])
end

itemLoader:Override("organscalpel_brain", RemoveBrain)

-- ==================== Miscellaneous ====================
Timer.Wait(function()

    -- Add CyberBlood to the known blood types
    NTCS.NTBloodTypes.AddBloodType("abc_positive", 0)

    -- Pharmacy Integration
    if NTP ~= nil and NTP.PillData ~= nil then
		NTP.PillData.items.bloodpackabcplus = NTP.PillData.items["antibloodloss2"]
	end

    -- NT Eye Integration
    -- TO DO
    -- Add NT Eyes ItemMethod + override partially here
    -- TO DO

end, 5000)