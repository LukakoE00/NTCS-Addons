--timer values
NTCS_Lobotomy.ClientUpdateCooldown = 0
NTCS_Lobotomy.ClientUpdateInterval = 120

-- updates client effects every 2 seconds
Hook.Add("think", "NTCS_Lobotomy.ClientUpdate", function()
    if NTCS.HF.GameIsPaused() or not Level.Loaded then return end
	
	 --use for deaf
    NTCS_Lobotomy.ClientUpdateCooldown = NTCS_Lobotomy.ClientUpdateCooldown-1
    if (NTCS_Lobotomy.ClientUpdateCooldown <= 0) then
        NTCS_Lobotomy.ClientUpdateCooldown = NTCS_Lobotomy.ClientUpdateInterval
        NTCS_Lobotomy.UpdateClientEffect()
    end
end)


function NTCS_Lobotomy.UpdateClientEffect()
	if Character.Controlled==nil then return end

	if --different team
		NTCS.HF.HasAffliction(Character.Controlled, "lobo_differentteam") and Game.IsMultiplayer and not (LuaUserData.IsTargetType(Game.GameSession.GameMode, "Barotrauma.PvPMode"))
	then
		Character.Controlled.TeamID=2 
	else
		Character.Controlled.TeamID=1
	end

end