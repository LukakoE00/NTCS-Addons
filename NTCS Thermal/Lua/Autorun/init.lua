-- Most of this code has been lifted from NT Eyes, you should go check it out. Thank you POSTACI.
-- Set up dictonary
NTCS_Thermal = {}
NTCS_Thermal.Name = "Thermal"
NTCS_Thermal.Version = "1.0.0h0"
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
dofile(NTCS_Thermal.Path.."/Lua/Library/thermfunctions.lua") -- Setup THERM functions.
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
	
	--NTCS.NTC.AddDrainageAffliction("pulmonary_edema", 3, "retractedskin", function (itemPackage)
		--return true
	--end) -- Make pulmonary_edema go away with drainage.
	
	--NTCS.NTC.AddSuturableAffliction("removed_skin",3,"removed_skin",function (itemPackage) -- Cure removed skin with sutures.
        --local item = itemPackage.item
        --local usingCharacter = itemPackage.user.Human
        --local targetCharacter = itemPackage.target.Human
        --local targetLimb = itemPackage.targetLimb
		--NTCS.HF.AddAfflictionLimb(targetCharacter, "removed_skin", targetLimb.type, -100, usingCharacter)
		--return true
	--end)

	--NTCS.NTC.AddSuturableAffliction("grafted_skin", 3, "grafted_skin", function (itemPackage) -- Cure removed skin with sutures.
        --local item = itemPackage.item
        --local usingCharacter = itemPackage.user.Human
        --local targetCharacter = itemPackage.target.Human
        --local targetLimb = itemPackage.targetLimb
		--NTCS.HF.AddAfflictionLimb(targetCharacter, "grafted_skin", targetLimb.type, -100, usingCharacter)
		--THERM.ReduceBurns(targetCharacter,targetLimb,usingCharacter)
		--return true
	--end)

	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/humanupdate.lua") 		-- HumanUpdates.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/heatedsuitlist.lua") 	-- The Heated Diving Suit
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/playerhooks.lua") 		-- Main Hooks used for a large portion of the mod.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/roomtempcalc.lua") 		-- Script used for a calculating temperature of rooms.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/items.lua") 			-- Item methods.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/modcompat.lua") 		-- Compat.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/translationcompat.lua") -- Translation Compat.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/patches.lua") 			-- Patches.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/debug.lua") 			-- Patches.
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Server/ondamaged.lua") 		-- ondamaged.

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
	dofile(NTCS_Thermal.Path .. "/Lua/Scripts/Shared/configdata.lua") 	    --Config.
end, 1)