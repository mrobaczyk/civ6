-- ===========================================================================
--	Logitech ARX Support for Pirates Scenario
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
local m_bIsPortrait:boolean = false;
local startYear : number = 1620;
m_kEras = nil;	-- Table of all era names sorted properly.


-- ===========================================================================
-- Draw the Top 4 Pirates screen
-- ===========================================================================
function DrawTop4()
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
			local pPlayerConfig = PlayerConfigurations[pPlayer:GetID()];

			-- make the civs that aren't pirates walk the plank
			if pPlayerConfig ~= nil then
				local pTypeName:string = pPlayerConfig:GetCivilizationTypeName();

				if pTypeName ~= nil then
					if pTypeName == "CIVILIZATION_PIRATES_SCENARIO_PRIVATEER" or
					   pTypeName == "CIVILIZATION_PIRATES_SCENARIO_HOARDER" or
					   pTypeName == "CIVILIZATION_PIRATES_SCENARIO_DREAD_PIRATE" or
					   pTypeName == "CIVILIZATION_PIRATES_SCENARIO_SWASHBUCKLER" then
						table.insert(playersData, {
							Player = pPlayer,
							Score = pPlayer:GetScore(),
							OriginalID = i,
							TeamID = lTeamID;
						});
						numPlayers = numPlayers + 1;
					end
				end
			end
		end
	end

	if(numPlayers > 0) then
		-- Sort players by Score
		table.sort(playersData, function(a, b)
			if (a.Score == b.Score) then
                return a.Player:GetID() < b.Player:GetID();
			end
			return a.Score > b.Score;
		end);
    end

    -- now walk the sorted list of civs
    for iPlayer = 1, numPlayers do
        if civsShown < 5 then
            local pPlayer = playersData[iPlayer].Player;
            if (pPlayer:IsAlive() == true and pPlayer:IsMajor() == true) then
                local pID = pPlayer:GetID();
                local playerConfig:table = PlayerConfigurations[pID];

				local bHasMet = false;
				if(m_LocalPlayer) then
					bHasMet = m_LocalPlayer:GetDiplomacy():HasMet(playersData[iPlayer].OriginalID);
				end

                local name:string;
                local teamName:string;
                local imgname:string;
                local detailsText:string = "";
                local scoreCategories = GameInfo.ScoringCategories;
                local numCategories:number = #scoreCategories;
                local bUseTick = false;
                for i = 0, numCategories - 1 do
                    if scoreCategories[i].Multiplier > 0 then
                        local category:table = scoreCategories[i];
                        if bUseTick then
                            detailsText = detailsText .. " - ";
                        end
                        if category.Name == "LOC_CATEGORY_INCOME_NAME" then
                            detailsText = detailsText .. Locale.Lookup("LOC_HUD_REPORTS_TOTAL_INCOME_PER_TURN") .. "&nbsp; " .. pPlayer:GetCategoryScore(i);
                        else
                            detailsText = detailsText .. Locale.Lookup(category.Name) .. ":&nbsp;" .. pPlayer:GetCategoryScore(i);
                        end
                        bUseTick = true;
                    end
                end

                if (bHasMet == true or pID == Game.GetLocalPlayer() or GameConfiguration.IsHotseat()) then
                    name = Locale.Lookup(playerConfig:GetPlayerName());
                    imgname = Locale.Lookup(playerConfig:GetLeaderTypeName());
                    -- Civ name and score
                    if playersData[iPlayer].TeamID ~= -1 then
                        teamName = GameConfiguration.GetTeamName(playersData[iPlayer].TeamID); 
                        fullStr = fullStr.."<p><span class=title><img src='Civ_"..imgname..".png' align=left>"..name.." ("..Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", teamName).."): "..Locale.Lookup("LOC_WORLD_RANKINGS_SCORE_TAB")..":  "..pPlayer:GetScore().."</span><br>";
                    else
                        fullStr = fullStr.."<p><span class=title><img src='Civ_"..imgname..".png' align=left>"..name..": "..Locale.Lookup("LOC_WORLD_RANKINGS_SCORE_TAB")..":  "..pPlayer:GetScore().."</span><br>";
                    end
                else
                    name = Locale.Lookup("LOC_WORLD_RANKING_UNMET_PLAYER");
                    -- Civ name and score
                    fullStr = fullStr.."<p><img src=Civ_Unmet.png align=left><span class=title>"..name..": "..Locale.Lookup("LOC_WORLD_RANKINGS_SCORE_TAB")..":  "..pPlayer:GetScore().."</span><br>";
                end

				local playerTreasury	:table	= pPlayer:GetTreasury();
				local goldBalance		:number = math.floor(playerTreasury:GetGoldBalance());

                -- Civ scoring info
                fullStr = fullStr.."<span class=content>"..detailsText.."&nbsp;- "..Locale.Lookup("LOC_HUD_REPORTS_HEADER_GOLD")..": "..tostring(goldBalance).."</span>";

                civsShown = civsShown + 1;
            end
        end                
    end

    UI.SetARXTagContentByID("Content", fullStr);
