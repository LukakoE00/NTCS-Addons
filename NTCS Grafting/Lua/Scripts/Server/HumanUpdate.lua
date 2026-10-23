


NT.Afflictions.hybriddna = {
  update = function(c,i)

    if (HF.HasAffliction(c.character,"crossspeciesrejection",1)) then
      local creatures = 0

      local function AddCreatureMark() -- Rather then doign a augmented assignment every where we just reference this instead.
          creatures=creatures+1
      end
      
      -- Grafting Types is a table containing our possible grafts, each row has a 'parent' graft and it's alternatives.
      -- If one graft is identified from a table then it skips the rest and moves onto the next row.

      local GraftingTypes = {
                            {Parent="crawlerTailAegis",Child="crawlerLungsAffliction"                 -- Crawler
                          },
                            {Parent="fractalGuardianEyesAffliction",Child="watcherEyesAffliction"     -- Eyes
                          },
                            {Parent="huskArmAffliction",Child="huskHeartAffliction"                   -- Husk
                          },
                            {Parent="latcherHeartAffliction",Child="latcherTongueAffliction"          -- Latcher
                          },
                            {Parent="mantisLiverAffliction",Child="broodmotherLiverAffliction",       -- Liver
                            Child2="viperlingLiverAffliction"
                          },
                            {Parent="mudraptorLungsAffliction",Child="mudraptorHeadAffliction"        -- Mudraptor
                          },
                            {Parent="tigerThresherJawAffliction",Child="tigerThresherTailAffliction"  -- Tiger Thresher
                          },
                            {Parent="boneThresherJawAffliction",Child="charybdisJawAffliction"        -- Jaw
                          },
                            {Parent="hammerheadTorsoAffliction",Child="hammerheadLimbsAffliction"     -- Hammerhead
                          },
                            {Parent="endwormTorsoAffliction",Child="endwormLArmAffliction",           -- Endworm
                            Child2="endwormRArmAffliction",Child3="endwormLLegAffliction",
                            Child4="endwormRLegAffliction"
                          },
                            {Parent="molochHeadAffliction",Child="molochCracked"                      -- Moloch
                          },
                            {Parent="orangeboyTailAffliction"}                                        -- Tail?
                          }
      
      for Key, Value in pairs(GraftingTypes) do -- We iterate through our graft types using this structure, which is much more compact and easy to mainatain.

        for GraftKey, GraftName in pairs(Value) do

          if (HF.HasAffliction(c.character,GraftName,1)) then
            AddCreatureMark()
            break -- Incase we do have the affliction we break and move onto the next graft type. Keeps the old functionality.

          end
      end
        
      HF.SetAffliction(c.character,"hybriddna",creatures) -- I'm not too sure what this is needed for but I'll keep it lol.

    end

      if c.afflictions[i].strength >= 2 and not HF.HasTalent(c.character,"tolerantdna") and not HF.HasTalent(c.character, "hackeddna") then
        HF.SetAffliction(c.character,"crossspeciesrejection",100)
        HF.SetAffliction(c.character,"hybriddnakiller",100)
      elseif c.afflictions[i].strength >= 3 and not HF.HasTalent(c.character,"hackeddna") then
        HF.SetAffliction(c.character,"crossspeciesrejection",100)
        HF.SetAffliction(c.character,"hybriddnakiller",100)
      end

  end
end
}


function limbLockedInitialAegis(c, limbtype, key)
	return not NTC.GetSymptomFalse(c.character, key)
		and (
			NTC.GetSymptom(c.character, key)
			or c.afflictions.t_paralysis.strength > 0
			or NT.LimbIsAmputated(c.character, limbtype)
			or (HF.GetAfflictionStrengthLimb(c.character, limbtype, "bandaged", 0) <= 0 and HF.GetAfflictionStrengthLimb(
				c.character,
				limbtype,
				"dirtybandage",
				0
			) <= 0 and NT.LimbIsDislocated(c.character, limbtype))
			or (
				HF.GetAfflictionStrengthLimb(c.character, limbtype, "gypsumcast", 0) <= 0
				and NT.LimbIsBroken(c.character, limbtype)
			)
		) and HF.HasAffliction(c.character,"huskHeartAffliction",5)
