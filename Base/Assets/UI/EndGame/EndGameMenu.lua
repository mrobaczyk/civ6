-- Copyright 2016-2018, Firaxis Games
-- See global EndGameMenu_ include at bottom of file!

include("InstanceManager")
include("EndGameReplayLogic")
include("ChatLogic");
include("TeamSupport");
include("PopupDialog");

---------------------------------------------------------------
-- CONSTANTS
----------------------------------------------------------------
MAX_BUTTON_SIZE = 160;

---------------------------------------------------------------
-- Globals
----------------------------------------------------------------
g_GraphVerticalMarkers = {
	Controls.VerticalLabel1,
	Controls.VerticalLabel2,
	Controls.VerticalLabel3,
	Controls.VerticalLabel4,
	Controls.VerticalLabel5
};

g_GraphHorizontalMarkers = {
	Controls.HorizontalLabel1,
	Controls.HorizontalLabel2,
	Controls.HorizontalLabel3,
	Controls.HorizontalLabel4,
	Controls.HorizontalLabel5
};

-- Custom popup setup
m_kPopupDialog = PopupDialog:new( "EndGameMenu" );

local g_HasPlayerPortrait;	-- Whether or not a player portrait has been set.
local g_Movie;				-- The movie which has been set.
local g_SoundtrackStart;    -- Wwise start event for the movie's audio
local g_SoundtrackStop;     -- Wwise stop event for the movie's audio
local g_SavedMusicVol;      -- Saved music volume around movie play

-- Chat Panel Data
local m_playerTarget = { targetType = ChatTargetTypes.CHATTARGET_ALL, targetID = GetNoPlayerTargetID() };
local m_playerTargetEntries = {};
local m_ChatInstances		= {};

local PlayerConnectedChatStr = Locale.Lookup( "LOC_MP_PLAYER_CONNECTED_CHAT" );
local PlayerDisconnectedChatStr = Locale.Lookup( "LOC_MP_PLAYER_DISCONNECTED_CHAT" );
local PlayerHostMigratedChatStr = Locale.Lookup( "LOC_MP_PLAYER_HOST_MIGRATED_CHAT" );
local PlayerKickedChatStr = Locale.Lookup( "LOC_MP_PLAYER_KICKED_CHAT" );

local g_HideLeaderPortrait = false;

local m_bAllowBack = true;

local m_MovieWasPlayed	= false;
local m_teamVictory		= false;

local g_RankIM = InstanceManager:new( "RankEntry", "Root", Controls.RankingStack );
local g_GraphLegendInstanceManager = InstanceManager:new("GraphLegendInstance", "GraphLegend", Controls.GraphLegendStack);
local g_LineSegmentInstanceManager = InstanceManager:new("GraphLineInstance","LineSegment", Controls.GraphCanvas);

Styles = {
	["GENERIC_DEFEAT"] ={
		RibbonIcon = "ICON_DEFEAT_GENERIC",
		Ribbon = "EndGame_Ribbon_Defeat",
		RibbonTile = "EndGame_RibbonTile_Defeat",
		Background = "EndGame_BG_Defeat",
		Movie = "Defeat.bk2",
		SndStart = "Play_Cinematic_Endgame_Defeat",
		SndStop = "Stop_Cinematic_Endgame_Defeat",
	},
	["GENERIC_VICTORY"] = {
		RibbonIcon = "ICON_VICTORY_SCORE",
		Ribbon = "EndGame_Ribbon_Time",
		RibbonTile = "EndGame_RibbonTile_Time",
		Background = "EndGame_BG_Time",
		Color = "COLOR_VICTORY_DEFAULT",
	},
	["VICTORY_SCORE"] = {
		RibbonIcon = "ICON_VICTORY_SCORE",
		Ribbon = "EndGame_Ribbon_Time",
		RibbonTile = "EndGame_RibbonTile_Time",
		Background = "EndGame_BG_Time",
		Movie = "Time.bk2",
		SndStart = "Play_Cinematic_Endgame_Time",
		SndStop = "Stop_Cinematic_Endgame_Time",
		Color = "COLOR_VICTORY_SCORE",
	},
	["VICTORY_DEFAULT"] = {
		RibbonIcon = "ICON_VICTORY_DEFAULT",
		Ribbon = "EndGame_Ribbon_Domination",
		RibbonTile = "EndGame_RibbonTile_Domination",
		Background = "EndGame_BG_Domination",
		Movie = "Domination.bk2",
		SndStart = "Play_Cinematic_Endgame_Domination",
		SndStop = "Stop_Cinematic_Endgame_Domination",
		Color = "COLOR_VICTORY_DEFAULT",
	},
	["VICTORY_CONQUEST"] = {
		RibbonIcon = "ICON_VICTORY_CONQUEST",
		Ribbon = "EndGame_Ribbon_Domination",
		RibbonTile = "EndGame_RibbonTile_Domination",
		Background = "EndGame_BG_Domination",
		Movie = "Domination.bk2",
		SndStart = "Play_Cinematic_Endgame_Domination",
		SndStop = "Stop_Cinematic_Endgame_Domination",
		Color = "COLOR_VICTORY_DOMINATION",
	},
	["VICTORY_CULTURE"] = {
		RibbonIcon = "ICON_VICTORY_CULTURE",
		Ribbon = "EndGame_Ribbon_Culture",
		RibbonTile = "EndGame_RibbonTile_Culture",
		Background = "EndGame_BG_Culture",
		Movie = "Culture.bk2",
		SndStart = "Play_Cinematic_Endgame_Culture",
		SndStop = "Stop_Cinematic_Endgame_Culture",
		Color = "COLOR_VICTORY_CULTURE",
	},
	["VICTORY_RELIGIOUS"] = {
		RibbonIcon = "ICON_VICTORY_RELIGIOUS",
		Ribbon = "EndGame_Ribbon_Religion",
		RibbonTile = "EndGame_RibbonTile_Religion",
		Background = "EndGame_BG_Religion",
		Movie = "Religion.bk2",
		SndStart = "Play_Cinematic_Endgame_Religion",
		SndStop = "Stop_Cinematic_Endgame_Religion",
		Color = "COLOR_VICTORY_RELIGION",
	},
	["VICTORY_TECHNOLOGY"] = {
		RibbonIcon = "ICON_VICTORY_TECHNOLOGY",
		Ribbon = "EndGame_Ribbon_Science",
		RibbonTile = "EndGame_RibbonTile_Science",
		Background = "EndGame_BG_Science",
		Movie = "Science.bk2",
		SndStart = "Play_Cinematic_Endgame_Science",
		SndStop = "Stop_Cinematic_Endgame_Science",
		Color = "COLOR_VICTORY_SCIENCE",
	},
	-- Kluuudge
	["VICTORY_ALEXANDER"] = {
		RibbonIcon = "ICON_VICTORY_DEFAULT",
		Ribbon = "EndGame_Ribbon_Domination",
		RibbonTile = "EndGame_RibbonTile_Domination",
		Background = "EndGame_BG_Domination",
		Movie = "Domination.bk2",
		SndStart = "Play_Cinematic_Endgame_Domination",
		SndStop = "Stop_Cinematic_Endgame_Domination",
		Color = "COLOR_VICTORY_DEFAULT",
	},
};