end                              

-- ===========================================================================
-- Draw the Victory Progress screen
-- ===========================================================================
function PopulateVictoryType(victoryType:string, typeText:string)
    fullStr = fullStr.."<p><span class=title>"..Locale.Lookup(typeText);

    -- Tiebreak score functions
	local firstTiebreakerText = "LOC_WORLD_RANKINGS_OVERVIEW_DOMINATION_SCORE";
	local firstTiebreakerFunction = function(p)
		return p:GetScore();
	end;
	local secondTiebreakerText = "LOC_WORLD_RANKINGS_OVERVIEW_DOMINATION_SCORE";
	local secondTiebreakerFunction = function(p)
		return p:GetScore();
	end;
	if (victoryType == "VICTORY_TECHNOLOGY") then
		firstTiebreakerText = "LOC_WORLD_RANKINGS_OVERVIEW_SCIENCE_NUM_TECHS";
		firstTiebreakerFunction = function(p)
			return p:GetStats():GetNumTechsResearched();
		end;
		secondTiebreakerText = "LOC_WORLD_RANKINGS_OVERVIEW_SCIENCE_SCIENCE_RATE";
		secondTiebreakerFunction = function(p)
			return p:GetTechs():GetScienceYield();
		end;
	elseif (victoryType == "VICTORY_CULTURE") then
		firstTiebreakerText = "LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE";
		firstTiebreakerFunction = function(p)
			return p:GetStats():GetTourism();
		end;
		secondTiebreakerText = "LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_CULTURE_RATE";
		secondTiebreakerFunction = function(p)
			return p:GetCulture():GetCultureYield();
		end;
	elseif (victoryType == "VICTORY_CONQUEST") then
		firstTiebreakerText = "LOC_WORLD_RANKINGS_OVERVIEW_DOMINATION_MILITARY_STRENGTH";
		firstTiebreakerFunction = function(p)
			return p:GetStats():GetMilitaryStrength();
		end;
	elseif (victoryType == "VICTORY_RELIGIOUS") then
		firstTiebreakerText = "LOC_WORLD_RANKINGS_OVERVIEW_RELIGION_CITIES_FOLLOWING_RELIGION";
		firstTiebreakerFunction = function(p)
			return p:GetStats():GetNumCitiesFollowingReligion();
		end;
		secondTiebreakerText = "LOC_WORLD_RANKINGS_OVERVIEW_RELIGION_FAITH_RATE";
		secondTiebreakerFunction = function(p)
			return p:GetReligion():GetFaithYield();
		end;
	end

	local numPlayers:number = 0;
	local playersData:table = {};
	for i = 0, PlayerManager.GetWasEverAliveCount() - 1 do
		local pPlayer = Players[i];
		if (pPlayer:IsAlive() == true and pPlayer:IsMajor() == true) then
			table.insert(playersData, {
				Player = pPlayer,
				Score = Game.GetVictoryProgressForTeam(victoryType, pPlayer:GetTeam()), -- Game Core Call
				FirstTiebreakScore = firstTiebreakerFunction(pPlayer),
				SecondTiebreakScore = secondTiebreakerFunction(pPlayer),
				FirstTiebreakSummary = Locale.Lookup(firstTiebreakerText, Round(firstTiebreakerFunction(pPlayer), 1)),
				SecondTiebreakSummary = Locale.Lookup(secondTiebreakerText, Round(secondTiebreakerFunction(pPlayer), 1)),
			});
			numPlayers = numPlayers + 1;
		end
	end

	if(numPlayers > 0) then
		-- Sort players by Score, including tiebreakers
		table.sort(playersData, function(a, b)
			if (a.Score == b.Score) then
				if (a.FirstTiebreakScore == b.FirstTiebreakScore) then
					if (a.SecondTiebreakScore == b.SecondTiebreakScore) then
						return a.Player:GetID() < b.Player:GetID();
					end
					return a.SecondTiebreakScore > b.SecondTiebreakScore;
				end
				return a.FirstTiebreakScore > b.FirstTiebreakScore;
			end
			return a.Score > b.Score;
		end);

		local topPlayer:number = playersData[1].Player:GetID();
		if(topPlayer == m_LocalPlayerID) then
            fullStr = fullStr..Locale.Lookup("LOC_WORLD_RANKINGS_FIRST_PLACE_YOU_SIMPLE");
		else
			-- Determine local player position
			local localPlayerPosition:number = 1;
			local localPlayerPositionText:string;
			local localPlayerPositionLocTag:string;
			for i = 1, numPlayers do
				if(playersData[i].Player == m_LocalPlayer) then
					localPlayerPosition = i;
					break;
				end
			end

			-- Generate position text (ex: "You are in third place" or "You are in position 15")
			if(localPlayerPosition <= 12) then
				localPlayerPositionText = Locale.Lookup("LOC_WORLD_RANKINGS_" .. localPlayerPosition .. "_PLACE");
				localPlayerPositionLocTag = "LOC_WORLD_RANKINGS_OTHER_PLACE_";
			else
				localPlayerPositionText = tostring(localPlayerPosition);
				localPlayerPositionLocTag = "LOC_WORLD_RANKINGS_OTHER_POSITION_";
			end
			localPlayerPositionLocTag = localPlayerPositionLocTag .. "SIMPLE";
			fullStr = fullStr..Locale.Lookup(localPlayerPositionLocTag, localPlayerPositionText);
        end
    end

    fullStr = fullStr.."</span>";
