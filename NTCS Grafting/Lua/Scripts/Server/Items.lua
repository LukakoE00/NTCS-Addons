local itemLoader = NTCS.ItemFunctionLoader("NTCS_Grafting")

-- ========================================================= GENERAL ITEMS =========================================================

-- Graft Cure
local GraftingCure = function (d)

  local usingCharacter = d.user.Human
  local targetCharacter = d.target.Human

  local medicalLevel = NTCS.HF.GetSkillLevel(usingCharacter, "medical")

  -- Skillcheck
  local overdose = 70
  if medicalLevel < 50 then
    overdose = medicalLevel >= math.random(0, 50) and 75 or 85
  end

  NTCS.HF.AddAffliction(targetCharacter, "graftingcureoverdose", overdose, usingCharacter)
  NTCS.HF.AddAffliction(targetCharacter, "crossspeciesrejection", -25, usingCharacter)
  NTCS.HF.RemoveItem(d.item)
end

itemLoader:Register("graftingcure", GraftingCure)

-- DNA Splicer
local DNASplicer = function (d)

  local usingCharacter = d.user.Human
  local targetCharacter = d.target.Human
  local limbtype = NTCS.HF.NormalizeLimbType(d.targetLimb.type)

  local medicalLevel = NTCS.HF.GetSurgerySkill(usingCharacter)

  -- Hammerhead / Endworm grafts resist
  local strength = 100
  if NTCS.HF.HasAfflictionLimb(targetCharacter, "grafting_HammerheadTorso", limbtype, 1) then
    strength = 66
  elseif NTCS.HF.HasAfflictionLimb(targetCharacter, "grafting_EndwormTorso", LimbType.Torso, 1) and limbtype ~= LimbType.Head then
    strength = 33
  end

  -- Skill check
  if medicalLevel < 50 and medicalLevel < math.random(0, 50) then
    strength = strength / 2
  end

  NTCS.HF.AddAfflictionLimb(targetCharacter, "alienDNARemoval", limbtype, strength, usingCharacter)
  NTCS.HF.RemoveItem(d.item)
end

itemLoader:Register("dnasplicer", DNASplicer)

-- Alien Scalpel
-- Graft Affliction ID (to cut) + Item ID (that it gives back)
local TorsoGraftRemovals = {
  { "grafting_OrangeboyTail", "grafting_OrangeboyTail" },
  { "grafting_CrawlerTail", "grafting_CrawlerTail" },
  { "grafting_TigerThresherTail", "grafting_TigerThresherTail" },
  { "grafting_HuskArm", "grafting_HuskArm" },
  { "grafting_HammerheadLimbs", "grafting_HammerheadLimbs" },
}

local HeadGraftRemovals = {
  { "grafting_LatcherTongue", "grafting_LatcherTongue" },
}

local AlienScalpel = function (d)

  local usingCharacter = d.user.Human
  local targetCharacter = d.target.Human
  local limbtype = NTCS.HF.NormalizeLimbType(d.targetLimb.type)

  -- Determine which grafts to check for depending on the selected limb + the damage we take on removing a graft.
  local GraftsToRemove, BleedAmount
  if limbtype == LimbType.Torso then
    GraftsToRemove, BleedAmount = TorsoGraftRemovals, 15
  elseif limbtype == LimbType.Head then
    GraftsToRemove, BleedAmount = HeadGraftRemovals, 5
  else
    return
  end

  -- Skill check
  local medicalLevel = NTCS.HF.GetSurgerySkill(usingCharacter)
  if medicalLevel < 30 and medicalLevel < math.random(0, 30) then
    NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, BleedAmount, usingCharacter)
    return
  end

  if not NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99) then return end

  -- If we have a graft present, remove it and return the respective item
  for _, Graft in ipairs(GraftsToRemove) do
    if NTCS.HF.HasAffliction(targetCharacter, Graft[1], 1) then
      NTCS.HF.SetAffliction(targetCharacter, Graft[1], 0, usingCharacter, 0)
      NTCS.HF.GiveItem(usingCharacter, Graft[2])
      return
    end
  end
end

itemLoader:Register("alienscalpel", AlienScalpel)

-- ========================================================= ACTUAL GRAFTS =========================================================

-- Moloch cells can also repair a cracked Moloch head.
local function MolochRepair(item, usingCharacter, targetCharacter, limbtype, medicalLevel)
  if not NTCS.HF.HasAffliction(targetCharacter, "grafting_MolochHeadCracked", 95) then return false end

  if medicalLevel >= 70 or medicalLevel >= math.random(0, 70) then
    if NTCS.HF.HasAffliction(targetCharacter, "retractedskin", 1) then
      NTCS.HF.SetAffliction(targetCharacter, "grafting_MolochHeadCracked", 20, usingCharacter)
      NTCS.HF.SetAffliction(targetCharacter, "grafting_MolochHeadCrackedSprite", 0, usingCharacter)
      NTCS.HF.AddAfflictionLimb(targetCharacter, "grafting_MolochHead", limbtype, 10, usingCharacter)
      NTCS.HF.RemoveItem(item)
    end
  else
    NTCS.HF.AddAffliction(targetCharacter, "bleeding", 3, usingCharacter)
  end

  return true
