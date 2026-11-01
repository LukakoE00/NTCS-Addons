local AfflictionLoader = NTCS.AfflictionsLoader("NTCS Grafting")
local AfflictionBuilder = NTCS.AfflictionPrefabBuilder()

-- Groups of grafts since you cant have more than 2 unique graft groups
local GraftingTypes = {

  -- Crawler
  { "grafting_CrawlerTail", "grafting_CrawlerLungs" },

  -- Eyes
  { "grafting_FractalGuardianEyes", "grafting_WatcherEyes" },

  -- Husk
  { "grafting_HuskArm", "grafting_HuskHeart" },

  -- Latcher
  { "grafting_LatcherHeart", "grafting_LatcherTongue" },

  -- Liver
  { "grafting_MantisLiver", "grafting_BroodmotherLiver", "grafting_ViperlingLiver" },

  -- Mudraptor
  { "grafting_MudraptorLungs", "grafting_MudraptorHead" },

  -- Tiger Thresher
  { "grafting_TigerThresherJaw", "grafting_TigerThresherTail" },

  -- Jaw
  { "grafting_BoneThresherJaw", "grafting_CharybdisJaw" },

  -- Hammerhead
  { "grafting_HammerheadTorso", "grafting_HammerheadLimbs" },

  -- Endworm
  { "grafting_EndwormTorso", "grafting_EndwormLeftArm", "grafting_EndwormRightArm",
    "grafting_EndwormLeftLeg", "grafting_EndwormRightLeg" },

  -- Moloch
  { "grafting_MolochHead", "grafting_MolochHeadCracked" },

  -- Orang
  { "grafting_OrangeboyTail" },
}

local function CountGrafts(Character)
  local Count = 0
  for g = 1, #GraftingTypes do
    local Row = GraftingTypes[g]
    for k = 1, #Row do
      if NTCS.HF.HasAffliction(Character, Row[k], 1) then
        Count = Count + 1
        break
      end
    end
  end
  return Count
end

local HybridDNA = AfflictionBuilder:New("hybriddna"):SetUpdateAction(
  function(C, Identifier, Limb, DeltaT)

    local Character = C.Human
    if not NTCS.HF.HasAffliction(Character, "crossspeciesrejection", 1) then return end

    local Strength = C:GetAfflictionStrength("hybriddna")

    C:SetAffliction("hybriddna", CountGrafts(Character))

    if Strength < 2 or NTCS.HF.HasTalent(Character, "hackeddna") then return end

    -- Strength >= 3: always. Strength >= 2: only without the tolerant talent.
    if Strength >= 3 or not NTCS.HF.HasTalent(Character, "tolerantdna") then
      NTCS.HF.SetAffliction(Character, "crossspeciesrejection", 100)
      NTCS.HF.SetAffliction(Character, "hybriddnakiller", 100)
    end

  end):Build()

AfflictionLoader:Register(HybridDNA)

-- ========================================================= LIMB LOCKING =========================================================
-- Probably works? I fucking hate these vro
local LockedHands = AfflictionBuilder:New("lockedhands")
  :IsConst(true)
  :SetUpdateAction(
  function(C, Identifier, Limb, DeltaT)

    local Character = C.Human

    local LeftHandItem = NTCS.HF.GetItemInLeftHand(Character)
    local RightHandItem = NTCS.HF.GetItemInRightHand(Character)

    local LeftLockItem = LeftHandItem
    if LeftLockItem == nil or LeftLockItem.Prefab.Identifier.Value ~= "armlock" then
      LeftLockItem = nil
    end

    local RightLockItem = RightHandItem
    if RightLockItem == nil or RightLockItem.Prefab.Identifier.Value ~= "armlock" then
      RightLockItem = nil
    end

    -- Handcuffs check
    local Handcuffs = Character.Inventory.FindItemByIdentifier("handcuffs", false)
    local Handcuffed = Handcuffs ~= nil and Character.Inventory.FindIndex(Handcuffs) <= 6

    -- Husk Heart makes you immune to arm locks (unless handcuffed).
    if not Handcuffed and NTCS.HF.HasAffliction(Character, "grafting_HuskHeart", 5) then
      if LeftLockItem then NTCS.HF.RemoveItem(LeftLockItem) end
      if RightLockItem then NTCS.HF.RemoveItem(RightLockItem) end
      C:SetAffliction(Identifier, 0)
      return
    end

    if Handcuffed then
      -- Drop non-handcuff items
      if LeftHandItem ~= nil and LeftHandItem ~= Handcuffs and LeftLockItem == nil then
        LeftHandItem.Drop(Character)
      end
      if RightHandItem ~= nil and RightHandItem ~= Handcuffs and RightLockItem == nil then
        RightHandItem.Drop(Character)
      end
    end

    local WantLeft = C:GetBoolStat("lockleftarm")
    local WantRight = C:GetBoolStat("lockrightarm")

    local LeftArmLocked = LeftLockItem ~= nil and not Handcuffed
    local RightArmLocked = RightLockItem ~= nil and not Handcuffed

    if LeftArmLocked and not WantLeft then
      NTCS.HF.RemoveItem(LeftLockItem)
    end
    if RightArmLocked and not WantRight then
      NTCS.HF.RemoveItem(RightLockItem)
    end

    if not LeftArmLocked and WantLeft then
      NTCS.HF.ForceArmLock(Character, "LeftArm")
    end
    if not RightArmLocked and WantRight then
      NTCS.HF.ForceArmLock(Character, "RightArm")
    end

    C:SetAffliction(Identifier, NTCS.HF.BoolToNum((WantLeft and WantRight) or Handcuffed, 100))

  end):Build()

