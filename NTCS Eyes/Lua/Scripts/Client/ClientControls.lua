--key to activate lenses (make this configurable)
NTCS_Eyes.LensActivationKey = Keys.F

--Medical Scanner key (make this configurable)
NTCS_Eyes.MedicalScannerKey = Keys.F

--this enables recognition of selected limb in health UI
LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.CharacterHealth"], "selectedLimbIndex")

--I dont recall what this does, probably enable keyboard input
Hook.HookMethod("Barotrauma.Character", "ControlLocalPlayer", function(instance, ptable)
	NTCS_Eyes.MedicalLensScanner()
	NTCS_Eyes.HudToggle()
end, Hook.HookMethodType.After)

--function to enable/disable HUD
function NTCS_Eyes.HudToggle()
	for _, hud in pairs(NTCS_Eyes.HUDValues) do
		if NTCS.HF.HasAffliction(Character.Controlled, hud.affliction) and not CharacterHealth.OpenHealthWindow then
			if PlayerInput.KeyHit(NTCS_Eyes.LensActivationKey) then
				if NTCS_Eyes.HUDEnabled then
					--print("NTCS_Eyess: Disabling Client HUD")
					NTCS_Eyes.HUDEnabled = false
					NTCS_Eyes.PlayBeepSound(Character.Controlled)
				else
					--print("NTCS_Eyess: Enabling Client HUD")
					NTCS_Eyes.HUDEnabled = true
					NTCS_Eyes.PlayBeepSound(Character.Controlled)
				end
			end
		end
	end
end

--or GUI.InputBlockingMenuOpen
--or GUI.PauseMenuOpen
--or GUI.SettingsMenuOpen

--health UI scanner function for medical lens
function NTCS_Eyes.MedicalLensScanner()
	--check if the player has a medical lens
	if not NTCS.HF.HasAffliction(Character.Controlled, "lt_medical") then
		return
	end
	if not CharacterHealth.OpenHealthWindow or NTCS_Eyes.ScannerActive then
		return
	end

	if PlayerInput.KeyHit(NTCS_Eyes.MedicalScannerKey) then
		local scannerUser = Character.Controlled
		local scannerTarget = Character.Controlled.SelectedCharacter or scannerUser
		local limbIndex = CharacterHealth.OpenHealthWindow.selectedLimbIndex

		-- Prevent scanning own head
		if limbIndex == 0 and scannerUser == scannerTarget then
			HF.DMClient(
				HF.CharacterToClient(scannerUser),
				"‖color:255,100,100‖You can't see your own head.‖color:end‖"
			)
			NTCS_Eyes.ScannerActive = true
			NTCS_Eyes.PlayScannerSound(scannerUser)
			Timer.Wait(function()
				NTCS_Eyes.ScannerActive = false
			end, 500)
			return
		end

		-- Map limb index to LimbType
		local limbTypes = {
			[0] = LimbType.Head,
			[1] = LimbType.Torso,
			[2] = LimbType.LeftArm,
			[3] = LimbType.RightArm,
			[4] = LimbType.LeftLeg,
			[5] = LimbType.RightLeg,
		}
		local limb = limbTypes[limbIndex]
		if not limb then
			return
		end

		-- Perform scan
		NTCS_Eyes.HealthScanner(scannerUser, scannerTarget, limb)
		NTCS_Eyes.ScannerActive = true
	end
end
