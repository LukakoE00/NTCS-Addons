---@diagnostic disable: undefined-global

-- Grafting Types is a table containing our possible grafts, each row has a 'parent' graft and it's alternatives.
-- If one graft is identified from a table then it skips the rest and moves onto the next row.
local GraftingTypes = {
  { "crawlerTailAegis", "crawlerLungsAffliction" }, -- Crawler
  { "fractalGuardianEyesAffliction", "watcherEyesAffliction" }, -- Eyes
  { "huskArmAffliction", "huskHeartAffliction" }, -- Husk
  { "latcherHeartAffliction", "latcherTongueAffliction" }, -- Latcher
  { "mantisLiverAffliction", "broodmotherLiverAffliction", "viperlingLiverAffliction" }, -- Liver
  { "mudraptorLungsAffliction", "mudraptorHeadAffliction" }, -- Mudraptor
  { "tigerThresherJawAffliction", "tigerThresherTailAffliction" }, -- Tiger Thresher
  { "boneThresherJawAffliction", "charybdisJawAffliction" }, -- Jaw
  { "hammerheadTorsoAffliction", "hammerheadLimbsAffliction" }, -- Hammerhead
  {
    "endwormTorsoAffliction",
    "endwormLArmAffliction",
    "endwormRArmAffliction",
    "endwormLLegAffliction",
    "endwormRLegAffliction",
  }, -- Endworm
  { "molochHeadAffliction", "molochCracked" }, -- Moloch
  { "orangeboyTailAffliction" }, -- Tail?
}

local function CountHybridGrafts(character)
  local creatures = 0

  for _, graftGroup in ipairs(GraftingTypes) do
    for graftIndex = 1, #graftGroup do
      if HF.HasAffliction(character, graftGroup[graftIndex], 1) then
        creatures = creatures + 1
        break -- Incase we do have the affliction we break and move onto the next graft type. Keeps the old functionality.
      end
    end
  end

  return creatures
end

NT.Afflictions.hybriddna = {
  update = function(c, i)
    local character = c.character

    -- Hacked DNA bypasses the rejection and kill effects entirely.
    if HF.HasTalent(character, "hackeddna") then return end

    -- Recalculate while rejection or DNA Ligation Enhancer overdose is active.
    local active = HF.HasAffliction(character, "crossspeciesrejection", 1)
      or HF.HasAffliction(character, "graftingcureoverdose", 1)
    if active then
      local creatures = CountHybridGrafts(character)
      if c.afflictions[i].strength ~= creatures then
        HF.SetAffliction(character, "hybriddna", creatures)
      end

      local hybridDnaStrength = c.afflictions[i].strength
      -- Tolerant DNA prevents the kill effect at 2 strength, but not at 3 strength.
      if (hybridDnaStrength >= 2 and not HF.HasTalent(character, "tolerantdna")) or hybridDnaStrength >= 3 then
        if HF.GetAfflictionStrength(character, "crossspeciesrejection", 0) < 100 then
          HF.SetAffliction(character, "crossspeciesrejection", 100)
        end
        if HF.GetAfflictionStrength(character, "hybriddnakiller", 0) < 10 then
          HF.SetAffliction(character, "hybriddnakiller", 100)
        end
      end
    end
  end
}



function limbLockedInitialAegis(c, limbtype, key)
	local character = c.character

	-- A developed husk heart prevents normal limb-lock conditions.
	if HF.HasAffliction(character, "huskHeartAffliction", 5) then
		return false
	end

	return not NTC.GetSymptomFalse(character, key)
		and (
			NTC.GetSymptom(character, key)
			or c.afflictions.t_paralysis.strength > 0
			or NT.LimbIsAmputated(character, limbtype)
			or (HF.GetAfflictionStrengthLimb(character, limbtype, "bandaged", 0) <= 0 and HF.GetAfflictionStrengthLimb(
				character,
				limbtype,
				"dirtybandage",
				0
			) <= 0 and NT.LimbIsDislocated(character, limbtype))
			or (
				HF.GetAfflictionStrengthLimb(character, limbtype, "gypsumcast", 0) <= 0
				and NT.LimbIsBroken(character, limbtype)
			)
		)
end



