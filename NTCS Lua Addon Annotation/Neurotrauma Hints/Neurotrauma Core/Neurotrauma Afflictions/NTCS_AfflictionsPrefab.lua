---@meta
---Namespace: Neurotrauma.NTAfflictions

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
    ---@type function
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
