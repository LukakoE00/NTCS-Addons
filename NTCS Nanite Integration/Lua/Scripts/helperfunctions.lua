function NTCS_Nanite.addAfflictionAllLimbs(character, affliction, strength)
    character.Human.CharacterHealth.ReduceAfflictionOnAllLimbs(affliction, -strength)
end

function NTCS_Nanite.downBattery(ntHuman, amount)

    local currentStrength = ntHuman:GetAfflictionStrength("nanitebattery")

    local multiplier = NTCS.Config.Get("NTCS_Nanite_batteryDecayMultiplier", 1)

    -- TODO: get config working
    ntHuman:SetAffliction("nanitebattery", math.max(currentStrength - amount * multiplier, 1))
end