end

-- Every tissue graft item, keyed by item identifier.
--  LimbForGraft; limb the graft goes on
--  SkillRequired; surgery / medical skill needed to never fail
--  GraftAfflictionID; the affliction that gets applied
--  LimbSpecific; if true, apply above affliction to limb(s)
--  ConflictingGraftOnLimb; grafts that stop this one from getting applied, checked on the same limb
--  ConflictingGraftOnBody; " but checked anywhere on the body
--  ConflictWithEyes; these grafts dont work if NTCS Eyes is loaded
--  FuncBeforeGraft; optional function to run before graft logic (in this case for moloch repair)

--  RejectionAmount; amount of cross-species RejectionAmount added based on skillcheck math:
--  skilled + graftingcure, skilled, lucky + graftingcure, lucky }
--  'skilled' means passing the check via medskill, lucky means passing via random chance.
--  having graftingcureoverdose on a character makes it 'easier' to apply a graft and thus gives less sepsis

local TissueGrafts = {

  -- Crawler
  grafting_CrawlerTail = {
    LimbForGraft = LimbType.Torso,
    SkillRequired = 70,
    GraftAfflictionID = "grafting_CrawlerTail",
    LimbSpecific = false,
    ConflictingGraftOnLimb = { "grafting_CrawlerTail", "grafting_TigerThresherTail" },
    RejectionAmount = { 45, 70, 60, 85 },
  },

  -- Fractal Guardian
  Eye_FractalGuardian = {
    LimbForGraft = LimbType.Head,
    SkillRequired = 70,
    GraftAfflictionID = "grafting_FractalGuardianEyes",
    LimbSpecific = true,
    ConflictingGraftOnLimb = { "grafting_FractalGuardianEyes", "grafting_WatcherEyes" },
    ConflictWithEyes = true,
    RejectionAmount = { 40, 65, 55, 80 },
  },

  -- Husk
  grafting_HuskArm = {
    LimbForGraft = LimbType.Torso,
    SkillRequired = 90,
    GraftAfflictionID = "grafting_HuskArm",
    LimbSpecific = false,
    ConflictingGraftOnLimb = { "grafting_HuskArm" },
    RejectionAmount = { 70, 85, 80, 100 },
  },

  -- Mudraptor
  Cells_Mudraptor = {
    LimbForGraft = LimbType.Head,
    SkillRequired = 70,
    GraftAfflictionID = "grafting_MudraptorHead",
    LimbSpecific = true,
    ConflictingGraftOnLimb = { "grafting_MudraptorHead", "grafting_MolochHead" },
    RejectionAmount = { 40, 65, 55, 80 },
  },

  -- Tiger Thresher
  Cells_TigerThresher = {
    LimbForGraft = LimbType.Head,
    SkillRequired = 70,
    GraftAfflictionID = "grafting_TigerThresherJaw",
    LimbSpecific = true,
    ConflictingGraftOnLimb = { "grafting_TigerThresherJaw", "grafting_BoneThresherJaw", "grafting_CharybdisJaw" },
    ConflictingGraftOnBody = { "grafting_LatcherTongue" },
    RejectionAmount = { 40, 65, 55, 80 },
  },
  grafting_TigerThresherTail = {
    LimbForGraft = LimbType.Torso,
    SkillRequired = 75,
    GraftAfflictionID = "grafting_TigerThresherTail",
    LimbSpecific = false,
    ConflictingGraftOnLimb = { "grafting_CrawlerTail", "grafting_TigerThresherTail" },
    RejectionAmount = { 50, 75, 65, 90 },
  },

  -- Bone Thresher
  Cells_BoneThresher = {
    LimbForGraft = LimbType.Head,
    SkillRequired = 70,
    GraftAfflictionID = "grafting_BoneThresherJaw",
    LimbSpecific = true,
    ConflictingGraftOnLimb = { "grafting_TigerThresherJaw", "grafting_BoneThresherJaw", "grafting_CharybdisJaw" },
    ConflictingGraftOnBody = { "grafting_LatcherTongue" },
    RejectionAmount = { 40, 65, 55, 80 },
  },

  -- Hammerhead
  Cells_Hammerhead = {
    LimbForGraft = LimbType.Torso,
    SkillRequired = 70,
    GraftAfflictionID = "grafting_HammerheadTorso",
    LimbSpecific = true,
    ConflictingGraftOnLimb = { "grafting_HammerheadTorso", "grafting_EndwormTorso" },
    RejectionAmount = { 50, 75, 65, 90 },
  },
  grafting_HammerheadLimbs = {
    LimbForGraft = LimbType.Torso,
    SkillRequired = 70,
    GraftAfflictionID = "grafting_HammerheadLimbs",
    LimbSpecific = false,
    ConflictingGraftOnLimb = {},
    RejectionAmount = { 50, 75, 65, 90 },
  },

  -- Moloch
  Cells_Moloch = {
    LimbForGraft = LimbType.Head,
    SkillRequired = 70,
    GraftAfflictionID = "grafting_MolochHead",
    LimbSpecific = true,
    ConflictingGraftOnLimb = { "grafting_MolochHead", "grafting_MudraptorHead" },
    FuncBeforeGraft = MolochRepair,
    RejectionAmount = { 60, 85, 80, 95 },
  },

  -- Watcher
  Eye_Watcher = {
    LimbForGraft = LimbType.Head,
    SkillRequired = 80,
    GraftAfflictionID = "grafting_WatcherEyes",
    LimbSpecific = true,
    ConflictingGraftOnLimb = { "grafting_FractalGuardianEyes", "grafting_WatcherEyes" },
    ConflictWithEyes = true,
    RejectionAmount = { 70, 95, 80, 95 },
  },

  -- Charybdis
  Cells_Charybdis = {
    LimbForGraft = LimbType.Head,
    SkillRequired = 90,
    GraftAfflictionID = "grafting_CharybdisJaw",
    LimbSpecific = true,
    ConflictingGraftOnLimb = { "grafting_CharybdisJaw", "grafting_TigerThresherJaw", "grafting_BoneThresherJaw" },
    ConflictingGraftOnBody = { "grafting_LatcherTongue" },
    RejectionAmount = { 80, 95, 85, 100 },
  },

  -- Latcher
  grafting_LatcherTongue = {
    LimbForGraft = LimbType.Head,
    SkillRequired = 90,
    GraftAfflictionID = "grafting_LatcherTongue",
    LimbSpecific = false,
    ConflictingGraftOnLimb = { "grafting_TigerThresherJaw", "grafting_BoneThresherJaw", "grafting_CharybdisJaw" },
    ConflictingGraftOnBody = { "grafting_LatcherTongue" },
    RejectionAmount = { 80, 95, 85, 100 },
  },

  -- Endworm
  Cells_Endworm = {
    LimbForGraft = LimbType.Torso,
    SkillRequired = 90,
    GraftAfflictionID = "grafting_EndwormTorso",
    LimbSpecific = true,
    ConflictingGraftOnLimb = { "grafting_EndwormTorso", "grafting_HammerheadTorso" },
    RejectionAmount = { 60, 85, 65, 90 },
  },

  -- Orangeboy
  grafting_OrangeboyTail = {
    LimbForGraft = LimbType.Torso,
    SkillRequired = 30,
    GraftAfflictionID = "grafting_OrangeboyTail",
    LimbSpecific = false,
    ConflictingGraftOnLimb = { "grafting_CrawlerTail", "grafting_TigerThresherTail", "grafting_OrangeboyTail" },
    RejectionAmount = { 30, 45, 40, 55 },
  },
}

