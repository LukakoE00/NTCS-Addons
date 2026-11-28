local convertedDamageTypes = {
    bleeding = true,
    blunttrauma = true,
    lacerations = true,
    burn = true,
    gunshotwound = true,
    bitewounds = true,
    explosiondamage = true,
    internaldamage = true,
    foreignbody = true,
}

local damageTypeSFXDict = {}
damageTypeSFXDict["blunttrauma"] = "ntcsfx_cyberblunt"
damageTypeSFXDict["lacerations"] = "ntcsfx_cyberblunt"
damageTypeSFXDict["burn"] = "ntcsfx_welding"
damageTypeSFXDict["gunshotwound"] = "ntcsfx_cyberblunt"
damageTypeSFXDict["bitewounds"] = "ntcsfx_cyberbite"
damageTypeSFXDict["explosiondamage"] = "ntcsfx_cyberblunt"
damageTypeSFXDict["internaldamage"] = "ntcsfx_cyberblunt"
damageTypeSFXDict["foreignbody"] = "ntcsfx_cyberblunt"

NTCS.NTC.AddModifyingOnDamagedHook(function(characterHealth, afflictions, hitLimb)
    local targetChar = characterHealth.Character
    if targetChar == nil or hitLimb == nil then return afflictions end
    if not NTCS_Cybernetics.HF.LimbIsCyber(targetChar, hitLimb.type) then return afflictions end

    local sfxidentifier = nil
    local IncomingDamage = {}
    local ShouldConvertToCyberAffliction = false

    for _, value in pairs(afflictions) do
        local identifier = value.Prefab.Identifier.Value

        if value.Strength > 1 and convertedDamageTypes[identifier] then
            ShouldConvertToCyberAffliction = true
            sfxidentifier = damageTypeSFXDict[identifier] or sfxidentifier
            IncomingDamage[identifier] = (IncomingDamage[identifier] or 0) + value.Strength
            value.Strength = 0
        end
    end

    if ShouldConvertToCyberAffliction then
        if sfxidentifier ~= nil then NTCS.HF.GiveItem(targetChar, sfxidentifier) end
        NTCS_Cybernetics.ConvertDamageTypes(targetChar, hitLimb.type, IncomingDamage)
    end

    return afflictions
end)