end



NT.Afflictions.lockedhands = {
		update = function(c, i)
			-- arm locking
			local leftlockitem = c.character.Inventory.FindItemByIdentifier("armlock2", false)
			local rightlockitem = c.character.Inventory.FindItemByIdentifier("armlock1", false)
			-- handcuffs
			local handcuffs = c.character.Inventory.FindItemByIdentifier("handcuffs", false)
			local handcuffed = handcuffs ~= nil and c.character.Inventory.FindIndex(handcuffs) <= 6

      if not handcuffed and HF.HasAffliction(c.character,"huskHeartAffliction",5) then
        HF.RemoveItem(leftlockitem)
        HF.RemoveItem(rightlockitem)
        return
      end

      if handcuffed then
				-- drop non-handcuff items
				local leftHandItem = HF.GetItemInLeftHand(c.character)
				local rightHandItem = HF.GetItemInRightHand(c.character)
				if leftHandItem ~= nil and leftHandItem ~= handcuffs and leftlockitem == nil then
					leftHandItem.Drop(c.character)
				end
				if rightHandItem ~= nil and rightHandItem ~= handcuffs and rightlockitem == nil then
					rightHandItem.Drop(c.character)
				end
			end

			local leftarmlocked = leftlockitem ~= nil and not handcuffed
			local rightarmlocked = rightlockitem ~= nil and not handcuffed
    
			if leftarmlocked and not c.stats.lockleftarm then
				HF.RemoveItem(leftlockitem)
			end
			if rightarmlocked and not c.stats.lockrightarm then
				HF.RemoveItem(rightlockitem)
			end


      if not leftarmlocked and c.stats.lockleftarm then
				HF.ForceArmLock(c.character, "armlock2")
			end
			if not rightarmlocked and c.stats.lockrightarm then
				HF.ForceArmLock(c.character, "armlock1")
			end

			c.afflictions[i].strength = HF.BoolToNum((c.stats.lockleftarm and c.stats.lockrightarm) or handcuffed, 100)
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

NT.Afflictions.hammerheadTorsoAffliction = {

  update = function(c,i)
    if c.afflictions[i].strength > 10 then
      local outwearItem = c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
      local clothes = c.character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
      if outwearItem == nil and clothes == nil then
        HF.SetAffliction(c.character,"hammerheadTorsoAfflictionSprite",100)  
      else
        HF.SetAffliction(c.character,"hammerheadTorsoAfflictionSprite",0)
      end
    else
      HF.SetAffliction(c.character,"hammerheadTorsoAfflictionSprite",0)
    end
  end,


}

Hook.Add("item.equip", "graftedTorsoFixEquip", function(item, character)

  if (HF.HasAfflictionLimb(character, "hammerheadTorsoAffliction", LimbType.Torso, 5)) then
    local outwearItem = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    local clothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    if outwearItem == nil and clothes == nil then
      HF.SetAffliction(character,"hammerheadTorsoAfflictionSprite",100)  
    else
      HF.SetAffliction(character,"hammerheadTorsoAfflictionSprite",0)
    end

  elseif (HF.HasAfflictionLimb(character, "endwormTorsoAffliction", LimbType.Torso, 5)) then
    local outwearItem = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    local clothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    if outwearItem == nil and clothes == nil then
      HF.SetAffliction(character,"endwormTorsoAfflictionSprite",100)  
    else
      HF.SetAffliction(character,"endwormTorsoAfflictionSprite",0)
    end

  end
end)


Hook.Add("item.unequip", "graftedTorsoFixUnequip", function(item, character)

  if (HF.HasAfflictionLimb(character, "hammerheadTorsoAffliction", LimbType.Torso, 5)) then
    local outwearItem = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    local clothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    if outwearItem == nil and clothes == nil then
      HF.SetAffliction(character,"hammerheadTorsoAfflictionSprite",100)  
    else
      HF.SetAffliction(character,"hammerheadTorsoAfflictionSprite",0)
    end

  elseif (HF.HasAfflictionLimb(character, "endwormTorsoAffliction", LimbType.Torso, 5)) then
    local outwearItem = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    local clothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    if outwearItem == nil and clothes == nil then
      HF.SetAffliction(character,"endwormTorsoAfflictionSprite",100)  
    else
      HF.SetAffliction(character,"endwormTorsoAfflictionSprite",0)
    end

  end
end)






NT.Afflictions.molochHeadAffliction = {
  update = function(c,i)

    if c.afflictions[i].strength > 0 then
      if HF.HasAfflictionLimb(c.character,"blunttrauma",LimbType.Head,40) 
      or HF.HasAfflictionLimb(c.character,"lacerations",LimbType.Head,40)
      or HF.HasAfflictionLimb(c.character,"gunshotwound",LimbType.Head,40) then
        HF.AddAffliction(c.character,"molochCracked",1.5)
      elseif HF.HasAfflictionLimb(c.character,"blunttrauma",LimbType.Head,4) 
      or HF.HasAfflictionLimb(c.character,"lacerations",LimbType.Head,4)
      or HF.HasAfflictionLimb(c.character,"gunshotwound",LimbType.Head,7) then
        HF.AddAffliction(c.character,"molochCracked",0.5)
      end
    end      


  end,
}




NT.Afflictions.endwormTorsoAffliction = {

  update = function(c,i)
    if c.afflictions[i].strength > 10 and NTCyb == nil then
      if HF.HasAfflictionLimb(c.character,"endwormTorsoAffliction",LimbType.Torso,90) then
        HF.AddAfflictionLimb(c.character,"endwormLArmAffliction",LimbType.LeftArm,1)
        HF.AddAfflictionLimb(c.character,"endwormRArmAffliction",LimbType.RightArm,1)
        HF.AddAfflictionLimb(c.character,"endwormLLegAffliction",LimbType.LeftLeg,1)
        HF.AddAfflictionLimb(c.character,"endwormRLegAffliction",LimbType.RightLeg,1)
      end
    elseif c.afflictions[i].strength > 10 and NTCyb ~= nil then
      if HF.HasAfflictionLimb(c.character,"endwormTorsoAffliction",LimbType.Torso,90) then
        if HF.HasAfflictionLimb(c.character,"ntc_cyberarm",LimbType.LeftArm,1) then
        else HF.AddAfflictionLimb(c.character,"endwormLArmAffliction",LimbType.LeftArm,1) end
        if HF.HasAfflictionLimb(c.character,"ntc_cyberarm",LimbType.RightArm,1) then
        else HF.AddAfflictionLimb(c.character,"endwormRArmAffliction",LimbType.RightArm,1) end
        if HF.HasAfflictionLimb(c.character,"ntc_cyberleg",LimbType.LeftLeg,1) then
        else HF.AddAfflictionLimb(c.character,"endwormLLegAffliction",LimbType.LeftLeg,1) end
        if HF.HasAfflictionLimb(c.character,"ntc_cyberleg",LimbType.RightLeg,1) then
        else HF.AddAfflictionLimb(c.character,"endwormRLegAffliction",LimbType.RightLeg,1) end
    end



      local outwearItem = c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
      local clothes = c.character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
      if outwearItem == nil and clothes == nil then
        HF.SetAffliction(c.character,"endwormTorsoAfflictionSprite",100)  
      else
        HF.SetAffliction(c.character,"endwormTorsoAfflictionSprite",0)
      end
    else
      HF.SetAffliction(c.character,"endwormTorsoAfflictionSprite",0)
    end
  end,

}


math.randomseed(os.time())
NT.Afflictions.orangeboyTailAffliction = {
  update = function(c,i)
    if c.afflictions[i].strength > 1 then
      local dropChance = math.random(0,1250)
      if(dropChance <= 3) then
        HF.GiveItem(c.character,"chitin")
      end
    end
  end,
}
