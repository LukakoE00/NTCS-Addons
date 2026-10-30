NTCS_Eyes = {} 
NTCS_Eyes.Name = "Eyes"
NTCS_Eyes.Version = "1.0.0"
NTCS_Eyes.VersionNum = 01000000
NTCS_Eyes.Path = table.pack(...)[1]

dofile(NTCS_Eyes.Path.."/Lua/Library/NeurotraumaLib.lua")
NTCS.Info.RegisterAddon(NTCS_Eyes)

local NTLuaEnabledMsg = "Error loading NTCS Eyes: Lua Neurotrauma is enabled!"
local NTCSNotEnabledMsg = "Error loading NTCS Eyes: It appears Neurotrauma CS isn't loaded!"

-- Serverside + Singleplayer code
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

	if SERVER or (CLIENT and not Game.IsMultiplayer) then
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Server/HumanUpdate.lua") --passive update checks
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Server/Items.lua") --item functions
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Server/LOSWarning.lua") --warning in chat about line of sight
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Server/HUDItemSpawn.lua") --spawns required items for drawing client-side huds
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Server/ServerReceive.lua") --server-client communications
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Server/Multiscalpel.lua") --multipurpouse scalpel override
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Server/OnDamaged.lua") --physical damage calculation
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Server/Spoon.lua") --spoon
	end

	if CLIENT then
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Client/ClientUpdate.lua") --client-side updates (visual)
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Client/ClientHUD.lua") --writes hud over screen
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Client/ClientControls.lua") --client keyboard controls
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Client/HealthScanner.lua") --health scanner code for medical eyes
		dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Client/ClientSend.lua") --server-client communications
	end

	-- Shared code
	dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Shared/ConfigData.lua")
	dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Shared/InterfaceEnable.lua")
	dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Shared/HelperFunctions.lua")
	dofile(NTCS_Eyes.Path .. "/Lua/Scripts/Shared/HUIButtons.lua") -- Add SurgeryButtons
end, 1)