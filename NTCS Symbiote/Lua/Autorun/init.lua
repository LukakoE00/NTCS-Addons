NTCS_Symbiote = {}
NTCS_Symbiote.Name="Symbiote"
NTCS_Symbiote.Version = "A1.0.0"
NTCS_Symbiote.VersionNum = 01000000
NTCS_Symbiote.Path = table.pack(...)[1]

-- Initialise C# Classes needed
dofile(NTCS_Symbiote.Path.."/Lua/Library/NeurotraumaLib.lua")
NTCS.Info.RegisterAddon(NTCS_Symbiote)

local NTLuaEnabledMsg = "Error loading NTCS Cybernetics: Lua Neurotrauma is enabled!"
local NTCSNotEnabledMsg = "Error loading NTCS Cybernetics: It appears Neurotrauma CS isn't loaded!"

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
        dofile(NTCS_Symbiote.Path.."/Lua/Scripts/HelperFunctions.lua")
        dofile(NTCS_Symbiote.Path.."/Lua/Scripts/HumanUpdate.lua")
        dofile(NTCS_Symbiote.Path.."/Lua/Scripts/Items.lua")

        -- Hook a function to NTCS Post-HumanUpdate
		Hook.Add("Neurotrauma.HumanUpdate.PostHook", "NTCS_Symbiote.CheckForZealotRobes", function(character, deltaTime)
			if character == nil or character.Human == nil or character.Human.Removed then return end
			NTCS_Symbiote.CheckForZealotRobes(character.Human, deltaTime)
		end)
	end, 1)
end