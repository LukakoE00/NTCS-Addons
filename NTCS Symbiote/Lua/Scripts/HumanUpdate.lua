local AfflictionLoader = NTCS.AfflictionsLoader("NTCS Symbiote")
local AfflictionBuilder = NTCS.AfflictionPrefabBuilder()

local limbTypes = {
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
    LimbType.Torso,
    LimbType.Head
}

Timer.Wait(function()

    -- Make Calyxanide visible on the Blood Analyzer
    NTCS.NTC.AddHematologyAffliction("af_calyxanide")

    -- Calyxanide
    local CalyxanideAff = AfflictionBuilder:New("af_calyxanide"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

        -- If in stasis, end early
        if C:GetBoolStat("stasis") then return end

        local CurrentStrength = C:GetAfflictionStrength(Identifier)
        local StrengthIncrease = NTCS.HF.Clamp(CurrentStrength - 0.5 * DeltaT, 0, 100)
        local HuskHealth = C:GetAfflictionStrength("surgery_huskhealth")

        C:SetAffliction(Identifier, StrengthIncrease);

        if CurrentStrength > 0 then
            if HuskHealth > 80 then
                -- Reduce Husk Health
                C:SetAffliction("surgery_huskhealth", HuskHealth - 1 * DeltaT)
            end

            -- Reduce Husk Infection
            local PreviousHuskInfection = C:GetAfflictionStrength("huskinfection")
            local NewHuskInfection = PreviousHuskInfection - (1 * DeltaT)

            -- 0-10%    : fully treat
            -- 10-25%   : prevent increase
            -- 25%-99%  : lower to 25%
            -- >99%     : :skull:
            if (PreviousHuskInfection > 25 or PreviousHuskInfection < 10) and PreviousHuskInfection < 99 then
                C:SetAffliction("huskinfection", NewHuskInfection) 
            end
        end

    end):Build()

    AfflictionLoader:Register(CalyxanideAff)

    -- Husk Lantern 
    local HuskLampAff = AfflictionBuilder:New("husklamp"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

        local CurrentStrength = C:GetAfflictionStrength(Identifier)

        if CurrentStrength > 0.1 then
            -- Increase immunity
            local CurrentImmunity = C.GetAfflictionStrength("immunity");
            if not NTCS.HF.HasAffliction(C.Human,"afimmunosuppressant") then
                C:SetAffliction("immunity", CurrentImmunity + (5 * DeltaT))
            end

            -- Heal lungs
            local CurrentLungDamage = C:GetAfflictionStrength("lungdamage")
            if CurrentLungDamage < 99 then
                C:SetAffliction("lungdamage", CurrentLungDamage - (0.04 * DeltaT))
            end

            -- Limb Specifics
            for limbType in limbTypes do
                -- Add Ointmented to character's limbs
                if NTCS.HF.GetAfflictionStrengthLimb(C.Human, limbType, "ointmented") < 10 then
                    NTCS.HF.AddAfflictionLimb(C.Human, "ointmented", limbType, (2 * DeltaT)) 
                end

                -- Reduce burns on character's limbs
                if NTCS.HF.GetAfflictionStrengthLimb(C.Human, limbType,"burn") < 50 then
                    NTCS.HF.AddAfflictionLimb(C.Human, "burn", limbType, (-0.2 * DeltaT)) 
                end
            end
        end

    end):Build()

    AfflictionLoader:Register(HuskLampAff)

    -- Husk Health in Surgery 
    local HuskHealth = AfflictionBuilder:New("surgery_huskhealth"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

        -- Stasis check
        if C:GetBoolStat("stasis") then 
            C:SetAffliction(Identifier, 0)
            return 
        end

        -- Husk Check
        if not NTCS_Symbiote.HF.HasHusk(C.Human) then 
            C:SetAffliction(Identifier, 0)
            return
        end

        -- Rib Sawed Check
        if not NTCS.HF.HasAffliction(C.Human,"bonecuttorso", 99) then
            C:SetAffliction(Identifier, 0)
            return
        end

        local CurrentStrength = C:GetAfflictionStrength(Identifier)

        -- Husk Parasite Health Regeneration
        if C:GetAfflictionStrength("af_calyxanide") <= 0.1 and CurrentStrength > 0.1 then
            local ParasiteHealthRegen = NTCS.HF.Clamp(CurrentStrength + (0.5 * DeltaT), 0, 100)
            C:SetAffliction(Identifier, ParasiteHealthRegen)
        end

    end):Build()

    AfflictionLoader:Register(HuskHealth)

    -- Sawed Ribs
    local BoneCutTorso = AfflictionBuilder:New("bonecuttorso"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

         -- Stasis check
        if C:GetBoolStat("stasis") then 
            C:SetAffliction(Identifier, 0)
            return 
        end

        -- Instantiate Husk Parasite Health
        if C:GetAfflictionStrength(Identifier) >= 99 and C:GetAfflictionStrength("surgery_huskhealth") <= 0.1 and NTCS_Symbiote.HF.HasHusk(C.Human) then
            NTCS.HF.GiveItem(C.Human, "ntsfx_huskhurt")
            C:SetAffliction("surgery_huskhealth", NTCS.HF.Clamp(100 - C:GetAfflictionStrength("af_calyxanide"), 80, 100))
        end

    end):Build()

    AfflictionLoader:Register(BoneCutTorso)

    -- Make Symbiosis treat Neurotrauma afflictions
    local HuskSymbiosis = AfflictionBuilder:New("husksymbiosis"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

        -- Stasis check
        if C:GetBoolStat("stasis") then 
            C:SetAffliction(Identifier, 0)
            return 
        end

        -- Symbiosis Check
        if C:GetAfflictionStrength(Identifier) < 1 then return end

        -- Treat Afflictions
        C:SetAffliction("sepsis", 0)
        C:SetAffliction("hemotransfusionshock", 0)
        C:SetAffliction("pneumothorax", 0)
        C:SetAffliction("internalbleeding", C:GetAfflictionStrength("internalbleeding") - 0.5 * DeltaT)
        C:SetAffliction("acidosis", C:GetAfflictionStrength("acidosis") - 0.2 * DeltaT)
        C:SetAffliction("alkalosis", C:GetAfflictionStrength("alkalosis") - 0.2 * DeltaT)
        C:SetAffliction("lungdamage", C:GetAfflictionStrength("lungdamage") - 0.05 * DeltaT)
        C:SetAffliction("oxygenlow", C:GetAfflictionStrength("oxygenlow") - 100 * DeltaT)
    
        C.SetSymptomFalse("hyperventilation", 2)
        C.SetSymptomFalse("hypoventilation", 2)

        C:SetAffliction("respiratoryarrest", 0)

        C.SetSymptomFalse("shortnessofbreath", 2)
            
        -- Limb Specifics
        for limbType in limbTypes do
            if NTCS.HF.GetAfflictionStrengthLimb(C.Human, limbType, "gangrene") < 15 then
                NTCS.HF.AddAfflictionLimb(C.Human, "gangrene", limbType, -0.1 * DeltaT) 
            end
        end

        -- Wait a tick with this because otherwise it'll be removed before being used
        Timer.Wait(function() 
            NTCS.NTC.SetMultiplier(C.Human,"hypoxemiagain", 0.1) 
        end,1)

        -- Symbiotic Stasis
        local shouldBeInStasis = 
            C:GetAfflictionStrength("cardiacarrest") > 0.1
            or C:GetAfflictionStrength("neurotrauma") > 102
            or C:GetAfflictionStrength("coma") > 20
            or C.Human.Vitality < 0
            or C.Human.bloodloss > 80

        if shouldBeInStasis then
            C:SetAffliction("huskstasis", 10)
        end

    end):Build()

    AfflictionLoader:Register(HuskSymbiosis)

    -- Husk Stasis
    local HuskStasis = AfflictionBuilder:New("huskstasis"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

        -- Stasis check
        if C:GetBoolStat("stasis") then 
            C:SetAffliction(Identifier, 0)
            return 
        end

        -- HuskStasis Check
        if C:GetAfflictionStrength(Identifier) < 1 then return end

        -- Treat Afflictions
        C:SetAffliction("internalbleeding", C:GetAfflictionStrength("internalbleeding") - 5 * DeltaT)
        C:SetAffliction("coma", C:GetAfflictionStrength("coma") - 10 * DeltaT)
        C:SetAffliction("tamponade", C:GetAfflictionStrength("tamponade") - 5 * DeltaT)
        C:SetAffliction("bonedamage", C:GetAfflictionStrength("bonedamage") - 5 * DeltaT)
        C:SetAffliction("traumaticshock", C:GetAfflictionStrength("traumaticshock") - 5 * DeltaT)
        NTCS.HF.SetAffliction(C.Human,"cpr_buff_auto", 2)
            
        -- Heal Organs
        local CurrentHeartDamage = C:GetAfflictionStrength("heartdamage")
        if CurrentHeartDamage < 99 then
            C:SetAffliction("heartdamage", CurrentHeartDamage - 0.5 * DeltaT)
        end

        local CurrentLungDamage = C:GetAfflictionStrength("lungdamage")
        if CurrentLungDamage < 99 then
            C:SetAffliction("lungdamage", CurrentLungDamage - 0.5 * DeltaT)
        end

        local CurrentLiverDamage = C:GetAfflictionStrength("liverdamage")
        if CurrentLiverDamage < 99 then
            C:SetAffliction("liverdamage", CurrentLiverDamage - 0.5 * DeltaT)
        end

        local CurrentKidneyDamage = C:GetAfflictionStrength("kidneydamage")
        
        if CurrentKidneyDamage < 50 then
            C:SetAffliction("kidneydamage", CurrentKidneyDamage - 0.5 * DeltaT)
        elseif CurrentKidneyDamage < 99 then
            C:SetAffliction("kidneydamage", NTCS.HF.Clamp(CurrentKidneyDamage - 0.5 * DeltaT, 51, 100))
        end

        -- Miscellaneous
        local CurrentAnalgesia = C:GetAfflictionStrength("analgesia")
        if CurrentAnalgesia < 40 then
            C:SetAffliction("analgesia", CurrentAnalgesia - 5 * DeltaT)
        end

        if C:GetAfflictionStrength("seizure") < 5 then
            C:SetAffliction("seizure", 10)
        end

        -- Limb Specifics
        for limbType in limbTypes do
            -- Arterial Bleeds
            NTCS.HF.ArteryCutLimb(C.Human, limbType, -10 * DeltaT)
            
            -- Fractures
            if NTCS.HF.Chance(0.05) then
                NTCS.HF.BreakLimb(C.Human, limbType, -1000)
            end

            -- Foreign Bodies
            NTCS.HF.AddAfflictionLimb(C.Human, "foreignbody", limbType, -1 * DeltaT)
        end

        local CurrentStrength = C:GetAfflictionStrength(Identifier)

        C:SetAffliction(Identifier, C:GetAfflictionStrength(Identifier) - 1 * DeltaT)

        C.SetSymptomTrue("unconsciousness", 2)

    end):Build()

    AfflictionLoader:Register(HuskStasis)
    
    function NTCS_Symbiote.CheckForZealotRobes(character, deltaTime)

        -- Check if wearing husk robes
        if NTCS.HF.GetInnerWearIdentifier(character) == "zealotrobes" and NTCS_Symbiote.HF.HasHusk(character) then
            -- Heal Afflictions
            NTCS.HF.SetAffliction(character, "sepsis", 0)
            NTCS.HF.SetAffliction(character, "hemotransfusionshock", 0)
            NTCS.HF.SetAffliction(character, "pneumothorax", 0)
            NTCS.HF.AddAffliction(character, "internalbleeding", -0.5 * deltaTime)
            NTCS.HF.AddAffliction(character, "acidosis", -0.2 * deltaTime)
            NTCS.HF.AddAffliction(character, "alkalosis", -0.2 * deltaTime)
            NTCS.HF.AddAffliction(character, "lungdamage", -0.05 * deltaTime)
            NTCS.HF.AddAffliction(character, "oxygenlow", -100 * deltaTime)

            local NTHuman = NTCS.Human.getNTHumanFromCharacter(character)
            NTHuman.SetSymptomFalse("hyperventilation")
            NTHuman.SetSymptomFalse("hypoventilation")
            
            -- Limb Specifics
            for limbType in limbTypes do
                if NTCS.HF.GetAfflictionStrengthLimb(character, limbType, "gangrene") < 15 then
                    NTCS.HF.AddAfflictionLimb(character, "gangrene", limbType, -0.1 * deltaTime) 
                end
            end
        end
    end
end,1)