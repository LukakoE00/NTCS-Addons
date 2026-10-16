---@diagnostic disable: undefined-global

Hook.Add("item.applyTreatment", "NTGraft.itemused", function(item, usingCharacter, targetCharacter, limb)
	local identifier = item.Prefab.Identifier.Value

	local methodtorun = NTGraft.ItemMethods[identifier]
	if (methodtorun ~= nil) then
		methodtorun(item, usingCharacter, targetCharacter, limb)
		return
	end
end)





NTGraft.ItemMethods = {}




-- ORGAN IDENTIFIER FUNCTION

local graftedOrganItems = {
	Lungs = {
		{ affliction = "crawlerLungsAffliction", item = "crawlerLungsAegis" },
		{ affliction = "mudraptorLungsAffliction", item = "mudraptorLungsAegis" },
	},
	Heart = {
		{ affliction = "huskHeartAffliction", item = "huskHeartAegis" },
		{ affliction = "latcherHeartAffliction", item = "latcherHeartAegis" },
	},
	Liver = {
		{ affliction = "mantisLiverAffliction", item = "mantisLiverAegis" },
		{ affliction = "broodmotherLiverAffliction", item = "broodmotherLiverAegis", clearWithAggressor = false },
		{ affliction = "viperlingLiverAffliction", item = "viperlingLiverAegis" },
	},
}

local function GetGraftedOrganItem(targetCharacter, organ)
	local organItems = graftedOrganItems[organ]
	if organItems == nil then return nil end

	for _, organItem in ipairs(organItems) do
		if HF.HasAffliction(targetCharacter, organItem.affliction, 1) then
			return organItem
		end
	end
	return nil
end

local function ClearGraftedOrgan(targetCharacter, usingCharacter, organ)
	local organItem = GetGraftedOrganItem(targetCharacter, organ)
	if organItem == nil then return nil end

	if organItem.clearWithAggressor == false then
		HF.SetAffliction(targetCharacter, organItem.affliction, 0)
	else
		HF.SetAffliction(targetCharacter, organItem.affliction, 0, usingCharacter)
	end
	return organItem.item
end

local cyberOrganNames = {
	Lungs = "lung",
	Heart = "heart",
	Liver = "liver",
}

local function ClearCyberOrgan(targetCharacter, usingCharacter, organ)
	if NTCyb == nil or NTCyb.OrganConfigDatas == nil then return nil end

	local organName = cyberOrganNames[organ]
	local organConfig = organName ~= nil and NTCyb.OrganConfigDatas[organName] or nil
	if organConfig == nil or organConfig.cyberAffliction == nil then return nil end

	local cyberStrength = HF.GetAfflictionStrengthLimb(
		targetCharacter,
		LimbType.Torso,
		organConfig.cyberAffliction,
		0
	)
	if cyberStrength < 0.1 then return nil end

	HF.SetAfflictionLimb(
		targetCharacter,
		organConfig.cyberAffliction,
		LimbType.Torso,
		0,
		usingCharacter
	)
	if cyberStrength > 50 then return organConfig.tier3Item end
	return organConfig.tier2Item
end

local function organIdentifier(targetCharacter, usingCharacter, organ)
	local graftedItem = ClearGraftedOrgan(targetCharacter, usingCharacter, organ)
	if graftedItem ~= nil then return graftedItem end

	local cyberItem = ClearCyberOrgan(targetCharacter, usingCharacter, organ)
	if cyberItem ~= nil then return cyberItem end

	if organ == "Lungs" then
		if NTC.HasTag(usingCharacter, "organssellforfull") then return "lungtransplant" end
		return "lungtransplant_q1"
	elseif organ == "Heart" then
		if NTC.HasTag(usingCharacter, "organssellforfull") then return "hearttransplant" end
		return "hearttransplant_q1"
	elseif organ == "Liver" then
		if NTC.HasTag(usingCharacter, "organssellforfull") then return "livertransplant" end
		return "livertransplant_q1"
	end
end

local function ApplyTransplantDonorData(args)
	local tags = {}

	if args.acidosis > 0 then
		table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
	elseif args.alkalosis > 0 then
		table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
	end
	if args.sepsis > 10 then table.insert(tags, "sepsis") end

	args.item.Tags = table.concat(tags, ",")
	args.item.Condition = args.condition
end

local function GetTransplantDonorParams(targetCharacter, condition)
	return {
		acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
		alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
		sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
		condition = condition,
	}
end


-- GENERAL ITEMS


NTGraft.ItemMethods.graftingcure = function(item, usingCharacter, targetCharacter, limb)
	local medicalLevel = HF.GetSkillLevel(usingCharacter, "medical")

	if (medicalLevel >= 50) then
		HF.AddAffliction(targetCharacter, "graftingcureoverdose", 70, usingCharacter)
		HF.AddAffliction(targetCharacter, "crossspeciesrejection", -25, usingCharacter)
		HF.RemoveItem(item)
	else
		local skillcheck = math.random(0, 50)
		if (medicalLevel >= skillcheck) then
			HF.AddAffliction(targetCharacter, "graftingcureoverdose", 75, usingCharacter)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", -25, usingCharacter)
			HF.RemoveItem(item)
		elseif (medicalLevel < skillcheck) then
			HF.AddAffliction(targetCharacter, "graftingcureoverdose", 85, usingCharacter)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", -25, usingCharacter)
			HF.RemoveItem(item)
		end
	end
end




NTGraft.ItemMethods.dnasplicer = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	local strength = 100
	if (HF.HasAfflictionLimb(targetCharacter, "hammerheadTorsoAffliction", limbtype, 1)) then
		strength = 66
	elseif (HF.HasAfflictionLimb(targetCharacter, "endwormTorsoAffliction", LimbType.Torso, 1)) and limbtype ~= LimbType.Head then
		strength = 33
	end

	if (medicalLevel >= 50) then
		HF.AddAfflictionLimb(targetCharacter, "alienDNARemoval", limbtype, strength, usingCharacter)
		HF.RemoveItem(item)
	else
		local skillcheck = math.random(0, 50)
		if (medicalLevel >= skillcheck) then
			HF.AddAfflictionLimb(targetCharacter, "alienDNARemoval", limbtype, strength, usingCharacter)
			HF.RemoveItem(item)
		elseif (medicalLevel < skillcheck) then
			strength = strength / 2
			HF.AddAfflictionLimb(targetCharacter, "alienDNARemoval", limbtype, strength, usingCharacter)
			HF.RemoveItem(item)
		end
	end
end




