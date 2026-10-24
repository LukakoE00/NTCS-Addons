---@meta
---Namespace: Neurotrauma.HF

---@public
---@class HF
NTCS.HF = {

    ---@public
    ---@static
    ---@type List<LimbType>
    ArmsLegsToCheck = {},

    ---@public
    ---@static
    ---@type List<LimbType>
    LegsToCheck = {},

    ---@public
    ---@static
    ---@type List<LimbType>
    ArmsToCheck = {},

    ---@public
    ---@static
    ---@type List<LimbType>
    LimbsToCheck = {},

    ---@public
    ---@static
    ---@type Dictionary<LimbType,string>
    StringLimbsToCheck = {},

    ---@public
    ---@static
    ---@type Dictionary<LimbType,string>
    ShortHandLimbsToCheck = {},

    ---@public
    ---@static
    ---@type Dictionary<LimbType,number>
    DefaultLimbAffStrengths = {},

    ---@public
    ---@static
    ---@type Dictionary<LimbType,integer>
    DefaultLimbSymUpdateTime = {},

    ---@public
    ---@static
    ---@param Character Character
    ---@param Limb LimbType
    ---@return Limb
    GetCharacterLimb = function(Character, Limb) end,

    ---@public
    ---@static
    ---@param Limb LimbType
    ---@return Limb
    NormalizeLimbType = function(Limb) end,

    ---@public
    ---@static
    ---@param Limb LimbType
    ---@return string?
    LimbToString = function(Limb) end,

    ---@public
    ---@static
    ---@param Identifier string
    ---@return boolean
    IsValidIdentifier = function(Identifier) end,

    ---@public
    ---@static
    ---@param Identifier string
    ---@param Limb LimbType
    ---@return boolean?
    CreateLimbAfflictionID = function(Limb, Identifier) end,

    ---@public
    ---@static
    ---@param Limb LimbType
    ---@return boolean
    LimbIsExtremity = function(Limb) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param ArmToLock string
    ---@return nil
    ForceArmLock = function(Character, ArmToLock) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param Identifier string
    ---@param Limb LimbType?
    ---@return number
    GetResistance = function(Character, Identifier, Limb) end,

    ---@public
    ---@static
    ---@param Item Barotrauma.Item
    ---@param ResistanceID string
    ---@return number
    GetItemAfflictionResistance = function(Item, ResistanceID) end,

    ---@public
    ---@static
    ---@param Item Barotrauma.Item
    ---@return number
    FindDepth = function(Item) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param Slot integer
    ---@return Barotrauma.Item
    GetCharacterInventorySlot = function(Character, Slot) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return Barotrauma.Item
    GetItemInRightHand = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return Barotrauma.Item
    GetItemInLeftHand = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return Barotrauma.Item
    GetItemInOuterWear = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return Barotrauma.Item
    GetItemInInnerWear = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return Barotrauma.Item
    GetItemInHeadWear = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return Barotrauma.Item
    GetItemInHeadSet = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param Slot integer
    ---@return string
    GetCharacterInventorySlotIdentifier = function(Character,Slot) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return string
    GetOuterWearIdentifier = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return string
    GetInnerWearIdentifier = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return string
    GetHeadWearIdentifier = function(Character) end,

    ---@public
    ---@static
    ---@param Client Client?
    ---@param Message string
    ---@param Color Color?
    ---@return nil
    DMClient = function(Client, Message, Color) end,

    ---@public
    ---@static
    ---@param ConfigEntry string
    ---@return Color
    GetColorFromConfigEntry = function(ConfigEntry) end,

    ---@public
    ---@static
    ---@param Vector Vector2
    ---@return number
    Magnitude = function(Vector) end,

    ---@public
    ---@static
    ---@param Min number
    ---@param Max number
    ---@return number
    RandomRange = function(Min, Max) end,

    ---@public
    ---@static
    ---@param Chance number
    ---@return boolean
    Chance = function(Chance) end,

    ---@public
    ---@static
    ---@param Value boolean
    ---@param Out number?
    ---@return boolean
    BoolToNum = function(Value, Out) end,

    ---@public
    ---@static
    ---@return boolean
    GameIsPaused = function() end,

    ---@public
    ---@static
    ---@return boolean
    InGame = function() end,

    ---@public
    ---@static
    ---@return boolean
    GameIsMultiplayer = function() end,

    ---@public
    ---@static
    ---@return boolean
    GameIsSingleplayer = function() end,

    ---@public
    ---@static
    ---@return boolean
    IsMain = function() end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param ItemIdentifier string
    ---@param Condition number?
    ---@return nil
    GiveItem = function(Character, ItemIdentifier, Condition) end,

    ---@public
    ---@static
    ---@param ItemIdentifier string
    ---@param Inventory Inventory
    ---@param Slot InvSlotType
    ---@param Position Vector2
    ---@param Function function?
    ---@param Condition number?
    ---@param Parameters [...]
    ---@return nil
    SpawnItemPlusFunction = function(ItemIdentifier, Inventory, Slot, Position, Function, Condition, Parameters) end,

    ---@public
    ---@static
    ---@param ItemIdentifier string
    ---@param Character Character
    ---@param Function function?
    ---@param Parameters [...]
    ---@return nil
    GiveItemPlusFunction = function(ItemIdentifier, Character, Function, Parameters) end,

    ---@public
    ---@static
    ---@param ItemIdentifier string
    ---@param Vector Vector2
    ---@return nil
    SpawnItemAt = function(ItemIdentifier, Vector) end,

    ---@public
    ---@static
    ---@param Item Barotrauma.Item?
    ---@return nil
    RemoveItem = function(Item) end,

    ---@public
    ---@static
    ---@param Item Barotrauma.Item?
    ---@param Tag string
    ---@return boolean
    ItemHasTag = function(Item,Tag) end,

    ---@public
    ---@static
    ---@param Container Barotrauma.Item
    ---@param Identifier string
    ---@param Index integer?
    ---@return nil
    PutItemInContainer = function(Container, Identifier, Index) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return nil
    RemoveCharacter = function(Character) end,

    ---@public
    ---@static
    ---@param COD CauseOfDeath
    ---@return string
    CauseOfDeathToString = function(COD) end,

    ---@public
    ---@static
    ---@param GivenEntity Entity
    ---@param Range number?
    ---@param Force number?
    ---@param Damage number?
    ---@param StructureDamage number?
    ---@param ItemDamage number?
    ---@param EmpStrength number?
    ---@param BallastStrength number?
    ---@return nil
    Explode = function(GivenEntity, Range, Force, Damage, StructureDamage, ItemDamage, EmpStrength, BallastStrength) end,

    ---@public
    ---@static
    ---@param Identifier Identifier
    ---@return string
    GetText = function(Identifier) end,

    ---@public
    ---@static
    ---@param JobIdentifier string
    ---@return string
    JobMemberCount = function(JobIdentifier) end,

    ---@public
    ---@static
    ---@param Header string
    ---@param Msg string
    ---@param CharacterClient Client
    ---@return nil
    SendTextBox = function(Header, Msg, CharacterClient) end,

    ---@public
    ---@static
    ---@param Message string
    ---@return nil
    Print = function(Message) end,

    ---@public
    ---@static
    ---@param Message string
    ---@return nil
    PrintError = function(Message) end,

    ---@public
    ---@static
    ---@param Message string
    ---@return nil
    PrintWarning = function(Message) end,

    ---@public
    ---@static
    ---@param Message string
    ---@return nil
    PrintUtility = function(Message) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param SkillType Identifier
    ---@return number
    GetSkillLevel = function(Character, SkillType) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param SkillType Identifier
    ---@return number
    GetBaseSkillLevel = function(Character, SkillType) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param SkillType Identifier
    ---@param RequiredAmount number
    ---@return boolean
    GetSkillRequirementMet = function(Character, SkillType, RequiredAmount) end,

    ---@public
    ---@static
    ---@return boolean
    IsNTSPEnabled = function() end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return number
    GetSurgerySkill = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param RequiredAmount number
    ---@return boolean
    GetSurgerySkillRequirementMet = function(Character, RequiredAmount) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param SkillType Identifier
    ---@param Amount number
    ---@return nil
    GiveSkill = function(Character, SkillType, Amount) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param Amount number
    ---@return nil
    GiveSurgerySkill = function(Character, Amount) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param SkillType Identifier
    ---@param Amount number
    ---@return nil
    GiveSkillScaled = function(Character, SkillType, Amount) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param FlagType AbilityFlags
    ---@return boolean
    HasAbilityFlag = function(Character, FlagType) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@return Vector2
    GetVelocity = function(Character) end,

    ---@public
    ---@static
    ---@param Character Character
    ---@param Talent string
    ---@return boolean
    HasTalent = function(Character, Talent) end,

    ---@public
    ---@static
    ---@param Character1 Character
    ---@param Character2 Character
    ---@return number
    CharacterDistance = function(Character1, Character2) end,

    ---@public
    ---@static
    ---@param Input string
    ---@return string
    FirstCharToUpper = function(Input) end,

    ---@public
    ---@static
    ---@return boolean
    UsingAddons = function() end,

    ---@public
    ---@static
    ---@return boolean
    UsingLuaAddons = function() end,

    ---@public
    ---@static
    ---@return boolean
    UsingCSAddons = function() end,

    ---@public
    ---@static 
    ---@param ModName string
    ---@return boolean
    UsingCSAddon = function(ModName) end,

    ---@public
    ---@static 
    ---@param Value number
    ---@param Aff NTAfflictionPrefab
    ---@return number
    AffClamp = function(Value, Aff) end,

    ---@public
    ---@static 
    ---@param Value number
    ---@return boolean
    IsNaNOrInfinity = function(Value) end,

    ---@public
    ---@static 
    ---@param Value number
    ---@return number
    NormalizeDouble = function(Value) end,

    ---@public
    ---@static 
    ---@param Value number
    ---@return number
    NormalizeFloat = function(Value) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@return boolean
    IsCharacterValid = function(Character) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Identifier string
    ---@param MinAmount number?
    ---@return boolean
    HasAffliction = function(Character, Identifier, MinAmount) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Identifier string
    ---@param GivenLimbType LimbType?
    ---@param MinAmount number?
    ---@return boolean
    HasAfflictionLimb = function(Character, Identifier, GivenLimbType, MinAmount) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Identifier string
    ---@param GivenLimbType LimbType?
    ---@param MinAmount number?
    ---@return boolean
    HasAfflictionExtremity = function(Character, Identifier, GivenLimbType, MinAmount) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Identifier string
    ---@return Affliction
    GetAffliction = function(Character, Identifier) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Identifier string
    ---@param GivenLimbType LimbType?
    ---@return Affliction
    GetAfflictionLimb = function(Character, Identifier, GivenLimbType) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Identifier string
    ---@param DefaultValue number?
    ---@return number
    GetAfflictionStrength = function(Character, Identifier, DefaultValue) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Identifier string
    ---@param DefaultValue number?
    ---@return number
    GetAfflictionStrengthLimb = function(Character, GivenLimbType, Identifier, DefaultValue) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Identifier string
    ---@param Strength number
    ---@param Aggressor Character?
    ---@return nil
    AddAffliction = function(Character, Identifier, Strength, Aggressor) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Identifier string
    ---@param Strength number
    ---@param Aggressor Character?
    ---@param PrevStrength number?
    ---@return nil
    SetAffliction = function(Character, Identifier, Strength, Aggressor, PrevStrength) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Identifier string
    ---@param Strength number
    ---@param Aggressor Character?
    ---@param PrevStrength number?
    ---@return nil
    SetAfflictionLimb = function(Character, Identifier, GivenLimbType, Strength, Aggressor, PrevStrength) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Identifier string
    ---@param Strength number
    ---@param Aggressor Character?
    ---@return nil
    AddAfflictionLimb = function(Character, Identifier, GivenLimbType, Strength, Aggressor) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Identifier string
    ---@param Strength number
    ---@param Aggressor Character?
    ---@return nil
    AddAfflictionResisted = function(Character, Identifier, Strength, Aggressor) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Identifier string
    ---@param TotalAmount number
    ---@param Duration number
    ---@param Aggressor Character?
    ---@return nil
    ApplyAfflictionOverTime = function(Character, Identifier, TotalAmount, Duration, Aggressor) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Identifier string
    ---@param Strength number
    ---@param PrevStrength number
    ---@param MinStrength number
    ---@param MaxStrength number
    ---@return nil
    ApplyAfflictionChangeLimb = function(Character, GivenLimbType, Identifier, Strength, PrevStrength, MinStrength, MaxStrength) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Strength number?
    ---@return nil
    DislocateLimb = function(Character, GivenLimbType, Strength) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Strength number?
    ---@return nil
    BreakLimb = function(Character, GivenLimbType, Strength) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Strength number?
    ---@return nil
    ArteryCutLimb = function(Character, GivenLimbType, Strength) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param IsArm boolean?
    ---@return boolean
    LimbIsDislocated = function(Character, GivenLimbType, IsArm) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param IsArm boolean?
    ---@return boolean
    LimbIsBroken = function(Character, GivenLimbType, IsArm) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@return boolean
    LimbIsArterialCut = function(Character, GivenLimbType) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@return boolean
    LimbIsTraumaticallyAmputated = function(Character, GivenLimbType) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@return boolean
    LimbIsSurgicallyAmputated = function(Character, GivenLimbType) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@return boolean
    LimbIsAmputated = function(Character, GivenLimbType) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Attacker Character?
    ---@return nil
    TraumamputateLimbAndGenerateItem = function(Character, GivenLimbType, Attacker) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Attacker Character?
    ---@return nil
    TraumamputateLimb = function(Character, GivenLimbType, Attacker) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Attacker Character?
    ---@return nil
    SurgicallyAmputateLimbAndGenerateItem = function(Character, Attacker, GivenLimbType) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param GivenLimbType LimbType
    ---@param Strength number?
    ---@param traumampStrength number?
    ---@return nil
    SurgicallyAmputateLimb = function(Character, GivenLimbType, Strength, traumampStrength) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@return boolean
    CanPerformSurgeryOn = function(Character) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@param Amount number
    ---@return boolean
    Fibrillate = function(Character, Amount) end,

    ---@public
    ---@static 
    ---@param C NTHuman
    ---@param Limb LimbType
    ---@param Key string
    ---@return boolean
    LimbLockedInitial = function(C, Limb, Key) end,

    ---@public
    ---@static 
    ---@param C NTHuman
    ---@param DamageValue number
    ---@param deltaTime number
    ---@param noMaxStrength boolean
    ---@return number
    OrganDamageCalc = function(C, DamageValue, deltaTime, noMaxStrength) end,

    ---@public
    ---@static 
    ---@param C NTHuman
    ---@param DamageValue number
    ---@param deltaTime number
    ---@return number
    KidneyDamageCalc = function(C, DamageValue, deltaTime) end,

    ---@public
    ---@static 
    ---@param Package ContentPackage
    ---@param DesiredPackageIdentifier string
    ---@return boolean
    IsWorkshopPackageEnabledByID = function(Package, DesiredPackageIdentifier) end,

    ---@public
    ---@static 
    ---@param Character Character
    ---@return Client?
    CharacterToClient = function(Character) end,

    ---@public
    ---@static 
    ---@param Name string
    ---@return Client?
    ClientFromName = function(Name) end,

    ---@public
    ---@static 
    ---@return Dictionary<string, boolean>?
    DynamicUnavailableItems = function() end,

    ---@public
    ---@static 
    ---@param A number
    ---@param B number
    ---@param T number
    ---@return number
    Lerp = function(A,B,T) end,

    ---@public
    ---@static 
    ---@param Value number
    ---@param Minimum number
    ---@param Maximum number
    ---@return number
    Clamp = function(Value, Minimum, Maximum) end,

    ---@public
    ---@static 
    ---@param Value number
    ---@param NumOfDecimalPlaces integer?
    ---@return number
    Round = function(Value, NumOfDecimalPlaces) end,

    ---@public
    ---@static 
    ---@param String string
    ---@param Start string
    ---@return boolean
    StartsWith = function(String, Start) end,

    ---@public
    ---@static 
    ---@param StringToSplit string
    ---@param Separator string
    ---@return List<string>
    SplitString = function(StringToSplit, Separator) end,

    ---@public
    ---@static 
    ---@param StringToReplace string
    ---@param ValueToReplace string
    ---@param ValueToReplaceWith string
    ---@return string
    ReplaceString = function(StringToReplace, ValueToReplace, ValueToReplaceWith) end,

    ---@public
    ---@static 
    ---@param Pos1 Vector2
    ---@param Pos2 Vector2
    ---@return number
    Distance = function(Pos1, Pos2) end,

    ---@public
    ---@static 
    ---@param Table table
    ---@param Value unknown
    ---@return boolean
    TableContains = function(Table, Value) end,

}