function NTNan.addAfflictionAllLimbs(character, affliction, strength)
    for _,limb in pairs(NTCS.HF.LimbsToCheck) do
        character:AddAfflictionLimb(affliction, limb, strength)
    end
end