end

local STANDARD_VICTORY_TYPES:table = {
	"VICTORY_TECHNOLOGY",
	"VICTORY_CULTURE",
	"VICTORY_CONQUEST",
	"VICTORY_RELIGIOUS"
};

function IsCustomVictoryType(victoryType:string)
	for _, checkVictoryType in ipairs(STANDARD_VICTORY_TYPES) do
		if victoryType == checkVictoryType then
			return false;
		end
	end
	return true;
end

-- ===========================================================================
-- Clear ARX if exiting to main menu
-- ===========================================================================
function OnExitToMain()
    UI.SetARXTagContentByID("top5", " ");
    UI.SetARXTagContentByID("victory", " ");
    UI.SetARXTagContentByID("gossip", " ");
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
        UI.SetARXTagContentByID("top5", "<span class=content>"..Locale.Lookup("LOC_WORLD_RANKINGS_OVERALL_TAB").."</span>");

        -- make buttons visible
        UI.SetARXTagsPropertyByClass("button", "style.visibility", "visible");

        -- header with civ name
		local playerName;
		if(m_LocalPlayerID and PlayerConfigurations[m_LocalPlayerID]) then
            local bOnTeam = false;
            local team = Teams[m_LocalPlayer:GetTeam()];
            if(team ~= nil and #team ~= 1) then
                bOnTeam = true;
            end

            if bOnTeam then
                playerName = Locale.Lookup(PlayerConfigurations[m_LocalPlayerID]:GetPlayerName())..", "..Locale.Lookup("LOC_WORLD_RANKINGS_TEAM", m_LocalPlayer:GetTeam());
            else
                playerName = Locale.Lookup(PlayerConfigurations[m_LocalPlayerID]:GetPlayerName());
            end
		else
			playerName = Locale.Lookup("LOC_MULTIPLAYER_UNKNOWN");
		end

		local endTurn:number = Game.GetGameEndTurn();
		local turn:number = Game.GetCurrentGameTurn();

		if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_NORMALIZED_TURN") then
			turn = (turn - GameConfiguration.GetStartTurn()) + 1;
			if endTurn > 0 then
				endTurn = endTurn - GameConfiguration.GetStartTurn();
			end
		end

		local startTurn : number = GameConfiguration.GetStartTurn();
		local currentYear : number = Game.GetCurrentGameTurn() + startYear - startTurn + 1;
        local strDate:string = tostring(currentYear).." AD";

        fullStr = "<span class=title>".. playerName .."</span>";
        -- and turn and date
		fullStr = fullStr.."<br><span class=content>" .. Locale.Lookup("LOC_TOP_PANEL_CURRENT_TURN").." "..tostring(turn);

        if m_bIsPortrait then
            fullStr = fullStr..", "..strDate;
        else
            fullStr = fullStr..", "..strDate;
        end
                       
		fullStr = fullStr.."</span>";

		DrawTop4();
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
--	Update our scores when the treasury changes
-- ===========================================================================
function OnTreasuryChanged()
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
	Events.TreasuryChanged.Add(OnTreasuryChanged);

    -- build era table
	m_kEras = {};
	for row:table in GameInfo.Eras() do
		table.insert(m_kEras, {
			Name = row.Name,
			ChronologyIndex = row.ChronologyIndex,
		});
	end	
	table.sort(m_kEras, function(a,b) 
		return a.ChronologyIndex < b.ChronologyIndex;
	end);

    OnTurnBegin();
end
Initialize();   
