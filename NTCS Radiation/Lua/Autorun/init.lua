---@diagnostic disable: undefined-global

NTCS_Rad = {} -- Neurotrauma Radiation
NTCS_Rad.Name="Radiation"
NTCS_Rad.Version = "1.0.0"
NTCS_Rad.VersionNum = 01000000
NTCS_Rad.MinNTVersion = "2.0.0"
NTCS_Rad.MinNTVersionNum = 02000000
NTCS_Rad.Path = table.pack(...)[1]

dofile(NTCS_Rad.Path.."/Lua/Library/NeurotraumaLib.lua")
NTCS.Info.RegisterAddon(NTCS_Rad)

local NTLuaEnabledMsg = "Error loading NT Radiation: Lua Neurotrauma is enabled!"
local NTCSNotEnabledMsg = "Error loading NT Radiation: It appears Neurotrauma CS isn't loaded!"

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
		dofile(NTCS_Rad.Path .. "/Lua/Scripts/helperfunctions.lua")
        dofile(NTCS_Rad.Path .. "/Lua/Scripts/afflictions.lua")
        dofile(NTCS_Rad.Path .. "/Lua/Scripts/items.lua")
	end, 1)
else
	Timer.Wait(function()

		if NT ~= nil then
			print(NTLuaEnabledMsg)
			Game.SendMessage(NTLuaEnabledMsg, ChatMessageType.Server)
			return
		end

		if NTCS.Info == nil then
			print(NTCSNotEnabledMsg)
			Game.SendMessage(NTCSNotEnabledMsg, ChatMessageType.Server)
			return
		end

	end, 1)
end

Timer.Wait(function()
	dofile(NTCS_Rad.Path .. "/Lua/Scripts/config.lua")
end, 1)