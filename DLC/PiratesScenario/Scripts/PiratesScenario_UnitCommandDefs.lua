--[[ =======================================================================

	Pirates Scenario Custom Unit Commands - Definitions

		Data and callbacks for enabling custom unit commands to appear and 
		work in the Unit Panel UI. These definitions mimic what appears in 
		data for common unit commands, and are used in the replacement 
		UnitPanel script.

-- =========================================================================]]
include("PiratesScenario_Shared_Script");


-- ===========================================================================
--	Defines
-- ===========================================================================
local NO_PLAYER :number = -1;


-- ===========================================================================
--	Variables
-- ===========================================================================
m_ScenarioUnitCommands = {};


-- ===========================================================================
--	Helper Functions
-- ===========================================================================
function BaseVisibleCheck(pUnit :object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerPlayer :object = Players[pUnit:GetOwner()];
	if(pOwnerPlayer ~= nil and not pOwnerPlayer:IsTurnActive()) then
		return false;
	end

	return true;
end

-- ===========================================================================
--	Unit Actions
-- ===========================================================================
--[[ =======================================================================
	VISIT_TAVERN

	Useable by Pirate factions to get a new quest.
-- =========================================================================]]
m_ScenarioUnitCommands.VISIT_TAVERN = {};

-- Study Command State Properties
m_ScenarioUnitCommands.VISIT_TAVERN.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.VISIT_TAVERN.EventName				= "ScenarioCommand_VisitTavern";
m_ScenarioUnitCommands.VISIT_TAVERN.CommandSubType			= g_unitCommandSubTypeNames.VISIT_TAVERN;
m_ScenarioUnitCommands.VISIT_TAVERN.CategoryInUI			= "SPECIFIC";
m_ScenarioUnitCommands.VISIT_TAVERN.Icon					= "ICON_UNITOPERATION_VISIT_TAVERN";
m_ScenarioUnitCommands.VISIT_TAVERN.ToolTipString			= "LOC_VISIT_TAVERN_TOOLTIP";
m_ScenarioUnitCommands.VISIT_TAVERN.VisibleInUI			= true;

-- ===========================================================================
function m_ScenarioUnitCommands.VISIT_TAVERN.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	if(not IsPiratePlayer(pUnit:GetOwner())) then
		return false;
	end

	if (GameInfo.Units[pUnit:GetUnitType()].Domain ~= "DOMAIN_SEA") then
		return false;
	end

	--Don't add to unit panel action bar if not next to a city
	local adjCity = FindAdjacentCity(pUnit);
	if(adjCity == nil) then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.VISIT_TAVERN.IsVisible(pUnit : object)
	return BaseVisibleCheck(pUnit);
end

-- ===========================================================================
function m_ScenarioUnitCommands.VISIT_TAVERN.IsDisabled(pUnit : object)
	return not VisitTavern_CanStart(pUnit);
end

function m_ScenarioUnitCommands.VISIT_TAVERN.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local adjCity = FindAdjacentCity(pUnit);
	if(adjCity == nil) then
		return "LOC_VISIT_TAVERN_NOT_ADJACENT_TT";
	end

	local timerStatus = GetPropertyTimerStatus(adjCity, g_cityPlayerSpecificKeys.LastTavernTurn, pUnit:GetOwner(), VISIT_TAVERN_DURATION, VISIT_TAVERN_DEBOUNCE);
	if(timerStatus.Status == g_PropertyTimerStatusTypes.Status_Recharging) then
		return Locale.Lookup("LOC_UNITOPERATION_VISIT_TAVERN_RECHARGING_TT", timerStatus.TurnsRemaining);
	end

	return nil;
end

--[[ =======================================================================
	CAREENING

	Useable by naval boats to rapidly heal in exchange for spending their remaining moves.
-- =========================================================================]]
m_ScenarioUnitCommands.CAREENING = {};

-- Study Command State Properties
m_ScenarioUnitCommands.CAREENING.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.CAREENING.EventName				= "ScenarioCommand_Careening";
m_ScenarioUnitCommands.CAREENING.CommandSubType			= g_unitCommandSubTypeNames.CAREENING;
m_ScenarioUnitCommands.CAREENING.CategoryInUI			= "SPECIFIC";
m_ScenarioUnitCommands.CAREENING.Icon					= "ICON_UNITOPERATION_CAREENING";
m_ScenarioUnitCommands.CAREENING.ToolTipString			= "LOC_CAREENING_TOOLTIP";
m_ScenarioUnitCommands.CAREENING.VisibleInUI			= true;

-- ===========================================================================
function m_ScenarioUnitCommands.CAREENING.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	--Don't add to unit panel action bar if unit is at full health
	if(pUnit:GetDamage() <= 0)then
		return false;
	end

	if (GameInfo.Units[pUnit:GetUnitType()].Domain ~= "DOMAIN_SEA") then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.CAREENING.IsVisible(pUnit : object)
	return BaseVisibleCheck(pUnit);
end

-- ===========================================================================
function m_ScenarioUnitCommands.CAREENING.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	local careeningStatus = GetCareeningStatus(pUnit);
	if(careeningStatus.Result ~= g_GetCareeningResults.VALID) then
		return true;
	end

	return false;
end

function m_ScenarioUnitCommands.CAREENING.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local careeningStatus = GetCareeningStatus(pUnit);
	if(careeningStatus.Result == g_GetCareeningResults.NO_DAMAGE) then
		return "LOC_CAREENING_NO_DAMAGE_TOOLTIP";
	elseif(careeningStatus.Result == g_GetCareeningResults.NO_MOVEMENT) then
		return "LOC_CAREENING_NO_MOVEMENT_TOOLTIP";
	elseif(careeningStatus.Result == g_GetCareeningResults.ENEMY_TERRITORY) then
		return "LOC_CAREENING_ENEMY_TERRITORY_TOOLTIP";
	elseif(careeningStatus.Result == g_GetCareeningResults.DEEP_WATER) then
		return "LOC_CAREENING_DEEP_WATER_TOOLTIP";
	end

	return nil;
end

--[[ =======================================================================
	CAPTURE_BOAT

	Capture a damaged enemy boat.
-- =========================================================================]]
m_ScenarioUnitCommands.CAPTURE_BOAT = {};

-- Study Command State Properties
m_ScenarioUnitCommands.CAPTURE_BOAT.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.CAPTURE_BOAT.EventName			= nil;
m_ScenarioUnitCommands.CAPTURE_BOAT.CategoryInUI		= "SPECIFIC";
m_ScenarioUnitCommands.CAPTURE_BOAT.Icon				= "ICON_UNITOPERATION_CAPTURE_BOAT";
m_ScenarioUnitCommands.CAPTURE_BOAT.ToolTipString		= "LOC_CAPTURE_BOAT_TOOLTIP";
m_ScenarioUnitCommands.CAPTURE_BOAT.VisibleInUI			= true;
m_ScenarioUnitCommands.CAPTURE_BOAT.InterfaceMode		= INTERFACEMODE_CAPTURE_BOAT;

-- ===========================================================================
function m_ScenarioUnitCommands.CAPTURE_BOAT.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if (GameInfo.Units[pUnit:GetUnitType()].Domain ~= "DOMAIN_SEA") then
		return false;
	end

	--Don't add to unit panel action bar if there are no boats to capture
	local captureResult = GetCaptureBoatStatus(pUnit);
	if(captureResult.Result == m_GetCaptureBoatResults.NO_SHIPS) then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.CAPTURE_BOAT.IsVisible(pUnit : object)
	return BaseVisibleCheck(pUnit);
end

-- ===========================================================================
function m_ScenarioUnitCommands.CAPTURE_BOAT.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	-- Not Enough Crew?
	local curCrewProp = pUnit:GetProperty(g_unitPropertyKeys.Crew);
	if(curCrewProp == nil or curCrewProp < CAPTURE_BOAT_CREW_COST) then
		return true;
	end

	-- No capturable boats available?
	local captureResult = GetCaptureBoatStatus(pUnit);
	if(captureResult.Result ~= m_GetCaptureBoatResults.CAPTURABLE) then
		return true;
	end

	return false;
end

function m_ScenarioUnitCommands.CAPTURE_BOAT.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	-- Not Enough Crew?
	local curCrewProp = pUnit:GetProperty(g_unitPropertyKeys.Crew);
	if(curCrewProp == nil or curCrewProp < CAPTURE_BOAT_CREW_COST) then
		return Locale.Lookup("LOC_UNITOPERATION_CAPTURE_BOAT_NO_CREW_TT");
	end

	-- No capturable boats available?
	local captureResult = GetCaptureBoatStatus(pUnit);
	if(captureResult.Result == m_GetCaptureBoatResults.NOT_DAMAGED) then
		return Locale.Lookup("LOC_UNITOPERATION_CAPTURE_BOAT_NO_DAMAGE_TT");
	elseif(captureResult.Result == m_GetCaptureBoatResults.MAX_HIT_POINTS) then
		return Locale.Lookup("LOC_UNITOPERATION_CAPTURE_BOAT_FLAGSHIP_TT");
	end

	return nil;
end


--[[ =======================================================================
	DREAD_PIRATE_ACTIVE

	Dread Pirate unique ability to sacrifice damaged enemy ships for bonuses.
-- =========================================================================]]
m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE = {};

-- State Properties
m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE.Properties = {};

-- UI Data
m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE.CategoryInUI		= "SPECIFIC";
m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE.Icon				= "ICON_UNITOPERATION_DREAD_PIRATE_ACTIVE";
m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE.ToolTipString	= "LOC_DREAD_PIRATE_UNIT_ACTIVE_TOOLTIP";
m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE.VisibleInUI		= true;
m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE.InterfaceMode	= INTERFACEMODE_DREAD_PIRATE_ACTIVE;

-- ===========================================================================
function m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() ~= g_CivTypeNames.DreadPirate) then
		return false;
	end

	if (GameInfo.Units[pUnit:GetUnitType()].Domain ~= "DOMAIN_SEA") then
		return false;
	end

	local captureResult = GetCaptureBoatStatus(pUnit);
	if(captureResult.Result == m_GetCaptureBoatResults.NO_SHIPS) then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE.IsVisible(pUnit : object)
	return BaseVisibleCheck(pUnit);
