local itemLoader = NTCS.ItemFunctionLoader(NTCS_Lobotomy.Name)

itemLoader:Register("orbitoclast", function (d)

    local item = d.item
    local usingCharacter = d.user
    local targetCharacter = d.target
    local targetLimb = d.targetLimb

    -- Not usable in stasis
    if targetCharacter:GetBoolStat("stasis", false) then return end

    -- Only usable on the head
    if targetLimb.type ~= LimbType.Head then return end

    -- Not usable if already there
    if targetCharacter:HasAffliction("orbitoclastready") then return end

    if --skill check
        not NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter.Human, 60)
    then
        targetCharacter:AddAfflictionLimb("severepainlite", targetLimb.type, 5)
        targetCharacter:AddAfflictionLimb("pain_extremity", targetLimb.type, 100)

        targetCharacter:AddAfflictionLimb("bleeding", targetLimb.type, math.random(1,20))
        
        if NTCS.isAddonRegistered("Eyes") then NTCS_Lobotomy.DealEyeDamage(targetCharacter, math.random(1,20)) end
    end
    
    
    targetCharacter:AddAfflictionLimb("orbitoclastready", targetLimb.type, 1+NTCS.HF.GetSurgerySkill(usingCharacter.Human)/2)
    Entity.Spawner.AddItemToRemoveQueue(item) --despawn item as it is inside the patients skull
    
    NTCS.HF.GiveItem(targetCharacter.Human, "lobosfx_orbitoclast") --sfx

end)

itemLoader:Register("surgicalhammer", function (d)

    local item = d.item
    local usingCharacter = d.user
    local targetCharacter = d.target
    local targetLimb = d.targetLimb

    -- Not usable in stasis
    if targetCharacter:GetBoolStat("stasis", false) then return end

    -- Only usable on the head
    if targetLimb.type ~= LimbType.Head then return end

    if not targetCharacter:HasAffliction("orbitoclastready") or targetCharacter:HasAffliction("orbitoclastspin") then return end

    if --Cause pain if not anesthesia
        not NTCS.HF.CanPerformSurgeryOn(targetCharacter.Human)
    then
        targetCharacter:AddAfflictionLimb("severepainlite", targetLimb.type, 5)
        targetCharacter:AddAfflictionLimb("pain_extremity", targetLimb.type, 100)
    end

    if --skill check
			not NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter.Human, 60)
    then
        targetCharacter:AddAfflictionLimb("severepainlite", targetLimb.type, 5)
        targetCharacter:AddAfflictionLimb("pain_extremity", targetLimb.type, 100)
        
        targetCharacter:AddAfflictionLimb("bleeding", targetLimb.type, math.random(1,10))
        
        targetCharacter:AddAfflictionLimb("failedlobotomy", targetLimb.type, 2)
        
        if NTCS.isAddonRegistered("Eyes") then NTCS_Lobotomy.DealEyeDamage(targetCharacter, math.random(10,20)) end
    end
		

    targetCharacter:AddAfflictionLimb("orbitoclastspin", targetLimb.type, 1+NTCS.HF.GetSurgerySkill(usingCharacter.Human)/2,usingCharacter.Human)
    NTCS.HF.GiveItem(usingCharacter.Human,"orbitoclast") --give back orbitoclast
    
    NTCS.HF.GiveItem(targetCharacter.Human, "lobosfx_lobotomy") --sfx
    
end)

itemLoader:Override("advretractors", function (d)
    
    local item = d.item
    local usingCharacter = d.user
    local targetCharacter = d.target
    local targetLimb = d.targetLimb

    -- Not usable in stasis
    if targetCharacter:GetBoolStat("stasis", false) then goto jmp end

    -- Only usable on the head
    if targetLimb.type ~= LimbType.Head then goto jmp end

    if not targetCharacter:HasAffliction("orbitoclastready") or targetCharacter:HasAffliction("orbitoclastspin") then goto jmp end

    NTCS.HF.GiveItem(usingCharacter.Human,"orbitoclast") --give back orbitoclast
    NTCS.HF.GiveItem(targetCharacter.Human, "lobosfx_orbitoclast") --sfx
    targetCharacter.Human.CharacterHealth.ReduceAfflictionOnAllLimbs("orbitoclastready", 1000) --remove affliction

    ::jmp::
    itemLoader:CallOld("advretractors", "Neurotrauma C#", d)

end)

itemLoader:Register("ethanol", function (d)

    local item = d.item
    local usingCharacter = d.user
    local targetCharacter = d.target
    local targetLimb = d.targetLimb

    -- Not usable in stasis
    if targetCharacter:GetBoolStat("stasis", false) then return end

    -- Only usable on the head
    if targetLimb.type ~= LimbType.Head then return end

    if not targetCharacter:HasAffliction("drilledbones") or targetCharacter:HasAffliction("ethanollobotomy") then return end

    if --skill check
        not NTCS.HF.GetSurgerySkillRequirementMet(usingCharacter.Human, 45)
    then
        targetCharacter:AddAfflictionLimb("failedlobotomy", LimbType.Head, 2)
    end

    targetCharacter:AddAfflictionLimb("ethanollobotomy", LimbType.Head, 1+NTCS.HF.GetSurgerySkill(usingCharacter.Human)/2, usingCharacter.Human)
    Entity.Spawner.AddItemToRemoveQueue(item)

    NTCS.HF.GiveItem(targetCharacter.Human, "lobosfx_ethanollobotomy")

end)

