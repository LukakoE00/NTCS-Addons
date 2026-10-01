local AfflictionLoader = NTCS.AfflictionsLoader("NTCS Cybernetics")
local AfflictionBuilder = NTCS.AfflictionPrefabBuilder()

-- Used to apply UpdateLimb + BoneDamage override.
local LimbTypes = {
	LimbType.Torso,
	LimbType.Head,
	LimbType.LeftArm,
	LimbType.RightArm,
	LimbType.LeftLeg,
	LimbType.RightLeg,
}

function NTCS_Cybernetics.UpdateHuman(character, deltatime)
	local velocity = 0
	if
		character ~= nil
		and character.AnimController ~= nil
		and character.AnimController.MainLimb ~= nil
		and character.AnimController.MainLimb.body ~= nil
		and character.AnimController.MainLimb.body.LinearVelocity ~= nil
	then
		velocity = character.AnimController.MainLimb.body.LinearVelocity.Length()
	end

	local function UpdateLimb(character, limbtype)
		if not NTCS_Cybernetics.HF.LimbIsCyber(character, limbtype) then return end

		NTCS_Cybernetics.ConvertDamageTypes(character, limbtype)

		local limb = character.AnimController:GetLimb(limbtype)

		-- cyber stats
		local loosescrews = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "ntc_loosescrews", 0)
		local damagedelectronics = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "ntc_damagedelectronics", 0)
		local bentmetal = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "ntc_bentmetal", 0)
		local materialloss = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "ntc_materialloss", 0)

		-- water damage if unprotected
		if
			NTCS.Config.Get("NTCS_Cybernetics_waterDamage", 1) > 0
			and character.PressureProtection <= 1000
			and not NTCS.HF.HasAffliction(character, "stasis")
			and not NTCS.HF.HasAffliction(character, "bodybagoverlay")
			and NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "ntc_waterproof", 0) <= 0
		then
			-- in water?
			local inwater = false
			if limb ~= nil and limb.InWater then inwater = true end
			if inwater then
				-- add damaged electronics
				Timer.Wait(function()
					if limb ~= nil then
						local spawnpos = limb.WorldPosition
						NTCS.HF.SpawnItemAt("ntcvfx_malfunction", spawnpos)
					end
				end, math.random(1, 500))

				NTCS.HF.AddAfflictionLimb(
					character,
					"ntc_damagedelectronics",
					limbtype,
					(1 + loosescrews / 100)
						* (1 + materialloss / 100)
						* NTCS.Config.Get("NTCS_Cybernetics_waterDamage", 1)
						* deltatime
				)
			end
		end

		-- moving around damages if loose screws high enough
		if loosescrews > 30 and velocity > 1 then
			NTCS.HF.AddAfflictionLimb(
				character,
				"ntc_materialloss",
				limbtype,
				NTCS.HF.Clamp(velocity, 0, 5) * (loosescrews / 500) * deltatime
			)
			NTCS.HF.AddAfflictionLimb(
				character,
				"ntc_loosescrews",
				limbtype,
				NTCS.HF.Clamp(velocity, 0, 5) / 50 * deltatime
			)
		end

		-- losing the limb
		if materialloss >= 99 then
			NTCS_Cybernetics.UncyberifyLimb(character, limbtype)
			NTCS.NT.TraumamputateLimbMinusItem(character, limbtype)
			NTCS.HF.GiveItem(character, "ntcsfx_cyberdeath")
			NTCS.HF.AddAfflictionLimb(character, "internaldamage", limbtype, NTCS.HF.RandomRange(30, 60))
			NTCS.HF.AddAfflictionLimb(character, "foreignbody", limbtype, NTCS.HF.RandomRange(10, 25))
			return
		end

		-- limb malfunction due to damaged electronics
		local malfunction = (damagedelectronics > 20 and NTCS.HF.Chance((damagedelectronics / 120) ^ 4))
		if malfunction then NTCS.HF.SpawnItemAt("ntcvfx_malfunction", limb.WorldPosition) end
		local locklimb = damagedelectronics >= 99 or bentmetal >= 99 or malfunction

		local function lockLimb()
			local limbIdentifierLookup = {}
			limbIdentifierLookup[LimbType.LeftArm] = "lockleftarm"
			limbIdentifierLookup[LimbType.RightArm] = "lockrightarm"
			limbIdentifierLookup[LimbType.LeftLeg] = "lockleftleg"
			limbIdentifierLookup[LimbType.RightLeg] = "lockrightleg"
			if limbIdentifierLookup[limbtype] == nil then return end
			NTCS.NTC.SetSymptomTrue(character, limbIdentifierLookup[limbtype])
		end

		if locklimb then lockLimb() end

		-- slowdown due to bent metal
		if bentmetal > 5 and (limbtype == LimbType.LeftLeg or limbtype == LimbType.RightLeg) then
			NTCS.NTC.MultiplySpeed(character, 1 - (bentmetal / 100) * 0.5)
		end
	end

	for _, Type in ipairs(LimbTypes) do
		UpdateLimb(character, Type)
	end

	-- Reduce impact of certain afflictions based on the quality of the Cybernetic
	local OrganMultipliers = {
		ntc_cyberliver  = { Limb = LimbType.Torso, Names = { "liverdamagegain" } },
		ntc_cyberkidney = { Limb = LimbType.Torso, Names = { "kidneydamagegain" } },
		ntc_cyberlung   = { Limb = LimbType.Torso, Names = { "lungdamagegain", "pneumothoraxchance", "hypoxemia" } },
		ntc_cyberheart  = { Limb = LimbType.Torso, Names = { "heartdamagegain" } },
		ntc_cyberbrain  = { Limb = LimbType.Head,  Names = { "neurotraumagain" } },
	}

	for OrganId, Data in pairs(OrganMultipliers) do
		local Strength = NTCS.HF.GetAfflictionStrengthLimb(character, Data.Limb, OrganId, 0)
		if Strength >= 1 then
			local Multiplier = 1 - Strength / 200
			for _, Name in ipairs(Data.Names) do
				NTCS.NTC.SetMultiplier(character, Name, Multiplier)
			end
		end
	end

	local CyberPsychosisChance = NTCS.Config.Get("NTCS_Cybernetics_cyberpsychosisChance", 1)

	if CyberPsychosisChance ~= 1 then
		NTCS.HF.SetAffliction(character, "ntc_cyberpsychosis_resistance", 100 * (1 - CyberPsychosisChance))
	else
		NTCS.HF.SetAffliction(character, "ntc_cyberpsychosis_resistance", 0)
	end
