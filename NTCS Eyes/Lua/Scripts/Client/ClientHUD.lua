--variables to set HUD values
NTCS_Eyes.HUDEnabled = false
NTCS_Eyes.DrawnHUD = nil
NTCS_Eyes.DisableHoverTextHUD = false

-- there will be a table this time instead of individual variables
NTCS_Eyes.HUDValues = {
	thermal = {
		active = false,
		item = nil,
		itemPrefab = "misc_thermalhud",
		affliction = "lt_thermal",
	},
	medical = {
		active = false,
		item = nil,
		itemPrefab = "misc_medicalhud",
		affliction = "lt_medical",
	},
	electrical = {
		active = false,
		item = nil,
		itemPrefab = "misc_electricalhud",
		affliction = "lt_electrical",
	},
}

function NTCS_Eyes.WriteHUD()
	local hudFound = false
	--check if the player has enabled the HUD
	if not NTCS_Eyes.HUDEnabled then
		NTCS_Eyes.DisableHUDs()
		return
	end
	--check if the player has any of the lens afflictions
	for _, hud in pairs(NTCS_Eyes.HUDValues) do
		if NTCS.HF.HasAffliction(Character.Controlled, hud.affliction) then
			hudFound = true
			if NTCS_Eyes.DrawnHUD == nil then
				if hud.item == nil or hud.item.Removed then
					NTCS_Eyes.ResetHUDValues()
					NTCS_Eyes.GetHUDItemValues()
					NTCS_Eyes.SendItemSpawnRequest()
					return
				end
				hud.active = true
				hud.item.Equip(Character.Controlled)
				NTCS_Eyes.DrawnHUD = hud.item.GetComponentString("StatusHUD") --get hud component
				NTCS_Eyes.HUDEnabled = true

				--check to disable hover text if medical hud
				if hud.affliction == "lt_medical" then
					NTCS_Eyes.DisableHoverTextHUD = true
				end

				hudFound = true
			end
		end
	end
	if not hudFound then
		NTCS_Eyes.DisableHUDs() --if you implement multiple huds at the same time this will cause issues
	end
end

--get the item values for the HUDs
function NTCS_Eyes.GetHUDItemValues()
	for item in Item.ItemList do
		for _, hud in pairs(NTCS_Eyes.HUDValues) do
			if item.Prefab.Identifier == hud.itemPrefab then
				hud.item = item
			end
		end
	end
end

function NTCS_Eyes.DisableHUDs()
	for _, hud in pairs(NTCS_Eyes.HUDValues) do
		if hud.active then
			if hud.item then
				hud.item.Unequip(Character.Controlled)
			end
			hud.active = false
			if hud.affliction == "lt_medical" then
				NTCS_Eyes.DisableHoverTextHUD = false
			end
			NTCS_Eyes.DrawnHUD = nil
			--NTCS_Eyes.HUDEnabled = false
		end
	end
end

--sends a request for HUD items to spawn in case lua fucks up
function NTCS_Eyes.SendItemSpawnRequest()
	if not Game.IsMultiplayer then
		NTCS_Eyes.SpawnHUDItems()
		return
	end --singleplayer comp

	local message = Networking.Start("NTCS_Eyes.ItemSpawnRequest")

	message.WriteString("")

	Networking.Send(message)
end

--resets HUD values to prevent bugs
function NTCS_Eyes.ResetHUDValues()
	for _, hud in pairs(NTCS_Eyes.HUDValues) do
		hud.active = false
		hud.item = nil
		NTCS_Eyes.DrawnHUD = nil
		NTCS_Eyes.HUDEnabled = false
		NTCS_Eyes.DisableHoverTextHUD = false
	end
end

--resets hud parameters for client when character changes (for MCM and singleplayer)
Hook.Patch("Barotrauma.Character", "set_Controlled", function(instance, ptable)
	--disables all HUDs
	for _, hud in pairs(NTCS_Eyes.HUDValues) do
		hud.active = false
	end
	--sets the global variable to false
	NTCS_Eyes.HUDEnabled = false
	NTCS_Eyes.DrawnHUD = nil

	NTCS_Eyes.DisableHoverTextHUD = false
end)

--deletes duplicate player text from medical hud
Hook.Patch("Barotrauma.CharacterHUD", "DrawCharacterHoverTexts", function(instance, ptable)
	ptable.PreventExecution = NTCS_Eyes.DisableHoverTextHUD
	return nil
end, Hook.HookMethodType.Before)

--draws the written eye huds
Hook.Patch("Barotrauma.CharacterHUD", "Draw", function(instance, ptable)
	if NTCS_Eyes.DrawnHUD == nil then
		return
	end

	NTCS_Eyes.DrawnHUD.DrawHUD(ptable["spriteBatch"], Character.Controlled) --draws the huds
end)
