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

NTCS.NTC.AddOnDamagedHook(function(characterHealth, attackResult, hitLimb)

    local targetChar = characterHealth.Character
    local sfxidentifier = nil
    local convert = false

    for _, value in pairs(attackResult.Afflictions) do
        local identifier = value.Prefab.Identifier.Value

        if value.Strength > 1 and convertedDamageTypes[identifier] then
            convert = true
            sfxidentifier = damageTypeSFXDict[identifier] or sfxidentifier
        end
    end

    local isCyber = NTCS_Cybernetics.HF.LimbIsCyber(targetChar, hitLimb.type)

    if convert and isCyber then
        if sfxidentifier ~= nil then NTCS.HF.GiveItem(targetChar, sfxidentifier) end
        Timer.Wait(function()
            NTCS_Cybernetics.ConvertDamageTypes(targetChar, hitLimb.type)
        end, 1)
    end
end)

-- C# Method in the HF class;
-- We want to add a check for Cybernetics before running the original Dislocate function.
Hook.Patch("Neurotrauma.HF", "DislocateLimb", function(instance, ptable)
    local Character = ptable["Character"]
    local GivenLimbType  = ptable["GivenLimbType"]
    local Strength  = ptable["Strength"]

    if Strength > 0 and NTCS_Cybernetics.HF.LimbIsCyber(chaCharacterracter, GivenLimbType) then
        ptable.PreventExecution = true
    end
end, Hook.HookMethodType.Before)

Hook.Patch("Neurotrauma.HF", "BreakLimb", function(instance, ptable)
    local Character = ptable["Character"]
    local GivenLimbType  = ptable["GivenLimbType"]
    local Strength  = ptable["Strength"]

    if Strength > 0 and NTCS_Cybernetics.HF.LimbIsCyber(chaCharacterracter, GivenLimbType) then
        ptable.PreventExecution = true
    end
end, Hook.HookMethodType.Before)

Hook.Patch("Neurotrauma.HF", "ArteryCutLimb", function(instance, ptable)
    local Character = ptable["Character"]
    local GivenLimbType  = ptable["GivenLimbType"]
    local Strength  = ptable["Strength"]

    if Strength > 0 and NTCS_Cybernetics.HF.LimbIsCyber(chaCharacterracter, GivenLimbType) then
        ptable.PreventExecution = true
    end
end, Hook.HookMethodType.Before)