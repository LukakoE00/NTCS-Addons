
NTNan = {} -- Neurotrauma Nanite Integration
NTNan.Name="Nanite Integration"
NTNan.Version = "2.0.1"
NTNan.VersionNum = 02000001
NTNan.MinNTVersion = "2.0.0"
NTNan.MinNTVersionNum = 02000000
NTNan.Path = table.pack(...)[1]

dofile(NTNan.Path.."/Lua/Library/NeurotraumaLib.lua")
NTCS.Info.RegisterAddon(NTNan)

local NTLuaEnabledMsg = "Error loading NT Nanite Integration: Lua Neurotrauma is enabled!"
local NTCSNotEnabledMsg = "Error loading NT Nanite Integration: It appears Neurotrauma CS isn't loaded!"

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
		dofile(NTNan.Path .. "/Lua/Scripts/helperfunctions.lua")
		dofile(NTNan.Path .. "/Lua/Scripts/hook.lua")
        dofile(NTNan.Path .. "/Lua/Scripts/afflictions.lua")
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

-- Timer.Wait(function()
-- 	dofile(NTNan.Path .. "/Lua/Scripts/ConfigData.lua")
-- end, 1)