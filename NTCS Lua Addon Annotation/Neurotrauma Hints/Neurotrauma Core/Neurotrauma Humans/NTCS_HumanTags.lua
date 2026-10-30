---@meta
---Namespace: Neurotrauma.NTHuman

---@public
---@class CharacterTags
NTCS.NTHuman.CharacterTags = {

    ---@public
    ---@type Dictionary<string,number>
    Tags = {},

    ---@public
    ---@param Prefix string
    ---@param TagID string
    ---@param Amount number
    ---@return nil
    SetTag = function(self, Prefix, TagID, Amount) end,

    ---@public
    ---@param Prefix string
    ---@param Amount number
    ---@return nil
    SetTagsByPrefix = function(self, Prefix, Amount) end,

    ---@public
    ---@param TagID string
    ---@param Amount number
    ---@return nil
    SetTagsByID = function(self, TagID, Amount) end,

    ---@public
    ---@param Prefix string
    ---@param TagID string
    ---@return nil
    RemoveTag = function(self, Prefix, TagID) end,

    ---@public
    ---@param Prefix string
    ---@param TagID string
    ---@return boolean
    HasTag = function(self, Prefix, TagID) end,

    ---@public
    ---@param Prefix string
    ---@param TagID string
    ---@return number
    GetTag = function(self, Prefix, TagID) end,

}