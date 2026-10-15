local itemLoader = NTCS.ItemFunctionLoader(NTCS_Nanite.Name)

itemLoader:Register("nanitebatteryimplant", function (d)

    local item = d.item
    local usingCharacter = d.user
    local targetCharacter = d.target
    local targetLimb = d.targetLimb

    -- Not usable in stasis
    if targetCharacter:GetBoolStat("stasis", false) then return end

    -- Only usable on the Torso
    if targetLimb.type ~= LimbType.Torso then return end

    -- Not usable if already there
    if targetCharacter:HasAffliction("nanitebattery") then return end

    if not targetCharacter:HasAfflictionLimb("retractedskin", targetLimb.type, 99) then return end

    if NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter.Human, 80) then
        
        targetCharacter:SetAffliction("nanitebattery", 100)

        Entity.Spawner.AddItemToRemoveQueue(item)
    else
        -- Failed
        targetCharacter:AddAffliction("heartdamage", 20)
        targetCharacter:AddAfflictionLimb("bleeding", LimbType.Torso, 10, usingCharacter)
    end

end)

itemLoader:Register("fulguriumbatterycell", function (d)
    
    local item = d.item
    local usingCharacter = d.user
    local targetCharacter = d.target
    local targetLimb = d.targetLimb

    -- Not usable in stasis
    if targetCharacter:GetBoolStat("stasis", false) then return end

    -- Only usable on the Torso
    if targetLimb.type ~= LimbType.Torso then return end

    -- Not usable if already there
    if not targetCharacter:HasAffliction("nanitebattery") then return end

    if not targetCharacter:HasAfflictionLimb("retractedskin", targetLimb.type, 99) then return end

end)