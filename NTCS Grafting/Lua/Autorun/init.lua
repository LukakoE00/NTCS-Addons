NTCS_Grafting = {}
NTCS_Grafting.Name = "Grafting"
NTCS_Grafting.Version = "A1.0.0"
NTCS_Grafting.VersionNum = 01000000
NTCS_Grafting.Path = table.pack(...)[1]

-- Initialise C# Classes needed
dofile(NTCS_Grafting.Path.."/Lua/Library/NeurotraumaLib.lua")
NTCS.Info.RegisterAddon(NTCS_Grafting)

local NTLuaEnabledMsg = "Error loading NTCS Grafting: Lua Neurotrauma is enabled!"
local NTCSNotEnabledMsg = "Error loading NTCS Grafting: It appears Neurotrauma CS isn't loaded!"

Timer.Wait(function()

	-- NT is the table initialised in Lua Neurotrauma and not present in NTCS. If this returns true, NT Lua is active.
	if (SERVER or (CLIENT and not Game.IsMultiplayer)) and NT ~= nil then
		print(NTLuaEnabledMsg) 
		Game.SendMessage(NTLuaEnabledMsg, ChatMessageType.Server)
		return
	end

	-- If Info cannot be found it's because the initialization line above did not trigger since NTCS isn't active.
	if (SERVER or (CLIENT and not Game.IsMultiplayer)) and NTCS.Info == nil then
		print(NTCSNotEnabledMsg)
		Game.SendMessage(NTCSNotEnabledMsg, ChatMessageType.Server)
		return
	end

	-- Singleplayer + Serverside code
	if SERVER or (CLIENT and not Game.IsMultiplayer) then
		dofile(NTCS_Grafting.Path .. "/Lua/Scripts/Server/CreatureDrops.lua") -- Add loot drops via Lua instead of XML overrides
	end

	-- Client code
	if CLIENT then
	end

	-- Shared code
end, 1)