NTGraft.ItemMethods.alienscalpel = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	--Torso, Grafting Removal.
	--Current List: CrawlerTail, HuskArm, TigerThresherTail, HammerheadLimbs, OrangeboyTail
	if (limbtype == LimbType.Torso) then
		if (medicalLevel >= 30) then
			if (HF.HasAffliction(targetCharacter, "orangeboyTailAffliction", 1) and HF.HasAfflictionLimb(targetCharacter, "retractedSkin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "orangeboyTailAffliction", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "orangeboyTailAegis")
			elseif (HF.HasAffliction(targetCharacter, "crawlerTailAegis", 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "crawlerTailAegis", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "crawlerTailAegis")
			elseif (HF.HasAffliction(targetCharacter, "tigerThresherTailAffliction", 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "tigerThresherTailAffliction", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "tigerThresherTailAegis")
			elseif (HF.HasAffliction(targetCharacter, "huskArmAffliction", 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "huskArmAffliction", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "huskArmAegis")
			elseif (HF.HasAffliction(targetCharacter, "hammerheadLimbsAffliction", 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "hammerheadLimbsAffliction", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "hammerheadLimbsAegis")
			end
		else
			local skillcheck = math.random(0, 30)
			if (skillcheck > medicalLevel) then
				HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 15, usingCharacter)
			elseif (HF.HasAffliction(targetCharacter, "orangeboyTailAffliction", limbtype, 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "orangeboyTailAffliction", 0, usingCharacter, 0)
				HF.GiveItem(targetCharacter, "orangeboyTailAegis")
			elseif (HF.HasAffliction(targetCharacter, "crawlerTailAegis", limbtype, 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "crawlerTailAegis", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "crawlerTailAegis")
			elseif (HF.HasAffliction(targetCharacter, "tigerThresherTailAffliction", 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "tigerThresherTailAffliction", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "tigerThresherTailAegis")
			elseif (HF.HasAffliction(targetCharacter, "huskArmAffliction", 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "huskArmAffliction", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "huskArmAegis")
			elseif (HF.HasAffliction(targetCharacter, "hammerheadLimbsAffliction", 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "hammerheadLimbsAffliction", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "hammerheadLimbsAegis")
			end
		end
		--Head, Grafting Removal.
		--Current List: LatcherTongue
	elseif (limbtype == LimbType.Head) then
		if (medicalLevel >= 30) then
			if (HF.HasAffliction(targetCharacter, "latcherTongueAffliction", 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "latcherTongueAffliction", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "latcherTongueAegis")
			end
		else
			local skillcheck = math.random(0, 30)
			if (skillcheck > medicalLevel) then
				HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 5, usingCharacter)
			elseif (HF.HasAffliction(targetCharacter, "latcherTongueAffliction", 1) and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "latcherTongueAffliction", 0, usingCharacter, 0)
				HF.GiveItem(usingCharacter, "latcherTongueAegis")
			end
		end
	end
end



local function IsTransplantReady(targetCharacter, removedIdentifier, swapIdentifier, limbtype)
	return limbtype == LimbType.Torso
		and (
			HF.HasAffliction(targetCharacter, removedIdentifier, 1)
			or HF.HasAffliction(targetCharacter, swapIdentifier, 1)
		)
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
end

local function IsGraftedOrganProcurementReady(targetCharacter, removedIdentifier, swapIdentifier)
	return HF.GetAfflictionStrength(targetCharacter, removedIdentifier, 0) <= 0
		and HF.GetAfflictionStrength(targetCharacter, swapIdentifier, 0) < 0.1
end

local function BeginGraftedOrganRemoval(
	targetCharacter,
	usingCharacter,
	limbtype,
	damageIdentifier,
	removedIdentifier,
	swapIdentifier,
	surgerySkill
)
	if HF.GetSurgerySkillRequirementMet(usingCharacter, surgerySkill) then
		if HF.GetAfflictionStrength(targetCharacter, damageIdentifier, 0) >= 100 then
			HF.SetAffliction(targetCharacter, removedIdentifier, 100, usingCharacter)
		else
			HF.SetAffliction(targetCharacter, swapIdentifier, 100, usingCharacter)
		end
	else
		HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 15, usingCharacter)
		HF.AddAfflictionLimb(targetCharacter, "organdamage", limbtype, 5, usingCharacter)
		HF.AddAffliction(targetCharacter, damageIdentifier, 20, usingCharacter)
	end

	HF.GiveItem(targetCharacter, "ntsfx_slash")
end

local function SpawnReplacedOrgan(item, transplantidentifier, targetCharacter, damage)
	if damage >= 90 then return end

	local parentInventory = item.ParentInventory
	local inventorySpot = nil
	if parentInventory then
		inventorySpot = parentInventory.FindIndex(item)
	end

	HF.SpawnItemPlusFunction(
		transplantidentifier,
		ApplyTransplantDonorData,
		GetTransplantDonorParams(targetCharacter, 100 - damage),
		parentInventory,
		inventorySpot
	)
	HF.RemoveItem(item)
end

local function ReturnReplacedOrgan(
	transplantidentifier,
	targetCharacter,
	damage,
	usingCharacter,
	parentInventory,
	inventorySpot
)
	if damage >= 90 then return end

	local params = GetTransplantDonorParams(targetCharacter, 100 - damage)
	if parentInventory ~= nil then
		HF.SpawnItemPlusFunction(
			transplantidentifier,
			ApplyTransplantDonorData,
			params,
			parentInventory,
			inventorySpot
		)
	else
		HF.GiveItemPlusFunction(transplantidentifier, ApplyTransplantDonorData, params, usingCharacter)
	end
end

local function ApplyGraftedOrganResult(
	targetCharacter,
	usingCharacter,
	graftIdentifier,
	cureRejection,
	rejection,
	aggressor
)
	HF.SetAffliction(targetCharacter, graftIdentifier, 100, usingCharacter)
	if HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49) then
		HF.AddAffliction(targetCharacter, "crossspeciesrejection", cureRejection, aggressor)
	else
		HF.AddAffliction(targetCharacter, "crossspeciesrejection", rejection, aggressor)
		HF.AddAffliction(targetCharacter, "sepsis", 3, aggressor)
	end
end

local function ApplyCrawlerLungsGraft(targetCharacter, usingCharacter)
	ApplyGraftedOrganResult(targetCharacter, usingCharacter, "crawlerLungsAffliction", 45, 70)
end

local function ApplyMudraptorLungsGraft(targetCharacter, usingCharacter)
	ApplyGraftedOrganResult(targetCharacter, usingCharacter, "mudraptorLungsAffliction", 50, 75)
end

local function ApplyHuskHeartGraft(targetCharacter, usingCharacter)
	ApplyGraftedOrganResult(targetCharacter, usingCharacter, "huskHeartAffliction", 75, 90)
end

local function ApplyLatcherHeartGraft(targetCharacter, usingCharacter)
	ApplyGraftedOrganResult(targetCharacter, usingCharacter, "latcherHeartAffliction", 75, 90)
end

local function ApplyMantisLiverGraft(targetCharacter, usingCharacter)
	ApplyGraftedOrganResult(targetCharacter, usingCharacter, "mantisLiverAffliction", 50, 75, usingCharacter)
end

local function ApplyBroodmotherLiverGraft(targetCharacter, usingCharacter)
	ApplyGraftedOrganResult(targetCharacter, usingCharacter, "broodmotherLiverAffliction", 50, 75, usingCharacter)
end

local function ApplyViperlingLiverGraft(targetCharacter, usingCharacter)
	ApplyGraftedOrganResult(targetCharacter, usingCharacter, "viperlingLiverAffliction", 50, 75, usingCharacter)
end

local function TransplantLungs(item, usingCharacter, targetCharacter, limb, applyGraft)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then conditionmodifier = -40 end

	local damage = HF.GetAfflictionStrength(targetCharacter, "lungdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if not IsTransplantReady(targetCharacter, "lungremoved", "lungswap", limbtype) then return false end

	local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Lungs")
	if damage == 100 then
		HF.AddAffliction(targetCharacter, "lungdamage", -workcondition, usingCharacter)
		HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
		HF.SetAffliction(targetCharacter, "lungremoved", 0, usingCharacter)
		HF.SetAffliction(targetCharacter, "lungswap", 0, usingCharacter)
		if applyGraft then applyGraft(targetCharacter, usingCharacter) end
		HF.RemoveItem(item)
	else
		local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
		HF.SetAffliction(targetCharacter, "lungdamage", 100 - workcondition, targetCharacter)
		HF.SetAffliction(targetCharacter, "lungremoved", 0, usingCharacter)
		HF.SetAffliction(targetCharacter, "lungswap", 0, usingCharacter)
		HF.SetAffliction(targetCharacter, "respiratoryarrest", 100, targetCharacter)
		HF.SetAffliction(targetCharacter, "pneumothorax", 0, targetCharacter)
		HF.SetAffliction(targetCharacter, "needlec", 0, targetCharacter)
		HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, targetCharacter)
		if applyGraft then applyGraft(targetCharacter, usingCharacter) end
		SpawnReplacedOrgan(item, transplantidentifier, targetCharacter, damage)
	end

	return true
end

local function TransplantHeart(item, usingCharacter, targetCharacter, limb, applyGraft)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then conditionmodifier = -40 end

	local damage = HF.GetAfflictionStrength(targetCharacter, "heartdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if not IsTransplantReady(targetCharacter, "heartremoved", "heartswap", limbtype) then return false end

	local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Heart")
	if damage == 100 then
		HF.AddAffliction(targetCharacter, "heartdamage", -workcondition, usingCharacter)
		HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
		HF.SetAffliction(targetCharacter, "heartremoved", 0, usingCharacter)
		HF.SetAffliction(targetCharacter, "heartswap", 0, usingCharacter)
		if applyGraft then applyGraft(targetCharacter, usingCharacter) end
		HF.RemoveItem(item)
	else
		local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
		HF.SetAffliction(targetCharacter, "heartdamage", 100 - workcondition, targetCharacter)
		HF.SetAffliction(targetCharacter, "heartremoved", 0, usingCharacter)
		HF.SetAffliction(targetCharacter, "heartswap", 0, usingCharacter)
		HF.SetAffliction(targetCharacter, "cardiacarrest", 100, targetCharacter)
		HF.SetAffliction(targetCharacter, "tamponade", 0, targetCharacter)
		HF.SetAffliction(targetCharacter, "heartattack", 0, targetCharacter)
		HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, targetCharacter)
		if applyGraft then applyGraft(targetCharacter, usingCharacter) end
		SpawnReplacedOrgan(item, transplantidentifier, targetCharacter, damage)
	end

	return true
end

local function TransplantLiver(item, usingCharacter, targetCharacter, limb, applyGraft)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then conditionmodifier = -40 end

	local damage = HF.GetAfflictionStrength(targetCharacter, "liverdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if not IsTransplantReady(targetCharacter, "liverremoved", "liverswap", limbtype) then return false end

	HF.AddAffliction(targetCharacter, "liverdamage", -workcondition, usingCharacter)
	local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Liver")
	if damage == 100 then
		HF.AddAffliction(targetCharacter, "liverdamage", -workcondition, usingCharacter)
		HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
		HF.SetAffliction(targetCharacter, "liverremoved", 0, usingCharacter)
		HF.SetAffliction(targetCharacter, "liverswap", 0, usingCharacter)
		if applyGraft then applyGraft(targetCharacter, usingCharacter) end
		HF.RemoveItem(item)
	else
		local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
		HF.SetAffliction(targetCharacter, "liverdamage", 100 - workcondition, usingCharacter)
		HF.SetAffliction(targetCharacter, "liverremoved", 0, usingCharacter)
		HF.SetAffliction(targetCharacter, "liverswap", 0, usingCharacter)
		HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)
		if applyGraft then applyGraft(targetCharacter, usingCharacter) end
		SpawnReplacedOrgan(item, transplantidentifier, targetCharacter, damage)
	end

	return true
end

local function ApplyOrganRejection(targetCharacter, usingCharacter, damageIdentifier)
	local rejectionchance = HF.Clamp(
		(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
		/ 150
		* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
		0,
		1
	)
	if HF.Chance(rejectionchance) and NTConfig.Get("NT_organRejection", false) then
		HF.SetAffliction(targetCharacter, damageIdentifier, 100)
	end
end

local function TransplantLungsOverride(item, usingCharacter, targetCharacter, limb)
	if TransplantLungs(item, usingCharacter, targetCharacter, limb) then
		ApplyOrganRejection(targetCharacter, usingCharacter, "lungdamage")
	end
end

local function TransplantHeartOverride(item, usingCharacter, targetCharacter, limb)
	if TransplantHeart(item, usingCharacter, targetCharacter, limb) then
		ApplyOrganRejection(targetCharacter, usingCharacter, "heartdamage")
	end
end

local function TransplantLiverOverride(item, usingCharacter, targetCharacter, limb)
	if TransplantLiver(item, usingCharacter, targetCharacter, limb) then
		ApplyOrganRejection(targetCharacter, usingCharacter, "liverdamage")
	end
end















local graftedOrganTransplantOverrides = {
	{
		method = "lungtransplant",
		graftMethod = TransplantLungsOverride,
		organ = "Lungs",
	},
	{
		method = "hearttransplant",
		graftMethod = TransplantHeartOverride,
		organ = "Heart",
	},
	{
		method = "livertransplant",
		graftMethod = TransplantLiverOverride,
		organ = "Liver",
	},
}

local function RemoveGraftedLungs(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type

	if limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1) then
		if IsGraftedOrganProcurementReady(targetCharacter, "lungremoved", "lungswap") then
			BeginGraftedOrganRemoval(
				targetCharacter,
				usingCharacter,
				limbtype,
				"lungdamage",
				"lungremoved",
				"lungswap",
				50
			)
		else -- organ extraction
			local damage = HF.GetAfflictionStrength(targetCharacter, "lungdamage", 0)
			if damage == 100 then
				return
			else
				HF.SetAffliction(targetCharacter, "lungdamage", 100, targetCharacter)
				HF.SetAffliction(targetCharacter, "lungremoved", 100, usingCharacter)
				HF.SetAffliction(targetCharacter, "lungswap", 0, usingCharacter)
				HF.SetAffliction(targetCharacter, "respiratoryarrest", 100, targetCharacter)

				HF.SetAffliction(targetCharacter, "pneumothorax", 0, targetCharacter)
				HF.SetAffliction(targetCharacter, "needlec", 0, targetCharacter)

				HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, targetCharacter)
				local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Lungs")
				if damage < 90 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					HF.GiveItemPlusFunction(
						transplantidentifier,
						ApplyTransplantDonorData,
						GetTransplantDonorParams(targetCharacter, 100 - damage),
						usingCharacter
					)
				end
			end
		end
	end
end




local function RemoveGraftedHeart(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type

	if limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1) then
		if IsGraftedOrganProcurementReady(targetCharacter, "heartremoved", "heartswap") then
			BeginGraftedOrganRemoval(
				targetCharacter,
				usingCharacter,
				limbtype,
				"heartdamage",
				"heartremoved",
				"heartswap",
				60
			)
		else -- organ extraction
			local damage = HF.GetAfflictionStrength(targetCharacter, "heartdamage", 0)
			if damage == 100 then
				return
			else
				HF.SetAffliction(targetCharacter, "heartdamage", 100, targetCharacter)
				HF.SetAffliction(targetCharacter, "heartremoved", 100, usingCharacter)
				HF.SetAffliction(targetCharacter, "heartswap", 0, usingCharacter)
				HF.SetAffliction(targetCharacter, "cardiacarrest", 100, targetCharacter)

				HF.SetAffliction(targetCharacter, "tamponade", 0, targetCharacter)
				HF.SetAffliction(targetCharacter, "heartattack", 0, targetCharacter)
				HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, targetCharacter)
				local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Heart")
				if damage < 90 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					HF.GiveItemPlusFunction(
						transplantidentifier,
						ApplyTransplantDonorData,
						GetTransplantDonorParams(targetCharacter, 100 - damage),
						usingCharacter
					)
				end
			end
		end
	end
end


local function RemoveGraftedLiver(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type

	if limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1) then
		if IsGraftedOrganProcurementReady(targetCharacter, "liverremoved", "liverswap") then
			BeginGraftedOrganRemoval(
				targetCharacter,
				usingCharacter,
				limbtype,
				"liverdamage",
				"liverremoved",
				"liverswap",
				40
			)
		else -- organ extraction
			local damage = HF.GetAfflictionStrength(targetCharacter, "liverdamage", 0)
			if damage == 100 then
				return
			elseif HF.GetSurgerySkillRequirementMet(usingCharacter, 50) then
				HF.SetAffliction(targetCharacter, "liverdamage", 100, usingCharacter)
				HF.SetAffliction(targetCharacter, "liverremoved", 100, usingCharacter)
				HF.SetAffliction(targetCharacter, "liverswap", 0, usingCharacter)

				HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, usingCharacter)
				local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Liver")
				if damage < 90 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					HF.GiveItemPlusFunction(
						transplantidentifier,
						ApplyTransplantDonorData,
						GetTransplantDonorParams(targetCharacter, 100 - damage),
						usingCharacter
					)
				end
			end
		end
	end
end




NT.ItemMethods.emptybloodpack = function(item, usingCharacter, targetCharacter, limb)
	if item.Condition <= 0 then
		return
	end

	if targetCharacter.Bloodloss <= 31 then
		local success = HF.GetSkillRequirementMet(usingCharacter, "medical", 30)
		local bloodlossinduced = 30
		if not success then
			bloodlossinduced = 40
		end

		local bloodtype = NT.GetBloodtype(targetCharacter)

		-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
		local function postSpawnFunc(args)
			local tags = {}

			if args.acidosis > 0 then
				table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
			elseif args.alkalosis > 0 then
				table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
			end
			if args.sepsis > 0 then
				table.insert(tags, "sepsis")
			end
			if args.paralysis > 0 then
				table.insert(tags, "paralysis")
			elseif args.acidburn > 0 then
				table.insert(tags, "acidburn")
			end


			local tagstring = ""
			for index, value in ipairs(tags) do
				tagstring = tagstring .. value
				if index < #tags then
					tagstring = tagstring .. ","
				end
			end

			args.item.Tags = tagstring
		end
		local params = {
			acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
			alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
			sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
			paralysis = HF.GetAfflictionStrength(targetCharacter, "mantisLiverAffliction"),
			acidburn = HF.GetAfflictionStrength(targetCharacter, "broodmotherLiverAffliction"),
		}

		-- move towards isotonic
		HF.SetAffliction(targetCharacter, "acidosis", HF.GetAfflictionStrength(targetCharacter, "acidosis", 0) * 0.9)
		HF.SetAffliction(targetCharacter, "alkalosis", HF.GetAfflictionStrength(targetCharacter, "alkalosis", 0) * 0.9)

		HF.AddAffliction(targetCharacter, "bloodloss", bloodlossinduced, usingCharacter)

		local bloodpackIdentifier = "bloodpack" .. bloodtype
		if bloodtype == "ominus" then
			bloodpackIdentifier = "antibloodloss2"
		end

		HF.GiveItemPlusFunction(bloodpackIdentifier, postSpawnFunc, params, usingCharacter)
		item.Condition = 0
		--HF.RemoveItem(item)
		HF.GiveItem(targetCharacter, "ntsfx_syringe")
	end
end




local function InfuseBloodpack(item, packtype, usingCharacter, targetCharacter, limb)
	-- determine compatibility
	local packhasantibodyA = string.find(packtype, "a")
	local packhasantibodyB = string.find(packtype, "b")
	local packhasantibodyC = string.find(packtype, "c") -- NT Cybernetics cyberblood
	local packhasantibodyRh = string.find(packtype, "plus")

	local targettype = NT.GetBloodtype(targetCharacter)

	local targethasantibodyA = string.find(targettype, "a")
	local targethasantibodyB = string.find(targettype, "b")
	local targethasantibodyC = string.find(targettype, "c")
	local targethasantibodyRh = string.find(targettype, "plus")

	local compatible = (targethasantibodyRh or not packhasantibodyRh)
		and (targethasantibodyA or not packhasantibodyA)
		and (targethasantibodyB or not packhasantibodyB)
		and (targethasantibodyC or not packhasantibodyC)
	-- TODO: give always true to team of bots on enemy submarines for future medic AI logic

	local bloodloss = HF.GetAfflictionStrength(targetCharacter, "bloodloss", 0)
	local usefulFraction = HF.Clamp(bloodloss / 30, 0, 1)

	if compatible then
		HF.AddAffliction(targetCharacter, "bloodloss", -30, usingCharacter)
		HF.AddAffliction(targetCharacter, "bloodpressure", 30, usingCharacter)
		HF.GiveSkillScaled(usingCharacter, "medical", 4000 * HF.BoolToNum(bloodloss > 100))
	else
		HF.AddAffliction(targetCharacter, "bloodloss", -20, usingCharacter)
		HF.AddAffliction(targetCharacter, "bloodpressure", 30, usingCharacter)
		HF.GiveSkillScaled(usingCharacter, "medical", 4000 * HF.BoolToNum(bloodloss > 100))
		local immunity = HF.GetAfflictionStrength(targetCharacter, "immunity", 100)
		HF.AddAffliction(targetCharacter, "hemotransfusionshock", math.max(immunity - 6, 0), usingCharacter)
	end

	-- move towards isotonic
	HF.SetAffliction(
		targetCharacter,
		"acidosis",
		HF.GetAfflictionStrength(targetCharacter, "acidosis", 0) * HF.Lerp(1, 0.9, usefulFraction)
	)
	HF.SetAffliction(
		targetCharacter,
		"alkalosis",
		HF.GetAfflictionStrength(targetCharacter, "alkalosis", 0) * HF.Lerp(1, 0.9, usefulFraction)
	)

	-- check if acidosis, alkalosis or sepsis
	local tags = HF.SplitString(item.Tags, ",")
	for tag in tags do
		if tag == "sepsis" then
			HF.AddAffliction(targetCharacter, "sepsis", 1, usingCharacter)
		elseif tag == "paralysis" then
			HF.AddAffliction(targetCharacter, "paralysis", 50, usingCharacter)
		elseif tag == "acidburn" then
			HF.AddAffliction(targetCharacter, "acidburn", 50, usingCharacter)
		end

		if HF.StartsWith(tag, "acid") then
			local split = HF.SplitString(tag, ":")
			if split[2] ~= nil then
				HF.AddAffliction(targetCharacter, "acidosis", tonumber(split[2]) / 5 * usefulFraction, usingCharacter)
			end
		elseif HF.StartsWith(tag, "alkal") then
			local split = HF.SplitString(tag, ":")
			if split[2] ~= nil then
				HF.AddAffliction(targetCharacter, "alkalosis", tonumber(split[2]) / 5 * usefulFraction, usingCharacter)
			end
		end
	end

	item.Condition = 0
	--HF.RemoveItem(item)
	HF.GiveItem(usingCharacter, "emptybloodpack")
	HF.GiveItem(targetCharacter, "ntsfx_syringe")
end








NT.ItemStartsWithMethods.bloodpack = function(item, usingCharacter, targetCharacter, limb)
	if item.Condition <= 0 then
		return
	end

	local identifier = item.Prefab.Identifier.Value
	local packtype = string.sub(identifier, string.len("bloodpack") + 1)
	InfuseBloodpack(item, packtype, usingCharacter, targetCharacter, limb)
end







-- CRAWLER TRANSPLANTS

NTGraft.ItemMethods.crawlerTailAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Torso then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "crawlerTailAegis", limbtype, 1)) then
		return
	elseif (HF.HasAfflictionLimb(targetCharacter, "tigerThresherTailAffliction", limbtype, 1)) then
		return
	end
	if (medicalLevel >= 70) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.SetAffliction(targetCharacter, "crawlerTailAegis", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 45, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.SetAffliction(targetCharacter, "crawlerTailAegis", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 70, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 70)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.SetAffliction(targetCharacter, "crawlerTailAegis", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 60, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "crawlerTailAegis", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 85, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end




NTGraft.ItemMethods.crawlerLungsAegis = function(item, usingCharacter, targetCharacter, limb)
	return TransplantLungs(item, usingCharacter, targetCharacter, limb, ApplyCrawlerLungsGraft)
end



-- FRACTAL GUARDIAN ITEMS



NTGraft.ItemMethods.fractalGuardianEyeAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if NTEYE ~= nil then return end

	if limbtype ~= LimbType.Head then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "fractalGuardianEyesAffliction", limbtype, 1))
		or HF.HasAfflictionLimb(targetCharacter, "watcherEyesAffliction", limbtype, 1) then
		return
	end
	if (medicalLevel >= 70) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.AddAfflictionLimb(targetCharacter, "fractalGuardianEyesAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 40, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.AddAfflictionLimb(targetCharacter, "fractalGuardianEyesAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 65, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 70)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.AddAfflictionLimb(targetCharacter, "fractalGuardianEyesAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 55, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.AddAfflictionLimb(targetCharacter, "fractalGuardianEyesAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 80, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end



-- HUSK ITEMS


NTGraft.ItemMethods.huskArmAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Torso then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "huskArmAffliction", limbtype, 1)) then
		return
	end
	if (medicalLevel >= 90) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.SetAffliction(targetCharacter, "huskArmAffliction", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 70, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.SetAffliction(targetCharacter, "huskArmAffliction", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 85, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 90)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.SetAffliction(targetCharacter, "huskArmAffliction", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 80, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "huskArmAffliction", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 100, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end






NTGraft.ItemMethods.huskHeartAegis = function(item, usingCharacter, targetCharacter, limb)
	return TransplantHeart(item, usingCharacter, targetCharacter, limb, ApplyHuskHeartGraft)
end


-- MANTIS ITEMS



NTGraft.ItemMethods.mantisLiverAegis = function(item, usingCharacter, targetCharacter, limb)
	return TransplantLiver(item, usingCharacter, targetCharacter, limb, ApplyMantisLiverGraft)
end


-- MUDRAPTOR ITEMS






NTGraft.ItemMethods.mudraptorLungsAegis = function(item, usingCharacter, targetCharacter, limb)
	return TransplantLungs(item, usingCharacter, targetCharacter, limb, ApplyMudraptorLungsGraft)
end



NTGraft.ItemMethods.mudraptorCellsAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Head then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "mudraptorHeadAffliction", limbtype, 1)) or HF.HasAfflictionLimb(targetCharacter, "molochHeadAffliction", limbtype, 1) then
		return
	end
	if (medicalLevel >= 70) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.AddAfflictionLimb(targetCharacter, "mudraptorHeadAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 40, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.AddAfflictionLimb(targetCharacter, "mudraptorHeadAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 65, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 70)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.AddAfflictionLimb(targetCharacter, "mudraptorHeadAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 55, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.AddAfflictionLimb(targetCharacter, "mudraptorHeadAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 80, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end



-- BROODMOTHER ITEMS




NTGraft.ItemMethods.broodmotherLiverAegis = function(item, usingCharacter, targetCharacter, limb)
	return TransplantLiver(item, usingCharacter, targetCharacter, limb, ApplyBroodmotherLiverGraft)
end


-- TIGER THRESHER ITEMS





NTGraft.ItemMethods.tigerThresherCellsAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Head then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "tigerThresherJawAffliction", limbtype, 1))
		or HF.HasAfflictionLimb(targetCharacter, "boneThresherJawAffliction", limbtype, 1)
		or HF.HasAfflictionLimb(targetCharacter, "charybdisJawAffliction", limbtype, 1)
		or HF.HasAffliction(targetCharacter, "latcherTongueAffliction", 1) then
		return
	end
	if (medicalLevel >= 70) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.AddAfflictionLimb(targetCharacter, "tigerThresherJawAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 40, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.AddAfflictionLimb(targetCharacter, "tigerThresherJawAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 65, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 70)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.AddAfflictionLimb(targetCharacter, "tigerThresherJawAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 55, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.AddAfflictionLimb(targetCharacter, "tigerThresherJawAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 80, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end


NTGraft.ItemMethods.tigerThresherTailAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Torso then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "crawlerTailAegis", limbtype, 1)) then
		return
	elseif (HF.HasAfflictionLimb(targetCharacter, "tigerThresherTailAffliction", limbtype, 1)) then
		return
	end
	if (medicalLevel >= 75) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.SetAffliction(targetCharacter, "tigerThresherTailAffliction", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.SetAffliction(targetCharacter, "tigerThresherTailAffliction", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 75)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.SetAffliction(targetCharacter, "tigerThresherTailAffliction", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 65, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "tigerThresherTailAffliction", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 90, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end




--BONE THRESHER ITEMS





NTGraft.ItemMethods.boneThresherCellsAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Head then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "tigerThresherJawAffliction", limbtype, 1))
		or HF.HasAfflictionLimb(targetCharacter, "boneThresherJawAffliction", limbtype, 1)
		or HF.HasAfflictionLimb(targetCharacter, "charybdisJawAffliction", limbtype, 1)
		or HF.HasAffliction(targetCharacter, "latcherTongueAffliction", 1) then
		return
	end
	if (medicalLevel >= 70) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.AddAfflictionLimb(targetCharacter, "boneThresherJawAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 40, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.AddAfflictionLimb(targetCharacter, "boneThresherJawAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 65, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 70)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.AddAfflictionLimb(targetCharacter, "boneThresherJawAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 55, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.AddAfflictionLimb(targetCharacter, "boneThresherJawAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 80, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end




--HAMMERHEAD ITEMS





NTGraft.ItemMethods.hammerheadCellsAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Torso then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "hammerTorsoAffliction", limbtype, 1))
		or HF.HasAfflictionLimb(targetCharacter, "endwormTorsoAffliction", limbtype, 1) then
		return
	end
	if (medicalLevel >= 70) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.AddAfflictionLimb(targetCharacter, "hammerheadTorsoAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.AddAfflictionLimb(targetCharacter, "hammerheadTorsoAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 70)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.AddAfflictionLimb(targetCharacter, "hammerheadTorsoAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 65, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.AddAfflictionLimb(targetCharacter, "hammerheadTorsoAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 90, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end


NTGraft.ItemMethods.hammerheadLimbsAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Torso then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (medicalLevel >= 70) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.SetAffliction(targetCharacter, "hammerheadLimbsAffliction", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.SetAffliction(targetCharacter, "hammerheadLimbsAffliction", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 70)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.SetAffliction(targetCharacter, "hammerheadLimbsAffliction", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 65, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "hammerheadLimbsAffliction", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 90, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end



--MOLOCH ITEMS


NTGraft.ItemMethods.molochCellsAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Head then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "molochHeadAffliction", limbtype, 1))
		or HF.HasAfflictionLimb(targetCharacter, "mudraptorHeadAffliction", limbtype, 1) then
		return
	end

	if (HF.HasAffliction(targetCharacter, "molochCracked", 95)) then
		if (medicalLevel >= 70) then
			if (HF.HasAffliction(targetCharacter, "retractedskin", 1)) then
				HF.SetAffliction(targetCharacter, "molochCracked", 20, usingCharacter)
				HF.SetAffliction(targetCharacter, "molochCrackedSprite", 0, usingCharacter)
				HF.AddAfflictionLimb(targetCharacter, "molochHeadAffliction", limbtype, 10, usingCharacter)
				HF.RemoveItem(item)
			end
		else
			local skillcheck = math.random(0, 70)
			if (medicalLevel >= skillcheck) then
				if (HF.HasAffliction(targetCharacter, "retractedskin", 1)) then
					HF.SetAffliction(targetCharacter, "molochCracked", 20, usingCharacter)
					HF.SetAffliction(targetCharacter, "molochCrackedSprite", 0, usingCharacter)
					HF.AddAfflictionLimb(targetCharacter, "molochHeadAffliction", limbtype, 10, usingCharacter)
					HF.RemoveItem(item)
				end
			else
				HF.AddAffliction(targetCharacter, "bleeding", 3, usingCharacter)
			end
		end
		return
	end
	if (medicalLevel >= 70) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.AddAfflictionLimb(targetCharacter, "molochHeadAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 60, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.AddAfflictionLimb(targetCharacter, "molochHeadAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 85, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 70)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.AddAfflictionLimb(targetCharacter, "molochHeadAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 80, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.AddAfflictionLimb(targetCharacter, "molochHeadAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 95, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end


--VIPERLING ITEMS








NTGraft.ItemMethods.viperlingLiverAegis = function(item, usingCharacter, targetCharacter, limb)
	return TransplantLiver(item, usingCharacter, targetCharacter, limb, ApplyViperlingLiverGraft)
end


--WATCHER ITEMS


NTGraft.ItemMethods.watcherEyeAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if NTEYE ~= nil then return end

	if limbtype ~= LimbType.Head then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "fractalGuardianEyesAffliction", limbtype, 1))
		or HF.HasAfflictionLimb(targetCharacter, "watcherEyesAffliction", limbtype, 1) then
		return
	end
	if (medicalLevel >= 80) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.AddAfflictionLimb(targetCharacter, "watcherEyesAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 70, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.AddAfflictionLimb(targetCharacter, "watcherEyesAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 95, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 80)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.AddAfflictionLimb(targetCharacter, "watcherEyesAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 80, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.AddAfflictionLimb(targetCharacter, "watcherEyesAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 95, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end



--CHARYBDIS ITEMS




NTGraft.ItemMethods.charybdisCellsAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Head then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "charybdisJawAffliction", limbtype, 1))
		or HF.HasAfflictionLimb(targetCharacter, "tigerThresherJawAffliction", limbtype, 1)
		or HF.HasAfflictionLimb(targetCharacter, "boneThresherJawAffliction", limbtype, 1)
		or HF.HasAffliction(targetCharacter, "latcherTongueAffliction", 1) then
		return
	end
	if (medicalLevel >= 90) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.AddAfflictionLimb(targetCharacter, "charybdisJawAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 80, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.AddAfflictionLimb(targetCharacter, "charybdisJawAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 95, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 90)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.AddAfflictionLimb(targetCharacter, "charybdisJawAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 85, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.AddAfflictionLimb(targetCharacter, "charybdisJawAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 100, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end





--LATCHER RELATED ITEMS



NTGraft.ItemMethods.latcherHeartAegis = function(item, usingCharacter, targetCharacter, limb)
	return TransplantHeart(item, usingCharacter, targetCharacter, limb, ApplyLatcherHeartGraft)
end


NTGraft.ItemMethods.latcherTongueAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Head then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "tigerThresherJawAffliction", limbtype, 1))
		or HF.HasAfflictionLimb(targetCharacter, "boneThresherJawAffliction", limbtype, 1)
		or HF.HasAfflictionLimb(targetCharacter, "charybdisJawAffliction", limbtype, 1)
		or HF.HasAffliction(targetCharacter, "latcherTongueAffliction", 1) then
		return
	end
	if (medicalLevel >= 90) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.SetAffliction(targetCharacter, "latcherTongueAffliction", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 80, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.SetAffliction(targetCharacter, "latcherTongueAffliction", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 95, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 90)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.SetAffliction(targetCharacter, "latcherTongueAffliction", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 85, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "latcherTongueAffliction", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 100, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end



-- ENDWORM RELATED ITEMS




NTGraft.ItemMethods.endwormCellsAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Torso then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "endwormTorsoAffliction", limbtype, 1))
		or HF.HasAfflictionLimb(targetCharacter, "hammerheadTorsoAffliction", limbtype, 1) then
		return
	end
	if (medicalLevel >= 90) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.AddAfflictionLimb(targetCharacter, "endwormTorsoAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 60, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.AddAfflictionLimb(targetCharacter, "endwormTorsoAffliction", limbtype, 10, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 85, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 90)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.AddAfflictionLimb(targetCharacter, "endwormTorsoAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 65, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.AddAfflictionLimb(targetCharacter, "endwormTorsoAffliction", limbtype, 10, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 90, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end


-- ORANGE BOY RELATED ITEMS

NTGraft.ItemMethods.orangeboyTailAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = HF.NormalizeLimbType(limb.type)

	if limbtype ~= LimbType.Torso then return end

	local medicalLevel = HF.GetSurgerySkill(usingCharacter)

	if (HF.HasAfflictionLimb(targetCharacter, "crawlerTailAegis", limbtype, 1)) then
		return
	elseif (HF.HasAfflictionLimb(targetCharacter, "tigerThresherTailAffliction", limbtype, 1)) then
		return
	elseif (HF.HasAfflictionLimb(targetCharacter, "orangeboyTailAffliction", limbtype, 1)) then
		return
	end
	if (medicalLevel >= 30) then
		if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99))) then
			HF.SetAffliction(targetCharacter, "orangeboyTailAffliction", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 30, usingCharacter, 0)
			HF.RemoveItem(item)
		elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
			HF.SetAffliction(targetCharacter, "orangeboyTailAffliction", 100, usingCharacter, 0)
			HF.AddAffliction(targetCharacter, "crossspeciesrejection", 45, usingCharacter, 0)
			HF.SetAffliction(targetCharacter, "sepsis", 3, usingCharacter, 0)
			HF.RemoveItem(item)
		end
	else
		local skillcheck = math.random(0, 30)
		if (medicalLevel >= skillcheck) then
			if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50) and (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1))) then
				HF.SetAffliction(targetCharacter, "orangeboyTailAffliction", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 40, usingCharacter, 0)
				HF.RemoveItem(item)
			elseif (HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
				HF.SetAffliction(targetCharacter, "orangeboyTailAffliction", 100, usingCharacter, 0)
				HF.AddAffliction(targetCharacter, "crossspeciesrejection", 55, usingCharacter, 0)
				HF.SetAffliction(targetCharacter, "sepsis", 5, usingCharacter, 0)
				HF.RemoveItem(item)
			end
		else
			HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
		end
	end
end

-- Capture the current base methods after other compatibility patches have loaded.
local graftedOrganScalpelOverrides = {
	{
		method = "organscalpel_lungs",
		graftMethod = RemoveGraftedLungs,
		organ = "Lungs",
	},
	{
		method = "organscalpel_heart",
		graftMethod = RemoveGraftedHeart,
		organ = "Heart",
	},
	{
		method = "organscalpel_liver",
		graftMethod = RemoveGraftedLiver,
		organ = "Liver",
	},
}

local function HasGraftedOrgan(character, organ)
	return GetGraftedOrganItem(character, organ) ~= nil
end

local function MakeGraftedOrganOverride(baseMethod, graftMethod, organ)
	return function(item, usingCharacter, targetCharacter, limb)
		if HasGraftedOrgan(targetCharacter, organ) then
			graftMethod(item, usingCharacter, targetCharacter, limb)
		else
			baseMethod(item, usingCharacter, targetCharacter, limb)
		end
	end
end

local graftedCyberOrganOverrides = {
	{ method = "augmentedlung", organ = "Lungs", organName = "lung" },
	{ method = "cyberlung", organ = "Lungs", organName = "lung" },
	{ method = "augmentedheart", organ = "Heart", organName = "heart" },
	{ method = "cyberheart", organ = "Heart", organName = "heart" },
	{ method = "augmentedliver", organ = "Liver", organName = "liver" },
	{ method = "cyberliver", organ = "Liver", organName = "liver" },
}

local function ApplyCyberOrganRejection(targetCharacter, usingCharacter, organName)
	local rejectionchance = HF.Clamp(
		(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
		/ 150
		* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
		0,
		1
	)
	if
		HF.Chance(rejectionchance)
		and NTConfig.Get("NT_organRejection", false)
		and not HF.HasAfflictionLimb(targetCharacter, "ntc_cyberkidney", LimbType.Torso, 0.1)
	then
		HF.AddAffliction(targetCharacter, organName .. "damage", 100, usingCharacter)
	end
end

local function ImplantGraftedCyberOrgan(item, usingCharacter, targetCharacter, limb, definition, organConfig)
	local limbtype = limb.type
	local removedIdentifier = organConfig.removedAffliction
	local swapIdentifier = organConfig.swapAffliction
	if
		not HF.HasAffliction(targetCharacter, removedIdentifier, 1)
		and not HF.HasAffliction(targetCharacter, swapIdentifier, 1)
	then
		return false
	end

	local conditionmodifier = 0
	if not HF.GetSkillRequirementMet(usingCharacter, organConfig.secondarySkillName, 60) then
		conditionmodifier = -20
	end
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	local damage = HF.GetAfflictionStrength(targetCharacter, organConfig.damageAffliction, 0)
	local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
	local parentInventory = item.ParentInventory
	local inventorySpot = nil
	if parentInventory then inventorySpot = parentInventory.FindIndex(item) end

	if HF.GetSurgerySkillRequirementMet(usingCharacter, 70) then
		HF.GiveSurgerySkill(usingCharacter, 0.4)
	else
		HF.AddAfflictionLimb(targetCharacter, "internalbleeding", limbtype, HF.RandomRange(0, 10))
		HF.GiveItem(targetCharacter, "ntsfx_slash")
	end

	local organName = definition.organName
	HF.SetAffliction(targetCharacter, organName .. "damage", 100 - workcondition, targetCharacter)
	HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)
	HF.SetAfflictionLimb(
		targetCharacter,
		organConfig.cyberAffliction,
		limbtype,
		string.find(item.Prefab.Identifier.Value, "augmented") and 50 or 100
	)
	for _, affliction in ipairs(organConfig.curedAfflictions) do
		HF.SetAffliction(targetCharacter, affliction, 0, usingCharacter)
	end
	HF.SetAffliction(targetCharacter, removedIdentifier, 0, usingCharacter)
	HF.SetAffliction(targetCharacter, swapIdentifier, 0, usingCharacter)
	HF.RemoveItem(item)

	local graftItemIdentifier = ClearGraftedOrgan(targetCharacter, usingCharacter, definition.organ)
	if graftItemIdentifier ~= nil then
		ReturnReplacedOrgan(
			graftItemIdentifier,
			targetCharacter,
			damage,
			usingCharacter,
			parentInventory,
			inventorySpot
		)
	end
	ApplyCyberOrganRejection(targetCharacter, usingCharacter, organName)
	return true
end

local function MakeGraftedCyberOrganOverride(baseMethod, definition)
	return function(item, usingCharacter, targetCharacter, limb)
		local organConfig = NTCyb.OrganConfigDatas[definition.organName]
		local graftData = GetGraftedOrganItem(targetCharacter, definition.organ)
		local isArtificial = string.find(item.Prefab.Identifier.Value, "cyber")
			or string.find(item.Prefab.Identifier.Value, "augmented")
		local patientHasArtificial = organConfig ~= nil
			and limb ~= nil
			and HF.HasAfflictionLimb(targetCharacter, organConfig.cyberAffliction, limb.type, 1)
		if organConfig == nil
			or graftData == nil
			or not isArtificial
			or patientHasArtificial
			or limb == nil
			or limb.type ~= organConfig.limb
			or not HF.HasAfflictionLimb(targetCharacter, "retractedskin", limb.type, 99)
		then
			baseMethod(item, usingCharacter, targetCharacter, limb)
			return
		end

		if not ImplantGraftedCyberOrgan(item, usingCharacter, targetCharacter, limb, definition, organConfig) then
			baseMethod(item, usingCharacter, targetCharacter, limb)
		end
	end
end

local function InstallGraftedCyberOrganOverrides(attempt)
	if NTCyb == nil or NTCyb.ItemMethods == nil or NTCyb.OrganConfigDatas == nil then return end
	if NTGraft.GraftedCyberOrganOverridesInstalled == true then return end

	local installed = NTGraft.GraftedCyberOrganOverrideMethods or {}
	local pending = false
	for _, definition in ipairs(graftedCyberOrganOverrides) do
		if not installed[definition.method] then
			local baseMethod = NTCyb.ItemMethods[definition.method]
			if baseMethod ~= nil then
				NTCyb.ItemMethods[definition.method] = MakeGraftedCyberOrganOverride(baseMethod, definition)
				installed[definition.method] = true
			else
				pending = true
			end
		end
	end

	NTGraft.GraftedCyberOrganOverrideMethods = installed
	if not pending then
		NTGraft.GraftedCyberOrganOverridesInstalled = true
	elseif attempt < 5 then
		Timer.Wait(function()
			InstallGraftedCyberOrganOverrides(attempt + 1)
		end, 1000)
	end
end

local function InstallGraftedOrganOverrides(definitions, methods, installedField, completeField, attempt)
	if NTGraft[completeField] == true then return end

	local installed = NTGraft[installedField] or {}
	local pending = false
	for _, definition in ipairs(definitions) do
		if not installed[definition.method] then
			local baseMethod = methods ~= nil and methods[definition.method] or nil
			if baseMethod ~= nil then
				methods[definition.method] = MakeGraftedOrganOverride(
					baseMethod,
					definition.graftMethod,
					definition.organ
				)
				installed[definition.method] = true
			else
				pending = true
			end
		end
	end

	NTGraft[installedField] = installed
	if not pending then
		NTGraft[completeField] = true
	elseif attempt < 5 then
		Timer.Wait(function()
			InstallGraftedOrganOverrides(definitions, methods, installedField, completeField, attempt + 1)
		end, 1000)
	end
end

Timer.Wait(function()
	InstallGraftedOrganOverrides(
		graftedOrganTransplantOverrides,
		NT.ItemStartsWithMethods,
		"GraftedOrganTransplantOverrideMethods",
		"GraftedOrganTransplantOverridesInstalled",
		1
	)
	InstallGraftedOrganOverrides(
		graftedOrganScalpelOverrides,
		NT.ItemMethods,
		"GraftedOrganScalpelOverrideMethods",
		"GraftedOrganScalpelOverridesInstalled",
		1
	)
	InstallGraftedCyberOrganOverrides(1)
end, 1000)