----------------------------------------------------------------
-- Utility function that lets me pass an icon string or
-- an array of icons to attempt to use.
-- Upon success, show the control.  Failure, hide the control.  
----------------------------------------------------------------  
function SetIcon(control, icon) 
	control:SetHide(false);

	if(icon == nil) then
		control:SetHide(true);
		return;
	else
		if(type(icon) == "string") then
			if(control:SetIcon(icon)) then
				return;
			end

		elseif(type(icon) == "table") then
			for i,v in ipairs(icon) do
				if(control:SetIcon(v)) then
					return;
				end
			end	
		end
		control:SetHide(true);
	end
end

----------------------------------------------------------------  
----------------------------------------------------------------  
function PopulateRankingResults()
	g_RankIM:ResetInstances();

	local player = Players[Game.GetLocalPlayer()];
	local score = player:GetScore();
	
	local playerAdded = false;
	local count = 1;
	for row in GameInfo.HistoricRankings() do
		local instance = g_RankIM:GetInstance();
	
		instance.Number:LocalizeAndSetText("LOC_UI_ENDGAME_NUMBERING_FORMAT", count);
		instance.LeaderName:LocalizeAndSetText(row.HistoricLeader);
		
		if(score >= row.Score and not playerAdded)then
			instance.LeaderScore:SetText(Locale.ToNumber(score));
			instance.LeaderQuote:LocalizeAndSetText(row.Quote);
			instance.LeaderQuote:SetHide(false);
			Controls.RankingTitle:LocalizeAndSetText("LOC_UI_ENDGAME_RANKING_STATEMENT", row.HistoricLeader);
			playerAdded = true;
		else
			instance.LeaderScore:SetText(Locale.ToNumber(row.Score));
			instance.LeaderQuote:SetHide(true);
		end

		count = count + 1;
	end

	Controls.RankingScrollPanel:SetScrollValue(0);
	
	Controls.RankingStack:CalculateSize();
	Controls.RankingStack:ReprocessAnchoring();
	Controls.RankingScrollPanel:CalculateInternalSize();
end

function UpdateButtonStates(data:table)
	-- Display a continue button if there are other players left in the game
	local player = Players[Game.GetLocalPlayer()];

	-- If there are living human players in a hot-seat game, do not display the main menu button.
	-- Instead go to the next player's turn.
	local nextPlayer = false;
	if(not data.NoMorePlayers and GameConfiguration.IsHotseat()) then
		local humans = GameConfiguration.GetHumanPlayerIDs();
		for i,v in ipairs(humans) do
			local human = Players[v];
			if(human and human:IsAlive()) then
				nextPlayer = true;
				break;
			end
		end
	end

	local noExtendedGame = GameConfiguration.GetValue("NO_EXTENDED_GAME");
	-- Was One More Turn ever allowed for the current game?
	local everAllowExtended = (noExtendedGame == nil or (noExtendedGame ~= 1 and noExtendedGame ~= true))
							and not GameConfiguration.IsPlayByCloud();			
	-- Is One More Turn allowed for the local player now?							
	local canExtendGame = everAllowExtended;
	
	if data ~= nil and data.OneMoreTurn ~= nil then
		canExtendGame = data.OneMoreTurn;
	end
	
	canExtendGame = canExtendGame and player and player:IsAlive();
	
	-- Don't show next player button if Just One More Turn will be shown as the functionality is the same.
	nextPlayer = nextPlayer and not canExtendGame;

	-- Always show the main menu button.
	Controls.MainMenuButton:SetHide(false);
	
	-- Enable just one more turn if we can extend the game.
	-- Show the just one more turn button if we're not showing the next player button.	
	-- Hide the one more turn button if it was never allowed for this game.
	Controls.BackButton:SetDisabled(not canExtendGame);
	Controls.BackButton:SetHide(nextPlayer or not everAllowExtended);

	-- Show the next player button only if in a hot-seat match and just one more turn is disabled.
	Controls.NextPlayerButton:SetHide(not nextPlayer);
	
	Controls.ButtonStack:CalculateSize();
	Controls.ButtonStack:ReprocessAnchoring();
end

