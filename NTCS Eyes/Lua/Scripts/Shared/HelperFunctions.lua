--define helper functions
--checks if targetCharacter has eyes
function NTCS_Eyes.HasEyes(targetCharacter)
	return not NTCS.HF.HasAffliction(targetCharacter, "sr_removedeyes")
		and not NTCS.HF.HasAffliction(targetCharacter, "th_amputation")
		and not NTCS.HF.HasAffliction(targetCharacter, "sh_amputation")
end

-- All eye afflictions, used to wipe everything when the eyes are removed
local EyeAfflictionIds = {
	-- Surgery
	"sr_removedeyes", 
	"sr_removedeye", 
	"sr_heldlid", 
	"sr_poppedeye", 
	"sr_eyeconnector",
	"sr_corneaincision", 
	"sr_emulsification", 
	"sr_eyedrops", 
	"sr_lasersurgery",

	-- Mechanical
	"mc_deadeyes",
	"mc_deadeye",
	"mc_retinopathy", 
	"mc_pinkeye",
	"mc_cataract", 
	"mc_visionsickness", 
	"mc_mismatch",

	-- Eye damage
	"dm_human", 
	"dm_cyber", 
	"dm_enhanced", 
	"dm_plastic", 
	"dm_crawler", 
	"dm_mudraptor",
	"dm_hammerhead", 
	"dm_watcher", 
	"dm_husk", 
	"dm_latcher", 
	"dm_terror",

	-- Lenses
	"lt_medical", 
	"lt_electrical", 
	"lt_night", 
	"lt_thermal",

	-- Visual indicators
	"vi_human", 
	"vi_cyber", 
	"vi_enhanced", 
	"vi_plastic",
	"vi_crawler", 
	"vi_mudraptor",
	"vi_hammerhead", 
	"vi_watcher", 
	"vi_husk", 
	"vi_latcher", 
	"vi_terror",
}

function NTCS_Eyes.NukeEyeAfflictions(targetCharacter)
	for _, afflictionName in ipairs(EyeAfflictionIds) do
		targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs(afflictionName, 1000)
	end
end

--gives item based on the eye affliction
function NTCS_Eyes.GiveEyeItem(targetCharacter, usingCharacter)
	if not NTCS_Eyes.HasEyes(targetCharacter) then
		return
	end

	for _, eye in ipairs(NTCS_Eyes.EyeProperty) do
		if NTCS.HF.HasAffliction(targetCharacter, eye.type) then
			if eye.damage ~= nil then
				local afflictionDamage = NTCS.HF.GetAfflictionStrength(targetCharacter, eye.damage, 0)
				if
					NTCS.HF.HasAffliction(targetCharacter, "sr_removedeye")
					or NTCS.HF.HasAffliction(targetCharacter, "mc_deadeye")
					or NTCS.HF.HasAffliction(targetCharacter, "mc_mismatch")
				then
					if (usingCharacter ~= nil) and (eye.item ~= "") then
						--give one item
						NTCS.HF.GiveItem(usingCharacter, eye.item, (100 - afflictionDamage * 2))
					end
				else
					if (usingCharacter ~= nil) and (eye.item ~= "") then
						--give two items
						NTCS.HF.GiveItem(usingCharacter, eye.item, (100 - afflictionDamage))
						NTCS.HF.GiveItem(usingCharacter, eye.item, (100 - afflictionDamage))
					end
				end
			end
		end
	end
end

