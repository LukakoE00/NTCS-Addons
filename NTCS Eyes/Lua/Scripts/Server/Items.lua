local itemLoader = NTCS.ItemFunctionLoader("NTCS_Eyes")

--table to define eye afflictions/items
NTCS_Eyes.EyeProperty = {
	{ type = "vi_human", damage = "dm_human", item = "it_humaneye", biological = true },
	{ type = "vi_cyber", damage = "dm_cyber", item = "it_cybereye", biological = false },
	{ type = "vi_enhanced", damage = "dm_enhanced", item = "it_enhancedeye", biological = true },
	{ type = "vi_plastic", damage = "dm_plastic", item = "it_plasticeye", biological = false },
	{ type = "vi_crawler", damage = "dm_crawler", item = "it_crawlereye", biological = true },
	{ type = "vi_mudraptor", damage = "dm_mudraptor", item = "it_mudraptoreye", biological = true },
	{ type = "vi_hammerhead", damage = "dm_hammerhead", item = "it_hammerheadeye", biological = true },
	{ type = "vi_watcher", damage = "dm_watcher", item = "it_watchereye", biological = true },
	{ type = "vi_husk", damage = "dm_husk", item = "it_huskeye", biological = true },
	{ type = "vi_charybdis", damage = "dm_charybdis", item = "it_charybdiseye", biological = true },
	{ type = "vi_latcher", damage = "dm_latcher", item = "it_latchereye", biological = true },
	{ type = "vi_terror", damage = "dm_terror", item = "it_terroreye", biological = false },
	{ type = "sr_removedeyes", damage = 0, item = "" },
	{ type = "mc_deadeyes", damage = 0, item = "" },
}

NTCS_Eyes.LensProperty = {
	{ affliction = "lt_medical", item = "it_medicallens" },
	{ affliction = "lt_electrical", item = "it_electricallens" },
	{ affliction = "lt_night", item = "it_nightlens" },
	{ affliction = "lt_thermal", item = "it_thermallens" },
}

-- Advanced Retractors
local AdvancedRetractors = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head

	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end

	--check if targetCharacter has head or in surgery
	if
		NTCS.HF.HasAffliction(targetCharacter, "th_amputation")
		or NTCS.HF.HasAffliction(targetCharacter, "sh_amputation")
		or NTCS.HF.HasAfflictionLimb(targetCharacter, "surgeryincision", limb, 1)
	then
		return
	end

	--hold eye lids
	local skillrequired = 25

	--try to close lids first
	if NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid") then
		NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_heldlid", limb, 0, usingCharacter) --remove held lids
		NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_poppedeye", limb, 0, usingCharacter) --remove popped eyes
	else
		--check if surgery can be performed
		if not NTCS.HF.CanPerformSurgeryOn(targetCharacter) then
			return
		end

		--check for skill requirement
		if NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			NTCS.HF.SetAfflictionLimb(
				targetCharacter,
				"sr_heldlid",
				limb,
				1 + NTCS.HF.GetSurgerySkill(usingCharacter) / 2,
				usingCharacter
			) --add removed eyes to patient
		else
			--cause bleeding if fail
			NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limb, math.random(0, 7), usingCharacter)
			if --give eye damage on fail
				NTCS_Eyes.HasEyes(targetCharacter)
			then
				for _, eye in ipairs(NTCS_Eyes.EyeProperty) do
					if NTCS.HF.HasAffliction(targetCharacter, eye.type) then
						NTCS.HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, math.random(0, 3), usingCharacter)
					end
				end
			end
		end
	end
end

itemLoader:Override("advretractors", function (d)
	itemLoader:CallPrevious("advretractors", d)
	AdvancedRetractors(d)
end)

-- Tweezers
local Tweezers = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head

	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not NTCS.HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end
	--check if targetCharacter has eyes
	if not NTCS_Eyes.HasEyes(targetCharacter) then
		return
	end

	--pop eyes out
	if NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid", 99) then
		local skillrequired = 30

		--check for skill requirement
		if NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			NTCS.HF.SetAfflictionLimb(
				targetCharacter,
				"sr_poppedeye",
				limb,
				1 + NTCS.HF.GetSurgerySkill(usingCharacter) / 2,
				usingCharacter
			) --add removed eyes to patient
		else
			--cause bleeding and pain if fail
			NTCS.HF.AddAfflictionLimb(targetCharacter, "severepain", limb, 50, usingCharacter)
			NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limb, math.random(0, 10), usingCharacter)
			if --give eye damage on fail
				NTCS_Eyes.HasEyes(targetCharacter)
			then
				for _, eye in ipairs(NTCS_Eyes.EyeProperty) do
					if NTCS.HF.HasAffliction(targetCharacter, eye.type) then
						NTCS.HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, math.random(0, 5), usingCharacter)
					end
				end
			end
		end
	end
