-- ===========================================================================
--	Logitech ARX Support - Expansion 2 version
-- ===========================================================================
include("TabSupport");
include("InstanceManager");
include("SupportFunctions");
include("AnimSidePanelSupport");
include("TeamSupport");

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================

-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local m_ScreenMode:number = 0;
local m_LocalPlayer:table;
local m_LocalPlayerID:number;
local fullStr:string = "";

-- ===========================================================================
-- Draw the Top 5 Civs screen
-- ===========================================================================
function DrawTop5()
    local civsShown:number = 0;
	local numPlayers:number = 0;
	local playersData:table = {};
    for i = 0, PlayerManager.GetWasEverAliveCount() - 1 do
		local pPlayer = Players[i];
        local lTeamID = -1;
        local team = Teams[pPlayer:GetTeam()];
        if(team ~= nil and #team ~= 1) then
            lTeamID = pPlayer:GetTeam();
        end

		if (pPlayer:IsAlive() == true and pPlayer:IsMajor() == true) then
			table.insert(playersData, {
				Player = pPlayer,
				Score = pPlayer:GetScore(),
                OriginalID = i,
                TeamID = lTeamID;
			});
			numPlayers = numPlayers + 1;
		end
	end

	if not m_bIsPortrait then
		if numPlayers > 5 then
			numPlayers = 5;
		end
	end

    -- now walk the sorted list of civs
	fullStr = fullStr.."<p><span class=title>";
    for iPlayer = 1, numPlayers do
		local pPlayer = playersData[iPlayer].Player;
		if (pPlayer:IsAlive() == true and pPlayer:IsMajor() == true) then
			local pID = pPlayer:GetID();
			local playerConfig:table = PlayerConfigurations[pID];

			local name : string = Locale.Lookup(playerConfig:GetPlayerName());
			local imgname : string = Locale.Lookup(playerConfig:GetLeaderTypeName());
			-- Civ name and score
			if playersData[iPlayer].TeamID ~= -1 then
				teamName = GameConfiguration.GetTeamName(playersData[iPlayer].TeamID);
				fullStr = fullStr.."<img src='Civ_"..imgname..".png' align=left>"..name.." ("..Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", teamName)..")<br/><br/><br/>";
			else
				fullStr = fullStr.."<img src='Civ_"..imgname..".png' align=left>"..name.."<br/><br/><br/>";
			end
		end
    end
	fullStr = fullStr.."</span></p>"


    UI.SetARXTagContentByID("Content", fullStr);
end                              

-- ===========================================================================
-- Clear ARX if exiting to main menu
-- ===========================================================================
function OnExitToMain()
    UI.SetARXTagContentByID("top5", " ");
    UI.SetARXTagContentByID("Content", " ");
end

-- ===========================================================================
-- Refresh the ARX screen
-- ===========================================================================
function RefreshARX()
    if UI.HasARX() then
        m_bIsPortrait = UI.IsARXDisplayPortrait();
		
        if (Game.GetLocalPlayer() ~= -1) then
            m_LocalPlayer = Players[Game.GetLocalPlayer()];
            m_LocalPlayerID = m_LocalPlayer:GetID();
        end

        -- fill in button texts (generating full button HTML here fails for an unknown reason, may have to use JavaScript to be fully dynamic)
        UI.SetARXTagContentByID("top5", "<span class=content>"..Locale.Lookup("LOC_ARX_TOP_5").."</span>");

        -- make buttons visible
        UI.SetARXTagsPropertyByClass("button", "style.visibility", "visible");

		local turn		:number = Game.GetCurrentGameTurn();
		local turnsLeft	:number = Game:GetProperty("NextSafeZoneTurn");
		local turnsStart:number	= Game:GetProperty("StartSafeZoneTurn");
		local safeZonePhase:number = Game:GetProperty("SafeZonePhase");

		local pFalloutManager = Game.GetFalloutManager();
		local falloutDamage :number = pFalloutManager:GetFalloutDamageOverride();

		if(falloutDamage == FalloutDamages.USE_FALLOUT_DEFAULT or falloutDamage == nil) then
			falloutDamage = 0;
		end

        fullStr = "<span class=title><p></p></span> <span class=title>";
		if turnsLeft ~= nil then
			-- When the turns left is zero, the new count is in turnsStart
			if turnsLeft == turn then
				fullStr = fullStr..tostring(turnsStart).." "..Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS_UNTIL_RING_SHRINKS").."<p></p>";
			else
				fullStr = fullStr..tostring(turnsLeft-turn).." "..Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS_UNTIL_RING_SHRINKS").."<p></p>";
			end
		else
			fullStr = fullStr.."<p></p>";
		end
		fullStr = fullStr..Locale.Lookup("LOC_MINIMAP_RED_DEATH_TOOLTIP").." "..Locale.Lookup("LOC_CIV_ROYALE_HUD_DAMAGE")..": "..tostring(falloutDamage).."<p></p>";
		fullStr = fullStr.."</span>";
        DrawTop5();
    end
end

-- ===========================================================================
-- Handle turn change
-- ===========================================================================
function OnTurnBegin()
    RefreshARX();
end

-- ===========================================================================
-- Handle ARX taps
-- ===========================================================================
function OnARXTap(szButtonID:string)
end

-- ===========================================================================
--	Reset the hooks that are visible for hotseat
-- ===========================================================================
function OnLocalPlayerChanged()
	RefreshARX();
end

-- ===========================================================================
--	Update our scores when a city is captured
-- ===========================================================================
function OnCityOccupationChanged(player, cityID)
    RefreshARX();
end

-- ===========================================================================
function Initialize()

	Events.LocalPlayerChanged.Add( OnLocalPlayerChanged );
	Events.TurnBegin.Add( OnTurnBegin );
    Events.ARXTap.Add( OnARXTap );
    Events.ARXOrientationChanged.Add( RefreshARX );
    Events.ExitToMainMenu.Add( OnExitToMain );
	Events.CityOccupationChanged.Add( OnCityOccupationChanged );	

    OnTurnBegin();
end
Initialize();   
