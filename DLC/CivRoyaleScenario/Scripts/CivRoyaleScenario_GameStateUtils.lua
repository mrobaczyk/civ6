--[[ =======================================================================

	Civ Royale Scenario GameCore Game State Utilities

	Contains gamecore side scripting related to the game state that is used
	from multiple locations.
-- =========================================================================]]
include "CivRoyaleScenario_PropKeys"
include "PlotFiltering"


-- ===========================================================================
--	Constants
-- ===========================================================================
local NO_IMPROVEMENT :number = -1;
local m_eCrippledGDR	:number = GameInfo.Units["UNIT_CRIPPLED_GDR"].Index;

AbilityTimerStatusTypes =
{
	Status_Ready = "Status_Ready",
	Status_Active = "Status_Active",
	Status_Recharging = "Status_Recharging",
};
g_DefaultAbilityStatus = { Status = AbilityTimerStatusTypes.Status_Ready, TurnsRemaining = 0 };


-- ===========================================================================
--	Notification Helper Functions
-- ===========================================================================
-- iNotifyPlayer - (Optional) If set, sends notification only to this player.  If not set, notification is sent to all players.
function SendNotification_Plot(notificationData :table, pPlot :object, iNotifyPlayer :number)
	if (pPlot == nil) then
		return;
	end

	local msgString = Locale.Lookup(notificationData.Message);
	local sumString = Locale.Lookup(notificationData.Summary);

	if(iNotifyPlayer ~= nil) then
		NotificationManager.SendNotification(iNotifyPlayer, notificationData.Type, msgString, sumString, pPlot:GetX(), pPlot:GetY());
	else
		local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
		for k, iPlayerID in ipairs(pAllPlayerIDs) do
			NotificationManager.SendNotification(iPlayerID, notificationData.Type, msgString, sumString, pPlot:GetX(), pPlot:GetY());
		end
	end
	return true;
end

-- iNotifyPlayer - (Optional) If set, sends notification only to this player.  If not set, notification is sent to all players.
function SendNotification(notificationData :table, iNotifyPlayer :number)
	local msgString = Locale.Lookup(notificationData.Message);
	local sumString = Locale.Lookup(notificationData.Summary);

	if(iNotifyPlayer ~= nil) then
		NotificationManager.SendNotification(iNotifyPlayer, notificationData.Type, msgString, sumString);
	else
		local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
		for k, iPlayerID in ipairs(pAllPlayerIDs) do
			NotificationManager.SendNotification(iPlayerID, notificationData.Type, msgString, sumString);
		end
	end
	return true;
end


-- ===========================================================================
--	Misc Helper Scripting
-- ===========================================================================
-- Does the given player have a GDR unit?
function HaveGDR(iPlayerID :number)
	local pPlayer :object = Players[iPlayerID];
	if(pPlayer == nil) then
		return false;
	end

	local pPlayerUnits : object = pPlayer:GetUnits();
	for i, pUnit in pPlayerUnits:Members() do
		if(pUnit:GetType() == m_eCrippledGDR) then
			return true;
		end
	end

	return false;
end


-- ===========================================================================
--	Ability Timer Functions
-- ===========================================================================
-- Get the Ability Timer Status for abilities tied to a unit-based property.
function GetUnitAbilityTimerStatus(pUnit :object, lastUsedTimePropKey :string, abilityDuration :number, abilityDebounce :number)
	-- Using metatable trick to allow fallback to default values.
	local retValue = {};
	setmetatable(retValue, {__index = g_DefaultAbilityStatus});

	if(pUnit == nil) then
		return retValue;
	end

	local lastUsedTimeProp = pUnit:GetProperty(lastUsedTimePropKey);
	return GetAbilityTimerStatus(lastUsedTimeProp, abilityDuration, abilityDebounce);
end