----------------------------------------------------------------
----------------------------------------------------------------
function OnNextPlayer()
    UI.UnloadSoundBankGroup(5);
	UIManager:DequeuePopup( ContextPtr );
	UI.RequestAction(ActionTypes.ACTION_ENDTURN);
end
TruncateStringWithTooltip(Controls.NextPlayerButton, MAX_BUTTON_SIZE, Locale.Lookup("LOC_UI_ENDGAME_MP_PLAYER_CHANGE_CONTINUE"));
Controls.NextPlayerButton:RegisterCallback( Mouse.eLClick, OnNextPlayer );
Controls.NextPlayerButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

-- ===========================================================================
function Close()

	ReplayShutdown();
	g_RankIM:ResetInstances();	-- Unload instances.	
	Controls.Movie:Close();		-- Unload movie
	
	-- Unload large textures.
	Controls.Background:UnloadTexture();
	Controls.PlayerPortrait:UnloadTexture();

	UIManager:DequeuePopup( ContextPtr );
	UI.UnloadSoundBankGroup(5);	
	UI.ReleasePauseEvent();		-- Release any event we might have been holding on to.	

	local isHiding:boolean = true;
	HandlePauseGame( isHiding );	
end

----------------------------------------------------------------
----------------------------------------------------------------
function OnMainMenu()    
	Controls.Movie:Close();		-- Unload movie
	UI.UnloadSoundBankGroup(5);	
	UI.ReleasePauseEvent();		-- Release any event we might have been holding on to.	

	Events.ExitToMainMenu();	
end
TruncateStringWithTooltip(Controls.MainMenuButton, MAX_BUTTON_SIZE, Locale.Lookup("LOC_UI_ENDGAME_MAIN_MENU"));
Controls.MainMenuButton:RegisterCallback( Mouse.eLClick, OnMainMenu );
Controls.MainMenuButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

----------------------------------------------------------------
----------------------------------------------------------------
function OnBack()    
	Close();	
	LuaEvents.EndGameMenu_OneMoreTurn();	
end
TruncateStringWithTooltip(Controls.BackButton, MAX_BUTTON_SIZE, Locale.Lookup("LOC_UI_ENDGAME_EXTENDED_GAME"));
Controls.BackButton:RegisterCallback( Mouse.eLClick, OnBack );
Controls.BackButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

----------------------------------------------------------------
----------------------------------------------------------------
function OnInfo()
    Controls.InfoPanel:SetHide(false);
	Controls.RankingPanel:SetHide(true);
    Controls.GraphPanel:SetHide(true);
	Controls.ChatPanel:SetHide(true);
	Controls.PlayerPortrait:SetHide(g_HideLeaderPortrait);

	Controls.InfoButtonSelected:SetHide(false);
	Controls.RankingButtonSelected:SetHide(true);
	Controls.ReplayButtonSelected:SetHide(true);
	Controls.ChatButtonSelected:SetHide(true);

end
Controls.InfoButton:RegisterCallback( Mouse.eLClick, OnInfo );
Controls.InfoButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

----------------------------------------------------------------
----------------------------------------------------------------
function OnRanking()
    Controls.InfoPanel:SetHide(true);
	Controls.RankingPanel:SetHide(false);
    Controls.GraphPanel:SetHide(true);
	Controls.ChatPanel:SetHide(true);
	Controls.PlayerPortrait:SetHide(g_HideLeaderPortrait);

	Controls.InfoButtonSelected:SetHide(true);
	Controls.RankingButtonSelected:SetHide(false);
	Controls.ReplayButtonSelected:SetHide(true);
	Controls.ChatButtonSelected:SetHide(true);

	PopulateRankingResults();
end
Controls.RankingButton:RegisterCallback( Mouse.eLClick, OnRanking );
Controls.RankingButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

----------------------------------------------------------------
----------------------------------------------------------------
function OnReplay()
    Controls.InfoPanel:SetHide(true);
	Controls.RankingPanel:SetHide(true);
    Controls.GraphPanel:SetHide(false);
	Controls.ChatPanel:SetHide(true);
	Controls.PlayerPortrait:SetHide(true);

	Controls.InfoButtonSelected:SetHide(true);
	Controls.RankingButtonSelected:SetHide(true);
	Controls.ReplayButtonSelected:SetHide(false);
	Controls.ChatButtonSelected:SetHide(true);

	ReplayInitialize();

end
Controls.ReplayButton:RegisterCallback( Mouse.eLClick, OnReplay );
Controls.ReplayButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

----------------------------------------------------------------
----------------------------------------------------------------
function OnChat()
    Controls.InfoPanel:SetHide(true);
	Controls.RankingPanel:SetHide(true);
    Controls.GraphPanel:SetHide(true);
	Controls.ChatPanel:SetHide(false);
	Controls.PlayerPortrait:SetHide(true);

	Controls.InfoButtonSelected:SetHide(true);
	Controls.RankingButtonSelected:SetHide(true);
	Controls.ReplayButtonSelected:SetHide(true);
	Controls.ChatButtonSelected:SetHide(false);
end
Controls.ChatButton:RegisterCallback( Mouse.eLClick, OnChat );
Controls.ChatButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

----------------------------------------------------------------        
----------------------------------------------------------------   
function OnReplayMovie()
	if(g_Movie) then
		if Controls.Movie:SetMovie(g_Movie) then
    		Controls.MovieFill:SetHide(false);
    		Controls.Movie:Play();
            UI.StopInGameMusic();
            UI.PlaySound(g_SoundtrackStart);
            g_SavedMusicVol = Options.GetAudioOption("Sound", "Music Volume"); 
            Options.SetAudioOption("Sound", "Music Volume", 0, 0);
            m_MovieWasPlayed = true;
        end
	end

	-- If in Network MP, release the pause event, so our local machine continues processing
	if (GameConfiguration.IsNetworkMultiplayer()) then
		UI.ReleasePauseEvent();
	end
