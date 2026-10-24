---@meta
---Namespace: Neurotrauma.NTC

---@public
---@class NTC
NTCS.NTC = {

    ---@public
    ---@static
    ---@see NTC.DebugPrintAllAffStrengths
    ---@return nil
    ---@deprecated
    DebugPrintAllData = function() end,
    
    ---@public
    ---@static
    ---@return nil
    DebugPrintAllAffStrengths = function() end,

    ---@public
    ---@static
    ---@type List<Action<CharacterHealth, AttackResult, Limb>>
    OnDamagedHooks = {},

    ---@public
    ---@static
    ---@type List<Action<CharacterHealth, List<Affliction>, Limb>>
    ModifyingOnDamagedHooks = {},

    ---@public
    ---@static
    ---@param Hook Action|function
    ---@return nil
    AddOnDamagedHook = function(Hook) end,

    ---@public
    ---@static
    ---@param Hook Action
    ---@return nil
    AddModifyingOnDamagedHook = function(Hook) end,

    ---@public
    ---@static
    ---@type Dictionary<NTHuman, number>
    CharacterSpeedMultipliers = {},

    ---@public
    ---@static
    ---@param Character Character|NTHuman
    ---@param Multiplier number
    ---@return nil
    MultiplySpeed = function(Character, Multiplier) end,

    ---@public
    ---@static
    ---@param Character Character|NTHuman
    ---@param Multiplier number
    ---@return nil
    DivideSpeed = function(Character, Multiplier) end,

    ---@public
    ---@static
    ---@param Character Character|NTHuman
    ---@return number
    GetSpeed = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character|NTHuman
    ---@param Amount number
    ---@return nil
    SetSpeed = function(Character, Amount) end,

    ---@public
    ---@static
    ---@param Identifier string
    ---@return nil
    AddHematologyAffliction = function(Identifier) end,

    ---@public
    ---@static
    ---@param Identifier string
    ---@param SurgerySkillGain integer
    ---@param RequiredAfflictionID string
    ---@param Func Func<NTItems.ItemUpdateFunctionInfos, bool>|function|nil
    ---@return nil
    AddSuturableAffliction = function(Identifier, SurgerySkillGain, RequiredAfflictionID, Func) end,

    ---@public
    ---@static
    ---@param Identifier string
    ---@param SurgerySkillGain integer
    ---@param RequiredAfflictionID string
    ---@param Func Func<NTItems.ItemUpdateFunctionInfos, bool>|function|nil
    ---@return nil
    AddDrainageAffliction = function(Identifier, SurgerySkillGain, RequiredAfflictionID, Func) end,

    ---@public
    ---@static
    ---@param Identifier string
    ---@return nil
    AddAfflictionAffectingVitality = function(Identifier) end,

    ---@public
    ---@static
    ---@param Character Character|NTHuman|nil
    ---@param MultiplierIdentifier string
    ---@param Multiplier number
    ---@return number
    SetMultiplier = function(Character, MultiplierIdentifier, Multiplier) end,

    ---@public
    ---@static
    ---@param Character Character|NTHuman|nil
    ---@param MultiplierIdentifier string
    ---@return number
    GetMultiplier = function(Character, MultiplierIdentifier) end,

    ---@public
    ---@static
    ---@param Character Character|NTHuman|nil
    ---@param TagIdentifier string
    ---@return nil
    SetTag = function(Character, TagIdentifier) end,

    ---@public
    ---@static
    ---@param Character Character|NTHuman|nil
    ---@param TagIdentifier string
    ---@return boolean
    HasTag = function(Character, TagIdentifier) end,

    ---@public
    ---@static
    ---@param Character NTHuman
    ---@return nil
    TickCharacterTags = function(Character) end,

}