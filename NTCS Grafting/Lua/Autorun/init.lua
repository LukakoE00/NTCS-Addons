
NTGraft = {} -- Neurotrauma Grafting
NTGraft.Name="Grafting FORKED"
NTGraft.Version = "0.0.0"
NTGraft.VersionNum = 00000000
NTGraft.MinNTVersion = "A1.9.0"

NTGraft.MinNTVersionNum = 01090000
NTGraft.Path = table.pack(...)[1]
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(NTGraft) end end,1)

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    Timer.Wait(function()
        if NT ~= nil and NT.VersionNum < 01090000 then
            print("Error loading: use the modern fork published by 'guns'")
            Game.SendMessage("Error loading: use the modern fork published by 'guns'")
            return
        end
        if NTC == nil then
            print("Error loading: It appears Neurotrauma isn't loaded!")
            Game.SendMessage("Error loading: It appears Neurotrauma isn't loaded!", ChatMessageType.Server)
            return
        end
        -- Seed the shared RNG once before gameplay handlers use it.
        if NTGraft.RandomSeeded ~= true then
            math.randomseed(os.time())
            NTGraft.RandomSeeded = true
        end
        dofile(NTGraft.Path.."/Lua/Scripts/empexplosionpatch.lua")
        dofile(NTGraft.Path.."/Lua/Scripts/humanupdate.lua")
        dofile(NTGraft.Path.."/Lua/Scripts/items.lua")
--        dofile(NTGraft.Path.."/Lua/Scripts/items.shared.lua")
--        dofile(NTGraft.Path.."/Lua/Scripts/ondamaged.lua")
--        dofile(NTGraft.Path.."/Lua/Scripts/helperfunctions.lua")
    
--        dofile(NTGraft.Path.."/Lua/Scripts/testing.lua")



    end,1)
else
    Timer.Wait(function()
        if NT ~= nil and NT.VersionNum < 01090000 then
            local msg = "Error loading: old Neurotrauma detected, use the modern fork published by 'guns'"
            print(msg)
            Game.ChatBox.AddMessage(ChatMessage.Create("", msg, ChatMessageType.Server, nil))
            return
        end
--        dofile(NTGraft.Path.."/Lua/Scripts/items.client.lua")
--        dofile(NTGraft.Path.."/Lua/Scripts/items.shared.lua")
    end, 1)
end

Timer.Wait(function()
--    dofile(NTGraft.Path.."/Lua/Scripts/configdata.lua")
end, 1)
