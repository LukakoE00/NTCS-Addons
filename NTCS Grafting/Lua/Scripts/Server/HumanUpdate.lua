


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
                            {Parent="grafting_CrawlerTail",Child="grafting_CrawlerLungs"                 -- Crawler
                          },
                            {Parent="grafting_FractalGuardianEyes",Child="grafting_WatcherEyes"     -- Eyes
                          },
                            {Parent="grafting_HuskArm",Child="grafting_HuskHeart"                   -- Husk
                          },
                            {Parent="grafting_LatcherHeart",Child="grafting_LatcherTongue"          -- Latcher
                          },
                            {Parent="grafting_MantisLiver",Child="grafting_BroodmotherLiver",       -- Liver
                            Child2="grafting_ViperlingLiver"
                          },
                            {Parent="grafting_MudraptorLungs",Child="grafting_MudraptorHead"        -- Mudraptor
                          },
                            {Parent="grafting_TigerThresherJaw",Child="grafting_TigerThresherTail"  -- Tiger Thresher
                          },
                            {Parent="grafting_BoneThresherJaw",Child="grafting_CharybdisJaw"        -- Jaw
                          },
                            {Parent="grafting_HammerheadTorso",Child="grafting_HammerheadLimbs"     -- Hammerhead
                          },
                            {Parent="grafting_EndwormTorso",Child="grafting_EndwormLeftArm",           -- Endworm
                            Child2="grafting_EndwormRightArm",Child3="grafting_EndwormLeftLeg",
                            Child4="grafting_EndwormRightLeg"
                          },
                            {Parent="grafting_MolochHead",Child="grafting_MolochHeadCracked"                      -- Moloch
                          },
                            {Parent="grafting_OrangeboyTail"}                                        -- Tail?
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
		) and HF.HasAffliction(c.character,"grafting_HuskHeart",5)
end



