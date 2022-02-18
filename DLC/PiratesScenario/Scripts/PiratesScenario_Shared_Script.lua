--[[ =======================================================================

	Pirates Scenario GameCore Game State Utilities

	Contains gamecore side scripting related to the game state that is used
	from multiple locations.
-- =========================================================================]]
include "PiratesScenario_PropKeys"
include "PlotFiltering"


-- ===========================================================================
--	Defines
-- ===========================================================================
local NO_PLAYER :number = -1;
local NO_DISTRICT :number = -1;
local INVALID_PLOT :number = -1;
local NO_IMPROVEMENT :number = -1;

local CustomNotificationParameters = {
	CivicDiscovered_CivicIndex = 0xE4D94F18; -- Matches 
};

m_GetCaptureBoatResults = {
	-- Valued from worst to best capture state.
	NO_SHIPS			= 0,	-- No enemy ships is available
	MAX_HIT_POINTS		= 1,	-- Ship can't be captured because it too many max hitpoints (flagships and infamous pirates)
	NOT_DAMAGED			= 2,	-- Enemy ships have too much health.
	CAPTURABLE			= 3,	-- Capturable ship found.
}
m_kDefaultCaptureBoatResult = { Result = m_GetCaptureBoatResults.NO_SHIPS, CaptureUnit = nil, };

m_GetShorePartyResults = {
	-- Valued from worst to best state.
	NO_MOVEMENT			= 0,	-- Not enough movement available.
	NO_LAND				= 1,	-- No valid land is adjacent to the unit.
	VALID				= 2,	-- Shore Party action is possible.
}
m_kDefaultShorePartyResult = {Result = m_GetShorePartyResults.NO_LAND };

m_GetShorePartyEmbarkResults = {
	-- Valued from worst to best state.
	NO_MOVEMENT			= 0,	-- Not enough movement available.
	NO_SHIP				= 1,	-- No valid naval ship is adjacent to the unit.
	VALID				= 2,	-- Shore Party Embark action is possible.
}
m_kDefaultShorePartyEmbarkResult = { Result = m_GetShorePartyEmbarkResults.NO_SHIP, EmbarkShip = nil, };

g_GetCareeningResults = {
	INVALID_UNIT		= 0,	-- Unit data was invalid.
	NO_DAMAGE			= 1,	-- Can't careen when not damaged.
	NO_MOVEMENT			= 2,	-- No movement available to careen.
	ENEMY_TERRITORY		= 3, 	-- Can't careen in enemy territory.
	DEEP_WATER			= 4,	-- Careening requires shallow water.
	VALID				= 5,	-- Careening is a valid action now.
}
g_kDefaultGetCareeningResults = {Result = g_GetCareeningResults.VALID };

g_GetChainShotResults = {
	-- Valued from worst to best state.
	INVALID_DATA		= 0,	-- Invalid input data.
	NO_ENEMY			= 1,	-- no enemy units on plot.
	VALID				= 2,	-- This is a valid plot for the chain shot ability.
}
g_kDefaultChainShotResult = {Result = g_GetChainShotResults.VALID };

local ms_BuriedTreasureImprov :number = GameInfo.Improvements[BURY_TREASURE_IMPROVEMENT].Index;
local ms_FloatingTreasureImprov :number = GameInfo.Improvements["IMPROVEMENT_FLOATING_TREASURE"].Index;


-- ===========================================================================
--	Misc Helper Functions
-- ===========================================================================
-- Returns a table of all the alive pirate player objects.
function GetAlivePiratePlayers()
	local kPiratePlayers = {};
	local aPlayers = PlayerManager.GetAliveMajors();
	for _, pPlayer in ipairs(aPlayers) do
		if(IsPiratePlayer(pPlayer:GetID())) then
			table.insert(kPiratePlayers, pPlayer);
		end
	end
	return kPiratePlayers;
end 

-- Returns a table of all the alive colonial player objects.
function GetAliveColonialPlayers()
	local kColonialPlayers = {};
	local aPlayers = PlayerManager.GetAliveMajors();
	for _, pPlayer in ipairs(aPlayers) do
		if(IsColonyPlayer(pPlayer:GetID())) then
			table.insert(kColonialPlayers, pPlayer);
		end
	end
	return kColonialPlayers;
end 

function GetAliveInfamousPirates()
	local infamousPirates = {};
	local infamousPlayer = Players[INFAMOUS_PIRATES_PLAYERID];
	if(infamousPlayer == nil) then
		print("Infamous pirate player missing!");
		return nil;
	end

	local pInfamousUnits : object = infamousPlayer:GetUnits();
	for i, pUnit in pInfamousUnits:Members() do
		-- Assuming the unit is an infamous pirate if they have KillInfamyPoints. This might not be the best assumption.
		if(pUnit:GetProperty(g_unitPropertyKeys.KillInfamyPoints) ~= nil) then
			table.insert(infamousPirates, pUnit);
		end
	end

	return infamousPirates;
end

function IsInfamousPirate(iPlayerID :number, iUnitID :number)
	if(iPlayerID ~= INFAMOUS_PIRATES_PLAYERID) then
		return false;
	end

	local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
	return IsInfamousPirateUnit(pUnit);
end

function IsInfamousPirateUnit(pUnit :object)
	if(pUnit == nil) then
		return false;
	end

	local killInfamy = pUnit:GetProperty(g_unitPropertyKeys.KillInfamyPoints);
	if(killInfamy == nil or killInfamy <= 0) then
		return false;
	end

	return true;
end