end

itemLoader:Override("tweezers", function (d)
	itemLoader:CallPrevious("tweezers", d)
	Tweezers(d)
end)

-- Needle
local Needle = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not NTCS.HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end
	--check if target has eyes
	if not NTCS_Eyes.HasEyes(targetCharacter) then
		return
	end

	--emulsification
	if
		NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
		and NTCS.HF.HasAffliction(targetCharacter, "sr_corneaincision", 99)
		and not NTCS.HF.HasAffliction(targetCharacter, "sr_poppedeye", 99)
	then
		local skillrequired = 50
		if NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			NTCS.HF.AddAfflictionLimb(
				targetCharacter,
				"sr_emulsification",
				limb,
				1 + NTCS.HF.GetSurgerySkill(usingCharacter) / 2,
				usingCharacter
			) --add emulsification
		else
			if --give eye damage on fail
				NTCS_Eyes.HasEyes(targetCharacter)
			then
				for _, eye in ipairs(NTCS_Eyes.EyeProperty) do
					if NTCS.HF.HasAffliction(targetCharacter, eye.type) then
						NTCS.HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, math.random(0, 7), usingCharacter)
					end
				end
			end
		end
	end
end

itemLoader:Override("needle", function (d)
	itemLoader:CallPrevious("needle", d)
	Needle(d)
end)

-- Eye Scalpel
NTCS_Eyes.EyeScalpel = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head

	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not NTCS.HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--eye removal
	if
		NTCS.HF.HasAffliction(targetCharacter, "sr_poppedeye", 99) and NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
	then
		local skillrequired = 45
		--check for skill requirement
		if NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			--remove dead eye if there is one first
			if NTCS.HF.HasAffliction(targetCharacter, "mc_deadeye") then
				NTCS.HF.SetAfflictionLimb(targetCharacter, "mc_deadeye", limb, 0, usingCharacter) --remove dead eye
				NTCS.HF.AddAfflictionLimb(targetCharacter, "sr_removedeye", limb, 100, usingCharacter) --add removed eye
				return --exit if dead eye is removed
			end
			NTCS_Eyes.GiveEyeItem(targetCharacter, usingCharacter) --give eye items to usingCharacter
			NTCS_Eyes.GiveLensItem(targetCharacter, usingCharacter) --give lens items to usingCharacter
			NTCS_Eyes.NukeEyeAfflictions(targetCharacter) --remove all eye afflictions from patient

			NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_removedeyes", limb, 100, usingCharacter) --add removed eyes to patient
			NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_heldlid", limb, 100, usingCharacter) --revert held lids removal

			--NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_poppedeye", limb, 100, usingCharacter) --revert popped eyes removal // they dont have eyes
		else
			--cause bleeding and pain if fail
			NTCS.HF.AddAfflictionLimb(targetCharacter, "severepain", limb, 100, usingCharacter)
			NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limb, math.random(0, 25), usingCharacter)
			if --give eye damage on fail
				NTCS_Eyes.HasEyes(targetCharacter)
			then
				for _, eye in ipairs(NTCS_Eyes.EyeProperty) do
					if NTCS.HF.HasAffliction(targetCharacter, eye.type) then
						NTCS.HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, math.random(0, 15), usingCharacter)
					end
				end
			end
		end
	end

	--cornea incision
	if
		NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid")
		and not (
			NTCS.HF.HasAffliction(targetCharacter, "sr_poppedeye") or NTCS.HF.HasAffliction(targetCharacter, "sr_removedeyes")
		)
	then
		local skillrequired = 50
		if NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			NTCS.HF.AddAfflictionLimb(
				targetCharacter,
				"sr_corneaincision",
				limb,
				1 + NTCS.HF.GetSurgerySkill(usingCharacter) / 2,
				usingCharacter
			) --add cornea incision
		else
			if --give eye damage on fail
				NTCS_Eyes.HasEyes(targetCharacter)
			then
				for _, eye in ipairs(NTCS_Eyes.EyeProperty) do
					if NTCS.HF.HasAffliction(targetCharacter, eye.type) then
						NTCS.HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, math.random(0, 15))
					end
				end
			end
		end
	end