-- We are NOT adding 15 indiviual grafts like before. Dump info in a table then iterate it.
local function GraftTissue(d, GraftInfo)

  local item = d.item
  local usingCharacter = d.user.Human
  local targetCharacter = d.target.Human
  local limbtype = NTCS.HF.NormalizeLimbType(d.targetLimb.type)

  if limbtype ~= GraftInfo.LimbForGraft then return end
  if GraftInfo.ConflictWithEyes and NTCS_Eyes ~= nil then return end

  -- Already grafted, or a conflicting graft is present.
  for _, id in ipairs(GraftInfo.ConflictingGraftOnLimb) do
    if NTCS.HF.HasAfflictionLimb(targetCharacter, id, limbtype, 1) then return end
  end

  if GraftInfo.ConflictingGraftOnBody ~= nil then
    for _, id in ipairs(GraftInfo.ConflictingGraftOnBody) do
      if NTCS.HF.HasAffliction(targetCharacter, id, 1) then return end
    end
  end

  local medicalLevel = NTCS.HF.GetSurgerySkill(usingCharacter)

  if GraftInfo.FuncBeforeGraft ~= nil and GraftInfo.FuncBeforeGraft(item, usingCharacter, targetCharacter, limbtype, medicalLevel) then return end

  local overdosed = NTCS.HF.HasAffliction(targetCharacter, "graftingcureoverdose", 50)
  local RejectionAmount, sepsis

  -- NEVER FAIL!
  if medicalLevel >= GraftInfo.SkillRequired then
    if not NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99) then return end

    if overdosed then
      RejectionAmount = GraftInfo.RejectionAmount[1]
    else
      RejectionAmount, sepsis = GraftInfo.RejectionAmount[2], 3
    end
  else
    -- Gambling
    if medicalLevel < math.random(0, GraftInfo.SkillRequired) then
      NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
      return
    end

    if overdosed and NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1) then
      RejectionAmount = GraftInfo.RejectionAmount[3]
    elseif NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99) then
      RejectionAmount, sepsis = GraftInfo.RejectionAmount[4], 5
    else
      return
    end
  end

  if GraftInfo.LimbSpecific then
    NTCS.HF.AddAfflictionLimb(targetCharacter, GraftInfo.GraftAfflictionID, limbtype, 10, usingCharacter, 0)
  else
    NTCS.HF.SetAffliction(targetCharacter, GraftInfo.GraftAfflictionID, 100, usingCharacter, 0)
  end

  NTCS.HF.AddAffliction(targetCharacter, "crossspeciesrejection", RejectionAmount, usingCharacter, 0)
  if sepsis ~= nil then
    NTCS.HF.SetAffliction(targetCharacter, "sepsis", sepsis, usingCharacter, 0)
  end

  NTCS.HF.RemoveItem(item)