function IsFlagship(pUnit :object)
	if(pUnit == nil) then
		return false;
	end

	local pUnitAbility :object = pUnit:GetAbility();
	local abilityFlagCount :number = pUnitAbility:GetAbilityCount(FLAGSHIP_ABILITY_NAME);
	if(abilityFlagCount == nil or abilityFlagCount < 1) then
		return false;
	end

	return true;
end

-- Returns the city instance adjacent to the given unit.  Returns nil if unit is not adjacent to a city.
function FindAdjacentCity(pUnit :object)
	if(pUnit == nil) then
		return;
	end

	local adjPlots :table = Map.GetAdjacentPlots(pUnit:GetX(), pUnit:GetY());
	for index, curPlot in ipairs(adjPlots) do
		if(curPlot:IsCity()) then
			local pOwner :object = Players[curPlot:GetOwner()];
			if(pOwner ~= nil) then
				local pOwnerCities :object = pOwner:GetCities();
				if(pOwnerCities ~= nil) then
					local pCity :object = pOwnerCities:FindClosest(curPlot:GetX(), curPlot:GetY());
					return pCity;
				end
			end
		end
	end

	return nil;
end

-- plotX/plotY - [Optional] Location of the infamy change event.  If set, display world view text of the event.
function ChangeScore(playerID :number, scoreData :table, scoreDelta :number, plotX :number, plotY :number)
	local pPlayer = Players[playerID];
	if(pPlayer == nil) then
		print("ERROR: player missing!");
		return;
	end

	-- Only Pirate players score points.
	if(not IsPiratePlayer(playerID)) then
		return;
	end
	
	if(scoreData.Name == g_scoreTypes.Treasure.Name) then
		pPlayer:ChangeScoringScenario1(scoreDelta);
	elseif(scoreData.Name == g_scoreTypes.InfamousPirate.Name) then
		pPlayer:ChangeScoringScenario2(scoreDelta);
	else
		pPlayer:ChangeScoringScenario3(scoreDelta);
	end
	

	if(plotX ~= nil and plotY ~= nil) then
		local scoreText :string = "";
		if(scoreDelta > 0) then
			scoreText = "+";
		elseif(scoreDelta < 0) then
			scoreText = "-";
		end
		scoreText = scoreText .. tostring(scoreDelta);
		local worldText :string = Locale.Lookup(scoreData.WorldText, scoreText);

		local messageData : table = {
			MessageType = 0;
			MessageText = worldText;
			PlotX = plotX;
			PlotY = plotY;
			Visibility = RevealedState.VISIBLE;
			TargetID = playerID;
		}
		Game.AddWorldViewText(messageData);
	end
end

function IsTreasureFleetGoldShip(pUnit :object)
	if(pUnit == nil) then
		return false;
	end

	local goldShip :number = pUnit:GetProperty(g_unitPropertyKeys.TreasureFleetGoldShip);
	if(goldShip ~= nil and goldShip > 0) then
		return true;
	end

	return false;
end

function IsPlotAlreadyImproved(pPlot : object)
	if(pPlot:GetImprovementType() ~= -1)then return true; end

	return false;
end

-- ===========================================================================
--	Property Timer Helper Functions
-- ===========================================================================
g_PropertyTimerStatusTypes =
{
	Status_Ready = "Status_Ready",
	Status_Active = "Status_Active",
	Status_Recharging = "Status_Recharging",
};
g_DefaultPropertyTimerStatus = { Status = g_PropertyTimerStatusTypes.Status_Ready, TurnsRemaining = 0 };

-- Sets the dynamic property to the current game turn.  This "restarts" the property timer.
-- specificPlayerID [OPTIONAL] If set, this indicates that this property is player specific and must be instanciated with GetPlayerSpecificPropKey() before being used.
function StartPropertyTimer(pPropertyObject :object, lastUsedTimePropKey :string, specificPlayerID :number) 
	local lastUsedPropertyName = lastUsedTimePropKey;
	if(specificPlayerID ~= nil and specificPlayerID ~= NO_PLAYER) then
		lastUsedPropertyName = GetPlayerSpecificPropKey(lastUsedPropertyName, specificPlayerID);
	end	

	pPropertyObject:SetProperty(lastUsedPropertyName, Game.GetCurrentGameTurn());
end

-- Get the Property Timer Status for properties tied to a property on an object.
function GetPropertyTimerStatus(pPropertyObject :object, lastUsedTimePropKey :string, specificPlayerID :number, timerDuration :number, timerDebounce :number)
	-- Using metatable trick to allow fallback to default values.
	local retValue = {};
	setmetatable(retValue, {__index = g_DefaultPropertyTimerStatus});

	if(pPropertyObject == nil) then
		return retValue;
	end

	local lastUsedPropertyName = lastUsedTimePropKey;
	if(specificPlayerID ~= nil and specificPlayerID ~= NO_PLAYER) then
		lastUsedPropertyName = GetPlayerSpecificPropKey(lastUsedPropertyName, specificPlayerID);
	end

	local lastUsedTime = pPropertyObject:GetProperty(lastUsedPropertyName);
	return CalcPropertyTimerStatus(lastUsedTime, timerDuration, timerDebounce);
end

