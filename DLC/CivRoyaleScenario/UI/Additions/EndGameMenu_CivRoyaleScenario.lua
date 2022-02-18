-- Copyright 2019, Firaxis Games

-- Add the new victory type
Styles = {
	["GENERIC_DEFEAT"] ={
		RibbonIcon = "ICON_DEFEAT_GENERIC",
		Ribbon = "EndGame_Ribbon_Defeat",
		RibbonTile = "EndGame_RibbonTile_Defeat",
		Background = "EndGame_BG_CivRoyaleDefeat",
		SndStart = "Play_Cinematic_Endgame_Defeat",
		SndStop = "Stop_Cinematic_Endgame_Defeat",
		FadeOutTime = 7,
	},

	["VICTORY_DEFAULT"] = {
		RibbonIcon = "ICON_VICTORY_DEFAULT",
		Ribbon = "EndGame_Ribbon_Domination",
		RibbonTile = "EndGame_RibbonTile_Domination",
		Background = "EndGame_BG_CivRoyaleVictory",
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
	if dataSetName=="REPLAYDATASET_TOTALCOMBATS" then return true; end
	if dataSetName=="REPLAYDATASET_TOTALPLAYERUNITSDESTROYED" then return true; end
	if dataSetName=="REPLAYDATASET_TOTALUNITSDESTROYED" then return true; end
	return false;
end
