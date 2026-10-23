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
---@class NTAfflictionsLoader
NTCS.Afflictions.NTAfflictionsLoader = {


    ---@public
    ---@type string
    ModID = "",


    ---@public
    ---@param Affliction NTAfflictionPrefab
    ---@return boolean
    Register = function(Affliction) end,


    ---@public
    ---@param Afflictions List<NTAfflictionPrefab>
    ---@return boolean
    Registers = function(Afflictions) end,


    ---@public
    ---@param Affliction NTAfflictionPrefab
    ---@param RegisterInstead boolean
    ---@return boolean
    Override = function(Affliction, RegisterInstead) end,


    ---@public
    ---@param AfflictionID string
    ---@return boolean
    Remove = function(AfflictionID) end,


    ---@public
    ---@param AfflictionID string
    ---@return boolean
    Exists = function(AfflictionID) end,


    ---@public
    ---@param AfflictionID string
    ---@return NTAfflictionPrefab | nil
    Get = function(AfflictionID) end,


    ---@public
    ---@param ModName string
    ---@param AfflictionID string
    ---@param C string
    ---@param ID string
    ---@param Limb string
    ---@param DeltaTime string
    ---@return nil
    CallOldUpdate = function(ModName,AfflictionID,C,ID,Limb,DeltaTime) end,


    ---@public
    ---@param AfflictionID string
    ---@param UpdateFunction function
    ---@param ExtensionName string
    ---@return nil
    PreExtend = function(AfflictionID,UpdateFunction,ExtensionName) end,


    ---@public
    ---@param AfflictionID string
    ---@param UpdateFunction function
    ---@param ExtensionName string
    ---@return nil
    Extend = function(AfflictionID,UpdateFunction,ExtensionName) end,

}

--- Constructs a new NTAfflictionsLoader to be used in a human update.
---@public
---@param ID string
---@return NTAfflictionsLoader
NTCS.AfflictionsLoader = function(ID) end

---@public
---@class NTAfflictionPrefabBuilder
NTCS.Afflictions.NTAfflictionPrefabBuilder = {


    ---@public
    ---@param Const boolean
    ---@return NTAfflictionPrefabBuilder
    IsConst = function(Const) end,


    ---@public
    ---@param Real boolean
    ---@return NTAfflictionPrefabBuilder
    IsReal = function(Real) end,


    ---@public
    ---@param LimbSpecific boolean
    ---@return NTAfflictionPrefabBuilder
    IsLimbSpecific = function(LimbSpecific) end,


    ---@public
    ---@param Symptom boolean
    ---@return NTAfflictionPrefabBuilder
    IsSymptom = function(Symptom) end,


    ---@public
    ---@param Delay number
    ---@return NTAfflictionPrefabBuilder
    SetDelay = function(Delay) end,


    ---@public
    ---@param MinStrength number
    ---@param MaxStrength number
    ---@param DefaultStrength number
    ---@return NTAfflictionPrefabBuilder
    SetStrengths = function(MinStrength, MaxStrength, DefaultStrength) end,


    ---@public
    ---@param Priority number
    ---@return AfflictionPriority
    SetPriority = function(Priority) end,


    ---@deprecated
    ---@public
    ---@param IgnoreStasis boolean
    ---@return AfflictionPriority
    SetIgnoreStasis = function(IgnoreStasis) end,


    ---@public
    ---@overload fun(UpdateAction: Action) : AfflictionPriority
    ---@param UpdateAction function
    ---@return AfflictionPriority
    SetUpdateAction = function(UpdateAction) end,


    ---@public
    ---@return AfflictionPriority
    Build = function() end,
    
}

--- Constructs a new NTAfflictionPrefabBuilder to be used in a human update.
---@public
---@param ID string
---@return NTAfflictionPrefabBuilder
NTCS.AfflictionPrefabBuilder = function(ID) end

---@public
---@class NTAfflictionPrefab
NTCS.Afflictions.NTAfflictionPrefab = {


    ---@public
    ---@type boolean
    Const = false,


    ---@public
    ---@type boolean
    Real = true,


    ---@public
    ---@type boolean
    LimbSpecific = false,


    ---@public
    ---@type boolean
    Symptom = false,


    ---@public
    ---@type integer
    Delay = 0,


    ---@public
    ---@type number
    MinStrength = 0,


    ---@public
    ---@type number
    MaxStrength = 100,


    ---@public
    ---@type number
    DefaultStrength = 0,


    ---@public
    ---@type AfflictionPriority
    Priority = NTCS.AfflictionPriority.HIGH,


    ---@deprecated
    ---@public
    ---@type boolean
    IgnoreStasis = false,
    

    ---@public
    ---@type string
    ID = "",


    ---@public
    ---@type Action
    UpdateAction = function ()end,


    ---@public
    ---@param C NTHuman
    ---@param ID string
    ---@param Limb LimbType
    ---@param DeltaTime number
    ---@return nil
    Update = function(C, ID, Limb, DeltaTime) end,


    ---@public
    ---@return NTAfflictionPrefab
    Clone = function() end,

}
