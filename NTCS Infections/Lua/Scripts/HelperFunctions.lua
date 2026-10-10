local limbtypes = {
    LimbType.Torso,
    LimbType.Head,
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
}

NTCS_Infections.anti_strep = {
    afceftazidime = 4/5,
    afcotrim = 1/3,
    afantibiotics = 1/4,
    afimipenem = 1/5,
    afampicillin = 1/10,
    afaugmentin = 1/16,
    afvancomycin = 1/20,
}

NTCS_Infections.anti_staph = {
    afgentamicin = 9/10,
    afimipenem = 1/4,
    afampicillin = 1/4,
    afcotrim = 1/5,
    afaugmentin = 1/10,
    afvancomycin = 1/50,
}

NTCS_Infections.anti_pseudo = {
    afimipenem = 1/5,
    afceftazidime = 1/8,
    afgentamicin = 1/20,
}

NTCS_Infections.anti_provo = {
    afampicillin = 3/5,
    afaugmentin = 2/5,
    afimipenem = 1/3,
    afceftazidime = 1/5,
    afgentamicin = 1/20,
}

NTCS_Infections.anti_aero = {
    afampicillin = 4/5,
    afaugmentin = 3/4,
    afimipenem = 1/2,
    afvancomycin = 1/2,
    afcotrim = 2/5,
    afceftazidime = 1/4,
    afgentamicin = 1/20,
}

NTCS_Infections.anti_mrsa = {
    afgentamicin = 9/10,
    afcotrim = 1/5,
    afvancomycin = 1/50,
}

NTCS_Infections.med_viral = {
    afdextromethorphan = 100,
    analgesia = 50,
    afzincsupplement = 50,
}

NTCS_Infections.head_protection = {
    sterile = 10,
    diving = 10,
}

NTCS_Infections.outer_protection = {
    diving = 15,
    divinghelmet = 15,
}

NTCS_Infections.beta_lactams = {afampicillin=true, afaugmentin=true, afimipenem=true}
NTCS_Infections.resistant = {limbstaph=true}

NTCS_Infections.pus_yellow_causes = {"limbstrep", "limbstaph", "limbprovo", "limbmrsa"}
NTCS_Infections.pus_green_causes = {"limbpseudo", "limbaero"}

function NTCS_Infections.VirusInfo(_id, _probability, _basespeed, _severityspeed, _antibiotics, _medicine, _slowdown, _virulence, _samplename, _vaccine, _name)
    return { id = _id, probability = _probability, basespeed = _basespeed, severityspeed = _severityspeed, antibiotics = _antibiotics, medicine = _medicine, slowdown = _slowdown, virulence = _virulence, samplename = _samplename, vaccine = _vaccine, name = _name }
end

--[[
    id - unique integer identifier
    probability - the odds of a bot spawning with the infection
    basespeed - the base speed the infection will increase
    severityspeed - increase depending on severity level. severity level ranges from 1-10, so totalspeed = basespeed + (severity_level * severityspeed)
    antibiotics - actually antivirals (misnomer for compatability), list of drugs that will decrease the speed of the virus
    medicine - list of drugs that will alleviate symptoms of the virus
    slowdown - speed multiplier to show down a character
    virulence - multiplier for infection spread chance, cannot be 0 or less
    samplename - sample to be returned when analyzing virus
    vaccine - the vaccine affliction acting against this virus
    name - stopgap way to identify virus in sampling tool
]]--

function NTCS_Infections.BacteriaInfo(_id, _bloodname, _prevalence, _basespeed, _severityspeed, _antibiotics, _samplename, _vaccine, _resistant)
    return { id = _id, bloodname = _bloodname, prevalence = _prevalence, basespeed = _basespeed, severityspeed = _severityspeed, antibiotics = _antibiotics, samplename = _samplename, vaccine = _vaccine, resistant = _resistant }
end

--[[
    id - unique integer identifier
    bloodname - the blood infection version on the infection
    prevalence - the "number of names put into the hat" that will have the chance to be pulled from the list of random infections. change in config
    basespeed - basespeed at which the infection progresses
    severityspeed - increase depending on severity level. severity level ranges from 2-10, so totalspeed = basespeed + (severity_level * severityspeed)
    antibiotics - a list of antibiotics that have an effect on said disease. the number provided is the denominator, so antibiotics are calculated as: infection_speed * (1 / antibiotic_value)...
    samplename - the item that is returned when using a sample collector
    vaccine - the vaccine affliction name that will have an effect on this disease
    resistant - name of the resistant version of the infection
]]--

