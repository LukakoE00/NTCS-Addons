local AfflictionLoader = NTCS.AfflictionsLoader("NTCS Infections")
local AfflictionBuilder = NTCS.AfflictionPrefabBuilder()

local limbtypes = {
    LimbType.Torso,
    LimbType.Head,
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
}

-- Affliction overrides
-- InfectedCavity
local InfectedCavityOverride = AfflictionBuilder:New("infectedcavity"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    -- Run the original Neurotrauma C# update
    AfflictionLoader:CallOldUpdate("Neurotrauma C#", "infectedcavity", C, Identifier, Limb, DeltaT)

    -- Stasis check
    if C:GetBoolStat("stasis") then return end

    -- Chance for the cavity infection to spread to the blood
    local CurrentInfectedCavity = C:GetAfflictionStrength(Identifier)

    if CurrentInfectedCavity > 25 and NTCS.HF.Chance(((CurrentInfectedCavity - 25) / 100) ^ 10) then
        NTCS_Infections.InfectCharacterBloodRandom(C.Human)
    end

end):Build()

AfflictionLoader:Override(InfectedCavityOverride)

local BloodPressureOverride = AfflictionBuilder:New("bloodpressure"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    -- Fix people not having a blood pressure
    if not C:HasAffliction(Identifier) then C:SetAffliction(Identifier, 100) end

    -- Does not progress in stasis
    if C:GetBoolStat("stasis") then return end

    local str = C:GetAfflictionStrength(Identifier)

    local desiredbloodpressure = (
            C:GetFloatStat("bloodamount")
            - C:GetAfflictionStrength("tamponade") / 2                                          -- -50 if full tamponade
            - NTCS.HF.Clamp(C:GetAfflictionStrength("afpressuredrug") * 5, 0, 45)               -- -45 if blood pressure medication
            - NTCS.HF.Clamp(C:GetAfflictionStrength("anesthesia"), 0, 15)                       -- -15 if propofol
            - C:GetAfflictionStrength("sepsis")                                                 -- sepsis lowers blood pressure
            + NTCS.HF.Clamp(C:GetAfflictionStrength("afadrenaline") * 10, 0, 30)                -- +30 if adrenaline
            + NTCS.HF.Clamp(C:GetAfflictionStrength("afsaline") * 5, 0, 30)                     -- +30 if saline
            + NTCS.HF.Clamp(C:GetAfflictionStrength("afringerssolution") * 5, 0, 30)            -- +30 if ringers
        )
        * (1 + 0.5 * ((C:GetAfflictionStrength("liverdamage") / 100) ^ 2))                      -- elevated if full liver damage
        * (1 + 0.5 * ((C:GetAfflictionStrength("kidneydamage") / 100) ^ 2))                     -- elevated if full kidney damage
        * (1 + C:GetAfflictionStrength("alcoholwithdrawal") / 200)                              -- elevated if alcohol withdrawal
        * NTCS.HF.Clamp((100 - C:GetAfflictionStrength("traumaticshock") * 2) / 100, 0, 1)      -- none if half or more traumatic shock
        * ((100 - C:GetAfflictionStrength("fibrillation")) / 100)                               -- lowered if fibrillated
        * (1 - math.min(1, C:GetAfflictionStrength("cardiacarrest")))                           -- none if cardiac arrest
        * NTCS.NTC.GetMultiplier(C, "bloodpressure")

    local bloodpressurelerp = 0.2 * NTCS.NTC.GetMultiplier(C, "bloodpressurerate")

    -- Adjust three times slower to heightened blood pressure
    if desiredbloodpressure > str then
        bloodpressurelerp = bloodpressurelerp / 3
    end

    -- Move towards the desired amount
    C:SetAffliction(Identifier, NTCS.HF.Clamp(
        NTCS.HF.Round(NTCS.HF.Lerp(str, desiredbloodpressure, bloodpressurelerp), 2),
        5,
        200
    ))

    -- Effects
    local conscious = C:GetAfflictionStrength("unconsciousness") <= 0

    if str < 60 then
        if conscious then
            C:SetSymptomTrue("lightheadedness", 2)
            C:SetSymptomTrue("headache", 2)
        end

        if str < 55 then
            if conscious then
                C:SetSymptomTrue("blurredvision", 2)
            end

            if str < 50 then
                C:SetSymptomTrue("paleskin", 2)

                if str < 30 and conscious then
                    C:SetSymptomTrue("confusion", 2)
                end
            end
        end
    end

    -- Heart attack + stroke
    if str > 150 then
        local excess = (str - 150) / 50 * 0.02

        if C:GetAfflictionStrength("afstreptokinase") <= 0
            and C:GetAfflictionStrength("heartremoved") <= 0
            and NTCS.HF.Chance(NTConfig.Get("NT_heartattackChance", 1) * excess) then
            C:AddAffliction("heartattack", 50)
        end

        if NTCS.HF.Chance(NTCS.Config.Get("NT_strokeChance", 1)
            * (excess + NTCS.HF.Clamp(C:GetAfflictionStrength("afstreptokinase"), 0, 1) * 0.05)) then
            C:AddAffliction("stroke", 5)
        end
    end

end):Build()

