
NTCS_Pharmacy.ActiveChemCraftalls = {}

Timer.Wait(function() 

NT.ItemStartsWithMethods.custompill = function(item, usingCharacter, targetCharacter, limb)

    local config = NTCS_Pharmacy.TagsToPillconfig(HF.SplitString(item.Tags,","))

    for identifier,strength in pairs(config.fx) do
        HF.AddAffliction(targetCharacter,identifier,strength,usingCharacter)
    end

    HF.RemoveItem(item)
    HF.GiveItem(targetCharacter,"ntsfx_pills")
end

end,1)

function NTCS_Pharmacy.TryCraftPills(chemmaster,user,dontreporterrors)

    if chemmaster == nil or user == nil then return false end
    if dontreporterrors == nil then dontreporterrors = false end

    local errors = {}

    local inv = chemmaster.OwnInventory
    if inv == nil then return false end

    -- fetch ingredients
    local ingredients = {}
    ingredients.base = {inv.GetItemAt(0)}
    ingredients.binder = {inv.GetItemAt(1)}
    ingredients.filler = {inv.GetItemAt(2),inv.GetItemAt(3)}
    ingredients.dye = {inv.GetItemAt(4),inv.GetItemAt(5),inv.GetItemAt(6)}
    ingredients.active = {}
    for i = 7, 12, 1 do table.insert(ingredients.active,inv.GetItemAt(i)) end

    -- vaildate ingredients
    for categorykey,category in pairs(ingredients) do
        for item in category do
            local itemdata = NTCS_Pharmacy.PillData.items[item.Prefab.identifier.Value]
            if itemdata == nil then
                errors[#errors+1]=HF.ReplaceString(TextManager.Get("lua.chemerror.invaliditem").Value,"{id}",item.Name)
            elseif itemdata.types[1] ~= categorykey then
                errors[#errors+1]=HF.ReplaceString(TextManager.Get("lua.chemerror.invalidcategory."..categorykey).Value,"{id}",item.Name)
            else
            end
        end
    end

    -- missing ingredient errors
    if #ingredients.base <= 0 then errors[#errors+1] = TextManager.Get("lua.chemerror.missingbase").Value end
    if #ingredients.binder <= 0 then errors[#errors+1] = TextManager.Get("lua.chemerror.missingbinder").Value end
    --if #ingredients.active <= 0 then errors[#errors+1] = TextManager.Get("lua.chemerror.missingactive").Value end

    -- fetch ingredient array
    local ingredientArray = {}
    for categorykey,category in pairs(ingredients) do
        for item in category do ingredientArray[#ingredientArray+1] = item.Prefab.Identifier.Value end
    end

    -- determine config
    local descriptionOverride = nil
    if chemmaster.OriginalOutpost ~= "" then
        descriptionOverride=chemmaster.OriginalOutpost
    end
    local config = NTCS_Pharmacy.PillConfigFromItems(ingredientArray,HF.GetSkillLevel(user,"medical"),descriptionOverride,user)
    local productidentifier = "custompill"
    if config.sprite~=nil then productidentifier="custompill_"..config.sprite end

    -- determine if theres space to put the output
    local outputItem = inv.GetItemAt(13)
    if outputItem ~= nil then
        if outputItem.Prefab.Identifier.Value ~= productidentifier then
            errors[#errors+1] = TextManager.Get("lua.chemerror.outputfull").Value
        else
            local items = inv.AllItems
            local pillsInOutput = 0
            for item in items do
                if inv.FindIndex(item) == 13 then
                    pillsInOutput=pillsInOutput+1
                end
            end
            local capacity = outputItem.Prefab.MaxStackSize
            if pillsInOutput + config.yield > capacity then
                -- exceeding capacity, prevent craft
                table.insert(errors,TextManager.Get("lua.chemerror.outputfull").Value)
            end
        end
    end

    -- determine if the active ingredient capacity isnt exceeded
    if #ingredients.base>0 and #ingredients.active > config.capacity then
        errors[#errors+1] = HF.ReplaceString(
            TextManager.Get("lua.chemerror.capacity").Value,"{cap}",tostring(config.capacity))
    end

    -- determine if the configuration even yields at least one pill
    if config.yield<=0 then
        errors[#errors+1] = TextManager.Get("lua.chemerror.yield").Value
    end

    -- we had errors, report them and abort
    if #errors > 0 then
        if not dontreporterrors then
            HF.GiveItem(user,"NTCS_Pharmacysfx_chemerror")
            local client = HF.CharacterToClient(user)
            if CLIENT or client ~= nil then
                local errorstring=TextManager.Get("lua.chemerror.header").Value.."\n"
                for error in errors do
                    errorstring=errorstring.."\n"..error
                end
                HF.SendTextBox(TextManager.Get("entityname.chemmaster").Value,errorstring,client)
            end
        end
        return false
    end

    -- spawn output
    for i = 1, config.yield, 1 do
        HF.SpawnItemPlusFunction(productidentifier,function(params)
            NTCS_Pharmacy.SetPillFromConfig(params.item,params.config)
        end,{config=config},inv,13)
    end

    -- consume items
    for categorykey,category in pairs(ingredients) do
        if categorykey~="dye" then
            for item in category do HF.RemoveItem(item) end
        else
            for item in category do
                item.Condition = item.Condition-25
            end
        end
    end

    if not dontreporterrors then HF.GiveItem(user,"NTCS_Pharmacysfx_chemaccept") end
    return true
end


Hook.Add("NTCS_Pharmacy.ChemMaster.makeone", "NTCS_Pharmacy.ChemMaster.makeone", function (effect, deltaTime, item, targets, worldPosition)
    
    -- check if in craftall queue, if so, abort
    for craftall in NTCS_Pharmacy.ActiveChemCraftalls do
        if craftall==item then return end
    end
    
    local user = nil

    if SERVER then
        -- sadly lua hooks dont tell us who pressed the button, so it'll just be the closest client for now
        local minDist = 9000
        local itemPos = item.WorldPosition
        for key,client in pairs(Client.ClientList) do
            local char = client.Character
            if char ~= nil and char.IsHuman then
                local dist = HF.Distance(char.WorldPosition,itemPos)
                if dist < minDist then
                    minDist = dist
                    user=char
                end
            end
            
        end
    else 
        user=Character.Controlled
    end

    -- wait 250ms so that the description can update
    Timer.Wait(function() NTCS_Pharmacy.TryCraftPills(item,user) end,250)

end)

Hook.Add("NTCS_Pharmacy.ChemMaster.makeall", "NTCS_Pharmacy.ChemMaster.makeall", function (effect, deltaTime, item, targets, worldPosition)
    
    -- check if in craftall queue, if so, abort
    for craftall in NTCS_Pharmacy.ActiveChemCraftalls do
        if craftall==item then return end
    end
    
    local user = nil

    if SERVER then
        -- sadly lua hooks dont tell us who pressed the button, so it'll just be the closest client for now
        local minDist = 9000
        local itemPos = item.WorldPosition
        for key,client in pairs(Client.ClientList) do
            local char = client.Character
            if char ~= nil and char.IsHuman then
                local dist = HF.Distance(char.WorldPosition,itemPos)
                if dist < minDist then
                    minDist = dist
                    user=char
                end
            end
            
        end
    else 
        user=Character.Controlled
    end

    -- if i try to do this in a while loop on a server then lua dies
    -- not sure why, so heres a recursive timer variant instead

    local function recursiveUse(dontReportErrors)
        Timer.Wait(function()
            if NTCS_Pharmacy.TryCraftPills(item,user,dontReportErrors) then
                recursiveUse(true)
            else
                HF.GiveItem(user,"NTCS_Pharmacysfx_chemfinish")
                -- craftall finished, remove from craftalls
                for index, value in ipairs(NTCS_Pharmacy.ActiveChemCraftalls) do
                    if value == item then
                        NTCS_Pharmacy.ActiveChemCraftalls[index] = nil
                    end
                end
            end
        end, 250)
    end

    -- add to craftalls so fellas cant spam it
    NTCS_Pharmacy.ActiveChemCraftalls[#NTCS_Pharmacy.ActiveChemCraftalls+1] = item

    recursiveUse(false)
end)

NTCS_Pharmacy.DetachChemMasters = function()
    -- fetch items
    local chemmasters = {}
    for item in Item.ItemList do
        if item.Prefab.Identifier.Value == "chemmaster" then
            table.insert(chemmasters,item)
        end
    end
    local chemMasterCount = #chemmasters
    if chemMasterCount <= 0 then
        print("didn't find any chemmasters to reset")
        return
    end
    -- refresh chem masters
    for item in chemmasters do
        HF.SpawnItemAt("chemmaster",item.WorldPosition)
        HF.RemoveItem(item)
    end

    print("successfully reset "..tostring(chemMasterCount).." chemmasters")
end

Hook.Add("NTCS_Pharmacy.Chemalyzer.analyze", "NTCS_Pharmacy.Chemalyzer.analyze", function (effect, deltaTime, item, targets, worldPosition)
    
    local inv = item.OwnInventory
    if inv == nil then return end
    local containedItem = inv.GetItemAt(0)
    if containedItem==nil then return end

    local user = nil
    local userclient = nil

    if SERVER then
        -- sadly lua hooks dont tell us who pressed the button, so it'll just be the closest client for now
        local minDist = 9000
        local itemPos = item.WorldPosition
        for key,client in pairs(Client.ClientList) do
            local char = client.Character
            if char ~= nil and char.IsHuman then
                local dist = HF.Distance(char.WorldPosition,itemPos)
                if dist < minDist then
                    minDist = dist
                    user=char
                    userclient=client
                end
            end
            
        end
    else 
        user=Character.Controlled
    end

    if user == nil then return end

    -- construct readout
    local config = NTCS_Pharmacy.PillConfigFromPill(containedItem)
    local resstring = TextManager.Get("lua.chemalyzer.header").Value
    for key, value in pairs(config.ingredients) do
        if value > 1 then
            resstring = resstring.."\n   "..value.." * "..TextManager.Get("entityname."..key,false).Value
        else
            resstring = resstring.."\n   "..TextManager.Get("entityname."..key,false).Value
        end
    end

    HF.SendTextBox(TextManager.Get("entityname.chemalyzer").Value,resstring,userclient)
end)

Hook.Add("NTCS_Pharmacy.Chemalyzer.rename", "NTCS_Pharmacy.Chemalyzer.rename", function (effect, deltaTime, item, targets, worldPosition)
    
    local inv = item.OwnInventory
    if inv == nil then return end
    local containedItem = inv.GetItemAt(0)
    if containedItem==nil then return end
    if containedItem.Condition == 1 then return end

    containedItem.Condition = 1

    Timer.Wait(function()
        local newdescription = nil
        if item.OriginalOutpost ~= "" then
            newdescription=item.OriginalOutpost
        end
        local config = NTCS_Pharmacy.PillConfigFromPill(containedItem)
        config.description = HF.ReplaceString(newdescription,",","")
        NTCS_Pharmacy.SetPillFromConfig(containedItem,config)
        NTCS_Pharmacy.RefreshPillDescription(containedItem)
        containedItem.Condition = 100
    end,250)
end)

Hook.Add("NTCS_Pharmacy.Chemalyzer.automatic", "NTCS_Pharmacy.Chemalyzer.automatic", function (effect, deltaTime, item, targets, worldPosition)
    
    local inv = item.OwnInventory
    if inv == nil then return end
    local containedItem = inv.GetItemAt(0)
    if containedItem==nil then return end

    if containedItem.Condition == 1 then return end

    containedItem.Condition = 1

    local user = nil
    local userclient = nil

    if SERVER then
        -- copied checks
        local minDist = 9000
        local itemPos = item.WorldPosition
        for key,client in pairs(Client.ClientList) do
            local char = client.Character
            if char ~= nil and char.IsHuman then
                local dist = HF.Distance(char.WorldPosition,itemPos)
                if dist < minDist then
                    minDist = dist
                    user=char
                    userclient=client
                end
            end
            
        end
    else 
        user=Character.Controlled
    end

    if user == nil then return end

    -- construct automatic custom label
    local config = NTCS_Pharmacy.PillConfigFromPill(containedItem)
    local resstring = ""
    for key, value in pairs(config.ingredients) do
        if next(config.ingredients, key) ~= nil then
            if value > 1 then
                resstring = resstring..value.." * "..TextManager.Get("entityname."..key,false).Value.." | "
            else
                resstring = resstring..TextManager.Get("entityname."..key,false).Value.." | "
            end
        else 
            if value > 1 then
                resstring = resstring..value.." * "..TextManager.Get("entityname."..key,false).Value
            else
                resstring = resstring..TextManager.Get("entityname."..key,false).Value
            end
        end
    end
    Timer.Wait(function()
        config.description = resstring
        NTCS_Pharmacy.SetPillFromConfig(containedItem,config)
        NTCS_Pharmacy.RefreshPillDescription(containedItem)
        containedItem.Condition = 100
    end,250)
end)
