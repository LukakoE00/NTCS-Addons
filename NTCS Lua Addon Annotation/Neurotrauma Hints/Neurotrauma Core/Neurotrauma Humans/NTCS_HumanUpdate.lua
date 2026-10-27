---@meta
---Namespace: Neurotrauma.HumanUpdate

---@public
---@class HumanUpdate
NTCS.HumanUpdate = {

    ---@public
    ---@param Priority AfflictionPriority
    ---@return integer
    GetUpdateInterval = function(Priority) end,

    -- Not intended for external use, leave alone unless you know what your doing.
    ---@private
    ---@return nil
    ThinkUpdate = function() end,

    -- Not intended for external use, leave alone unless you know what your doing.
    ---@private
    ---@param Priorities List<AfflictionPriority>
    ---@param Character Character
    ---@param Delay number
    ---@return nil
    UpdateHuman = function(Priorities, Character, Delay) end,

    -- Not intended for external use, leave alone unless you know what your doing.
    ---@private
    ---@param Monster Character
    ---@param Delay number
    ---@return nil
    UpdateMonster = function(Priorities, Monster, Delay) end,

}