-- Table with lootdrops, global so other mods can edit it.
-- Each entry is the lowercase identifier of the creature.
-- This is the commonness value originally present, just adjusted for a 0 to 1 chance value.
NTCS_Grafting.CreatureDrops = {
    crawler = {
        { item = "grafting_CrawlerTail", chance = 0.119403 },
        { item = "crawlerLungsAegis", chance = 0.119403 },
    },
    crawlerhusk = {
        { item = "grafting_CrawlerTail", chance = 0.107463 },
        { item = "crawlerLungsAegis", chance = 0.107463 },
        { item = "Cells_Husk", chance = 0.1 },
    },

    mudraptor = {
        { item = "Cells_Mudraptor", chance = 0.37037 },
        { item = "mudraptorLungsAegis", chance = 0.185185 },
    },

    crawlerbroodmother = {
        { item = "Cells_Broodmother", chance = 0.545455 },
        { item = "broodmotherLiverAegis", chance = 0.181818 },
    },

    hammerhead = {
        { item = "Cells_Hammerhead", chance = 0.222222 },
        { item = "hammerheadLimbsAegis", chance = 0.222222 },
    },

    moloch = {
        { item = "Cells_Moloch", chance = 0.727273 },
    },

    charybdis = {
        { item = "Cells_Charybdis", chance = 0.8 },
    },

    fractalguardian = {
        { item = "fractalGuardianEyeAegis", chance = 0.625 },
    },

    endworm = {
        { item = "Cells_Endworm", chance = 0.952381 },
    },

    latcher = {
        { item = "latcherCellsAegis", chance = 0.333333 },
        { item = "latcherTongueAegis", chance = 0.333333 },
    },

    watcher = {
        { item = "watcherEyeAegis", chance = 0.8 },
    },

    bonethresher = {
        { item = "Cells_BoneThresher", chance = 0.166667 },
    },

    tigerthresher = {
        { item = "tigerThresherTailAegis", chance = 0.151515 },
        { item = "Cells_TigerThresher", chance = 0.242424 },
    },

    mantis = {
        { item = "Cells_Mantis", chance = 0.8 },
        { item = "mantisLiverAegis", chance = 0.2 },
    },

    orangeboy = {
        { item = "orangeboyTailAegis", chance = 0.18 },
    },

    spineling_morbusine = {
        { item = "Cells_Viperling", chance = 0.6 },
        { item = "viperlingLiverAegis", chance = 0.1 },
    },

    husk = {
        { item = "Cells_Husk", chance = 0.181818 },
    },
    husk_chimera = {
        { item = "huskArmAegis", chance = 0.25 },
        { item = "Cells_Husk", chance = 0.375 },
        { item = "huskHeartAegis", chance = 0.125 },
    },
}

local function GetIdentifier(character)
    local prefab = character.Prefab
    if prefab == nil or prefab.Identifier == nil then return nil end
    local id = prefab.Identifier
    if id.Value ~= nil then id = id.Value end
    return string.lower(tostring(id))
end

Hook.Add("characterDeath", "CreatureDrops.OnDeath", function(character)
    if character == nil or character.Removed or character.Inventory == nil then return end

    local identifier = GetIdentifier(character)
    local drops = identifier and NTCS_Grafting.CreatureDrops[identifier]
    if drops == nil then return end

    local roll = math.random()
    local cumulative = 0

    for _, drop in ipairs(drops) do
        cumulative = cumulative + drop.chance
        if roll < cumulative then
            if ItemPrefab.GetItemPrefab(drop.item) ~= nil then
                NTCS.HF.GiveItem(character, drop.item, drop.condition or 100)
            end
            return
        end
    end
end)