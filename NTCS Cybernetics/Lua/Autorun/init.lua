NTCS_Cybernetics = {}
NTCS_Cybernetics.Name = "Cybernetics"
NTCS_Cybernetics.Version = "A1.5.2"
NTCS_Cybernetics.VersionNum = 01050200
NTCS_Cybernetics.MinNTVersion = "A1.9.0"
NTCS_Cybernetics.MinNTVersionNum = 01090000
NTCS_Cybernetics.Path = table.pack(...)[1]

dofile(NTCS_Cybernetics.Path.."/Lua/Library/NeurotraumaLib.lua")
Neurotrauma.NTInfo.RegisterAddon(NTCS_Cybernetics)

local NTLuaEnabledMsg = "Error loading NTCS Cybernetics: Lua Neurotrauma is enabled!"
local NTCSNotEnabledMsg = "Error loading NTCS Cybernetics: It appears Neurotrauma CS isn't loaded!"

-- Serverside + Singleplayer code
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then
	Timer.Wait(function()

		if NT ~= nil then
			print(NTLuaEnabledMsg) 
			Game.SendMessage(NTLuaEnabledMsg, ChatMessageType.Server)
			return
		end

		if Neurotrauma.NTInfo == nil then
			print(NTCSNotEnabledMsg)
			Game.SendMessage(NTCSNotEnabledMsg, ChatMessageType.Server)
			return
		end

	end, 1)
else
	Timer.Wait(function()

		if NT ~= nil then
			print(NTLuaEnabledMsg) 
			Game.SendMessage(NTLuaEnabledMsg, ChatMessageType.Server)
			return
		end

		if Neurotrauma.NTInfo == nil then
			print(NTCSNotEnabledMsg)
			Game.SendMessage(NTCSNotEnabledMsg, ChatMessageType.Server)
			return
		end

	end, 1)
end