AfflictionLoader:Override(BloodPressureOverride)

-- Override for sepsis to increase by NTCS_Infections infections and no longer affected by antibiotics directly
local SepsisOverride = AfflictionBuilder:New("sepsis"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    -- Does not progress in stasis
    if C:GetBoolStat("stasis") then return end

    local str = C:GetAfflictionStrength(Identifier)
    local conscious = C:GetAfflictionStrength("unconsciousness") <= 0

    if str > 0 then
        local increase = (NTCS.HF.GetAfflictionStrength(C.Human, "bloodinfectionlevel", 0) / 250)
                            + NTCS_Infections.GetLimbIncreaseSepsis(C.Human)
                            + (NTCS.HF.GetAfflictionStrength(C.Human, "pneumonia", 0) / 1000)
                            + (NTCS_Infections.GetTotalNecValue(C.Human) / 1000)

        increase = increase * (1 - NTCS.HF.BoolToNum(C:GetAfflictionStrength("immunity") <= 85, 0.5))

        if not (increase > 0.003) then
            increase = -DeltaT
        end

        C:AddAffliction(Identifier, increase)
    end

    -- Effects
    -- Abdominal pain
    if str > 20 and conscious and not C:GetBoolStat("sedated") then
        C:SetSymptomTrue("abdominalpain", 2)
    end

    -- Neurotrauma
    local neurotraumagain = str / 100 * 0.4 * DeltaT
        * NTCS.NTC.GetMultiplier(C, "neurotraumagain")
        * NTCS.Config.Get("NT_neurotraumaGain", 1)
        * (1 - NTCS.HF.Clamp(C:GetAfflictionStrength("afmannitol"), 0, 0.5))

    C:AddAffliction("neurotrauma", neurotraumagain)

    -- Bone damage
    C:AddAffliction("bonedamage", str / 500 * NTCS.NTC.GetMultiplier(C, "bonedamagegain") * DeltaT)

    -- Fever
    if str > 5 then
        C:SetSymptomTrue("fever", 2)

        -- Gangrene
        if NTCS.HF.Chance(0.04) then
            for _, limb in ipairs(limbtypes) do
                if NTCS.HF.LimbIsExtremity(limb) then
                    C:AddAfflictionLimb("gangrene", limb,
                        (0.5 + str / 150) * NTCS.Config.Get("NT_gangrenespeed", 1) * DeltaT)
                end
            end
        end

        -- Confusion
        if str > 40 and conscious then
            C:SetSymptomTrue("confusion", 2)
        end
    end

end):Build()

AfflictionLoader:Override(SepsisOverride)