Timer.Wait(function()
    NTCS_Infections.Viruses = {
        europancough = NTCS_Infections.VirusInfo(1, "NTI_europanChance", 0.4, 0.05, {afremdesivir = 1/10}, NTCS_Infections.med_viral, 0.6, 1, "europanviralunk", "afeuropanvac", "europancough"),
        influenza = NTCS_Infections.VirusInfo(2, "NTI_influenzaChance", 0.35, 0.05, {afzincsupplement = 4/5}, NTCS_Infections.med_viral, 0.4, 0.9, "fluviralunk", "affluvac", "influenza"),
        commoncold = NTCS_Infections.VirusInfo(3, "NTI_coldChance", 0.3, 0.05, {afzincsupplement = 3/4}, NTCS_Infections.med_viral, 0.2, 0.8, "coldviralunk", "NONE", "commoncold"),
    }

    NTCS_Infections.Bacterias = {
        limbstaph = NTCS_Infections.BacteriaInfo(1, "bloodstaph", "NTI_staphPrevalence", 0.5, 0.05, NTCS_Infections.anti_staph, "staphtubeunk", "afstaphvac", "limbmrsa"),
        limbstrep = NTCS_Infections.BacteriaInfo(2, "bloodstrep", "NTI_strepPrevalence", 0.5, 0.05, NTCS_Infections.anti_strep, "streptubeunk", "afstrepvac", "NONE"),
        limbprovo = NTCS_Infections.BacteriaInfo(3, "bloodprovo", "NTI_provoPrevalence", 0.5, 0.05, NTCS_Infections.anti_provo, "provotubeunk", "afprovovac", "NONE"),
        limbpseudo = NTCS_Infections.BacteriaInfo(4, "bloodpseudo", "NTI_pseudoPrevalence", 0.5, 0.05, NTCS_Infections.anti_pseudo, "pseudotubeunk", "afpseudovac", "NONE"),
        limbaero = NTCS_Infections.BacteriaInfo(5, "bloodaero", "NTI_aeroPrevalence", 0.5, 0.05, NTCS_Infections.anti_aero, "aerotubeunk", "afaerovac", "NONE"),
        limbmrsa = NTCS_Infections.BacteriaInfo(6, "bloodmrsa", "NTI_mrsaPrevalence", 0.5, 0.05, NTCS_Infections.anti_mrsa, "mrsatubeunk", "afstaphvac", "NONE"),
    }

    NTCS_Infections.BacteriasIndex = {}
    NTCS_Infections.VirusesIndex = {}
    for _, info in pairs(NTCS_Infections.Bacterias) do NTCS_Infections.BacteriasIndex[info.id] = info end
    for _, info in pairs(NTCS_Infections.Viruses) do NTCS_Infections.VirusesIndex[info.id] = info end
end,1)


---- HELPER FUNCTIONS ----
--symptom dealing
function NTCS_Infections.CheckSymptom(character, symptom, level, threshold, chance)
    if (level < threshold) then return end

    local NTHuman = NTCS.Human.getNTHumanFromCharacter(character)
    if (NTHuman.HasSymptom(symptom) or NTCS.HF.Chance(chance)) then
        NTHuman.SetSymptomTrue(symptom, 4)
    end
end

--return the total antibiotic value from a list
function NTCS_Infections.GetAntibioticValue(character, list)
    local result = 1
    
    for key, value in pairs(list) do
        if NTCS.HF.GetAfflictionStrength(character, key, 0) > 0 then
            result = result * value
        end
    end

    return result
end

--return a boolean if there is sepsis
function NTCS_Infections.HasSepsis(character)
    return NTCS.HF.GetAfflictionStrength(character, "sepsis", 0) > 0
end

--decomposing the wound calculating stuff
function NTCS_Infections.HasWound(c, limbaff, type)
    local wound = limbaff.burn.strength +
    limbaff.lacerations.strength +
    limbaff.gunshotwound.strength +
    limbaff.bitewounds.strength +
    limbaff.explosiondamage.strength +
    NTCS.HF.GetAfflictionStrengthLimb(c.Human, type, "suturedw", 0) +
    NTCS.HF.GetAfflictionStrengthLimb(c.Human, type, "surgeryincision", 0)

    return wound > 0
