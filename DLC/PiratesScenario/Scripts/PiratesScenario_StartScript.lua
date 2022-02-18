----------------------------------------------------------------  
-- Includes
----------------------------------------------------------------  
include "SupportFunctions" -- RandRange
include "PiratesScenario_UnitCommands"	-- Game Side handler for custom unit commands.
include "PiratesScenario_GameCore_Script"


----------------------------------------------------------------  
-- Defines
----------------------------------------------------------------  
local INVALID_COORD = -9999;
local INVALID_PLOT_DISTANCE = -1;
local INVALID_TURN :number = -1;
local NO_TEAM :number = -1;
local NO_PLAYER :number = -1;
local NO_PLOT :number = -1;
local NO_UNIT :number = -1;
local NO_DISTRICT :number = -1;
local NO_IMPROVEMENT :number = -1;
local NO_BUILDING :number = -1;

local NUM_CITIES :number = 6; 	-- How many cities should each player start with?


----------------------------------------------------------------  
-- Statics
----------------------------------------------------------------  
local ms_TundraTerrainClass :number 	= GameInfo.TerrainClasses["TERRAIN_CLASS_TUNDRA"].Index;
local ms_sloopUnitType :number			= GameInfo.Units["UNIT_SLOOP"].Index;
local ms_brigantineUnitType :number 	= GameInfo.Units["UNIT_BRIGANTINE"].Index;
local ms_galleonUnitType :number		= GameInfo.Units["UNIT_GALLEON"].Index;
local ms_piratesUnitType :number		= GameInfo.Units["UNIT_PIRATES"].Index;

local ms_BuriedTreasureImprov :number	= GameInfo.Improvements[BURY_TREASURE_IMPROVEMENT].Index;
local ms_FloatingTreasureImprov :number	= GameInfo.Improvements["IMPROVEMENT_FLOATING_TREASURE"].Index;
local ms_BarbCampImprov :number			= GameInfo.Improvements["IMPROVEMENT_BARBARIAN_CAMP"].Index;
local ms_BlackbeardFusePolicy : number	= GameInfo.Policies["POLICY_RELIC_BLACKBEARD_FUSE"].Index;
local ms_JollyRogersPolicy :number		= GameInfo.Policies["POLICY_RELIC_JOLLY_ROGERS"].Index;
local ms_cityCenterDistrict :number		= GameInfo.Districts["DISTRICT_CITY_CENTER"].Index;


----------------------------------------------------------------  
-- Helper Functions
---------------------------------------------------------------- 
function GetNumColonyCivilizations()
	local numColonyCivs :number = 0;
	local aPlayers = PlayerManager.GetAliveMajors();
	for loop, pPlayer in ipairs(aPlayers) do
		if(IsColonyPlayer(pPlayer:GetID())) then
			numColonyCivs = numColonyCivs + 1;
		end
	end
	return numColonyCivs;
end

function IsNotTundraPlot(curPlot :object)
	if(curPlot ~= nil) then
		local terrainClass :number = curPlot:GetTerrainClassType();
		if(terrainClass == ms_TundraTerrainClass) then
			return false;
		end
	end
	return true;
end

function IsTreasureFleetUnit(pUnit :object)
	local goldShip :number = pUnit:GetProperty(g_unitPropertyKeys.TreasureFleetGoldShip);
	if(goldShip ~= nil and goldShip > 0) then
		return true;
	end

	local guardShip :number = pUnit:GetProperty(g_unitPropertyKeys.TreasureFleetGuardShip);
	if(guardShip ~= nil and guardShip > 0) then
		return true;
	end

	return false;
end

function CheckUnitAbilityDepleted(pUnit :object, turn :number, unitStateKey :string, abilityName :string, abilityDuration :number, worldDepletedText :string)
	local unitStateProp = pUnit:GetProperty(unitStateKey);
	if(unitStateProp == nil) then
		-- Set the unitStateProp to 0 so we still check for and remove the unit ability if it is active.
		-- This addresses a bug where a unit with an active unit ability could be merged into a corp/army and the corp/army would inherit the ability permanently. 
		unitStateProp = 0;
	end

	local pUnitAbility = pUnit:GetAbility();
	local iCurrentCount = pUnitAbility:GetAbilityCount(abilityName);
	if(pUnitAbility ~= nil 
		and iCurrentCount > 0 
		and turn >= (unitStateProp + abilityDuration)) then
		if(worldDepletedText ~= nil and worldDepletedText ~= "") then
			local messageData : table = {
				MessageType = 0;
				MessageText = worldDepletedText;
				PlotX = pUnit:GetX();
				PlotY = pUnit:GetY();
				Visibility = RevealedState.VISIBLE;
				TargetID = pUnit:GetOwner();
			}
			Game.AddWorldViewText(messageData);
		end

		pUnitAbility:ChangeAbilityCount(abilityName, -iCurrentCount);
	end
end

function CheckFactionUnitAbilityDepleted(turn :number, factionName :string, unitStateKey :string, abilityName :string, abilityDuration :number, worldDepletedText :string)
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		if (pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == factionName) then
			local pPlayer = Players[iPlayerID];
			if(pPlayer ~= nil) then
				local pPlayerUnits : object = pPlayer:GetUnits();
				for i, pUnit in pPlayerUnits:Members() do
					CheckUnitAbilityDepleted(pUnit, turn, unitStateKey, abilityName, abilityDuration, worldDepletedText);
				end
			end
		end
	end	
end