end

itemLoader:Register("it_scalpel_eye", NTCS_Eyes.EyeScalpel)

-- Laser Surgery Tool
local LaserSurgeryTool = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head
	-- check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	if not NTCS.HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end
	if not NTCS_Eyes.HasEyes(targetCharacter) then
		return
	end
	if NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid", 99) then
		local skillrequired = 80
		if NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			NTCS.HF.AddAfflictionLimb(
				targetCharacter,
				"sr_lasersurgery",
				limb,
				1 + NTCS.HF.GetSurgerySkill(usingCharacter) / 4,
				usingCharacter
			)
		else
			if --give eye damage on fail
				NTCS_Eyes.HasEyes(targetCharacter)
			then
				for _, eye in ipairs(NTCS_Eyes.EyeProperty) do
					if NTCS.HF.HasAffliction(targetCharacter, eye.type) then
						NTCS.HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, math.random(10, 100))
					end
				end
			end
		end
		NTCS.HF.GiveItem(usingCharacter, "misc_sfx_slowlaser")
	end
end

itemLoader:Register("it_lasersurgerytool", LaserSurgeryTool)

-- Organic Lens
local OrganicLens = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not NTCS.HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end
	--check if target has eyes
	if not NTCS_Eyes.HasEyes(targetCharacter) then
		return
	end

	--organic lens application
	if
		NTCS.HF.HasAffliction(targetCharacter, "sr_corneaincision", 99)
		and NTCS.HF.HasAffliction(targetCharacter, "sr_emulsification", 99)
		and NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
		and not NTCS.HF.HasAffliction(targetCharacter, "sr_poppedeye", 99)
	then
		NTCS.HF.SetAfflictionLimb(targetCharacter, "mc_cataract", limb, 0, usingCharacter) --remove cataracts
		NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_emulsification", limb, 0, usingCharacter) --remove emulsification
		NTCS.HF.SetAfflictionLimb(targetCharacter, "sr_corneaincision", limb, 0, usingCharacter) --remove cornea incision

		item.Condition = 0 --remove item
	end
end

itemLoader:Register("it_organiclens", OrganicLens)

-- Eye Connectors
local EyeConnector = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not NTCS.HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--application
	if --check if eye(s) removed, lid open
		(NTCS.HF.HasAffliction(targetCharacter, "sr_removedeyes") or NTCS.HF.HasAffliction(targetCharacter, "sr_removedeye"))
		and NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid")
	then
		local skillrequired = 45
		--check for skill requirement
		if NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			--apply connector
			NTCS.HF.SetAfflictionLimb(
				targetCharacter,
				"sr_eyeconnector",
				limb,
				1 + NTCS.HF.GetSurgerySkill(usingCharacter) / 2,
				usingCharacter
			)
			item.Condition = 0 --remove item
		else --cause pain on fail
			NTCS.HF.AddAfflictionLimb(targetCharacter, "severepain", limb, 10)
		end
	end
end

itemLoader:Register("it_eyeconnector", EyeConnector)

-- Screwdriver
local LensRemoval = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head

	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not NTCS.HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--lens removal
	if
		NTCS.HF.HasAffliction(targetCharacter, "sr_poppedeye", 99) and NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
	then
		local skillrequired = 40
		--check for skill requirement
		if NTCS.HF.GetSkillRequirementMet(usingCharacter, "medical", skillrequired) then
			NTCS_Eyes.GiveLensItem(targetCharacter, usingCharacter)
		else
			--cause bleeding and pain if fail
			NTCS.HF.AddAfflictionLimb(targetCharacter, "severepain", limb, 100, usingCharacter)
			NTCS.HF.AddAfflictionLimb(targetCharacter, "bleeding", limb, math.random(0, 5), usingCharacter)
			if --give eye damage on fail
				NTCS_Eyes.HasEyes(targetCharacter)
			then
				if --give eye damage on fail
					NTCS_Eyes.HasEyes(targetCharacter)
				then
					for _, eye in ipairs(NTCS_Eyes.EyeProperty) do
						if NTCS.HF.HasAffliction(targetCharacter, eye.type) then
							NTCS.HF.AddAfflictionLimb(targetCharacter, eye.damage, limb, math.random(0, 7), usingCharacter)
						end
					end
				end
			end
		end
	end
end

