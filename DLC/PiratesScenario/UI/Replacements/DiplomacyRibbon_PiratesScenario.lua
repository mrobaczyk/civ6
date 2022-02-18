-- Copyright 2019, Firaxis Games.
-- Leader container list on top of the HUD

include("DiplomacyRibbon");
include("PiratesScenario_PropKeys");
include("Civ6Common");

-- ===========================================================================
-- MEMBERS
-- ===========================================================================
 local m_kTreasureCache:table = {};
 local m_kPirateCache:table = {};
 local m_kFightingCache:table = {};
 local m_kStatType:table = { Treasure=0, Pirate=1,  Fighting=2 };

-- ===========================================================================
-- OVERRIDES
-- ===========================================================================
BASE_UpdateStatValues = UpdateStatValues;
BASE_AddLeader = AddLeader;
BASE_OnTurnBegin = OnTurnBegin;
BASE_FinishAddingLeader = FinishAddingLeader;

local LEADER_ART_OFFSET_X	:number = -4;
local LEADER_ART_OFFSET_Y	:number = -3;

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function AddLeader(iconName : string, playerID : number, kProps: table)
	if (IsPiratePlayer(playerID)) then
		SetRibbonOption(RibbonHUDStats.SHOW);
		BASE_AddLeader(iconName, playerID, kProps);
	end
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function UpdateStatValues( playerID:number, uiLeader:table )	
	uiLeader.Gold:SetHide( false );
	BASE_UpdateStatValues(playerID, uiLeader);

	local pPlayer : table = Players[playerID];

	local scoreCategories : userdata = GameInfo.ScoringCategories;
	
	local treasureScore : number = 0;
	local pirateScore : number = 0;
	local fightingScore : number = 0;

	for i = 0, #scoreCategories - 1 do
		if(scoreCategories[i].PrimaryKey == "CATEGORY_SCENARIO1") then
			treasureScore = pPlayer:GetCategoryScore(i);
		elseif(scoreCategories[i].PrimaryKey == "CATEGORY_SCENARIO2") then
			pirateScore = pPlayer:GetCategoryScore(i);
		elseif(scoreCategories[i].PrimaryKey == "CATEGORY_SCENARIO3") then
			fightingScore = pPlayer:GetCategoryScore(i);
		end
	end



	if (m_kTreasureCache[playerID] ~= treasureScore) then
		m_kTreasureCache[playerID] = treasureScore;
		uiLeader.TreasureFlash:Play();
	end

	if (m_kPirateCache[playerID] ~= pirateScore) then
		m_kPirateCache[playerID] = pirateScore;
		uiLeader.PirateFlash:Play();
	end

	if (m_kFightingCache[playerID] ~= fightingScore) then
		m_kFightingCache[playerID] = fightingScore;
		uiLeader.FightingFlash:Play();
	end


	uiLeader.Treasure:SetText("[ICON_TreasureScore]"..tostring(treasureScore));
	uiLeader.Pirate:SetText("[ICON_PirateScore]"..tostring(pirateScore));
	uiLeader.Fighting:SetText("[ICON_FightingScore]"..tostring(fightingScore));

	local score	:number = Round( pPlayer:GetScore() );
	uiLeader.Score:SetText(score);

	RealizeSize();
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function FinishAddingLeader( playerID:number, uiLeader:table, kProps:table)
	BASE_FinishAddingLeader(playerID, uiLeader, kProps);

	local pPlayerConfig :table	= PlayerConfigurations[playerID];
	local playerName	:string = pPlayerConfig:GetPlayerName();
	local civType		:string = pPlayerConfig:GetCivilizationTypeName();
	local civUniqueAbilities : table, _, _ = GetCivilizationUniqueTraits( civType );

	local toolTipString : string = Locale.Lookup("LOC_"..civType.."_NAME");
	if(playerName ~= nil and playerName ~= pPlayerConfig:GetLeaderName())then
		toolTipString = playerName .. "[NEWLINE]" .. toolTipString;
	end
	for _, item in ipairs(civUniqueAbilities) do
		if (item.Name ~= nil and item.Name ~= "NONE") then
			toolTipString = toolTipString .. "[NEWLINE][NEWLINE]"..tostring( Locale.Lookup( item.Description ) );
		end
	end
	uiLeader.Portrait:SetToolTipString(toolTipString);

	uiLeader.TreasureFlash:RegisterAnimCallback(function() OnAnimStartGlow( uiLeader, m_kStatType.Treasure ); end );
	uiLeader.PirateFlash:RegisterAnimCallback(function() OnAnimStartGlow( uiLeader,  m_kStatType.Pirate ); end );
	uiLeader.FightingFlash:RegisterAnimCallback(function() OnAnimStartGlow( uiLeader,  m_kStatType.Fighting ); end );
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function OnTurnBegin(playerID:number)
	SetRibbonOption(RibbonHUDStats.SHOW);
	BASE_OnTurnBegin(playerID);

	if(IsPiratePlayer(playerID))then
		local uiLeader : table = GetLeaderInstanceByID(playerID);
		if(uiLeader ~= nil)then
			local pSize : table = uiLeader.LeaderContainer:GetSize();
			uiLeader.ActiveLeaderAndStats:SetSizeVal( pSize.x + LEADER_ART_OFFSET_X, pSize.y + LEADER_ART_OFFSET_Y );
		end
	end
end

-- ===========================================================================
--	Text Glow Start Callback
-- ===========================================================================
function OnAnimStartGlow ( uiLeader:table, type:number )
	local flash:object;
	local field:object;

	if(type == m_kStatType.Treasure) then
		flash = uiLeader.TreasureFlash;
		field = uiLeader.Treasure;
	
	elseif (type == m_kStatType.Pirate) then
		flash = uiLeader.PirateFlash;
		field = uiLeader.Pirate;

	elseif (type == m_kStatType.Fighting) then
		flash = uiLeader.FightingFlash;
		field = uiLeader.Fighting;

	end



	local progress:number = flash:GetProgress();

	if (progress < 1) then
		local alpha:number = (-1 * math.cos(progress * math.pi * 6) + 1) *.5; -- 3 peaks in [0, 1] ending on x-axis
		field:SetColor(UI.GetColorValue(1, 1, 0, alpha), 1);
	else
		field:SetColor(UI.GetColorValue(0, 0, 0, 1), 1);
		flash:Stop();
		flash:SetProgress(0);
	end
end