end

function NTCS_Cybernetics.ConvertDamageTypes(character, limbtype)
	if NTCS_Cybernetics.HF.LimbIsCyber(character, limbtype) then
		-- /// fetch stats ///

		-- physical damage types
		local bleeding = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "bleeding", 0)
		local burn = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "burn", 0)
		local lacerations = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "lacerations", 0)
		local gunshotwound = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "gunshotwound", 0)
		local bitewounds = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "bitewounds", 0)
		local explosiondamage = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "explosiondamage", 0)
		local blunttrauma = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "blunttrauma", 0)
		local internaldamage = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "internaldamage", 0)
		local foreignbody = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "foreignbody", 0)

		-- cyber stats
		local loosescrews = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "ntc_loosescrews", 0)
		local prevloosescrews = loosescrews
		local damagedelectronics = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "ntc_damagedelectronics", 0)
		local prevdamagedelectronics = damagedelectronics
		local bentmetal = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "ntc_bentmetal", 0)
		local prevbentmetal = bentmetal
		local materialloss = NTCS.HF.GetAfflictionStrengthLimb(character, limbtype, "ntc_materialloss", 0)
		local prevmaterialloss = materialloss

		-- calculate damage conversion

		local function damageChance(val, chance)
			if val > 0.01 and NTCS.HF.Chance(chance) then return val end
			return 0
		end

		loosescrews = loosescrews
			+ 1
				* (0.25 * damageChance(lacerations, 0.75) + 1 * damageChance(explosiondamage, 0.8) + 0.5 * damageChance(
					blunttrauma,
					0.5
				) + 1 * damageChance(internaldamage, 0.75) + 0.5 * damageChance(bitewounds, 0.5) + 0.75 * damageChance(
					foreignbody,
					0.75
				))

		damagedelectronics = damagedelectronics
			+ 0.5
				* (1 + prevmaterialloss / 50)
				* (2 * damageChance(burn, 0.75) + 0.75 * damageChance(gunshotwound, 0.85) + 0.25 * damageChance(
					bitewounds,
					0.5
				) + 0.5 * damageChance(explosiondamage, 0.5) + 1 * damageChance(blunttrauma, 0.5) + 1 * damageChance(
					internaldamage,
					0.75
				) + 0.75 * damageChance(foreignbody, 0.75))

		bentmetal = bentmetal
			+ 1
				* (0.25 * damageChance(burn, 0.85) + 0.25 * damageChance(lacerations, 0.5) + 0.5 * damageChance(
					bitewounds,
					0.5
				) + 1 * damageChance(explosiondamage, 0.85) + 2 * damageChance(blunttrauma, 0.75))

		materialloss = materialloss
			+ (1 + prevloosescrews / 50)
				* (0.5 * damageChance(lacerations, 0.75) + 0.8 * damageChance(gunshotwound, 0.8) + 0.6 * damageChance(
					bitewounds,
					0.7
				) + 1 * explosiondamage + 0.5 * damageChance(foreignbody, 0.8))

		-- /// apply changes ///

		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "burn", 0, burn, 0, 200)
		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "bleeding", 0, bleeding, 0, 100)
		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "lacerations", 0, lacerations, 0, 200)
		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "gunshotwound", 0, gunshotwound, 0, 200)
		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "bitewounds", 0, bitewounds, 0, 200)
		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "explosiondamage", 0, explosiondamage, 0, 200)
		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "blunttrauma", 0, blunttrauma, 0, 200)
		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "internaldamage", 0, internaldamage, 0, 200)
		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "foreignbody", 0, foreignbody, 0, 100)

		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "ntc_loosescrews", loosescrews, prevloosescrews, 0, 100)
		NTCS.HF.ApplyAfflictionChangeLimb(
			character,
			limbtype,
			"ntc_damagedelectronics",
			damagedelectronics,
			prevdamagedelectronics,
			0,
			100
		)
		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "ntc_bentmetal", bentmetal, prevbentmetal, 0, 100)
		NTCS.HF.ApplyAfflictionChangeLimb(character, limbtype, "ntc_materialloss", materialloss, prevmaterialloss, 0, 100)

		NTCS.HF.DislocateLimb(character, limbtype, -1000)
		NTCS.HF.BreakLimb(character, limbtype, -1000)
		NTCS.HF.ArteryCutLimb(character, limbtype, -1000)

		NTCS.HF.SetAfflictionLimb(character, "tourniqueted", limbtype, 0)
		NTCS.HF.SetAfflictionLimb(character, "surgeryincision", limbtype, 0)
		NTCS.HF.SetAfflictionLimb(character, "clampedbleeding", limbtype, 0)
		NTCS.HF.SetAfflictionLimb(character, "drilledbones", limbtype, 0)
		NTCS.HF.SetAfflictionLimb(character, "retractedskin", limbtype, 0)
		NTCS.HF.SetAfflictionLimb(character, "suturedi", limbtype, 0)
		NTCS.HF.SetAfflictionLimb(character, "suturedw", limbtype, 0)

		if limbtype == LimbType.LeftLeg then
			NTCS.HF.SetAffliction(character, "tll_amputation", 0)
			NTCS.HF.SetAffliction(character, "sll_amputation", 0)
		end
		if limbtype == LimbType.RightLeg then
			NTCS.HF.SetAffliction(character, "trl_amputation", 0)
			NTCS.HF.SetAffliction(character, "srl_amputation", 0)
		end
		if limbtype == LimbType.LeftArm then
			NTCS.HF.SetAffliction(character, "tla_amputation", 0)
			NTCS.HF.SetAffliction(character, "sla_amputation", 0)
		end
		if limbtype == LimbType.RightArm then
			NTCS.HF.SetAffliction(character, "tra_amputation", 0)
			NTCS.HF.SetAffliction(character, "sra_amputation", 0)
		end
	end