AfflictionLoader:Override(LockedHands)

-- ========================================================= HAMMERHEAD =========================================================
-- :drool:
local function IsUnclothed(Character)
  local Inventory = Character.Inventory
  return Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes) == nil
    and Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes) == nil
end

local function SetSprite(Character, Sprite, Show)
  NTCS.HF.SetAffliction(Character, Sprite, Show and 100 or 0)
end

local HammerheadTorso = AfflictionBuilder:New("grafting_HammerheadTorso")
  :IsConst(true)
  :SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    local Character = C.Human
    SetSprite(Character, "grafting_HammerheadTorsoSprite", C:GetAfflictionStrength("grafting_HammerheadTorso") > 10 and IsUnclothed(Character))

  end):Build()

AfflictionLoader:Register(HammerheadTorso)

local function RefreshTorsoSprite(Item, Character)
  if NTCS.HF.HasAfflictionLimb(Character, "grafting_HammerheadTorso", LimbType.Torso, 5) then
    SetSprite(Character, "grafting_HammerheadTorsoSprite", IsUnclothed(Character))
  elseif NTCS.HF.HasAfflictionLimb(Character, "grafting_EndwormTorso", LimbType.Torso, 5) then
    SetSprite(Character, "grafting_EndwormTorsoSprite", IsUnclothed(Character))
  end
end

Hook.Add("item.equip", "graftedTorsoFixEquip", RefreshTorsoSprite)
Hook.Add("item.unequip", "graftedTorsoFixUnequip", RefreshTorsoSprite)

-- ========================================================= MOLOCH =========================================================
-- moloch head
-- moloch head
local MolochHead = AfflictionBuilder:New("grafting_MolochHead"):SetUpdateAction(
  function(C, Identifier, Limb, DeltaT)

    if C:GetAfflictionStrength("grafting_MolochHead") <= 0 then return end

    local Character = C.Human
    local Head = LimbType.Head

    local Blunt = NTCS.HF.GetAfflictionStrengthLimb(Character, Head, "blunttrauma", 0)
    local Lacerations = NTCS.HF.GetAfflictionStrengthLimb(Character, Head, "lacerations", 0)
    local Gunshot = NTCS.HF.GetAfflictionStrengthLimb(Character, Head, "gunshotwound", 0)

    if Blunt >= 40 or Lacerations >= 40 or Gunshot >= 40 then
      NTCS.HF.AddAffliction(Character, "grafting_MolochHeadCracked", 1.5)
    elseif Blunt >= 4 or Lacerations >= 4 or Gunshot >= 7 then
      NTCS.HF.AddAffliction(Character, "grafting_MolochHeadCracked", 0.5)
    end

  end):Build()

AfflictionLoader:Register(MolochHead)

-- ========================================================= ENDWORM =========================================================

-- TODO: fold afflictions
local EndwormLimbs = {
  { LimbType.LeftArm,  "grafting_EndwormLeftArm",  "ntc_cyberarm" },
  { LimbType.RightArm, "grafting_EndwormRightArm", "ntc_cyberarm" },
  { LimbType.LeftLeg,  "grafting_EndwormLeftLeg",  "ntc_cyberleg" },
  { LimbType.RightLeg, "grafting_EndwormRightLeg", "ntc_cyberleg" },
}

local EndwormTorso = AfflictionBuilder:New("grafting_EndwormTorso"):SetUpdateAction(
  function(C, Identifier, Limb, DeltaT)

    local Character = C.Human

    if C:GetAfflictionStrength("grafting_EndwormTorso") <= 10 then
      SetSprite(Character, "grafting_EndwormTorsoSprite", false)
      return
    end

    if NTCS.HF.HasAfflictionLimb(Character, "grafting_EndwormTorso", LimbType.Torso, 90) then
      local HasCyber = NTCS_Cybernetics ~= nil
      for n = 1, #EndwormLimbs do
        local Entry = EndwormLimbs[n]
        if not (HasCyber and NTCS.HF.HasAfflictionLimb(Character, Entry[3], Entry[1], 1)) then
          NTCS.HF.AddAfflictionLimb(Character, Entry[2], Entry[1], 1)
        end
      end
    end

    SetSprite(Character, "grafting_EndwormTorsoSprite", IsUnclothed(Character))

  end):Build()

AfflictionLoader:Register(EndwormTorso)

-- ========================================================= ORANG BOY =========================================================

math.randomseed(os.time())

local OrangeboyTail = AfflictionBuilder:New("grafting_OrangeboyTail"):SetUpdateAction(
  function(C, Identifier, Limb, DeltaT)

    if C:GetAfflictionStrength("grafting_OrangeboyTail") > 1 and math.random(0, 1250) <= 3 then
      NTCS.HF.GiveItem(C.Human, "chitin")
    end

  end):Build()

AfflictionLoader:Register(OrangeboyTail)