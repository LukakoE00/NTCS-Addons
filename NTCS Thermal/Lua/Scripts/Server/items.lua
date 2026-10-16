
local itemLoader = NTCS.ItemFunctionLoader("NTCS_Thermal")

-- Function to determine which character is the affliction being applied to.
local function ConvertCharacter(usingCharacter,targetCharacter)
    if targetCharacter == nil then
        return usingCharacter
    else
        return targetCharacter
    end
end

-- Warm I.V Bag Low key stole all of this from Neuro's ice pack code.
NTCS_Thermal.warm_iv_bag = function(itemPackage)
        local item = itemPackage.item
        local usingCharacter = itemPackage.user.Human
        local targetCharacter = itemPackage.target.Human
        local targetLimb = itemPackage.targetLimb
        if item.Condition <= 25 then
		return
	end
	local success = NTCS.HF.BoolToNum(NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", 40), 1)
        NTCS.HF.AddAffliction(targetCharacter, "elevated_core_temperature", 5 + success * 25, usingCharacter)
        THERM.PlaySound("thermalsfx_liquidiv",targetCharacter)
	item.Condition = 0
end

itemLoader:Register("warm_iv_bag", NTCS_Thermal.warm_iv_bag)

-- Warm rag
NTCS_Thermal.warm_rag = function (itemPackage)
        local item = itemPackage.item
        local usingCharacter = itemPackage.user.Human
        local targetCharacter = itemPackage.target.Human
        local targetLimb = itemPackage.targetLimb
        if item.Condition <= 25 then
		return
	end
	local limbtype = targetLimb
	local success = NTCS.HF.BoolToNum(NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", 20), 1)
	NTCS.HF.AddAfflictionLimb(targetCharacter, "warmth", limbtype, 75 + success * 25, usingCharacter)

	item.Condition = item.Condition - 25
end

itemLoader:Register("warm_rag", NTCS_Thermal.warm_rag)

-- A.A.F.N
NTCS_Thermal.aafn = function (itemPackage)
        local item = itemPackage.item
        local usingCharacter = itemPackage.user.Human
        local targetCharacter = itemPackage.target.Human
        local targetLimb = itemPackage.targetLimb
        local success = NTCS.HF.BoolToNum(NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", 60), 1)
        local limbtype = targetLimb
        if NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "clampedbleeders", 0) == 100 then
                NTCS.HF.AddAffliction(targetCharacter, "aafn", 10 + success * 15, usingCharacter)
                item.Condition = item.Condition - 25
                return
        end
	NTCS.HF.AddAffliction(targetCharacter, "aafn", 5 + success * 5, usingCharacter)
        NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 5, usingCharacter)
        NTCS.HF.AddAfflictionLimb(targetCharacter, "lacerations", limbtype, 10, usingCharacter)
	item.Condition = item.Condition - 25
end

itemLoader:Register("aafn", NTCS_Thermal.aafn)

-- Skin Grafter
NTCS_Thermal.skin_grafter = function (itemPackage)
        local item = itemPackage.item
        local usingCharacter = itemPackage.user.Human
        local targetCharacter = itemPackage.target.Human
        local targetLimb = itemPackage.targetLimb
        local success = NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", 50)
        local limbtype = targetLimb
        if NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "retractedskin", 0) ~= 100 then
                NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 3, usingCharacter)
                NTCS.HF.AddAfflictionLimb(targetCharacter, "lacerations", limbtype, 4, usingCharacter)
                return
        end
        if success then
                if (NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "stretched_skin", 0) + 10) <= 20 then
                        NTCS.HF.AddAfflictionLimb(targetCharacter, "removed_skin", limbtype, 10, usingCharacter)
                        NTCS.HF.AddAfflictionLimb(targetCharacter, "stretched_skin", limbtype, 10, usingCharacter)
                        NTCS.HF.GiveItem(usingCharacter, "ntt_skin")
                        return
                end
        else
            if (NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "stretched_skin", 0) + 10) <= 20 then
                        NTCS.HF.AddAfflictionLimb(targetCharacter, "removed_skin", limbtype, 10, usingCharacter)
                        NTCS.HF.AddAfflictionLimb(targetCharacter, "stretched_skin", limbtype, 10, usingCharacter)
                        NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 1, usingCharacter)
                        NTCS.HF.AddAfflictionLimb(targetCharacter, "lacerations", limbtype, 2, usingCharacter)
                        NTCS.HF.GiveItem(usingCharacter, "ntt_skin")
                        return
                end
        end
