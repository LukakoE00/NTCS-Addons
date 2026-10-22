


Hook.Add("item.applyTreatment", "NTGraft.itemused", function(item, usingCharacter, targetCharacter, limb)
  local identifier = item.Prefab.Identifier.Value

  local methodtorun = NTGraft.ItemMethods[identifier]
  if(methodtorun~=nil) then

      methodtorun(item, usingCharacter, targetCharacter, limb)
      return
  end

  for key,value in pairs(NTGraft.ItemStartsWithMethods) do
    if HF.StartsWith(identifier,key) then
      value(item, usingCharacter, targetCharacter, limb)
      return
    end
  end


end)





local function forceSyncAfflictions(character)
  if Game.IsSinglePlayer then return end

  Networking.CreateEntityEvent(character, Character.CharacterStatusEventData.__new(true))
end

NTGraft.ItemMethods = {}
NTGraft.ItemStartsWithMethods = {}




-- ORGAN IDENTIFIER FUNCTION

local function organIdentifier(targetCharacter, usingCharacter, organ)

  if (organ == "Lungs") then
    --Lungs, Grafting Removal
    --Current List: crawlerLungs, mudraptorLungs
    if (HF.HasAffliction(targetCharacter, "crawlerLungsAffliction", 1)) then
      HF.SetAffliction(targetCharacter, "crawlerLungsAffliction", 0, usingCharacter)
      return "crawlerLungsAegis"
    elseif (HF.HasAffliction(targetCharacter, "mudraptorLungsAffliction", 1)) then
      HF.SetAffliction(targetCharacter, "mudraptorLungsAffliction", 0, usingCharacter)
      return "mudraptorLungsAegis"
    else
      if NTC.HasTag(usingCharacter, "organssellforfull") then
        return "lungtransplant"
      else
        return "lungtransplant_q1"
      end
    end
  elseif (organ == "Heart") then
    --Heart, Grafting Removal
    --Current List: huskHeart, latcherHeart
    if (HF.HasAffliction(targetCharacter, "huskHeartAffliction", 1)) then
      HF.SetAffliction(targetCharacter, "huskHeartAffliction", 0, usingCharacter)
      return "huskHeartAegis"
    elseif (HF.HasAffliction(targetCharacter, "latcherHeartAffliction", 1)) then
      HF.SetAffliction(targetCharacter, "latcherHeartAffliction", 0, usingCharacter)
      return "latcherHeartAegis"
    else
			if NTC.HasTag(usingCharacter, "organssellforfull") then
				return "hearttransplant"
      else
        return "hearttransplant_q1"
      end
    end
  elseif (organ == "Liver") then
    --Livers, Grafting Removal
    --Current List: mantisLiver, broodmotherLiver, viperlingLiver
    if (HF.HasAffliction(targetCharacter, "mantisLiverAffliction", 1)) then
      HF.SetAffliction(targetCharacter, "mantisLiverAffliction", 0, usingCharacter)
      return "mantisLiverAegis"
    elseif (HF.HasAffliction(targetCharacter, "broodmotherLiverAffliction", 1)) then
      HF.SetAffliction(targetCharacter, "broodmotherLiverAffliction", 0)
      return "broodmotherLiverAegis"
    elseif (HF.HasAffliction(targetCharacter, "viperlingLiverAffliction", 1)) then
      HF.SetAffliction(targetCharacter, "viperlingLiverAffliction", 0, usingCharacter)
      return "viperlingLiverAegis"
    else
      if NTC.HasTag(usingCharacter, "organssellforfull") then
        return "livertransplant"
      else
        return "livertransplant_q1"
      end
    end
  end

end



-- GENERAL ITEMS