end

for ItemID, GraftInfo in pairs(TissueGrafts) do
  itemLoader:Register(ItemID, function (d) GraftTissue(d, GraftInfo) end)
end

-- ========================================================= ORGAN GRAFTS =========================================================

-- Shoot me
-- Which Graft Organs can replace a HUMAN organ
local OrganConfigs = {
  lung = {
    DamageAff = "lungdamage",
    RemovedAff = "lungremoved",
    SwapAff = "lungswap",
    SkillRequired = 50,
    AfflictionsToCure = { "pneumothorax", "needlec", "respiratoryarrest", "hyperventilation", "hypoventilation" },
    TransplantItem = "lungtransplant",
    ScalpelItem = "organscalpel_lungs",
    PossibleGrafts = {
      { affliction = "grafting_CrawlerLungs", item = "Lungs_Crawler", RejectionAmount = { 45, 70 } },
      { affliction = "grafting_MudraptorLungs", item = "Lungs_Mudraptor", RejectionAmount = { 50, 75 } },
    },
  },
 
  heart = {
    DamageAff = "heartdamage",
    RemovedAff = "heartremoved",
    SwapAff = "heartswap",
    SkillRequired = 60,
    AfflictionsToCure = { "tamponade", "heartattack", "cardiacarrest", "fibrillation", "tachycardia", "t_arterialcut" },
    TransplantItem = "hearttransplant",
    ScalpelItem = "organscalpel_heart",
    PossibleGrafts = {
      { affliction = "grafting_HuskHeart", item = "Heart_Husk", RejectionAmount = { 75, 90 } },
      { affliction = "grafting_LatcherHeart", item = "Heart_Latcher", RejectionAmount = { 75, 90 } },
    },
  },
 
  liver = {
    DamageAff = "liverdamage",
    RemovedAff = "liverremoved",
    SwapAff = "liverswap",
    SkillRequired = 40,
    AfflictionsToCure = {},
    TransplantItem = "livertransplant",
    ScalpelItem = "organscalpel_liver",
    PossibleGrafts = {
      { affliction = "grafting_MantisLiver", item = "Liver_Mantis", RejectionAmount = { 50, 75 } },
      { affliction = "grafting_BroodmotherLiver", item = "Liver_Broodmother", RejectionAmount = { 50, 75 } },
      { affliction = "grafting_ViperlingLiver", item = "Liver_Viperling", RejectionAmount = { 50, 75 } },
    },
  },
}
 