end

-- ===========================================================================
function m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	local timerStatus = GetPropertyTimerStatus(pUnit, g_unitPropertyKeys.LastDreadPirateActive, NO_PLAYER, DREAD_PIRATE_ACTIVE_DURATION, DREAD_PIRATE_ACTIVE_DEBOUNCE);
	if(timerStatus.Status ~= g_PropertyTimerStatusTypes.Status_Ready) then
		return true;
	end
		
	-- No capturable boats available?
	local captureResult = GetCaptureBoatStatus(pUnit);
	if(captureResult.Result ~= m_GetCaptureBoatResults.CAPTURABLE) then
		return true;
	end

	return false;
end

function m_ScenarioUnitCommands.DREAD_PIRATE_ACTIVE.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local timerStatus = GetPropertyTimerStatus(pUnit, g_unitPropertyKeys.LastDreadPirateActive, NO_PLAYER, DREAD_PIRATE_ACTIVE_DURATION, DREAD_PIRATE_ACTIVE_DEBOUNCE);
	if(timerStatus.Status == g_PropertyTimerStatusTypes.Status_Active) then
		return Locale.Lookup("LOC_DREAD_PIRATE_ACTIVE_ACTIVATED_TT", timerStatus.TurnsRemaining);
	elseif(timerStatus.Status == g_PropertyTimerStatusTypes.Status_Recharging) then
		return Locale.Lookup("LOC_DREAD_PIRATE_ACTIVE_RECHARGING_TT", timerStatus.TurnsRemaining);
	end

	-- No capturable boats available?
	local captureResult = GetCaptureBoatStatus(pUnit);
	if(captureResult.Result == m_GetCaptureBoatResults.NOT_DAMAGED) then
		return Locale.Lookup("LOC_UNITOPERATION_CAPTURE_BOAT_NO_DAMAGE_TT");
	elseif(captureResult.Result == m_GetCaptureBoatResults.MAX_HIT_POINTS) then
		return Locale.Lookup("LOC_UNITOPERATION_CAPTURE_BOAT_FLAGSHIP_TT");
	end

	return nil;