--gives eye affliction based on item
function NTCS_Eyes.ApplyEyeItem(targetCharacter, usingCharacter, item)
	local limb = LimbType.Head

	--eye application
	if --check if eye(s) removed, lid open
		(NTCS.HF.HasAffliction(targetCharacter, "sr_removedeyes") or NTCS.HF.HasAffliction(targetCharacter, "sr_removedeye"))
		and NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
		and NTCS.HF.HasAffliction(targetCharacter, "sr_eyeconnector", 99)
	then
		local skillrequired = 45

		--check for skill requirement
		if NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			for _, eye in ipairs(NTCS_Eyes.EyeProperty) do
				--check if right property in the table is selected
				if (item.Prefab.Identifier == eye.item) and not (item.Prefab.Identifier == "") then
					--get eye damage affliction strength
					local strength = (100 - item.Condition) / 2

					--check how many eyes target has
					--if one eye removed:
					if NTCS.HF.HasAffliction(targetCharacter, "sr_removedeye") then
						--add single eye
						--check if eye affliction matches the item
						if NTCS.HF.HasAffliction(targetCharacter, eye.type) then
							NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_removedeye", limb, 0, usingCharacter) --remove eye affliction
							NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_eyeconnector", limb, 0, usingCharacter) --remove eye connector affliction
							NTCS.HF.SetAfflictionLimb(targetCharacter, "mc_mismatch", limb, 0, usingCharacter) --remove mismatch affliction

							NTCS.HF.SetAfflictionLimb(targetCharacter, eye.type, limb, 100, usingCharacter) --add eye indicator affliction
							NTCS.HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, strength, usingCharacter) --add eye damage affliction

							NTCS.HF.AddAfflictionLimb(targetCharacter, "mc_visionsickness", limb, 50, usingCharacter) --add vision sickness
							item.Condition = 0 --remove item
						else --if it doesn't; add eye+mismatch
							NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_removedeye", limb, 0, usingCharacter) --remove eye affliction
							NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_eyeconnector", limb, 0, usingCharacter) --remove eye connector affliction

							NTCS.HF.SetAfflictionLimb(targetCharacter, "mc_mismatch", limb, 100, usingCharacter) --add mismatch affliction
							NTCS.HF.SetAfflictionLimb(targetCharacter, eye.type, limb, 100, usingCharacter) --add eye affliction
							NTCS.HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, strength, usingCharacter) --add eye damage affliction

							NTCS.HF.AddAfflictionLimb(targetCharacter, "mc_visionsickness", limb, 50, usingCharacter) --add vision sickness
							item.Condition = 0 --remove item
						end
					else --if two eyes removed, add one eye
						if NTCS.HF.HasAffliction(targetCharacter, "sr_removedeyes") then
							--add double eye
							NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_removedeyes", limb, 0, usingCharacter) --remove eye affliction
							NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_eyeconnector", limb, 0, usingCharacter) --remove eye connector affliction
							NTCS.HF.SetAfflictionLimb(targetCharacter, "mc_mismatch", limb, 0, usingCharacter) --remove mismatch affliction

							NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_removedeye", limb, 100, usingCharacter) --add eye affliction
							NTCS.HF.SetAfflictionLimb(targetCharacter, eye.type, limb, 100, usingCharacter) --add eye affliction
							NTCS.HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, strength, usingCharacter) --add eye damage affliction

							NTCS.HF.AddAfflictionLimb(targetCharacter, "mc_visionsickness", limb, 100, usingCharacter) --add vision sickness
							item.Condition = 0 --remove item
						end
					end
				end
			end
		else
			item.Condition = item.Condition - 5 --damage eye item on fail
		end
	end
end

--gives lens item based on affliction
function NTCS_Eyes.GiveLensItem(targetCharacter, usingCharacter)
	local limb = LimbType.Head
	for _, lens in ipairs(NTCS_Eyes.LensProperty) do
		if NTCS.HF.HasAffliction(targetCharacter, lens.affliction) then
			NTCS.HF.GiveItem(usingCharacter, lens.item, 100)
		end
		NTCS.HF.SetAfflictionLimb(targetCharacter, lens.affliction, limb, 0, usingCharacter)
	end
end

--gives lens affliction based on item
function NTCS_Eyes.ApplyLensItem(targetCharacter, usingCharacter, item)
	local limb = LimbType.Head

	--lens application
	if --check if correct eyes are present, no mismatch, lid open, eyes popped
		NTCS_Eyes.HasEyes(targetCharacter)
		and (NTCS.HF.HasAffliction(targetCharacter, "vi_cyber") or NTCS.HF.HasAffliction(targetCharacter, "vi_enhanced"))
		--and (not HF.HasAffliction(targetCharacter, "mc_mismatch")) --not sure if I should keep this or not
		and (
			NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
			and NTCS.HF.HasAffliction(targetCharacter, "sr_poppedeye", 99)
		)
	then
		for _, lens in ipairs(NTCS_Eyes.LensProperty) do
			--check if a lens is present, return if so
			if NTCS.HF.HasAffliction(targetCharacter, lens.affliction) then
				return
			end
		end

		for _, lens in ipairs(NTCS_Eyes.LensProperty) do
			--check if right property is selected
			if item.Prefab.Identifier == lens.item then
				NTCS.HF.SetAfflictionLimb(targetCharacter, lens.affliction, limb, 100, usingCharacter)
				item.Condition = 0
			end
		end
	end
end