-- ORGAN SWAPPING FOR THE TORSO BABY
-- Is graft not nil? We're swapping a normal organ for a graft. Otherwise, it's the inverse.
local function ImplantOrgan(d, organ, graft)
 
  local item = d.item
  local usingCharacter = d.user.Human
  local targetCharacter = d.target.Human
  local limbtype = d.targetLimb.type
 
  -- Are we swapping / removing on the torso with skin retracted?
  if limbtype ~= LimbType.Torso
    or not NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
    or not (NTCS.HF.HasAffliction(targetCharacter, organ.RemovedAff, 1)
      or NTCS.HF.HasAffliction(targetCharacter, organ.SwapAff, 1))
  then
    return
  end
 
  -- Skill check
  local conditionmodifier = 0
  if not NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
    conditionmodifier = -40
  end
 
  local workcondition = NTCS.HF.Clamp(item.Condition + conditionmodifier, 0, 100)
  local damage = NTCS.HF.GetAfflictionStrength(targetCharacter, organ.DamageAff, 0)
 
  -- Return the organ we're swapping in for; either normal (+ surgery talent check) or a graft.
  local OrganToExtract
 
  -- Is it a graft?
  for _, existingGraft in ipairs(organ.PossibleGrafts) do
    if NTCS.HF.HasAffliction(targetCharacter, existingGraft.affliction, 1) then
      NTCS.HF.SetAffliction(targetCharacter, existingGraft.affliction, 0, usingCharacter)
      OrganToExtract = existingGraft.item
      break
    end
  end
 
  -- If not a graft at this point, it's a normal human ahh organ.
  if OrganToExtract == nil then
    -- HasTag requires a NTHuman instance. Convert the current Character to NTHuman beforehand.
    local NTHuman = NTCS.Human.getNTHumanFromCharacter(usingCharacter)
    -- HATE. I HATE SURGERY PLUS. HATE. HATE.
    if NTHuman ~= nil and NTHuman.Tags:HasTag("NTC", "organssellforfull") then
      OrganToExtract = organ.TransplantItem
    else
      OrganToExtract = organ.TransplantItem .. "_q1"
    end
  end
 
  NTCS.HF.RemoveItem(item)
 
  if damage == 100 then
    -- The old organ was already gone, so just heal.
    NTCS.HF.AddAffliction(targetCharacter, organ.DamageAff, -workcondition, usingCharacter)
    NTCS.HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
  else
    -- Swap the organs and their generic and specific organ damage and heal a lil bit.
    local newdamage = NTCS.HF.Clamp((100 - damage) - workcondition, -100, 100)
    NTCS.HF.SetAffliction(targetCharacter, organ.DamageAff, 100 - workcondition, usingCharacter)
    NTCS.HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)
 
    -- Organs that are too damaged aren't returned. Too bad!
    if damage < 90 then
 
      -- I know we DONT use this but otherwise ThousandFields will accuse me of tech debt.
      local function postSpawnFunc(args, spawnedItem)
        local tags = {}
 
        if args.acidosis > 0 then
          table.insert(tags, "acid:" .. tostring(NTCS.HF.Round(args.acidosis)))
        elseif args.alkalosis > 0 then
          table.insert(tags, "alkal:" .. tostring(NTCS.HF.Round(args.alkalosis)))
        end
        if args.sepsis > 10 then table.insert(tags, "sepsis") end
 
        spawnedItem.Tags = table.concat(tags, ",")
        spawnedItem.Condition = args.condition
      end
 
      local params = {
        acidosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "acidosis"),
        alkalosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
        sepsis = NTCS.HF.GetAfflictionStrength(targetCharacter, "sepsis"),
        condition = 100 - damage,
      }
 
      local pos = usingCharacter.WorldPosition
 
      -- Swapped organs go back into the inventory where the organ we just implanted was.
      local parentInventory = item.ParentInventory
      if parentInventory ~= nil then
        NTCS.HF.SpawnItemPlusFunction(OrganToExtract, parentInventory, InvSlotType.Any, pos, postSpawnFunc, params)
      else
        -- Otherwise, default to a handheld container.
        local container = usingCharacter.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
        if container == nil or container.OwnInventory == nil or container.OwnInventory.IsFull() then
          container = usingCharacter.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)
        end
 
        -- Just fucking throw it on the ground fuck you.
        if container ~= nil and container.OwnInventory ~= nil and not container.OwnInventory.IsFull() then
          NTCS.HF.SpawnItemPlusFunction(OrganToExtract, container.OwnInventory, InvSlotType.Any, pos, postSpawnFunc, params)
        else
          NTCS.HF.GiveItemPlusFunction(OrganToExtract, usingCharacter, postSpawnFunc, params)
        end
      end
    end
  end
 
  if graft ~= nil then
    NTCS.HF.SetAffliction(targetCharacter, graft.affliction, 100, usingCharacter)
 
    if NTCS.HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49) then
      NTCS.HF.AddAffliction(targetCharacter, "crossspeciesrejection", graft.RejectionAmount[1], usingCharacter)
    else
      NTCS.HF.AddAffliction(targetCharacter, "crossspeciesrejection", graft.RejectionAmount[2], usingCharacter)
      NTCS.HF.AddAffliction(targetCharacter, "sepsis", 3, usingCharacter)
    end
 
    -- Remove the afflictions that should be cured on swapped (cant have pneumothorax with a new set of lungs)
    for _, affliction in ipairs(organ.AfflictionsToCure) do
      NTCS.HF.SetAffliction(targetCharacter, affliction, 0, usingCharacter)
    end
  end
 
  -- Remove the Swap/Removed afflictions cause we're done baby.
  NTCS.HF.SetAffliction(targetCharacter, organ.RemovedAff, 0, usingCharacter)
  NTCS.HF.SetAffliction(targetCharacter, organ.SwapAff, 0, usingCharacter)
end
 
