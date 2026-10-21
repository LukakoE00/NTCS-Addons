-- Most of this code has been lifted from NT Eyes, you should go check it out. Thank you POSTACI.
-- Set up dictonary
NTCS_Thermal = {}
NTCS_Thermal.Name = "Thermal"
NTCS_Thermal.Version = "1.0.2h3"
NTCS_Thermal.VersionNum = 000000001
NTCS_Thermal.MinNTVersion = "A1.12.1"
NTCS_Thermal.MinNTVersionNum = 01120100
NTCS_Thermal.Path = table.pack(...)[1]
-- I don't think this is required.
NTCS_Thermal.OnDamagedMethods = {}
NTCS_Thermal.UsingRoboTrauma = false
NTCS_Thermal.UsingEnhancedReactors = false

-- Initialise C# Classes needed
dofile(NTCS_Thermal.Path.."/Lua/Library/NeurotraumaLib.lua")
NTCS.Info.RegisterAddon(NTCS_Thermal)

local NTLuaEnabledMsg = "Error loading NTCS Thermal: Lua Neurotrauma is enabled!"
local NTCSNotEnabledMsg = "Error loading NTCS Thermal: It appears Neurotrauma CS isn't loaded!"

LuaUserData.MakeMethodAccessible(Descriptors["Barotrauma.Explosion"], "GetObstacleDamageMultiplier") -- For the Enhanced Reactors compat

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

	NTCS_Thermal.UsingEnhancedReactors = EnhancedReactors -- Used to determine if enhanced reactors is on.

	--local thermal_afflictions = { "sym_hot", "sym_cold", "sym_shivers", "sym_numb", "heat_cramp" } -- Add our NPC symptom announcements.
	--table.insert(NT.SymsForNPC, thermal_afflictions)
	
	NTCS.NTC.AddDrainageAffliction("pulmonary_edema", 3, "retractedskin") -- Make pulmonary_edema go away with drainage.
	
	NTCS.NTC.AddSuturableAffliction("removed_skin",3,"removed_skin",
	function (itemPackage)
	    local item = itemPackage.item
        local usingCharacter = itemPackage.user.Human
        local targetCharacter = itemPackage.target.Human
        local targetLimb = itemPackage.targetLimb
		NTCS.HF.AddAfflictionLimb(targetCharacter, "removed_skin", targetLimb.type, -100, usingCharacter)
	end)

	NTCS.NTC.AddSuturableAffliction("grafted_skin", 3, "grafted_skin",
	function (itemPackage)
	    local item = itemPackage.item
        local usingCharacter = itemPackage.user.Human
        local targetCharacter = itemPackage.target.Human
        local targetLimb = itemPackage.targetLimb
		NTCS.HF.AddAfflictionLimb(targetCharacter, "grafted_skin", targetLimb.type, -100, usingCharacter)
		THERM.ReduceBurns(targetCharacter,targetLimb,usingCharacter)
	end)

	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/HumanUpdate.lua") 		-- HumanUpdates.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/HeatedSuitList.lua") 	-- The Heated Diving Suit
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/PlayerHooks.lua") 		-- Main Hooks used for a large portion of the mod.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/RoomTempCalc.lua")     -- Script used for a calculating temperature of rooms.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/Items.lua") 			-- Item methods.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/ModCompat.lua") 		-- Compat.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/TranslationCompat.lua") -- Translation Compat.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/Patches.lua") 			-- Patches.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/Debug.lua") 			-- Patches.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/OnDamaged.lua") 		-- ondamaged.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/ThermFunctions.lua")   -- Setup THERM functions.

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
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Shared/ConfigData.lua") 	    --Config.
end, 1)