-- Override to change how infections are received (no longer directly to sepsis)
local ForeignBodyOverride = AfflictionBuilder:New("foreignbody"):IsLimbSpecific(true):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
    
    local strength = C:GetAfflictionStrengthLimb(Identifier, Limb)

    if strength < 15 then
        C:SetAfflictionLimb(Identifier, Limb, (-0.05 * C:GetFloatStat("healingrate") * DeltaT))
    end

    -- check for arterial cut triggers and foreign body sepsis
    local foreignbodycutchance = ((math.min(strength, 20) / 100) ^ 6) * 0.5
    
    if C:GetAfflictionStrengthLimb("bleeding", Limb) > 80 or NTCS.HF.Chance(foreignbodycutchance) then
        NTCS.HF.ArteryCutLimb(C.Human, Limb)
    end

    -- infection chance
    local infchance = math.min(C:GetAfflictionStrengthLimb("gangrene", Limb), 15, 0) / 400 + math.min(C:GetAfflictionStrengthLimb("infectedwound", Limb), 20) / 1000 + foreignbodycutchance

    if (not NTCS_Infections.LimbIsInfected(C.Human, Limb) and NTCS.HF.Chance(infchance)) then
        NTCS_Infections.InfectCharacterRandom(C.Human, Limb)
    end

end):Build()

AfflictionLoader:Override(ForeignBodyOverride)

-- Override to how inflammation accumulates
local InflammationOverride = AfflictionBuilder:New("inflammation"):IsLimbSpecific(true):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    local InflammationChange = NTCS.HF.Round(NTCS.HF.BoolToNum(NTCS_Infections.LimbIsInfected(C.Human, Limb), 0.75) + (1.25 * (C:GetAfflictionStrengthLimb(C.Human, Limb, "infectionlevel", 0) / 100)), 1) + 0.01
    
    C:SetAfflictionLimb(Identifier, Limb, InflammationChange)

    if C:GetAfflictionStrengthLimb("foreignbody", Limb) > 15 then
            C:SetAfflictionLimb(Identifier, Limb, 2)
    end

end):Build()

AfflictionLoader:Override(InflammationOverride)

-- Infections afflictions
-- Dextromethorphan
local Dextromethorphan = AfflictionBuilder:New("afdextromethorphan"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
    local strength = C:GetAfflictionStrength(Identifier)

    if strength > 0 then C:SetSymptomFalse("cough") end
    if strength > 80 then C:SetSymptomTrue("nausea", 2) end
    if strength > 90 then C:AddAffliction("psychosis", 1) end

end):Build()

AfflictionLoader:Register(Dextromethorphan)

-- Zinc supplement
local ZincSupplement = AfflictionBuilder:New("afzincsupplement"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
    local strength = C:GetAfflictionStrength(Identifier)

    if strength > 80 then C:SetSymptomTrue("nausea", 2) end
    if strength > 90 then C:SetSymptomTrue("vomiting", 2) end

end):Build()

AfflictionLoader:Register(ZincSupplement)

-- Immunocompromised affliction
-- Constant until better rewrite
local ImmunoCompromised = AfflictionBuilder:New("immunodeficiency"):IsConst(true):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
    local strength = C:GetAfflictionStrength(Identifier)

    if C:GetAfflictionStrength(Identifier) > 50 then 
        C:SetAffliction(Identifier, 100) 
    else 
        C:SetAffliction(Identifier, 0) 
    end

end):Build()

AfflictionLoader:Register(ImmunoCompromised)

-- Remdesivir
local Remdesivir = AfflictionBuilder:New("afremdesivir"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
    local strength = C:GetAfflictionStrength(Identifier)

    if strength > 70 then C:SetSymptomTrue("nausea", 2) end
    if strength > 75 then C:SetSymptomTrue("jaundice", 2) end

    if strength > 80 and C:GetAfflictionStrength("unconsciousness") <= 0 and not C:GetBoolStat("sedated") then 
        C:SetSymptomTrue("headache", 2) 
    end

end):Build()

AfflictionLoader:Register(Remdesivir)