end

--return a boolean if a limb is not the head (or torso if specified)
function NTCS_Infections.NotHead(limb, torso_included)
    return limb ~= LimbType.Head or (torso_included and limb ~= LimbType.Torso)
end


---- BACTERIAL INFECTIONS ----
--returns the increase at which blood infection should increase
function NTCS_Infections.BloodInfUpdate(c)
    local total = 0
    local infections = {}

    for key, info in pairs(NTCS_Infections.Bacterias) do
        local severity = NTCS.HF.GetAfflictionStrength(c.Human, info.bloodname, 0)

        if severity > 0 then
            local base = 0.5 + (severity * 0.05)
            total = total + base
            infections[key] = base
        end
    end

    if total < 1 then total = 1 end
    local result = 0

    for key, value in pairs(infections) do
        local info = NTCS_Infections.Bacterias[key]
        local increase = (value / total) 
                        * NTCS_Infections.GetAntibioticValue(c.Human, info.antibiotics)
                        * (1 - (NTCS.HF.GetAfflictionStrength(c.Human, info.vaccine, 0) / 200) * (c:GetAfflictionStrength("immunity") / 100))

        result = result + increase
    end

    return result
end

--returns if the blood is infected
function NTCS_Infections.BloodIsInfected(character)
    return NTCS.HF.GetAfflictionStrength(character, "bloodinfectionlevel", 0) > 0
end

--return the total blood infection in the body
function NTCS_Infections.BloodSeverityTotal(character)
    local result = 0

    for _, info in pairs(NTCS_Infections.Bacterias) do
        result = result + NTCS.HF.GetAfflictionStrength(character, info.bloodname, 0)
    end

    return result
end

--kind of a dumb solution, but i didnt want to go out of my way to override a lot of the code from ntsp and ntspu as they do not specify which limb is unsterile
function NTCS_Infections.DetermineDirtiestLimb(character)
    local choice = nil

    for limb in limbtypes do
        if not NTCS_Infections.LimbIsInfected(character, limb) and NTCS.HF.HasAfflictionLimb(character, "surgeryincision", limb) then
            if not NTCS.HF.HasAfflictionLimb(character, "ointmented", limb) then
                choice = limb
                break
            end

            choice = limb
        end
    end

    if choice ~= nil and choice ~= LimbType.Torso and NTCS.HF.LimbIsAmputated(character, choice) then
        choice = LimbType.Torso
    end

    return choice
end

--make a list for the probability of which infection is picked
function NTCS_Infections.FormBacteriaList(character)
    local list = {}

    for key, info in pairs(NTCS_Infections.Bacterias) do
        for i = 1, (NTConfig.Get(info.prevalence, 1)) do
            table.insert(list, 1, key)
        end
    end

    return list
end

--return current bacteria infection name on limb
function NTCS_Infections.GetCurrentBacteria(character, limb)
    for key, _ in pairs(NTCS_Infections.Bacterias) do
        if NTCS.HF.GetAfflictionStrengthLimb(character, limb, key, 0) > 0 then return key end
    end

    return nil
end

--return random blood bacteria infection name
function NTCS_Infections.GetCurrentBacteriaBloodRandom(character)
    local total = 0
    local infections = {}

    for key, info in pairs(NTCS_Infections.Bacterias) do
        local strength = NTCS.HF.GetAfflictionStrength(character, info.bloodname, 0)

        if strength > 0 then
            infections[key] = strength
            total = total + strength
        end
    end

    local cumulative = 0
    local random = math.random(total)

    for key, value in pairs(infections) do
        cumulative = cumulative + value

        if random <= cumulative then return key end
    end

    return nil
end

--return sepsis increase from limb infections
function NTCS_Infections.GetLimbIncreaseSepsis(character)
    return NTCS_Infections.LimbTotalInfectionLevel(character) / 1000
end

