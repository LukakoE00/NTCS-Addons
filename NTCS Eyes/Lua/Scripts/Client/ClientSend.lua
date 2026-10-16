--send a request to spawn a sound effect item health scanner
function NTCS_Eyes.PlayScannerSound(target)
	if not Game.IsMultiplayer then
		NTCS.HF.GiveItem(target, NTCS_Eyes.ScannerActive and "misc_sfx_fail" or "misc_sfx_selfscan")
		return
	end

	local message = Networking.Start(NTCS_Eyes.ScannerActive and "PlayScannerSoundFail" or "PlayScannerSound")
	message.WriteString(target.ID)
	Networking.Send(message)
end

--send a request to spawn a sound effect item beep
function NTCS_Eyes.PlayBeepSound(target)
	if not Game.IsMultiplayer then
		NTCS.HF.GiveItem(target, "misc_sfx_beep")
		return
	end
	local message = Networking.Start("PlayBeepSound")
	message.WriteString(target.ID)
	Networking.Send(message)
end

--send a request to get config values
function NTCS_Eyes.GetConfigValue()
	local message = Networking.Start("GetConfigValue")
	Networking.Send(message)
end
