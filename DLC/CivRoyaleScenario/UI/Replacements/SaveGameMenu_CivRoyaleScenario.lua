include("SaveGameMenu");


-- ===========================================================================
--	OVERRIDES functionality from LoadSaveMenu_Shared
--	Create the default filename.
-- ===========================================================================
function CreateDefaultFileName( playerID:number, turn:number )
	local displayTurnNumber :number = turn;
	if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_NORMALIZED_TURN") then
		displayTurnNumber = (displayTurnNumber - GameConfiguration.GetStartTurn()) + 1; -- Keep turns starting at 1.
	end
	local player		:object = Players[playerID];
	local playerConfig	:object = PlayerConfigurations[player:GetID()];
	return Locale.ToUpper( Locale.Lookup(playerConfig:GetLeaderName() )).." "..tostring(displayTurnNumber);
end