--returns the correct pus color depending on infection type
function NTCS_Infections.GetPusColor(character, limb)
    for bacteria in NTCS_Infections.pus_yellow_causes do
        if NTCS.HF.GetAfflictionStrengthLimb(character, limb, bacteria, 0) > 0 then return "pusyellow" end
    end

    for bacteria in NTCS_Infections.pus_green_causes do
        if NTCS.HF.GetAfflictionStrengthLimb(character, limb, bacteria, 0) > 0 then return "pusgreen" end
    end

    return nil
end

--infect character with a specific bacteria on a limb
function NTCS_Infections.InfectCharacterBacteria(character, limb, bacteria, severity)
    if bacteria == nil then return end
    if NTCS_Infections.LimbIsInfected(character, limb) then return end

    local mrrisk = NTCS.HF.GetAfflictionStrength(character, "mrrisk", 0)
    local mrname = NTCS_Infections.Bacterias[bacteria].resistant
    local truename = bacteria

    if mrrisk > 0 and mrname ~= "NONE" then
        if NTCS.HF.Chance(NTConfig.Get("NTI_mrChance", 1) * (mrrisk / 100)) then
            truename = mrname
        end
    end

    NTCS.HF.SetAfflictionLimb(character, truename, limb, severity)
    NTCS.HF.SetAfflictionLimb(character, "infectionlevel", limb, 1)
end

--infect a character's blood with a specific bacteria
function NTCS_Infections.InfectCharacterBlood(character, bacteria, severity)
    if bacteria == nil then return end

    NTCS.HF.AddAffliction(character, "bloodinfectionlevel", 1)
    NTCS.HF.SetAffliction(character, bacteria, severity)
end