-- REMOVE THE DAMN ORGAN (no swapping!)
local function RemoveGraftedOrgan(d, organ)
 
  local usingCharacter = d.user.Human
  local targetCharacter = d.target.Human
  local limbtype = d.targetLimb.type
 
  -- Is it a graft?
  local existingGraft
  for _, graft in ipairs(organ.PossibleGrafts) do
    if NTCS.HF.HasAffliction(targetCharacter, graft.affliction, 1) then
      existingGraft = graft
      break
    end
  end
 
  -- Are we removing on the torso with skin retracted, so the swap started but organ not yet removed?
  local procureready = existingGraft ~= nil
    and limbtype == LimbType.Torso
    and NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1)
    and NTCS.HF.GetAfflictionStrength(targetCharacter, organ.RemovedAff, 0) <= 0
    and NTCS.HF.GetAfflictionStrength(targetCharacter, organ.SwapAff, 0) >= 0.1
 
  -- Not grafted or not ready yet: refer to original code.
  if not procureready then
    itemLoader:CallPrevious(organ.ScalpelItem, d)
    return
  end
 
  -- Skill check, do damage on failure.
  if not NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter, organ.SkillRequired) then
    NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 15, usingCharacter)
    NTCS.HF.AddAfflictionLimb(targetCharacter, "organdamage", limbtype, 5, usingCharacter)
    NTCS.HF.AddAffliction(targetCharacter, organ.DamageAff, 20, usingCharacter)
    return
  end
 
  local damage = NTCS.HF.GetAfflictionStrength(targetCharacter, organ.DamageAff, 0)
 
  -- Return the graft we're taking out and clear it.
  local OrganToExtract = existingGraft.item
  NTCS.HF.SetAffliction(targetCharacter, existingGraft.affliction, 0, usingCharacter)
 
  -- The organ is now removed, with nothing swapped in. Its slot is fully damaged.
  NTCS.HF.SetAffliction(targetCharacter, organ.RemovedAff, 100, usingCharacter)
  NTCS.HF.SetAffliction(targetCharacter, organ.SwapAff, 0, usingCharacter)
  NTCS.HF.SetAffliction(targetCharacter, organ.DamageAff, 100, usingCharacter)
 
  -- Remove the afflictions that should be cured on removal.
  for _, affliction in ipairs(organ.AfflictionsToCure) do
    NTCS.HF.SetAffliction(targetCharacter, affliction, 0, usingCharacter)
  end
 
  NTCS.HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, usingCharacter)
 
  -- Organs that are too damaged aren't returned. Too bad!
  if damage < 90 then
 
    local function postSpawnFunc(args, spawnedItem)
      local tags = {}
 
      if args.acidosis > 0 then
        table.insert(tags, "acid:" .. tostring(NTCS.HF.Round(args.acidosis)))
      elseif args.alkalosis > 0 then
        table.insert(tags, "alkal:" .. tostring(NTCS.HF.Round(args.alkalosis)))
      end
      if args.sepsis > 10 then table.insert(tags, "sepsis") end
 
      spawnedItem.Tags = table.concat(tags, ",")
      spawnedItem.Condition = args.condition
    end
 
    local params = {
      acidosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "acidosis"),
      alkalosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
      sepsis = NTCS.HF.GetAfflictionStrength(targetCharacter, "sepsis"),
      condition = 100 - damage,
    }
 
    local pos = usingCharacter.WorldPosition
 
    local container = usingCharacter.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
    if container == nil or container.OwnInventory == nil or container.OwnInventory.IsFull() then
      container = usingCharacter.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)
    end
 
    if container ~= nil and container.OwnInventory ~= nil and not container.OwnInventory.IsFull() then
      NTCS.HF.SpawnItemPlusFunction(OrganToExtract, container.OwnInventory, InvSlotType.Any, pos, postSpawnFunc, params)
    else
      NTCS.HF.GiveItemPlusFunction(OrganToExtract, usingCharacter, postSpawnFunc, params)
    end
  end
 
  NTCS.HF.GiveItem(targetCharacter, "ntsfx_slash")
end

-- REGISTERING TIME!
for _, organ in pairs(OrganConfigs) do

  -- Register organ grafts (we already did cells + limb grafts earlier)
  for _, graft in ipairs(organ.PossibleGrafts) do
    itemLoader:Register(graft.item, function (d) ImplantOrgan(d, organ, graft) end)
  end
 
  -- Add a check over the original swap code (i.e. lungtransplant) to deal with grafted organs.
  local NormalTransplant = function (d)
    local hasGraft = false

    for _, graft in ipairs(organ.PossibleGrafts) do
      if NTCS.HF.HasAffliction(d.target.Human, graft.affliction, 1) then
        hasGraft = true
        break
      end
    end
 
    if hasGraft then
      ImplantOrgan(d, organ, nil)
    else
      -- Cant call a specific ID since we're using a table. Grab the relative ID instead.
      itemLoader:CallPrevious(d.item.Prefab.Identifier.Value, d)
    end
  end
 
  -- Add the additional functionality to the respective organs.
  itemLoader:Override(organ.TransplantItem, NormalTransplant)
  itemLoader:Override(organ.TransplantItem .. "_q1", NormalTransplant)
 
  -- Also the specific organ scalpels.
  itemLoader:Override(organ.ScalpelItem, function (d) RemoveGraftedOrgan(d, organ) end)
end
 
-- ========================================================= BLOODPACKS =========================================================
 