-- Europan Cough
local EuropanCough = AfflictionBuilder:New("europancough"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
    local strength = C:GetAfflictionStrength(Identifier)

    local level = C:GetAfflictionStrength("virallevel")

        if (level <= 0) then
            C:SetAffliction(Identifier, 0)
            return
        end

        if strength <= 0 then return end

        NTCS_Infections.CheckSymptom(C.Human, "fever", level, 30, 0.1)
        NTCS_Infections.CheckSymptom(C.Human, "weakness", level, 50, 0.01)
        NTCS_Infections.CheckSymptom(C.Human, "shortnessofbreath", level, 60, 0.01)
        NTCS_Infections.CheckSymptom(C.Human, "nausea", level, 70, 0.02)
        NTCS_Infections.CheckSymptom(C.Human, "respiratoryarrest", strength, 90, 0.1)

        if C:GetAfflictionStrength("respiratoryarrest") <= 0 then
            NTCS_Infections.CheckSymptom(C.Human, "cough", level, 10, 0.2)
            NTCS_Infections.CheckSymptom(C.Human, "wheezing", level, 70, 0.01)
        end

        if C:GetAfflictionStrength("unconsciousness") <= 0 and not C:GetBoolStat("sedated") then
            NTCS_Infections.CheckSymptom(C.Human, "headache", level, 75, 0.02)
            NTCS_Infections.CheckSymptom(C.Human, "chestpain", level, 90, 0.02)
        end

end):Build()

AfflictionLoader:Register(EuropanCough)

-- Influenza 
local Influenza = AfflictionBuilder:New("influenza"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
    local strength = C:GetAfflictionStrength(Identifier)

    local level = C:GetAfflictionStrength("virallevel")

        if (level <= 0) then
            C:SetAffliction(Identifier, 0)
            return
        end

        if strength <= 0 then return end

        NTCS_Infections.CheckSymptom(C.Human, "cough", level, 15, 0.2)
        NTCS_Infections.CheckSymptom(C.Human, "fever", level, 30, 0.1)
        NTCS_Infections.CheckSymptom(C.Human, "sym_nausea", level, 50, 0.02)

        if C:GetAfflictionStrength("unconsciousness") <= 0 and not C:GetBoolStat("sedated") then
            NTCS_Infections.CheckSymptom(C.Human, "headache", level, 80, 0.02)
        end

end):Build()

AfflictionLoader:Register(Influenza)

-- Common Cold 
local CommonCold = AfflictionBuilder:New("commoncold"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
    local strength = C:GetAfflictionStrength(Identifier)

    local level = C:GetAfflictionStrength("virallevel")

        if (level <= 0) then
            C:SetAffliction(Identifier, 0)
            return
        end

        if strength <= 0 then return end

        NTCS_Infections.CheckSymptom(C.Human, "cough", level, 10, 0.2)

        if C:GetAfflictionStrength("unconsciousness") <= 0 and not C:GetBoolStat("sedated") then
            NTCS_Infections.CheckSymptom(C.Human, "headache", level, 60, 0.05)
        end

        NTCS_Infections.CheckSymptom(C.Human, "fever", level, 80, 0.02)

end):Build()

AfflictionLoader:Register(CommonCold)

-- Infection functionality
-- Immune response to a limb infection
local ImmuneResponse = AfflictionBuilder:New("immuneresponse"):IsConst(true):IsLimbSpecific(true):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    -- Stasis check
    if C:GetBoolStat("stasis") then return end

    if NTCS_Infections.LimbIsInfected(C.Human, Limb) then
            C:AddAfflictionLimb(Identifier, Limb, ((C:GetAfflictionStrength("immunity") - 50) / 100))
        else
            C:AddAfflictionLimb(Identifier, Limb, -1)
        end

end):Build()

AfflictionLoader:Register(ImmuneResponse)