end


--[[ =======================================================================
	PRIVATEER_ACTIVE

	Privateer unique ability to capture ships for the Privateer's patron.
-- =========================================================================]]
m_ScenarioUnitCommands.PRIVATEER_ACTIVE = {};

-- State Properties
m_ScenarioUnitCommands.PRIVATEER_ACTIVE.Properties = {};

-- UI Data
m_ScenarioUnitCommands.PRIVATEER_ACTIVE.CategoryInUI	= "SPECIFIC";
m_ScenarioUnitCommands.PRIVATEER_ACTIVE.Icon			= "ICON_UNITOPERATION_PRIVATEER_ACTIVE";
m_ScenarioUnitCommands.PRIVATEER_ACTIVE.ToolTipString	= "LOC_PRIVATEER_UNIT_ACTIVE_TOOLTIP";
m_ScenarioUnitCommands.PRIVATEER_ACTIVE.VisibleInUI		= true;
m_ScenarioUnitCommands.PRIVATEER_ACTIVE.InterfaceMode	= INTERFACEMODE_PRIVATEER_ACTIVE;

-- ===========================================================================
function m_ScenarioUnitCommands.PRIVATEER_ACTIVE.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() ~= g_CivTypeNames.Privateer) then
		return false;
	end

	if (GameInfo.Units[pUnit:GetUnitType()].Domain ~= "DOMAIN_SEA") then
		return false;
	end

	local captureResult = GetCaptureBoatStatus(pUnit);
	if(captureResult.Result == m_GetCaptureBoatResults.NO_SHIPS) then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.PRIVATEER_ACTIVE.IsVisible(pUnit : object)
	return BaseVisibleCheck(pUnit);
