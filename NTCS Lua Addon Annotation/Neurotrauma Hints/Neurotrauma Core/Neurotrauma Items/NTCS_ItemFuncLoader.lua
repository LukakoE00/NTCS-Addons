---@meta
---Namespace: Neurotrauma.NTItems.NTItemFunctionLoader

---@public
---@class NTItemFunctionLoader
NTCS.NTItems.NTItemFunctionLoader = {

    -- Create a new instance of the NTItemFunctionLoader class for a specific mod. This allows you to register update functions for items associated with that mod.
    ---@public
    ---@param ModID string
    ---@return NTItemFunctionLoader
    New = function(ModID) end,

    -- Register a new function associated with the given item ID. This function will be called when the item is used in the game.
    -- <example>
    -- 
    -- ```c#
    -- NTItemFunctionLoader loader = new NTItems.NTItemFunctionLoader("MyMod");
    -- 
    -- loader.Register("MyItemID", (infos) => {
    --     // Your item update logic here
    -- });
    -- ```
    -- 
    -- </example>
    -- </summary>
    -- <param name="ItemID">The ID of the item defined in the XML.</param>
    -- <param name="UpdateFunction">A function that runs when the item is used.</param>
    -- <returns>true if the function was registered successfully, false otherwise (the item already has a function assigned).</returns>
    ---@public
    ---@param ItemID string
    ---@param UpdateFunction Action<ItemUpdateFunctionInfos>|function
    ---@return boolean
    Register = function(ItemID,UpdateFunction) end,

    -- Overrides the update function for an existing item. If the item does not have a registered update function, it will register it instead.
    ---@public
    ---@param ItemID string
    ---@param UpdateFunction Action<ItemUpdateFunctionInfos>|function
    ---@param RegisterInstead boolean
    ---@return boolean
    Override = function(ItemID,UpdateFunction,RegisterInstead) end,

    -- Removes the update function associated with the given item ID.
    ---@public
    ---@param ItemID string
    ---@return boolean
    Remove = function(ItemID) end,

    -- Check if the given item ID has a corresponding function registered.
    ---@public
    ---@param ItemID string
    ---@return boolean
    Has = function(ItemID) end,

    -- Returns the function associated with the given item ID, or null if no function is registered for that item.
    ---@public
    ---@param ItemID string
    ---@return Action<ItemUpdateFunctionInfos>?
    Get = function(ItemID) end,

    ---@public
    ---@param ItemID string
    ---@param Infos ItemUpdateFunctionInfos
    ---@return nil
    Call = function(ItemID, Infos) end,

    -- Calls the old function associated with the given item ID and mod name after an override.
    -- 
    -- ```lua
    -- 
    -- local loader = NTCS.ItemFunctionLoader("MyMod")
    -- 
    -- loader:Override("MyItemID", function (infos) 
    --     -- do your things
    --     
    --     loader:CallOld("MyItemID", "OtherMod", infos) -- Call the old function defined by OtherMod
    -- end)
    -- ```
    ---@public
    ---@param ItemID string
    ---@param Infos ItemUpdateFunctionInfos
    ---@return nil
    CallOld = function(ItemID, Infos) end,

    -- Check if there is an old function associated with the given item ID and mod name after an override.
    ---@public
    ---@param ItemID string
    ---@param ModName string
    ---@return nil
    HasOld = function(ItemID, ModName) end,

}