-- Immune response for the whole body (in response to blood infection)
local SystemicResponse = AfflictionBuilder:New("systemicresponse"):IsConst(true):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    -- Stasis check
    if C:GetBoolStat("stasis") then return end

    if NTCS_Infections.BloodIsInfected(C.Human) or C:GetAfflictionStrength("pneumoniabacteria") > 0 then
        C:AddAffliction(Identifier, ((C:GetAfflictionStrength("immunity") - 50) / 100))
    else
        C:AddAffliction(Identifier, -1)
    end

end):Build()

AfflictionLoader:Register(SystemicResponse)

-- Immune response for viral infections
local ViralAntibodies = AfflictionBuilder:New("viralantibodies"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    -- Stasis check
    if C:GetBoolStat("stasis") then return end

    if C:HasAffliction("virallevel") or C:GetAfflictionStrength("pneumoniavirus") > 0 then
        C:AddAffliction(Identifier, ((C:GetAfflictionStrength("immunity") - 50) / 100))
    else
        C:AddAffliction(Identifier, -0.1)
    end

end):Build()

AfflictionLoader:Register(ViralAntibodies)

-- Current progress of a viral infection
local ViralLevel = AfflictionBuilder:New("virallevel"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    -- Stasis check
    if C:GetBoolStat("stasis") then return end

    if C:GetAfflictionStrength(Identifier) > 0 then
        local name = NTCS_Infections.GetCurrentVirus(C.Human)

        if name == nil then
            C:SetAffliction(Identifier, 0)
            return
        end

        local virus = NTCS_Infections.Viruses[name]
        local meds = NTCS_Infections.GetTotalMedValue(C.Human, virus.medicine)
        local gain = math.min(virus.basespeed + NTCS.HF.GetAfflictionStrength(C.Human, name, 0) * virus.severityspeed, 0.99) 
                    * NTCS_Infections.GetAntibioticValue(C.Human, virus.antibiotics)
                    * (1 - (NTCS.HF.GetAfflictionStrength(C.Human, virus.vaccine, 0) / 200) * (C:GetAfflictionStrength("immunity") / 100))
        local defense = (gain + 0.1) * (NTCS.HF.GetAfflictionStrength(C.Human, "viralantibodies", 0) / 100)

        C:AddAffliction(Identifier, (gain * NTCS.HF.BoolToNum(NTCS.Config.Get("NTI_infectionDifficulty", true))) - defense)

        C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * (1 - virus.slowdown * (C:GetAfflictionStrength(Identifier) / (100 + meds))))

        NTCS_Infections.SpreadViralInfection(C.Human, NTCS.HF.BoolToNum(NTCS.Config.Get("NTI_viralSpreadChance", true)), virus, meds, C:GetAfflictionStrength(Identifier), name, NTCS.HF.GetAfflictionStrength(C.Human, name, 0))
end

end):Build()

AfflictionLoader:Register(ViralLevel)

-- Current progress of an infection
local InfectionLevel = AfflictionBuilder:New("infectionlevel"):IsLimbSpecific(true):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    -- Stasis check
    if C:GetBoolStat("stasis") then return end

    local strength = C:GetAfflictionStrengthLimb(Identifier, Limb)
    if strength <= 0 then return end

    if NTCS_Infections.LimbAmputatedOrCybernetic(C.Human, Limb) then
        C:SetAfflictionLimb(Identifier, Limb, 0)
        return
    end

    local name = NTCS_Infections.GetCurrentBacteria(C.Human, Limb)
    if name == nil then
        C:SetAfflictionLimb(Identifier, Limb, 0)
        return
    end

    local info = NTCS_Infections.Bacterias[name]
    local severity = NTCS.HF.GetAfflictionStrengthLimb(C.Human, Limb, name, 1)
    local antibiotic = NTCS_Infections.GetAntibioticValue(C.Human, info.antibiotics)

    local gain = math.min(info.basespeed + severity * info.severityspeed, 0.99)
                * antibiotic
                * (1 - (NTCS.HF.GetAfflictionStrength(C.Human, info.vaccine, 0) / 200) * (C:GetAfflictionStrength("immunity") / 100))

    local defense = C:GetAfflictionStrengthLimb("immuneresponse", Limb) / 100

    local delta = (gain * NTCS.HF.BoolToNum(NTCS.Config.Get("NTI_infectionDifficulty", true))) - defense
    local newstrength = NTCS.HF.Clamp(strength + delta, 0, 100)

    C:SetAfflictionLimb(Identifier, Limb, newstrength)

    -- Spread to the blood
    if strength > 50 and not (NTCS.HF.GetAfflictionStrength(C.Human, info.bloodname, 0) > 0) then
        if NTCS.HF.Chance(((strength - 50) / 150) ^ 2) then
            NTCS_Infections.InfectCharacterBlood(C.Human, info.bloodname, severity)
        end
    end

    -- Sepsis from this limb
    if strength > 75 and not NTCS_Infections.HasSepsis(C.Human) then
        if NTCS.HF.Chance(((strength - 75) / 150) ^ 2) then
            C:SetAffliction("sepsis", 1)
        end
    end