end

-- ========================================================= ADDING AFFLICTIONS =========================================================
-- Augmented / Cybernetic Liver
local CyberLiverRecoveryRates = {
    -- these numbers are mostly "the natural recovery rate", so having the Cyberliver at 100% strength doubles the natural rate.
    radiationsickness = 0.03, -- half the normal recovery rate since I'm not sure how much a liver can help with that
    opiateoverdose = 0.3, -- 75% of the natural rate since there's also Resistance
    nausea = 1,
    drunk = 0.3, -- 150% natural rate, because liver is the funny alcohol organ :)
    alcoholaddiction = 0.015, -- half liver, half brain (mental)
    alcoholwithdrawal = 0.05, -- half liver, half brain (mental)
    mannaoverdose = 0.03, -- Real Sonar
    anesthesia = -0.3, -- Propofol grows until it hits 100 strength and resets
    incrementalstun = 1, -- aka chloralhydrate; this one normally falls at -5 below 90, then at -1 above 90 (during which they're stunned), so this should halve how long they're stunned for
    -- these poison recoveries are not enough to save them after strength > 10, but halves the rate of increase at least
    morbusinepoisoning = 0.5,
    cyanidepoisoning = 0.5,
    sufforinpoisoning = 0.3, -- slower than the others < 50%
    deliriuminepoisoning = 0.5,
}

