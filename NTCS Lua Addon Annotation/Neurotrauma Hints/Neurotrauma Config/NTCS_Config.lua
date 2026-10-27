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
    ---@param DefaultValue unknown
    ---@return boolean|number|unknown|nil
    Get = function(EntryName, DefaultValue) end,

}