-- Calculate the Property Timer Status for given values.
-- lastUsedTurn [number] - The property value for the last time the property timer was used. If nil, we assume the property timer has never been used and is ready to use now.
function CalcPropertyTimerStatus(lastUsedTurnProp, timerDuration :number, timerDebounce :number)
	-- Using metatable trick to allow fallback to default values.
	local retValue = {};
	setmetatable(retValue, {__index = g_DefaultPropertyTimerStatus});

	if(lastUsedTurnProp == nil) then
		-- property is missing, assume this means the ability is ready to use.
		return retValue;
	end

	local currentTurn = Game.GetCurrentGameTurn();
	if(currentTurn < (lastUsedTurnProp + timerDuration)) then
		-- Ability is still active.
		retValue.Status = g_PropertyTimerStatusTypes.Status_Active;
		retValue.TurnsRemaining = lastUsedTurnProp + timerDuration - currentTurn;
	elseif(currentTurn < (lastUsedTurnProp + timerDuration + timerDebounce)) then
		-- Ability is recharging
		retValue.Status = g_PropertyTimerStatusTypes.Status_Recharging;
		retValue.TurnsRemaining = lastUsedTurnProp + timerDuration + timerDebounce - currentTurn;
	end
	return retValue;
end


-- ===========================================================================
--	Notification Helper Functions
-- ===========================================================================
-- iNotifyPlayer - (Optional) If set, sends notification only to this player.  If not set, notification is sent to all players.
-- pProperties - (Optional) Additional property table data to be stored in the notification.
function SendNotification_Plot(notificationData :table, pPlot :object, iNotifyPlayer :number, pProperties :table)
	if (pPlot == nil) then
		return false;
	end

	local msgString = Locale.Lookup(notificationData.Message);
	local sumString = Locale.Lookup(notificationData.Summary);

	return SendNotification_PlotExtra(notificationData.Type, notificationData.Message, notificationData.Summary, pPlot, iNotifyPlayer, pProperties);
end

-- pPlot - (Optional) plot object for location associated with notification.
-- pProperties - (Optional) Additional property table data to be stored in the notification.
function SendNotification_PlotExtra(notificationType :number, notifyMessage :string, notifySummary :string, pPlot :object, iNotifyPlayer :number, pProperties :table)
	local notificationData = pProperties or {};
	notificationData[ParameterTypes.MESSAGE] = notifyMessage;
	notificationData[ParameterTypes.SUMMARY] = notifySummary;

	if(pPlot ~= nil) then
		notificationData[ParameterTypes.LOCATION] = { x = pPlot:GetX(), y = pPlot:GetY() };
	end

	if(iNotifyPlayer ~= nil) then
		NotificationManager.SendNotification(iNotifyPlayer, notificationType, notificationData);
	else
		local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
		for k, iPlayerID in ipairs(pAllPlayerIDs) do
			NotificationManager.SendNotification(iPlayerID, notificationType, notificationData);
		end
	end
	return true;
end


-- ===========================================================================
--	Pirate Faction Scripting
-- ===========================================================================
-- Reveal the nearest unrevealed port.
-- plotX/plotY - hex location from which the nearest port will be calculated.
function RevealNearestPort(iPlayerID :number, plotX :number, plotY :number)
	local closestCity = nil;
	local closestDistance = -1;
	local pPlayerVis = PlayersVisibility[iPlayerID];

	local aPlayers = PlayerManager.GetAliveMajors();
	for loop, pPlayer in ipairs(aPlayers) do
		if(IsColonyPlayer(pPlayer:GetID())) then
			for _,pCity in pPlayer:GetCities():Members() do
				if(pPlayerVis:IsRevealed(pCity:GetX(), pCity:GetY()) == false) then
					local curDistance = Map.GetPlotDistance(plotX, plotY, pCity:GetX(), pCity:GetY());
					if(closestDistance == -1 or closestDistance > curDistance) then
						closestCity = pCity;
						closestDistance = curDistance;
					end				
				end
			end
		end
	end

	if(closestCity ~= nil) then
		local cityX = closestCity:GetX();
		local cityY = closestCity:GetY();
		local revealRange = REVEAL_CITY_RANGE;
		for dx = -revealRange, revealRange, 1 do
			for dy = -revealRange, revealRange, 1 do
				local revealPlot = Map.GetPlotXYWithRangeCheck(cityX, cityY, dx, dy, revealRange);
				if(revealPlot) then
					pPlayerVis:ChangeVisibilityCount(revealPlot:GetIndex(), 0);
				end
			end
		end
	end
end