NTGraft.ItemMethods.graftingcure = function(item, usingCharacter, targetCharacter, limb)

  local medicalLevel = HF.GetSkillLevel(usingCharacter, "medical")

  if (medicalLevel >= 50) then
    HF.AddAffliction(targetCharacter, "graftingcureoverdose", 70, usingCharacter)
    HF.AddAffliction(targetCharacter, "crossspeciesrejection", -25, usingCharacter)
    HF.RemoveItem(item)
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 50)
    if(medicalLevel >= skillcheck) then
      HF.AddAffliction(targetCharacter, "graftingcureoverdose", 75, usingCharacter)
      HF.AddAffliction(targetCharacter, "crossspeciesrejection", -25, usingCharacter)
      HF.RemoveItem(item)
    elseif(medicalLevel < skillcheck) then
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
  elseif (HF.HasAfflictionLimb(targetCharacter, "endwormTorsoAffliction",LimbType.Torso,1)) and limbtype ~= LimbType.Head then
    strength = 33
  end

  if (medicalLevel >= 50) then
      HF.AddAfflictionLimb(targetCharacter, "alienDNARemoval", limbtype, strength, usingCharacter)
    HF.RemoveItem(item)
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 50)
    if(medicalLevel >= skillcheck) then
      HF.AddAfflictionLimb(targetCharacter, "alienDNARemoval", limbtype, strength, usingCharacter)
      HF.RemoveItem(item)
    elseif(medicalLevel < skillcheck) then
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
  if(limbtype == LimbType.Torso) then
    if (medicalLevel >= 30) then
      if (HF.HasAffliction(targetCharacter,"orangeboyTailAffliction",1) and HF.HasAfflictionLimb(targetCharacter,"retractedSkin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"orangeboyTailAffliction",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"orangeboyTailAegis")
      elseif(HF.HasAffliction(targetCharacter,"crawlerTailAegis",1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"crawlerTailAegis",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"crawlerTailAegis")
      elseif(HF.HasAffliction(targetCharacter,"tigerThresherTailAffliction",1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"tigerThresherTailAffliction",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"tigerThresherTailAegis")
      elseif(HF.HasAffliction(targetCharacter,"huskArmAffliction",1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"huskArmAffliction",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"huskArmAegis")
      elseif(HF.HasAffliction(targetCharacter,"hammerheadLimbsAffliction",1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"hammerheadLimbsAffliction",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"hammerheadLimbsAegis")
      end
    else
      math.randomseed(os.time())
      local skillcheck = math.random(0, 30)
      if (skillcheck > medicalLevel) then
        HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 15, usingCharacter)
      elseif (HF.HasAffliction(targetCharacter,"orangeboyTailAffliction",limbtype,1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"orangeboyTailAffliction",0,usingCharacter,0)
        HF.GiveItem(targetCharacter,"orangeboyTailAegis")
      elseif (HF.HasAffliction(targetCharacter,"crawlerTailAegis",limbtype,1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"crawlerTailAegis",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"crawlerTailAegis")
      elseif(HF.HasAffliction(targetCharacter,"tigerThresherTailAffliction",1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"tigerThresherTailAffliction",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"tigerThresherTailAegis")
      elseif(HF.HasAffliction(targetCharacter,"huskArmAffliction",1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"huskArmAffliction",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"huskArmAegis")
      elseif(HF.HasAffliction(targetCharacter,"hammerheadLimbsAffliction",1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"hammerheadLimbsAffliction",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"hammerheadLimbsAegis")
      end
    end
  --Head, Grafting Removal.
  --Current List: LatcherTongue 
  elseif(limbtype == LimbType.Head) then
    if (medicalLevel >= 30) then
      if (HF.HasAffliction(targetCharacter,"latcherTongueAffliction",1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"latcherTongueAffliction",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"latcherTongueAegis")
      end
    else
      math.randomseed(os.time())
      local skillcheck = math.random(0,30)
      if (skillcheck > medicalLevel) then
        HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 5, usingCharacter)
      elseif (HF.HasAffliction(targetCharacter,"latcherTongueAffliction",1) and HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"latcherTongueAffliction",0,usingCharacter,0)
        HF.GiveItem(usingCharacter,"latcherTongueAegis")
      end
    end
  end

end



NT.SutureAfflictions = {
	bonecut = { xpgain = 0, case = "surgeryincision" },
	drilledbones = { xpgain = 0, case = "surgeryincision" },

	ll_arterialcut = { xpgain = 3, case = "retractedskin" },
	rl_arterialcut = { xpgain = 3, case = "retractedskin" },
	la_arterialcut = { xpgain = 3, case = "retractedskin" },
	ra_arterialcut = { xpgain = 3, case = "retractedskin" },
	h_arterialcut = { xpgain = 3, case = "retractedskin" },
	t_arterialcut = { xpgain = 6, case = "retractedskin" },
	arteriesclamp = { xpgain = 0, case = "retractedskin" },
	tamponade = { xpgain = 3, case = "retractedskin" },
	internalbleeding = { xpgain = 3, case = "retractedskin" },
	stroke = { xpgain = 6, case = "retractedskin" },
	heartremoved = {
		xpgain = 0,
		case = "retractedskin",
		func = function(item, usingCharacter, targetCharacter, limb)
			local damage = HF.GetAfflictionStrength(targetCharacter, "heartdamage", 0)
			if damage == 100 or not HF.HasAffliction(targetCharacter, "heartremoved") then
				return
			else
				HF.SetAffliction(targetCharacter, "heartdamage", 100, targetCharacter)
				HF.SetAffliction(targetCharacter, "cardiacarrest", 100, targetCharacter)

				HF.SetAffliction(targetCharacter, "tamponade", 0, targetCharacter)
				HF.SetAffliction(targetCharacter, "heartattack", 0, targetCharacter)
				HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, targetCharacter)
        local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Heart")
--				if NTC.HasTag(usingCharacter, "organssellforfull") then
--					transplantidentifier = "hearttransplant"
--				end
				if damage < 90 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					local function postSpawnFunc(args)
						local tags = {}

						if args.acidosis > 0 then
							table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
						elseif args.alkalosis > 0 then
							table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
						end
						if args.sepsis > 10 then
							table.insert(tags, "sepsis")
						end

						local tagstring = ""
						for index, value in ipairs(tags) do
							tagstring = tagstring .. value
							if index < #tags then
								tagstring = tagstring .. ","
							end
						end

						args.item.Tags = tagstring
						args.item.Condition = args.condition
					end
					local params = {
						acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
						alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
						sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
						condition = 100 - damage,
					}

					HF.GiveItemPlusFunction(transplantidentifier, postSpawnFunc, params, usingCharacter)
				end
			end
		end,
	},
	lungremoved = {
		xpgain = 0,
		case = "retractedskin",
		func = function(item, usingCharacter, targetCharacter, limb)
			local damage = HF.GetAfflictionStrength(targetCharacter, "lungdamage", 0)
			if damage == 100 or not HF.HasAffliction(targetCharacter, "lungremoved") then
				return
			else
				HF.SetAffliction(targetCharacter, "lungdamage", 100, targetCharacter)
				HF.SetAffliction(targetCharacter, "respiratoryarrest", 100, targetCharacter)

				HF.SetAffliction(targetCharacter, "pneumothorax", 0, targetCharacter)
				HF.SetAffliction(targetCharacter, "needlec", 0, targetCharacter)

				HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, targetCharacter)
        local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Lungs")
--				local transplantidentifier = "lungtransplant_q1"
--				if NTC.HasTag(usingCharacter, "organssellforfull") then
--					transplantidentifier = "lungtransplant"
--				end
				if damage < 90 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					local function postSpawnFunc(args)
						local tags = {}

						if args.acidosis > 0 then
							table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
						elseif args.alkalosis > 0 then
							table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
						end
						if args.sepsis > 10 then
							table.insert(tags, "sepsis")
						end

						local tagstring = ""
						for index, value in ipairs(tags) do
							tagstring = tagstring .. value
							if index < #tags then
								tagstring = tagstring .. ","
							end
						end

						args.item.Tags = tagstring
						args.item.Condition = args.condition
					end
					local params = {
						acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
						alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
						sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
						condition = 100 - damage,
					}

					HF.GiveItemPlusFunction(transplantidentifier, postSpawnFunc, params, usingCharacter)
				end
			end
		end,
	},
	kidneyremoved = {
		xpgain = 0,
		case = "retractedskin",
		func = function(item, usingCharacter, targetCharacter, limb)
			local damage = HF.GetAfflictionStrength(targetCharacter, "kidneydamage", 0)
			if damage == 100 or not HF.HasAffliction(targetCharacter, "kidneyremoved") then
				return
			else
				HF.SetAffliction(targetCharacter, "kidneydamage", 100, usingCharacter)
				HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, usingCharacter)
				local transplantidentifier = "kidneytransplant_q1"
				if NTC.HasTag(usingCharacter, "organssellforfull") then
					transplantidentifier = "kidneytransplant"
				end
				if damage < 50 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					local function postSpawnFunc(args)
						local tags = {}

						if args.acidosis > 0 then
							table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
						elseif args.alkalosis > 0 then
							table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
						end
						if args.sepsis > 10 then
							table.insert(tags, "sepsis")
						end

						local tagstring = ""
						for index, value in ipairs(tags) do
							tagstring = tagstring .. value
							if index < #tags then
								tagstring = tagstring .. ","
							end
						end

						args.item.Tags = tagstring
						args.item.Condition = args.condition
					end
					local params = {
						acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
						alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
						sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
						condition = 100,
					}

					HF.GiveItemPlusFunction(transplantidentifier, postSpawnFunc, params, usingCharacter)
					damage = damage + 50
				end
				if damage < 95 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					local function postSpawnFunc(args)
						local tags = {}

						if args.acidosis > 0 then
							table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
						elseif args.alkalosis > 0 then
							table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
						end
						if args.sepsis > 10 then
							table.insert(tags, "sepsis")
						end

						local tagstring = ""
						for index, value in ipairs(tags) do
							tagstring = tagstring .. value
							if index < #tags then
								tagstring = tagstring .. ","
							end
						end

						args.item.Tags = tagstring
						args.item.Condition = args.condition
					end
					local params = {
						acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
						alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
						sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
						condition = 100 - (damage - 50) * 2,
					}

					HF.GiveItemPlusFunction(transplantidentifier, postSpawnFunc, params, usingCharacter)
				end
			end
		end,
	},
	liverremoved = {
		xpgain = 0,
		case = "retractedskin",
		func = function(item, usingCharacter, targetCharacter, limb)
			local damage = HF.GetAfflictionStrength(targetCharacter, "liverdamage", 0)
			if damage == 100 or not HF.HasAffliction(targetCharacter, "liverremoved") then
				return
			else
				HF.SetAffliction(targetCharacter, "liverdamage", 100, usingCharacter)

				HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, usingCharacter)
        local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Liver")
--				local transplantidentifier = "livertransplant_q1"
--				if NTC.HasTag(usingCharacter, "organssellforfull") then
--					transplantidentifier = "livertransplant"
--				end
				if damage < 90 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					local function postSpawnFunc(args)
						local tags = {}

						if args.acidosis > 0 then
							table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
						elseif args.alkalosis > 0 then
							table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
						end
						if args.sepsis > 10 then
							table.insert(tags, "sepsis")
						end

						local tagstring = ""
						for index, value in ipairs(tags) do
							tagstring = tagstring .. value
							if index < #tags then
								tagstring = tagstring .. ","
							end
						end

						args.item.Tags = tagstring
						args.item.Condition = args.condition
					end
					local params = {
						acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
						alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
						sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
						condition = 100 - damage,
					}

					HF.GiveItemPlusFunction(transplantidentifier, postSpawnFunc, params, usingCharacter)
				end
			end
		end,
	},
	brainremoved = {
		xpgain = 0,
		case = "retractedskin",
		func = function(item, usingCharacter, targetCharacter, limb)
			local damage = HF.GetAfflictionStrength(targetCharacter, "cerebralhypoxia", 0)
			if damage == 100 or not HF.HasAffliction(targetCharacter, "brainremoved") then
				return
			else
				HF.AddAffliction(targetCharacter, "cerebralhypoxia", 100, usingCharacter)

				if NTSP ~= nil then
					if HF.HasAffliction(targetCharacter, "artificialbrain") then
						HF.SetAffliction(targetCharacter, "artificialbrain", 0, usingCharacter)
						damage = 100
					end
				end

				if damage < 90 then
					local postSpawnFunction = function(item, donor, client)
						item.Condition = 100 - damage
						if client ~= nil then
							item.Description = client.Name
						end
					end

					if SERVER then
						-- use server spawn method
						local prefab = ItemPrefab.GetItemPrefab("braintransplant")
						local client = HF.CharacterToClient(targetCharacter)
						Entity.Spawner.AddItemToSpawnQueue(
							prefab,
							usingCharacter.WorldPosition,
							nil,
							nil,
							function(item)
								usingCharacter.Inventory.TryPutItem(item, nil, { InvSlotType.Any })
								postSpawnFunction(item, targetCharacter, client)
							end
						)

						if client ~= nil then
							client.SetClientCharacter(nil)
						end
					else
						-- use client spawn method
						local item = Item(ItemPrefab.GetItemPrefab("braintransplant"), usingCharacter.WorldPosition)
						usingCharacter.Inventory.TryPutItem(item, nil, { InvSlotType.Any })
						postSpawnFunction(item, targetCharacter, nil)
					end
				end
			end
		end,
	},

	clampedbleeders = {},
	surgeryincision = {},
	retractedskin = {},
}


NT.ItemStartsWithMethods.lungtransplant = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
		conditionmodifier = -40
	end
	local damage = HF.GetAfflictionStrength(targetCharacter, "lungdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		HF.HasAffliction(targetCharacter, "lungremoved", 1)
		and limbtype == LimbType.Torso
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
    local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Lungs")
		if damage == 100 then
			HF.AddAffliction(targetCharacter, "lungdamage", -workcondition, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			HF.SetAffliction(targetCharacter, "lungremoved", 0, usingCharacter)
			HF.RemoveItem(item)
		else -- swap the organs and its generic and specific organ damage, avoiding unintentionally reducing the patients health
			local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
			HF.SetAffliction(targetCharacter, "lungdamage", 100 - workcondition, targetCharacter)
			HF.SetAffliction(targetCharacter, "lungremoved", 0, usingCharacter)
			HF.SetAffliction(targetCharacter, "respiratoryarrest", 100, targetCharacter)

			HF.SetAffliction(targetCharacter, "pneumothorax", 0, targetCharacter)
			HF.SetAffliction(targetCharacter, "needlec", 0, targetCharacter)

			HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, targetCharacter)
--			local transplantidentifier = "lungtransplant_q1"
--			if NTC.HasTag(usingCharacter, "organssellforfull") then
--				transplantidentifier = "lungtransplant"
--			end
			if damage < 90 then
				-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
				local function postSpawnFunc(args)
					local tags = {}

					if args.acidosis > 0 then
						table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
					elseif args.alkalosis > 0 then
						table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
					end
					if args.sepsis > 10 then
						table.insert(tags, "sepsis")
					end

					local tagstring = ""
					for index, value in ipairs(tags) do
						tagstring = tagstring .. value
						if index < #tags then
							tagstring = tagstring .. ","
						end
					end

					args.item.Tags = tagstring
					args.item.Condition = args.condition
				end
				local params = {
					acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
					alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
					sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
					condition = 100 - damage,
				}
				local inventorySpot = nil
				local parentInventory = item.ParentInventory
				if parentInventory then
					inventorySpot = parentInventory.FindIndex(item)
				end

				HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
				HF.RemoveItem(item)
			end
		end
		local rejectionchance = HF.Clamp(
			(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
				/ 150
				* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
			0,
			1
		)
		if HF.Chance(rejectionchance) and NTConfig.Get("NT_organRejection", false) then
			HF.SetAffliction(targetCharacter, "lungdamage", 100)
		end
	end
end



NT.ItemStartsWithMethods.hearttransplant = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
		conditionmodifier = -40
	end
	local damage = HF.GetAfflictionStrength(targetCharacter, "heartdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		HF.HasAffliction(targetCharacter, "heartremoved", 1)
		and limbtype == LimbType.Torso
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
    local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Heart")
		if damage == 100 then
			HF.AddAffliction(targetCharacter, "heartdamage", -workcondition, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			HF.SetAffliction(targetCharacter, "heartremoved", 0, usingCharacter)
			HF.RemoveItem(item)
		else -- swap the organs and its generic and specific organ damage, avoiding unintentionally reducing the patients health
			local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
			HF.SetAffliction(targetCharacter, "heartdamage", 100 - workcondition, targetCharacter)
			HF.SetAffliction(targetCharacter, "heartremoved", 0, usingCharacter)
			HF.SetAffliction(targetCharacter, "cardiacarrest", 100, targetCharacter)

			HF.SetAffliction(targetCharacter, "tamponade", 0, targetCharacter)
			HF.SetAffliction(targetCharacter, "heartattack", 0, targetCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, targetCharacter)
--			local transplantidentifier = "hearttransplant_q1"
--			if NTC.HasTag(usingCharacter, "organssellforfull") then
--				transplantidentifier = "hearttransplant"
--			end
			if damage < 90 then
				-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
				local function postSpawnFunc(args)
					local tags = {}

					if args.acidosis > 0 then
						table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
					elseif args.alkalosis > 0 then
						table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
					end
					if args.sepsis > 10 then
						table.insert(tags, "sepsis")
					end

					local tagstring = ""
					for index, value in ipairs(tags) do
						tagstring = tagstring .. value
						if index < #tags then
							tagstring = tagstring .. ","
						end
					end

					args.item.Tags = tagstring
					args.item.Condition = args.condition
				end
				local params = {
					acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
					alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
					sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
					condition = 100 - damage,
				}
				local inventorySpot = nil
				local parentInventory = item.ParentInventory
				if parentInventory then
					inventorySpot = parentInventory.FindIndex(item)
				end

				HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
				HF.RemoveItem(item)
			end
		end
		local rejectionchance = HF.Clamp(
			(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
				/ 150
				* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
			0,
			1
		)
		if HF.Chance(rejectionchance) and NTConfig.Get("NT_organRejection", false) then
			HF.SetAffliction(targetCharacter, "heartdamage", 100)
		end
	end
end








NT.ItemStartsWithMethods.livertransplant = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
		conditionmodifier = -40
	end
	local damage = HF.GetAfflictionStrength(targetCharacter, "liverdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		HF.HasAffliction(targetCharacter, "liverremoved", 1)
		and limbtype == LimbType.Torso
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
    local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Liver")
		if damage == 100 then
			HF.AddAffliction(targetCharacter, "liverdamage", -workcondition, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			HF.SetAffliction(targetCharacter, "liverremoved", 0, usingCharacter)
			HF.RemoveItem(item)
		else -- swap the organs and its generic and specific organ damage, avoiding unintentionally reducing the patients health
			local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
			HF.SetAffliction(targetCharacter, "liverdamage", 100 - workcondition, usingCharacter)
			HF.SetAffliction(targetCharacter, "liverremoved", 0, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)
--			local transplantidentifier = "livertransplant_q1"
--			if NTC.HasTag(usingCharacter, "organssellforfull") then
--				transplantidentifier = "livertransplant"
--			end
			if damage < 90 then
				-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
				local function postSpawnFunc(args)
					local tags = {}

					if args.acidosis > 0 then
						table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
					elseif args.alkalosis > 0 then
						table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
					end
					if args.sepsis > 10 then
						table.insert(tags, "sepsis")
					end

					local tagstring = ""
					for index, value in ipairs(tags) do
						tagstring = tagstring .. value
						if index < #tags then
							tagstring = tagstring .. ","
						end
					end

					args.item.Tags = tagstring
					args.item.Condition = args.condition
				end
				local params = {
					acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
					alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
					sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
					condition = 100 - damage,
				}
				local inventorySpot = nil
				local parentInventory = item.ParentInventory
				if parentInventory then
					inventorySpot = parentInventory.FindIndex(item)
				end

				HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
				HF.RemoveItem(item)
			end
		end
		local rejectionchance = HF.Clamp(
			(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
				/ 150
				* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
			0,
			1
		)
		if HF.Chance(rejectionchance) and NTConfig.Get("NT_organRejection", false) then
			HF.SetAffliction(targetCharacter, "liverdamage", 100)
		end
	end
end





NT.ItemMethods.organscalpel_lungs = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type

	local removed = HF.GetAfflictionStrength(targetCharacter, "lungremoved", 0)
	if limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1) then
		if removed <= 0 then
			if HF.GetSurgerySkillRequirementMet(usingCharacter, 50) then
				HF.SetAffliction(targetCharacter, "lungremoved", 100, usingCharacter)
			else
				HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 15, usingCharacter)
				HF.AddAfflictionLimb(targetCharacter, "organdamage", limbtype, 5, usingCharacter)
				HF.AddAffliction(targetCharacter, "lungdamage", 20, usingCharacter)
			end

			HF.GiveItem(targetCharacter, "ntsfx_slash")
		else -- organ extraction
			local damage = HF.GetAfflictionStrength(targetCharacter, "lungdamage", 0)
			if damage == 100 then
				return
			else
				HF.SetAffliction(targetCharacter, "lungdamage", 100, targetCharacter)
				HF.SetAffliction(targetCharacter, "respiratoryarrest", 100, targetCharacter)

				HF.SetAffliction(targetCharacter, "pneumothorax", 0, targetCharacter)
				HF.SetAffliction(targetCharacter, "needlec", 0, targetCharacter)

				HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, targetCharacter)
				local transplantidentifier = "lungtransplant_q1"
				if NTC.HasTag(usingCharacter, "organssellforfull") then
					transplantidentifier = "lungtransplant"
				end
        transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Lungs")
				if damage < 90 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					local function postSpawnFunc(args)
						local tags = {}

						if args.acidosis > 0 then
							table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
						elseif args.alkalosis > 0 then
							table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
						end
						if args.sepsis > 10 then
							table.insert(tags, "sepsis")
						end

						local tagstring = ""
						for index, value in ipairs(tags) do
							tagstring = tagstring .. value
							if index < #tags then
								tagstring = tagstring .. ","
							end
						end

						args.item.Tags = tagstring
						args.item.Condition = args.condition
					end
					local params = {
						acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
						alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
						sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
						condition = 100 - damage,
					}

					HF.GiveItemPlusFunction(transplantidentifier, postSpawnFunc, params, usingCharacter)
				end
			end
		end
	end
end




NT.ItemMethods.organscalpel_heart = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type

	local removed = HF.GetAfflictionStrength(targetCharacter, "heartremoved", 0)
	if limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1) then
		if removed <= 0 then
			if HF.GetSurgerySkillRequirementMet(usingCharacter, 60) then
				HF.SetAffliction(targetCharacter, "heartremoved", 100, usingCharacter)
			else
				HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 15, usingCharacter)
				HF.AddAfflictionLimb(targetCharacter, "organdamage", limbtype, 5, usingCharacter)
				HF.AddAffliction(targetCharacter, "heartdamage", 20, usingCharacter)
			end

			HF.GiveItem(targetCharacter, "ntsfx_slash")
		else -- organ extraction
			local damage = HF.GetAfflictionStrength(targetCharacter, "heartdamage", 0)
			if damage == 100 then
				return
			else
				HF.SetAffliction(targetCharacter, "heartdamage", 100, targetCharacter)
				HF.SetAffliction(targetCharacter, "cardiacarrest", 100, targetCharacter)

				HF.SetAffliction(targetCharacter, "tamponade", 0, targetCharacter)
				HF.SetAffliction(targetCharacter, "heartattack", 0, targetCharacter)
				HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, targetCharacter)
				local transplantidentifier = "hearttransplant_q1"
				if NTC.HasTag(usingCharacter, "organssellforfull") then
					transplantidentifier = "hearttransplant"
				end
        transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Heart")
				if damage < 90 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					local function postSpawnFunc(args)
						local tags = {}

						if args.acidosis > 0 then
							table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
						elseif args.alkalosis > 0 then
							table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
						end
						if args.sepsis > 10 then
							table.insert(tags, "sepsis")
						end

						local tagstring = ""
						for index, value in ipairs(tags) do
							tagstring = tagstring .. value
							if index < #tags then
								tagstring = tagstring .. ","
							end
						end

						args.item.Tags = tagstring
						args.item.Condition = args.condition
					end
					local params = {
						acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
						alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
						sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
						condition = 100 - damage,
					}

					HF.GiveItemPlusFunction(transplantidentifier, postSpawnFunc, params, usingCharacter)
				end
			end
		end
	end
end


NT.ItemMethods.organscalpel_liver = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type

	local removed = HF.GetAfflictionStrength(targetCharacter, "liverremoved", 0)
	if limbtype == LimbType.Torso and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 1) then
		if removed <= 0 then
			if HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
				HF.SetAffliction(targetCharacter, "liverremoved", 100, usingCharacter)
			else
				HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 15, usingCharacter)
				HF.AddAfflictionLimb(targetCharacter, "organdamage", limbtype, 5, usingCharacter)
				HF.AddAffliction(targetCharacter, "liverdamage", 20, usingCharacter)
			end

			HF.GiveItem(targetCharacter, "ntsfx_slash")
		else -- organ extraction
			local damage = HF.GetAfflictionStrength(targetCharacter, "liverdamage", 0)
			if damage == 100 then
				return
			elseif HF.GetSurgerySkillRequirementMet(usingCharacter, 50) then
				HF.SetAffliction(targetCharacter, "liverdamage", 100, usingCharacter)

				HF.AddAffliction(targetCharacter, "organdamage", (100 - damage) / 5, usingCharacter)
				local transplantidentifier = "livertransplant_q1"
				if NTC.HasTag(usingCharacter, "organssellforfull") then
					transplantidentifier = "livertransplant"
				end
        transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Liver")
				if damage < 90 then
					-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
					local function postSpawnFunc(args)
						local tags = {}

						if args.acidosis > 0 then
							table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
						elseif args.alkalosis > 0 then
							table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
						end
						if args.sepsis > 10 then
							table.insert(tags, "sepsis")
						end

						local tagstring = ""
						for index, value in ipairs(tags) do
							tagstring = tagstring .. value
							if index < #tags then
								tagstring = tagstring .. ","
							end
						end

						args.item.Tags = tagstring
						args.item.Condition = args.condition
					end
					local params = {
						acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
						alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
						sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
						condition = 100 - damage,
					}

					HF.GiveItemPlusFunction(transplantidentifier, postSpawnFunc, params, usingCharacter)
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

  if(HF.HasAfflictionLimb(targetCharacter,"crawlerTailAegis",limbtype,1)) then
    return
  elseif(HF.HasAfflictionLimb(targetCharacter,"tigerThresherTailAffliction",limbtype,1)) then
    return
  end
  if(medicalLevel >= 70) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.SetAffliction(targetCharacter,"crawlerTailAegis",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",45,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.SetAffliction(targetCharacter,"crawlerTailAegis",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",70,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 70)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.SetAffliction(targetCharacter,"crawlerTailAegis",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",60,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"crawlerTailAegis",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",85,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
        HF.RemoveItem(item)
      end
    else
      HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
    end
  end
end




NTGraft.ItemStartsWithMethods.crawlerLungsAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
		conditionmodifier = -40
	end
	local damage = HF.GetAfflictionStrength(targetCharacter, "lungdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		HF.HasAffliction(targetCharacter, "lungremoved", 1)
		and limbtype == LimbType.Torso
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
    local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Lungs")
		if damage == 100 then
			HF.AddAffliction(targetCharacter, "lungdamage", -workcondition, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			HF.SetAffliction(targetCharacter, "lungremoved", 0, usingCharacter)
      HF.SetAffliction(targetCharacter, "crawlerLungsAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 45)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 70)
        HF.AddAffliction(targetCharacter, "sepsis", 3)
      end
			HF.RemoveItem(item)
		else -- swap the organs and its generic and specific organ damage, avoiding unintentionally reducing the patients health
			local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
			HF.SetAffliction(targetCharacter, "lungdamage", 100 - workcondition, targetCharacter)
			HF.SetAffliction(targetCharacter, "lungremoved", 0, usingCharacter)
			HF.SetAffliction(targetCharacter, "respiratoryarrest", 100, targetCharacter)
      
      HF.SetAffliction(targetCharacter, "crawlerLungsAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 45)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 70)
        HF.AddAffliction(targetCharacter, "sepsis", 3)
      end

			HF.SetAffliction(targetCharacter, "pneumothorax", 0, targetCharacter)
			HF.SetAffliction(targetCharacter, "needlec", 0, targetCharacter)

			HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, targetCharacter)
--			local transplantidentifier = "lungtransplant_q1"
--			if NTC.HasTag(usingCharacter, "organssellforfull") then
--				transplantidentifier = "lungtransplant"
--			end
			if damage < 90 then
				-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
				local function postSpawnFunc(args)
					local tags = {}

					if args.acidosis > 0 then
						table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
					elseif args.alkalosis > 0 then
						table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
					end
					if args.sepsis > 10 then
						table.insert(tags, "sepsis")
					end

					local tagstring = ""
					for index, value in ipairs(tags) do
						tagstring = tagstring .. value
						if index < #tags then
							tagstring = tagstring .. ","
						end
					end

					args.item.Tags = tagstring
					args.item.Condition = args.condition
				end
				local params = {
					acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
					alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
					sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
					condition = 100 - damage,
				}
				local inventorySpot = nil
				local parentInventory = item.ParentInventory
				if parentInventory then
					inventorySpot = parentInventory.FindIndex(item)
				end

				HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
				HF.RemoveItem(item)
			end
		end
		local rejectionchance = HF.Clamp(
			(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
				/ 150
				* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
			0,
			1
		)
	end
end



-- FRACTAL GUARDIAN ITEMS



NTGraft.ItemMethods.fractalGuardianEyeAegis = function(item, usingCharacter, targetCharacter, limb)
  local limbtype = HF.NormalizeLimbType(limb.type)

  if NTEYE ~= nil then return end

  if limbtype ~= LimbType.Head then return end

  local medicalLevel = HF.GetSurgerySkill(usingCharacter)

  if(HF.HasAfflictionLimb(targetCharacter,"fractalGuardianEyesAffliction",limbtype,1))
  or HF.HasAfflictionLimb(targetCharacter,"watcherEyesAffliction",limbtype,1)then
    return end
  if(medicalLevel >= 70) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.AddAfflictionLimb(targetCharacter,"fractalGuardianEyesAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",40,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.AddAfflictionLimb(targetCharacter,"fractalGuardianEyesAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",65,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 70)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.AddAfflictionLimb(targetCharacter,"fractalGuardianEyesAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",55,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAfflictionLimb(targetCharacter,"fractalGuardianEyesAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",80,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
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

  if(HF.HasAfflictionLimb(targetCharacter,"huskArmAffliction",limbtype,1)) then
    return end
  if(medicalLevel >= 90) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.SetAffliction(targetCharacter,"huskArmAffliction",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",70,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.SetAffliction(targetCharacter,"huskArmAffliction",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",85,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 90)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.SetAffliction(targetCharacter,"huskArmAffliction",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",80,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"huskArmAffliction",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",100,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
        HF.RemoveItem(item)
      end
    else
      HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
    end
  end
end






NTGraft.ItemStartsWithMethods.huskHeartAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
		conditionmodifier = -40
	end
	local damage = HF.GetAfflictionStrength(targetCharacter, "heartdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		HF.HasAffliction(targetCharacter, "heartremoved", 1)
		and limbtype == LimbType.Torso
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
    local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Heart")
		if damage == 100 then
			HF.AddAffliction(targetCharacter, "heartdamage", -workcondition, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			HF.SetAffliction(targetCharacter, "heartremoved", 0, usingCharacter)
      HF.SetAffliction(targetCharacter, "huskHeartAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 90)
        HF.AddAffliction(targetCharacter, "sepsis", 3)
      end
			HF.RemoveItem(item)
		else -- swap the organs and its generic and specific organ damage, avoiding unintentionally reducing the patients health
			local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
			HF.SetAffliction(targetCharacter, "heartdamage", 100 - workcondition, targetCharacter)
			HF.SetAffliction(targetCharacter, "heartremoved", 0, usingCharacter)
			HF.SetAffliction(targetCharacter, "cardiacarrest", 100, targetCharacter)

      HF.SetAffliction(targetCharacter, "huskHeartAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 90)
        HF.AddAffliction(targetCharacter, "sepsis", 3)
      end

			HF.SetAffliction(targetCharacter, "tamponade", 0, targetCharacter)
			HF.SetAffliction(targetCharacter, "heartattack", 0, targetCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, targetCharacter)
--			local transplantidentifier = "hearttransplant_q1"
--			if NTC.HasTag(usingCharacter, "organssellforfull") then
--				transplantidentifier = "hearttransplant"
--			end
			if damage < 90 then
				-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
				local function postSpawnFunc(args)
					local tags = {}

					if args.acidosis > 0 then
						table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
					elseif args.alkalosis > 0 then
						table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
					end
					if args.sepsis > 10 then
						table.insert(tags, "sepsis")
					end

					local tagstring = ""
					for index, value in ipairs(tags) do
						tagstring = tagstring .. value
						if index < #tags then
							tagstring = tagstring .. ","
						end
					end

					args.item.Tags = tagstring
					args.item.Condition = args.condition
				end
				local params = {
					acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
					alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
					sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
					condition = 100 - damage,
				}
				local inventorySpot = nil
				local parentInventory = item.ParentInventory
				if parentInventory then
					inventorySpot = parentInventory.FindIndex(item)
				end

				HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
				HF.RemoveItem(item)
			end
		end
		local rejectionchance = HF.Clamp(
			(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
				/ 150
				* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
			0,
			1
		)
	end
end


-- MANTIS ITEMS



NTGraft.ItemStartsWithMethods.mantisLiverAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
		conditionmodifier = -40
	end
	local damage = HF.GetAfflictionStrength(targetCharacter, "liverdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		HF.HasAffliction(targetCharacter, "liverremoved", 1)
		and limbtype == LimbType.Torso
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
    local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Liver")
		if damage == 100 then
			HF.AddAffliction(targetCharacter, "liverdamage", -workcondition, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			HF.SetAffliction(targetCharacter, "liverremoved", 0, usingCharacter)
      HF.SetAffliction(targetCharacter, "mantisLiverAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50, usingCharacter)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75, usingCharacter)
        HF.AddAffliction(targetCharacter, "sepsis", 3, usingCharacter)
      end
			HF.RemoveItem(item)
		else -- swap the organs and its generic and specific organ damage, avoiding unintentionally reducing the patients health
			local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
			HF.SetAffliction(targetCharacter, "liverdamage", 100 - workcondition, usingCharacter)
			HF.SetAffliction(targetCharacter, "liverremoved", 0, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)

      HF.SetAffliction(targetCharacter, "mantisLiverAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50, usingCharacter)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75, usingCharacter)
        HF.AddAffliction(targetCharacter, "sepsis", 3, usingCharacter)
      end

--			local transplantidentifier = "livertransplant_q1"
--			if NTC.HasTag(usingCharacter, "organssellforfull") then
--				transplantidentifier = "livertransplant"
--			end
			if damage < 90 then
				-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
				local function postSpawnFunc(args)
					local tags = {}

					if args.acidosis > 0 then
						table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
					elseif args.alkalosis > 0 then
						table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
					end
					if args.sepsis > 10 then
						table.insert(tags, "sepsis")
					end

					local tagstring = ""
					for index, value in ipairs(tags) do
						tagstring = tagstring .. value
						if index < #tags then
							tagstring = tagstring .. ","
						end
					end

					args.item.Tags = tagstring
					args.item.Condition = args.condition
				end
				local params = {
					acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
					alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
					sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
					condition = 100 - damage,
				}
				local inventorySpot = nil
				local parentInventory = item.ParentInventory
				if parentInventory then
					inventorySpot = parentInventory.FindIndex(item)
				end

				HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
				HF.RemoveItem(item)
			end
		end
		local rejectionchance = HF.Clamp(
			(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
				/ 150
				* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
			0,
			1
		)
	end
end


-- MUDRAPTOR ITEMS






NTGraft.ItemStartsWithMethods.mudraptorLungsAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
		conditionmodifier = -40
	end
	local damage = HF.GetAfflictionStrength(targetCharacter, "lungdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		HF.HasAffliction(targetCharacter, "lungremoved", 1)
		and limbtype == LimbType.Torso
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
    local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Lungs")
		if damage == 100 then
			HF.AddAffliction(targetCharacter, "lungdamage", -workcondition, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			HF.SetAffliction(targetCharacter, "lungremoved", 0, usingCharacter)
      HF.SetAffliction(targetCharacter, "mudraptorLungsAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75)
        HF.AddAffliction(targetCharacter, "sepsis", 3)
      end
			HF.RemoveItem(item)
		else -- swap the organs and its generic and specific organ damage, avoiding unintentionally reducing the patients health
			local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
			HF.SetAffliction(targetCharacter, "lungdamage", 100 - workcondition, targetCharacter)
			HF.SetAffliction(targetCharacter, "lungremoved", 0, usingCharacter)
			HF.SetAffliction(targetCharacter, "respiratoryarrest", 100, targetCharacter)
      
      HF.SetAffliction(targetCharacter, "mudraptorLungsAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75)
        HF.AddAffliction(targetCharacter, "sepsis", 3)
      end

			HF.SetAffliction(targetCharacter, "pneumothorax", 0, targetCharacter)
			HF.SetAffliction(targetCharacter, "needlec", 0, targetCharacter)

			HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, targetCharacter)
--			local transplantidentifier = "lungtransplant_q1"
--			if NTC.HasTag(usingCharacter, "organssellforfull") then
--				transplantidentifier = "lungtransplant"
--			end
			if damage < 90 then
				-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
				local function postSpawnFunc(args)
					local tags = {}

					if args.acidosis > 0 then
						table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
					elseif args.alkalosis > 0 then
						table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
					end
					if args.sepsis > 10 then
						table.insert(tags, "sepsis")
					end

					local tagstring = ""
					for index, value in ipairs(tags) do
						tagstring = tagstring .. value
						if index < #tags then
							tagstring = tagstring .. ","
						end
					end

					args.item.Tags = tagstring
					args.item.Condition = args.condition
				end
				local params = {
					acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
					alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
					sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
					condition = 100 - damage,
				}
				local inventorySpot = nil
				local parentInventory = item.ParentInventory
				if parentInventory then
					inventorySpot = parentInventory.FindIndex(item)
				end

				HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
				HF.RemoveItem(item)
			end
		end
		local rejectionchance = HF.Clamp(
			(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
				/ 150
				* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
			0,
			1
		)
	end
end



NTGraft.ItemMethods.mudraptorCellsAegis = function(item, usingCharacter, targetCharacter, limb)
  local limbtype = HF.NormalizeLimbType(limb.type)

  if limbtype ~= LimbType.Head then return end

  local medicalLevel = HF.GetSurgerySkill(usingCharacter)

  if(HF.HasAfflictionLimb(targetCharacter,"mudraptorHeadAffliction",limbtype,1)) or HF.HasAfflictionLimb(targetCharacter,"molochHeadAffliction",limbtype,1) then
    return end
  if(medicalLevel >= 70) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.AddAfflictionLimb(targetCharacter,"mudraptorHeadAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",40,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.AddAfflictionLimb(targetCharacter,"mudraptorHeadAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",65,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 70)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.AddAfflictionLimb(targetCharacter,"mudraptorHeadAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",55,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAfflictionLimb(targetCharacter,"mudraptorHeadAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",80,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
        HF.RemoveItem(item)
      end
    else
      HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
    end
  end
end



-- BROODMOTHER ITEMS




NTGraft.ItemStartsWithMethods.broodmotherLiverAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
		conditionmodifier = -40
	end
	local damage = HF.GetAfflictionStrength(targetCharacter, "liverdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		HF.HasAffliction(targetCharacter, "liverremoved", 1)
		and limbtype == LimbType.Torso
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
    local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Liver")
		if damage == 100 then
			HF.AddAffliction(targetCharacter, "liverdamage", -workcondition, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			HF.SetAffliction(targetCharacter, "liverremoved", 0, usingCharacter)
      HF.SetAffliction(targetCharacter, "broodmotherLiverAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50, usingCharacter)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75, usingCharacter)
        HF.AddAffliction(targetCharacter, "sepsis", 3, usingCharacter)
      end
			HF.RemoveItem(item)
		else -- swap the organs and its generic and specific organ damage, avoiding unintentionally reducing the patients health
			local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
			HF.SetAffliction(targetCharacter, "liverdamage", 100 - workcondition, usingCharacter)
			HF.SetAffliction(targetCharacter, "liverremoved", 0, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)

      HF.SetAffliction(targetCharacter, "broodmotherLiverAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50, usingCharacter)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75, usingCharacter)
        HF.AddAffliction(targetCharacter, "sepsis", 3, usingCharacter)
      end

--			local transplantidentifier = "livertransplant_q1"
--			if NTC.HasTag(usingCharacter, "organssellforfull") then
--				transplantidentifier = "livertransplant"
--			end
			if damage < 90 then
				-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
				local function postSpawnFunc(args)
					local tags = {}

					if args.acidosis > 0 then
						table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
					elseif args.alkalosis > 0 then
						table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
					end
					if args.sepsis > 10 then
						table.insert(tags, "sepsis")
					end

					local tagstring = ""
					for index, value in ipairs(tags) do
						tagstring = tagstring .. value
						if index < #tags then
							tagstring = tagstring .. ","
						end
					end

					args.item.Tags = tagstring
					args.item.Condition = args.condition
				end
				local params = {
					acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
					alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
					sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
					condition = 100 - damage,
				}
				local inventorySpot = nil
				local parentInventory = item.ParentInventory
				if parentInventory then
					inventorySpot = parentInventory.FindIndex(item)
				end

				HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
				HF.RemoveItem(item)
			end
		end
		local rejectionchance = HF.Clamp(
			(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
				/ 150
				* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
			0,
			1
		)
	end
end


-- TIGER THRESHER ITEMS





NTGraft.ItemMethods.tigerThresherCellsAegis = function(item, usingCharacter, targetCharacter, limb)
  local limbtype = HF.NormalizeLimbType(limb.type)

  if limbtype ~= LimbType.Head then return end

  local medicalLevel = HF.GetSurgerySkill(usingCharacter)

  if(HF.HasAfflictionLimb(targetCharacter,"tigerThresherJawAffliction",limbtype,1))
  or HF.HasAfflictionLimb(targetCharacter,"boneThresherJawAffliction",limbtype,1) 
  or HF.HasAfflictionLimb(targetCharacter,"charybdisJawAffliction",limbtype,1)
  or HF.HasAffliction(targetCharacter,"latcherTongueAffliction",1) then
    return end
  if(medicalLevel >= 70) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.AddAfflictionLimb(targetCharacter,"tigerThresherJawAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",40,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.AddAfflictionLimb(targetCharacter,"tigerThresherJawAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",65,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 70)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.AddAfflictionLimb(targetCharacter,"tigerThresherJawAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",55,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAfflictionLimb(targetCharacter,"tigerThresherJawAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",80,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
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

  if(HF.HasAfflictionLimb(targetCharacter,"crawlerTailAegis",limbtype,1)) then
    return
  elseif(HF.HasAfflictionLimb(targetCharacter,"tigerThresherTailAffliction",limbtype,1)) then
    return
  end
  if(medicalLevel >= 75) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.SetAffliction(targetCharacter,"tigerThresherTailAffliction",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",50,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.SetAffliction(targetCharacter,"tigerThresherTailAffliction",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",75,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 75)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.SetAffliction(targetCharacter,"tigerThresherTailAffliction",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",65,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"tigerThresherTailAffliction",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",90,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
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

  if(HF.HasAfflictionLimb(targetCharacter,"tigerThresherJawAffliction",limbtype,1))
  or HF.HasAfflictionLimb(targetCharacter,"boneThresherJawAffliction",limbtype,1)
  or HF.HasAfflictionLimb(targetCharacter,"charybdisJawAffliction",limbtype,1)
  or HF.HasAffliction(targetCharacter,"latcherTongueAffliction",1) then
    return end
  if(medicalLevel >= 70) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.AddAfflictionLimb(targetCharacter,"boneThresherJawAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",40,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.AddAfflictionLimb(targetCharacter,"boneThresherJawAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",65,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 70)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.AddAfflictionLimb(targetCharacter,"boneThresherJawAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",55,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAfflictionLimb(targetCharacter,"boneThresherJawAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",80,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
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

  if(HF.HasAfflictionLimb(targetCharacter,"hammerTorsoAffliction",limbtype,1))
  or HF.HasAfflictionLimb(targetCharacter,"endwormTorsoAffliction",limbtype,1) then
    return end
  if(medicalLevel >= 70) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.AddAfflictionLimb(targetCharacter,"hammerheadTorsoAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",50,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.AddAfflictionLimb(targetCharacter,"hammerheadTorsoAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",75,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 70)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.AddAfflictionLimb(targetCharacter,"hammerheadTorsoAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",65,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAfflictionLimb(targetCharacter,"hammerheadTorsoAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",90,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
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

  if(medicalLevel >= 70) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.SetAffliction(targetCharacter,"hammerheadLimbsAffliction",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",50,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.SetAffliction(targetCharacter,"hammerheadLimbsAffliction",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",75,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 70)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.SetAffliction(targetCharacter,"hammerheadLimbsAffliction",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",65,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"hammerheadLimbsAffliction",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",90,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
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

  if(HF.HasAfflictionLimb(targetCharacter,"molochHeadAffliction",limbtype,1))
  or HF.HasAfflictionLimb(targetCharacter,"mudraptorHeadAffliction",limbtype,1) then
    return
  end

  if(HF.HasAffliction(targetCharacter,"molochCracked",95)) then
    if (medicalLevel >= 70) then
      if(HF.HasAffliction(targetCharacter,"retractedskin", 1)) then
        HF.SetAffliction(targetCharacter, "molochCracked", 20, usingCharacter)
        HF.SetAffliction(targetCharacter, "molochCrackedSprite", 0, usingCharacter)
        HF.AddAfflictionLimb(targetCharacter, "molochHeadAffliction",limbtype, 10, usingCharacter)
        HF.RemoveItem(item)
      end
    else
      math.randomseed(os.time())
      local skillcheck = math.random(0, 70)
      if (medicalLevel >= skillcheck) then
        if(HF.HasAffliction(targetCharacter,"retractedskin", 1)) then
          HF.SetAffliction(targetCharacter, "molochCracked", 20, usingCharacter)
          HF.SetAffliction(targetCharacter, "molochCrackedSprite", 0, usingCharacter)
          HF.AddAfflictionLimb(targetCharacter, "molochHeadAffliction",limbtype, 10, usingCharacter)
          HF.RemoveItem(item)
        end
      else
        HF.AddAffliction(targetCharacter, "bleeding", 3, usingCharacter)
      end
    end
    return
  end
  if(medicalLevel >= 70) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.AddAfflictionLimb(targetCharacter,"molochHeadAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",60,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.AddAfflictionLimb(targetCharacter,"molochHeadAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",85,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 70)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.AddAfflictionLimb(targetCharacter,"molochHeadAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",80,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAfflictionLimb(targetCharacter,"molochHeadAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",95,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
        HF.RemoveItem(item)
      end
    else
      HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
    end
  end
end


--VIPERLING ITEMS




NTGraft.ItemStartsWithMethods.viperlingLiverAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
		conditionmodifier = -40
	end
	local damage = HF.GetAfflictionStrength(targetCharacter, "liverdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		HF.HasAffliction(targetCharacter, "liverremoved", 1)
		and limbtype == LimbType.Torso
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
    local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Liver")
		if damage == 100 then
			HF.AddAffliction(targetCharacter, "liverdamage", -workcondition, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			HF.SetAffliction(targetCharacter, "liverremoved", 0, usingCharacter)
      HF.SetAffliction(targetCharacter, "viperlingLiverAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50, usingCharacter)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75, usingCharacter)
        HF.AddAffliction(targetCharacter, "sepsis", 3, usingCharacter)
      end
			HF.RemoveItem(item)
		else -- swap the organs and its generic and specific organ damage, avoiding unintentionally reducing the patients health
			local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
			HF.SetAffliction(targetCharacter, "liverdamage", 100 - workcondition, usingCharacter)
			HF.SetAffliction(targetCharacter, "liverremoved", 0, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, usingCharacter)

      HF.SetAffliction(targetCharacter, "viperlingLiverAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 50, usingCharacter)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75, usingCharacter)
        HF.AddAffliction(targetCharacter, "sepsis", 3, usingCharacter)
      end

--			local transplantidentifier = "livertransplant_q1"
--			if NTC.HasTag(usingCharacter, "organssellforfull") then
--				transplantidentifier = "livertransplant"
--			end
			if damage < 90 then
				-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
				local function postSpawnFunc(args)
					local tags = {}

					if args.acidosis > 0 then
						table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
					elseif args.alkalosis > 0 then
						table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
					end
					if args.sepsis > 10 then
						table.insert(tags, "sepsis")
					end

					local tagstring = ""
					for index, value in ipairs(tags) do
						tagstring = tagstring .. value
						if index < #tags then
							tagstring = tagstring .. ","
						end
					end

					args.item.Tags = tagstring
					args.item.Condition = args.condition
				end
				local params = {
					acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
					alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
					sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
					condition = 100 - damage,
				}
				local inventorySpot = nil
				local parentInventory = item.ParentInventory
				if parentInventory then
					inventorySpot = parentInventory.FindIndex(item)
				end

				HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
				HF.RemoveItem(item)
			end
		end
		local rejectionchance = HF.Clamp(
			(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
				/ 150
				* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
			0,
			1
		)
	end
end



--WATCHER ITEMS


NTGraft.ItemMethods.watcherEyeAegis = function(item, usingCharacter, targetCharacter, limb)
  local limbtype = HF.NormalizeLimbType(limb.type)

  if NTEYE ~= nil then return end

  if limbtype ~= LimbType.Head then return end

  local medicalLevel = HF.GetSurgerySkill(usingCharacter)

  if(HF.HasAfflictionLimb(targetCharacter,"fractalGuardianEyesAffliction",limbtype,1))
  or HF.HasAfflictionLimb(targetCharacter,"watcherEyesAffliction",limbtype,1) then
    return end
  if(medicalLevel >= 80) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.AddAfflictionLimb(targetCharacter,"watcherEyesAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",70,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.AddAfflictionLimb(targetCharacter,"watcherEyesAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",95,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 80)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.AddAfflictionLimb(targetCharacter,"watcherEyesAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",80,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAfflictionLimb(targetCharacter,"watcherEyesAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",95,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
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

  if(HF.HasAfflictionLimb(targetCharacter,"charybdisJawAffliction",limbtype,1))
  or HF.HasAfflictionLimb(targetCharacter,"tigerThresherJawAffliction",limbtype,1)
  or HF.HasAfflictionLimb(targetCharacter,"boneThresherJawAffliction",limbtype,1)
  or HF.HasAffliction(targetCharacter,"latcherTongueAffliction",1) then
    return end
  if(medicalLevel >= 90) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.AddAfflictionLimb(targetCharacter,"charybdisJawAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",80,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.AddAfflictionLimb(targetCharacter,"charybdisJawAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",95,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 90)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.AddAfflictionLimb(targetCharacter,"charybdisJawAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",85,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAfflictionLimb(targetCharacter,"charybdisJawAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",100,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
        HF.RemoveItem(item)
      end
    else
      HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
    end
  end
end





--LATCHER RELATED ITEMS



NTGraft.ItemStartsWithMethods.latcherHeartAegis = function(item, usingCharacter, targetCharacter, limb)
	local limbtype = limb.type
	local conditionmodifier = 0
	if not HF.GetSurgerySkillRequirementMet(usingCharacter, 40) then
		conditionmodifier = -40
	end
	local damage = HF.GetAfflictionStrength(targetCharacter, "heartdamage", 0)
	local workcondition = HF.Clamp(item.Condition + conditionmodifier, 0, 100)
	if
		HF.HasAffliction(targetCharacter, "heartremoved", 1)
		and limbtype == LimbType.Torso
		and HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)
	then
    local transplantidentifier = organIdentifier(targetCharacter, usingCharacter, "Heart")
		if damage == 100 then
			HF.AddAffliction(targetCharacter, "heartdamage", -workcondition, usingCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", -workcondition / 5, usingCharacter)
			HF.SetAffliction(targetCharacter, "heartremoved", 0, usingCharacter)
      HF.SetAffliction(targetCharacter, "latcherHeartAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 90)
        HF.AddAffliction(targetCharacter, "sepsis", 3)
      end
			HF.RemoveItem(item)
		else -- swap the organs and its generic and specific organ damage, avoiding unintentionally reducing the patients health
			local newdamage = HF.Clamp((100 - damage) - workcondition, -100, 100)
			HF.SetAffliction(targetCharacter, "heartdamage", 100 - workcondition, targetCharacter)
			HF.SetAffliction(targetCharacter, "heartremoved", 0, usingCharacter)
			HF.SetAffliction(targetCharacter, "cardiacarrest", 100, targetCharacter)

      HF.SetAffliction(targetCharacter, "latcherHeartAffliction", 100, usingCharacter)
      if (HF.HasAffliction(targetCharacter, "graftingcureoverdose", 49)) then
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 75)
      else
        HF.AddAffliction(targetCharacter, "crossspeciesrejection", 90)
        HF.AddAffliction(targetCharacter, "sepsis", 3)
      end

			HF.SetAffliction(targetCharacter, "tamponade", 0, targetCharacter)
			HF.SetAffliction(targetCharacter, "heartattack", 0, targetCharacter)
			HF.AddAffliction(targetCharacter, "organdamage", newdamage / 5, targetCharacter)
--			local transplantidentifier = "hearttransplant_q1"
--			if NTC.HasTag(usingCharacter, "organssellforfull") then
--				transplantidentifier = "hearttransplant"
--			end
			if damage < 90 then
				-- add acidosis, alkalosis and sepsis to the bloodpack if the donor has them
				local function postSpawnFunc(args)
					local tags = {}

					if args.acidosis > 0 then
						table.insert(tags, "acid:" .. tostring(HF.Round(args.acidosis)))
					elseif args.alkalosis > 0 then
						table.insert(tags, "alkal:" .. tostring(HF.Round(args.alkalosis)))
					end
					if args.sepsis > 10 then
						table.insert(tags, "sepsis")
					end

					local tagstring = ""
					for index, value in ipairs(tags) do
						tagstring = tagstring .. value
						if index < #tags then
							tagstring = tagstring .. ","
						end
					end

					args.item.Tags = tagstring
					args.item.Condition = args.condition
				end
				local params = {
					acidosis = HF.GetAfflictionStrength(targetCharacter, "acidosis"),
					alkalosis = HF.GetAfflictionStrength(targetCharacter, "alkalosis"),
					sepsis = HF.GetAfflictionStrength(targetCharacter, "sepsis"),
					condition = 100 - damage,
				}
				local inventorySpot = nil
				local parentInventory = item.ParentInventory
				if parentInventory then
					inventorySpot = parentInventory.FindIndex(item)
				end

				HF.SpawnItemPlusFunction(transplantidentifier, postSpawnFunc, params, parentInventory, inventorySpot)
				HF.RemoveItem(item)
			end
		end
		local rejectionchance = HF.Clamp(
			(HF.GetAfflictionStrength(targetCharacter, "immunity", 0) - 10)
				/ 150
				* NTC.GetMultiplier(usingCharacter, "organrejectionchance"),
			0,
			1
		)
	end
end


NTGraft.ItemMethods.latcherTongueAegis = function(item, usingCharacter, targetCharacter, limb)
  local limbtype = HF.NormalizeLimbType(limb.type)

  if limbtype ~= LimbType.Head then return end

  local medicalLevel = HF.GetSurgerySkill(usingCharacter)

  if(HF.HasAfflictionLimb(targetCharacter,"tigerThresherJawAffliction",limbtype,1))
  or HF.HasAfflictionLimb(targetCharacter,"boneThresherJawAffliction",limbtype,1) 
  or HF.HasAfflictionLimb(targetCharacter,"charybdisJawAffliction",limbtype,1)
  or HF.HasAffliction(targetCharacter,"latcherTongueAffliction",1) then
    return end
  if(medicalLevel >= 90) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.SetAffliction(targetCharacter,"latcherTongueAffliction",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",80,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.SetAffliction(targetCharacter,"latcherTongueAffliction",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",95,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 90)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.SetAffliction(targetCharacter,"latcherTongueAffliction",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",85,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"latcherTongueAffliction",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",100,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
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

  if(HF.HasAfflictionLimb(targetCharacter,"endwormTorsoAffliction",limbtype,1))
  or HF.HasAfflictionLimb(targetCharacter,"hammerheadTorsoAffliction",limbtype,1) then
    return end
  if(medicalLevel >= 90) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.AddAfflictionLimb(targetCharacter,"endwormTorsoAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",60,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.AddAfflictionLimb(targetCharacter,"endwormTorsoAffliction",limbtype,10,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",85,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 90)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.AddAfflictionLimb(targetCharacter,"endwormTorsoAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",65,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.AddAfflictionLimb(targetCharacter,"endwormTorsoAffliction",limbtype,10,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",90,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
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

  if(HF.HasAfflictionLimb(targetCharacter,"crawlerTailAegis",limbtype,1)) then
    return
  elseif(HF.HasAfflictionLimb(targetCharacter,"tigerThresherTailAffliction",limbtype,1)) then
    return
  elseif(HF.HasAfflictionLimb(targetCharacter,"orangeboyTailAffliction",limbtype,1)) then
    return
  end
  if(medicalLevel >= 30) then
    if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99))) then
      HF.SetAffliction(targetCharacter,"orangeboyTailAffliction",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",30,usingCharacter,0)
      HF.RemoveItem(item)
    elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
      HF.SetAffliction(targetCharacter,"orangeboyTailAffliction",100,usingCharacter,0)
      HF.AddAffliction(targetCharacter,"crossspeciesrejection",45,usingCharacter,0)
      HF.SetAffliction(targetCharacter,"sepsis",3,usingCharacter,0)
      HF.RemoveItem(item)
    end
  else
    math.randomseed(os.time())
    local skillcheck = math.random(0, 30)
    if (medicalLevel >= skillcheck) then
      if(HF.HasAffliction(targetCharacter,"graftingcureoverdose",50) and (HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,1))) then
        HF.SetAffliction(targetCharacter,"orangeboyTailAffliction",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",40,usingCharacter,0)
        HF.RemoveItem(item)
      elseif(HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,99)) then
        HF.SetAffliction(targetCharacter,"orangeboyTailAffliction",100,usingCharacter,0)
        HF.AddAffliction(targetCharacter,"crossspeciesrejection",55,usingCharacter,0)
        HF.SetAffliction(targetCharacter,"sepsis",5,usingCharacter,0)
        HF.RemoveItem(item)
      end
    else
      HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
    end
  end
end

