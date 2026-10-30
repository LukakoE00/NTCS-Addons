---@meta
---Namespace: Neurotrauma.NTAfflictions

---@public
---@class NTAfflictionPrefabBuilder
NTCS.Afflictions.NTAfflictionPrefabBuilder = {


    ---@public
    ---@param Const boolean
    ---@return NTAfflictionPrefabBuilder
    IsConst = function(self, Const) end,


    ---@public
    ---@param Real boolean
    ---@return NTAfflictionPrefabBuilder
    IsReal = function(self, Real) end,


    ---@public
    ---@param LimbSpecific boolean
    ---@return NTAfflictionPrefabBuilder
    IsLimbSpecific = function(self, LimbSpecific) end,


    ---@public
    ---@param Symptom boolean
    ---@return NTAfflictionPrefabBuilder
    IsSymptom = function(self, Symptom) end,


    ---@public
    ---@param Delay number
    ---@return NTAfflictionPrefabBuilder
    SetDelay = function(self, Delay) end,


    ---@public
    ---@param MinStrength number
    ---@param MaxStrength number
    ---@param DefaultStrength number
    ---@return NTAfflictionPrefabBuilder
    SetStrengths = function(self, MinStrength, MaxStrength, DefaultStrength) end,


    ---@public
    ---@param Priority number
    ---@return NTAfflictionPrefabBuilder
    SetPriority = function(self, Priority) end,


    ---@deprecated
    ---@public
    ---@param IgnoreStasis boolean
    ---@return NTAfflictionPrefabBuilder
    SetIgnoreStasis = function(self, IgnoreStasis) end,


    ---@public
    ---@overload fun(self, UpdateAction: Action) : NTAfflictionPrefabBuilder
    ---@param UpdateAction function
    ---@return NTAfflictionPrefabBuilder
    SetUpdateAction = function(self, UpdateAction) end,


    ---@public
    ---@return NTAfflictionPrefab
    Build = function(self) end,

    ---@public
    ---@param ID string
    ---@return NTAfflictionPrefabBuilder
    New = function(self, ID) end,
    
}

--- Constructs a new NTAfflictionPrefabBuilder to be used in a human update.
---@public
---@param ID string
---@return NTAfflictionPrefabBuilder
NTCS.AfflictionPrefabBuilder = function(ID) end