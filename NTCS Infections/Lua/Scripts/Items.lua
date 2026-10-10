local itemLoader = NTCS.ItemFunctionLoader("NTCS_Cybernetics")

Timer.Wait(function()
    -- Additional Hematology Identifiers
    NTCS_Infections.MoreHematologyDetectable = {
        "afampicillin",
        "afaugmentin",
        "afvancomycin",
        "afgentamicin",
        "afcotrim",
        "afimipenem",
        "afdextromethorphan",
        "afremdesivir",
        "afzincsupplement",
        "afceftazidime",
        "afcorticosteroids",
        "bloodinfectionlevel",
        "afascorbicacid",
    }

    -- Add the new hematology identifiers into the HematologyDetectable list
    for i = 1, #NTCS_Infections.MoreHematologyDetectable do
        NTCS.NTC.AddHematologyAffliction(NTCS_Infections.MoreHematologyDetectable[i])
    end

    -- Sampler Tool Item
    NTCS_Infections.CultureAnalyzer = function (d)
        local item = d.item
        local usingCharacter = d.user.Human
        local targetCharacter = d.target.Human
        local targetLimb = d.targetLimb
        
        local containedItem = item.OwnInventory.GetItemAt(0)

        if containedItem ~= nil then
            local function postSpawnFunc(args)
                args.item.Condition = args.condition
            end

            if containedItem.HasTag("viraltest") then
                local params = {condition=100}
                local name = NTCS_Infections.GetCurrentVirus(targetCharacter)

                if name ~= nil then
                    local info = NTCS_Infections.Viruses[name]
                    
                else
                    NTCS.HF.GiveItemPlusFunction("emptyviralunk", usingCharacter, postSpawnFunc, params)
                end

                NTCS.HF.DMClient(NTCS.HF.CharacterToClient(usingCharacter),"Sampler tool\n\nSwab sample found.", Color(127,255,127,255))
            else
                local params = {condition=100}
                local name = nil
                local pus = NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, targetLimb.type, "pusyellow", 0) + NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, targetLimb.type, "pusgreen", 0)

                if pus > 0 then
                    name = NTCS_Infections.GetCurrentBacteria(targetCharacter, targetLimb.type)
                    NTCS.HF.DMClient(NTCS.HF.CharacterToClient(usingCharacter),"Sampler tool\n\nPus sample found.",Color(127,255,127,255))
                elseif NTCS.HF.HasAfflictionLimb(targetCharacter, "abscess", targetLimb.type, 0) then
                    name = NTCS_Infections.GetCurrentBacteria(targetCharacter, targetLimb.type)
                    NTCS.HF.AddAfflictionLimb(targetCharacter,"lacerations",targetLimb.type,4,usingCharacter)
                    NTCS.HF.DMClient(NTCS.HF.CharacterToClient(usingCharacter),"Sampler tool\n\nPus sample found.",Color(127,255,127,255))
                elseif NTCS.HF.HasAfflictionLimb(targetCharacter, "retractedskin", targetLimb.type, 0) then
                    name = NTCS_Infections.GetCurrentBacteria(targetCharacter, targetLimb.type)
                    NTCS.HF.AddAfflictionLimb(targetCharacter,"lacerations",targetLimb.type,8,usingCharacter)
                    NTCS.HF.DMClient(NTCS.HF.CharacterToClient(usingCharacter),"Sampler tool\n\nTissue sample found.",Color(127,255,127,255))
                else
                    name = NTCS_Infections.GetCurrentBacteriaBloodRandom(targetCharacter)
                    NTCS.HF.DMClient(NTCS.HF.CharacterToClient(usingCharacter),"Sampler tool\n\nBlood sample found.",Color(127,255,127,255))
                end

                if name ~= nil then
                    local info = NTCS_Infections.Bacterias[name]
                    NTCS.HF.GiveItemPlusFunction(info.samplename, usingCharacter, postSpawnFunc, params)
                else
                    NTCS.HF.GiveItemPlusFunction("emptytubeunk", usingCharacter, postSpawnFunc, params)
                end
            end

            NTCS.HF.RemoveItem(containedItem)
        else
            local string = "Sampler tool\nBloodwork readout:\n"
            local total = 0
            local infections = {}

            for key, info in pairs(NTCS_Infections.Bacterias) do
                local strength = NTCS.HF.GetAfflictionStrength(targetCharacter, info.bloodname, 0)

                if strength > 0 then
                    infections[key] = strength
                    total = total + strength
                end
            end

            if total <= 0 then
                string = string .. "\nNo bacterial presence in blood."
            else
                local bacteremia = targetCharacter.CharacterHealth.GetAffliction("bloodinfectionlevel")
                local bil = NTCS.HF.GetAfflictionStrength(targetCharacter, "bloodinfectionlevel", 0)
                if bacteremia ~= nil then string = string .. bacteremia.Prefab.Name.Value .. ": " .. NTCS.HF.Round(bil) .. "%" .. "\n" end
                for key, value in pairs(infections) do
                    local affliction = targetCharacter.CharacterHealth.GetAffliction(NTCS_Infections.Bacterias[key].bloodname)
                    string = string .. "\n" .. affliction.Prefab.Name.Value .. ": " .. NTCS.HF.Round((value / total) * 100) .. "%"
                end
            end

            --this is a stopgap solution to diagnosing pneumonia. will probably change in the future
            if NTCS.HF.GetAfflictionStrength(targetCharacter, "pneumonia", 0) > 0 then
                string = string .. "\n\nLung Biopsy Positive For:"

                local index = NTCS.HF.Round(NTCS.HF.GetAfflictionStrength(targetCharacter, "pneumoniabacteria", 0))
                if index > 0 then
                    info = NTCS_Infections.BacteriasIndex[index]
                    local affliction = targetCharacter.CharacterHealth.GetAffliction(info.bloodname)
                    string = string .. " " .. affliction.Prefab.Name.Value
                end

                index = NTCS.HF.Round(NTCS.HF.GetAfflictionStrength(targetCharacter, "pneumoniavirus", 0))
                if index > 0 then
                    info = NTCS_Infections.VirusesIndex[index]
                    local affliction = targetCharacter.CharacterHealth.GetAffliction(info.name)
                    string = string .. " " .. affliction.Prefab.Name.Value
                end
            end

            NTCS.HF.DMClient(NTCS.HF.CharacterToClient(usingCharacter),string,Color(127,255,127,255))
        end
    end
        
    itemLoader:Register("cultureanalyzer", NTCS_Infections.CultureAnalyzer)

    -- Override suture function and add it so that a necrotized targetLimb is not dropped during amputation
    NTCS_Infections.SutureOverride = function(d)
        local item = d.item
        local usingCharacter = d.user.Human
        local targetCharacter = d.target.Human
        local targetLimb = d.targetLimb
        
        if(NTCS.HF.GetSkillRequirementMet(usingCharacter,"medical",30)) then
            local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)

            if NTCS.HF.HasAfflictionLimb(targetCharacter,"bonecut",limbtype,1) then
                local previtem = NTCS.HF.GetItemInHeadWear(targetCharacter)
                if previtem ~= nil and limbtype == LimbType.Head then
                    previtem.Drop(usingCharacter, true)
                end
                local droplimb =
                    not NTCS.HF.LimbIsAmputated(targetCharacter,limbtype)
                    and not NTCS.HF.HasAfflictionLimb(targetCharacter,"gangrene",limbtype,15)
                    and not NTCS.HF.HasAfflictionLimb(targetCharacter,"infectionlevel",limbtype,20)
                    and not NTCS.HF.HasAfflictionLimb(targetCharacter,"necfasc",limbtype,1)
                NTCS.HF.SurgicallyAmputateLimb(targetCharacter,limbtype)
                if (droplimb) then
                    local limbtoitem = {}
                    limbtoitem[LimbType.RightLeg] = "rleg"
                    limbtoitem[LimbType.LeftLeg] = "lleg"
                    limbtoitem[LimbType.RightArm] = "rarm"
                    limbtoitem[LimbType.LeftArm] = "larm"
                    limbtoitem[LimbType.Head] = "headsa"
                    if limbtoitem[limbtype] ~= nil then
                        NTCS.HF.GiveItem(usingCharacter, limbtoitem[limbtype])
                        NTCS.HF.GiveSurgerySkill(usingCharacter, 0.5)
                    end
                end
            end
        end

        itemLoader:CallOld("suture", "Neurotrauma C#", d)
    end

    itemLoader:Override("suture", NTCS_Infections.SutureOverride)

    --override scalpel function and add it so that it can debride necrotic tissue
    NTCS_Infections.ScalpelOverride = function(d)
        local item = d.item
        local usingCharacter = d.user.Human
        local targetCharacter = d.target.Human
        local targetLimb = d.targetLimb

        itemLoader:CallOld("advscalpel", "Neurotrauma C#", d)

        local limbtype = NTCS.HF.NormalizeLimbType(targetLimb.type)

        if(NTCS.HF.HasAffliction(targetCharacter,"stasis",0.1)) then return end

        if not NTCS.HF.HasAfflictionLimb(targetCharacter, "necfasc", limbtype, 0) or not NTCS.HF.HasAfflictionLimb(targetCharacter,"retractedskin",limbtype,0.1) then
            return
        else
            local function healAfflictionGiveSkill(identifier,healamount,skillgain) 
                local affAmount = NTCS.HF.GetAfflictionStrengthLimb(targetCharacter,limbtype,identifier)
                local healedamount = math.min(affAmount,healamount)
                NTCS.HF.AddAfflictionLimb(targetCharacter,identifier,limbtype,-healamount,usingCharacter)
                
                if NTCS_SurgeryPlus ~= nil and NTCS.Config.Get("NTSP_enableSurgerySkill",true) then 
                    NTCS.HF.GiveSkillScaled(usingCharacter,"surgery",healedamount*skillgain)
                else 
                    NTCS.HF.GiveSkillScaled(usingCharacter,"medical",healedamount*skillgain/2)
                end
            end

            if NTCS.HF.GetSkillRequirementMet(usingCharacter,"medical",50) then
                healAfflictionGiveSkill("necfasc", 5, 20)
                NTCS.HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,8,usingCharacter)
            else
                healAfflictionGiveSkill("necfasc", 5, 20)
                NTCS.HF.AddAfflictionLimb(targetCharacter,"bleeding",limbtype,5,usingCharacter)
                NTCS.HF.AddAfflictionLimb(targetCharacter,"lacerations",limbtype,10,usingCharacter)
            end
            
            NTCS.HF.GiveItem(targetCharacter,"ntsfx_slash")
        end
    end

    itemLoader:Override("advscalpel", NTCS_Infections.ScalpelOverride)
end,1)