end

-- ===========================================================================
function m_ScenarioUnitCommands.PRIVATEER_ACTIVE.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	local timerStatus = GetPropertyTimerStatus(pUnit, g_unitPropertyKeys.LastPrivateerActive, NO_PLAYER, PRIVATEER_ACTIVE_DURATION, PRIVATEER_ACTIVE_DEBOUNCE);
	if(timerStatus.Status ~= g_PropertyTimerStatusTypes.Status_Ready) then
		return true;
	end
		
	-- No capturable boats available?
	local captureResult = GetCaptureBoatStatus(pUnit);
	if(captureResult.Result ~= m_GetCaptureBoatResults.CAPTURABLE) then
		return true;
	end

	return false;
end

function m_ScenarioUnitCommands.PRIVATEER_ACTIVE.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local timerStatus = GetPropertyTimerStatus(pUnit, g_unitPropertyKeys.LastPrivateerActive, NO_PLAYER, PRIVATEER_ACTIVE_DURATION, PRIVATEER_ACTIVE_DEBOUNCE);
	if(timerStatus.Status == g_PropertyTimerStatusTypes.Status_Active) then
		return Locale.Lookup("LOC_PRIVATEER_ACTIVE_ACTIVATED_TT", timerStatus.TurnsRemaining);
	elseif(timerStatus.Status == g_PropertyTimerStatusTypes.Status_Recharging) then
		return Locale.Lookup("LOC_PRIVATEER_ACTIVE_RECHARGING_TT", timerStatus.TurnsRemaining);
	end

	-- No capturable boats available?
	local captureResult = GetCaptureBoatStatus(pUnit);
	if(captureResult.Result == m_GetCaptureBoatResults.NOT_DAMAGED) then
		return Locale.Lookup("LOC_UNITOPERATION_CAPTURE_BOAT_NO_DAMAGE_TT");
	elseif(captureResult.Result == m_GetCaptureBoatResults.MAX_HIT_POINTS) then
		return Locale.Lookup("LOC_UNITOPERATION_CAPTURE_BOAT_FLAGSHIP_TT");
	end

	return nil;
end


--[[ =======================================================================
	SHORE_PARTY

	Deploy a crew toke nas a shore party (pirate unit).
-- =========================================================================]]
m_ScenarioUnitCommands.SHORE_PARTY = {};

-- Study Command State Properties
m_ScenarioUnitCommands.SHORE_PARTY.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.SHORE_PARTY.EventName			= nil;
m_ScenarioUnitCommands.SHORE_PARTY.CategoryInUI			= "SPECIFIC";
m_ScenarioUnitCommands.SHORE_PARTY.Icon					= "ICON_UNITOPERATION_PIRATES_DISEMBARK";
m_ScenarioUnitCommands.SHORE_PARTY.ToolTipString		= "LOC_SHORE_PARTY_TOOLTIP";
m_ScenarioUnitCommands.SHORE_PARTY.VisibleInUI			= true;
m_ScenarioUnitCommands.SHORE_PARTY.InterfaceMode		= INTERFACEMODE_SHORE_PARTY;