-- Gotta add Mantis / Broodmother effects to blood packs too on draining of blood.
local EmptyBloodpack = function (d)
 
  local item = d.item
  local usingCharacter = d.user.Human
  local targetCharacter = d.target.Human
 
  if item.Condition <= 0 or targetCharacter.Bloodloss > 31 then return end
 
  local bloodlossinduced = 30
  if not NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", 30) then
    bloodlossinduced = 40
  end
 
  local bloodtype = NTCS.NTBloodTypes.GetBloodtype(targetCharacter)
 
  -- Add Acidosis / Alkalosis / Sepsis / Mantis / Broodmother effects into the tags of the pack.
  local function postSpawnFunc(args, spawnedItem)
    local tags = {}
 
    if args.acidosis > 0 then
      table.insert(tags, "acid:" .. tostring(NTCS.HF.Round(args.acidosis)))
    elseif args.alkalosis > 0 then
      table.insert(tags, "alkal:" .. tostring(NTCS.HF.Round(args.alkalosis)))
    end
    if args.sepsis > 0 then table.insert(tags, "sepsis") end
 
    if args.paralysis > 0 then
      table.insert(tags, "paralysis")
    elseif args.acidburn > 0 then
      table.insert(tags, "acidburn")
    end
 
    spawnedItem.Tags = table.concat(tags, ",")
  end
 
  local params = {
    acidosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "acidosis"),
    alkalosis = NTCS.HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
    sepsis = NTCS.HF.GetAfflictionStrength(targetCharacter, "sepsis"),
    paralysis = NTCS.HF.GetAfflictionStrength(targetCharacter, "grafting_MantisLiver"),
    acidburn = NTCS.HF.GetAfflictionStrength(targetCharacter, "grafting_BroodmotherLiver"),
  }
 
  -- Move towards isotonic.
  NTCS.HF.SetAffliction(targetCharacter, "acidosis", NTCS.HF.GetAfflictionStrength(targetCharacter, "acidosis", 0) * 0.9)
  NTCS.HF.SetAffliction(targetCharacter, "alkalosis", NTCS.HF.GetAfflictionStrength(targetCharacter, "alkalosis", 0) * 0.9)
 
  NTCS.HF.AddAffliction(targetCharacter, "bloodloss", bloodlossinduced, usingCharacter)
 
  local bloodpackIdentifier = "bloodpack" .. bloodtype
  if bloodtype == "o_negative" then
    bloodpackIdentifier = "antibloodloss2"
  end
 
  NTCS.HF.GiveItemPlusFunction(bloodpackIdentifier, usingCharacter, postSpawnFunc, params)
  item.Condition = 0
  NTCS.HF.GiveItem(targetCharacter, "ntsfx_syringe")
end
 
itemLoader:Override("emptybloodpack", EmptyBloodpack)
 
-- Add the mantis / broodmother effects then let the original function do the rest.
local function InfuseGraftBloodpack(d)
 
  local item = d.item
 
  if item.Condition > 0 then
    if item.HasTag("paralysis") then
      NTCS.HF.AddAffliction(d.target.Human, "paralysis", 50, d.user.Human)
    end
    if item.HasTag("acidburn") then
      NTCS.HF.AddAffliction(d.target.Human, "acidburn", 50, d.user.Human)
    end
  end
 
  itemLoader:CallPrevious(item.Prefab.Identifier.Value, d)
end
 
local BloodpackIds = {
  "bloodpacka_positive", "bloodpacka_negative",
  "bloodpackb_positive", "bloodpackb_negative",
  "bloodpackab_positive", "bloodpackab_negative",
  "bloodpacko_positive", "antibloodloss2",
  "bloodpackabc_positive", -- NT Cybernetics cyberblood
}
 
for _, id in ipairs(BloodpackIds) do
  itemLoader:Override(id, InfuseGraftBloodpack)
end

