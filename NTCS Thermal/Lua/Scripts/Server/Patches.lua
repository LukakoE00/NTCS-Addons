-- I'm going to patch the bots to not kill themselves in water here at some point.

THERMPatch = {}
THERMPatch.RepairTools = {
                          ["extinguisher"] = -.0025,["plasmacutter"] = .0035,["weldingtool"] = .0025,["flamer"] = .0025,
                          ["ekutility_laserdrill"] = .005,["ekutility_arcwelder"] = .0015,["ekutility_ioncutter"] = .0015, ["ekutility_miningdrill"]= .003 -- EK Compat
                         }

-- Panicked stops you from shooting patch!
Hook.Patch("Barotrauma.Items.Components.RangedWeapon","Use", function (instance, ptable)
    local User = THERM.InstanceToUser(instance)
    if NTCS.Config.Get("FireCausePanic", true) and not (NTCS.Config.Get("BotTempIgnoreMode", true) and User and User.IsBot)
		and not (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(User, "pressurestabilized", 0) > 0)then
        local Character = ptable["character"]
        if NTCS.HF.GetAfflictionStrength(Character, "panicking", 0) > 0 then
            ptable.PreventExecution = true
        end
    end
end, Hook.HookMethodType.Before)

-- Hooks Lua event "Barotrauma.Character" to apply vanilla burning (formerly NT onfire) affliction and set a human on fire
Hook.HookMethod("Barotrauma.Character", "ApplyStatusEffects", function(instance, ptable)
	if ptable.actionType == ActionType.OnFire and NTCS.Config.Get("FireCausePanic", true) and not (NTCS.Config.Get("BotTempIgnoreMode", true) and instance.IsBot)
		and not (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(instance, "pressurestabilized", 0) > 0) then
        local function MakeOnFire(character)
            if NTCS.HF.GetAfflictionStrength(character, "ntt_temperature", 0) > THERM.FetchConfigStats().HyperthermiaLevel * NTCS_Thermal.LowHyperthermiaScaling then
                NTCS.HF.AddAffliction(character, "panicking", 2.5 * (ptable.deltaTime * 5))
            end
        end

		if instance.IsHuman then
			if not NTCS.HF.HasAffliction(instance, "luabotomy") then NTCS.HF.SetAffliction(instance, "luabotomy", 1) end
            MakeOnFire(instance)
		end
	end
end, Hook.HookMethodType.After)

-- Used for displaying temperature via status monitor
--Hook.Patch("Barotrauma.Items.Components.MiniMap", "SetTooltip", function(instance, ptable)
--end, Hook.HookMethodType.After)

-- For irridating heat from a welder
Hook.Patch("Barotrauma.Items.Components.RepairTool", "Use", function(instance, ptable)
    local User = THERM.InstanceToUser(instance)
    if NTCS.Config.Get("RepairToolsTemp",true) and not (NTCS.Config.Get("BotTempIgnoreMode", true) and User and User.IsBot)
		and not (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(User, "pressurestabilized", 0) > 0) then
        local ItemIdentifier = instance.Item.Prefab.Identifier

        local Temp = function ()
            local Temp = THERMPatch.RepairTools[tostring(ItemIdentifier)]
            if not User then
                return 0
            end
            if not Temp then return 0 end
            if Temp < 0 then
                return Temp
            end
            return Temp / THERM.TotalBurnResistance(THERM.GetCharacter(User.ID,User))
        end

        if User then
            local Temp = Temp()
            NTCS.HF.AddAfflictionLimb(User, "ntt_temperature", LimbType.LeftArm, Temp)
            NTCS.HF.AddAfflictionLimb(User, "ntt_temperature", LimbType.RightArm, Temp)
        end
    end
end, Hook.HookMethodType.After)