-- Get the Ability Timer Status for abilities tied to a player-based property.
function GetPlayerAbilityTimerStatus(iPlayer :number, lastUsedTimePropKey :string, abilityDuration :number, abilityDebounce :number)
	local lastUsedTimeProp :number = nil;
	local pPlayer :object = Players[iPlayer];
	if(pPlayer ~= nil) then
		lastUsedTimeProp = pPlayer:GetProperty(lastUsedTimePropKey);
	end
	return GetAbilityTimerStatus(lastUsedTimeProp, abilityDuration, abilityDebounce);
end

-- Get the Ability Timer Status for a given property value.
-- lastUsedTurnProp [number] - The property value for the last time the ability was used. If nil, we assume the ability has never been used and is ready to use now.
function GetAbilityTimerStatus(lastUsedTurnProp, abilityDuration :number, abilityDebounce :number)
	-- Using metatable trick to allow fallback to default values.
	local retValue = {};
	setmetatable(retValue, {__index = g_DefaultAbilityStatus});

	if(lastUsedTurnProp == nil) then
		-- property is missing, assume this means the ability is ready to use.
		return retValue;
	end

	local currentTurn = Game.GetCurrentGameTurn();
	if(currentTurn < (lastUsedTurnProp + abilityDuration)) then
		-- Ability is still active.
		retValue.Status = AbilityTimerStatusTypes.Status_Active;
		retValue.TurnsRemaining = lastUsedTurnProp + abilityDuration - currentTurn;
	elseif(currentTurn < (lastUsedTurnProp + abilityDuration + abilityDebounce)) then
		-- Ability is recharging
		retValue.Status = AbilityTimerStatusTypes.Status_Recharging;
		retValue.TurnsRemaining = lastUsedTurnProp + abilityDuration + abilityDebounce - currentTurn;
	end
	return retValue;
end


