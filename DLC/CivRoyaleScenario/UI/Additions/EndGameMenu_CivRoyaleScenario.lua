-- Copyright 2020, Firaxis Games

BASE_UpdateButtonStates = UpdateButtonStates;
BASE_LateInitialize = LateInitialize;
BASE_OnShow = OnShow;

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

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function UpdateButtonStates(data:table)
	BASE_UpdateButtonStates(data);
	Controls.ObserveButton:SetShow(CanObserve());
end

-- ===========================================================================
function OnObserve()
	local kParameters:table = {};
	UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.START_OBSERVER_MODE, kParameters);
	LuaEvents.EndGameMenu_StartObserverMode();
	Close();
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function OnShow()
	local localObserverID = Game.GetLocalObserver();
	if localObserverID ~= PlayerTypes.OBSERVER then
		BASE_OnShow();
	else
		OnShowEndGame();
		OnInfoTab();
	end
end

-- =============================================================
function OnEndObserverMode()
	OnShowEndGame();
	OnInfoTab();
end

-- ===========================================================================
function CanObserve()
	return(GameConfiguration.IsAnyMultiplayer() and 
	(PlayerManager.GetAliveMajorsCount() > 1) and 
	(not GameConfiguration.IsHotseat()) and 
	(not GameConfiguration.IsPlayByCloud()));
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function LateInitialize()
	BASE_LateInitialize();
	LuaEvents.ActionPanel_EndObserverMode.Add(OnShowEndGame);
	TruncateStringWithTooltip(Controls.ObserveButton, MAX_BUTTON_SIZE, Locale.Lookup("LOC_END_GAME_MENU_OBSERVE"));
	Controls.ObserveButton:RegisterCallback(Mouse.eLClick, OnObserve);
	Controls.ObserveButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
end