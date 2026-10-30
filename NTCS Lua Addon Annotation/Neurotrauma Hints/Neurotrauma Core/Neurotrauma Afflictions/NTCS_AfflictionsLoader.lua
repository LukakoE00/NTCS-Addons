---@meta
---Namespace: Neurotrauma.NTAfflictions

---@public
---@class NTAfflictionsLoader
NTCS.Afflictions.NTAfflictionsLoader = {


    ---@public
    ---@type string
    ModID = "",


    ---@public
    ---@param Affliction NTAfflictionPrefab
    ---@return boolean
    Register = function(self, Affliction) end,


    ---@public
    ---@param Afflictions List<NTAfflictionPrefab>
    ---@return boolean
    Registers = function(self, Afflictions) end,


    ---@public
    ---@param Affliction NTAfflictionPrefab
    ---@param RegisterInstead boolean
    ---@return boolean
    Override = function(self, Affliction, RegisterInstead) end,


    ---@public
    ---@param AfflictionID string
    ---@return boolean
    Remove = function(self, AfflictionID) end,


    ---@public
    ---@param AfflictionID string
    ---@return boolean
    Exists = function(self, AfflictionID) end,


    ---@public
    ---@param AfflictionID string
    ---@return NTAfflictionPrefab | nil
    Get = function(self, AfflictionID) end,


    ---@public
    ---@param ModName string
    ---@param AfflictionID string
    ---@param C string
    ---@param ID string
    ---@param Limb string
    ---@param DeltaTime string
    ---@return nil
    CallOldUpdate = function(self, ModName,AfflictionID,C,ID,Limb,DeltaTime) end,


    ---@public
    ---@param AfflictionID string
    ---@param UpdateFunction function
    ---@param ExtensionName string
    ---@return nil
    PreExtend = function(self, AfflictionID,UpdateFunction,ExtensionName) end,


    ---@public
    ---@param AfflictionID string
    ---@param UpdateFunction function
    ---@param ExtensionName string
    ---@return nil
    Extend = function(self, AfflictionID,UpdateFunction,ExtensionName) end,

}

--- Constructs a new NTAfflictionsLoader to be used in a human update.
---@public
---@param ID string
---@return NTAfflictionsLoader
NTCS.AfflictionsLoader = function(ID) end