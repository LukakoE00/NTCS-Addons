
THERMTranslation = {}

-- TODO: Make this use XML
-- TextManager.ContainsTag(config.Label)  TextManager.Get(config.Label)

EnglishTranslation = {
                    Readout = "Temperature readout of ", Hypothermic = "Hypothermic", Hyperthermic = "Hyperthermic", 
                    NormalTemp = "Normal temperature range", LimbsToCheck = {
                        [LimbType.Torso]      = "Torso",
                        [LimbType.Head]       = "Head",
                        [LimbType.LeftArm]    = "Left Arm",
                        [LimbType.RightArm]   = "Right Arm",
                        [LimbType.LeftThigh]  = "Left Leg",
                        [LimbType.RightThigh] = "Right Leg"},
                    Body = "Body"
}
RussianTranslation = {
                    Readout = "Температура тела ", Hypothermic = "Гипотермия", Hyperthermic = "Гипертермия", 
                    NormalTemp = "Температура в пределах нормы", LimbsToCheck = {
                        [LimbType.Torso]      = "Торс",
                        [LimbType.Head]       = "Голова",
                        [LimbType.LeftArm]    = "Левая рука",
                        [LimbType.RightArm]   = "Правая рука",
                        [LimbType.LeftThigh]  = "Левая нога",
                        [LimbType.RightThigh] = "Правая нога"},
                    Body = "Тело"
}
PolishTranslation = {
                    Readout = "Odczyt temperatury ", Hypothermic = "Hipotermiczny", Hyperthermic = "Hipertermiczny", 
                    NormalTemp = "Normalny zakres temperatury", LimbsToCheck = {
                        [LimbType.Torso]      = "Tors",
                        [LimbType.Head]       = "Głowa",
                        [LimbType.LeftArm]    = "Lew Ramię",
                        [LimbType.RightArm]   = "Prawe Ramię",
                        [LimbType.LeftThigh]  = "Lewa Noga",
                        [LimbType.RightThigh] = "Prawa Noga"},
                    Body = "Ciało"
}
Translation = {
                    ["English"] = EnglishTranslation,
                    ["Russian"] = RussianTranslation,
                    ["Polish"] = PolishTranslation
}

 -- MOD COMPAT ----------------------------------------------------------------------------------------------------------------------------

-- Use this to add translations to the thermometer.
-- Make sure to follow the structure seen above.
---@param language string
---@param translation_table table
THERMTranslation.AddTranslation = function (language, translation_table)
    Translation[language] = translation_table
end