NT.Afflictions.lockedhands = {
		update = function(c, i)
			-- arm locking
			local leftlockitem = c.character.Inventory.FindItemByIdentifier("armlock2", false)
			local rightlockitem = c.character.Inventory.FindItemByIdentifier("armlock1", false)
			-- handcuffs
			local handcuffs = c.character.Inventory.FindItemByIdentifier("handcuffs", false)
			local handcuffed = handcuffs ~= nil and c.character.Inventory.FindIndex(handcuffs) <= 6

      if not handcuffed and HF.HasAffliction(c.character,"grafting_HuskHeart",5) then
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

NT.Afflictions.grafting_HammerheadTorso = {

  update = function(c,i)
    if c.afflictions[i].strength > 10 then
      local outwearItem = c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
      local clothes = c.character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
      if outwearItem == nil and clothes == nil then
        HF.SetAffliction(c.character,"grafting_HammerheadTorsoSprite",100)  
      else
        HF.SetAffliction(c.character,"grafting_HammerheadTorsoSprite",0)
      end
    else
      HF.SetAffliction(c.character,"grafting_HammerheadTorsoSprite",0)
    end
  end,


}

Hook.Add("item.equip", "graftedTorsoFixEquip", function(item, character)

  if (HF.HasAfflictionLimb(character, "grafting_HammerheadTorso", LimbType.Torso, 5)) then
    local outwearItem = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    local clothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    if outwearItem == nil and clothes == nil then
      HF.SetAffliction(character,"grafting_HammerheadTorsoSprite",100)  
    else
      HF.SetAffliction(character,"grafting_HammerheadTorsoSprite",0)
    end

  elseif (HF.HasAfflictionLimb(character, "grafting_EndwormTorso", LimbType.Torso, 5)) then
    local outwearItem = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    local clothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    if outwearItem == nil and clothes == nil then
      HF.SetAffliction(character,"grafting_EndwormTorsoSprite",100)  
    else
      HF.SetAffliction(character,"grafting_EndwormTorsoSprite",0)
    end

  end
end)


Hook.Add("item.unequip", "graftedTorsoFixUnequip", function(item, character)

  if (HF.HasAfflictionLimb(character, "grafting_HammerheadTorso", LimbType.Torso, 5)) then
    local outwearItem = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    local clothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    if outwearItem == nil and clothes == nil then
      HF.SetAffliction(character,"grafting_HammerheadTorsoSprite",100)  
    else
      HF.SetAffliction(character,"grafting_HammerheadTorsoSprite",0)
    end

  elseif (HF.HasAfflictionLimb(character, "grafting_EndwormTorso", LimbType.Torso, 5)) then
    local outwearItem = character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
    local clothes = character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
    if outwearItem == nil and clothes == nil then
      HF.SetAffliction(character,"grafting_EndwormTorsoSprite",100)  
    else
      HF.SetAffliction(character,"grafting_EndwormTorsoSprite",0)
    end

  end
end)






NT.Afflictions.grafting_MolochHead = {
  update = function(c,i)

    if c.afflictions[i].strength > 0 then
      if HF.HasAfflictionLimb(c.character,"blunttrauma",LimbType.Head,40) 
      or HF.HasAfflictionLimb(c.character,"lacerations",LimbType.Head,40)
      or HF.HasAfflictionLimb(c.character,"gunshotwound",LimbType.Head,40) then
        HF.AddAffliction(c.character,"grafting_MolochHeadCracked",1.5)
      elseif HF.HasAfflictionLimb(c.character,"blunttrauma",LimbType.Head,4) 
      or HF.HasAfflictionLimb(c.character,"lacerations",LimbType.Head,4)
      or HF.HasAfflictionLimb(c.character,"gunshotwound",LimbType.Head,7) then
        HF.AddAffliction(c.character,"grafting_MolochHeadCracked",0.5)
      end
    end      


  end,
}




NT.Afflictions.grafting_EndwormTorso = {

  update = function(c,i)
    if c.afflictions[i].strength > 10 and NTCyb == nil then
      if HF.HasAfflictionLimb(c.character,"grafting_EndwormTorso",LimbType.Torso,90) then
        HF.AddAfflictionLimb(c.character,"grafting_EndwormLeftArm",LimbType.LeftArm,1)
        HF.AddAfflictionLimb(c.character,"grafting_EndwormRightArm",LimbType.RightArm,1)
        HF.AddAfflictionLimb(c.character,"grafting_EndwormLeftLeg",LimbType.LeftLeg,1)
        HF.AddAfflictionLimb(c.character,"grafting_EndwormRightLeg",LimbType.RightLeg,1)
      end
    elseif c.afflictions[i].strength > 10 and NTCyb ~= nil then
      if HF.HasAfflictionLimb(c.character,"grafting_EndwormTorso",LimbType.Torso,90) then
        if HF.HasAfflictionLimb(c.character,"ntc_cyberarm",LimbType.LeftArm,1) then
        else HF.AddAfflictionLimb(c.character,"grafting_EndwormLeftArm",LimbType.LeftArm,1) end
        if HF.HasAfflictionLimb(c.character,"ntc_cyberarm",LimbType.RightArm,1) then
        else HF.AddAfflictionLimb(c.character,"grafting_EndwormRightArm",LimbType.RightArm,1) end
        if HF.HasAfflictionLimb(c.character,"ntc_cyberleg",LimbType.LeftLeg,1) then
        else HF.AddAfflictionLimb(c.character,"grafting_EndwormLeftLeg",LimbType.LeftLeg,1) end
        if HF.HasAfflictionLimb(c.character,"ntc_cyberleg",LimbType.RightLeg,1) then
        else HF.AddAfflictionLimb(c.character,"grafting_EndwormRightLeg",LimbType.RightLeg,1) end
    end



      local outwearItem = c.character.Inventory.GetItemInLimbSlot(InvSlotType.OuterClothes)
      local clothes = c.character.Inventory.GetItemInLimbSlot(InvSlotType.InnerClothes)
      if outwearItem == nil and clothes == nil then
        HF.SetAffliction(c.character,"grafting_EndwormTorsoSprite",100)  
      else
        HF.SetAffliction(c.character,"grafting_EndwormTorsoSprite",0)
      end
    else
      HF.SetAffliction(c.character,"grafting_EndwormTorsoSprite",0)
    end
  end,

}


math.randomseed(os.time())
NT.Afflictions.grafting_OrangeboyTail = {
  update = function(c,i)
    if c.afflictions[i].strength > 1 then
      local dropChance = math.random(0,1250)
      if(dropChance <= 3) then
        HF.GiveItem(c.character,"chitin")
      end
    end
  end,
}
