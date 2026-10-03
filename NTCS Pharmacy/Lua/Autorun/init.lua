
NTCS_Pharmacy = {}
NTCS_Pharmacy.Name="Pharmacy"
NTCS_Pharmacy.Version = "A1.0.8"
NTCS_Pharmacy.VersionNum = 01000800
NTCS_Pharmacy.MinNTVersion = "A1.15.0"
NTCS_Pharmacy.MinNTVersionNum = 01150000
NTCS_Pharmacy.Path = table.pack(...)[1]

-- Initialise C# Classes needed
dofile(NTCS_Cybernetics.Path.."/Lua/Library/NeurotraumaLib.lua")
NTCS.Info.RegisterAddon(NTCS_Cybernetics)

local NTLuaEnabledMsg = "Error loading NTCS Cybernetics: Lua Neurotrauma is enabled!"
local NTCSNotEnabledMsg = "Error loading NTCS Cybernetics: It appears Neurotrauma CS isn't loaded!"

-- Serverside + Singleplayer code
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

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

    dofile(NTCS_Pharmacy.Path.."/Lua/Scripts/Items.lua")
    dofile(NTCS_Pharmacy.Path.."/Lua/Scripts/Pills.lua")

    Timer.Wait(function()
        -- Symbiote patch for pill effects with calyxanide ingredient / husk cure combo
        if NTS ~= nil then 
            dofile(NTCS_Pharmacy.Path.."/Lua/Scripts/symbiotepatch.lua")
        end
    end,1)
end