end
TruncateStringWithTooltip(Controls.ReplayMovieButton, MAX_BUTTON_SIZE, Locale.Lookup("LOC_UI_ENDGAME_REPLAY_MOVIE"));
Controls.ReplayMovieButton:RegisterCallback(Mouse.eLClick, OnReplayMovie);
Controls.ReplayMovieButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

----------------------------------------------------------------        
----------------------------------------------------------------   
function OnMovieExitOrFinished()
	--Controls.Movie:Stop();
	Controls.Movie:Close();
	Controls.MovieFill:SetHide(true);
    if (m_MovieWasPlayed) then
        UI.PlaySound(g_SoundtrackStop);
        Options.SetAudioOption("Sound", "Music Volume", g_SavedMusicVol, 0);
        UI.SkipSong();
        m_MovieWasPlayed = false;
    end

	-- If in Network or PlayByCloud MP, release the pause event, so our local machine continues processing
	if (GameConfiguration.IsNetworkMultiplayer() or GameConfiguration.IsPlayByCloud()) then
		UI.ReleasePauseEvent();
	end
end
Controls.Movie:SetMovieFinishedCallback(OnMovieExitOrFinished);
Controls.MovieFill:RegisterCallback(Mouse.eLClick, OnMovieExitOrFinished);

-- ===========================================================================
function OnInputHandler( input )
	local msg = input:GetMessageType();
	if (msg == KeyEvents.KeyUp) then
		local key = input:GetKey();
		if (key == Keys.VK_ESCAPE) then
			if(not Controls.MovieFill:IsHidden()) then
				OnMovieExitOrFinished();
			end

			-- Always trap the escape key here.
			return true;
		end
	end
	return false;
end

-- ===========================================================================
function OnShow()
	print("Showing EndGame Menu");

	LuaEvents.EndGameMenu_Shown();	-- Add ingame bulk hide counter
	Resize();						-- Verify we're scaled properly.
	OnInfo();						-- Always start with the info panel.	
	OnReplayMovie();				-- Noop if no movie is set.

	-- Setup Chat Player Target Pulldown.
	PopulateTargetPull(Controls.ChatPull, Controls.ChatEntry, Controls.ChatIcon, m_playerTargetEntries, m_playerTarget, false, OnChatPulldownChanged);

	-- TODO: Better place for this to happen so it doesn't get called on every show (every queue popup)
	local isHiding:boolean = false;
	HandlePauseGame( isHiding );
end

-- ===========================================================================
function OnHide()
	print("Hiding EndGame Menu");
	LuaEvents.EndGameMenu_Closed();		-- Remove ingame bulk (un)hide counter.
end

-- ===========================================================================
-- When should the End Game screen pause the game?
-- Network multiplayer games need to pause the game in specific situations so the game does not progress while the local player looks at this screen.
-- NOTE: We use the gameplay pausing instead of an UI pause event because UI pause events lock gameplay event playback in a unmultiplayer friendly way.
function ShouldPauseGame()
	if(not GameConfiguration.IsNetworkMultiplayer() ) then
		return false;
	end
	
	-- Only pause if there has been a game victory.  We do not pause the game for personal defeats because gameplay should continue for the non-defeated players.
	if(m_teamVictory == false) then
		return false;
	end
	
	return true;	
end

-- ===========================================================================
function HandlePauseGame( bIsHide : boolean )
	if(ShouldPauseGame()) then
		local localPlayerID = Network.GetLocalPlayerID();
		local localPlayerConfig = PlayerConfigurations[localPlayerID];
		if(localPlayerConfig) then
			localPlayerConfig:SetWantsPause(not bIsHide);
			Network.BroadcastPlayerInfo();
		end
	end
end
     
	 -- ===========================================================================
function Resize()
	local screenX, screenY = UIManager:GetScreenSizeVal();

	g_HideLeaderPortrait = screenX < 1280;

	Controls.Background:Resize(screenX,screenY);
	Controls.RankingStack:CalculateSize();
	Controls.RankingStack:ReprocessAnchoring();
	Controls.RankingScrollPanel:CalculateInternalSize();

	local portraitOffsetY = math.min(0, screenY-1024);
	Controls.PlayerPortrait:SetOffsetVal(-420, portraitOffsetY);

	-- Show/Hide the chat panel button
	Controls.ChatButton:SetShow(GameConfiguration.IsNetworkMultiplayer() and UI.HasFeature("Chat")); 

end

function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string )   
  if (type == SystemUpdateUI.ScreenResize) then
    Resize();
  end
end

----------------------------------------------------------------
function ViewWinnerPanel(data:table)
	if data.WinnerName ~= "" then
		Controls.VictoryPanel:SetHide(false);

		-- Update pennant
		SetIcon(Controls.VictoryIcon, data.VictoryTypeIcon);
		SetIcon(Controls.VictoryCivIcon, data.WinnerIcon);
		Controls.VictoryCivIconBacking:SetColor(data.WinnerBackColor);
		Controls.VictoryCivIcon:SetColor(data.WinnerFrontColor);
		Controls.VictoryPennant:SetColor(UI.GetColorValue(data.VictoryTypeColor));

		-- Update victory type name and player/team name
		Controls.VictoryTypeName:SetText(Locale.ToUpper(data.VictoryTypeHeader));
		Controls.VictoryPlayerName:SetText(Locale.Lookup(data.WinnerName));

		if data.VictoryBlurb ~= "" then
			Controls.VictoryBlurb:SetHide(false);
			Controls.VictoryBlurbDivider:SetHide(false);
			Controls.VictoryBlurb:SetText(data.VictoryBlurb);
		else
			Controls.VictoryBlurb:SetHide(true);
			Controls.VictoryBlurbDivider:SetHide(true);
		end

		-- Show local player indicator if local player
		if data.IsWinnerLocalPlayer then
			Controls.LocalPlayerRim:SetHide(false);
			Controls.LocalPlayerArrow:SetHide(false);
		else
			Controls.LocalPlayerRim:SetHide(true);
			Controls.LocalPlayerArrow:SetHide(true);
		end

		Controls.VictoryPanel:DoAutoSize();
	else
		Controls.VictoryPanel:SetHide(true);
	end
