local itemLoader = NTCS.ItemFunctionLoader("NTCS_Eyes")

local function GetMultiscalpelMode(item)
	local tags = item.Tags
	if tags == nil or tags == "" then return "" end

	for tag in string.gmatch(tags, "[^,]+") do
		tag = tag:match("^%s*(.-)%s*$")
		if string.sub(tag, 1, 13) == "multiscalpel_" then
			return string.sub(tag, 14)
		end
	end
	return ""
end

-- Hook to switch the multiscalpel to eye mode
-- SetMultiscalpelFunction is public static in C#, so we try to call it directly.
LuaUserData.RegisterType("Neurotrauma.NTMultiscalpel")
local NTMultiscalpel = LuaUserData.CreateStatic("Neurotrauma.NTMultiscalpel")

Hook.Add("NT.multiscalpel.eye", "NTCS.multiscalpel.eye", function(effect, deltaTime, item, targets, worldPosition)
	NTMultiscalpel.SetMultiscalpelFunction(item, "eye")
end)

-- Multiscalpel
local Multiscalpel = function (d)

	local item = d.item
	local limbtype = NTCS.HF.NormalizeLimbType(d.targetLimb.type)
	local mode = GetMultiscalpelMode(item)

	if mode == "eye" then
		NTCS_Eyes.EyeScalpel(d)

		-- C# resets the tag after use, so do the same for the eye mode
		Timer.Wait(function()
			item.Tags = "multiscalpel_eye"
		end, 50)
		return
	end

	-- Speedflex on the head: the C# side runs the brain scalpel, we add the eye scalpel
	if mode == "speedflex" and limbtype == LimbType.Head then
		itemLoader:CallOld("multiscalpel", "Neurotrauma C#", d)
		NTCS_Eyes.EyeScalpel(d)
		return
	end

	-- Everything else is unchanged
	itemLoader:CallOld("multiscalpel", "Neurotrauma C#", d)
end

itemLoader:Override("multiscalpel", Multiscalpel)