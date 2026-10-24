---@meta
---Namespace: Neurotrauma.NTConfig

---@public
---@class NTInfo
NTCS.Config = {

    ---@public
    ---@static
    ---@param Expansion ConfigExpansion|table
    ---@return nil
    AddConfigOptions = function(Expansion) end,

    ---@public
    ---@static
    ---@param EntryName string
    ---@return boolean|number|unknown
    Get = function(EntryName) end,

}