end

itemLoader:Register("skin_grafter", NTCS_Thermal.skin_grafter)

-- Skin Grafter
NTCS_Thermal.ntt_skin = function (itemPackage)
        local item = itemPackage.item
        local usingCharacter = itemPackage.user.Human
        local targetCharacter = itemPackage.target.Human
        local targetLimb = itemPackage.targetLimb
        local success = NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", 50)
        local limbtype = targetLimb
        
        if NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "retractedskin", 0) ~= 100 
                and NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "grafted_skin", 0) == 0 then
                return
        end

        if success then
                NTCS.HF.AddAfflictionLimb(targetCharacter, "grafted_skin", limbtype, 10, usingCharacter)
        else
                NTCS.HF.AddAfflictionLimb(targetCharacter, "grafted_skin", limbtype, 10, usingCharacter)
                NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 5, usingCharacter)
        end
        item.Condition = 0
end

itemLoader:Register("ntt_skin", NTCS_Thermal.ntt_skin)

local LimbsToCheck2 = {LimbType.Head,LimbType.Torso,LimbType.RightArm,LimbType.LeftArm,LimbType.RightThigh,LimbType.LeftThigh}

-- Thermometer
NTCS_Thermal.handheld_thermometer = function (itemPackage)
        local item = itemPackage.item
        local usingCharacter = itemPackage.user.Human
        local targetCharacter = itemPackage.target.Human
        local targetLimb = itemPackage.targetLimb

        -- Get Contained item.
        local containedItem = item.OwnInventory.GetItemAt(0)
        if containedItem == nil then
                return
        end
        local hasVoltage = containedItem.Condition > 0
        -- Make sure the thermometer has a battery.
        if hasVoltage and THERM.GetCharacter(targetCharacter.ID)  ~= nil then
                containedItem.Condition = containedItem.Condition - 2.5
                -- Translations!
                THERM.PlaySound("thermalsfx_thermometer",targetCharacter)
                local actuallimb = targetLimb.type
                local HypothermiaLevel = NTCS.Config.Get("NewHypothermiaLevel", 36) - 1
                local HyperthermiaLevel = NTCS.Config.Get("NewHyperthermiaLevel", 39) - 1
                local character = ConvertCharacter(usingCharacter,targetCharacter)
                local LimbTemp = THERM.Round(NTCS.HF.GetAfflictionStrengthLimb(character, actuallimb, "ntt_temperature", NTCS.Config.Get("NormalBodyTemp", 38)) - 1, 1)
                local CharacterClient = NTCS.HF.CharacterToClient(usingCharacter)
                local Language = function ()
                        if CharacterClient ~= nil then
                                if Translation[tostring(CharacterClient.Language)] ~= nil then
                                        return tostring(CharacterClient.Language)
                                end
                                return "English" -- Default to english since language is implemented.
                        end
                        if Translation[tostring(GameSettings.CurrentConfig.Language)] ~= nil then
                                return tostring(GameSettings.CurrentConfig.Language)
                        end
                        return "English"
                end
                local BaseColor = "100,100,200"
                local NameColor = "125,125,225"
                -- Temp Colors
                local BoilingColor     = "255,40,0"
                local HotColor         = "240,110,40"
                local WarmColor        = "240,200,150"
                local AverageColor     = "100,200,100"
                local ColdColor        = "170,230,200"
                local ChillyColor      = "40,140,230"
                local FreezingColor    = "0,60,255"
                local CurrentTempColor = AverageColor

                -- Determine Temp Color
                local function TempColor(TempStrength)
                        if TempStrength < 1 then
                                return FreezingColor
                        elseif TempStrength < HypothermiaLevel/NTCS_Thermal.MediumHypothermiaScaling then
                                return ChillyColor
                        elseif TempStrength < HypothermiaLevel/NTCS_Thermal.LowHypothermiaScaling then
                                return ColdColor
                        elseif TempStrength > HypothermiaLevel and TempStrength < HyperthermiaLevel then
                                return AverageColor
                        elseif TempStrength >  HyperthermiaLevel * NTCS_Thermal.ExtremeHyperthermiaScaling then
                                return BoilingColor
                        elseif TempStrength > HyperthermiaLevel * NTCS_Thermal.MediumHyperthermiaScaling then
                                return HotColor
                        elseif TempStrength > HyperthermiaLevel * NTCS_Thermal.LowHyperthermiaScaling then 
                                return WarmColor
                        else 
                                return AverageColor
                        end
                end

                -- Determine if a patient has hypothermia or hyperthermia.
                local function ThermiaValue(Temp)
                        if Temp < HypothermiaLevel then
                                return Translation[Language()].Hypothermic
                        elseif Temp > HyperthermiaLevel then
                                return Translation[Language()].Hyperthermic
                        else
                                return Translation[Language()].NormalTemp
                        end
                end

                local BodyTemp = THERM.AverageBodyTemp(targetCharacter)
                local BodyTempColor = TempColor(BodyTemp)
                local BodyTempThermia = ThermiaValue(BodyTemp)
                CurrentTempColor = TempColor(LimbTemp)
                local CurrentTempThermia = ThermiaValue(LimbTemp)
                local Report = 
                                        -- Intial Readout -------------------
                                        "‖color:" 
                                        .. BaseColor 
                                        .. "‖" 
                                        .. Translation[Language()].Readout
                                        .. "‖color:end‖"
                                        .. "‖color:" 
                                        .. NameColor 
                                        .. "‖" 
                                        .. character.Name
                                        .. "‖color:end‖"
                                        .. ":\n"
                                        .. "\n"

                                        -- Limb Checked --------------------
                                        .. "‖color:" 
                                        .. NameColor 
                                        .. "‖" 
                                        .. Translation[Language()].LimbsToCheck[actuallimb]
                                        .. "‖color:end‖"
                                        .. ":\n"
                                        .. "‖color:" 
                                        .. CurrentTempColor
                                        .. "‖" 
                                        .. tostring(LimbTemp)
                                        .. "°C/"
                                        .. tostring(THERM.Round(((LimbTemp * 9/5)+32),1))
                                        .. "°F"
                                        .. "\n"
                                        .. CurrentTempThermia
                                        .."‖color:end‖"
                                        .. "\n"
                                        .. "\n"

                                        -- Body ----------------------------
                                        .. "‖color:" 
                                        .. NameColor
                                        .. "‖" 
                                        .. Translation[Language()].Body
                                        .. "‖color:end‖"
                                        .. ":\n"
                                        .. "‖color:" 
                                        .. BodyTempColor
                                        .. "‖" 
                                        .. tostring(BodyTemp)
                                        .. " °C/"
                                        .. tostring(THERM.Round(((BodyTemp * 9/5)+32),1))
                                        .. "°F"
                                        .. "\n"
                                        .. BodyTempThermia
                                        .. "‖color:end‖"

                -- Send the temperature to chat via the rat jacuzzi overlord commands.
                Timer.Wait(function ()
                        NTCS.HF.DMClient(CharacterClient, Report)  
                end, 1000)     
        end
end

itemLoader:Register("handheld_thermometer", NTCS_Thermal.handheld_thermometer)