--infect a character's blood with a random bacteria
function NTCS_Infections.InfectCharacterBloodRandom(character)
    local randomval = math.random(5) + math.random(5)
    local list = NTCS_Infections.FormBacteriaList(character)
    local bacteria = list[math.random(#list)]
    local info = NTCS_Infections.Bacterias[bacteria]

    if NTCS.HF.GetAfflictionStrength(character, info.bloodname, 0) > 0 then return end

    NTCS_Infections.InfectCharacterBlood(character, info.bloodname, randomval);
end

--infect the character with a random infection and severity on a limb
function NTCS_Infections.InfectCharacterRandom(character, limb)
    local randomval = math.random(5) + math.random(5)
    local list = NTCS_Infections.FormBacteriaList(character)
    NTCS_Infections.InfectCharacterBacteria(character, limb, list[math.random(#list)], randomval)
end

--returns if the limb is cybernetic or amputated surgically
function NTCS_Infections.LimbAmputatedOrCybernetic(character, limb)
    if NTCS.HF.LimbIsSurgicallyAmputated(character, limb) then return true end
    if NTCS_Cybernetics ~= nil and NTCS_Cybernetics.HF.LimbIsCyber(character, limb) then return true end

    return false
end

--return the infection level of a limb from a list of infections
function NTCS_Infections.LimbInfectionLevelList(character, limb, list)
    for i = 1, #list do
        if NTCS.HF.HasAfflictionLimb(character, list[i], limb, 0) then
            return NTCS.HF.GetAfflictionStrengthLimb(character, limb, "infectionlevel", 0)
        end
    end

    return 0
end

--return a boolean if a limb is currently infected
function NTCS_Infections.LimbIsInfected(character, limb)
    return NTCS.HF.GetAfflictionStrengthLimb(character, limb, "infectionlevel", 0) > 0
end

--return total limb infection across the whole body
function NTCS_Infections.LimbTotalInfectionLevel(character)
    local result = 0

    for limb in limbtypes do
        result = result + NTCS.HF.GetAfflictionStrengthLimb(character, limb, "infectionlevel", 0)
    end

    return result
end

--NTCS_Infections override for surgery plus stuff
function NTCS_Infections.TriggerUnsterilityEvent(character)
    local type = NTCS_Infections.DetermineDirtiestLimb(character)

    if type ~= nil then
        NTCS_Infections.InfectCharacterRandom(character, type)
    end
end


---- VIRAL INFECTIONS ----
--for when a new ai npc spawns, give a chance to randomly infect them
function NTCS_Infections.BotViralStarter(character, virus)
    local val = math.random(40)
    local sev = math.random(10)
    NTCS_Infections.InfectCharacterViral(character, virus, val, sev)
    NTCS.HF.SetAffliction(character, "systemicresponse", val / 2)
end

--get the name of the current virus of a character
function NTCS_Infections.GetCurrentVirus(character)
    for key, _ in pairs(NTCS_Infections.Viruses) do
        if NTCS.HF.GetAfflictionStrength(character, key, 0) > 0 then return key end
    end

    return nil
end

--return the total medicine value from a list
function NTCS_Infections.GetTotalMedValue(character, list)
    local result = 0

    for key, value in pairs(list) do
        if NTCS.HF.GetAfflictionStrength(character, key, 0) > 0 then
            result = result + value
        end
    end

    return result
end

--return full body necrotizing fasciitis level
function NTCS_Infections.GetTotalNecValue(character)
    local result = 0

    for limb in limbtypes do
        result = result + NTCS.HF.GetAfflictionStrengthLimb(character, limb, "necfasc", 0)
    end

    return result
end

--infect viral infection with random severity
function NTCS_Infections.InfectCharacterViral(character, virus, level, severity)
    NTCS.HF.SetAffliction(character, virus, severity)
    NTCS.HF.SetAffliction(character, "virallevel", level)
end

--spread viral infections to other characters from an infected character
function NTCS_Infections.SpreadViralInfection(character, initial_chance, virus, meds, strength, name, level)
    if not NTCS.HF.Chance(initial_chance) then return end

    for _, targetcharacter in pairs(Character.CharacterList) do
        NTCS_Infections.HelperSpreadViralInfectionLoop(character, targetcharacter, virus, meds, strength, name, level)
    end
end

function NTCS_Infections.HelperSpreadViralInfectionLoop(character, targetcharacter, virus, meds, strength, name, level)
    if targetcharacter == character or not targetcharacter.IsHuman then return end

    local distance = NTCS.HF.CharacterDistance(character,targetcharacter)

    if distance > 300 or NTCS.HF.HasAffliction(targetcharacter, "virallevel") then return end

    local head = NTCS_Infections.WearingNeededHead(targetcharacter, NTCS_Infections.head_protection) + NTCS_Infections.WearingNeededHead(character, NTCS_Infections.head_protection)
    local outer = NTCS_Infections.WearingNeededOuter(targetcharacter, NTCS_Infections.outer_protection) + NTCS_Infections.WearingNeededOuter(character, NTCS_Infections.outer_protection)

    local chance = NTCS.HF.Clamp(((distance / 3) + NTCS.HF.GetAfflictionStrength(targetcharacter, "immunity", 0)) / 10, 1, 30) * (1 / math.max(0.1, virus.virulence)) + head + outer
                + (meds / 50)
                + NTCS.HF.Clamp(20 - strength / 2, 0, 20)
                + NTCS.HF.BoolToNum(not targetcharacter.IsPlayer, 20)
                + NTCS.HF.BoolToNum(not targetcharacter.IsOnPlayerTeam, 20)

    if NTCS.HF.Chance(1 / chance) then
        NTCS_Infections.InfectCharacterViral(targetcharacter, name, 1, level)
    end
end

--check if a character is wearing a specific tag from a list on their head
function NTCS_Infections.WearingNeededHead(character, tagval)
    local result = 0

    local headwear = NTCS.HF.GetItemInHeadWear(character)

    if headwear == nil then return result end

    for key, value in pairs(tagval) do

        
        if NTCS.HF.ItemHasTag(headwear, key) then
            result = result + value
        end
    end

    return result
end

--ibidem but for outer wear
function NTCS_Infections.WearingNeededOuter(character, tagval)
    local result = 0

    for key, value in pairs(tagval) do
        if NTCS.HF.ItemHasTag(NTCS.HF.GetItemInOuterWear(character), key) then
            result = result + value
        end
    end

    return result
end

Hook.Add("characterCreated", "NTCS_Infections.StartWithInfection", function(createdCharacter)
    Timer.Wait(function()
        if (createdCharacter.IsHuman and not createdCharacter.IsDead and not createdCharacter.IsPlayer and not createdCharacter.IsOnPlayerTeam) then
            for key, info in pairs(NTCS_Infections.Viruses) do
                if NTCS.HF.Chance(1 / NTCS.Config.Get(info.probability, 1)) then
                    NTCS_Infections.BotViralStarter(createdCharacter, key)
                    break
                end
            end
        end
    end, 2000)
end)