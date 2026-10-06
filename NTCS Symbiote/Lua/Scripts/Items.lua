local itemLoader = NTCS.ItemFunctionLoader("NTCS_Symbiote")

Timer.Wait(function()

    -- Remove these afflictions on suturing
    NTCS.NTC.AddSuturableAffliction("bonecuttorso", 0, "surgeryincision")
    NTCS.NTC.AddSuturableAffliction("surgery_huskhealth", 0, "surgeryincision")

    -- Add Stabbing Parasites to the Scalpel's functionality
    NTCS_Symbiote.StabParasites = function(d, OriginalItemFunction)
        itemLoader:CallOld(OriginalItemFunction, "Neurotrauma C#", d)

        local item = d.item
        local usingCharacter = d.user.Human
        local targetCharacter = d.target.Human
        local targetLimb = d.targetLimb

        local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)

        -- If not on the torso, tap out
        if limbtype ~= LimbType.Torso then return end
    
        -- Doesn't work in stasis
        if (NTCS.HF.HasAffliction(targetCharacter,"stasis", 0.1)) then 
            return 
        end

        local HuskHealth = NTCS.HF.GetAfflictionStrength(targetCharacter,"surgery_huskhealth")
        
        -- If not in stabbing phase, tap out
        if HuskHealth < 0.1 then return end

        local CalyxanideStrength = NTCS.HF.GetAfflictionStrength(targetCharacter,"af_calyxanide")
    
        if (NTCS.HF.CanPerformSurgeryOn(targetCharacter)) then
            
            -- Skillcheck is 30 with and 100 without calyxanide
            if (NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter, 30 + 70 * NTCS.HF.BoolToNum(CalyxanideStrength < 0.1))) then
                -- Remove some husk health
                local NewHuskHealth = NTCS.HF.Clamp(HuskHealth-10,5,100)
                NTCS.HF.SetAffliction(targetCharacter, "surgery_huskhealth", NewHuskHealth)
                NTCS.HF.GiveItem(targetCharacter,"ntsfx_huskhurt")
            else
                if CalyxanideStrength < 0.1 and HuskHealth > 20 then
                    -- No calyxanide and the Husk is active
                    -- Determine what limb is being retaliated against
                    local hitLimb = LimbType.RightArm
                    if
                        NTCS.HF.LimbIsDislocated(usingCharacter,hitLimb) or
                        NTCS.HF.LimbIsBroken(usingCharacter,hitLimb) or
                        NTCS.HF.LimbIsAmputated(usingCharacter,hitLimb)
                    then 
                        hitLimb = LimbType.LeftArm 
                    end

                    NTCS.HF.AddAfflictionLimb(usingCharacter, "bleeding", hitLimb, 5)
                    NTCS.HF.AddAfflictionLimb(usingCharacter, "bitewounds", hitLimb, 10)
                    NTCS.HF.AddAffliction(usingCharacter, "stun", 0.2)

                    -- 20% chance of getting the unfortunate soul holding the scalpel infected
                    if NTCS.HF.Chance(0.2) then
                        NTCS.HF.AddAffliction(usingCharacter, "huskinfection", 1)
                    end
                    NTCS.HF.GiveItem(targetCharacter, "ntsfx_huskhurt")
                else
                    -- stop stabbing the patient, stupid
                    NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype,10,usingCharacter)
                    NTCS.HF.AddAfflictionLimb(targetCharacter, "lacerations", limbtype,10,usingCharacter)
                end
            end
        end
    end

    local StabParasites = function (d)
        NTCS_Symbiote.StabParasites(d, "advscalpel")
    end

    itemLoader:Override("advscalpel", StabParasites)

    -- Add ripping parasites out of the patients chest cavity to the hemostats functionality
    NTCS_Symbiote.RemoveParasites = function(d, OriginalItemFunction) 
        itemLoader:CallOld(OriginalItemFunction, "Neurotrauma C#", d)

        local item = d.item
        local usingCharacter = d.user.Human
        local targetCharacter = d.target.Human
        local targetLimb = d.targetLimb

        local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)

        -- If not on the torso, tap out
        if limbtype ~= LimbType.Torso then return end
    
        -- Doesn't work in stasis
        if (NTCS.HF.HasAffliction(targetCharacter,"stasis", 0.1)) then 
            return 
        end

        local HuskHealth = NTCS.HF.GetAfflictionStrength(targetCharacter,"surgery_huskhealth")
        
        -- don't work if we're not in the "grabbing the parasite by the balls" phase of treatment
        if (HuskHealth > 20) or (HuskHealth < 0.1) then return end
    
        if(NTCS.HF.CanPerformSurgeryOn(targetCharacter)) then
            if(NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter, 30)) then
                -- rip that sucker out for good
                -- ...but first, give the patient lung damage equivalent to the remaining husk health
                NTCS.HF.AddAffliction(targetCharacter, "lungdamage", HuskHealth * 2 + NTCS.HF.Clamp(50 - NTCS.HF.GetSurgerySkill(usingCharacter),0,30))
                NTCS.HF.SetAffliction(targetCharacter, "surgery_huskhealth", 0)
                NTCS.HF.SetAffliction(targetCharacter, "huskinfection", 0)
                NTCS.HF.GiveItem(targetCharacter, "ntsfx_huskdeath")
                NTCS.HF.GiveSkill(usingCharacter, "medical", 3)
            else
                -- stop stabbing the patient, stupid
                NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 10, usingCharacter)
                NTCS.HF.AddAfflictionLimb(targetCharacter, "lacerations", limbtype, 10, usingCharacter)
            end
        end
    end

    local RemoveParasites = function (d)
        NTCS_Symbiote.RemoveParasites(d, "advhemostat")
    end

    itemLoader:Override("advhemostat", RemoveParasites)

    -- Add sawing torso bones to the bonesaw
    NTCS_Symbiote.SawRibs = function(d, OriginalItemFunction) 
        itemLoader:CallOld(OriginalItemFunction, "Neurotrauma C#", d)

        local item = d.item
        local usingCharacter = d.user.Human
        local targetCharacter = d.target.Human
        local targetLimb = d.targetLimb

        local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)

        -- If not on the torso, tap out
        if limbtype ~= LimbType.Torso then return end
    
        -- Doesn't work in stasis
        if (NTCS.HF.HasAffliction(targetCharacter,"stasis", 0.1)) then 
            return 
        end

        -- don't work if we've already cut the torso open
        if NTCS.HF.HasAffliction(targetCharacter,"bonecuttorso",1) then 
            return 
        end
    
        if(NTCS.HF.CanPerformSurgeryOn(targetCharacter) and NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", limbtype, 99)) then
            if (NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter,50)) then
                NTCS.HF.AddAffliction(targetCharacter, "bonecuttorso", 1 + NTCS.HF.GetSurgerySkill(usingCharacter) / 2, usingCharacter)
            else
                NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limbtype, 15, usingCharacter)
                NTCS.HF.AddAfflictionLimb(targetCharacter, "internaldamage", limbtype, 6, usingCharacter)
                NTCS.HF.AddAfflictionLimb(targetCharacter, "lacerations", limbtype, 4, usingCharacter)
            end
        end
    end

    local SawRibs = function (d)
        NTCS_Symbiote.SawRibs(d, "surgerysaw")
    end

    itemLoader:Override("surgerysaw", SawRibs)

    -- Make it so trying to defib someones parasite will do funny things
    NTCS_Symbiote.DefibParasite = function(d, OriginalItemFunction) 
        local item = d.item
        local usingCharacter = d.user.Human
        local targetCharacter = d.target.Human
        local targetLimb = d.targetLimb

        local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)

        -- If not on the torso, tap out
        if limbtype ~= LimbType.Torso then return end
    
        local HuskHealth = NTCS.HF.GetAfflictionStrength(targetCharacter,"surgery_huskhealth")

        if HuskHealth > 0.1 and NTCS.HF.HasAffliction(targetCharacter,"bonecuttorso",99) then

            -- Doesn't work in stasis
            if (NTCS.HF.HasAffliction(targetCharacter,"stasis", 0.1)) then 
                return 
            end

            local CalyxanideStrength = NTCS.HF.GetAfflictionStrength(targetCharacter,"af_calyxanide")

            if CalyxanideStrength < 0.1 and HuskHealth > 20 then
                -- trying to defib a very aggressive parasite

                if NTCS.HF.Chance(0.3) then
                    -- we're doing the funny double traumatic amputation now
                    if not NTCS.HF.LimbIsAmputated(usingCharacter, LimbType.RightArm) then
                        NTCS.HF.TraumamputateLimb(usingCharacter, LimbType.RightArm) 
                    end

                    if not NTCS.HF.LimbIsAmputated(usingCharacter, LimbType.LeftArm) then
                        NTCS.HF.TraumamputateLimb(usingCharacter, LimbType.LeftArm) 
                    end
                    
                    NTCS.HF.GiveItem(targetCharacter,"ntsfx_huskhurt") 
                else
                    -- determine what limb is being retaliated against
                    local hitLimb = LimbType.RightArm
                    if NTCS.HF.Chance(0.5) then 
                        hitLimb = LimbType.LeftArm 
                    end

                    if NTCS.HF.LimbIsAmputated(usingCharacter, LimbType.RightArm) then 
                        hitLimb = LimbType.LeftArm 
                    end

                    if NTCS.HF.LimbIsAmputated(usingCharacter, LimbType.LeftArm) then 
                        hitLimb = LimbType.RightArm 
                    end

                    NTCS.HF.AddAfflictionLimb(usingCharacter,"bleeding",hitLimb,5)
                    NTCS.HF.AddAfflictionLimb(usingCharacter,"bitewounds",hitLimb,10)
                    NTCS.HF.AddAffliction(usingCharacter,"stun",0.2)

                    -- 20% chance of getting the unfortunate soul holding the defib infected
                    if NTCS.HF.Chance(0.2) then
                        NTCS.HF.AddAffliction(usingCharacter, "huskinfection", 1)
                    end
                end

                NTCS.HF.GiveItem(targetCharacter,"ntsfx_huskhurt")
                
            else
                -- defibbing a stunned parasite
                local containedItem = item.OwnInventory.GetItemAt(0)
                if containedItem==nil then return end
                local hasVoltage = containedItem.Condition > 0

                if hasVoltage then 
                    NTCS.HF.GiveItem(targetCharacter,"ntsfx_manualdefib")
                    containedItem.Condition = containedItem.Condition - 10

                    if containedItem.Prefab.Identifier.Value ~= "fulguriumbatterycell" then 
                        containedItem.Condition = containedItem.Condition - 10 
                    end

                    local successChance = (NTCS.HF.GetSkillLevel(usingCharacter,"medical")/100)^2

                    Timer.Wait(function()
                        NTCS.HF.AddAffliction(targetCharacter,"stun",0.5,usingCharacter)

                        HuskHealth = NTCS.HF.GetAfflictionStrength(targetCharacter,"surgery_huskhealth")

                        -- make sure surgery wasnt terminated in the 2 seconds it takes for the defib to do its job
                        if HuskHealth < 0.1 then return end

                        if NTCS.HF.Chance(successChance) then
                            HuskHealth = HuskHealth - 30
                        else
                            HuskHealth = HuskHealth - 10
                        end

                        HuskHealth = NTCS.HF.Clamp(HuskHealth,5,100)
                        NTCS.HF.SetAffliction(targetCharacter, "surgery_huskhealth", HuskHealth)
                        NTCS.HF.GiveItem(targetCharacter, "ntsfx_huskdeath")
                        
                    end, 2000)
                end

            end

        else
            itemLoader:CallOld(OriginalItemFunction, "Neurotrauma C#", d)
        end
    end

    local DefibParasite = function (d)
        NTCS_Symbiote.SawRibs(d, "defibrillator")
    end

    itemLoader:Override("defibrillator", DefibParasite)
end,2000)