-- ===========================================================================
function m_ScenarioUnitCommands.SHORE_PARTY.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if (GameInfo.Units[pUnit:GetUnitType()].Domain ~= "DOMAIN_SEA") then
		return false;
	end

	--Don't add to unit panel action bar if not on the shoreline
	local shorePartyResult = GetShorePartyStatusForUnit(pUnit);
	if(shorePartyResult.Result ~= m_GetShorePartyResults.VALID
		and shorePartyResult.Result ~= m_GetShorePartyResults.NO_MOVEMENT) then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.SHORE_PARTY.IsVisible(pUnit : object)
	return BaseVisibleCheck(pUnit);
end

-- ===========================================================================
function m_ScenarioUnitCommands.SHORE_PARTY.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	-- Not Enough Crew?
	local curCrewProp = pUnit:GetProperty(g_unitPropertyKeys.Crew);
	if(curCrewProp == nil or curCrewProp < SHORE_PARTY_CREW_COST) then
		return true;
	end

	local shorePartyResult = GetShorePartyStatusForUnit(pUnit);
	if(shorePartyResult.Result ~= m_GetShorePartyResults.VALID) then
		return true;
	end

	return false;
end

function m_ScenarioUnitCommands.SHORE_PARTY.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	-- Not Enough Crew?
	local curCrewProp = pUnit:GetProperty(g_unitPropertyKeys.Crew);
	if(curCrewProp == nil or curCrewProp < SHORE_PARTY_CREW_COST) then
		return Locale.Lookup("LOC_UNITOPERATION_SHORE_PARTY_NO_CREW_TT");
	end

	local shorePartyResult = GetShorePartyStatusForUnit(pUnit);
	if(shorePartyResult.Result == m_GetShorePartyResults.NO_LAND) then
		return "LOC_SHORE_PARTY_NO_LAND_TOOLTIP";
	elseif(shorePartyResult.Result == m_GetShorePartyResults.NO_MOVEMENT) then
		return "LOC_UNIT_ABILITY_NOT_ENOUGH_MOVEMENT";
	end

	return nil;
end


--[[ =======================================================================
	SHORE_PARTY_EMBARK

	Embark a shore party unit onto a ship.
-- =========================================================================]]
m_ScenarioUnitCommands.SHORE_PARTY_EMBARK = {};

-- Study Command State Properties
m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.EventName			= nil;
m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.CategoryInUI		= "SPECIFIC";
m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.Icon				= "ICON_UNITOPERATION_PIRATES_EMBARK";
m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.ToolTipString		= "LOC_SHORE_PARTY_EMBARK_TOOLTIP"; 
m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.VisibleInUI		= true;
m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.InterfaceMode		= INTERFACEMODE_SHORE_PARTY_EMBARK;


-- ===========================================================================
function m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if (GameInfo.Units[pUnit:GetUnitType()].Domain ~= "DOMAIN_LAND") then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.IsVisible(pUnit : object)
	return BaseVisibleCheck(pUnit);
end

-- ===========================================================================
function m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	local shorePartyResult = GetShorePartyEmbarkStatusForUnit(pUnit);
	if(shorePartyResult.Result ~= m_GetShorePartyEmbarkResults.VALID) then
		return true;
	end

	return false;
end

function m_ScenarioUnitCommands.SHORE_PARTY_EMBARK.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local shorePartyResult = GetShorePartyEmbarkStatusForUnit(pUnit);
	if(shorePartyResult.Result == m_GetShorePartyEmbarkResults.NO_SHIP) then
		return "LOC_SHORE_PARTY_EMBARK_NO_SHIP_TOOLTIP";
	elseif(shorePartyResult.Result == m_GetShorePartyEmbarkResults.NO_MOVEMENT) then
		return "LOC_UNIT_ABILITY_NOT_ENOUGH_MOVEMENT";
	end

	return nil;
end


