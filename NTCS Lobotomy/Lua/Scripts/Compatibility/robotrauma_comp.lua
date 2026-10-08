-- DISABLED FOR NOW

function NTCS_Lobotomy.Robot(targetCharacter) --check for robots
	if not (targetCharacter.IsFemale or targetCharacter.IsMale) then return true end
end