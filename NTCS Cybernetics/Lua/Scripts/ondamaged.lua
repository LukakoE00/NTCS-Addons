local convertedDamageTypes = {
	"bleeding",
	"blunttrauma",
	"lacerations",
	"burn",
	"gunshotwound",
	"bitewounds",
	"explosiondamage",
	"internaldamage",
	"foreignbody",
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

Timer.Wait(function()
	NTCS_Cybernetics.NTC.AddOnDamagedHook(function(characterHealth, attackResult, hitLimb)
		-- automatically convert damage types
		local targetChar = characterHealth.Character
		local causeDamageTypeConversion = false
		local identifier = ""
		local sfxidentifier = nil

		for index, value in ipairs(attackResult.Afflictions) do
			if value.Strength > 1 then
				identifier = value.Prefab.Identifier.Value

				if NTCS.HF.TableContains(convertedDamageTypes, identifier) then
					causeDamageTypeConversion = true
					if damageTypeSFXDict[identifier] ~= nil then sfxidentifier = damageTypeSFXDict[identifier] end
				end
			end
		end

		if causeDamageTypeConversion and NTCS_Cybernetics.HF.LimbIsCyber(targetChar, hitLimb.type) then
			if sfxidentifier ~= nil then NTCS.HF.GiveItem(targetChar, sfxidentifier) end
			Timer.Wait(function()
				NTCS_Cybernetics.ConvertDamageTypes(targetChar, hitLimb.type)
			end, 1)
		end
	end)
end, 1)

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