end

----------------------------------------------------------------
function ViewDefeatedPanel(data:table)
	if data.DefeatedName ~= "" then
		Controls.DefeatedPanel:SetHide(false);
		Controls.DefeatedTypeName:SetText(Locale.ToUpper("LOC_DEFEAT_DEFAULT_NAME"));
		Controls.DefeatedPlayerName:SetText(data.DefeatedName);
		SetIcon(Controls.DefeatedCivIcon, data.DefeatedIcon);
		Controls.DefeatedCivIconBacking:SetColor(data.DefeatedBackColor);
		Controls.DefeatedCivIcon:SetColor(data.DefeatedFrontColor);
		Controls.DefeatedCivIconBacking:ReprocessAnchoring();
	else
		Controls.DefeatedPanel:SetHide(true);
	end
end

----------------------------------------------------------------
-- The primary method for updating the UI.
----------------------------------------------------------------
function View(data:table)
	
	ViewWinnerPanel(data);
	ViewDefeatedPanel(data);

	-- Update background
	Controls.Background:SetTexture(data.RibbonStyle.Background);

	-- Update ribbon
	SetIcon(Controls.RibbonIcon, data.RibbonIcon);
	Controls.RibbonLabel:SetText(Locale.ToUpper(Locale.Lookup(data.RibbonText)));
	Controls.Ribbon:SetTexture(data.RibbonStyle.Ribbon);
	Controls.RibbonTile:SetTexture(data.RibbonStyle.RibbonTile);

	-- Update player portrait
	if(data.PlayerPortrait) then
		g_HasPlayerPortrait = true;
		Controls.PlayerPortrait:SetTexture(data.PlayerPortrait);
		Controls.PlayerPortrait:SetHide(false);
	else
		g_HasPlayerPortrait = false;
		Controls.PlayerPortrait:UnloadTexture();
		Controls.PlayerPortrait:SetHide(true);
	end

	Resize();

	if(g_HideLeaderPortrait) then
		Controls.PlayerPortrait:SetHide(true);
		Controls.PlayerPortrait:UnloadTexture();
	end

	---- Movie begins play-back when UI is shown.
	g_Movie = data.RibbonStyle.Movie;
    g_SoundtrackStart = data.RibbonStyle.SndStart;
    g_SoundtrackStop = data.RibbonStyle.SndStop;

    if g_Movie ~= nil then
        UI.LoadSoundBankGroup(5);   -- BANKS_FMV, must teach Lua these constants
    end

	Controls.ReplayMovieButton:SetHide(g_Movie == nil);
	Controls.MovieFill:SetHide(true);
	Controls.Movie:Close();

	if(ContextPtr:IsHidden()) then
		UIManager:QueuePopup( ContextPtr, PopupPriority.EndGameMenu );
	end	

	UpdateButtonStates(data);
end

----------------------------------------------------------------
function DefaultData()
	local data:table = {};
		
	data.PlayerPortrait = "";

	data.RibbonText = "";
	data.RibbonIcon = "";
	data.RibbonStyle = nil;

	data.IsWinnerLocalPlayer = false;
	data.WinnerName = "";
	data.WinnerIcon = "";
	data.WinnerBackColor = nil;
	data.WinnerFrontColor = nil;

	data.VictoryTypeHeader = "";
	data.VictoryTypeIcon = "";
	data.VictoryTypeColor = nil;
	data.VictoryBlurb = "";

	data.DefeatedName = "";
	data.DefeatedIcon = "";
	data.DefeatedBackColor = nil;
	data.DefeatedFrontColor = nil;

	return data;
end

----------------------------------------------------------------
function PlayerDefeatedData(playerID:number, defeatType:string)
	local data:table = DefaultData();

	-- Gather player portrait data
	local pPlayerConfig = PlayerConfigurations[playerID];
	local leaderType = pPlayerConfig:GetLeaderTypeName();
	local loadingInfo:table = GameInfo.LoadingInfo[leaderType];
	if loadingInfo and loadingInfo.ForegroundImage then
		data.PlayerPortrait = loadingInfo.ForegroundImage;
	else
		data.PlayerPortrait = leaderType .. "_NEUTRAL";
	end

	local defeatInfo = GameInfo.Defeats[defeatType];
	if defeatInfo and defeatInfo.Name then
		data.RibbonText = Locale.ToUpper(defeatInfo.Name);
	else
		data.RibbonText = Locale.ToUpper("LOC_DEFEAT_DEFAULT_NAME");
	end

	-- Gather ribbon data
	data.RibbonIcon = "ICON_DEFEAT_GENERIC";
	data.RibbonStyle = Styles["GENERIC_DEFEAT"];

	-- No winner so clear out winner name
	data.WinnerName = "";

	-- Defeated player data
	local pDefeatedConfig = PlayerConfigurations[playerID];
	local pDefeatedPlayer = Players[playerID];
	data.DefeatedName = Locale.Lookup(pDefeatedConfig:GetCivilizationDescription());
	if GameConfiguration.IsAnyMultiplayer() and pDefeatedPlayer:IsHuman() then
		local defeatedName = Locale.Lookup(pDefeatedConfig:GetPlayerName());
		data.DefeatedName = data.DefeatedName .. " (" .. defeatedName .. ")"
	end

	local defeatedCivType = pDefeatedConfig:GetCivilizationTypeName();
	data.DefeatedIcon = "ICON_" .. defeatedCivType;

	local backColor, frontColor = UI.GetPlayerColors(playerID);
	data.DefeatedFrontColor = frontColor;
	data.DefeatedBackColor = backColor;

	local defeat = GameInfo.Defeats[defeatType];
	if (defeat) then
		data.OneMoreTurn = defeat.OneMoreTurn;

		-- KLUDGE
		-- This is a kludge for hot-seat games to avoid a soft hang.
		-- What's happening is the local player is still in the process of handling their defeat
		-- The cache of whether other players are alive hasn't been updated for the other players yet
		-- so end-game thinks other players are alive and the game can be resumed.
		data.NoMorePlayers= defeat.Global;
	end

	return data;
