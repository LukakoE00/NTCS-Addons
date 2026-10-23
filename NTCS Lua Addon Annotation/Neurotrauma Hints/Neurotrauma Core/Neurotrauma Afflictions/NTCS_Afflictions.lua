---@meta
---Namespace: Neurotrauma.NTAfflictions

---@public
---@enum
---@class AfflictionPriority
NTCS.AfflictionPriority = {LOW = 1,MEDIUM = 2,HIGH = 3}

---@public
---@type Dictionary<string,NTAfflictionPrefab>
NTCS.Afflictions.NTAfflictionsPrefabRegistry = {}

---@public
---@type Dictionary<string,string>
NTCS.Afflictions.NTAfflictionsPrefabModDefinerRegistry = {}

---@public
---@type Dictionary<[string,string],NTAfflictionPrefab>
NTCS.Afflictions.NTOldAfflictionsPrefabRegistry = {}

---@public
---@type List<string>
NTCS.Afflictions.ConstantAfflicitonPrefabs  = {}

---@public
---@class NTSymptoms
NTCS.Afflictions.NTSymptoms = {

    ---@public
    ---@type integer
    Duration = 0,

    ---@public
    ---@type NTAfflictionPrefab
    Affliction = nil,

    ---@public
    ---@type LimbType
    Limb = LimbType.None,

    ---@public
    ---@param Affliction NTAfflictionPrefab
    ---@param Duration integer
    ---@param Limb LimbType
    ---@return NTAfflictionPrefabBuilder
    New = function(self, Affliction, Duration, Limb) end,

}