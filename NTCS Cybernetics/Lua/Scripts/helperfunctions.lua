-- This file contains a bunch of useful functions that see heavy use in the other scripts.
NTCS_Cybernetics.HF = {} -- Helperfunctions

function NTCS_Cybernetics.HF.LimbIsCyber(character, limbtype)
	return NTCS.HF.HasAfflictionLimb(character, "ntc_cyberlimb", NTCS.HF.NormalizeLimbType(limbtype), 0.1)
end

function NTCS_Cybernetics.UncyberifyLimb(character, limbtype)
	limbtype = NTCS.HF.NormalizeLimbType(limbtype)

	NTCS.HF.SetAfflictionLimb(character, "ntc_cyberlimb", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "ntc_cyberarm", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "ntc_cyberleg", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "ntc_legspeed", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "ntc_armspeed", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "ntc_waterproof", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "ntc_loosescrews", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "ntc_damagedelectronics", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "ntc_bentmetal", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "ntc_materialloss", limbtype, 0)

	if limbtype == LimbType.RightArm then
		NTCS.HF.SetAffliction(character, "ra_cyber", 0)
	elseif limbtype == LimbType.LeftArm then
		NTCS.HF.SetAffliction(character, "la_cyber", 0)
	elseif limbtype == LimbType.RightLeg then
		NTCS.HF.SetAffliction(character, "rl_cyber", 0)
	elseif limbtype == LimbType.LeftLeg then
		NTCS.HF.SetAffliction(character, "ll_cyber", 0)
	end
end

function NTCS_Cybernetics.CyberifyLimb(character, limbtype, iswaterproof)
	if limbtype == LimbType.RightArm then
		NTCS.HF.SetAffliction(character, "ra_cyber", 100)
		NTCS.HF.SetAfflictionLimb(character, "ntc_cyberarm", limbtype, 100)
		NTCS.HF.SetAfflictionLimb(character, "ntc_armspeed", limbtype, 100 * NTConfig.Get("NTCS_Cybernetics_cyberarmSpeed", 1))
		if iswaterproof == true then NTCS.HF.SetAfflictionLimb(character, "ntc_waterproof", limbtype, 100) end
	elseif limbtype == LimbType.LeftArm then
		NTCS.HF.SetAffliction(character, "la_cyber", 100)
		NTCS.HF.SetAfflictionLimb(character, "ntc_cyberarm", limbtype, 100)
		NTCS.HF.SetAfflictionLimb(character, "ntc_armspeed", limbtype, 100 * NTConfig.Get("NTCS_Cybernetics_cyberarmSpeed", 1))
		if iswaterproof == true then NTCS.HF.SetAfflictionLimb(character, "ntc_waterproof", limbtype, 100) end
	elseif limbtype == LimbType.RightLeg then
		NTCS.HF.SetAffliction(character, "rl_cyber", 100)
		NTCS.HF.SetAfflictionLimb(character, "ntc_cyberleg", limbtype, 100)
		NTCS.HF.SetAfflictionLimb(character, "ntc_legspeed", limbtype, 100 * NTConfig.Get("NTCS_Cybernetics_cyberlegSpeed", 1))
		if iswaterproof == true then NTCS.HF.SetAfflictionLimb(character, "ntc_waterproof", limbtype, 100) end
	elseif limbtype == LimbType.LeftLeg then
		NTCS.HF.SetAffliction(character, "ll_cyber", 100)
		NTCS.HF.SetAfflictionLimb(character, "ntc_cyberleg", limbtype, 100)
		NTCS.HF.SetAfflictionLimb(character, "ntc_legspeed", limbtype, 100 * NTConfig.Get("NTCS_Cybernetics_cyberlegSpeed", 1))
		if iswaterproof == true then NTCS.HF.SetAfflictionLimb(character, "ntc_waterproof", limbtype, 100) end
	end

	-- get rid of all the flesh-only stuff

	NT.ArteryCutLimb(character, limbtype, -1000)
	NT.BreakLimb(character, limbtype, -1000)
	NT.DislocateLimb(character, limbtype, -1000)
	NT.SurgicallyAmputateLimb(character, limbtype, 0, 0)

	NTCS.HF.SetAfflictionLimb(character, "arteriesclamp", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "surgeryincision", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "clampedbleeders", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "drilledbones", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "retractedskin", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "suturedi", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "suturedw", limbtype, 0)

	NTCS.HF.SetAfflictionLimb(character, "internaldamage", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "burn", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "gunshotwound", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "bitewounds", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "explosiondamage", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "bleeding", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "lacerations", limbtype, 0)
	NTCS.HF.SetAfflictionLimb(character, "blunttrauma", limbtype, 0)

	NTCS.HF.SetAfflictionLimb(character, "bonecut", limbtype, 0)

	-- do the thing

	NTCS.HF.SetAfflictionLimb(character, "ntc_cyberlimb", limbtype, 100)
end

NTCS_Cybernetics.HF.GetAllCyberDamages = function(targetCharacter, limbtype)
	return {
		ntc_bentmetal = NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "ntc_bentmetal", 0),
		ntc_materialloss = NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "ntc_materialloss", 0),
		ntc_damagedelectronics = NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "ntc_damagedelectronics", 0),
		ntc_loosescrews = NTCS.HF.GetAfflictionStrengthLimb(targetCharacter, limbtype, "ntc_loosescrews", 0),
	}
end

NTCS_Cybernetics.HF.SetAllCyberDamages = function(targetCharacter, limbtype, oldCyberDamages)
	for damageType, damageAmount in pairs(oldCyberDamages) do
		NTCS.HF.SetAfflictionLimb(targetCharacter, damageType, limbtype, damageAmount)
	end
end