end

----------------------------------------------------------------
function TeamVictoryData(winningTeamID:number, victoryType:string)
	local data:table = DefaultData();
	local localPlayerID:number = Game.GetLocalPlayer();
	local pLocalPlayer:table = Players[localPlayerID];
	local localPlayerTeamID:number = pLocalPlayer:GetTeam();
	
	-- Determine if the local player is a winner
	data.IsWinnerLocalPlayer = winningTeamID == localPlayerTeamID;

	local victoryStyle = Styles[victoryType];
	if not victoryStyle then
		if data.IsWinnerLocalPlayer then
			victoryStyle = Styles["GENERIC_VICTORY"];
		else
			victoryStyle = Styles["GENERIC_DEFEAT"];
		end
	end

	-- Gather player portrait data
	-- The portrait should be the first living player in the winning team.
	local playerToShow = localPlayerID; -- default to local player, if something weird happens.
	local team = Teams[winningTeamID];
	for i, v in ipairs(team) do
		local player = Players[v];
		if(player:IsAlive()) then
			playerToShow = v;
			break;
		end
	end

	local pPlayerConfig = PlayerConfigurations[playerToShow];
	local leaderType = pPlayerConfig:GetLeaderTypeName();
	local loadingInfo:table = GameInfo.LoadingInfo[leaderType];
	if loadingInfo and loadingInfo.ForegroundImage then
		data.PlayerPortrait = loadingInfo.ForegroundImage;
	else
		data.PlayerPortrait = leaderType .. "_NEUTRAL";
	end

	-- Gather ribbon data
	if data.IsWinnerLocalPlayer then
		data.RibbonText = Locale.ToUpper("LOC_VICTORY_DEFAULT_NAME");
		data.RibbonIcon = "ICON_VICTORY_UNIVERSAL";
		data.RibbonStyle = victoryStyle;
		if(data.RibbonStyle == nil) then
			data.RibbonStyle = Styles["GENERIC_VICTORY"];
		end
	else
		data.RibbonText = Locale.ToUpper("LOC_DEFEAT_DEFAULT_NAME");
		data.RibbonIcon = "ICON_DEFEAT_GENERIC";
		data.RibbonStyle = Styles["GENERIC_DEFEAT"];
	end

	-- Gather winner data
	local victory = GameInfo.Victories[victoryType];
	data.VictoryTypeHeader = victory.Name;
	data.VictoryTypeIcon = victoryStyle.RibbonIcon;
	if victoryStyle.Color then
		data.VictoryTypeColor = victoryStyle.Color;
	end
	data.OneMoreTurn = victory.OneMoreTurn;

	-- Display victory blurb if local player is the winner
	if data.IsWinnerLocalPlayer then
		data.VictoryBlurb = Locale.Lookup(victory.Blurb);
	else
		data.VictoryBlurb = "";
	end

	if #Teams[winningTeamID] > 1 then
		-- Show team info if more than one player on a team
		data.WinnerName = Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", winningTeamID);
		data.WinnerIcon = "ICON_TEAM_ICON_" .. winningTeamID;
		data.WinnerBackColor = GetTeamColor(winningTeamID);
		data.WinnerFrontColor = UI.GetColorValue("COLOR_WHITE");
	else
		-- Show player info if only one player on team
		local winnerPlayerID:number = Teams[winningTeamID][1];
		local pWinnerConfig = PlayerConfigurations[winnerPlayerID];
		local pWinnerPlayer = Players[winnerPlayerID];
		data.WinnerName = Locale.Lookup(pWinnerConfig:GetCivilizationDescription());
		if GameConfiguration.IsAnyMultiplayer() and pWinnerPlayer:IsHuman() then
			local winnerName = Locale.Lookup(pWinnerConfig:GetPlayerName());
			data.WinnerName = data.WinnerName .. " (" .. winnerName .. ")"
		end

		local winnerCivType = pWinnerConfig:GetCivilizationTypeName();
		data.WinnerIcon = "ICON_" .. winnerCivType;

		local backColor, frontColor = UI.GetPlayerColors(winnerPlayerID);
		data.WinnerFrontColor = frontColor;
		data.WinnerBackColor = backColor;
	end

	-- Gather defeated data
	if data.IsWinnerLocalPlayer then
		-- No defeated name indicates we should hide the whole panel
		-- We hide this panel unless the winning player is not the local player
		data.DefeatedName = "";
	else
		local pDefeatedConfig = PlayerConfigurations[localPlayerID];
		local pDefeatedPlayer = Players[localPlayerID];
		data.DefeatedName = Locale.Lookup(pDefeatedConfig:GetCivilizationDescription());
		if GameConfiguration.IsAnyMultiplayer() and pDefeatedPlayer:IsHuman() then
			local defeatedName = Locale.Lookup(pDefeatedConfig:GetPlayerName());
			data.DefeatedName = data.DefeatedName .. " (" .. defeatedName .. ")"
		end

		local defeatedCivType = pDefeatedConfig:GetCivilizationTypeName();
		data.DefeatedIcon = "ICON_" .. defeatedCivType;

		local backColor, frontColor = UI.GetPlayerColors(localPlayerID);
		data.DefeatedFrontColor = frontColor;
		data.DefeatedBackColor = backColor;
	end
	
	return data;