--[[ =======================================================================
	BURY_TREASURE

	Usable to land units to bury treasure to incease the player's treasure score.
-- =========================================================================]]
m_ScenarioUnitCommands.BURY_TREASURE = {};

-- Study Command State Properties
m_ScenarioUnitCommands.BURY_TREASURE.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.BURY_TREASURE.EventName				= "ScenarioCommand_BuryTreasure";
m_ScenarioUnitCommands.BURY_TREASURE.CommandSubType			= g_unitCommandSubTypeNames.BURY_TREASURE;
m_ScenarioUnitCommands.BURY_TREASURE.CategoryInUI			= "SPECIFIC";
m_ScenarioUnitCommands.BURY_TREASURE.Icon					= "ICON_UNITOPERATION_DONATE_MUSEUM";
m_ScenarioUnitCommands.BURY_TREASURE.ToolTipString			= "LOC_BURY_TREASURE_TOOLTIP";
m_ScenarioUnitCommands.BURY_TREASURE.VisibleInUI			= true;

-- ===========================================================================
function m_ScenarioUnitCommands.BURY_TREASURE.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	if (GameInfo.Units[pUnit:GetUnitType()].Domain ~= "DOMAIN_LAND") then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.BURY_TREASURE.IsVisible(pUnit : object)
	return BaseVisibleCheck(pUnit);
end

-- ===========================================================================
function m_ScenarioUnitCommands.BURY_TREASURE.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	local pUnitPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY());
	if(pUnitPlot == nil or pUnitPlot:IsWater()) then
		return true;
	end

	if(pUnitPlot:GetImprovementType() ~= -1)then
		return true;
	end

	if(pUnitPlot:GetOwner() ~= NO_PLAYER)then
		return true;
	end

	if(pUnit:GetOwner() == NO_PLAYER) then
		return true;
	end

	local pPlayer = Players[pUnit:GetOwner()];
	if(pPlayer == nil) then
		return true;
	end

	local pPlayerTreasury: object = pPlayer:GetTreasury();
	if(pPlayerTreasury:GetGoldBalance() < BURY_TREASURE_GOLD_COST) then
		return true;
	end

	return false;
end

function m_ScenarioUnitCommands.BURY_TREASURE.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	if(pUnit:GetOwner() == NO_PLAYER) then
		return nil;
	end

	local pPlayer :object = Players[pUnit:GetOwner()];
	if(pPlayer == nil) then
		return nil;
	end

	local pUnitPlot :object = Map.GetPlot(pUnit:GetX(), pUnit:GetY());
	if(pUnitPlot == nil or pUnitPlot:IsWater()) then
		return Locale.Lookup("LOC_UNITOPERATION_BURY_TREASURE_NO_LAND_TT");
	end

	if(IsPlotAlreadyImproved(pUnitPlot))then
		return Locale.Lookup("LOC_UNITOPERATION_BURY_TREASURE_ALREADY_IMPROVED_TT");
	end

	if(pUnitPlot:GetOwner() ~= NO_PLAYER)then
		return Locale.Lookup("LOC_UNITOPERATION_BURY_TREASURE_OWNED_PLOT_TT");
	end

	local pPlayerTreasury :object = pPlayer:GetTreasury();
	if(pPlayerTreasury:GetGoldBalance() < BURY_TREASURE_GOLD_COST) then
		return Locale.Lookup("LOC_UNITOPERATION_BURY_TREASURE_NO_GOLD_TT");
	end

	return nil;
end


--[[ =======================================================================
	SWASHBUCKLER_ACTIVE

	Swashbuckler 2x movement unit action.
-- =========================================================================]]
m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE = {};

-- Study Command State Properties
m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.EventName		= "ScenarioCommand_SwashbucklerActive";
m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.CommandSubType	= g_unitCommandSubTypeNames.SWASHBUCKLER_ACTIVE;
m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.CategoryInUI		= "SPECIFIC";
m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.Icon				= "ICON_UNITOPERATION_SWASHBUCKLER_ACTIVE";
m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.ToolTipString	= "LOC_SWASHBUCKLER_UNIT_ACTIVE_TOOLTIP";
m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.VisibleInUI		= true;