----------------------------------------------------------------  
-- Logic Functions
---------------------------------------------------------------- 
-- Check to see the buried treasure location is now visible to the player.  If it is, remove the search zone and notify the player so the specific plot can be revealed.
function CheckTreasureLocationFound(iPlayerID)
	local pPlayer :object = Players[iPlayerID];
	if(pPlayer == nil) then
		print("Player missing!");
		return;
	end

	local pCurPlayerVisibility :object = PlayersVisibility[iPlayerID];
	if(pCurPlayerVisibility == nil) then
		print("Error: player visibility missing");
		return;
	end

	local treasureMaps :table = pPlayer:GetProperty(g_playerPropertyKeys.TreasureMaps);
	local treasureLocated :table = {};
	if(treasureMaps ~= nil) then
		for loop, curTreasureMap in ipairs(treasureMaps) do
			if(pCurPlayerVisibility:IsVisible(curTreasureMap.TreasurePlotIndex)) then
				local treasurePlot :object = Map.GetPlotByIndex(curTreasureMap.TreasurePlotIndex);
				print("Treasure Plot Found (" .. tostring(treasurePlot:GetX()) .. ", " .. tostring(treasurePlot:GetY()) .. ") by Player " .. tostring(iPlayerID) );
				table.insert(treasureLocated, treasurePlot);

				-- Hightlight just the treasure location.
				curTreasureMap.SearchCenterIndex = curTreasureMap.TreasurePlotIndex;
				curTreasureMap.ZoneSize = 0;
			end
		end

		if(#treasureLocated > 0) then
			pPlayer:SetProperty(g_playerPropertyKeys.TreasureMaps, treasureMaps);

			-- Send notifications after updating the TreasureMaps data so it is correct when the notification events are dispatched.
			for loop, curTreasurePlot in ipairs(treasureLocated) do
				local notificationData = {};
				notificationData[NotificationParameterTypes.CanUserDismiss] = false;
				SendNotification_Plot(g_NotificationsData.BuriedTreasureLocated, curTreasurePlot, iPlayerID, notificationData);
			end
		end
	end
end

function CheckSwashbucklerExplorerPoints(iPlayerID :number, pUnit :object)
	local pPlayer :object = Players[iPlayerID];
	local pPlayerConfig :object = PlayerConfigurations[iPlayerID];
	local pCurPlayerVisibility = PlayersVisibility[iPlayerID];
	if(pPlayerConfig == nil 
		or pPlayerConfig:GetCivilizationTypeName() ~=  g_CivTypeNames.Swashbuckler
		or pUnit == nil) then
		return;
	end

	local lastExploredProp :number = pPlayer:GetProperty(g_playerPropertyKeys.LastExploredHexes);
	local lastExploredCount :number = lastExploredProp ~= nil and lastExploredProp or 0;
	local curExploredCount :number = pCurPlayerVisibility:GetNumRevealedHexes();
	if(lastExploredCount ~= curExploredCount) then
		pPlayer:SetProperty(g_playerPropertyKeys.LastExploredHexes, curExploredCount);

		local oldExplorePointable :number = math.floor(lastExploredCount / SWASHBUCKLER_HEX_EXPLORED_DELTA);
		local curExplorePointable :number = math.floor(curExploredCount / SWASHBUCKLER_HEX_EXPLORED_DELTA);
		local deltaExplorePointable :number = curExplorePointable - oldExplorePointable;
		if(deltaExplorePointable > 0) then
			local changeExplorePoints :number = deltaExplorePointable * SWASHBUCKLER_HEX_EXPLORED_POINTS;
			print("Awarding Exploration Infamous Pirate Points, iPlayerID=" .. tostring(iPlayerID) .. ", changeExplorePoints=" .. tostring(changeExplorePoints) .. ", curExploredCount=" .. tostring(curExploredCount) .. ", lastExploredCount=" .. tostring(lastExploredCount));
			ChangeScore(iPlayerID, g_scoreTypes.InfamousPirate, changeExplorePoints, pUnit:GetX(), pUnit:GetY());
		end
	end
end

function SpawnInfamousPirate( )
	local infamousPlayer :object = Players[INFAMOUS_PIRATES_PLAYERID];
	if(infamousPlayer == nil) then
		print("Infamous pirate player missing!");
		return;
	end

	local infamousPlayerUnits :object = infamousPlayer:GetUnits();

	-- IMPORTANT:  The following filtering uses a non-sequential table and is only network safe because all filtering are deterministic and non-order dependant!
	local unsortedPlots :table = {};
	local curPlotCount :number = 0;

	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
		local curPlot :object = Map.GetPlotByIndex(iPlotIndex);
		if(curPlot ~= nil and curPlot:IsWater()) then
			unsortedPlots[curPlot:GetIndex()] = curPlot;
			curPlotCount = curPlotCount + 1;
		end
	end

	print("Initial Infamous Pirate Spawn Plots: " .. tostring(curPlotCount));

	-- Remove all plots too close to pirate player units.
	local scanRange :number = INFAMOUS_PIRATES_MIN_PLAYER_UNIT_DISTANCE;
	local kPiratePlayers :object = GetAlivePiratePlayers();
	for _, pPlayer in ipairs(kPiratePlayers) do
		local pPlayerUnits :object = pPlayer:GetUnits();
		for i, pUnit in pPlayerUnits:Members() do
			for dx = -scanRange, scanRange - 1, 1 do
				for dy = -scanRange, scanRange - 1, 1 do
					local curPlot :object = Map.GetPlotXYWithRangeCheck(pUnit:GetX(), pUnit:GetY(), dx, dy, scanRange);
					if (curPlot ~= nil and unsortedPlots[curPlot:GetIndex()] ~= nil) then
						curPlotCount = curPlotCount - 1;
						unsortedPlots[curPlot:GetIndex()] = nil;
					end
				end
			end
		end
	end

	print("Removed Infamous Pirate Spawn Plots too close to pirate player units. Plots Remaining: " .. tostring(curPlotCount));

	-- Convert unsortedPlots into pirateSpawnPlots, which is deterministic and ipair safe 
	local pirateSpawnPlots :table = {};
	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
		if(unsortedPlots[iPlotIndex] ~= nil) then
			table.insert(pirateSpawnPlots, unsortedPlots[iPlotIndex]);
		end
	end

	local pirateRand :number = RandRange(1, #g_InfamousPirates, "Picking Infamous Pirate Pick");
	local curPirate = g_InfamousPirates[pirateRand];
	local spawnPlotIndex: number = RandRange(1, #pirateSpawnPlots, "Selecting spawn plot for infamous pirate");
	local spawnPlot :object = pirateSpawnPlots[spawnPlotIndex];

	print("Creating infamous pirate=" .. tostring(curPirate.Name) .. ", unitType=" .. tostring(curPirate.UnitType) .. " , spawnLoc=" .. tostring(spawnPlot:GetX()) .. "," .. tostring(spawnPlot:GetY()));
	local pPirateUnitInfo : object = GameInfo.Units[curPirate.UnitType];
	if(pPirateUnitInfo == nil) then
		print("Error: missing pPirateUnitInfo");
		return;
	end

	local pPirateUnit = infamousPlayerUnits:Create(pPirateUnitInfo.Index, spawnPlot:GetX(), spawnPlot:GetY());
	if(pPirateUnit == nil) then
		print("Error: Pirate unit failed to spawn");
		return;
	end

	pPirateUnit:GetExperience():SetVeteranName(Locale.Lookup(curPirate.Name));
	pPirateUnit:SetProperty(g_unitPropertyKeys.KillInfamyPoints, curPirate.KillInfamyPoints);
	if(curPirate.MaxHitPoints ~= nil and curPirate.MaxHitPoints > 0) then
		pPirateUnit:SetProperty(g_unitPropertyKeys.MaxHitPoints, curPirate.MaxHitPoints);
	end

	-- Create Search Zone
	local searchZones :table = Game:GetProperty(g_gamePropertyKeys.InfamousPirateSearchZones);
	if(searchZones == nil) then
		searchZones = {};
	end

	local nextZoneID :number = Game:GetProperty(g_gamePropertyKeys.NextInfamousPirateZoneID);
	if(nextZoneID == nil) then
		nextZoneID = 0;
	end

	local newZone :table = {};
	newZone.PirateUnitID = pPirateUnit:GetID();
	local searchCenterPlots :table = Map.GetNeighborPlots(pPirateUnit:GetX(), pPirateUnit:GetY(), INFAMOUS_PIRATE_SEARCH_ZONE_SIZE);
	local searchCenterRand :number = RandRange(1, #searchCenterPlots, "New Infamous Pirate Search Zone Center Roll");
	local searchCenterPlot :object = searchCenterPlots[searchCenterRand];
	print("New Infamous Pirate Search Location Center (" .. tostring(searchCenterPlot:GetX()) .. "," .. tostring(searchCenterPlot:GetY()) .. "), InfamousPirateUnitID=" .. tostring(newZone.PirateUnitID));
	newZone.CenterPlotIndex = searchCenterPlot:GetIndex();
	newZone.ZoneID = nextZoneID;
	table.insert(searchZones, newZone);
	Game:SetProperty(g_gamePropertyKeys.InfamousPirateSearchZones, searchZones);

	nextZoneID = nextZoneID + 1;
	Game:SetProperty(g_gamePropertyKeys.NextInfamousPirateZoneID, nextZoneID);

	-- Create New Infamous Pirate Notification
	local msgString :string = Locale.Lookup(g_NotificationsData.NewInfamousPirate.Message);
	local summaryString :string = Locale.Lookup(g_NotificationsData.NewInfamousPirate.Summary);

	local notifyProperties = {};
	notifyProperties[g_notificationKeys.InfamousPirateID] = pPirateUnit:GetID();
	notifyProperties[g_notificationKeys.InfamousSearchZoneID] = newZone.ZoneID;
	notifyProperties[NotificationParameterTypes.CanUserDismiss] = false;
	SendNotification_PlotExtra(g_NotificationsData.NewInfamousPirate.Type, msgString, summaryString, nil, nil, notifyProperties);
end

function PlotHasNoPirateUnits(filterPlot :object)
	local pfilterUnitList :table = Map.GetUnitsAt(filterPlot);
	if pfilterUnitList ~= nil then
		for pfilterUnit :object in pfilterUnitList:Units() do
			if(IsPiratePlayer(pfilterUnit:GetOwner())) then
				return false;
			end
		end
	end
	return true;
end

function NewGamePirateFaction(iPlayerID :number)
	local pPlayer = Players[iPlayerID];
	local pDiplo :object = pPlayer:GetDiplomacy();
	local pPlayerConfig :object = PlayerConfigurations[iPlayerID];
	local patronCiv :number = NO_PLAYER;

	-- Randomly select the patron colonial player for the Privateer.
	if(pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() ==  g_CivTypeNames.Privateer) then
		local kColonialPlayers :table = GetAliveColonialPlayers();
		local patronRand = RandRange(1, #kColonialPlayers, "Selecting patron civilization for Privateer");
		patronCiv = kColonialPlayers[patronRand]:GetID();

		print("Privateer Player=" .. tostring(iPlayerID) .. " is now a privateer for Colonial Player=" .. tostring(patronCiv));

		pPlayer:SetProperty(g_playerPropertyKeys.PrivateerPatron, patronCiv);

		RevealPatronPorts(iPlayerID, patronCiv);
		SendLetterOfMarqueNotification(iPlayerID, patronCiv);
	end

	-- Set War/Ally states
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();
	for k, iterPlayerID in ipairs(pAllPlayerIDs) do
		if (pPlayer:GetID() ~= iterPlayerID) then
			pDiplo:SetHasMet(iterPlayerID);
			if(iterPlayerID == patronCiv) then
				pDiplo:SetPermanentAlliance(iterPlayerID);
			else
				pDiplo:DeclareWarOn(iterPlayerID, WarTypes.FORMAL_WAR, true);
				
				-- Human diplo is disabled but AI controlled pirates can still make peace offers.  Disallow peace offers in either direction.
				pDiplo:NeverMakePeaceWith(iterPlayerID);

				local pOtherPlayer :object = Players[iterPlayerID];
				if(pOtherPlayer ~= nil) then
					local pOtherDiplo :object = pOtherPlayer:GetDiplomacy();
					if(pOtherDiplo ~= nil) then
						pOtherDiplo:NeverMakePeaceWith(iPlayerID);
					end 
				end
			end
		end
	end

	RemoveSettlers(iPlayerID);
	SelectNewQuest(iPlayerID);  -- Give this pirate a quest to starrrrrrrt.
	RevealStartingPort(iPlayerID);

	-- Reveal map corners so the minimap displays at the global scale.
	local pCurPlayerVisibility = PlayersVisibility[iPlayerID];
	if(pCurPlayerVisibility ~= nil) then
		pCurPlayerVisibility:ChangeVisibilityCount(0, 0);	
		pCurPlayerVisibility:ChangeVisibilityCount(Map.GetPlotCount() -1, 0);
	end

	-- All the pirate factions have a custom government so they can use the policies system for their pirate relics.
	local pPlayerCulture:table = pPlayer:GetCulture();
	pPlayerCulture:SetCurrentGovernment(GameInfo.Governments["GOVERNMENT_PIRATE_KING"].Index);
end

function SendLetterOfMarqueNotification(iPiratePlayerID :number, iPatronPlayerID :number)
	local pPatronConfig :object = PlayerConfigurations[iPatronPlayerID];
	local patronAdjective :string = Locale.Lookup(GameInfo.Civilizations[pPatronConfig:GetCivilizationTypeID()].Adjective);

	local notificationData = {};
	notificationData[ParameterTypes.MESSAGE] = Locale.Lookup(g_NotificationsData.LetterofMarque.Message, patronAdjective);
	notificationData[ParameterTypes.SUMMARY] = Locale.Lookup(g_NotificationsData.LetterofMarque.Summary, pPatronConfig:GetCivilizationShortDescription());
	NotificationManager.SendNotification(iPiratePlayerID, g_NotificationsData.LetterofMarque.Type, notificationData);
end

function RevealPatronPorts(iPiratePlayerID :number, iPatronPlayerID :number)
	local pPlayerVis = PlayersVisibility[iPiratePlayerID];
	local pPatronPlayer :object = Players[iPatronPlayerID];

	for _,pCity in pPatronPlayer:GetCities():Members() do
		local cityX :number = pCity:GetX();
		local cityY :number = pCity:GetY();
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

function NewGameColonyFaction(iPlayerID :number)
	-- Colonial factions have met everyone.
	local pPlayer = Players[iPlayerID];
	local pDiplo :object = pPlayer:GetDiplomacy();
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();
	for k, iterPlayerID in ipairs(pAllPlayerIDs) do
		if (iterPlayerID ~= iPlayerID) then
			pDiplo:SetHasMet(iterPlayerID);
		end
	end

	RemoveSettlers(iPlayerID);
end

function RemoveSettlers(iPlayerID :number)
	local pSettlerUnitInfo = GameInfo.Units["UNIT_SETTLER"];
	local pPlayer = Players[iPlayerID];
	local pPlayerUnits : object = pPlayer:GetUnits();
	for i, pUnit in pPlayerUnits:Members() do
		if(pUnit:GetTypeHash() == pSettlerUnitInfo.Hash) then
			pPlayerUnits:Destroy(pUnit);
		end
	end
end

function RevealStartingPort(iPlayerID :number)
	local pPlayerConfig = PlayerConfigurations[iPlayerID];
	local startingPosition = pPlayerConfig:GetStartingPosition();
	RevealNearestPort(iPlayerID, startingPosition.x, startingPosition.y);
end


----------------------------------------------------------------  
-- Event Handlers
----------------------------------------------------------------  
function InitializeNewGame()
	print("Pirates Scenario InitializeNewGame");

	-- Collect all the coastal plots for all continents.
	local colonyPlots = {};
	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
		local curPlot = Map.GetPlotByIndex(iPlotIndex);
		if(curPlot ~= nil and curPlot:IsCoastalLand()) then
			table.insert(colonyPlots, curPlot);
		end
	end

	-- Remove tundra plots
	colonyPlots = FilterPlots(colonyPlots, IsNotTundraPlot, true);

	-- Create colony cities for all the major civs in the game.
	local aPlayers = PlayerManager.GetAliveMajors();
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();
	local numColonyCivs = GetNumColonyCivilizations();
	local tradersPerCity = (GetNumColonyCivilizations()-1) * NUM_CITIES;
	for loop, pPlayer in ipairs(aPlayers) do
		if(IsColonyPlayer(pPlayer:GetID())) then

			-- Colony Civs see the entire map
			local pCurPlayerVisibility = PlayersVisibility[pPlayer:GetID()];
			if(pCurPlayerVisibility ~= nil) then
				pCurPlayerVisibility:RevealAllPlots();
			end

			local pPlayerCities:table = pPlayer:GetCities();
			if(pPlayerCities:GetCount() > 0) then
				print("Colonial player " .. tostring(pPlayer:GetID()) .. " already has cities, skipping city creation.");
			else
				print("Creating colony cities for player " .. tostring(pPlayer:GetID()));
				local pPlayerUnits : object = pPlayer:GetUnits();
				for cityNum = 1, NUM_CITIES, 1 do
					local pCity = nil;
					local colonyPlotIndex :number = 1;
					local attemptNum = 1;
					while (pCity == nil and attemptNum <= #colonyPlots) do 
						local colonyPlotIndex: number = RandRange(1, #colonyPlots, "Selecting plot for new colony.");
						local settlePlot :object = colonyPlots[colonyPlotIndex];
						if(settlePlot ~= nil and pPlayerCities:IsValidFoundLocation(settlePlot:GetX(), settlePlot:GetY()) == true) then
							pCity = pPlayerCities:Create(settlePlot:GetX(), settlePlot:GetY());
							if(pCity ~= nil) then				
								print("Creating colony city at (" .. tostring(settlePlot:GetX()) .. ", " .. tostring(settlePlot:GetY()) .. tostring(")."));
							end

							table.remove(colonyPlots, colonyPlotIndex);
						end
						attemptNum = attemptNum + 1;
					end
				end
			end
		end
	end

	SpawnPirateFlagships();

	for _, pPlayer in ipairs(aPlayers) do
		if(IsPiratePlayer(pPlayer:GetID())) then
			NewGamePirateFaction(pPlayer:GetID());
		elseif(IsColonyPlayer(pPlayer:GetID())) then
			NewGameColonyFaction(pPlayer:GetID());
		end
	end

	CalcTreasureFleetExitPlot();
	CalcNextTreasureFleet(Game.GetCurrentGameTurn());
end

-- Spawn the Pirate Player's Flagships randomly placed in the largest ocean on the map.
function SpawnPirateFlagships()
	local pFlagshipUnitInfo = GameInfo.Units["UNIT_BRIGANTINE"];
	local kPiratePlayers = GetAlivePiratePlayers();

	-- Start with all the plots in the largest ocean.
	local largestOcean :object = Areas.FindBiggestArea(true);
	local oceanAreaID :number = largestOcean:GetID()
	local spawnPlotsFirstPass = {};
	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
		local curPlot = Map.GetPlotByIndex(iPlotIndex);
		if(curPlot ~= nil 
			and not curPlot:IsOwned()
			and curPlot:GetAreaID() == oceanAreaID) then
			table.insert(spawnPlotsFirstPass, curPlot);
		end
	end

	local spawnPlots = {};
	spawnPlots = spawnPlotsFirstPass;
	for _, pPlayer in ipairs(kPiratePlayers) do
		if(#spawnPlots <= 0) then
			-- All the possible locations were filtered from spawnPlots, fallback to the first pass.
			print("Falling back to spawnPlotsFirstPass Pirate Player=" .. tostring(pPlayer:GetID()));
			spawnPlots = spawnPlotsFirstPass;
		end

		local spawnPlotIndex: number = RandRange(1, #spawnPlots, "Selecting spawn plot for Pirate Player Flagship");
		local spawnPlot :object = spawnPlots[spawnPlotIndex];
		if(spawnPlot == nil) then
			print("Spawn plot is missing for Pirate Player=" .. tostring(pPlayer:GetID()));
		else
			print("Spawning Pirate Player=" .. tostring(pPlayer:GetID()) .. " Flagship at (" .. tostring(spawnPlot:GetX()) .. "," .. tostring(spawnPlot:GetY()) .. ")");
			local pPlayerUnits :object = pPlayer:GetUnits();
			local pNewFlagShip = pPlayerUnits:Create(pFlagshipUnitInfo.Index, spawnPlot:GetX(), spawnPlot:GetY());
			if(pNewFlagShip == nil) then
				print("Flagship failed to spawn for Pirate Player=" .. tostring(pPlayer:GetID()));
			else
				pNewFlagShip:SetProperty(g_unitPropertyKeys.MaxHitPoints, FLAGSHIP_HITPOINTS);
				pNewFlagShip:SetProperty(g_unitPropertyKeys.Crew, FLAGSHIP_CREW);

				local pNewFlagAbility :object = pNewFlagShip:GetAbility();
				pNewFlagAbility:ChangeAbilityCount(FLAGSHIP_ABILITY_NAME, 1);
			end

			-- Remove the plot where we spawned a player so it is not selectable even if we have to fallback from the nearby hexes filtering.
			table.remove(spawnPlots, spawnPlotIndex);

			-- Filter out hexes near this flagship's spawn plot.
			local filterNearByPlots = GetFilterPlots_FarPlots(spawnPlot:GetX(), spawnPlot:GetY(), FLAGSHIP_SPAWN_MIN_DISTANCE);
			spawnPlots = FilterPlots(spawnPlots, filterNearByPlots, true);
		end
	end
end

-- Calculates and caches the exit plot for treasure fleets.
function CalcTreasureFleetExitPlot()
	local biggest_area :object = Areas.FindBiggestArea(true);
	local biggest_id : number = biggest_area:GetID();
	local boundaries :table = biggest_area:GetBoundaries();
	local exitPlot = nil;
		
	-- Find the NE corner plot of the area.
	local exitPlot :object = FindTreasureCorner(boundaries, biggest_id);
	if(exitPlot ~= nil) then
		print("Treasure Fleet Exit Plot Found. PlotID = " .. tostring(exitPlot:GetIndex()) .. ", (" .. tostring(exitPlot:GetX()) .. ", " .. tostring(exitPlot:GetY()) .. ")");
		Game:SetProperty(g_gamePropertyKeys.TreasureFleetPlotIndex, exitPlot:GetIndex() );
	else
		print("Error: Treasure Fleet Exit Plot Not Found!");	
	end
end

function FindTreasureCorner(boundaries :table, areaID :number)
	for x=boundaries.EastEdge, boundaries.WestEdge, -1 do
		for y=boundaries.NorthEdge, boundaries.SouthEdge, -1 do
			local curPlot :object = Map.GetPlot(x, y);
			if(curPlot ~= nil and curPlot:GetAreaID() == areaID) then
				return curPlot;
			end
		end
	end

	return nil;
end

function OnGameTurnStarted( turn:number )
	print ("Pirates Scenario TURN STARTING: " .. turn);
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		if(IsPiratePlayer(iPlayerID)) then
			CheckTreasureLocationFound(iPlayerID);
		end
	end

	UpdateInfamousPirates(turn);	
	UpdateEconomy(turn);
	UpdateWar(turn);
	UpdateMutiny(turn);
	UpdateTreasureFleet(turn);

	CheckFactionUnitAbilityDepleted(turn, g_CivTypeNames.DreadPirate, g_unitPropertyKeys.LastDreadPirateActive, "ABILITY_DREAD_PIRATE_UNIT_ACTIVE", DREAD_PIRATE_ACTIVE_DURATION, "LOC_DREAD_PIRATE_ACTIVE_DEACTIVATED_WORLDTEXT");
	CheckFactionUnitAbilityDepleted(turn, g_CivTypeNames.Swashbuckler, g_unitPropertyKeys.LastSwashbuckerActive, "ABILITY_SWASHBUCKLER_UNIT_ACTIVE", SWASHBUCKLER_ACTIVE_DURATION, "LOC_SWASHBUCKLER_ACTIVE_DEACTIVATED_WORLDTEXT");
end

function UpdateInfamousPirates(turn :number)
	local maxTurns :number = GameConfiguration.GetMaxTurns();
	if(maxTurns <= 0) then
		return;
	end

	if(#g_InfamousPirates <= 0) then
		return;
	end

	local maxInfamousTurns :number = maxTurns - 5;
	local spawnChance :number = #g_InfamousPirates / maxInfamousTurns * 100;
	local randNum :number = RandRange(0, 100, "Infamous Pirate Spawn Roll");
	local outcomeString :string = (randNum <= spawnChance and "Success" or "Failed");
	print("Infamous Pirate Spawn Roll=" .. outcomeString  .. ", randNum=" .. tostring(randNum) .. ", chance=" .. tostring(spawnChance));
	if(randNum <= spawnChance) then
		SpawnInfamousPirate();
	end
end

function UpdateInfamousPiratesSearchZones()
	-- Update Search Zones.
	local oldSearchZones :table = Game:GetProperty(g_gamePropertyKeys.InfamousPirateSearchZones);
	local newSearchZones :table = {};
	local zonesChanged :boolean = false;
	if(oldSearchZones ~= nil and #oldSearchZones > 0) then
		for index, currentZone in ipairs(oldSearchZones) do
			if(currentZone ~= nil and currentZone.CenterPlotIndex ~= nil and currentZone.PirateUnitID ~= nil) then
				local curPirateUnit :object = UnitManager.GetUnit(INFAMOUS_PIRATES_PLAYERID, currentZone.PirateUnitID);
				local curCenterPlot :object = Map.GetPlotByIndex(currentZone.CenterPlotIndex);
				if(curPirateUnit == nil 
					or not IsInfamousPirate(INFAMOUS_PIRATES_PLAYERID, currentZone.PirateUnitID)) then -- This can happen if the barbs recycled the unit id to another unit.
					-- unit is gone. remove the search zone.
					zonesChanged = true;
				elseif(curCenterPlot ~= nil) then
					local curPiratePlot :object = Map.GetPlot(curPirateUnit:GetX(), curPirateUnit:GetY());
					if(curPiratePlot ~= nil) then
						local distance :number = Map.GetPlotDistance(curCenterPlot:GetIndex(), curPiratePlot:GetIndex());
						if(distance > PIRATE_TREASURE_SEARCH_ZONE_SIZE) then
							-- Pirate has moved out of the search zone. recenter the zone.
							local searchCenterPlots :table = Map.GetNeighborPlots(curPirateUnit:GetX(), curPirateUnit:GetY(), INFAMOUS_PIRATE_SEARCH_ZONE_SIZE);
							local searchCenterRand :number = RandRange(1, #searchCenterPlots, "Updated Infamous Pirate Search Zone Center Roll");
							local searchCenterPlot :object = searchCenterPlots[searchCenterRand];
							print("Updated Infamous Pirate Search Location Center (" .. tostring(searchCenterPlot:GetX()) .. "," .. tostring(searchCenterPlot:GetY()) .. "), InfamousPirateUnitID=" .. tostring(currentZone.PirateUnitID));
							currentZone.CenterPlotIndex = searchCenterPlot:GetIndex();
							zonesChanged = true;
						end

						table.insert(newSearchZones, currentZone);
					end
				end
			end
		end

		if(zonesChanged == true) then
			Game:SetProperty(g_gamePropertyKeys.InfamousPirateSearchZones, newSearchZones);
		end
	end
end

function UpdateEconomy(turn :number)
	local aPlayers = PlayerManager.GetAliveMajors();
	for loop, pPlayer in ipairs(aPlayers) do
		if(IsColonyPlayer(pPlayer:GetID())) then
			UpdateColonyEcomony(pPlayer, turn);
		end
	end
end

function UpdateWar(turn :number)
	local aPlayers = PlayerManager.GetAliveMajors();
	for loop, pPlayer in ipairs(aPlayers) do
		if(IsColonyPlayer(pPlayer:GetID())) then
			UpdateColonyWar(pPlayer, turn);
		end
	end
end

function UpdateColonyWar(pPlayer :object, turn :number)
	local warTargets :table = GetPossibleWarTargets(pPlayer);
	if(#warTargets > 0) then
		local warChance :number = RandRange(0, 100, "Colonial War Roll");
		local outcomeString :string = (warChance <= COLONIES_WAR_CHANCE and "Success" or "Failed");
		print("Colony War Roll=" .. outcomeString  .. ", playerID=" .. tostring(pPlayer:GetID()) .. ", randNum=" .. tostring(warChance) .. ", chance=" .. tostring(COLONIES_WAR_CHANCE));
		if(warChance <= COLONIES_WAR_CHANCE) then
			local pDiplo :object = pPlayer:GetDiplomacy();
			local targetRand :number = RandRange(1, #warTargets, "Colonial War Target");
			pDiplo:DeclareWarOn(warTargets[targetRand], WarTypes.FORMAL_WAR, true);
			print("Colony War Declared. Attacker=" .. tostring(pPlayer:GetID()) .. ", Defender=" .. tostring(warTargets[targetRand]));
		end
	end

	local peaceTargets :table = GetPossiblePeaceTargets(pPlayer);
	if(#peaceTargets > 0) then
		local peaceChance :number = RandRange(0, 100, "Colonial Peace Roll");
		local outcomeString :string = (peaceChance <= COLONIES_PEACE_CHANCE and "Success" or "Failed");
		print("Colony Peace Roll=" .. outcomeString  .. ", playerID=" .. tostring(pPlayer:GetID()) .. ", randNum=" .. tostring(peaceChance) .. ", chance=" .. tostring(COLONIES_PEACE_CHANCE));
		if(peaceChance <= COLONIES_PEACE_CHANCE) then
			local pDiplo :object = pPlayer:GetDiplomacy();
			local targetRand :number = RandRange(1, #peaceTargets, "Colonial Peace Target");
			pDiplo:MakePeaceWith(peaceTargets[targetRand]);
			print("Colony Peace Declared. Initiator=" .. tostring(pPlayer:GetID()) .. ", Defender=" .. tostring(peaceTargets[targetRand]));
		end
	end
end

function GetPossibleWarTargets(pPlayer :object)
	local warTargets = {};
	local pDiplo :object = pPlayer:GetDiplomacy();
	local aPlayers = PlayerManager.GetAliveMajors();
	for loop, pLoopPlayer in ipairs(aPlayers) do
		if(pLoopPlayer:GetID() ~= pPlayer:GetID() 
			and IsColonyPlayer(pLoopPlayer:GetID())
			and pDiplo:CanDeclareWarOn(pLoopPlayer:GetID(), WarTypes.FORMAL_WAR, true)) then
			table.insert(warTargets, pLoopPlayer:GetID());
		end
	end
	return warTargets;
end

function GetPossiblePeaceTargets(pPlayer :object)
	local peaceTargets = {};
	local pDiplo :object = pPlayer:GetDiplomacy();
	local aPlayers = PlayerManager.GetAliveMajors();
	for loop, pLoopPlayer in ipairs(aPlayers) do
		if(pLoopPlayer:GetID() ~= pPlayer:GetID() 
			and IsColonyPlayer(pLoopPlayer:GetID())
			and pDiplo:IsAtWarWith(pLoopPlayer:GetID())
			and pDiplo:CanMakePeaceWith(pLoopPlayer:GetID())) then
			table.insert(peaceTargets, pLoopPlayer:GetID());
		end
	end
	return peaceTargets;
end

function UpdateColonyEcomony(pPlayer :object, turn :number)
	local pPlayerTrade :table = pPlayer:GetTrade();
	local routesActive	:number = pPlayerTrade:CountOutgoingRoutes();
	local routesCapacity:number = pPlayerTrade:GetOutgoingRouteCapacity();

	if(routesActive >= routesCapacity) then
		return;
	end

	local pPlayerCities:table = pPlayer:GetCities();
	for j, pCity in pPlayerCities:Members() do
		local nextTradeRouteTurn :number = pCity:GetProperty(g_cityPropertyKeys.NextTradeRouteTurn);
		if(nextTradeRouteTurn == nil or turn >= nextTradeRouteTurn) then
			if(CanStartTradeRoute(pCity)) then
				AddTradeRoute(pCity);

				local randDelta :number = RandRange(CITY_TRADE_ROUTE_MIN_TURNS, CITY_TRADE_ROUTE_MAX_TURNS, "Scenario Next Trade Route Delta");
				local nextTradeRouteTurn :number = turn + randDelta;
				pCity:SetProperty(g_cityPropertyKeys.NextTradeRouteTurn, nextTradeRouteTurn);
				print("Added Trade Route to Player=" .. tostring(pPlayer:GetID()) .. ", CityID=" .. pCity:GetID() .. ", NextTradeRouteTurn=" .. tostring(nextTradeRouteTurn));
			end
		end
	end
end  

function CanStartTradeRoute(pCity :object)
	local tradeManager:table = Game.GetTradeManager();
	local players:table = Game.GetPlayers();
	for i, destinationPlayer in ipairs(players) do
		if(pCity:GetOwner() ~= destinationPlayer:GetID()) then
			local cities:table = destinationPlayer:GetCities();
			for j, destinationCity in cities:Members() do
				if tradeManager:CanStartRoute(pCity:GetOwner(), pCity:GetID(), destinationCity:GetOwner(), destinationCity:GetID(), true) then
					return true;
				end
			end
		end
	end
	return false;
end

function AddTradeRoute(pCity :object)
	if(pCity:GetOwner() == NO_PLAYER) then
		return;
	end
	local pPlayer :object = Players[pCity:GetOwner()];
	local pPlayerUnits :object = pPlayer:GetUnits();

	local pTraderUnitInfo = GameInfo.Units["UNIT_TRADER"];
	if(pTraderUnitInfo ~= nil) then
		local pNewTradeUnit = pPlayerUnits:Create(pTraderUnitInfo.Index, pCity:GetX(), pCity:GetY());
	end
end

function UpdateMutiny(turn :number)
	local aPlayers = PlayerManager.GetAliveMajors();
	for loop, pPlayer in ipairs(aPlayers) do
		if(IsPiratePlayer(pPlayer:GetID())) then
			UpdatePirateMutiny(pPlayer, turn);
		end
	end
end

function UpdatePirateMutiny(pPlayer :object, turn :number)
	if(pPlayer:IsAlive() == false) then
		return;
	end

	local pPlayerTreasury = pPlayer:GetTreasury();
	if(pPlayerTreasury:GetGoldBalance() > 0) then
		pPlayer:SetProperty(g_playerPropertyKeys.LastHadGoldTurn, turn);
		return;
	end

	local lastHadGoldTurn :number = pPlayer:GetProperty(g_playerPropertyKeys.LastHadGoldTurn);
	if(lastHadGoldTurn == nil) then
		lastHadGoldTurn = turn;
	end

	if(turn < lastHadGoldTurn + PIRATE_BANKRUPTCY_MUTINY_DELAY) then 
		-- Still waiting for the mutiny delay
		return;
	end

	-- MUTINY!
	local pMutinyShip = GetMutinyShip(pPlayer);
	if(pMutinyShip == nil) then
		return;
	end
	local mutinyShipData :object = GameInfo.Units[pMutinyShip:GetType()];
	local mutinyDamage :number = pMutinyShip:GetDamage();
	local pPlayerUnits :object = pPlayer:GetUnits();
	local mutinyX :number = pMutinyShip:GetX();
	local mutinyY :number = pMutinyShip:GetY();
	pPlayerUnits:Destroy(pMutinyShip);

	local pBarbPlayer :object = Players[INFAMOUS_PIRATES_PLAYERID];
	local pBarbUnits :object = pBarbPlayer:GetUnits();
	local pBarbMutinyShip :object = pBarbUnits:Create(mutinyShipData.Index, mutinyX, mutinyY);
	if(pBarbMutinyShip ~= nil) then
		pBarbMutinyShip:ChangeDamage(mutinyDamage);
		UnitManager.FinishMoves(pBarbMutinyShip);
	end
end

function UpdateTreasureFleet(turn :number)
	local nextFleetTurn : number = Game:GetProperty(g_gamePropertyKeys.NextTreasureFleetTurn);
	if(nextFleetTurn == nil or turn >= nextFleetTurn) then
		StartTreasureFleet();
		CalcNextTreasureFleet(turn);
	end

	UpdateTreasureFleetPlotTags();
end

function StartTreasureFleet()
	local startCity :object = GetTreasureFleetStartCity();
	if(startCity == nil) then
		print("Error: No start city found for Treasure fleet!");
		return;
	end

	-- Treasure Fleet AI can't be started on the first game turn.
	if(Game.GetCurrentGameTurn() == GameConfiguration.GetStartTurn()) then
		return;
	end

	if(startCity:GetOwner() == NO_PLAYER) then
		print("Error: no owner in treasure fleet start city?");
		return;
	end

	print("Spawning treasure fleet location=(" .. tostring(startCity:GetX()) .. ", " .. tostring(startCity:GetY()) .. ")");
	local startPlayer :object = Players[startCity:GetOwner()];
	local startUnits :object = startPlayer:GetUnits();

	-- Start AI Operation.
	local pMilitaryAI :object = startPlayer:GetAi_Military();
	if(pMilitaryAI == nil) then
		print("ERROR: No military AI found.");
		return;
	end
	local rallyPlot :object = Map.GetPlot(startCity:GetX(), startCity:GetY());
	if(rallyPlot == nil) then
		print("ERROR: could not find rally plot.");
		return;
	end
	local treasurePlotIndex :number = Game:GetProperty(g_gamePropertyKeys.TreasureFleetPlotIndex);
	if(treasurePlotIndex == nil) then
		print("ERROR: treasure plot index not set.");
		return;
	end
	local treasurePlot :object = Map.GetPlotByIndex(treasurePlotIndex);
	if(treasurePlot == nil) then
		print("ERROR: treasure plot missing.");
		return;
	end

	local treasureFleetID :number = GetNextTreasureFleetID();

	local iOperationID = pMilitaryAI:StartScriptedOperationWithTargetAndRally("Treasure Fleet Op", NO_PLAYER, treasurePlot:GetIndex(), rallyPlot:GetIndex());

	-- Spawn treasure ships
	for treasureShipIndex = 1, TREASURE_FLEET_GOLD_BOATS, 1 do
		local newTreasureShip :object = startUnits:Create(ms_galleonUnitType, startCity:GetX(), startCity:GetY());
		if(newTreasureShip == nil) then
			print("ERROR: Treasure fleet gold ship failed to spawn");
		else
			newTreasureShip:GetExperience():SetVeteranName(Locale.Lookup("LOC_UNIT_TREASURE_FLEET_GOLD_SHIP_NAME"));
			newTreasureShip:SetProperty(g_unitPropertyKeys.TreasureFleetGoldShip, 1);
			newTreasureShip:SetProperty(g_unitPropertyKeys.TreasureFleetID, treasureFleetID);
			pMilitaryAI:AddUnitToScriptedOperation(iOperationID, newTreasureShip:GetID());
		end
	end

	for guardShipIndex = 1, TREASURE_FLEET_GUARD_BOATS, 1 do
		local newGuardShip :object = startUnits:Create(ms_brigantineUnitType, startCity:GetX(), startCity:GetY());
		if(newGuardShip == nil) then
			print("ERROR: Treasure fleet guard ship failed to spawn");
		else
			newGuardShip:GetExperience():SetVeteranName(Locale.Lookup("LOC_UNIT_TREASURE_FLEET_GUARD_SHIP_NAME"));
			newGuardShip:SetProperty(g_unitPropertyKeys.TreasureFleetGuardShip, 1);
			newGuardShip:SetProperty(g_unitPropertyKeys.TreasureFleetID, treasureFleetID);
			pMilitaryAI:AddUnitToScriptedOperation(iOperationID, newGuardShip:GetID());
		end
	end

	-- Cache the treasureFleetPath for this treasure fleet.
	local treasureFleetPaths :table = Game:GetProperty(g_gamePropertyKeys.TreasureFleetPaths);
	if(treasureFleetPaths == nil) then
		treasureFleetPaths = {};
	end
	treasureFleetPaths = AddTreasureFleetPathsForPlayer(startPlayer:GetID(), treasureFleetPaths);
	Game:SetProperty(g_gamePropertyKeys.TreasureFleetPaths, treasureFleetPaths);

	local cityPlot :object = Map.GetPlot(startCity:GetX(), startCity:GetY());
	SendNotification_Plot(g_NotificationsData.NewTreasureFleet, cityPlot);
end

function GetNextTreasureFleetID()
	local nextTreasureFleetID :number = Game:GetProperty(g_gamePropertyKeys.NextTreasureFleetID);
	if(nextTreasureFleetID == nil) then
		nextTreasureFleetID = 0;
	end

	Game:SetProperty(g_gamePropertyKeys.NextTreasureFleetID, nextTreasureFleetID + 1);

	return nextTreasureFleetID;
end

function GetTreasureFleetStartCity()
	local aPlayers = PlayerManager.GetAliveMajors();
	local validCities = {};
	for loop, pLoopPlayer in ipairs(aPlayers) do
		if(IsColonyPlayer(pLoopPlayer:GetID())) then
			local pLoopCities :object = pLoopPlayer:GetCities();
			for j, pLoopCity in pLoopCities:Members() do
				if(IsValidTreasureFleetCity(pLoopCity)) then
					table.insert(validCities, pLoopCity);					
				end
			end
		end
	end

	if(#validCities <= 0) then
		return nil;
	end

	local randIndex :number = RandRange(1, #validCities, "Picking Treasure Fleet Start City");
	local pStartCity :object = validCities[randIndex];
	return pStartCity;
end

function IsValidTreasureFleetCity(pCity :object)
	local exitPlotIndex :number = Game:GetProperty(g_gamePropertyKeys.TreasureFleetPlotIndex);
	if(exitPlotIndex == nil) then
		print("ERROR: No TreasureFleetPlotIndex");
		return false;
	end

	local exitPlot :object = Map.GetPlotByIndex(exitPlotIndex);
	if(exitPlot == nil) then
		print("ERROR: No exitPlot");
		return false;		
	end

	local exitAreaID :number = exitPlot:GetAreaID();

	-- Is the city connected to the treasure fleet exit plot's area?
	local adjPlots = Map.GetAdjacentPlots(pCity:GetX(), pCity:GetY());
	for _, pLoopPlot : object in ipairs(adjPlots) do	
		if(pLoopPlot:GetAreaID() == exitAreaID) then
			return true;
		end
	end	

	return false;
end

function CalcNextTreasureFleet(turn :number)
	local randNext :number = RandRange(TREASURE_FLEET_MIN_TURNS, TREASURE_FLEET_MAX_TURNS, "Next Treasure Fleet Start");
	local nextTurn :number = turn + randNext;
	Game:SetProperty(g_gamePropertyKeys.NextTreasureFleetTurn, nextTurn);
	print("Next Treasure Fleet Time=" .. tostring(randNext) .. ", Turn=" .. tostring(nextTurn));
end

function UpdateTreasureFleetPlotTags()
	local treasureFleetPaths :table = Game:GetProperty(g_gamePropertyKeys.TreasureFleetPaths);
	if(treasureFleetPaths == nil) then
		treasureFleetPaths = {};
	end

	-- Remove the tagging associated with the old paths.
	if(#treasureFleetPaths > 0) then
		for pathIndex, curPath in ipairs(treasureFleetPaths) do
			for plotIndex, curPathIndex in ipairs(curPath.PathData) do
				local curPathPlot :object = Map.GetPlotByIndex(curPathIndex);
				if(curPathPlot ~= nil) then
					curPathPlot:SetProperty(g_plotPropertyKeys.TreasureFleetPath, nil);
				end
			end
		end
	end

	-- Cache current paths and tag path plots.
	treasureFleetPaths = {};
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();
	for k, iterPlayerID in ipairs(pAllPlayerIDs) do
		if(IsColonyPlayer(iterPlayerID)) then
			treasureFleetPaths = AddTreasureFleetPathsForPlayer(iterPlayerID, treasureFleetPaths);
		end
	end

	Game:SetProperty(g_gamePropertyKeys.TreasureFleetPaths, treasureFleetPaths);
end

function AddTreasureFleetPathsForPlayer(iPlayerID :number, treasureFleetPaths :table)
	local newTreasurePaths = treasureFleetPaths;
	if(newTreasurePaths == nil) then
		newTreasurePaths = {};
	end
	
	local treasureFleetPlotIndex :number = Game:GetProperty(g_gamePropertyKeys.TreasureFleetPlotIndex);
	if(treasureFleetPlotIndex == nil) then
		return newTreasurePaths;
	end

	local pPlayer :object = Players[iPlayerID];
	local pPlayerUnits :object = pPlayer:GetUnits();
	for i, pUnit in pPlayerUnits:Members() do
		if(IsTreasureFleetGoldShip(pUnit)) then
			local cachePath :boolean = true;
			local treasureFleetID :number = pUnit:GetProperty(g_unitPropertyKeys.TreasureFleetID);

			-- Only show one path per fleet.
			for pathIndex, curPath in ipairs(newTreasurePaths) do
				if(curPath.TreasureFleetID == treasureFleetID) then
					cachePath = false;
					break;
				end
			end

			if(cachePath == true) then
				local newTreasurePath = {};
				newTreasurePath.PathData = {};
				newTreasurePath.TreasureFleetID = treasureFleetID;

				local pathInfo = UnitManager.GetMoveToPath(pUnit, treasureFleetPlotIndex);
				for index, pathNode in ipairs(pathInfo) do
					table.insert(newTreasurePath.PathData, pathNode);

					local pathNodePlot :object = Map.GetPlotByIndex(pathNode);
					if(pathNodePlot ~= nil) then
						pathNodePlot:SetProperty(g_plotPropertyKeys.TreasureFleetPath, 1);
					end
				end
				table.insert(newTreasurePaths, newTreasurePath);
			end
		end				
	end

	return newTreasurePaths;
end

-- Return the unit instance of the best mutiny target for the given player.
function GetMutinyShip(pPlayer :object)
	local pPlayerUnits :object = pPlayer:GetUnits();
	local bestMutinyUnit :object = nil;
	local bestMutinyScore : number = 0;
	for i, pUnit in pPlayerUnits:Members() do
		local score :number = GetMutinyScore(pUnit);
		if(score > bestMutinyScore 
			or bestMutinyUnit == nil) then
			bestMutinyScore = score;
			bestMutinyUnit = pUnit;
		end
	end

	return bestMutinyUnit;
end

function GetMutinyScore(pUnit :object)
	local mutinyScore :number = 0;

	if(IsFlagship(pUnit)) then
		return 0;
	end

	local unitTypeHash = pUnit:GetTypeHash();
	if(unitTypeHash == ms_piratesUnitType) then
		mutinyScore = 4;
	elseif(unitTypeHash == ms_sloopUnitType) then
		mutinyScore = 3;
	elseif(unitTypeHash == ms_brigantineUnitType) then
		mutinyScore = 2;
	elseif(unitTypeHash == ms_galleonUnitType) then
		mutinyScore = 1;
	end

	local crewNumber :number = pUnit:GetProperty(g_unitPropertyKeys.Crew);
	if(crewNumber == nil or crewNumber <= 0) then
		mutinyScore = mutinyScore + 5;
	end

	return mutinyScore;
end

function OnUnitMoved(iPlayerID : number, iUnitID : number)
	if(IsPiratePlayer(iPlayerID)) then
		local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
		if (pUnit == nil) then
			print("Error! Unit not found.");
			return;
		end
		
		-- A player moving might reveal a treasure location.
		CheckTreasureLocationFound(iPlayerID);
		CheckSwashbucklerExplorerPoints(iPlayerID, pUnit);
	end
end

function OnTradeRoutePlundered(plunderPlayerID :number, plunderUnitID :number, traderPlayerID :number, traderUnitID :number, plunderX :number, plunderY :number)
	if(IsPiratePlayer(plunderPlayerID)) then
		ChangeScore(plunderPlayerID, g_scoreTypes.Treasure, 1, plunderX, plunderY);

		local pPlunderConfig :object = PlayerConfigurations[plunderPlayerID];
		if(pPlunderConfig ~= nil and pPlunderConfig:GetCivilizationTypeName() ==  g_CivTypeNames.Privateer) then
			GrantGoldPlot(plunderPlayerID, plunderX, plunderY, PRIVATEER_PLUNDER_TRADE_ROUTE_BONUS, "Privateer Trade Plunder Bonus");
		end

		local pPlunderPlayer :object = Players[plunderPlayerID];
		local pPlunderCulture :object = pPlunderPlayer:GetCulture();
		if(pPlunderCulture:IsPolicyActive(ms_JollyRogersPolicy)) then
			GrantGoldPlot(plunderPlayerID, plunderX, plunderY, RELIC_JOLLY_ROGERS_TRADE_ROUTE_GOLD, "Jolly Rogers Relic Trade Plunder Bonus");
		end
	end
end

function OnCombatOccurred(attackerPlayerID :number, attackerUnitID :number, defenderPlayerID :number, defenderUnitID :number, attackerDistrictID :number, defenderDistrictID :number)
	-- Grant KillInfamyPoints
	if(attackerPlayerID == NO_PLAYER 
		or defenderPlayerID == NO_PLAYER) then
		return;
	end

	local pAttackerPlayer = Players[attackerPlayerID];
	local pDefenderPlayer = Players[defenderPlayerID];
	local pAttackingUnit :object = attackerUnitID ~= NO_UNIT and pAttackerPlayer:GetUnits():FindID(attackerUnitID) or nil;
	local pDefendingUnit :object = defenderUnitID ~= NO_UNIT and pDefenderPlayer:GetUnits():FindID(defenderUnitID) or nil;
	local pAttackingDistrict :object = attackerDistrictID ~= NO_DISTRICT and pAttackerPlayer:GetDistricts():FindID(attackerDistrictID) or nil;
	local pDefendingDistrict :object = defenderDistrictID ~= NO_DISTRICT and pDefenderPlayer:GetDistricts():FindID(defenderDistrictID) or nil;
	
	-- Attacker died to defender.
	if(pAttackingUnit ~= nil and (pAttackingUnit:IsDead() or pAttackingUnit:IsDelayedDeath())) then
		CheckKillRewards(pAttackingUnit, pDefendingUnit, pDefendingDistrict);
	end

	-- Defender died to attacker
	if(pDefendingUnit ~= nil and (pDefendingUnit:IsDead() or pDefendingUnit:IsDelayedDeath())) then
		CheckKillRewards(pDefendingUnit, pAttackingUnit, pAttackingDistrict);
	end

	-- Unit vs Unit combat.
	if(pAttackingUnit ~= nil and pDefendingUnit ~= nil) then
		-- Apply Blackbeard's Fuse effect.
		local pAttackerCulture :object = pAttackerPlayer:GetCulture();
		if(pAttackerCulture:IsPolicyActive(ms_BlackbeardFusePolicy) 
			and GameInfo.Units[pAttackingUnit:GetType()].Domain == "DOMAIN_SEA"
			and GameInfo.Units[pDefendingUnit:GetType()].Domain == "DOMAIN_SEA") then
			local extraMoveProp :number = pDefendingUnit:GetProperty(g_unitPropertyKeys.ExtraMovement);
			local nextExtraMove :number = extraMoveProp ~= nil and extraMoveProp + RELIC_BLACKBEARD_FUSE_MOVE_DAMAGE or RELIC_BLACKBEARD_FUSE_MOVE_DAMAGE;
			print("Applying Blackbeard's Short Fuse Move Damage. DefenderPlayerID=" .. tostring(defenderPlayerID) .. ", defenderUnitID=" .. tostring(defenderUnitID) .. ", oldExtraMove=" .. tostring(extraMoveProp) .. ", nextExtraMove=" .. tostring(nextExtraMove));
			pDefendingUnit:SetProperty(g_unitPropertyKeys.ExtraMovement, nextExtraMove);
		end
	end

	-- Reward Infamy for surviving combat.
	if(pAttackingUnit ~= nil and not pAttackingUnit:IsDead() and not pAttackingUnit:IsDelayedDeath()) then
		CheckSurviveInfamyReward(pAttackingUnit);
	end
	if(pDefendingUnit ~= nil and not pDefendingUnit:IsDead() and not pDefendingUnit:IsDelayedDeath()) then
		CheckSurviveInfamyReward(pDefendingUnit);
	end

	-- Apply Dread Pirate Passive Ability.
	CheckDreadPiratePassiveAbility(pAttackerPlayer, pAttackingUnit);
	CheckDreadPiratePassiveAbility(pDefenderPlayer, pDefendingUnit);

	-- Check for cities being sacked.
	if(pDefendingDistrict ~= nil and pAttackingUnit ~= nil) then
		CheckCitySacked(pDefendingDistrict, pAttackingUnit);
	end
end

function CheckDreadPiratePassiveAbility(pPlayer :object, pUnit :object)
	if(pPlayer == nil) then
		return;
	end

	if(pUnit == nil) then
		return;
	end

	local pUnitAbility = pUnit:GetAbility();
	local iCurrentCount = pUnitAbility:GetAbilityCount("ABILITY_DREAD_PIRATE_PASSIVE");
	if(iCurrentCount > 0) then
		local worldViewData : table = {
		MessageType = 0;
		MessageText = Locale.Lookup("LOC_DREAD_PIRATE_PASSIVE_COMBAT_GOLD", DREAD_PIRATE_PASSIVE_COMBAT_GOLD);
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
		TargetID = pUnit:GetOwner();
		}
		Game.AddWorldViewText(worldViewData);
		pPlayer:GetTreasury():ChangeGoldBalance(DREAD_PIRATE_PASSIVE_COMBAT_GOLD);
	end
end

function CheckSurviveInfamyReward(survivedUnit :object)
	if(survivedUnit == nil) then
		print("survivedUnit missing!");
		return;
	end

	if(IsPiratePlayer(survivedUnit:GetOwner())) then
		ChangeScore(survivedUnit:GetOwner(), g_scoreTypes.Fighting, INFAMY_PIRATE_COMBAT_SURVIVED, survivedUnit:GetX(), survivedUnit:GetY());
	end
end

function CheckCitySacked(pDefendingDistrict :object, pAttackingUnit :object)
	if(pDefendingDistrict == nil or pAttackingUnit == nil) then
		print("data missing");
		return;
	end

	if(pDefendingDistrict:GetType() ~= ms_cityCenterDistrict) then
		return;
	end

	local wallDamage :number = pDefendingDistrict:GetDamage(DefenseTypes.DISTRICT_OUTER);
	local wallMaxDamage	:number = pDefendingDistrict:GetMaxDamage(DefenseTypes.DISTRICT_OUTER);
	if(wallDamage >= wallMaxDamage) then
		local pCity :object = pDefendingDistrict:GetCity();
		local lastSackedTurn :number = pCity:GetProperty(g_cityPropertyKeys.LastSackedTurn);
		local sackTexted :string = "";
		local sackedReward :boolean = false;
		if(lastSackedTurn ~= nil and Game.GetCurrentGameTurn() <= (lastSackedTurn + CITY_SACKED_DEBOUNCE)) then
			print("Player=" .. tostring(pAttackingUnit:GetOwner()) .. " attacked recently sacked city=" .. tostring(pCity:GetName()) .. ", lastSackedTurn=" .. tostring(lastSackedTurn));
			sackTexted = Locale.Lookup("LOC_CITY_RECENTLY_SACKED_WORLDTEXT");
		else
			print("Player=" .. tostring(pAttackingUnit:GetOwner()) .. " sacked city=" .. tostring(pCity:GetName()));
			sackTexted = Locale.Lookup("LOC_CITY_SACKED_WORLDTEXT");
			sackedReward = true;
		end

		local messageData : table = {
			MessageType = 0;
			MessageText = sackTexted;
			PlotX = pAttackingUnit:GetX();
			PlotY = pAttackingUnit:GetY();
			Visibility = RevealedState.VISIBLE;
			TargetID = pAttackingUnit:GetOwner();
		}
		Game.AddWorldViewText(messageData);
		
		pDefendingDistrict:SetDamage(DefenseTypes.DISTRICT_OUTER, 0);
		pDefendingDistrict:SetDamage(DefenseTypes.DISTRICT_GARRISON, 0);

		if(sackedReward == true) then
			ChangeScore(pAttackingUnit:GetOwner(), g_scoreTypes.InfamousPirate, INFAMY_CITY_SACKED, pAttackingUnit:GetX(), pAttackingUnit:GetY());
			GrantGoldPlot(pAttackingUnit:GetOwner(), pAttackingUnit:GetX(), pAttackingUnit:GetY(), GOLD_CITY_SACKED, "Sacked City");
			pCity:SetProperty(g_cityPropertyKeys.LastSackedTurn, Game.GetCurrentGameTurn());
			UnitManager.ReportActivation(pAttackingUnit, "SUNK_GOLD_SHIP");
		end
	end
end

function IsBarbCampGoody(goodyHutType :number)
	local barbCampGoodyData = GameInfo.GoodyHutSubTypes["BARB_GOODIES"];
	if(barbCampGoodyData ~= nil and goodyHutType == barbCampGoodyData.Index) then
		return true;
	end
	
	return false;
end

function OnUnitTriggerGoodyHut(iPlayerID :number, iUnitID :number, goodyHutType :number)
	local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
	if (pUnit == nil) then
		return;
	end

	if(IsBarbCampGoody(goodyHutType)) then
		ChangeScore(iPlayerID, g_scoreTypes.InfamousPirate, IPP_CLEAR_BARB_CAMP, pUnit:GetX(), pUnit:GetY());
		return;
	end

	-- Standard scoring for traditional goody huts.
	ChangeScore(iPlayerID, g_scoreTypes.Treasure, INFAMY_GOODY_HUT, pUnit:GetX(), pUnit:GetY());
end

function OnImprovementPillaged(iPlotIndex :number, eImprovement :number)
	if(iPlotIndex == NO_PLOT) then
		print("ERROR: no plot");
		return;
	end
	
	if(eImprovement == ms_BuriedTreasureImprov or eImprovement == ms_FloatingTreasureImprov) then
		local improvPlot :object = Map.GetPlotByIndex(iPlotIndex);
		if(improvPlot == nil) then
			print("ERROR: improvPlot missing");
			return;
		end
		
		if(improvPlot:GetImprovementOwner() ~= NO_PLAYER) then
			local pOwner :object = Players[improvPlot:GetImprovementOwner()];
			if(pOwner ~= nil) then
				local lostScore :number = -GetBuryTreasureScore(pOwner:GetID());
				ChangeScore(pOwner:GetID(), g_scoreTypes.Treasure, lostScore, improvPlot:GetX(), improvPlot:GetY());
				SendNotification_Plot(g_NotificationsData.YourTreasurePlundered, improvPlot, improvPlot:GetImprovementOwner());
			end
		end
	end
end

function OnPillage(iUnitPlayerID :number, iUnitID :number, eImprovement :number, eBuilding :number, eDistrict :number, iPlotIndex :number)
	if(iUnitPlayerID == NO_PLAYER) then
		return;
	end

	local pUnitPlayer :object = Players[iUnitPlayerID];
	if(pUnitPlayer == nil) then
		print("ERROR: pUnitPlayer missing");
		return;
	end

	local pUnit :object = UnitManager.GetUnit(iUnitPlayerID, iUnitID);
	if (pUnit == nil) then
		print("ERROR: pillaging unit missing");
		return;
	end

	if(eImprovement == ms_BuriedTreasureImprov or eImprovement == ms_FloatingTreasureImprov) then
		OnPillageTreasure_MapUpdate(iUnitPlayerID, iUnitID, iPlotIndex);

		GrantGoldPlot(iUnitPlayerID, pUnit:GetX(), pUnit:GetY(), BURY_TREASURE_PILLAGE_GOLD, "Pillaged Treasure Chest");
		ChangeScore(iUnitPlayerID, g_scoreTypes.Treasure, TREASURE_POINTS_PLUNDER_TREASURE, pUnit:GetX(), pUnit:GetY());
		RelicDropRoll(iUnitPlayerID, RELIC_DROP_PILLAGE_TREASURE, "Pillaged Treasure Chest");
	elseif(eBuilding ~= NO_BUILDING or eDistrict ~= NO_DISTRICT) then
		-- Score for plundering a district or building.
		ChangeScore(iUnitPlayerID, g_scoreTypes.Treasure, TREASURE_POINTS_PLUNDER_DISTRICT, pUnit:GetX(), pUnit:GetY());
	elseif(eImprovement ~= ms_BarbCampImprov) then
		-- Score for plundering non-treasure improvements.
		ChangeScore(iUnitPlayerID, g_scoreTypes.Treasure, TREASURE_POINTS_PLUNDER_IMPROVE, pUnit:GetX(), pUnit:GetY());
	end
end

-- This player unit just pillaged a treasure, remove treasure maps associated with that treasure.
function OnPillageTreasure_MapUpdate(iUnitPlayerID :number, iUnitID :number, iPlotIndex :number)
	local aPlayers = PlayerManager.GetAliveMajors();
	for loop, pPlayer in ipairs(aPlayers) do
		if(IsPiratePlayer(pPlayer:GetID())) then
			local treasureMaps :table = pPlayer:GetProperty(g_playerPropertyKeys.TreasureMaps);
			local newTreasureMaps = {};
			local plotRemoved :boolean = false;
			if(treasureMaps ~= nil) then
				for loop, curTreasureMap in ipairs(treasureMaps) do
					if(curTreasureMap.TreasurePlotIndex == iPlotIndex) then
						plotRemoved = true;
						local pillagedPlot :object = Map.GetPlotByIndex(iPlotIndex);
						if(pillagedPlot ~= nil and pPlayer:GetID() ~= iUnitPlayerID) then
							SendNotification_Plot(g_NotificationsData.BuriedTreasurePillaged, pillagedPlot, pPlayer:GetID());
						end
					else
						table.insert(newTreasureMaps, curTreasureMap);
					end
				end

				if(plotRemoved == true) then
					pPlayer:SetProperty(g_playerPropertyKeys.TreasureMaps, newTreasureMaps);
				end
			end
		end
	end
end

function OnPlayerTurnStartComplete(iPlayerID :number)
	if(iPlayerID == NO_PLAYER or iPlayerID < 0) then
		return;
	end

	local pPlayer = Players[iPlayerID];
	if(pPlayer == nil) then
		return;
	end

	local turn :number = Game.GetCurrentGameTurn();
	local pPlayerUnits : object = pPlayer:GetUnits();
	for i, pUnit in pPlayerUnits:Members() do
		local pUnitAbility :object = pUnit:GetAbility();
		local extraMoveProp :number = pUnit:GetProperty(g_unitPropertyKeys.ExtraMovement);
		if(extraMoveProp ~= nil) then
			pUnit:ChangeMovesRemaining(extraMoveProp);
			pUnit:SetProperty(g_unitPropertyKeys.ExtraMovement, nil);
		end

		local lastChainShotTurn :number = pUnit:GetProperty(g_unitPropertyKeys.LastChainShotHit);
		if(lastChainShotTurn ~= nil and (lastChainShotTurn + HOARDER_ACTIVE_LOCK_DURATION) >= turn) then
			local movesRemaining :number = pUnit:GetMovesRemaining();
			pUnit:ChangeMovesRemaining(-movesRemaining);
		elseif(pUnitAbility ~= nil) then
			-- Remove the dummy unit ability if it is currently applied.
			local lockCount :number = pUnitAbility:GetAbilityCount("ABILITY_CHAINSHOT_MOVE_LOCKED");
			if(lockCount > 0) then
				pUnitAbility:ChangeAbilityCount("ABILITY_CHAINSHOT_MOVE_LOCKED", -lockCount);
			end
		end

		local bucklerAbility :number = pUnitAbility:GetAbilityCount("ABILITY_SWASHBUCKLER_UNIT_ACTIVE");
		if(bucklerAbility ~= nil and bucklerAbility > 0) then
			local maxMoves :number = pUnit:GetMaxMoves();
			pUnit:ChangeMovesRemaining(maxMoves);			
		end
	end
end

function OnUnitInitialized(iPlayerID : number, iUnitID : number)
	NewUnitCreated(iPlayerID, iUnitID);
end

function OnUnitCreated(iPlayerID : number, iUnitID : number)
	NewUnitCreated(iPlayerID, iUnitID);
end

function OnPlayerTurnEnded(iPlayerID :number)
	-- Update Infamous Pirate Search Zones after the pirates have moved so they are up to date.
	if(iPlayerID == INFAMOUS_PIRATES_PLAYERID) then
		UpdateInfamousPiratesSearchZones();
	end
end

-- Setup scenario state information for a new unit.
-- This function can be called multiple times for the same unit 
function NewUnitCreated(iPlayerID : number, iUnitID : number)
	local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
	if (pUnit == nil) then
		return;
	end

	-- Shore Parties do not gain experience.
	if(pUnit:GetType() == ms_piratesUnitType) then
		pUnit:GetExperience():SetExperienceLocked(true);
	end
end


---------------------------------------------------------------- 
-- AI Functions
---------------------------------------------------------------- 
-- Lua callback for Treasure Fleet Behavior Operation.  Needs to always return true so not to fail the operation.
function OnPiratesScenario_DeleteUnitsAtGoal(targetInfo :table)
	-- Delete any operation boats that have made it to the exit plot.
	local treasurePlotIndex :number = Game:GetProperty(g_gamePropertyKeys.TreasureFleetPlotIndex);
	if(treasurePlotIndex == nil) then
		return true;
	end

	local treasurePlot :object = Map.GetPlotByIndex(treasurePlotIndex);
	if(treasurePlot == nil) then
		return true;
	end

	local treasurePlotUnits :table = Map.GetUnitsAt(treasurePlot);
	if treasurePlotUnits ~= nil then
		for pPlotUnit :object in treasurePlotUnits:Units() do
			if(IsTreasureFleetUnit(pPlotUnit) and pPlotUnit:GetOwner() ~= NO_PLAYER) then
				local pOwner :object = Players[pPlotUnit:GetOwner()];
				local pOwnerUnits :object = pOwner:GetUnits();
				print("Treasure Fleet Ship Name=" .. tostring(pPlotUnit:GetName()) .. " reached treasure exit plot.");
				pOwnerUnits:Destroy(pPlotUnit);
			end
		end
	end

	targetInfo.Extra = 1;
	return true;
end


----------------------------------------------------------------  
-- Context Functions
----------------------------------------------------------------  
function Initialize()
	print("Pirates Scenario Start Script initializing");		
	LuaEvents.NewGameInitialized.Add(InitializeNewGame);
	GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted);
	GameEvents.OnUnitMoved.Add(OnUnitMoved);
	GameEvents.TradeRoutePlundered.Add(OnTradeRoutePlundered);
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
	GameEvents.UnitTriggerGoodyHut.Add(OnUnitTriggerGoodyHut);
	GameEvents.OnImprovementPillaged.Add(OnImprovementPillaged);
	GameEvents.OnPillage.Add(OnPillage);
	GameEvents.PlayerTurnStartComplete.Add(OnPlayerTurnStartComplete);
	GameEvents.UnitInitialized.Add(OnUnitInitialized);
	GameEvents.UnitCreated.Add(OnUnitCreated);
	GameEvents.OnPlayerTurnEnded.Add(OnPlayerTurnEnded);
	GameEvents.PiratesScenario_DeleteUnitsAtGoal.Add(OnPiratesScenario_DeleteUnitsAtGoal);	
end
print("Starting pirates scenario script");
Initialize();