function SelectNewQuest(iPlayerID :number)
	print("Selecting New Quest for Player " .. tostring(iPlayerID));
	local pPlayer = Players[iPlayerID];
	if(pPlayer == nil) then
		return;
	end

	local QUESTTYPE_TREASURE		= "QUESTTYPE_TREASURE";
	local availableQuests = {};

	table.insert(availableQuests, QUESTTYPE_TREASURE);

	if(#availableQuests <= 0) then
		print("No Quests available for Player " .. tostring(iPlayerID));
		return;
	end

	local questRand :number = RandRange(1, #availableQuests, "Quest Type Roll");
	local questType = availableQuests[questRand];
	print("QuestType=" .. tostring(questType) .. ", Player=" .. tostring(iPlayerID));
	if(questType == QUESTTYPE_TREASURE) then
		TreasureMapDrop(iPlayerID);
	end
end


function TreasureMapDrop(iPlayerID :number)
	print("Dropping new treasure map for player " .. tostring(iPlayerID));
	NewTreasureMap(iPlayerID);

	-- Captain Kidd Journal Roll
	local pPlayer :object = Players[iPlayerID];
	if(pPlayer == nil) then
		print("Player missing!");
		return;
	end

	local pPlayerCulture :object = pPlayer:GetCulture();
	if(pPlayerCulture == nil) then
		print("Player Culture missing!");
		return;
	end

	local numSlots :number = pPlayerCulture:GetNumPolicySlots();
	local hasJournal :boolean = false;
	local journalPolicyIndex :number = GameInfo.Policies["POLICY_RELIC_CAPTAIN_KIDD_JOURNAL"].Index;
	for i = 0, numSlots-1, 1 do
		local	iSlotPolicy	:number = pPlayerCulture:GetSlotPolicy(i);
		if(iSlotPolicy == journalPolicyIndex) then
			hasJournal = true;
			break;
		end
	end

	if(not hasJournal) then
		return;
	end

	local randNum :number = RandRange(0, 100, "Captain Kidd Journal Treasure Map Chance");
	local outcomeString :string = (randNum <= RELIC_KIDD_JOURNAL_MAP_CHANCE and "Success" or "Failed");
	print("Captain Kidd Journal Treasure Map Random Roll=" .. outcomeString  .. ", randNum=" .. tostring(randNum) .. ", chance=" .. tostring(RELIC_KIDD_JOURNAL_MAP_CHANCE));
	if(randNum <= RELIC_KIDD_JOURNAL_MAP_CHANCE) then
		NewTreasureMap(iPlayerID);
	end
end

function NewTreasureMap(iPlayerID :number)
	local randNum :number = RandRange(0, 100, "New Treasure for Treasure Map Chance");
	local outcomeString :string = (randNum <= TREASURE_MAP_NEW_TREASURE_CHANCE and "Success" or "Failed");
	print("New Treasure for Treasure Map Random Roll=" .. outcomeString  .. ", randNum=" .. tostring(randNum) .. ", chance=" .. tostring(TREASURE_MAP_NEW_TREASURE_CHANCE));

	local unknownTreasures :table = nil;
	if(randNum > TREASURE_MAP_NEW_TREASURE_CHANCE) then
		-- Try to use find an existing treasure that is unknown to the current player.
		unknownTreasures = GetUnknownTreasures(iPlayerID);
	end

	if(unknownTreasures == nil or #unknownTreasures <= 0) then
		unknownTreasures = {};
		local newTreasureIndex :number = CreateNewTreasure(iPlayerID);
		if(newTreasureIndex == INVALID_PLOT) then
			print("ERROR: unable to create new treasure.");
			return;
		else
			table.insert(unknownTreasures, newTreasureIndex);
		end
	end

	local treasureRand :number = RandRange(1, #unknownTreasures, "New Treasure Map Roll");
	local treasurePlotIndex :number = unknownTreasures[treasureRand];
	MakeTreasureMapForTreasurePlot(iPlayerID, treasurePlotIndex);
end

function GetUnknownTreasures(iPlayerID :number)
	local unknownTreasures :table = {};
	local pPlayer :object = Players[iPlayerID];
	if(pPlayer == nil) then
		return nil;
	end

	local knownTreasures : table = pPlayer:GetProperty(g_playerPropertyKeys.TreasureMaps);

	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do	
		local curPlot :object = Map.GetPlotByIndex(iPlotIndex);
		if((curPlot:GetImprovementType() == ms_BuriedTreasureImprov or curPlot:GetImprovementType() == ms_FloatingTreasureImprov)
			and curPlot:GetImprovementOwner() ~= iPlayerID
			and not curPlot:IsImprovementPillaged()) then
			-- Do I already have a treasure map for this treasure?
			if(not IsKnownTreasure(knownTreasures, curPlot:GetIndex())) then
				table.insert(unknownTreasures, curPlot:GetIndex());
			end
		end
	end

	return unknownTreasures;
end

function IsKnownTreasure(knownTreasures :table, treasurePlotIndex :number)
	if(knownTreasures == nil or #knownTreasures < 1) then
		return false;
	end

	for loop, curKnown in ipairs(knownTreasures) do
		if(curKnown.TreasurePlotIndex == treasurePlotIndex) then
			return true;
		end
	end

	return false;
end

function MakeTreasureMapForTreasurePlot(iPlayerID :number, treasurePlotIndex :number)
	local treasurePlot :object = Map.GetPlotByIndex(treasurePlotIndex);
	if(treasurePlot == nil) then
		print("ERROR: treasurePlot missing.");
		return;
	end

	local pPlayer = Players[iPlayerID];
	if(pPlayer == nil) then
		print("ERROR: pPlayer missing.");
		return;
	end

	print("Adding Treasure Map (" .. tostring(treasurePlot:GetX()) .. "," .. tostring(treasurePlot:GetY()) .. ") for player " .. tostring(iPlayerID));
	local newTreasureMap :table = {};
	newTreasureMap.TreasurePlotIndex = treasurePlotIndex;
	newTreasureMap.ZoneSize = PIRATE_TREASURE_SEARCH_ZONE_SIZE;

	-- Create a search area randomly around the treasure location.
	local searchCenterPlots :table = Map.GetNeighborPlots(treasurePlot:GetX(), treasurePlot:GetY(), PIRATE_TREASURE_SEARCH_ZONE_SIZE);
	local searchCenterRand :number = RandRange(1, #searchCenterPlots, "Treasure Search Zone Center Roll");
	local searchCenterPlot :object = searchCenterPlots[searchCenterRand];
	print("New Treasure Search Location Center Selected (" .. tostring(searchCenterPlot:GetX()) .. "," .. tostring(searchCenterPlot:GetY()) .. "), TreasureOwner=" .. tostring(searchCenterPlot:GetImprovementOwner()) .. " for player " .. tostring(iPlayerID));
	newTreasureMap.SearchCenterIndex = searchCenterPlot:GetIndex();

	local treasureMaps :table = pPlayer:GetProperty(g_playerPropertyKeys.TreasureMaps);
	if(treasureMaps == nil) then
		treasureMaps = {};
	end
	table.insert(treasureMaps, newTreasureMap);
	pPlayer:SetProperty(g_playerPropertyKeys.TreasureMaps, treasureMaps);

	local ownerName :string = Locale.Lookup("LOC_UNKNOWN_TREASURE_OWNER");
	local treasureOwnerID :number = treasurePlot:GetImprovementOwner();
	if(treasureOwnerID == NO_PLAYER) then
		local treasureOwnerNameProp :string = treasurePlot:GetProperty(g_plotPropertyKeys.TreasureOwnerName);
		if(treasureOwnerNameProp ~= nil) then
			ownerName = Locale.Lookup(treasureOwnerNameProp);
		end
	else
		local pTreasureOwnerConfig :object = PlayerConfigurations[treasureOwnerID];
		ownerName = pTreasureOwnerConfig:GetPlayerName();
	end
	local msgString :string = Locale.Lookup(g_NotificationsData.NewBuriedTreasure.Message, ownerName);
	local summaryString :string = Locale.Lookup(g_NotificationsData.NewBuriedTreasure.Summary, ownerName);

	local notifyProperties = {};
	notifyProperties[g_notificationKeys.TreasurePlotIndex] = treasurePlotIndex;
	notifyProperties[NotificationParameterTypes.CanUserDismiss] = false;
	SendNotification_PlotExtra(g_NotificationsData.NewBuriedTreasure.Type, msgString, summaryString, searchCenterPlot, iPlayerID, notifyProperties);
end

function CreateNewTreasure(iPlayerID :number)
	local randNum :number = RandRange(0, 100, "New Treasure Floating Chance");
	local outcomeString :string = (randNum <= TREASURE_MAP_FLOATING and "Success" or "Failed");
	print("New Treasure Floating Random Roll=" .. outcomeString  .. ", randNum=" .. tostring(randNum) .. ", chance=" .. tostring(TREASURE_MAP_FLOATING));

	local isFloating :boolean = randNum <= TREASURE_MAP_FLOATING;
	local treasureImproName :string = isFloating and "IMPROVEMENT_FLOATING_TREASURE" or "IMPROVEMENT_BURIED_TREASURE";
	local treasureImproData :object = GameInfo.Improvements[treasureImproName];
	if(treasureImproData == nil) then
		print("ERROR: Missing improvement data for new treasure " .. tostring(treasureImproName));
		return INVALID_PLOT;
	end	
	
	local pPlayer :object = Players[iPlayerID];	
	if(pPlayer == nil) then
		print("ERROR: Missing pPlayer");
		return INVALID_PLOT;
	end

	local pPlayerUnits : object = pPlayer:GetUnits();
	if(pPlayerUnits == nil) then
		print("ERROR: Missing pPlayerUnits");
		return INVALID_PLOT;
	end

	-- IMPORTANT:  The following filtering uses a non-sequential table and is only network safe because all filtering are deterministic and non-order dependant!
	local unsortedPlots :table = {};
	local curPlotCount = 0;
	local scanRange :number = PIRATE_TREASURE_MAX_DIST_UNITS;

	-- Initial Filter, Must be Passable, Correct Terrain for Treasure, No Improvement, Not in Someone's Territory.
	for i, pUnit in pPlayerUnits:Members() do
		for dx = -scanRange, scanRange - 1, 1 do
			for dy = -scanRange, scanRange - 1, 1 do
				local curPlot :object = Map.GetPlotXYWithRangeCheck(pUnit:GetX(), pUnit:GetY(), dx, dy, scanRange);
				if (curPlot ~= nil
					and not curPlot:IsImpassable()																		-- Passable plot
					and curPlot:GetImprovementType() == NO_IMPROVEMENT													-- Not improved
					and curPlot:IsOwned() == false																	-- Not owned
					and ( (isFloating and curPlot:IsWater()) or (not isFloating and not curPlot:IsWater()) ) ) then		-- water check
					unsortedPlots[curPlot:GetIndex()] = curPlot;
					curPlotCount = curPlotCount + 1;
				end
			end
		end
	end

	print("Initial Treasure Plots: " .. tostring(curPlotCount));

	-- Remove all plots that are too close to the player's units.
	local removedPlotCount :number = 0;
	scanRange = PIRATE_TREASURE_MIN_DIST_UNITS;
	for i, pUnit in pPlayerUnits:Members() do
		for dx = -scanRange, scanRange - 1, 1 do
			for dy = -scanRange, scanRange - 1, 1 do
				local scanPlot :object = Map.GetPlotXYWithRangeCheck(pUnit:GetX(), pUnit:GetY(), dx, dy, scanRange);
				if(scanPlot ~= nil and unsortedPlots[scanPlot:GetIndex()] ~= nil) then
					unsortedPlots[scanPlot:GetIndex()] = nil;
					removedPlotCount = removedPlotCount + 1;
					curPlotCount = curPlotCount - 1;
				end
			end
		end
	end

	print("Removing Treasure Plots too close to player units. Plots removed: " .. tostring(removedPlotCount) .. ", Plots Remaining: " .. tostring(curPlotCount));

	-- Convert unsortedPlots into treasurePlots, which is deterministic and ipair safe 
	local treasurePlots :table = {};
	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
		if(unsortedPlots[iPlotIndex] ~= nil) then
			table.insert(treasurePlots, unsortedPlots[iPlotIndex]);
		end
	end

	if(#treasurePlots > 0) then
		local treasureRand :number = RandRange(1, #treasurePlots, "Treasure Plot Roll");
		local treasurePlot = treasurePlots[treasureRand];

		-- Use an infamous pirate's name as the owner of randomly generated treasure.
		local infamousPirateRand :number = RandRange(1, #g_InfamousPirates, "Infamous Pirate Owner for Treasure Plot Roll");
		local infamousPirateName :string = g_InfamousPirates[infamousPirateRand].Name;

		treasurePlot:SetProperty(g_plotPropertyKeys.TreasureOwnerName, infamousPirateName);

		print("New Treasure (" .. tostring(treasureImproName) ..") Created (" .. tostring(treasurePlot:GetX()) .. "," .. tostring(treasurePlot:GetY()) .. ") for player=" .. tostring(iPlayerID) .. ", OwnerName=" .. tostring(infamousPirateName));
		ImprovementBuilder.SetImprovementType(treasurePlot, treasureImproData.Index, NO_PLAYER);

		return treasurePlot:GetIndex();
	end

	return INVALID_PLOT;
end


-- Scan for a capturable boat in target plot.  Returns the first instance of the best m_GetCaptureBoatResults possible.
-- Returns a table consisting of...
--	Result		- A m_GetCaptureBoatResults value indicating the result.
--  CaptureUnit	- unit instance of the unit with the highest capture result found.  This can be nil. 
function GetCaptureBoat(iCapturePlayerID :number, pTargetPlot :object)
	-- Using metatable trick to allow fallback to default values.
	local results = {};
	setmetatable(results, {__index = m_kDefaultCaptureBoatResult});

	local iPatronPlayerID :number = NO_PLAYER;
	local pCapturePlayer :object = Players[iCapturePlayerID];
	if(pCapturePlayer ~= nil) then
		local patronProp :number = pCapturePlayer:GetProperty(g_playerPropertyKeys.PrivateerPatron);
		if(patronProp ~= nil) then
			iPatronPlayerID = patronProp;
		end
	end

	local targetUnits :table = Map.GetUnitsAt(pTargetPlot);
	if targetUnits ~= nil then
		for pTargetUnit :object in targetUnits:Units() do
			local pTargetUnitData :object = GameInfo.Units[pTargetUnit:GetType()];
			if(pTargetUnit:GetOwner() ~= iCapturePlayerID
				and pTargetUnit:GetOwner() ~= iPatronPlayerID
				and pTargetUnitData.CanCapture == true		
				and pTargetUnitData.Domain == "DOMAIN_SEA") then	-- Must be a boat.
				if(pTargetUnit:GetMaxDamage() > 100) then
					-- Can't capture ships with more than 100 MaxDamage (flagships and infamous pirates).
					if(results.CaptureUnit == nil) then
						results.Result = m_GetCaptureBoatResults.MAX_HIT_POINTS;
						results.CaptureUnit = pTargetUnit;						
					end
				elseif(pTargetUnit:GetDamage() >= CAPTURE_BOAT_DAMAGE_MIN) then
					-- Found capturable boat.  We're done.
					results.Result = m_GetCaptureBoatResults.CAPTURABLE;
					results.CaptureUnit = pTargetUnit;
					break;
				elseif(results.CaptureUnit == nil) then
					-- unit is not damaged enough to capture. Note and keep searching.
					results.Result = m_GetCaptureBoatResults.NOT_DAMAGED;
					results.CaptureUnit = pTargetUnit;
				end
			end
		end
	end

	return results;
end

-- Calculate the CaptureBoatStatus for a given unit.
-- Returns a table consisting of...
--	Result		- A m_GetCaptureBoatResults value indicating the result.
--  CaptureUnit	- unit instance of the unit with the highest capture result found.  This can be nil. 
function GetCaptureBoatStatus(pCapturingUnit :object)
	local results = {};
	setmetatable(results, {__index = m_kDefaultCaptureBoatResult});

	local adjPlots = Map.GetAdjacentPlots(pCapturingUnit:GetX(), pCapturingUnit:GetY());
	for _, adjPlot in ipairs(adjPlots) do
		local adjPlotCapResults = GetCaptureBoat(pCapturingUnit:GetOwner(), adjPlot);
		if(adjPlotCapResults.Result == m_GetCaptureBoatResults.CAPTURABLE) then
			results = adjPlotCapResults;
			break;
		elseif(results.Result == m_GetCaptureBoatResults.NO_SHIPS) then
			results = adjPlotCapResults;
		end
	end

	return results;
end

-- Can the given unit start the VisitTavern action right now?
function VisitTavern_CanStart(pUnit :object)
	if(pUnit == nil) then
		return false;
	end

	local pCity :object = FindAdjacentCity(pUnit);
	if(pCity == nil) then
		return false;
	end

	local timerStatus = GetPropertyTimerStatus(pCity, g_cityPlayerSpecificKeys.LastTavernTurn, pUnit:GetOwner(), VISIT_TAVERN_DURATION, VISIT_TAVERN_DEBOUNCE);
	if(timerStatus.Status ~= g_PropertyTimerStatusTypes.Status_Ready) then
		return false;
	end

	return true;
end

-- Calculate the ShorePartyStatus for a given unit.
-- Returns a table consisting of...
--	Result		- A m_GetShorePartyResults value indicating the result.
function GetShorePartyStatusForUnit(pHomeUnit :object)
	local results = {};
	setmetatable(results, {__index = m_kDefaultShorePartyResult});

	-- Check movement
	if(pHomeUnit:GetMovesRemaining() < SHORE_PARTY_MOVE_COST) then
		results.Result = m_GetShorePartyResults.NO_MOVEMENT;
		return results;
	end

	local adjPlots = Map.GetAdjacentPlots(pHomeUnit:GetX(), pHomeUnit:GetY());
	for _, adjPlot in ipairs(adjPlots) do
		local adjPlotResults = GetShorePartyStatusForPlot(pHomeUnit:GetOwner(), adjPlot);
		if(adjPlotResults.Result == m_GetShorePartyResults.VALID) then
			results = adjPlotResults;
			break;
		end
	end

	return results;
end

--  Get the shore party status for a given target plot.
-- Returns a table consisting of...
--	Result		- A m_GetShorePartyResults value indicating the result.
function GetShorePartyStatusForPlot(iCapturePlayerID :number, pTargetPlot :object)
	-- Using metatable trick to allow fallback to default values.
	local results = {};
	setmetatable(results, {__index = m_kDefaultShorePartyResult});

	if(pTargetPlot:IsWater()) then
		return results;
	end

	if(pTargetPlot:IsImpassable()) then
		return results;
	end

	if(pTargetPlot:GetDistrictType() ~= NO_DISTRICT) then
		return results; 
	end

	local plotUnits :table = Map.GetUnitsAt(pTargetPlot);
	if(plotUnits ~= nil and plotUnits:GetCount() > 0) then
		return results;
	end

	-- If we made it here, this is a valid shore party plot.
	results.Result = m_GetShorePartyResults.VALID;
	return results;
end


-- ===========================================================================
--	Shore Party Embark Functions
-- ===========================================================================
-- Calculate the ShorePartyEmbarkStatus for a given unit.
function GetShorePartyEmbarkStatusForUnit(pHomeUnit :object)
	local results = {};
	setmetatable(results, {__index = m_kDefaultShorePartyEmbarkResult});

	if(pHomeUnit:GetMovesRemaining() < SHORE_PARTY_EMBARK_MOVE_COST) then
		results.Result = m_GetShorePartyEmbarkResults.NO_MOVEMENT;
		return results;		
	end

	local adjPlots = Map.GetAdjacentPlots(pHomeUnit:GetX(), pHomeUnit:GetY());
	for _, adjPlot in pairs(adjPlots) do
		local adjPlotResults = GetShorePartyEmbarkStatusForPlot(pHomeUnit:GetOwner(), adjPlot);
		if(adjPlotResults.Result == m_GetShorePartyEmbarkResults.VALID) then
			results = adjPlotResults;
			break;
		end
	end

	return results;
end

--  Get the shore party embark status for a given target plot.
function GetShorePartyEmbarkStatusForPlot(iShorePlayerID :number, pTargetPlot :object)
	-- Using metatable trick to allow fallback to default values.
	local results = {};
	setmetatable(results, {__index = m_kDefaultShorePartyEmbarkResult});

	if(not pTargetPlot:IsWater()) then
		return results;
	end

	local targetUnits :table = Map.GetUnitsAt(pTargetPlot);
	if targetUnits ~= nil then
		for pTargetUnit :object in targetUnits:Units() do
			if(pTargetUnit:GetOwner() == iShorePlayerID) then
				results.Result = m_GetShorePartyEmbarkResults.VALID;
				results.EmbarkShip = pTargetUnit;
				break;
			end
		end
	end

	return results;
end


-- ===========================================================================
--	Careening Functions
-- ===========================================================================
-- Calculate the CareeningStatus for a given unit.
function GetCareeningStatus(pUnit :object)
	-- Using metatable trick to allow fallback to default values.
	local results = {};
	setmetatable(results, {__index = g_kDefaultGetCareeningResults});

	if(pUnit == nil) then
		print("pUnit missing");
		results.Result = g_GetCareeningResults.INVALID_UNIT;
		return results;
	end

	if(pUnit:GetDamage() <= 0) then
		results.Result = g_GetCareeningResults.NO_DAMAGE;
		return results;
	end

	if(pUnit:GetMovesRemaining() < 1) then
		results.Result = g_GetCareeningResults.NO_MOVEMENT;
		return results;		
	end

	local pOwner : object = Players[pUnit:GetOwner()];
	if(pOwner == nil) then
		print("pOwner missing!");
		results.Result = g_GetCareeningResults.INVALID_UNIT;
		return results;
	end

	local pOwnerDiplo :object = pOwner:GetDiplomacy();
	if(pOwnerDiplo == nil) then
		print("pOwnerDiplo missing!");
		results.Result = g_GetCareeningResults.INVALID_UNIT;
		return results;
	end

	local pUnitPlot :object = Map.GetPlot(pUnit:GetX(), pUnit:GetY());
	if(pUnitPlot ~= nil 
		and pUnitPlot:IsOwned() == true
		and pOwnerDiplo:IsAtWarWith(pUnitPlot:GetOwner())) then
		results.Result = g_GetCareeningResults.ENEMY_TERRITORY;
		return results;
	end

	if(pUnitPlot ~= nil and not pUnitPlot:IsShallowWater()) then
		results.Result = g_GetCareeningResults.DEEP_WATER;
		return results;
	end

	-- We can careen if we got here.
	return results; 
end


-- ===========================================================================
--	Pirate Relic Functions
-- ===========================================================================
function RelicDropRoll(iPlayerID :number, dropChance :number, dropReason :string)
	local rollReason :string = "Relic Drop Roll: " .. dropReason;
	local relicRand :number = RandRange(0, 100, rollReason);
	if(relicRand <= dropChance) then
		print("Relic Drop Success: Player=" .. tostring(iPlayerID) .. ", dropReason=" .. tostring(dropReason) .. ", relicRoll=" .. tostring(relicRand) .. ", dropChance=" .. tostring(dropChance));
		GrantRelic(iPlayerID);
	else
		print("Relic Drop Failed: Player=" .. tostring(iPlayerID) .. ", dropReason=" .. tostring(dropReason) .. ", relicRoll=" .. tostring(relicRand) .. ", dropChance=" .. tostring(dropChance));
	end
end

function GrantRelic(iPlayerID :number)
	local pPlayer :object = Players[iPlayerID];
	if(pPlayer == nil) then
		print("error, pPlayer missing!");
		return;
	end

	local pPlayerCulture :object = pPlayer:GetCulture();	
	if(pPlayerCulture == nil) then
		print("error, pPlayerCulture missing!");
		return;
	end
	
	local lockedRelics = {};
	for kCivic in GameInfo.Civics() do
		if(kCivic.EraType == "ERA_INFORMATION" and not pPlayerCulture:HasCivic(kCivic.Index)) then
			table.insert(lockedRelics, kCivic);
		end
	end

	if(#lockedRelics < 1) then
		print("Unable to grant pirate relic, player " .. tostring(iPlayerID) .. " has them all.");
		return;
	end

	local relicRand :number = RandRange(1, #lockedRelics, "Picking Pirate Relic");
	pPlayerCulture:SetCivic(lockedRelics[relicRand].Index, true);
	pPlayerCulture:SetCivicCompletedThisTurn(true); -- allow free relic selection this turn.
	NotificationManager.SendNotification(iPlayerID, NotificationTypes.FILL_CIVIC_SLOT); -- this adds the fill civic slot end turn blocker which isn't triggered by script civic unlocks.

	local notificationData :table = {};
	notificationData[ParameterTypes.MESSAGE] = Locale.Lookup("LOC_NOTIFICATION_NEW_RELIC_MESSAGE", lockedRelics[relicRand].Name);
	notificationData[ParameterTypes.SUMMARY] = Locale.Lookup("LOC_NOTIFICATION_NEW_RELIC_SUMMARY");
	notificationData[CustomNotificationParameters.CivicDiscovered_CivicIndex] = lockedRelics[relicRand].Index;
	NotificationManager.SendNotification(iPlayerID, NotificationTypes.CIVIC_DISCOVERED, notificationData);
end


-- ===========================================================================
--	Hoarder Functions
-- ===========================================================================
-- Returns a sequenced table of plot indexes of chain shot target plots for the input pUnit.
function GetChainShotTargetPlots(pUnit :object)
	if(pUnit == nil) then
		print("pUnit missing");
		return nil;
	end

	local targetPlotIDs ={};
	for dx = -HOARDER_ACTIVE_RANGE, HOARDER_ACTIVE_RANGE, 1 do
		for dy = -HOARDER_ACTIVE_RANGE, HOARDER_ACTIVE_RANGE, 1 do
			local pPlot = Map.GetPlotXYWithRangeCheck(pUnit:GetX(), pUnit:GetY(), dx, dy, HOARDER_ACTIVE_RANGE);
			if(pPlot ~= nil) then
				local chainShotStatus = GetChainShotStatusForPlot(pUnit, pPlot);
				if(chainShotStatus.Result == g_GetChainShotResults.VALID) then
					table.insert(targetPlotIDs, pPlot:GetIndex());
				end
			end
		end
	end
	return targetPlotIDs;
end

--  Get the chain shot status for a given target plot.
-- Returns a table consisting of...
--	Result		- A g_GetChainShotResults value indicating the result.
function GetChainShotStatusForPlot(pChainUnit :object, pTargetPlot :object)
	-- Using metatable trick to allow fallback to default values.
	local results = {};
	setmetatable(results, {__index = g_kDefaultChainShotResult});

	if(pChainUnit == nil) then
		results.Result = g_GetChainShotResults.INVALID_DATA;
		return results;
	end

	local pTargetUnit = GetTargetChainShotUnitForPlot(pChainUnit, pTargetPlot);
	if(pTargetUnit == nil) then
		results.Result = g_GetChainShotResults.NO_ENEMY;
		return results;
	end		
	
	-- If we made it here, there is a valid chain shot target in this hex.
	return results;
end

function GetTargetChainShotUnitForPlot(pChainUnit :object, pTargetPlot :object)
	if(pChainUnit == nil or pTargetPlot == nil) then
		print("input missing!")
		return nil;
	end

	local plotUnits :table = Map.GetUnitsAt(pTargetPlot);
	if(plotUnits == nil or plotUnits:GetCount() <= 0) then
		return nil;
	end

	local pOwner :object = Players[pChainUnit:GetOwner()];
	if(pOwner == nil) then
		print("pOwner missing!")
		return nil;
	end
	local pOwnerDiplo :object = pOwner:GetDiplomacy();
	if(pOwnerDiplo == nil) then
		print("pOwnerDiplo missing!")
		return nil;
	end
	local pPlayerVis :object = PlayersVisibility[pChainUnit:GetOwner()];
	if(pPlayerVis == nil) then
		print("pPlayerVis missing!")
		return nil;
	end

	-- Players can only target visible hexes.
	if(pPlayerVis:IsVisible(pTargetPlot:GetX(), pTargetPlot:GetY()) == false) then
		return nil;
	end

	for pPlotUnit in plotUnits:Units() do
		if(pPlotUnit ~= nil 
			and GameInfo.Units[pPlotUnit:GetType()].Domain == "DOMAIN_SEA"
			and pOwnerDiplo:IsAtWarWith(pPlotUnit:GetOwner())) then
			-- valid target!
			return pPlotUnit;
		end
	end

	return nil;
end