-- ===========================================================================
function m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() ~= g_CivTypeNames.Swashbuckler) then
		return false;
	end

	-- Land Units can't use Tack into the Wind
	if(GameInfo.Units[pUnit:GetType()].Domain ~= "DOMAIN_SEA") then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.IsVisible(pUnit : object)
	return BaseVisibleCheck(pUnit);
end

-- ===========================================================================
function m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	local timerStatus = GetPropertyTimerStatus(pUnit, g_unitPropertyKeys.LastSwashbuckerActive, NO_PLAYER, SWASHBUCKLER_ACTIVE_DURATION, SWASHBUCKLER_ACTIVE_DEBOUNCE);
	if(timerStatus.Status ~= g_PropertyTimerStatusTypes.Status_Ready) then
		return true;
	end
		
	return false;
end

function m_ScenarioUnitCommands.SWASHBUCKLER_ACTIVE.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local timerStatus = GetPropertyTimerStatus(pUnit, g_unitPropertyKeys.LastSwashbuckerActive, NO_PLAYER, SWASHBUCKLER_ACTIVE_DURATION, SWASHBUCKLER_ACTIVE_DEBOUNCE);
	if(timerStatus.Status == g_PropertyTimerStatusTypes.Status_Active) then
		return Locale.Lookup("LOC_SWASHBUCKLER_ACTIVE_ACTIVATED_TT", timerStatus.TurnsRemaining);
	elseif(timerStatus.Status == g_PropertyTimerStatusTypes.Status_Recharging) then
		return Locale.Lookup("LOC_SWASHBUCKLER_ACTIVE_RECHARGING_TT", timerStatus.TurnsRemaining);
	end

	return nil;
end


--[[ =======================================================================
	HOARDER_ACTIVE

	Chain Shot that locks a unit in place for two turns.
-- =========================================================================]]
m_ScenarioUnitCommands.HOARDER_ACTIVE = {};

-- State Properties
m_ScenarioUnitCommands.HOARDER_ACTIVE.Properties = {};

-- UI Data
m_ScenarioUnitCommands.HOARDER_ACTIVE.CategoryInUI		= "SPECIFIC";
m_ScenarioUnitCommands.HOARDER_ACTIVE.Icon				= "ICON_UNITOPERATION_HOARDER_ACTIVE";
m_ScenarioUnitCommands.HOARDER_ACTIVE.ToolTipString		= "LOC_HOARDER_UNIT_ACTIVE_TOOLTIP";
m_ScenarioUnitCommands.HOARDER_ACTIVE.VisibleInUI		= true;
m_ScenarioUnitCommands.HOARDER_ACTIVE.InterfaceMode		= INTERFACEMODE_HOARDER_ACTIVE;

-- ===========================================================================
function m_ScenarioUnitCommands.HOARDER_ACTIVE.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() ~= g_CivTypeNames.Hoarder) then
		return false;
	end

	-- Land Units can't use chain shot.
	if(GameInfo.Units[pUnit:GetType()].Domain ~= "DOMAIN_SEA") then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.HOARDER_ACTIVE.IsVisible(pUnit : object)
	return BaseVisibleCheck(pUnit);
end

-- ===========================================================================
function m_ScenarioUnitCommands.HOARDER_ACTIVE.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	local timerStatus = GetPropertyTimerStatus(pUnit, g_unitPropertyKeys.LastHoarderActive, nil, HOARDER_ACTIVE_DURATION, HOARDER_ACTIVE_DEBOUNCE);
	if(timerStatus.Status ~= g_PropertyTimerStatusTypes.Status_Ready) then
		return true;
	end

	local targetPlots :table = GetChainShotTargetPlots(pUnit);
	if(targetPlots == nil or #targetPlots <= 0) then
		return true;
	end

	return false;
end

function m_ScenarioUnitCommands.HOARDER_ACTIVE.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local timerStatus = GetPropertyTimerStatus(pUnit, g_unitPropertyKeys.LastHoarderActive, nil, HOARDER_ACTIVE_DURATION, HOARDER_ACTIVE_DEBOUNCE);
	if(timerStatus.Status ~= g_PropertyTimerStatusTypes.Status_Ready) then
		return Locale.Lookup("LOC_HOARDER_ACTIVE_RECHARGING_TT", timerStatus.TurnsRemaining);
	end

	return nil;
end