local CyberLiver = AfflictionBuilder:New("ntc_cyberliver"):SetUpdateAction(
    function(C, Identifier, Limb, DeltaT)

        -- If in stasis, end early
        if C:GetBoolStat("stasis") then return end

        local CyberOrganQuality = C:GetAfflictionStrength("ntc_cyberliver") / 100 -- 0.5 Augmented, 1 Cybernetic
        local OrganHealth = (100 - C:GetAfflictionStrength("liverdamage")) / 100

        -- If the organ is effectively gone, end early.
        if OrganHealth < 0.1 then return end

         for AfflictionId, Rate in pairs(CyberLiverRecoveryRates) do
            local Change = Rate * CyberOrganQuality * OrganHealth * DeltaT
            local Strength = C:GetAfflictionStrength(AfflictionId)

            if Strength > 0.1 then
                -- In the HU
                C:SetAffliction(AfflictionId, math.max(0, Strength - Change))
            elseif NTCS.HF.HasAffliction(C.Human, AfflictionId, 0.1) then
                -- Not in the HU
                NTCS.HF.AddAffliction(C.Human, AfflictionId, -Change)
            end
        end

    end):Build()

AfflictionLoader:Register(CyberLiver)

-- Augmented / Cybernetic Lung
local CyberneticLung = AfflictionBuilder:New("ntc_cyberlung"):SetUpdateAction(
    function(C, Identifier, Limb, DeltaT)

        -- If in Stasis / RespiratoryArrest / Cooked, end early
        if C:GetBoolStat("stasis")
            or C:GetAfflictionStrength("respiratoryarrest") >= 1
            or C:GetAfflictionStrength("lungdamage") > 90 then
            return
        end

        local CyberOrganQuality = C:GetAfflictionStrength("ntc_cyberlung") / 100 -- 0.5 augmented, 1 cybernetic
        local OrganHealth = (100 - C:GetAfflictionStrength("lungdamage")) / 100

        -- Fully healed and augmented should keep below 19 (at 20 acidosis starts to cause bad fibrillation)
        local Threshold = NTCS.HF.Clamp(NTCS.HF.Lerp(38, 0, OrganHealth * CyberOrganQuality), 5, 30)

        -- 2 on a successful roll, 0 otherwise
        local Strength = NTCS.HF.BoolToNum(NTCS.HF.Chance(CyberOrganQuality * OrganHealth), 2)

        if C:GetAfflictionStrength("alkalosis") > Threshold then
            C:SetAffliction("hypoventilation", Strength)
        elseif C:GetAfflictionStrength("acidosis") > Threshold then
            C:SetAffliction("hyperventilation", Strength)
        end

    end):Build()

