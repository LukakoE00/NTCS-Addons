---@meta
---Namespace: Neurotrauma.NTItems

---@public
---@class NTItems
NTCS.NTItems = {

    -- Stores which mod defined an item last. 
    -- Key is Item ID and Value is Mod Name.
    ---@public
    ---@type Dictionary<string,string>
    NTItemsModDefinerRegistry = {},

    -- When an Item action is overriden, the old Item action is stored here in case a mod needs to access the original action. 
    -- The Key is a tuple of (ModName, AfflictionID) and the Value is the old action.
    ---@public
    ---@type Dictionary<[string,string],ItemUpdateFunctionInfos>
    NTOldItemsRegistry = {},

    -- When an Item action is overriden, the replaced action is stored here so the overriding mod can call it with CallPrevious.
    -- The Key is a tuple of (OverridingModName, ItemID) and the Value is the replaced action.
    ---@public
    ---@type Dictionary<[string,string],ItemUpdateFunctionInfos>
    NTPreviousItemsRegistry  = {},

}