if CLIENT or not Game.IsMultiplayer then
	LuaUserData.RegisterType("Neurotrauma.ClientSource.ButtonData")
	local ButtonData = LuaUserData.CreateStatic("Neurotrauma.ClientSource.ButtonData")

	-- New sub-button under the organ scalpel
	ButtonData.Add(
		"surgery_eye", -- Button ID
		"GUIButtonEye", -- Icon Style
		"it_scalpel_eye", -- Item ID
		"surgerykit", -- Required Item ID
		"nt_huibutton_enabled_organscalpel", -- ToolTip
		"nt_huibutton_disabled_surgerykit", -- Disabled ToolTip
		"Head", -- RequiredLimb
		"organscalpel" -- ParentIdentifier
	)
end