--lobotomy tables
GoodLobotomyAfflictions = {
	"lobo_genius", "lobo_veryfast", "lobo_notrauma", "lobo_nopsychosis", "lobo_nostun", "lobo_nopain", "lobo_noneurotrauma",
	"lobo_nodrunk"
}	

BadLobotomyAfflictions = {
	"lobo_infinitepsychosis", "lobo_mute", "lobo_blurredvision", "lobo_ungenius", "lobo_alwaysdrunk", "lobo_hearscreams", "lobo_tinnitus",
	"lobo_screenshake", "lobo_deaf", "lobo_blind", "lobo_constantpain", "lobo_paralysis", "lobo_invertcontrols", "lobo_nausea", "lobo_alwaysvigorous",
	"lobo_alwaysjolly", "lobo_differentteam", "lobo_veryslow", "lobo_alwaysrun", "lobo_alwayswalk", "lobo_randomarrest", "lobo_makescreams", "lobo_fart", "lobo_randomuncon",
	"lobo_noanalgesia", "lobo_durden", "lobo_hearvoices"
	
}

    --lobotomy
Hook.Add("lobotomize", function(effect, deltaTime, item, targets, worldPosition, element)

	for k, targetCharacter in pairs(targets) do
		if 
			NTCS.HF.HasAffliction(targetCharacter, "orbitoclastspin", 90)
			or NTCS.HF.HasAffliction(targetCharacter, "ethanollobotomy", 90)
		then
			if --ethanol lobotomy has 5% more chance to yield good results
				NTCS.HF.HasAffliction(targetCharacter, "ethanollobotomy", 90) 
			then
				NTCS_Lobotomy.ApplyLobotomy(targetCharacter, nil, 0.20)
			else
				NTCS_Lobotomy.ApplyLobotomy(targetCharacter, nil, 0.15)
			end
				
			targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs("orbitoclastspin", 1000)
			targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs("orbitoclastready", 1000)
			
			targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs("ethanollobotomy", 1000)
		end
	end

end)

--nerve regen
Hook.Add("nerveregen", function(effect, deltaTime, item, targets, worldPosition, element)

	for k, targetCharacter in pairs(targets) do
		if --remove lobotomy
			NTCS.HF.HasAffliction(targetCharacter, "nervegeneration", 98)
		then
			if
				not NTCS.HF.HasAffliction(targetCharacter, "lobotomy")
			then
				NTCS.HF.AddAfflictionLimb(targetCharacter, "lobo_nervedeathdelay", 11, 2)
			end
			
			targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs("nervegeneration", 1000)
			
			targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs("lobotomy", 1000)
			
			targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs("failedlobotomy", 1000) --failsafe incase something fucks up
			
			targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs("lobotomydeath", 1000) --cure death if they have the skill I suppose
			
			for RemoveGoodLobotomy in GoodLobotomyAfflictions do
				targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs(RemoveGoodLobotomy, 1000)
			end
			
			for RemoveBadLobotomy in BadLobotomyAfflictions do
				targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs(RemoveBadLobotomy, 1000)
			end
		end
	end

end)


--lobotomize
function NTCS_Lobotomy.ApplyLobotomy(targetCharacter, prevresult, prevchance)
	local result=prevresult --in case result want to be determined beforehand
	local chance=prevchance
	
	if chance==nil then chance=0.15 end
	
	if --check for surgery fail, halve the chance
		NTCS.HF.HasAffliction(targetCharacter, "failedlobotomy")
	then
		chance=0.07
		
		NTCS.HF.AddAfflictionLimb(targetCharacter, "cerebralhypoxia", 11, math.random(0,50))
		targetCharacter.CharacterHealth.ReduceAfflictionOnAllLimbs("failedlobotomy", 1000)
	end
	
	if --determine result if not already determined
		result==nil 
	then
		if 
			NTCS.HF.Chance(chance)
		then
			result="good"
		else
			result="bad"
		end
	end

	
	local BadLobotomy = BadLobotomyAfflictions[ math.random( #BadLobotomyAfflictions ) ]
	local GoodLobotomy = GoodLobotomyAfflictions[ math.random( #GoodLobotomyAfflictions ) ]
	

	if --give lobotomy
		result=="bad"
	then
		NTCS.HF.AddAfflictionLimb(targetCharacter, BadLobotomy, 11, 3)
		--print(BadLobotomy)
	else
		NTCS.HF.AddAfflictionLimb(targetCharacter, GoodLobotomy, 11, 3)
		--print(GoodLobotomy)
	end
		
		
	NTCS.HF.AddAfflictionLimb(targetCharacter, "lobotomy", 11, 1) --add progress after lobotomy
	
	if --chance of death from lobotomy
		NTCS.HF.GetAfflictionStrength(targetCharacter, "lobotomy") <= 5
	then
		if
			NTCS.HF.Chance( NTCS.HF.GetAfflictionStrength(targetCharacter, "lobotomy")*0.06 )
		then
			NTCS.HF.AddAfflictionLimb(targetCharacter, "lobotomydeath", 11, 3)
		end
	else
		if --scales up after 5 lobotomies
			NTCS.HF.Chance( NTCS.HF.GetAfflictionStrength(targetCharacter, "lobotomy")*0.099 )
		then
			NTCS.HF.AddAfflictionLimb(targetCharacter, "lobotomydeath", 11, 3)
		end
	end
	
	
end