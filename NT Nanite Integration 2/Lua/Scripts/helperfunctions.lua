function NTNan.addAfflictionAllLimbs(character, affliction, strength)
    for _,limb in pairs(NTCS.HF.LimbsToCheck) do
        character:AddAfflictionLimb(affliction, limb, strength)
    end
end

function NTNan.applyHeals(C, healStats)


    for _,hl in pairs(healStats)do

        local affName = hl[1]
        local str = hl[2]
        local isLocal = hl[3]

        if isLocal == nil then
            C:AddAffliction(affName, -1*str*NT.Deltatime)
        else
            for _,limb in pairs(NTNan.Limbs) do
                C:AddAfflictionLimb(affName, limb, -1*str*NT.Deltatime)
            end
            
        end
    end

end

function NTNan.hasEnoughPrecursors(character, afflictions)

    local nanitesCount = 0
    
    for aff in afflictions do
        if aff == "naniteremover" or aff == "precursor" or aff == "nanitedecay" then
            goto continue
        end

        if aff == "oxybloodnanite" then
            nanitesCount = nanitesCount + 2*HF.GetAfflictionStrength(character, aff)
            goto continue
        end

        nanitesCount = nanitesCount + HF.GetAfflictionStrength(character, aff)

        ::continue::
    end

    if nanitesCount == 0 then return true end

    if not HF.HasAffliction(character, "precursor") then
        return false
    end

    local precursorCount = HF.GetAfflictionStrength(character, "precursor")
    if nanitesCount > precursorCount then
        return false
    end

    return true

end

function NTNan.GetAfflictionHeals(healsStats, tier)

    local heals = {}

    for key, i in ipairs(healsStats) do

        for _,value in pairs(i) do
            table.insert(heals, value)
        end

        if key == math.floor(tier) then return heals end

    end

    return {}
end

