-- Copyright 2020, Firaxis Games

BASE_LateInitialize = LateInitialize;

-- Add the new victory type
Styles = {
	["GENERIC_DEFEAT"] ={
		RibbonIcon = "ICON_DEFEAT_GENERIC",
		Ribbon = "EndGame_Ribbon_Defeat",
		RibbonTile = "EndGame_RibbonTile_Defeat",
		Background = "LEADER_PIRATES_SCENARIO_DRED_PIRATE_BACKGROUND",
		SndStart = "Play_Cinematic_Endgame_Defeat",
		SndStop = "Stop_Cinematic_Endgame_Defeat",
		FadeOutTime = 7,
	},

	["VICTORY_DEFAULT"] = {
		RibbonIcon = "ICON_VICTORY_DEFAULT",
		Ribbon = "EndGame_Ribbon_Domination",
		RibbonTile = "EndGame_RibbonTile_Domination",
		Background = "LEADER_PIRATES_SCENARIO_DREAD_PIRATE_BACKGROUND",
		SndStart = "Play_Cinematic_Endgame_Domination",
		SndStop = "Stop_Cinematic_Endgame_Domination",
		Color = "COLOR_VICTORY_DEFAULT",
		FadeOutTime = 13,
	},

	["VICTORY_SCORE"] = {
		RibbonIcon = "ICON_VICTORY_DEFAULT",
		Ribbon = "EndGame_Ribbon_Time",
		RibbonTile = "EndGame_RibbonTile_Time",
		Background = "LEADER_PIRATES_SCENARIO_DREAD_PIRATE_BACKGROUND",
		SndStart = "Play_Cinematic_Endgame_Domination",
		SndStop = "Stop_Cinematic_Endgame_Domination",
		Color = "COLOR_VICTORY_DEFAULT",
		FadeOutTime = 13,
	},
}



-- ===========================================================================
--	OVERRIDE EndGameReplyLogic (until DB solution is created)
-- ===========================================================================
function IsValidGraphDataSetToShow( dataSetName:string )
	if dataSetName=="REPLAYDATASET_SCOREPERTURN" then return true; end
	if dataSetName=="REPLAYDATASET_TOTALCOMBATS" then return true; end
	if dataSetName=="REPLAYDATASET_TOTALGOLD" then return true; end
	if dataSetName=="REPLAYDATASET_TOTALPLAYERUNITSDESTROYED" then return true; end
	if dataSetName=="REPLAYDATASET_TOTALUNITSDESTROYED" then return true; end
	return false;
end

function LateInitialize()
	BASE_LateInitialize()
	local leaderName : string = PlayerConfigurations[ Game.GetLocalPlayer() ]:GetLeaderTypeName();
	Styles["GENERIC_DEFEAT"].Background		= leaderName .. "_BACKGROUND";
	Styles["VICTORY_DEFAULT"].Background	= leaderName .. "_BACKGROUND";
end