NT.Afflictions.lockedhands = {
  update = function(c, i)
    local character = c.character
    local hasHuskHeart = HF.HasAffliction(character, "huskHeartAffliction", 5)
    local inventory = character.Inventory

    local leftLockItem = inventory.FindItemByIdentifier("armlock2", false)
    local rightLockItem = inventory.FindItemByIdentifier("armlock1", false)
    local handcuffs = inventory.FindItemByIdentifier("handcuffs", false)
    local handcuffed = handcuffs ~= nil and inventory.FindIndex(handcuffs) <= 6

    -- Husk heart removes artificial locks, but handcuffs still take priority.
    if hasHuskHeart and not handcuffed then
      if leftLockItem ~= nil then HF.RemoveItem(leftLockItem) end
      if rightLockItem ~= nil then HF.RemoveItem(rightLockItem) end
      return
    end

    if handcuffed then
      -- Drop non-handcuff items only when the corresponding lock is absent.
      if leftLockItem == nil then
        local leftHandItem = HF.GetItemInLeftHand(character)
        if leftHandItem ~= nil and leftHandItem ~= handcuffs then
          leftHandItem.Drop(character)
        end
      end
      if rightLockItem == nil then
        local rightHandItem = HF.GetItemInRightHand(character)
        if rightHandItem ~= nil and rightHandItem ~= handcuffs then
          rightHandItem.Drop(character)
        end
      end
    end

    local leftArmLocked = leftLockItem ~= nil and not handcuffed
    local rightArmLocked = rightLockItem ~= nil and not handcuffed

    if leftArmLocked and not c.stats.lockleftarm then
      HF.RemoveItem(leftLockItem)
    end
    if rightArmLocked and not c.stats.lockrightarm then
      HF.RemoveItem(rightLockItem)
    end

    if not leftArmLocked and c.stats.lockleftarm then
      HF.ForceArmLock(character, "armlock2")
    end
    if not rightArmLocked and c.stats.lockrightarm then
      HF.ForceArmLock(character, "armlock1")
    end

    local desiredStrength = HF.BoolToNum(
      (c.stats.lockleftarm and c.stats.lockrightarm) or handcuffed,
      100
    )
    if c.afflictions[i].strength ~= desiredStrength then
      c.afflictions[i].strength = desiredStrength
    end
  end,
}

NT.Afflictions.lockleftarm = {
  getter = function(c)
    return limbLockedInitialAegis(c, LimbType.LeftArm, "lockleftarm")
  end,
}

NT.Afflictions.lockrightarm = {
  getter = function(c)
    return limbLockedInitialAegis(c, LimbType.RightArm, "lockrightarm")
  end,
}
NT.Afflictions.lockleftleg = {
  getter = function(c)
    return limbLockedInitialAegis(c, LimbType.LeftLeg, "lockleftleg")
  end,
}
NT.Afflictions.lockrightleg = {
  getter = function(c)
    return limbLockedInitialAegis(c, LimbType.RightLeg, "lockrightleg")
  end,
}






-- Hooks related to Hammerhead and Endworm Afflictions

-- Track torso sprite state so clothing slots and afflictions are only queried when dirty.
local torsoSpriteStateCache = setmetatable({}, { __mode = "k" })

local function GetTorsoSpriteState(character, spriteAffliction)
  local characterState = torsoSpriteStateCache[character]
  if characterState == nil then
    characterState = {}
    torsoSpriteStateCache[character] = characterState
  end

  local state = characterState[spriteAffliction]
  if state == nil then
    state = {
      active = nil,
      visible = nil,
      dirty = true,
    }
    characterState[spriteAffliction] = state
  end

  return state
end

function NTGraft.MarkTorsoSpriteStateDirty(character)
  if character == nil then return end

  local characterState = torsoSpriteStateCache[character]
  if characterState ~= nil then
    for _, state in pairs(characterState) do
      state.dirty = true
    end
  end
end

local function UpdateTorsoGraftSprite(character, spriteAffliction, graftActive)
  local state = GetTorsoSpriteState(character, spriteAffliction)
  if not state.dirty and state.active == graftActive then return end

  state.active = graftActive
  state.dirty = false

  local visible = false
  if graftActive then
    local outwearItem = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    local clothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    visible = outwearItem == nil and clothes == nil
  end

  if state.visible ~= visible then
    HF.SetAffliction(character, spriteAffliction, HF.BoolToNum(visible, 100))
    state.visible = visible
  end
end

NT.Afflictions.hammerheadTorsoAffliction = {
  update = function(c, i)
    UpdateTorsoGraftSprite(
      c.character,
      "hammerheadTorsoAfflictionSprite",
      c.afflictions[i].strength > 10
    )
  end,
}

Hook.Add("item.equip", "graftedTorsoFixEquip", function(item, character)
  NTGraft.MarkTorsoSpriteStateDirty(character)

  if HF.HasAfflictionLimb(character, "hammerheadTorsoAffliction", LimbType.Torso, 5) then
    UpdateTorsoGraftSprite(character, "hammerheadTorsoAfflictionSprite", true)
  elseif HF.HasAfflictionLimb(character, "endwormTorsoAffliction", LimbType.Torso, 5) then
    UpdateTorsoGraftSprite(character, "endwormTorsoAfflictionSprite", true)
  end
end)