AfflictionLoader:Register(CyberneticLung)

-- Augmented / Cybernetic Heart
local CyberneticHeart = AfflictionBuilder:New("ntc_cyberheart"):SetUpdateAction(
    function(C, Identifier, Limb, DeltaT)

        SetGainMultipliers(C, "ntc_cyberheart", "heartdamagegain")

        -- If in Stasis / CardiacArrest / Cooked, end early
        if C:GetBoolStat("stasis")
            or C:GetAfflictionStrength("cardiacarrest") >= 0.1
            or C:GetAfflictionStrength("heartdamage") >= 90 then
            return
        end

        local CyberOrganQuality = C:GetAfflictionStrength("ntc_cyberheart") / 100 -- 0.5 Augmented, 1 Cybernetic
        local OrganHealth = (100 - C:GetAfflictionStrength("heartdamage")) / 100

        local BloodAmount = C:GetFloatStat("bloodamount")
        local BloodPressure = C:GetAfflictionStrength("bloodpressure")

        -- Only help when blood pressure is moving toward the blood amount
        local Recovering = (BloodAmount > BloodPressure and BloodPressure < 100)
            or (BloodAmount < BloodPressure and BloodPressure > 100)

        if not Recovering then return end

        -- Grants an extra 50-100% of the natural BP stabilization rate.
        -- Helps BP return to normal faster after bloodloss is fixed, and softens the many BP-modifying effects.
        local NewPressure = NTCS.HF.Clamp(
            NTCS.HF.Round(
                NTCS.HF.Lerp(
                    BloodPressure,
                    BloodAmount,
                    0.2 * CyberOrganQuality * OrganHealth * DeltaT
                ),
                2
            ),
            5,
            200
        )

        C:SetAffliction("bloodpressure", NewPressure)

    end):Build()

AfflictionLoader:Register(CyberneticHeart)

-- Cybernetic Brain
local CyberbrainRecoveryRates = {
    opiateaddiction = 0.1,
    opiatewithdrawal = 0.1,
    chemaddiction = 0.05,
    chemwithdrawal = 0.1,
    alcoholaddiction = 0.015, -- half liver, half brain (mental)
    alcoholwithdrawal = 0.05, -- half liver, half brain (mental)
}