-- im so cooked vros
-- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢋⡔⢊⣥⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⣿⠘⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢛⣩⣭⣶⣶⣶⣶⣶⣶⣶⣬⣴⣦⣭⣭⣍⡛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢛⣡⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⣍⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢋⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣤⡙⠻⣿⣿⣿⣿⣿⣿⣿⣿⠿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⠃⡷⢉⣿⣿⣿⣿⣿⣿⡿⢋⣴⣿⣿⣿⣿⣿⣿⣿⣿⡏⢻⣿⣿⣿⣿⣿⣿⣿⣿⡅⢻⣿⣿⣿⣿⣿⣿⣿⣿⣧⡈⢿⣿⣿⣿⣿⣿⡁⠦⣹⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣴⣿⣿⣿⣿⠿⠿⠏⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢡⡘⣿⣿⣿⣿⣿⣿⣿⣿⣗⢀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⣬⣭⣭⣭⣉⣘⣛⠛⠿⠿⢿⣿
-- ⣿⡿⢛⠛⣩⣭⣭⣤⣶⣶⣶⣾⢃⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢡⣭⡇⢿⣿⣿⣿⣿⣿⣿⣿⡏⣼⣦⡈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣷⡘⡛⠻⠿⠿⠿⠿⠿⠇⢘⡄⢹
-- ⣿⢰⣾⣤⣉⣛⣛⣛⣛⣋⣭⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⣰⣿⣿⣿⢸⣿⣿⣿⣿⣿⣿⡟⣰⣿⣿⣿⣄⠹⣿⣿⣿⣿⣿⣿⣿⣿⣷⡘⢿⣿⣿⣷⣶⣿⣿⣿⣿⡈
-- ⣿⢸⣿⣿⣿⣿⣿⣿⣿⣿⠇⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⢋⣼⠿⠿⠿⢿⡆⣿⣿⣿⣿⣿⠟⣰⣟⣛⠿⠙⠛⠓⠌⠻⣿⣿⣿⣿⣿⣿⣿⣷⡘⣿⣿⣿⣿⣿⣿⣿⣿⢡
-- ⣿⢸⣿⣿⣿⣿⣿⣿⣿⡿⢰⡟⢹⣿⣿⣿⣿⣿⣿⠟⠁⢈⡁⠀⠈⣉⡑⢳⢸⣿⣿⣿⠏⣴⣿⣏⡄⣒⣭⣍⠒⢦⣄⡀⠙⠿⣿⣿⣿⣿⡃⡇⢻⣿⣿⣿⣿⣿⣿⣿⢸
-- ⣿⡀⣿⣿⣿⣿⣿⣿⣿⠃⣿⠇⣾⣿⣿⣿⣿⡟⠉⣠⡶⢋⣴⢞⡳⣄⠙⣿⢨⣿⡿⢋⣼⣿⣿⡏⣴⠏⣵⡌⣷⡄⢻⣿⣆⠐⢈⠻⢿⣿⣇⠸⠸⣿⣿⣿⣿⡿⠟⢁⣾
-- ⣿⣷⣌⡛⠿⠿⠿⠿⠟⡁⡟⢠⣿⣿⣿⠿⠋⠀⣴⣿⠃⣻⣇⢞⢫⢸⠇⣿⢸⠋⣠⣾⣿⣿⣿⣧⠉⢻⣆⣒⣸⠏⣸⣿⣿⡆⣼⣿⣦⡍⠻⢧⡀⢶⣶⣤⡄⢀⢺⣿⣿
-- ⡿⢙⢿⢡⡀⠶⠿⠟⢛⠂⢠⣿⡿⠟⣡⣶⡆⢼⣿⣿⣦⡙⠟⣛⣀⣭⣬⣍⣠⣾⣿⡛⣿⣿⣿⣿⣿⣶⣶⣮⣥⡤⢟⡛⢽⠃⣿⣿⣿⣿⠁⢰⢀⡀⠲⣶⣶⣾⢸⣿⣿
-- ⣷⣦⣿⢸⣿⣿⣿⣿⡟⠠⢛⠉⢰⣿⣿⣿⣇⢸⣷⠭⠕⢘⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣔⣂⡜⣨⣿⣿⣿⡏⠀⡌⣼⣿⣿⣿⣿⣿⢸⣿⣿
-- ⣿⣿⣿⠸⣿⣿⣿⣿⣷⡦⢹⡆⠀⣿⣿⣿⣿⡈⣿⣧⣦⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⣿⣿⣿⣿⣿⢟⣿⣿⣿⣿⣿⢁⣿⣿⣿⣿⠁⠀⡀⠭⣉⣛⡛⠛⣉⣼⣿⣿
-- ⣿⣿⣿⣶⡆⠉⠭⠥⠖⣂⡄⡑⠀⠸⣿⣿⣿⣇⠸⣿⣿⣿⣿⣿⣿⣝⣛⣻⣭⣵⣶⣿⣿⣶⣶⣶⣶⣶⣿⣿⣿⣿⣿⢃⣼⣿⣿⣿⠇⣴⡇⢿⣶⣶⣬⣥⠆⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣧⢹⣿⣿⣿⡿⠃⣿⣦⠀⢻⣿⣿⣿⣆⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⣾⣿⣿⣿⠏⣼⣿⣷⡬⢉⣉⣉⠉⣴⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣶⢠⣶⣦⡐⢺⣿⣿⣧⡄⢝⣛⠿⠿⠆⠻⣿⣿⣿⣿⣿⡿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⣿⣿⣿⡏⣰⣿⣿⣿⣆⠻⠟⢋⣴⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⠶⢈⡙⢁⣾⣿⣿⣿⣿⡄⢿⣿⣿⣿⠀⠰⣶⣶⣶⣶⣦⣭⣥⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡿⢨⣿⣿⠏⣴⣿⣿⣿⣿⣿⣦⣙⣠⣽⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣶⣶⣶⣿⣿⣿⣿⣿⣿⣷⡌⢿⣿⣿⡀⠀⠬⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠇⣾⣿⠋⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠻⣿⡇⢸⣷⣬⣙⡛⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⢩⡔⣸⠛⡡⣸⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⠙⣿⡌⣿⣿⣿⡇⠰⣤⡀⢤⣉⣉⣉⣉⡩⢀⣴⡿⠀⠸⠐⣡⣾⢣⣿⠀⣮⡻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢋⣶⣌⠳⠘⣿⣿⡇⡀⢻⣿⡷⢂⡉⠋⣄⣚⡻⢿⠃⡄⣡⣾⣿⡏⠾⢁⣼⣿⣿⠊⠍⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⡣⢿⣿⣿⣷⡄⠹⣿⣿⠰⡄⢋⣾⣿⡇⠷⢻⣿⣿⠦⠐⠸⢿⣿⣿⢣⣶⣿⣿⣿⣿⣦⣀⡀⡙⣿⣿⣿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⣰⣿⣿⣿⣿⡔⢿⡇⣂⣡⡶⢸⣿⣇⣄⢸⣿⣇⠚⣋⣙⢃⡿⠁⣿⣿⣿⣿⣿⣿⣿⣿⠣⣹⣿⣿⣿⣿⣿⣿⣿⣿⣿
-- ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡑⠱⣾⣿⣿⣿⣿⣿⣿⡆⠙⢬⣭⣵⣿⣿⡆⠀⢸⣿⣿⣷⣶⣶⠞⣱⡇⠹⣿⣿⣿⣿⣿⡿⠃⣱⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