-- Screwdriver + Variants
for _, Identifier in ipairs({ "screwdriver", "screwdriverdementonite", "screwdriverhardened", "repairpack" }) do
	itemLoader:Override(Identifier, function (d)
		itemLoader:CallPrevious(Identifier, d)
		LensRemoval(d)
	end)
end

-- FPGA Circuit
local FPGACircuit = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head

	-- check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end

	-- check if surgery can be performed
	if not NTCS.HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	-- check if target has held lid, popped eye, cyber eye
	if
		NTCS.HF.HasAffliction(targetCharacter, "vi_cyber")
		and (
			NTCS.HF.HasAffliction(targetCharacter, "sr_heldlid", 99)
			and NTCS.HF.HasAffliction(targetCharacter, "sr_poppedeye", 99)
		)
	then
		if --if target has 1 cyber eye
			NTCS.HF.HasAffliction(targetCharacter, "sr_removedeye")
			or NTCS.HF.HasAffliction(targetCharacter, "mc_deadeye")
			or NTCS.HF.HasAffliction(targetCharacter, "mc_mismatch")
		then
			NTCS.HF.AddAffliction(targetCharacter, "dm_cyber", -(item.Condition / 2.5), usingCharacter) --reduce eye damage
			item.Condition = 0 --remove item
		else --if target has 2 cyber eyes
			NTCS.HF.AddAffliction(targetCharacter, "dm_cyber", -(item.Condition / 5), usingCharacter) --reduce eye damage
			--changing these from AddAfflictionLimb to AddAffliction fixes the issue, idk why, and I am too tired to care
			item.Condition = 0 --remove item
		end
	end
end

itemLoader:Override("fpgacircuit", function (d)
	itemLoader:CallPrevious("fpgacircuit", d)
	FPGACircuit(d)
end)

-- Eye Implants (human, plastic, enhanced, cyber, crawler, mudraptor, hammerhead, husk, watcher, latcher, terror)
local EyeImplant = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= limb then
		return
	end
	--check if surgery can be performed
	if not NTCS.HF.CanPerformSurgeryOn(targetCharacter) then
		return
	end

	--give eye affliction
	NTCS_Eyes.ApplyEyeItem(targetCharacter, usingCharacter, item)
end

--human eye
itemLoader:Register("it_humaneye", EyeImplant)
--plastic eye
itemLoader:Register("it_plasticeye", EyeImplant)
--enhanced eye
itemLoader:Register("it_enhancedeye", EyeImplant)
--cyber eye
itemLoader:Register("it_cybereye", EyeImplant)
--crawler eye
itemLoader:Register("it_crawlereye", EyeImplant)
--mudraptor eye
itemLoader:Register("it_mudraptoreye", EyeImplant)
--hammerhead eye
itemLoader:Register("it_hammerheadeye", EyeImplant)
--huskified eye
itemLoader:Register("it_huskeye", EyeImplant)
--watcher eye
itemLoader:Register("it_watchereye", EyeImplant)
--charybdis eye
--itemLoader:Register("it_charybdiseye", EyeImplant)
--latcher eye
itemLoader:Register("it_latchereye", EyeImplant)
--terror eye
itemLoader:Register("it_terroreye", EyeImplant)

-- ==================== Lenses ====================
-- Lens Implants (medical, electrical, night, thermal)
local LensImplant = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head
	NTCS_Eyes.ApplyLensItem(targetCharacter, usingCharacter, item)
end

--medical lens
itemLoader:Register("it_medicallens", LensImplant)
--electrical lens
itemLoader:Register("it_electricallens", LensImplant)
--nightvision lens
itemLoader:Register("it_nightlens", LensImplant)
--thermal lens
itemLoader:Register("it_thermallens", LensImplant)

-- Eye Drop
local EyeDrop = function (d)

	local item = d.item
	local usingCharacter = d.user.Human
	local targetCharacter = d.target.Human
	local targetLimb = d.targetLimb

	local limb = LimbType.Head
	--check if the item is used on the head
	if targetLimb.type ~= LimbType.Head then
		return
	end
	--check if character has eyes
	if not NTCS_Eyes.HasEyes(targetCharacter) then
		return
	end
	--give affliction if able
	if not NTCS.HF.HasAffliction(targetCharacter, "vi_cyber") and not NTCS.HF.HasAffliction(targetCharacter, "vi_plastic") then
		NTCS.HF.AddAfflictionLimb(targetCharacter, "sr_eyedrops", limb, 100)
		item.Condition = item.Condition - 25 --remove item condition
	end
end

itemLoader:Register("it_eyedrop", EyeDrop)