end):Build()

AfflictionLoader:Register(InfectionLevel)

local BloodInfectionLevel = AfflictionBuilder:New("bloodinfectionlevel"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    -- Stasis check
    if C:GetBoolStat("stasis") then return end

    if C:GetAfflictionStrength(Identifier) > 0 then
            if NTCS_Infections.BloodSeverityTotal(C.Human) <= 0 then C:SetAffliction(Identifier, 0) return end

            local gain = NTCS_Infections.BloodInfUpdate(C)
            local defense = (C:GetAfflictionStrength("systemicresponse", 0) / 100)

            C:AddAffliction(Identifier, (gain * NTCS.HF.BoolToNum(NTCS.Config.Get("NTI_infectionDifficulty", true))) - defense)

            if NTCS.HF.Chance((C:GetAfflictionStrength(Identifier) / 150) ^ 3) and not NTCS_Infections.HasSepsis(C.Human) then 
                C:SetAffliction("sepsis", 1)
            end
        end

end):Build()

AfflictionLoader:Register(BloodInfectionLevel)

-- Bacterial infections
-- I'm not fucking around
local function RegisterLimbBacteria(id)
    local aff = AfflictionBuilder:New(id):IsLimbSpecific(true):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
        if C:GetAfflictionStrengthLimb(Identifier, Limb) <= 0 then return end

        if not NTCS_Infections.LimbIsInfected(C.Human, Limb) then
            C:SetAfflictionLimb(Identifier, Limb, 0)
        end
    end):Build()

    AfflictionLoader:Register(aff)
end

local function RegisterBloodBacteria(id)
    local aff = AfflictionBuilder:New(id):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
        if C:GetAfflictionStrength(Identifier) <= 0 then return end

        if not NTCS_Infections.BloodIsInfected(C.Human) then
            C:SetAffliction(Identifier, 0)
        end
    end):Build()

    AfflictionLoader:Register(aff)
end

for _, name in ipairs({ "strep", "staph", "pseudo", "provo", "aero", "mrsa" }) do
    RegisterLimbBacteria("limb" .. name)
    RegisterBloodBacteria("blood" .. name)
end

-- Symptoms
local abscesscauses = {"limbstrep", "limbstaph", "limbpseudo", "limbprovo", "limbaero", "limbmrsa"}

local Abscess = AfflictionBuilder:New("abscess"):IsLimbSpecific(true):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
    local inflev = NTCS_Infections.LimbInfectionLevelList(C.Human, Limb, abscesscauses)
    local hasWound = NTCS_Infections.HasWound(C.Human, Limb)

    -- An abscess that has a wound to drain through turns into pus
    if C:GetAfflictionStrengthLimb(Identifier, Limb) > 0 and hasWound then
        local color = NTCS_Infections.GetPusColor(C.Human, Limb)
        if color ~= nil then
            C:SetAfflictionLimb(color, Limb, 2)
            C:SetAfflictionLimb(Identifier, Limb, 0)
            return
        end
    end

    if inflev > 25 and not hasWound then
        if C:GetAfflictionStrengthLimb(Identifier, Limb) <= 0 then
            C:SetAfflictionLimb(Identifier, Limb, NTCS.HF.BoolToNum(NTCS.HF.Chance((inflev / 400) ^ 2), 2))
        end
    else
        C:SetAfflictionLimb(Identifier, Limb, 0)
    end
