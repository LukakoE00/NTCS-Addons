local affLoader = NTCS.AfflictionsLoader(NTCS_Lobotomy.Name)
local builder = NTCS.AfflictionPrefabBuilder()

affLoader:Register(
    builder:New("lobo_infinitepsychosis")
    :SetStrengths(0,2,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.LOW)
    :SetUpdateAction(function(C, ID, Limb, dT)
        C:AddAfflictionLimb("psychosis", Limb, 100) -- might want to reduce this for compatibility with Nanites
    end)
    :Build()
)

affLoader:Register(
    builder:New("lobo_paralysis")
    :SetStrengths(0,2,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.LOW)
    :SetUpdateAction(function(C, ID, Limb, dT)
        C:AddAfflictionLimb("givein", Limb, 1 * dT)
    end)
    :Build()
)

affLoader:Register(
    builder:New("lobo_nausea")
    :SetStrengths(0,2,0)
    :IsLimbSpecific(true)
    :SetUpdateAction(function(C, ID, Limb, dT) -- Chance based affliction stay on HIGH priority to not skew the chances
        if NTCS.HF.Chance(0.2) then
            C:AddAffliction("nausea", 10 * dT)
        end
    end)
    :Build()
)

affLoader:Register(
    builder:New("lobo_randomarrest")
    :SetStrengths(0,2,0)
    :IsLimbSpecific(true)
    :SetUpdateAction(function(C, ID, Limb, dT) -- Chance based affliction stay on HIGH priority to not skew the chances
        if NTCS.HF.Chance(0.3) then
            C:AddAffliction("respiratoryarrest", 100)
        end
    end)
    :Build()
)

affLoader:Register(
    builder:New("lobo_randomuncon")
    :SetStrengths(0,2,0)
    :IsLimbSpecific(true)
    :SetUpdateAction(function(C, ID, Limb, dT) -- Chance based affliction stay on HIGH priority to not skew the chances
        if NTCS.HF.Chance(0.05) then
            C:AddAffliction("unconsciousness", 100)
        end
    end)
    :Build()
)

affLoader:Register(
    builder:New("lobo_constantpain")
    :SetStrengths(0,2,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.LOW)
    :SetUpdateAction(function(C, ID, Limb, dT)
        if not C:HasAffliction("analgesia") and not C:HasAffliction("lobo_nopain") then
            C:AddAfflictionLimb("pain_extremity", LimbType.Head, 100) --head
            C:AddAfflictionLimb("pain_extremity", LimbType.Torso, 100) --torso
            C:AddAfflictionLimb("pain_extremity", LimbType.RightArm, 100) --right arm
            C:AddAfflictionLimb("pain_extremity", LimbType.LeftArm, 100) --left arm
            C:AddAfflictionLimb("pain_extremity", LimbType.RightLeg, 100) --right leg
            C:AddAfflictionLimb("pain_extremity", LimbType.LeftLeg, 100) --left leg
        end
    end)
    :Build()
) 