Hook.Add("item.unequip", "graftedTorsoFixUnequip", function(item, character)
  NTGraft.MarkTorsoSpriteStateDirty(character)

  if HF.HasAfflictionLimb(character, "hammerheadTorsoAffliction", LimbType.Torso, 5) then
    UpdateTorsoGraftSprite(character, "hammerheadTorsoAfflictionSprite", true)
  elseif HF.HasAfflictionLimb(character, "endwormTorsoAffliction", LimbType.Torso, 5) then
    UpdateTorsoGraftSprite(character, "endwormTorsoAfflictionSprite", true)
  end
end)






-- Moloch shell damage is event-driven instead of being scanned every human update.
local molochCrackCoefficients = {
  blunttrauma = 0.75,
  gunshotwound = 0.6,
  lacerations = 0.25,
}
local molochCrackMaxPerType = 30
local molochCrackMaxPerHit = 30

local function GetMolochCrackAmount(character, attackResult, limbtype)
  if attackResult == nil or attackResult.Afflictions == nil then return 0 end

  local crackAmount = 0
  for _, affliction in ipairs(attackResult.Afflictions) do
    local identifier = affliction.Prefab.Identifier.Value
    local coefficient = molochCrackCoefficients[identifier]
    if coefficient ~= nil then
      local resistance = HF.GetResistance(character, identifier, limbtype)
      local strength = math.max(0, (affliction.Strength or 0) * (1 - resistance))
      crackAmount = crackAmount + math.min(strength * coefficient, molochCrackMaxPerType)
    end
  end

  return math.min(crackAmount, molochCrackMaxPerHit)
end

NTC.AddOnDamagedHook(function(characterHealth, attackResult, hitLimb)
  if characterHealth == nil or characterHealth.Character == nil
    or hitLimb == nil or hitLimb.type ~= LimbType.Head then
    return
  end

  local character = characterHealth.Character
  if not HF.HasAfflictionLimb(character, "molochHeadAffliction", LimbType.Head, 1) then
    return
  end

  local crackAmount = GetMolochCrackAmount(character, attackResult, hitLimb.type)
  if crackAmount > 0 then
    HF.AddAffliction(character, "molochCracked", crackAmount)
  end
end)




-- Propagate Endworm limbs once per Neurotrauma update while preserving the gradual rate.
local endwormLimbAfflictions = {
  { identifier = "endwormLArmAffliction", limb = LimbType.LeftArm, cyber = "ntc_cyberarm" },
  { identifier = "endwormRArmAffliction", limb = LimbType.RightArm, cyber = "ntc_cyberarm" },
  { identifier = "endwormLLegAffliction", limb = LimbType.LeftLeg, cyber = "ntc_cyberleg" },
  { identifier = "endwormRLegAffliction", limb = LimbType.RightLeg, cyber = "ntc_cyberleg" },
}

local function PropagateEndwormLimbs(character)
  for _, limbData in ipairs(endwormLimbAfflictions) do
    local hasCyberneticLimb = NTCyb ~= nil
      and HF.HasAfflictionLimb(character, limbData.cyber, limbData.limb, 1)

    if not hasCyberneticLimb then
      local currentStrength = HF.GetAfflictionStrengthLimb(
        character,
        limbData.limb,
        limbData.identifier,
        0
      )
      if currentStrength < 100 then
        HF.AddAfflictionLimb(
          character,
          limbData.identifier,
          limbData.limb,
          1
        )
      end
    end
  end
end

NT.Afflictions.endwormTorsoAffliction = {
  update = function(c, i)
    local character = c.character
    local torsoStrength = c.afflictions[i].strength

    UpdateTorsoGraftSprite(
      character,
      "endwormTorsoAfflictionSprite",
      torsoStrength > 10
    )

    if torsoStrength >= 90 then
      PropagateEndwormLimbs(character)
    end
  end,
}


local orangeboyRollState = setmetatable({}, { __mode = "k" })
local orangeboyRollIntervalUpdates = 5
local orangeboyRollChance = 4 / 1251
local orangeboyBatchChance = 1 - (1 - orangeboyRollChance) ^ orangeboyRollIntervalUpdates

NT.Afflictions.orangeboyTailAffliction = {
  update = function(c, i)
    local character = c.character
    local state = orangeboyRollState[character]

    if state == nil then
      state = { updates = 0 }
      orangeboyRollState[character] = state
    end

    if c.afflictions[i].strength <= 1 then
      state.updates = 0
      return
    end

    state.updates = state.updates + 1
    if state.updates < orangeboyRollIntervalUpdates then return end
    state.updates = 0

    -- Roll once per batch while preserving the chance of at least one drop.
    if math.random() < orangeboyBatchChance then
      HF.GiveItem(character, "chitin")
    end
  end,
}
