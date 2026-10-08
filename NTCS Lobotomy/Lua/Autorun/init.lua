NTCS_Lobotomy = {} -- Neurotrauma Lobotomy
NTCS_Lobotomy.Name="Lobotomy"
NTCS_Lobotomy.Version = "1.0.0"
NTCS_Lobotomy.VersionNum = 01000000
NTCS_Lobotomy.MinNTVersion = "2.0.0"
NTCS_Lobotomy.MinNTVersionNum = 02000000
NTCS_Lobotomy.Path = table.pack(...)[1]

dofile(NTCS_Lobotomy.Path.."/Lua/Library/NeurotraumaLib.lua")
NTCS.Info.RegisterAddon(NTCS_Lobotomy)

local NTLuaEnabledMsg = "Error loading NTCS Lobotomy: Lua Neurotrauma is enabled!"
local NTCSNotEnabledMsg = "Error loading NTCS Lobotomy: It appears Neurotrauma CS isn't loaded!"

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
        dofile(NTCS_Lobotomy.Path.."/Lua/Scripts/Server/hf.lua")
        dofile(NTCS_Lobotomy.Path.."/Lua/Scripts/Server/items.lua")
		dofile(NTCS_Lobotomy.Path.."/Lua/Scripts/Server/afflictions.lua")
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

        dofile(NTCS_Lobotomy.Path.."/Lua/Scripts/Client/effects.lua")

	end, 1)
end

-- Disabled for now because Robotrauma isnt compatible with NT? factcheck me on this -Cookie

-- for package in ContentPackageManager.EnabledPackages.All do
--     if 
--             tostring(package.UgcId) == "2948488019" --Robotrauma
--         or tostring(package.UgcId) == "2952546076" --Robo-Trauma-
--         or tostring(package.UgcId) == "3227815460" --Robotrauma (Afflictions Override)
--     then
--         if SERVER or (CLIENT and not Game.IsMultiplayer) then
--             dofile(NTCS_Lobotomy.Path.."/Lua/Scripts/Compatibility/robotrauma_comp.lua")
--             print("NTCS Lobotomy - Robotrauma Integrated Compatibility Patch")
--         end	
--     break
--     end
-- end 

