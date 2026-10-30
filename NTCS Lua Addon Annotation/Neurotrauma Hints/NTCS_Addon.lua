---@meta
---Namespace: Neurotrauma.NTAfflictions

---@public
---@class NTAddon
NTCS.Addon = {}

---@public
---@class NTInfo
NTCS.Info = {

    ---@public
    ---@static
    ---@param Addon NTAddon|table
    ---@return nil
    RegisterAddon = function(Addon) end,

    ---@public
    ---@static
    ---@param AddonName string
    ---@return boolean
    isAddonRegistered = function(AddonName) end,

}