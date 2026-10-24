---@meta
---Namespace: Neurotrauma.NTHuman

---@public
---@class NTHuman
NTCS.NTHuman = {

    ---@public
    ---@type Dictionary<Character,NTHuman>
    NTHumans = {},

    ---@public
    ---@type Dictionary<string,boolean>
    BoolStats = {},

    ---@public
    ---@type Dictionary<string,boolean>
    FloatStats = {},

    ---@public
    ---@type Dictionary<string,integer>
    AffDelay = {},

    ---@public
    ---@type NTSymptomsStorage
    Symptoms = {},

    ---@public
    ---@type Character
    Human = nil,

    ---@public
    ---@type CharacterTags
    Tags = {},

    ---@public
    ---@param Human Character
    ---@return NTHuman
    New = function(self, Human) end,

    ---@public
    ---@static
    ---@param Human Character
    ---@return NTHuman
    getNtHumanFromCharacter = function(Human) end,

    ---@public
    ---@static
    ---@param Human NTHuman
    ---@return NTHuman
    RemoveNTHuman = function(Human) end,

    ---@public
    ---@param DeltaTime number
    ---@return nil
    UpdateStats = function(self, DeltaTime) end,

    ---@public
    ---@param StatID string
    ---@return boolean
    GetBoolStat = function(self, StatID) end,

    ---@public
    ---@param StatID string
    ---@return number
    GetFloatStat = function(self, StatID) end,

    ---@public
    ---@param StatID string
    ---@param Value boolean
    ---@return nil
    SetBoolStat = function(self, StatID, Value) end,

    ---@public
    ---@param StatID string
    ---@param Value number
    ---@return nil
    SetFloatStat = function(self, StatID, Value) end,

    ---@public
    ---@param AfflictionID string
    ---@return Affliction
    GetAffliction = function(self, AfflictionID) end,

    ---@public
    ---@param AfflictionID string
    ---@param Limb LimbType
    ---@return Affliction
    GetAfflictionLimb = function(self, AfflictionID, Limb) end,

    ---@public
    ---@param AfflictionID string
    ---@param DefaultValue number?
    ---@return number
    GetAfflictionStrength = function(self, AfflictionID, DefaultValue) end,

    ---@public
    ---@param AfflictionID string
    ---@param Limb LimbType
    ---@param DefaultValue number?
    ---@return number
    GetAfflictionStrengthLimb = function(self, AfflictionID, Limb, DefaultValue) end,

    ---@public
    ---@param AfflictionID string
    ---@param Strength number
    ---@param Aggressor Character|NTHuman|nil
    ---@return nil
    AddAffliction = function(self, AfflictionID, Strength, Aggressor) end,

    ---@public
    ---@param AfflictionID string
    ---@param Limb LimbType
    ---@param Strength number
    ---@param Aggressor Character|NTHuman|nil
    ---@return nil
    AddAfflictionLimb = function(self, AfflictionID, Limb, Strength, Aggressor) end,

    ---@public
    ---@param AfflictionID string
    ---@param Strength number
    ---@param Aggressor Character|NTHuman|nil
    ---@return nil
    AddAfflictionResisted = function(self, AfflictionID, Strength, Aggressor) end,

    ---@public
    ---@param AfflictionID string
    ---@param Strength number
    ---@param Aggressor Character|NTHuman|nil
    ---@return nil
    SetAffliction = function(self, AfflictionID, Strength, Aggressor) end,

    ---@public
    ---@param AfflictionID string
    ---@param Limb LimbType
    ---@param Strength number
    ---@param Aggressor Character|NTHuman|nil
    ---@return nil
    SetAfflictionLimb = function(self, AfflictionID, Limb, Strength, Aggressor) end,

    ---@public
    ---@param AfflictionID string
    ---@param MinStrength number?
    ---@return boolean
    HasAffliction = function(self, AfflictionID, MinStrength) end,

    ---@public
    ---@param AfflictionID string
    ---@param Limb LimbType
    ---@param MinStrength number?
    ---@return boolean
    HasAfflictionLimb = function(self, AfflictionID, Limb, MinStrength) end,

    ---@public
    ---@param AfflictionID string
    ---@param Limb LimbType
    ---@param MinStrength number?
    ---@return boolean
    HasAfflictionExtremity = function(self, AfflictionID, Limb, MinStrength) end,

    ---@private
    ---@param DeltaTime number
    ---@return nil
    PreHook = function(self, DeltaTime) end,

    ---@public
    ---@param Priortities List<AfflictionPriority>
    ---@return List<KeyValuePair<string,LimbType>>
    FetchAfflictions = function(self, Priortities) end,

    ---@public
    ---@param AfflictionList List<KeyValuePair<string,LimbType>>
    ---@param DeltaTime number
    ---@return nil
    UpdateAfflictions = function(self, AfflictionList, DeltaTime) end,

    ---@private
    ---@param DeltaTime number
    ---@return nil
    PostHook = function(self, DeltaTime) end,

    ---@public
    ---@param AfflictionID string|NTAfflictionPrefab
    ---@param Duration integer
    ---@param Limb LimbType?
    ---@return nil
    SetSymptomTrue = function(self, AfflictionID, Duration, Limb) end,

    ---@public
    ---@param AfflictionID string|NTAfflictionPrefab
    ---@param Limb LimbType?
    ---@return nil
    SetSymptomFalse = function(self, AfflictionID, Limb) end,

    ---@public
    ---@param AfflictionID string|NTAfflictionPrefab
    ---@param Limb LimbType?
    ---@return nil
    HasSymptom = function(self, AfflictionID, Limb) end,
    
    ---@public
    ---@return nil
    UpdateSymptoms = function() end,

    ---@private
    ---@class NTSymptomsStorage
    NTSymptomsStorage = {}

}