end

----------------------------------------------------------------
-- Called when a player has been defeated.
-- The UI is only displayed if this player is you.
----------------------------------------------------------------
function OnPlayerDefeat( player, defeat, eventID)
	local localPlayer = Game.GetLocalPlayer();
	if (localPlayer and localPlayer >= 0) then		-- Check to see if there is any local player
		-- Was it the local player?
		if (localPlayer == player) then
			UI.SetPauseEventID( eventID );
			-- You have been defeated :(
			local defeatInfo = GameInfo.Defeats[defeat];
			defeat = defeatInfo and defeatInfo.DefeatType or "DEFEAT_DEFAULT";
			View(PlayerDefeatedData(player, defeat));

			-- In hotseat games, it is possible for a human player to get defeated by an AI civ during turn processing.
			-- We trigger an event so the PlayerChange screen can hide itself.
			LuaEvents.EndGameMenu_ViewingPlayerDefeat();
		end
	end
end

local ruleset = GameConfiguration.GetValue("RULESET");
if(ruleset ~= "RULESET_TUTORIAL") then
	Events.PlayerDefeat.Add(OnPlayerDefeat);
end

----------------------------------------------------------------
-- Called when a player is victorious.
-- The UI is only displayed if this player is you.
----------------------------------------------------------------
function OnTeamVictory(team, victory, eventID)
	m_teamVictory = true;
	local localPlayer = Game.GetLocalPlayer();
	if (localPlayer and localPlayer >= 0) then		-- Check to see if there is any local player
		local p = Players[localPlayer]; 
		
		-- [TTP 34847] Handle the specific case where the local player was defeated and it resulted in game victory.  
		-- It is possible that PlayerDefeat was processed first.  In that case the player defeated screen is visible but the game is not paused.
		if(ContextPtr:IsHidden() == false) then
			HandlePauseGame(false);
		end

		-- Only show the defeat screen to other living players.  If a player
		-- was defeated, they would receive another notification.
		if(p:IsAlive()) then
			UI.SetPauseEventID( eventID );	-- Set the pause event, the closing of the end game screen will release it.
			local victoryInfo = GameInfo.Victories[victory];
			victory = victoryInfo and victoryInfo.VictoryType or "VICTORY_DEFAULT";
			View(TeamVictoryData(team, victory));
		end
	end
end

----------------------------------------------------------------
-- Called when the display is to be manually shown.
----------------------------------------------------------------
function OnShowEndGame(playerId)
	if(playerId == nil) then
		playerId = Game.GetLocalPlayer();
	end

	local player = Players[playerId];
	if(player:IsAlive()) then
		local victor, victoryType = Game.GetWinningTeam();
		if(victor == player:GetTeam()) then
			local victory = GameInfo.Victories[victoryType];
			if(victory) then
				View(TeamVictoryData(victor, victory.VictoryType));
				return;
			end
		end
	end

	View(PlayerDefeatedData(playerId, "DEFEAT_DEFAULT"));
end


-- ===========================================================================
--	Chat Panel Functionality
-- ===========================================================================
function OnMultiplayerChat( fromPlayer, toPlayer, text, eTargetType )
	OnChat(fromPlayer, toPlayer, text, eTargetType);
end

function OnChat( fromPlayer, toPlayer, text, eTargetType )
	-- EndGameMenu doesn't play sounds for chat events because the ingame chat panel already does so. 
	if(ContextPtr:IsHidden() == false) then
		local pPlayerConfig = PlayerConfigurations[fromPlayer];
		local playerName = Locale.Lookup(pPlayerConfig:GetPlayerName());

		-- Selecting chat text color based on eTargetType	
		local chatColor :string = "[color:ChatMessage_Global]";
		if(eTargetType == ChatTargetTypes.CHATTARGET_TEAM) then
			chatColor = "[color:ChatMessage_Team]";
		elseif(eTargetType == ChatTargetTypes.CHATTARGET_PLAYER) then
			chatColor = "[color:ChatMessage_Whisper]";  
		end
		
		local chatString	= "[color:ChatPlayerName]" .. playerName;

		-- When whispering, include the whisperee's name as well.
		if(eTargetType == ChatTargetTypes.CHATTARGET_PLAYER) then
			local pTargetConfig :table	= PlayerConfigurations[toPlayer];
			if(pTargetConfig ~= nil) then
				local targetName = Locale.Lookup(pTargetConfig:GetPlayerName());
				chatString = chatString .. " [" .. targetName .. "]";
			end
		end

		-- Ensure text parsed properly
		text = ParseChatText(text);

		chatString			= chatString .. ": [ENDCOLOR]" .. chatColor;
		chatString			= chatString .. text .. "[ENDCOLOR]";

		AddChatEntry( chatString, Controls.ChatStack, m_ChatInstances, Controls.ChatScroll);
	end
end

-------------------------------------------------
-------------------------------------------------
function SendChat( text )
    if( string.len( text ) > 0 ) then
		-- Parse text for possible chat commands
		local parsedText :string;
		local chatTargetChanged :boolean = false;
		local printHelp :boolean = false;
		parsedText, chatTargetChanged, printHelp = ParseInputChatString(text, m_playerTarget);
		if(chatTargetChanged) then
			ValidatePlayerTarget(m_playerTarget);
			UpdatePlayerTargetPulldown(Controls.ChatPull, m_playerTarget);
			UpdatePlayerTargetEditBox(Controls.ChatEntry, m_playerTarget);
			UpdatePlayerTargetIcon(Controls.ChatIcon, m_playerTarget);
		end

		if(printHelp) then
			ChatPrintHelp(Controls.ChatStack, m_ChatInstances, Controls.ChatScroll);
		end

		if(parsedText ~= "") then
			-- m_playerTarget uses PlayerTargetLogic values and needs to be converted  
			local chatTarget :table ={};
			PlayerTargetToChatTarget(m_playerTarget, chatTarget);
			Network.SendChat( parsedText, chatTarget.targetType, chatTarget.targetID );
			UI.PlaySound("Play_MP_Chat_Message_Sent");
		end
    end
    Controls.ChatEntry:ClearString();
end

-------------------------------------------------
-- ParseChatText - ensures icon tags parsed properly
-------------------------------------------------
function ParseChatText(text)
	startIdx, endIdx = string.find(string.upper(text), "%[ICON_");
	if(startIdx == nil) then
		return text;
	else
		for i = endIdx + 1, string.len(text) do
			character = string.sub(text, i, i);
			if(character=="]") then
				return string.sub(text, 1, i) .. ParseChatText(string.sub(text,i + 1));
			elseif(character==" ") then
				text = string.gsub(text, " ", "]", 1);
				return string.sub(text, 1, i) .. ParseChatText(string.sub(text, i + 1));
			elseif (character=="[") then
				return string.sub(text, 1, i - 1) .. "]" .. ParseChatText(string.sub(text, i));
			end
		end
		return text.."]";
	end
	return text;
end

-------------------------------------------------
-------------------------------------------------

function OnMultplayerPlayerConnected( playerID )
	-- EndGameMenu doesn't play sounds for chat events because the ingame chat panel already does so. 
	if( ContextPtr:IsHidden() == false ) then
		OnChat( playerID, -1, PlayerConnectedChatStr);
	end
end

-------------------------------------------------
-------------------------------------------------

function OnMultiplayerPrePlayerDisconnected( playerID )
	-- EndGameMenu doesn't play sounds for chat events because the ingame chat panel already does so. 
	if( ContextPtr:IsHidden() == false ) then
		if(Network.IsPlayerKicked(playerID)) then
			OnChat( playerID, -1, PlayerKickedChatStr);
		else
    		OnChat( playerID, -1, PlayerDisconnectedChatStr);
		end
	end
end

----------------------------------------------------------------
function OnMultiplayerHostMigrated( newHostID : number )
	-- EndGameMenu doesn't play sounds for chat events because the ingame chat panel already does so. 
	if(ContextPtr:IsHidden() == false) then
		OnChat( newHostID, -1, PlayerHostMigratedChatStr);
	end
end

----------------------------------------------------------------
function OnPlayerInfoChanged(playerID)
	if(ContextPtr:IsHidden() == false) then
		-- Update chat target pulldown.
		PlayerTarget_OnPlayerInfoChanged( playerID, Controls.ChatPull, Controls.ChatEntry, Controls.ChatIcon, m_playerTargetEntries, m_playerTarget, false);
	end
end

----------------------------------------------------------------
function OnChatPulldownChanged(newTargetType :number, newTargetID :number)
	local textControl:table = Controls.ChatPull:GetButton():GetTextControl();
	local text:string = textControl:GetText();
	Controls.ChatPull:SetToolTipString(text);
end

-- ===========================================================================
function OnRequestClose()
	if (not m_kPopupDialog:IsOpen()) then
		m_kPopupDialog:AddText(	  Locale.Lookup("LOC_GAME_MENU_QUIT_WARNING"));
		m_kPopupDialog:AddButton( Locale.Lookup("LOC_COMMON_DIALOG_NO_BUTTON_CAPTION"), nil );
		m_kPopupDialog:AddButton( Locale.Lookup("LOC_COMMON_DIALOG_YES_BUTTON_CAPTION"), OnExitGame, nil, nil, "PopupButtonInstanceRed" );
		m_kPopupDialog:Open();
	end
end

-- ===========================================================================
function OnExitGame()
	local pFriends = Network.GetFriends();
	if pFriends ~= nil then
		pFriends:ClearRichPresence();
	end

	Events.UserConfirmedClose();
end

-- ===========================================================================
--	Initialize screen
-- ===========================================================================
function Initialize()

	ContextPtr:SetInputHandler( OnInputHandler, true );
	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetHideHandler( OnHide );

	Controls.ChatEntry:RegisterCommitCallback( SendChat );

	LuaEvents.ShowEndGame.Add(OnShowEndGame);

	Events.SystemUpdateUI.Add( OnUpdateUI );
	Events.UserRequestClose.Add( OnRequestClose );
	Events.PlayerInfoChanged.Add(OnPlayerInfoChanged);
	Events.MultiplayerPrePlayerDisconnected.Add( OnMultiplayerPrePlayerDisconnected );
	Events.MultiplayerPlayerConnected.Add( OnMultplayerPlayerConnected );
	Events.MultiplayerChat.Add( OnMultiplayerChat );

	local ruleset = GameConfiguration.GetValue("RULESET");
	if(ruleset ~= "RULESET_TUTORIAL") then
		Events.TeamVictory.Add(OnTeamVictory);
	end

	Resize();
end

include("EndGameMenu_", true);

Initialize();
 