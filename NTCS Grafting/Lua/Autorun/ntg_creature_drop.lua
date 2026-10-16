---@diagnostic disable: undefined-global

if not SERVER then return end

local preparedProfiles = {}
local ignoredCharacterIds = {}
local processedCharacters = {}
local profilesPrepared = false

local profiles = {
    crawler = {
        normal = {
            name = "Crawler Normal",
            drops = {
                { identifier = "crawlerTailAegis", chance = 0.119403 },
                { identifier = "crawlerLungsAegis", chance = 0.119403 },
            },
        },
        husk = {
            name = "Crawler Husk",
            drops = {
                { identifier = "crawlerTailAegis", chance = 0.107463 },
                { identifier = "crawlerLungsAegis", chance = 0.107463 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    mudraptor = {
        normal = {
            name = "Mudraptor Normal",
            drops = {
                { identifier = "mudraptorCellsAegis", chance = 0.37037 },
                { identifier = "mudraptorLungsAegis", chance = 0.185185 },
            },
        },
        husk = {
            name = "Mudraptor Husk",
            drops = {
                { identifier = "mudraptorCellsAegis", chance = 0.333333 },
                { identifier = "mudraptorLungsAegis", chance = 0.166667 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    crawlerbroodmother = {
        normal = {
            name = "Crawler Broodmother Normal",
            drops = {
                { identifier = "broodmotherCellsAegis", chance = 0.545455 },
                { identifier = "broodmotherLiverAegis", chance = 0.181818 },
            },
        },
        husk = {
            name = "Crawler Broodmother Husk",
            drops = {
                { identifier = "broodmotherCellsAegis", chance = 0.490909 },
                { identifier = "broodmotherLiverAegis", chance = 0.163636 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    hammerhead = {
        normal = {
            name = "Hammerhead Normal",
            drops = {
                { identifier = "hammerheadCellsAegis", chance = 0.222222 },
                { identifier = "hammerheadLimbsAegis", chance = 0.222222 },
            },
        },
        husk = {
            name = "Hammerhead Husk",
            drops = {
                { identifier = "hammerheadCellsAegis", chance = 0.2 },
                { identifier = "hammerheadLimbsAegis", chance = 0.2 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    moloch = {
        normal = {
            name = "Moloch Normal",
            drops = {
                { identifier = "molochCellsAegis", chance = 0.727273 },
            },
        },
        husk = {
            name = "Moloch Husk",
            drops = {
                { identifier = "molochCellsAegis", chance = 0.654545 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    charybdis = {
        normal = {
            name = "Charybdis Normal",
            drops = {
                { identifier = "charybdisCellsAegis", chance = 0.8 },
            },
        },
        husk = {
            name = "Charybdis Husk",
            drops = {
                { identifier = "charybdisCellsAegis", chance = 0.72 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    fractalguardian = {
        normal = {
            name = "Fractal Guardian Normal",
            drops = {
                { identifier = "fractalGuardianEyeAegis", chance = 0.625 },
            },
        },
        husk = {
            name = "Fractal Guardian Husk",
            drops = {
                { identifier = "fractalGuardianEyeAegis", chance = 0.5625 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    endworm = {
        normal = {
            name = "Endworm Normal",
            drops = {
                { identifier = "endwormCellsAegis", chance = 0.952381 },
            },
        },
        husk = {
            name = "Endworm Husk",
            drops = {
                { identifier = "endwormCellsAegis", chance = 0.857143 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    latcher = {
        normal = {
            name = "Latcher Normal",
            drops = {
                { identifier = "latcherCellsAegis", chance = 0.333333 },
                { identifier = "latcherTongueAegis", chance = 0.333333 },
            },
        },
        husk = {
            name = "Latcher Husk",
            drops = {
                { identifier = "latcherCellsAegis", chance = 0.3 },
                { identifier = "latcherTongueAegis", chance = 0.3 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    watcher = {
        normal = {
            name = "Watcher Normal",
            drops = {
                { identifier = "watcherEyeAegis", chance = 0.8 },
            },
        },
        husk = {
            name = "Watcher Husk",
            drops = {
                { identifier = "watcherEyeAegis", chance = 0.72 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    bonethresher = {
        normal = {
            name = "Bonethresher Normal",
            drops = {
                { identifier = "boneThresherCellsAegis", chance = 0.166667 },
            },
        },
        husk = {
            name = "Bonethresher Husk",
            drops = {
                { identifier = "boneThresherCellsAegis", chance = 0.15 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    tigerthresher = {
        normal = {
            name = "Tiger Thresher Normal",
            drops = {
                { identifier = "tigerThresherTailAegis", chance = 0.151515 },
                { identifier = "tigerThresherCellsAegis", chance = 0.242424 },
            },
        },
        husk = {
            name = "Tiger Thresher Husk",
            drops = {
                { identifier = "tigerThresherTailAegis", chance = 0.160714 },
                { identifier = "tigerThresherCellsAegis", chance = 0.257143 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    mantis = {
        normal = {
            name = "Mantis Normal",
            drops = {
                { identifier = "mantisCellsAegis", chance = 0.8 },
                { identifier = "mantisLiverAegis", chance = 0.2 },
            },
        },
        husk = {
            name = "Mantis Husk",
            drops = {
                { identifier = "mantisCellsAegis", chance = 0.72 },
                { identifier = "mantisLiverAegis", chance = 0.18 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    orangeboy = {
        normal = {
            name = "Orangeboy Normal",
            drops = {
                { identifier = "orangeboyTailAegis", chance = 0.18 },
            },
        },
        husk = {
            name = "Orangeboy Husk",
            drops = {
                { identifier = "orangeboyTailAegis", chance = 0.162 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    prowler = {
        husk = {
            name = "Prowler Husk",
            drops = {
                { identifier = "huskCellsAegis", chance = 0.157895 },
                { identifier = "huskHeartAegis", chance = 0.052632 },
            },
        },
    },
    viperling = {
        normal = {
            name = "Viperling Normal",
            drops = {
                { identifier = "viperlingCellsAegis", chance = 0.6 },
                { identifier = "viperlingLiverAegis", chance = 0.1 },
            },
        },
        husk = {
            name = "Viperling Husk",
            drops = {
                { identifier = "viperlingCellsAegis", chance = 0.54 },
                { identifier = "viperlingLiverAegis", chance = 0.09 },
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    husk = {
        husk = {
            name = "Husk",
            drops = {
                { identifier = "huskCellsAegis", chance = 0.181818 },
            },
        },
    },
    husk_fallback = {
        husk = {
            name = "Husk Fallback",
            drops = {
                { identifier = "huskCellsAegis", chance = 0.1 },
            },
        },
    },
    husk_chimera = {
        husk = {
            name = "Husk Chimera",
            drops = {
                { identifier = "huskArmAegis", chance = 0.25 },
                { identifier = "huskCellsAegis", chance = 0.375 },
                { identifier = "huskHeartAegis", chance = 0.125 },
            },
        },
    },
}

local graftIdentifiers = {
    huskCellsAegis = true,
    crawlerTailAegis = true,
    crawlerLungsAegis = true,
    broodmotherCellsAegis = true,
    broodmotherLiverAegis = true,
    mudraptorCellsAegis = true,
    mudraptorLungsAegis = true,
    hammerheadCellsAegis = true,
    hammerheadLimbsAegis = true,
    molochCellsAegis = true,
    charybdisCellsAegis = true,
    endwormCellsAegis = true,
    latcherCellsAegis = true,
    latcherTongueAegis = true,
    watcherEyeAegis = true,
    fractalGuardianEyeAegis = true,
    boneThresherCellsAegis = true,
    tigerThresherTailAegis = true,
    tigerThresherCellsAegis = true,
    mantisCellsAegis = true,
    mantisLiverAegis = true,
    orangeboyTailAegis = true,
    huskArmAegis = true,
    huskHeartAegis = true,
    viperlingCellsAegis = true,
    viperlingLiverAegis = true,
}

local function GetIdentifierValue(identifier)
    if identifier == nil then return nil end
    if identifier.Value ~= nil then return tostring(identifier.Value) end
    return tostring(identifier)
end

local function GetCharacterIdentifier(character)
    if character == nil then return nil end
    if character.Prefab ~= nil and character.Prefab.Identifier ~= nil then
        return GetIdentifierValue(character.Prefab.Identifier)
    end
    return GetIdentifierValue(character.SpeciesName)
end

local function IsExcludedIdentifier(identifier)
    local value = string.lower(identifier or "")
    local exclusions = {
        "hatchling",
        "spawn",
        "baby",
        "young",
        "juvenile",
        "cocoon",
        "legacy",
        "humanhusk",
        -- huskcontainer
        "container",
        -- Fractal repairbot (Barotraumatic)
        "repairbot",
        -- Husk Chimera Broodmother spawns (Barotraumatic)
        "randomtiny",
        "randomlight",
        "randomheavy",
        -- Baby Charybdis
        "charybdisre"
    }
    for _, exclusion in ipairs(exclusions) do
        if string.find(value, exclusion, 1, true) ~= nil then
            return true
        end
    end
    return false
end

local function GetBaseProfile(identifier)
    local value = string.lower(identifier or "")
    if IsExcludedIdentifier(value) then return nil end

    local isHusk = string.find(value, "husk", 1, true) ~= nil

    if value == "husk" then
        return profiles.husk, isHusk
    end
    if string.find(value, "husk_chimera", 1, true) ~= nil
        or string.find(value, "huskchimera", 1, true) ~= nil then
        return profiles.husk_chimera, isHusk
    end
    if string.find(value, "husk_prowler", 1, true) ~= nil then
        return profiles.prowler, isHusk
    end
    if string.find(value, "viperling", 1, true) ~= nil
        or string.find(value, "spineling_morbusine", 1, true) ~= nil then
        return profiles.viperling, isHusk
    end
    if string.find(value, "crawlerbroodmother", 1, true) ~= nil then
        return profiles.crawlerbroodmother, isHusk
    end
    if string.find(value, "crawler", 1, true) ~= nil then
        return profiles.crawler, isHusk
    end
    if string.find(value, "mudraptor", 1, true) ~= nil then
        return profiles.mudraptor, isHusk
    end
    if string.find(value, "hammerhead", 1, true) ~= nil then
        return profiles.hammerhead, isHusk
    end
    if string.find(value, "moloch", 1, true) ~= nil then
        return profiles.moloch, isHusk
    end
    if string.find(value, "charybdis", 1, true) ~= nil then
        return profiles.charybdis, isHusk
    end
    if string.find(value, "endworm", 1, true) ~= nil then
        return profiles.endworm, isHusk
    end
    if string.find(value, "latcher", 1, true) ~= nil then
        return profiles.latcher, isHusk
    end
    if string.find(value, "watcher", 1, true) ~= nil then
        return profiles.watcher, isHusk
    end
    if string.find(value, "fractalguardian", 1, true) ~= nil then
        return profiles.fractalguardian, isHusk
    end
    if string.find(value, "bonethresher", 1, true) ~= nil then
        return profiles.bonethresher, isHusk
    end
    if string.find(value, "tigerthresher", 1, true) ~= nil then
        return profiles.tigerthresher, isHusk
    end
    if string.find(value, "mantis", 1, true) ~= nil then
        return profiles.mantis, isHusk
    end
    if string.find(value, "orangeboy", 1, true) ~= nil then
        return profiles.orangeboy, isHusk
    end
    if isHusk then
        return profiles.husk_fallback, isHusk
    end
    return nil
end

local function GetChildElements(element, name)
    if element == nil then return {} end
    local result = {}
    local seen = {}
    local titleName = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
    for _, requestedName in ipairs({name, titleName, string.lower(name), string.upper(name)}) do
        local ok, children = pcall(function()
            return element:GetChildElements(requestedName)
        end)
        if ok and children ~= nil then
            for child in children do
                if not seen[child] then
                    seen[child] = true
                    table.insert(result, child)
                end
            end
        end
    end
    return result
end

local function GetAttributeString(element, name)
    local ok, value = pcall(function()
        return element:GetAttributeString(name, "")
    end)
    if ok and value ~= nil then return tostring(value) end
    return ""
end

local function HasStaticGraftDrops(prefab)
    local ok, configElement = pcall(function()
        return prefab.ConfigElement
    end)
    if not ok or configElement == nil then return nil end

    for _, inventory in ipairs(GetChildElements(configElement, "inventory")) do
        for _, item in ipairs(GetChildElements(inventory, "item")) do
            local identifier = GetAttributeString(item, "identifier")
            if graftIdentifiers[identifier] then
                return true
            end
        end
    end
    return false
end

local function PrepareProfiles()
    local nextPreparedProfiles = {}
    local nextIgnoredCharacterIds = {}

    local ok, prefabs = pcall(function()
        return CharacterPrefab.Prefabs
    end)
    if not ok or prefabs == nil then
        print("[NTG Creature Drop Lua] Could not enumerate CharacterPrefab.Prefabs")
        return false
    end

    local preparedCount = 0
    local ignoredCount = 0
    local scannedPrefabCount = 0
    local inspectionFailed = false
    for prefab in prefabs do
        if prefab ~= nil then
            scannedPrefabCount = scannedPrefabCount + 1
        end
        if prefab ~= nil and prefab.Identifier ~= nil then
            local identifier = GetIdentifierValue(prefab.Identifier)
            local baseProfile, isHusk = GetBaseProfile(identifier)
            if identifier ~= nil and baseProfile ~= nil then
                local hasStaticDrops = HasStaticGraftDrops(prefab)
                if hasStaticDrops == true then
                    nextIgnoredCharacterIds[identifier] = true
                    ignoredCount = ignoredCount + 1
                elseif hasStaticDrops == false then
                    local selectedProfile = nil
                    if isHusk then
                        selectedProfile = baseProfile.husk
                    else
                        selectedProfile = baseProfile.normal
                    end
                    if selectedProfile ~= nil then
                        nextPreparedProfiles[identifier] = selectedProfile
                        preparedCount = preparedCount + 1
                        print("[NTG Creature Drop Lua] Prepared " .. identifier .. " with profile " .. tostring(selectedProfile.name))
                    end
                else
                    inspectionFailed = true
                    print("[NTG Creature Drop Lua] Could not inspect the winning XML for " .. identifier)
                end
            end
        end
    end

    if scannedPrefabCount == 0 or inspectionFailed then
        print("[NTG Creature Drop Lua] Profile preparation incomplete; will retry")
        return false
    end

    preparedProfiles = nextPreparedProfiles
    ignoredCharacterIds = nextIgnoredCharacterIds
    print(string.format(
        "[NTG Creature Drop Lua] Prepared %d profiles; ignored %d IDs with static graft drops",
        preparedCount,
        ignoredCount
    ))
    return true
end

local function SelectDrop(drops)
    local roll = math.random()
    local cumulativeChance = 0
    for _, drop in ipairs(drops) do
        cumulativeChance = cumulativeChance + drop.chance
        if roll < cumulativeChance then
            return drop
        end
    end
    return nil
end

local function HasExistingGraft(character)
    if character == nil or character.Inventory == nil or character.Inventory.AllItems == nil then
        return false
    end
    for item in character.Inventory.AllItems do
        if item ~= nil and item.Prefab ~= nil and item.Prefab.Identifier ~= nil then
            if graftIdentifiers[GetIdentifierValue(item.Prefab.Identifier)] then
                return true
            end
        end
    end
    return false
end

local function SpawnGraft(character, identifier)
    if identifier == nil or character.Inventory == nil then return end

    local prefab = ItemPrefab.GetItemPrefab(identifier)
    if prefab == nil then
        print("[NTG Creature Drop Lua] Missing item prefab: " .. identifier)
        return
    end

    Entity.Spawner.AddItemToSpawnQueue(prefab, character.Inventory, nil, nil, function(item)
        print("[NTG Creature Drop Lua] Added " .. identifier .. " to " .. GetCharacterIdentifier(character))
    end, true)
end

local function ProcessCharacterDeath(character)
    if character == nil or character.Removed or processedCharacters[character] then return end

    local characterIdentifier = GetCharacterIdentifier(character)
    local profile = preparedProfiles[characterIdentifier]
    if profile == nil or ignoredCharacterIds[characterIdentifier] or HasExistingGraft(character) then
        return
    end

    processedCharacters[character] = true
    local drop = SelectDrop(profile.drops)
    if drop == nil then
        print("[NTG Creature Drop Lua] " .. characterIdentifier .. " using profile " .. tostring(profile.name) .. " selected no graft")
        return
    end

    print("[NTG Creature Drop Lua] " .. characterIdentifier .. " using profile " .. tostring(profile.name) .. " selected death drop " .. drop.identifier)
    SpawnGraft(character, drop.identifier)
end

profilesPrepared = PrepareProfiles()

Hook.Add("roundStart", "NTG.CreatureDropLua.RoundStart", function()
    processedCharacters = {}
    if not profilesPrepared then
        profilesPrepared = PrepareProfiles()
    end
end)

Hook.Add("characterDeath", "NTG.CreatureDropLua.CharacterDeath", function(character)
    Timer.Wait(function()
        ProcessCharacterDeath(character)
    end, 0)
end)

Hook.Add("roundEnd", "NTG.CreatureDropLua.RoundEnd", function()
    processedCharacters = {}
end)

if not profilesPrepared and Game.RoundStarted then
    Timer.Wait(function()
        if not profilesPrepared then
            profilesPrepared = PrepareProfiles()
        end
    end, 0)
end