end):Build()

AfflictionLoader:Register(Abscess)

-- Pus (Green / Yellow)
local function RegisterPus(id, causes)
    local pus = AfflictionBuilder:New(id):IsLimbSpecific(true):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
        local inflev = NTCS_Infections.LimbInfectionLevelList(C.Human, Limb, causes)

        if inflev > 25 and NTCS_Infections.HasWound(C.Human, Limb) then
            if C:GetAfflictionStrengthLimb(Identifier, Limb) <= 0 then
                C:SetAfflictionLimb(Identifier, Limb, NTCS.HF.BoolToNum(NTCS.HF.Chance((inflev / 400) ^ 2), 2))
            end
        else
            C:SetAfflictionLimb(Identifier, Limb, 0)
        end
    end):Build()

    AfflictionLoader:Register(pus)
end

RegisterPus("pusyellow", NTCS_Infections.pus_yellow_causes)
RegisterPus("pusgreen", NTCS_Infections.pus_green_causes)

-- Diseases
local NecFasc = AfflictionBuilder:New("necfasc"):IsLimbSpecific(true):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    -- ADD INTENSEPAIN
    if not NTCS_Infections.NotHead(Limb, false) or NTCS_Infections.LimbAmputatedOrCybernetic(C.Human, Limb) then
        C:SetAfflictionLimb(Identifier, Limb, 0)
        return
    end

    -- Stasis check
    if C:GetBoolStat("stasis") then return end

    local strength = C:GetAfflictionStrengthLimb(Identifier, Limb)

    if strength <= 0 then
        local inflev =C:GetAfflictionStrengthLimb("infectionlevel", Limb)
        if NTCS.HF.Chance((inflev / 1500) * ((100 - C:GetAfflictionStrength("immunity")) / 1500)) then
            C:SetAfflictionLimb(Identifier, Limb, 1)
        end
    else
        local name = NTCS_Infections.GetCurrentBacteria(C.Human, Limb)
        local increase = 0.05

        if name ~= nil then
            local info = NTCS_Infections.Bacterias[name]
            local antibiotic = NTCS_Infections.GetAntibioticValue(C.Human, info.antibiotics)

            increase = NTCS.HF.Clamp(info.basespeed + C:GetAfflictionStrengthLimb(name, Limb, 1) * info.severityspeed, 0.05, 1)
                * NTCS.HF.BoolToNum(NTCS.Config.Get("NTI_necFascSpeed", true))
                * (1 - (NTCS.HF.GetAfflictionStrength(C.Human, info.vaccine, 0) / 200) * (C:GetAfflictionStrength("immunity") / 100))
                * antibiotic
        end

        C:AddAffliction(Identifier, increase)

        if not NTCS_Infections.HasSepsis(C.Human) then
            if NTCS.HF.Chance(((strength + increase) / 400) ^ 2) then
                C:SetAffliction("sepsis", 1)
            end
        end
    end
end):Build()

AfflictionLoader:Register(NecFasc)

-- Pneumonia
local pneumoniacauses = {
    limbstrep = true,
    limbstaph = true,
    limbpseudo = true,
    limbprovo = true,
    limbaero = true,
    limbmrsa = true,
    europancough = true,
    influenza = true,
}

