NTCS_Infections = {}
NTCS_Infections.Name = "Infections"
NTCS_Infections.Version = "1.0.1"
NTCS_Infections.VersionNum = 01000001
NTCS_Infections.Path=table.pack(...)[1]

-- Initialise C# Classes needed
dofile(NTCS_Infections.Path.."/Lua/Library/NeurotraumaLib.lua")
NTCS.Info.RegisterAddon(NTCS_Infections)

local NTLuaEnabledMsg = "Error loading NTCS Infections: Lua Neurotrauma is enabled!"
local NTCSNotEnabledMsg = "Error loading NTCS Infections: It appears Neurotrauma CS isn't loaded!"

-- Serverside + Singleplayer code
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then
	Timer.Wait(function()

		-- NT is the table initialised in Lua Neurotrauma and not present in NTCS. If this returns true, NT Lua is active.
		if NT ~= nil then
			print(NTLuaEnabledMsg) 
			Game.SendMessage(NTLuaEnabledMsg, ChatMessageType.Server)
			return
		end

		-- If Info cannot be found it's because the initialization line above did not trigger since NTCS isn't active.
		if NTCS.Info == nil then
			print(NTCSNotEnabledMsg)
			Game.SendMessage(NTCSNotEnabledMsg, ChatMessageType.Server)
			return
		end

		-- Lua Content Scripts SP/MP:
        dofile(NTCS_Infections.Path.."/Lua/Scripts/HumanUpdate.lua")
        dofile(NTCS_Infections.Path.."/Lua/Scripts/Items.lua")
        dofile(NTCS_Infections.Path.."/Lua/Scripts/HelperFunctions.lua")

	end, 1)
end

Timer.Wait(function()
    dofile(NTCS_Infections.Path.."/Lua/Scripts/ConfigData.lua")
end, 1)