local CyberneticBrain = AfflictionBuilder:New("ntc_cyberbrain"):SetUpdateAction(
    function(C, Identifier, Limb, DeltaT)

        SetGainMultipliers(C, "ntc_cyberbrain", "neurotraumagain")

        -- If in stasis, end early
        if C:GetBoolStat("stasis") then return end

        local HealingRate = C:GetFloatStat("healingrate")

        -- New NTCS using the base NT formula
        local Gain =
            -0.1 * HealingRate
            + C:GetAfflictionStrength("hypoxemia") / 100
            + NTCS.HF.Clamp(C:GetAfflictionStrength("stroke"), 0, 20) * 0.1
            + C:GetAfflictionStrength("sepsis") / 100 * 0.4
            + C:GetAfflictionStrength("liverdamage") / 800
            + C:GetAfflictionStrength("kidneydamage") / 1000
            + C:GetAfflictionStrength("traumaticshock") / 100

        local CyberOrganQuality = C:GetAfflictionStrength("ntc_cyberbrain") / 100 -- 0.5 Augmented, 1 Cybernetic

        local HealingByMannitol = 0
        local HealingNatural = 0

        if C:GetAfflictionStrength("hypoxemia") <= 30 and C:GetAfflictionStrength("bloodpressure") >= 70 then
            -- Double healing rate of mannitol (1)
            HealingByMannitol = C:GetAfflictionStrength("afmannitol") / 100
        end

        if Gain < 0 then
            -- Triple natural healing rate if recovering
            HealingNatural = 0.2 * HealingRate
        end

        local Healing = math.max(HealingByMannitol, HealingNatural)

        local CurrentNeurotrauma = C:GetAfflictionStrength("NTCS")
        if CurrentNeurotrauma > 100 then
            -- Unconscious due to NTCS and recovering, so double it again
            Healing = Healing * 2
        end

        C:SetAffliction("NTCS", math.max(0, CurrentNeurotrauma - Healing * CyberOrganQuality * DeltaT))

        -- Coma: triple the natural healing rate once the causes are treated
        local Coma = C:GetAfflictionStrength("coma")
        if Coma > 0 then
            local Character = C.Human
            local ForcedOff = NTCS.NTC.GetSymptomFalse(Character, "triggersym_coma")
            local ComaCaused = NTCS.NTC.GetSymptom(Character, "triggersym_coma")
                or C:GetAfflictionStrength("cardiacarrest") > 1
                or C:GetAfflictionStrength("stroke") > 1
                or C:GetAfflictionStrength("acidosis") > 60

            if ForcedOff or not ComaCaused then
                C:SetAffliction("coma", math.max(0, Coma - 0.4 * CyberOrganQuality * DeltaT))
            end
        end

        -- Extra recovery for other afflictions
        for AfflictionId, Rate in pairs(CyberbrainRecoveryRates) do
            local Change = Rate * CyberOrganQuality * DeltaT
            local Strength = C:GetAfflictionStrength(AfflictionId)

            if Strength > 0.1 then
                -- In the HU
                C:SetAffliction(AfflictionId, math.max(0, Strength - Change))
            elseif NTCS.HF.HasAffliction(C.Human, AfflictionId, 0.1) then
                -- Not in the HU
                NTCS.HF.AddAffliction(C.Human, AfflictionId, -Change)
            end
        end

    end):Build()

AfflictionLoader:Register(CyberneticBrain)

-- Bone Damage adjustments
local function CyberLimbsCount(C)
    local Count = 0
    for _, Type in ipairs(LimbTypes) do
        if NTCS_Cybernetics.HF.LimbIsCyber(C.Human, Type) then
            Count = Count + 1
        end
    end
    return Count
end

-- Actual Override
local BoneDamage = AfflictionBuilder:New("bonedamage"):SetUpdateAction(
    function(C, Identifier, Limb, DeltaT)

        if C:GetBoolStat("stasis") then return end

        local Sepsis = C:GetAfflictionStrength("sepsis")
        local Hypoxemia = C:GetAfflictionStrength("hypoxemia")
        local Radiation = C:GetAfflictionStrength("radiationsickness")
        local Kidney = C:GetAfflictionStrength("kidneydamage")

        local GainMultiplier = NTCS.NTC.GetMultiplier(C.Human, "bonedamagegain")

        local Strength = NTCS.HF.OrganDamageCalc(
			C,
			C:GetAfflictionStrength("bonedamage")
				+ GainMultiplier
					* (Sepsis / 500 + Hypoxemia / 1000 + math.max(Radiation - 25, 0) / 600)
					* DeltaT,
			DeltaT,
			false
		)

        local BoneGrowthCount = C:GetFloatStat("bonegrowthCount")

        if Strength < 90 then
            Strength = Strength - (BoneGrowthCount * 0.3) * DeltaT
        elseif BoneGrowthCount + CyberLimbsCount(C) >= 6 then
            Strength = Strength - 2 * DeltaT
        end

        if Kidney > 70 then
            Strength = Strength + (Kidney - 70) / 30 * 0.15 * DeltaT
        end

        C:SetAffliction("bonedamage", math.max(0, Strength))

    end):Build()

AfflictionLoader:Override(BoneDamage)