-- ===========================================================================
--	Pirate Faction Scripting
-- ===========================================================================
function SelectNewPirateTreasureLocation(iPlayerID :number)
	--print("Selecting new Treasure Plot for player " .. tostring(iPlayerID));

	local pFalloutManager = Game.GetFalloutManager();
	local treasurePlots = {};

	local pPlayer :object = Players[iPlayerID];
	if(pPlayer == nil) then
		print("Error: player missing");
		return;
	end

	-- IMPORTANT:  The following filtering uses a non-sequential table and is only network safe because all filtering are deterministic and non-order dependant!

	-- Start with all the plots within PIRATE_TREASURE_MAX_DIST_UNITS of all the player's units.
	local unsortedPlots = {};	-- table of plot instances keyed by plotIndex.  
	local pPlayerUnits : object = pPlayer:GetUnits();
	for i, pUnit in pPlayerUnits:Members() do
		local scanRange :number = PIRATE_TREASURE_MAX_DIST_UNITS;
		for dx = -scanRange, scanRange - 1, 1 do
			for dy = -scanRange, scanRange - 1, 1 do
				local scanPlot :object = Map.GetPlotXYWithRangeCheck(pUnit:GetX(), pUnit:GetY(), dx, dy, scanRange);
				if(scanPlot ~= nil and unsortedPlots[scanPlot:GetIndex()] == nil) then
					unsortedPlots[scanPlot:GetIndex()] = scanPlot;
				end
			end
		end
	end
	local lastPlotsRemaining :number = #unsortedPlots;
	print("Initial Treasure Plots: " .. tostring(lastPlotsRemaining));

	-- Remove all plots that are too close to the player's units.
	local plotsRemoved :number = 0;
	for i, pUnit in pPlayerUnits:Members() do
		local scanRange :number = PIRATE_TREASURE_MIN_DIST_UNITS;
		for dx = -scanRange, scanRange - 1, 1 do
			for dy = -scanRange, scanRange - 1, 1 do
				local scanPlot :object = Map.GetPlotXYWithRangeCheck(pUnit:GetX(), pUnit:GetY(), dx, dy, scanRange);
				if(scanPlot ~= nil and unsortedPlots[scanPlot:GetIndex()] ~= nil) then
					unsortedPlots[scanPlot:GetIndex()] = nil;
				end
			end
		end
	end
	print("Removing Treasure Plots too close to player units. Plots removed: " .. tostring(lastPlotsRemaining-#unsortedPlots) .. ", Plots Remaining: " .. tostring(#unsortedPlots));
	lastPlotsRemaining = #unsortedPlots;

	-- Don't place treasure in fallout, unpassable terrain, improvements (city ruins, raider camps), or water.
	local scanPlots = {};
	for k, curPlot in pairs(unsortedPlots) do
		if (not pFalloutManager:HasFallout(curPlot:GetIndex())			-- Not in fallout
			and not curPlot:IsImpassable()								-- Passable plot
			and not curPlot:IsWater()									-- On land
			and curPlot:GetImprovementType() == NO_IMPROVEMENT) then	-- 
			scanPlots[curPlot:GetIndex()] = curPlot;
		end	
	end
	unsortedPlots = scanPlots;
	print("Treasure Plots Validity Scan. Plots removed: " .. tostring(lastPlotsRemaining-#unsortedPlots) .. ", Plots Remaining: " .. tostring(#unsortedPlots));
	lastPlotsRemaining = #unsortedPlots;

	-- Convert unsortedPlots into treasurePlots, which is deterministic and ipair safe 
	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
		if(unsortedPlots[iPlotIndex] ~= nil) then
			table.insert(treasurePlots, unsortedPlots[iPlotIndex]);
		end
	end

	if(#treasurePlots > 0) then
		local treasureRand :number = RandRange(1, #treasurePlots, "Treasure Plot Roll");
		local treasurePlot = treasurePlots[treasureRand];
		print("New Treasure Plot Selected (" .. tostring(treasurePlot:GetX()) .. "," .. tostring(treasurePlot:GetY()) .. ") for player " .. tostring(iPlayerID));
		
		
		if(pPlayer ~= nil) then
			pPlayer:SetProperty(g_playerPropertyKeys.TreasurePlotIndex, treasurePlot:GetIndex());
		end

		-- Reveal the buried treasure hex.
		local pPlayerVisibility = PlayersVisibility[iPlayerID];
		if(pPlayerVisibility ~= nil) then
			pPlayerVisibility:ChangeVisibilityCount(treasurePlot:GetIndex(), 0);
		end

		SendNotification_Plot(g_NotificationsData.NewBuriedTreasure, treasurePlot, iPlayerID);
	end
end


-- ===========================================================================
--	Cultists Faction Scripting
-- ===========================================================================
function GetSacrificeTarget(pUnit :object)
	local pUnitPlot :object = Map.GetPlot(pUnit:GetX(), pUnit:GetY());
	if(pUnitPlot ~= nil) then
		local sacrificeTarget :object = GetSacrificeTargetForLocation(pUnit, pUnitPlot);
		if(sacrificeTarget ~= nil) then
			return sacrificeTarget;
		end
	end

	local pUnitAdjPlots :table = Map.GetAdjacentPlots(pUnit:GetX(), pUnit:GetY());
	for i, pAdjPlot in ipairs(pUnitAdjPlots) do
		local sacrificeTarget :object = GetSacrificeTargetForLocation(pUnit, pAdjPlot);
		if(sacrificeTarget ~= nil) then
			return sacrificeTarget;
		end
	end 

	return nil;
end

function GetSacrificeTargetForLocation(pSacrificingUnit:object, pPlot :object)
	local targetUnits :table = Map.GetUnitsAt(pPlot);
	if targetUnits ~= nil then
		for pTargetUnit :object in targetUnits:Units() do
			if(pTargetUnit:GetOwner() == pSacrificingUnit:GetOwner() and pTargetUnit:GetType() == m_eCrippledGDR) then
				return pTargetUnit;
			end
		end
	end
end