local Pneumonia = AfflictionBuilder:New("pneumonia"):SetUpdateAction(function(C, Identifier, Limb, DeltaT)

    if C:HasAffliction("ntc_cyberlung") then
        C:SetAffliction(Identifier, 0)
        return
    end

    -- Stasis check
    if C:GetBoolStat("stasis") then return end

    local strength = C:GetAfflictionStrength(Identifier)
    local immunity = C:GetAfflictionStrength("immunity")

    if strength <= 0 then
        local bil = C:GetAfflictionStrength("bloodinfectionlevel")
        local vil = C:GetAfflictionStrength("virallevel")

        if bil > 0 and NTCS.HF.Chance(1 / (300 + immunity - bil)) then
            local name = NTCS_Infections.GetCurrentBacteriaBloodRandom(C.Human)

            if name ~= nil and pneumoniacauses[name] then
                local info = NTCS_Infections.Bacterias[name]
                C:SetAffliction(Identifier, 1)
                C:SetAffliction("pneumoniabacteria", info.id)
            end
        end

        if vil > 0 and NTCS.HF.Chance((vil / (500 + immunity)) ^ 3) then
            local name = NTCS_Infections.GetCurrentVirus(C.Human)

            if name ~= nil and pneumoniacauses[name] then
                local info = NTCS_Infections.Viruses[name]
                C:SetAffliction(Identifier, 1)
                C:SetAffliction("pneumoniavirus", info.id)
            end
        end
    else
        -- Symptoms
        NTCS_Infections.CheckSymptom(C.Human, "cough", strength, 5, 0.2)
        NTCS_Infections.CheckSymptom(C.Human, "shortnessofbreath", strength, 10, 0.1)

        if C:GetAfflictionStrength("unconsciousness") <= 0 and not C:GetBoolStat("sedated") then
            NTCS_Infections.CheckSymptom(C.Human, "chestpain", strength, 40, 0.1)
        end

        NTCS_Infections.CheckSymptom(C.Human, "respiratoryarrest", strength, 80, 0.1)

        local info = nil
        local defense = 0

        local index = NTCS.HF.Round(C:GetAfflictionStrength("pneumoniabacteria"))
        if index > 0 then
            info = NTCS_Infections.BacteriasIndex[index]
            defense = C:GetAfflictionStrength("systemicresponse") / 100
        end

        index = NTCS.HF.Round(C:GetAfflictionStrength("pneumoniavirus"))
        if index > 0 then
            info = NTCS_Infections.VirusesIndex[index]
            defense = C:GetAfflictionStrength("viralantibodies") / 100
        end

        if info == nil then
            C:SetAffliction(Identifier, 0)
            return
        end

        local antibiotic = NTCS_Infections.GetAntibioticValue(C.Human, info.antibiotics)
        local increase = (math.min(info.basespeed + 10 * info.severityspeed, 0.99)
                    * NTCS.HF.BoolToNum(NTCS.Config.Get("NTI_pneumoniaSpeed", true))
                    * (1 - (NTCS.HF.GetAfflictionStrength(C.Human, info.vaccine, 0) / 200) * (immunity / 100))
                    * antibiotic)
                - defense

        C:AddAffliction(Identifier, increase)

        if not NTCS_Infections.HasSepsis(C.Human) then
            if NTCS.HF.Chance(((strength + increase) / 300) ^ 3) then
                C:SetAffliction("sepsis", 1)
            end
        end
    end
end):Build()

AfflictionLoader:Register(Pneumonia)

-- Bacteria + Virus folded into 1 (same code)
local function RegisterPneumoniaVariant(id)
    local marker = AfflictionBuilder:New(id):SetUpdateAction(function(C, Identifier, Limb, DeltaT)
        if C:GetAfflictionStrength("pneumonia") <= 0 then
            C:SetAffliction(Identifier, 0)
        end
    end):Build()

    AfflictionLoader:Register(marker)
end

RegisterPneumoniaVariant("pneumoniabacteria")
RegisterPneumoniaVariant("pneumoniavirus")

-- Overriding other mods stuff
if (NTCS_SurgeryPlus ~= nil) then
    NTCS_SurgeryPlus.TriggerUnsterilityEvent=function(character)
        NTCS_Infections.TriggerUnsterilityEvent(character)
    end
end