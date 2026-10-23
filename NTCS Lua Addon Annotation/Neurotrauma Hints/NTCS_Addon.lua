---@meta
---Namespace: Neurotrauma.NTAfflictions

---@public
---@class NTAddon
NTCS.NTAddon = {}

---@public
---@class NTInfo
NTCS.NTInfo = {

    ---@public
    ---@static
    ---@overload fun(Addon : table) : nil
    ---@param Addon NTAddon
    ---@return nil
    RegisterAddon = function(Addon) end,

    ---@public
    ---@static
    ---@param AddonName string
    ---@return boolean
    isAddonRegistered = function(AddonName) end,

}