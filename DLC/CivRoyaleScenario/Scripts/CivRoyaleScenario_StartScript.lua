----------------------------------------------------------------  
-- Includes
----------------------------------------------------------------  
include "SupportFunctions" -- RandRange

----------------------------------------------------------------  
-- Defines
----------------------------------------------------------------  
local FALLOUT_DURATION = 9999;
local INVALID_COORD = -9999;
local INVALID_PLOT_DISTANCE = -1;
local INVALID_TURN :number = -1;
local NO_TEAM :number = -1;

-- Defines the number of turns between safe zone circle shrinks.  If a time is not defined for the current shrink iteration, the last entry will be reused.
local SAFE_ZONE_DELAY = {
	10,
	10,
	8,
	6,
	6,
	6,
	6,
	6,
	4,
};
local START_SAFE_ZONE_DISTANCE = .50; -- as percentage of GetMaxPlotDistance.  NOTE: This value gets capped to .5 max X/Y to prevent the safe zone looking like an hourglass when it overlaps the map edges too much.
local START_SAFE_ZONE_SHRINK_PERCENT = .80;
local START_SAFE_ZONE_POSITION_MARGIN_NON_WRAP = 0.4; 
local START_SAFE_ZONE_POSITION_MARGIN_WRAP = 0; 

local SAFE_ZONE_MIN_RADIUS = 1;
local SAFE_ZONE_MIN_LANDMASS_SIZE :number = 9;	-- The safe zone will attempt to center itself on hexes that are part of landmasses of that less this size.  Fallback -> Any Land -> Any Tile

local DANGER_ZONE_INTERVAL = 1;			-- How many game turns elapse between danger zone updates?
local DANGER_ZONE_SPEED :number = -1;	-- how quickly does the danger zone distance shrink per update (in hex distance)? 
										-- -1 == Shrink linearly so danger zone touches safe zone when the safe zone shrinks.
local DANGER_ZONE_DELAY :number = 1;	-- Turn delay between displaying the next safe zone and advancing the danger zone.
-- Defines danger zone damage per safe zone phase.  If a damage is not defined for the current safe zone phase, the last entry will be reused.
local DANGER_ZONE_DAMAGE = {
	10, -- Not important, this is the phase before the safe and danger zones appear.  
	10,
	15,
	20,
	25,
	30,
	35,
	40
};

-- Define the number of supply drops per safe zone phase.  Supply Drops are additional goody huts that appear around the edge of the safe zone.  
-- Drops will occur randomly during the current safe zone phase until the defined number is reached.
-- If a number is not defined for the current shrink iteration, the last entry will be reused.
local SUPPLY_DROP_COUNT = {
	0, -- No drops before the safe zone exists.
	1
};

-- Define the number of supply drop crates spawned per supply drop.
local SUPPLY_DROP_CRATES ={
	0, -- No drops before the safe zone exists.
	2,
};

-- Size of the supply drop band as a percentage of the current safe zone distance.
local SUPPLY_DROP_MARGIN = 0.2;

local SUPPLY_DROP_MIN_DISTANCE :number = 10;  -- In Hex Distance, the minimum distance required between supply drop crates during the current supply drop.

local EDGELORD_COMBAT_BONUS_SAFEZONE_MARGIN_SIZE :number = 3; -- In plot distance, how close to the safe zone border do Edgelords have to be to get their combat bonus.

local MUTANT_RAD_CHARGES_PER_FALLOUT_TURN :number = 50;	-- The number of radiation charges a mutant unit gets for being in the fallout for a turn.
local MUTANT_RAD_CHARGE_DURATION :number = 10;			-- How long does radiation dropped by mutant units last?

local g_ObjectStateKeys = {
	SafeZonePhase				= "SafeZonePhase",			-- 0 == Before the first safe zone is defined.
	LastSafeZoneTurn			= "LastSafeZoneTurn",		-- Last game turn on which the safe zone changed.
	StartSafeZoneTurn			= "StartSafeZoneTurn",		-- Number of turns the ring zone started at before shrinking

	CurrentSafeZoneDistance		= "CurrentSafeZoneDistance",
	SafeZoneX					= "SafeZoneX",
	SafeZoneY					= "SafeZoneY",

	NextSafeZoneTurn			= "NextSafeZoneTurn",		-- The next game turn on which the safe zone will shrink.
	NextSafeZoneDistance		= "NextSafeZoneDistance",
	NextSafeZoneX				= "NextSafeZoneX",
	NextSafeZoneY				= "NextSafeZoneY",

	DangerRingDistance			= "DistanceRingDistance",
	DangerRingTurn				= "DangerRingTurn",

	SuppliesDropped				= "SuppliesDropped",		-- The number of supplies dropped during the current safe zone phase.
};

local g_plotStateKeys = {
	SafeZoneRing				= "SafeZoneRing",
	EdgeLordZone				= "EdgeLordZone",			-- Defines plots where EdgeLords get a combat bonus.	
	DamageDelayTime				= "DELAYED_DAMAGE_TURN",	-- (Defined by GameCore) Used for blocking initial fallout damage for plots hit by nukes.
	MutantDropped				= "MutantDropped",			-- Fallout on this plot was dropped by a mutant unit.
};

local g_unitStateKeys = {
	RadiationCharges			= "RadiationCharges",		-- The number of radiation charges held on the current unit.  Used by mutants for their special radiation cloud ability.
};

local m_NotificationsData = {
	SupplyDrop			= { Type = NotificationTypes.USER_DEFINED_1,	Message = "LOC_CIVROYALE_NOTIFICATION_SUPPLY_DROP_MESSAGE", 		Summary = "LOC_CIVROYALE_NOTIFICATION_SUPPLY_DROP_SUMMARY" },
	SafeZoneChanged		= { Type = NotificationTypes.USER_DEFINED_2,	Message = "LOC_CIVROYALE_NOTIFICATION_SAFE_ZONE_CHANGED_MESSAGE", 	Summary = "LOC_CIVROYALE_NOTIFICATION_SAFE_ZONE_CHANGED_SUMMARY" },
	SafeZoneAppeared	= { Type = NotificationTypes.USER_DEFINED_3,	Message = "LOC_CIVROYALE_NOTIFICATION_SAFE_ZONE_APPEARED_MESSAGE", 	Summary = "LOC_CIVROYALE_NOTIFICATION_SAFE_ZONE_APPEARED_SUMMARY" },
};

local g_CivTypeNames = {
	Mutants						= "CIVILIZATION_CIVROYALE_SCENARIO_MUTANTS",
};

local g_MutantUniqueAbilityEnabled = false;

--------------------------------------------------
function GetMargin(size: number, isWrap :boolean)
	if(isWrap == true) then
		return math.floor(size * START_SAFE_ZONE_POSITION_MARGIN_WRAP);
	else
		return math.floor(size * START_SAFE_ZONE_POSITION_MARGIN_NON_WRAP);	
	end
end

function GetSupplyDropCount(safeZonePhase :number)
	if(#SUPPLY_DROP_COUNT == 0) then
		print("SUPPLY_DROP_COUNT is empty");
		return 0;
	end		

	local supplyDropCount :number = SUPPLY_DROP_COUNT[safeZonePhase+1];
	if(supplyDropCount == nil) then
		supplyDropCount = SUPPLY_DROP_COUNT[#SUPPLY_DROP_COUNT];
	end

	if(supplyDropCount ~= nil) then
		return supplyDropCount;
	end

	return 0;
end

function GetSupplyCrateCount(safeZonePhase :number)
	if(#SUPPLY_DROP_CRATES == 0) then
		print("SUPPLY_DROP_CRATES is empty");
		return 0;
	end		

	local supplyCrateCount :number = SUPPLY_DROP_CRATES[safeZonePhase+1];
	if(supplyCrateCount == nil) then
		supplyCrateCount = SUPPLY_DROP_CRATES[#SUPPLY_DROP_CRATES];
	end

	if(supplyCrateCount ~= nil) then
		return supplyCrateCount;
	end

	return 0;
end

function GetDangerZoneDamage(safeZonePhase :number)

	if(#DANGER_ZONE_DAMAGE == 0) then
		print("DANGER_ZONE_DAMAGE is empty");
		return 0;
	end		

	local currentDamage :number = DANGER_ZONE_DAMAGE[safeZonePhase+1];
	if(currentDamage == nil) then
		currentDamage = DANGER_ZONE_DAMAGE[#DANGER_ZONE_DAMAGE];
	end
	return currentDamage;
end

function CalculateNextSafeZoneTurn()
	local safeZonePhase = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase);
	if(safeZonePhase == nil) then
		print("SafeZonePhase missing");
		return;
	end

	if(#SAFE_ZONE_DELAY == 0) then
		print("SAFE_ZONE_DELAY is empty");
		return;
	end		

	local currentShrinkTime = SAFE_ZONE_DELAY[safeZonePhase+1];
	if(currentShrinkTime == nil) then
		currentShrinkTime = SAFE_ZONE_DELAY[#SAFE_ZONE_DELAY];
	end
	Game:SetProperty(g_ObjectStateKeys.StartSafeZoneTurn, currentShrinkTime );	

	local currentTurn = Game.GetCurrentGameTurn();
	local nextSafeZoneTurn = currentTurn + currentShrinkTime;
	print("Next safe zone turn is in " .. tostring(currentShrinkTime) .. " Turns, which is Game Turn " == tostring(nextSafeZoneTurn));	
	Game:SetProperty(g_ObjectStateKeys.NextSafeZoneTurn, nextSafeZoneTurn);
end

function AddFalloutAtLoc(iX : number, iY : number)
	local pPlot : object = Map.GetPlot(iX, iY);
	AddFalloutPlot(pPlot);
end

function AddFalloutPlot(pPlot : object, duration :number)
	if (pPlot ~= nil) then
		local iPlotIndex : number = pPlot:GetIndex();
		AddFalloutPlotIndex(iPlotIndex, duration);
	end
end

function AddFalloutPlotIndex(iPlotIndex : number, duration :number)
	local falloutDuration : number = duration ~= nil and duration or FALLOUT_DURATION;
	Game.GetFalloutManager():AddFallout(iPlotIndex, falloutDuration);
end

function InitializeNewGame()
	print("Civ Royale Scenario InitializeNewGame");
	local currentTurn = Game.GetCurrentGameTurn();

	-- Initialize SafeZonePhase
	local safeZoneShrinkNum = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase);
	if(safeZoneShrinkNum == nil) then
		Game:SetProperty(g_ObjectStateKeys.SafeZonePhase, 0);
	end

	-- Initialize NextSafeZoneTurn, set to invalid define and then calculate proper turn.
	local displayNextSafeZone = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneTurn);
	if(displayNextSafeZone == nil) then
		Game:SetProperty(g_ObjectStateKeys.NextSafeZoneTurn, INVALID_TURN);

		CalculateNextSafeZoneTurn();
	end
	

	-- Initialize LastSafeZoneTurn
	local lastNextSafeZoneTurn = Game:GetProperty(g_ObjectStateKeys.LastSafeZoneTurn);
	if(lastNextSafeZoneTurn == nil) then
		Game:SetProperty(g_ObjectStateKeys.LastSafeZoneTurn, INVALID_TURN);
	end

	-- Initialize NextSafeZoneDistance
	local nextSafeZoneDistance = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneDistance);
	if(nextSafeZoneDistance == nil) then
		local startingSafeZoneSize = math.floor((Map.GetMaxPlotDistance() * START_SAFE_ZONE_DISTANCE));
		local mapWidth, mapHeight = Map.GetGridSize();
		local clampWidth :number = mapWidth/2;
		local clampHeight :number = mapHeight/2;
		
		if(startingSafeZoneSize > clampWidth) then
			print("Clamping startingSafeZoneSize to map width. OriginalStartSize=" .. tostring(startingSafeZoneSize) .. ", MapWidth=" .. tostring(mapWidth) .. ",ClampWidth=" .. tostring(clampWidth));
			startingSafeZoneSize = clampWidth;
		elseif(startingSafeZoneSize > mapHeight) then
			print("Clamping startingSafeZoneSize to map height. OriginalStartSize=" .. tostring(startingSafeZoneSize) .. ", MapHeight=" .. tostring(mapHeight) .. ",ClampHeight=" .. tostring(clampHeight));
			startingSafeZoneSize = clampWidth;
		else
			print("Setting startingSafeZoneSize to START_SAFE_ZONE_DISTANCE percent. StartSize=" .. tostring(startingSafeZoneSize));		
		end
		Game:SetProperty(g_ObjectStateKeys.NextSafeZoneDistance, startingSafeZoneSize);
	end

	-- Initialize SafeZone position
	local nextSafeZoneX = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneX);
	local nextSafeZoneY = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneY);
	if(nextSafeZoneX == nil or nextSafeZoneY == nil) then
		-- Safe Zone should spawn far away from non-world wrap edges.
		local mapWidth, mapHeight = Map.GetGridSize();
		local marginWidth :number = GetMargin(mapWidth, Map.IsWrapX());
		nextSafeZoneX = RandRange(0 + marginWidth, mapWidth-1-marginWidth, "Selecting initial Safe Zone X");

		local marginHeight :number = GetMargin(mapHeight, Map.IsWrapY());
		nextSafeZoneY = RandRange(0 + marginHeight, mapHeight-1-marginHeight, "Selecting initial Safe Zone Y");

		print("Initial Safe Zone=" .. tostring(nextSafeZoneX) .. ", " .. tostring(nextSafeZoneY) .. " Margins=" .. tostring(marginWidth) .. ", " .. tostring(marginHeight) .. " mapSize=" .. tostring(mapWidth) .. "," .. tostring(mapHeight));

		Game:SetProperty(g_ObjectStateKeys.NextSafeZoneX,  nextSafeZoneX);
		Game:SetProperty(g_ObjectStateKeys.NextSafeZoneY, nextSafeZoneY);
	end

	-- Initialize CurrentSafeZoneDistance
	local safeZoneDistance = Game:GetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance);
	if(safeZoneDistance == nil) then
		Game:SetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance, 0);
	end

	-- Initialize DangerRingDistance
	local dangerDistance = Game:GetProperty(g_ObjectStateKeys.DangerRingDistance);
	if(dangerDistance == nil) then
		Game:SetProperty(g_ObjectStateKeys.DangerRingDistance, INVALID_PLOT_DISTANCE);
	end

	-- Initialize DangerRingTurn
	local dangerTurn = Game:GetProperty(g_ObjectStateKeys.DangerRingTurn);
	if(dangerTurn == nil) then
		Game:SetProperty(g_ObjectStateKeys.DangerRingTurn, INVALID_TURN);
	end

	-- Initialize SafeZone position
	local safeZoneX = Game:GetProperty(g_ObjectStateKeys.SafeZoneX);
	local safeZoneY = Game:GetProperty(g_ObjectStateKeys.SafeZoneY);
	if(safeZoneX == nil or safeZoneY == nil) then
		Game:SetProperty(g_ObjectStateKeys.SafeZoneX, INVALID_COORD);
		Game:SetProperty(g_ObjectStateKeys.SafeZoneY, INVALID_COORD);
	end

	print("safeZoneX=" .. tostring(Game:GetProperty(g_ObjectStateKeys.SafeZoneX)) 
		.. " safeZoneY=" .. tostring(Game:GetProperty(g_ObjectStateKeys.SafeZoneY)) 
		.. " safeZoneDistance=" .. tostring(Game:GetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance)) 
		.. " dangerDistance=" .. tostring(Game:GetProperty(g_ObjectStateKeys.DangerRingDistance)));

	-- Initialize SuppliesDropped
	local suppliedDropped :number = Game:GetProperty(g_ObjectStateKeys.SuppliesDropped);
	if(suppliedDropped == nil) then
		Game:SetProperty(g_ObjectStateKeys.SuppliesDropped, 0);
	end

	-- Initial Player Setup
	local aPlayers = PlayerManager.GetAliveMajors();
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	local traditionTech = GameInfo.Civics["CIVIC_MILITARY_TRADITION"];
	for _, pPlayer in ipairs(aPlayers) do
		-- Everyone is at war and knows each other.
		local pDiplo :object = pPlayer:GetDiplomacy();
		for k, iPlayerID in ipairs(pAllPlayerIDs) do
			if (pPlayer:GetID() ~= iPlayerID) then
				pDiplo:SetHasMet(iPlayerID);
				pDiplo:DeclareWarOn(iPlayerID, WarTypes.FORMAL_WAR, true);
			end
		end

		-- Starting Techs.
		-- Providing enough techs so players have flanking bonuses.
		local pCulture:table = pPlayer:GetCulture();
		local pScience:table = pPlayer:GetTechs();
		pCulture:SetCivic(traditionTech.Index, true);
	end

	-- Set initial Red Death damage level.
	UpdateDangerZoneDamage();
end

function OnGameTurnStarted( turn:number )
	print ("Civ Royale Scenario TURN STARTING: " .. turn);

	UpdateSafeZone(turn);
	UpdateDangerZone(turn);
	UpdateSupplyDrops(turn);
	UpdateMutantUniqueAbility(turn);
end

function ShowSafeZone(turn:number)
	local nextZoneDistance = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneDistance);
	local nextZoneX = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneX);
	local nextZoneY = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneY);
	local safeZoneDistance = Game:GetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance);
	local safeZoneX = Game:GetProperty(g_ObjectStateKeys.SafeZoneX);
	local safeZoneY = Game:GetProperty(g_ObjectStateKeys.SafeZoneY);
	local displayNextSafeZone = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneTurn);
	local safeZonePhase = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase);
	if(nextZoneDistance == nil 
		or nextZoneX == nil
		or nextZoneY == nil
		or safeZoneDistance == nil 
		or safeZoneX == nil 
		or safeZoneY == nil
		or displayNextSafeZone == nil
		or safeZonePhase == nil) then
		print("Error bad safe zone data.");
	end

	local nextSafeCenterPlot = Map.GetPlot(nextZoneX, nextZoneY);
	if(nextSafeCenterPlot == nil) then
		print("Error missing next safe center plot!");
		return;
	end
	local nextSafeCenterIndex = nextSafeCenterPlot:GetIndex();

	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do		
		local curPlot = Map.GetPlotByIndex(iPlotIndex);
		local toNextSafeDist :number = Map.GetPlotDistance(iPlotIndex, nextSafeCenterIndex);
		if(toNextSafeDist <= nextZoneDistance) then
			curPlot:SetProperty(g_plotStateKeys.SafeZoneRing, 1);
		else
			curPlot:SetProperty(g_plotStateKeys.SafeZoneRing, 0);
		end

		if(toNextSafeDist <= (nextZoneDistance + EDGELORD_COMBAT_BONUS_SAFEZONE_MARGIN_SIZE) 
			and toNextSafeDist >= (nextZoneDistance - EDGELORD_COMBAT_BONUS_SAFEZONE_MARGIN_SIZE)) then
			curPlot:SetProperty(g_plotStateKeys.EdgeLordZone, 1);
		else
			curPlot:SetProperty(g_plotStateKeys.EdgeLordZone, 0);
		end
	end

	-- For the first actual safe zone phase, reveal two opposite corners of the world so minimap shows the whole world
	if(safeZonePhase == 0) then
		local aPlayers = PlayerManager.GetAliveMajors();
		for loop, pPlayer in ipairs(aPlayers) do
			local iPlayer = pPlayer:GetID();
			local pCurPlayerVisibility = PlayersVisibility[pPlayer:GetID()];
			if(pCurPlayerVisibility ~= nil) then
				pCurPlayerVisibility:ChangeVisibilityCount(0, 0);	
				pCurPlayerVisibility:ChangeVisibilityCount(Map.GetPlotCount() -1, 0);
			end
		end
	end

	-- Set safe zone to next zone
	Game:SetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance, nextZoneDistance);
	Game:SetProperty(g_ObjectStateKeys.SafeZoneX, nextZoneX);
	Game:SetProperty(g_ObjectStateKeys.SafeZoneY, nextZoneY);
	Game:SetProperty(g_ObjectStateKeys.LastSafeZoneTurn, displayNextSafeZone);
	Game:SetProperty(g_ObjectStateKeys.DangerRingTurn, turn + DANGER_ZONE_DELAY);
	Game:SetProperty(g_ObjectStateKeys.DangerRingDistance, INVALID_PLOT_DISTANCE);  -- This triggers a recalculation of the danger ring distance.  We do this so the danger zone edge still shrinks consistently for the far side of the safe center shift.

	Game:SetProperty(g_ObjectStateKeys.SuppliesDropped, 0);  -- Reset supply drops for new phase.

	SendNotification_Plot((safeZonePhase == 0 and m_NotificationsData.SafeZoneAppeared or m_NotificationsData.SafeZoneChanged), nextSafeCenterPlot);
end

function UpdateSafeZone(turn:number)
	-- Time to update the safe zone?
	local displayNextSafeZone = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneTurn);
	if (displayNextSafeZone ~= nil 
	and displayNextSafeZone ~= INVALID_TURN
	and turn >= displayNextSafeZone) then
		ShowSafeZone(turn);
		CalculateNewSafeZone();
	end
end

function CalculateNewSafeZone()
	local safeZoneDistance = Game:GetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance);
	local safeZoneX = Game:GetProperty(g_ObjectStateKeys.SafeZoneX);
	local safeZoneY = Game:GetProperty(g_ObjectStateKeys.SafeZoneY);
	local safeZonePhase = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase);
	if(safeZoneDistance == nil
		or safeZoneX == nil
		or safeZoneY == nil
		or safeZonePhase == nil) then
		print("Error bad data.");
		return;
	end

	print("Calculating new safe zone. Current Zone. x=" .. tostring(safeZoneX) .. " y=" .. tostring(safeZoneY) .. " radius=" .. tostring(safeZoneDistance));

	-- Stop moving the safe zone once it is at minimum size.
	if(safeZoneDistance <= SAFE_ZONE_MIN_RADIUS) then
		print("Safe Zone is already at minimum size. Safe Zone will no longer be updated.");
		Game:SetProperty(g_ObjectStateKeys.NextSafeZoneTurn, INVALID_TURN);
		return;
	end

	--New safe zone needs to fit inside the old zone.
	local newSafeZoneDistance = math.floor(safeZoneDistance * START_SAFE_ZONE_SHRINK_PERCENT);
	newSafeZoneDistance = math.max(newSafeZoneDistance, SAFE_ZONE_MIN_RADIUS); 

	local safeZoneDelta = safeZoneDistance - newSafeZoneDistance;
	local safeDeltaPlots = Map.GetNeighborPlots(safeZoneX, safeZoneY, safeZoneDelta);
	local safePlots = {};
	
	-- Try only center the safe zone on land masses of a certain size
	for loop, deltaPlot in ipairs(safeDeltaPlots) do
		local deltaMapArea = deltaPlot:GetArea();
		if(deltaMapArea ~= nil 
			and not deltaMapArea:IsWater()
			and deltaMapArea:GetPlotCount() > SAFE_ZONE_MIN_LANDMASS_SIZE) then
			table.insert(safePlots, deltaPlot);
		end
	end

	-- Fallback #1 - Any Land tiles
	if(#safePlots <= 0) then
		for loop, deltaPlot in ipairs(safeDeltaPlots) do
			local deltaMapArea = deltaPlot:GetArea();
			if(deltaMapArea ~= nil 
				and not deltaMapArea:IsWater()) then
				table.insert(safePlots, deltaPlot);
			end
		end		
	end

	-- Fallback #2 - Any tile
	if(#safePlots <= 0 and safeDeltaPlots ~= nil) then
		safePlots = safeDeltaPlots;
	end

	if(#safePlots > 0) then
		local newCenterIndex = RandRange(1, #safePlots, "Selecting new safe zone center");
		local pPlot = safePlots[newCenterIndex];
		local newSafeZoneX = pPlot:GetX();
		local newSafeZoneY = pPlot:GetY();

		local pCenterMapArea = pPlot:GetArea();
		local isWaterStr = pPlot:IsWater() and "True" or "False";
		print("New Safe Zone. x=" .. tostring(newSafeZoneX) .. ", y=" .. tostring(newSafeZoneY) .. ", radius=" .. tostring(newSafeZoneDistance) .. ", centerWater=" .. tostring(isWaterStr) .. ", centerAreaSize=" .. tostring(pCenterMapArea:GetPlotCount()) );

		Game:SetProperty(g_ObjectStateKeys.NextSafeZoneDistance, newSafeZoneDistance);
		Game:SetProperty(g_ObjectStateKeys.NextSafeZoneX, newSafeZoneX);
		Game:SetProperty(g_ObjectStateKeys.NextSafeZoneY, newSafeZoneY);
	end

	safeZonePhase = safeZonePhase + 1;
	print("New Safe Zone Phase=" .. tostring(safeZonePhase));
	Game:SetProperty(g_ObjectStateKeys.SafeZonePhase, safeZonePhase);

	CalculateNextSafeZoneTurn(); 
end

function UpdateDangerZoneDamage()
	local safeZonePhase = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase);
	if(safeZonePhase == nil) then
		print("SafeZonePhase missing");
		return;
	end

	local currentDamage :number = GetDangerZoneDamage(safeZonePhase);
	local pFalloutManager = Game.GetFalloutManager();
	local previousDamange :number = pFalloutManager:GetFalloutDamageOverride()
	if(previousDamange ~=  currentDamage) then
		pFalloutManager:SetFalloutDamageOverride(currentDamage);
		print("Danger Zone Damage = " .. tostring(currentDamage));
	end
end

function UpdateDangerZone(turn:number)
	-- Is this a danger zone update turn?
	local dangerRingTurn = Game:GetProperty(g_ObjectStateKeys.DangerRingTurn);
	if(dangerRingTurn == nil 
		or dangerRingTurn == INVALID_TURN
		or turn < dangerRingTurn) then
		return;
	end

	-- DANGER ZONE!
	local dangerDistance = Game:GetProperty(g_ObjectStateKeys.DangerRingDistance);
	local safeZoneDistance = Game:GetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance);
	local nextSafeZoneTurn :number = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneTurn); 
	local safeZoneX = Game:GetProperty(g_ObjectStateKeys.SafeZoneX);
	local safeZoneY = Game:GetProperty(g_ObjectStateKeys.SafeZoneY);
	if(dangerDistance == nil 
		or safeZoneDistance == nil
		or safeZoneX == nil
		or safeZoneY == nil) then
		print("Error bad data.");
		return;
	end

	UpdateDangerZoneDamage();

	local safeCenterPlot = Map.GetPlot(safeZoneX, safeZoneY);
	if(safeCenterPlot == nil) then
		print("Error missing safe center plot!");
		return;
	end
	local safeCenterIndex = safeCenterPlot:GetIndex();

	-- If the DangerRingDistance is invalid, we need to recalculate it.  It should be the farthest plot distance from the safe zone center that is not covered in fallout.
	local pFalloutManager = Game.GetFalloutManager();
	if(dangerDistance == INVALID_PLOT_DISTANCE) then
		for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do		
			if (not pFalloutManager:HasFallout(iPlotIndex)) then
				local safeCenterDistance :number = Map.GetPlotDistance(iPlotIndex, safeCenterIndex);
				if(safeCenterDistance >= dangerDistance) then
					dangerDistance = safeCenterDistance;
				end
			end
		end
		print("Reset Danger Distance= " .. tostring(dangerDistance));
	end

	local newDangerDistance :number;
	if(DANGER_ZONE_SPEED > 0) then
		-- Advance at the given speed so player units have time to get out of the way.
		newDangerDistance = dangerDistance - DANGER_ZONE_SPEED;	
	else
		-- Linearly shrink to size of safety zone based on NextSafeZoneTurn
		newDangerDistance = safeZoneDistance;
		if(turn < nextSafeZoneTurn) then
			newDangerDistance = math.floor(dangerDistance - (dangerDistance-safeZoneDistance)/(nextSafeZoneTurn-turn));
		end
	end	

	if(newDangerDistance > safeZoneDistance) then
		-- keep shrinking danger zone until it matches the safe zone.
		print("DANGER ZONE! newDangerDistance=" .. tostring(newDangerDistance));

		local aPlayers = PlayerManager.GetAliveMajors();
		for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do		
			local dangerPlot = Map.GetPlotByIndex(iPlotIndex);
			local toSafeDistance :number = Map.GetPlotDistance(iPlotIndex, safeCenterIndex);
			if (not pFalloutManager:HasFallout(iPlotIndex)) then
				if(toSafeDistance >= newDangerDistance) then
					--print("Adding fallout to plot=" .. tostring(iPlotIndex) .. ", X=" .. tostring(dangerPlot:GetX()) .. ", Y=" .. tostring(dangerPlot:GetY()) .. ", toSafeDistance=" .. tostring(toSafeDistance));
					AddFalloutPlotIndex(iPlotIndex);

					for loop, pPlayer in ipairs(aPlayers) do
						local iPlayer = pPlayer:GetID();
						local pCurPlayerVisibility = PlayersVisibility[pPlayer:GetID()];
						if(pCurPlayerVisibility ~= nil) then
						--	pCurPlayerVisibility:ChangeVisibilityCount(iPlotIndex, 0);
						end
					end
				end
			end
		end

		Game:SetProperty(g_ObjectStateKeys.DangerRingDistance, newDangerDistance);
		Game:SetProperty(g_ObjectStateKeys.DangerRingTurn, turn + DANGER_ZONE_INTERVAL);
	end
end

-- Access to safe zone for game core, intended for use by the AI
function CivRoyale_GetSafeZone(targetInfo)
	--print("Calling function hook from AI");
	targetInfo.PlotX = Game:GetProperty(g_ObjectStateKeys.SafeZoneX);
	targetInfo.PlotY = Game:GetProperty(g_ObjectStateKeys.SafeZoneY);
	targetInfo.Extra = Game:GetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance);	

	if ( targetInfo.PlotX < 0 ) then
		local mapWidth, mapHeight = Map.GetGridSize();
		targetInfo.PlotY = mapHeight / 2;
		targetInfo.PlotX = mapWidth / 2;

		-- Check if the plot is on water. We don't want that. Look for a land spot
		local centerPlot = Map.GetPlot(targetInfo.PlotX, targetInfo.PlotY);
		if ( centerPlot:IsWater() ) then
			local centerPlotIndex : number = centerPlot:GetIndex();
			local bestLandDistance : number = Map.GetPlotCount();
			for plotIndex = 0, Map.GetPlotCount()-1, 1 do	
				local distance :number = Map.GetPlotDistance(plotIndex, centerPlotIndex);
				local curPlot = Map.GetPlotByIndex(plotIndex);
				if( curPlot:IsWater() and distance < bestLandDistance ) then
					bestLandDistance = distance;
					targetInfo.PlotX = curPlot:GetX();
					targetInfo.PlotY = curPlot:GetY();
				end
			end
		end
	end
	return true;
end

function UpdateSupplyDrops(turns :number)
	local safeZoneDistance = Game:GetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance);
	local safeZoneX = Game:GetProperty(g_ObjectStateKeys.SafeZoneX);
	local safeZoneY = Game:GetProperty(g_ObjectStateKeys.SafeZoneY);
	local safeZonePhase = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase);
	local suppliesDropped = Game:GetProperty(g_ObjectStateKeys.SuppliesDropped);
	if(safeZoneDistance == nil
		or safeZoneX == nil
		or safeZoneY == nil
		or safeZonePhase == nil
		or suppliesDropped == nil) then
		print("Error bad data.");
		return;
	end

	-- Can't drop supplies when the safe zone hasn't been defined yet
	if(safeZoneX == INVALID_COORD 
		or safeZoneY == INVALID_COORD
		or safeZoneDistance <= 0) then
		return;
	end

	local supplyCountMax :number = GetSupplyDropCount(safeZonePhase);
	if(suppliesDropped >= supplyCountMax) then
		return;
	end

	local lastSafeZoneTurn :number = Game:GetProperty(g_ObjectStateKeys.LastSafeZoneTurn);
	local nextSafeZoneTurn :number = Game:GetProperty(g_ObjectStateKeys.NextSafeZoneTurn); 
	local phaseDuration = nextSafeZoneTurn - lastSafeZoneTurn;
	local chance :number = supplyCountMax / phaseDuration * 100;
	local randNum :number = RandRange(0, 100, "Supply Drop Chance");
	local outcomeString :string = (randNum <= chance and "Success" or "Failed");
	print("Supply Drop Random Roll=" .. outcomeString  .. ", randNum=" .. tostring(randNum) .. ", chance=" .. tostring(chance));
	if(randNum <= chance) then
		
		local safeCenterPlot = Map.GetPlot(safeZoneX, safeZoneY);
		if(safeCenterPlot == nil) then
			print("Error missing safe center plot!");
			return;
		end
		local safeCenterIndex = safeCenterPlot:GetIndex();

		local maxDistance :number = safeZoneDistance + safeZoneDistance * SUPPLY_DROP_MARGIN;
		local minDistance :number = safeZoneDistance - safeZoneDistance * SUPPLY_DROP_MARGIN;
		local goodyHutImprovIndex : number = GameInfo.Improvements["IMPROVEMENT_SUPPLY_DROP"].Index;
		local supplyDropPlots = {};
		local pFalloutManager = Game.GetFalloutManager();
		for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do	
			local toSafeDistance :number = Map.GetPlotDistance(iPlotIndex, safeCenterIndex);
			if(toSafeDistance <= maxDistance and toSafeDistance >= minDistance) then
				local curPlot = Map.GetPlotByIndex(iPlotIndex);
				if (not pFalloutManager:HasFallout(iPlotIndex)											-- Not in fallout
					and ImprovementBuilder.CanHaveImprovement(curPlot, goodyHutImprovIndex, NO_TEAM)	-- Supports the supply crate improvement
					and not curPlot:IsUnit()) then														-- No units already on hex.
					table.insert(supplyDropPlots, curPlot);
				end
			end
		end

		local supplyCrateCount = GetSupplyCrateCount(safeZonePhase);
		local aPlayers = PlayerManager.GetAliveMajors();
		for dropCount = 0, supplyCrateCount-1, 1 do
			-- Filter drop plots that are too close to other supply drop crates.
			if(SUPPLY_DROP_MIN_DISTANCE > 0) then
				local nextSupplyDropPlots :table = {};
				for oldPlotsIndex=1, #supplyDropPlots do
					local oldDropPlot = supplyDropPlots[oldPlotsIndex];
					local adjPlots = Map.GetNeighborPlots(oldDropPlot:GetX(), oldDropPlot:GetY(), SUPPLY_DROP_MIN_DISTANCE);
					local validPlot :boolean = true;
					for loop, adjPlot in ipairs(adjPlots) do
						if(adjPlot:GetImprovementType() == goodyHutImprovIndex) then
							validPlot = false;
							break;
						end
					end
					
					if(validPlot == true) then
						table.insert(nextSupplyDropPlots, oldDropPlot);
					end
				end
				supplyDropPlots = nextSupplyDropPlots;	
			end
			
			if(#supplyDropPlots > 0) then
				local dropPlotIndex :number = RandRange(1, #supplyDropPlots, "Supply Drop Plot Roll");
				local dropPlot = supplyDropPlots[dropPlotIndex];
				print("Adding Supply Drop to (" .. tostring(dropPlot:GetX()) .. "," .. tostring(dropPlot:GetY()) .. ")");
				ImprovementBuilder.SetImprovementType(dropPlot, goodyHutImprovIndex, NO_TEAM);
				SendNotification_Plot(m_NotificationsData.SupplyDrop, dropPlot);

				for loop, pPlayer in ipairs(aPlayers) do
					local iPlayer = pPlayer:GetID();
					local pCurPlayerVisibility = PlayersVisibility[pPlayer:GetID()];
					if(pCurPlayerVisibility ~= nil) then
						-- reveal the crate hex.
						pCurPlayerVisibility:ChangeVisibilityCount(dropPlot:GetIndex(), 0);	
					end
				end
				
				table.remove(supplyDropPlots, dropPlotIndex);
			else
				print("Supply Drop Complete, no remaining valid supply drop plots.");
				return;
			end
		end

		suppliesDropped = suppliesDropped + 1;
		Game:SetProperty(g_ObjectStateKeys.SuppliesDropped, suppliesDropped);
		print("Supply Drops=" .. tostring(suppliesDropped) .. "/" .. tostring(supplyCountMax) .. " SafeZonePhase=" .. tostring(safeZonePhase));
	end
end

function UpdateMutantUniqueAbility(turn)

	if g_MutantUniqueAbilityEnabled == false then
		return;
	end

	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		if (pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Mutants) then
			local pPlayer = Players[iPlayerID];
			if(pPlayer ~= nil) then
				local pPlayerUnits : object = pPlayer:GetUnits();
				for i, pUnit in pPlayerUnits:Members() do
					CheckMutantUnitUniqueAbility(pUnit, true);
				end
			end
		end
	end
end

function CheckMutantUnitUniqueAbility(pUnit :object, recharge: boolean)

	if g_MutantUniqueAbilityEnabled == false then
		return;
	end

	local pUnitPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY());
	if(pUnitPlot ~= nil) then
		local pFalloutManager = Game.GetFalloutManager();
		local unitRadChargesProp = pUnit:GetProperty(g_unitStateKeys.RadiationCharges);
		if(pFalloutManager:HasFallout(pUnitPlot:GetIndex())) then
			-- Is this fallout dropped by a mutant unit?
			local mutantDropProp = pUnitPlot:GetProperty(g_plotStateKeys.MutantDropped);
			if(recharge == true) then 
				if(mutantDropProp == nil or mutantDropProp ~= 1) then
					-- This fallout was not dropped by a mutant unit, recharge RadiationCharges!
					local newUnitRadCharges = MUTANT_RAD_CHARGES_PER_FALLOUT_TURN;
					if(unitRadChargesProp ~= nil) then
						newUnitRadCharges = newUnitRadCharges + unitRadChargesProp;
					end
					pUnit:SetProperty(g_unitStateKeys.RadiationCharges, newUnitRadCharges);
				else
					-- mutant dropped fallout, heal the unit to counteract the damage taking this turn.
					local safeZonePhase = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase);
					if(safeZonePhase == nil) then
						print("SafeZonePhase missing");
						return;
					end
					local redDeathDamage :number = GetDangerZoneDamage(safeZonePhase);
					pUnit:ChangeDamage(-redDeathDamage);
				end
			end
		else
			-- No fallout on this plot, should the unit drop fallout here?
			if(unitRadChargesProp ~= nil and unitRadChargesProp > 0) then
				AddFalloutPlot(pUnitPlot, MUTANT_RAD_CHARGE_DURATION);

				pUnitPlot:SetProperty(g_plotStateKeys.MutantDropped, 1);

				local nextRadCharges :number = unitRadChargesProp - 1;
				pUnit:SetProperty(g_unitStateKeys.RadiationCharges, nextRadCharges);
			end
		end
	end
end

function SendNotification_Plot(notificationData :table, pPlot :object)
	if (pPlot == nil) then
		return;
	end

	local msgString = Locale.Lookup(notificationData.Message);
	local sumString = Locale.Lookup(notificationData.Summary);

	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		NotificationManager.SendNotification(iPlayerID, notificationData.Type, msgString, sumString, pPlot:GetX(), pPlot:GetY());
	end
	return true;
end

function OnNuclearWeaponDetonated(iPlayerID :number, locationX :number, locationY :number, wmdType :number)
	RefreshAllWMDAbility(iPlayerID);

	local nukeData = GameInfo.WMDs[wmdType];
	if(nukeData == nil) then
		print("error: missing nuke info");
		return;
	end
	
	local curTurn = Game.GetCurrentGameTurn();

	print("Setting WMD blast fallout to have delayed damage. locationX=" .. tostring(locationX) .. ", locationY=" .. tostring(locationY) .. ", blastRadius=" .. tostring(nukeData.BlastRadius));
	local nukedPlots = Map.GetNeighborPlots(locationX, locationY, nukeData.BlastRadius);
	for loop, curPlot in ipairs(nukedPlots) do
		curPlot:SetProperty(g_plotStateKeys.DamageDelayTime, curTurn);
	end
	
end

function OnWMDCountChanged( playerID :number, eWMD :number, iDelta :number)
	RefreshAllWMDAbility(playerID);
end

function RefreshAllWMDAbility(iPlayerID :number)
	local pPlayer = Players[iPlayerID];
	if(pPlayer == nil) then
		print("Error: No Player!");
		return;
	end

	local playerWMDs = pPlayer:GetWMDs();
	local grantWMDAbility :boolean = playerWMDs:GetWeaponCount(GameInfo.WMDs["WMD_THERMONUCLEAR_DEVICE"].Index) > 0;
	print("Setting WMD Ability to " .. tostring(grantWMDAbility) .. " playerID: " .. tostring(iPlayerID));
	local pPlayerUnits : object = pPlayer:GetUnits();
    for i, pUnit in pPlayerUnits:Members() do
		local unitInfo:table = GameInfo.Units[pUnit:GetType()];
		if(unitInfo ~= nil and unitInfo.FormationClass ~= "FORMATION_CLASS_CIVILIAN") then
			local pUnitAbility = pUnit:GetAbility();
			local iCurrentCount = pUnitAbility:GetAbilityCount("ABILITY_WMD_STRIKE");
			pUnitAbility:ChangeAbilityCount("ABILITY_WMD_STRIKE", grantWMDAbility and 1 or -iCurrentCount);
		end
	end
end

function RefreshUnitWMDAbility(pUnit :object)
	local pPlayer = Players[pUnit:GetOwner()];
	if(pPlayer == nil) then
		print("Error: No Player!");
		return;
	end

	local playerWMDs = pPlayer:GetWMDs();
	local grantWMDAbility :boolean = playerWMDs:GetWeaponCount(GameInfo.WMDs["WMD_THERMONUCLEAR_DEVICE"].Index) > 0;
	if(grantWMDAbility) then
		print("Setting WMD Ability for new unit playerID: " .. tostring(pPlayer:GetID()) .. " unitID: " .. tostring(pUnit:GetID()));
		local pUnitAbility = pUnit:GetAbility();
		pUnitAbility:ChangeAbilityCount("ABILITY_WMD_STRIKE", 1);
	end
end
function OnUnitInitialized(iPlayerID : number, iUnitID : number)
	local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
	if (pUnit == nil) then
		return;
	end
	RefreshUnitWMDAbility(pUnit);
end

function OnUnitMoved(iPlayerID : number, iUnitID : number)
	local pOwnerConfig : table = PlayerConfigurations[iPlayerID];
	if (pOwnerConfig ~= nil and pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Mutants) then
		local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
		if (pUnit == nil) then
			print("Error! Unit not found.");
			return;
		end
		CheckMutantUnitUniqueAbility(pUnit, false);
	end
end

function Initialize()
	print("Civ Royale Scenario Start Script initializing");		
	Game:SetProperty("DANGER_ZONE_INTERVAL", DANGER_ZONE_INTERVAL);
	Game:SetProperty("DANGER_ZONE_SPEED", DANGER_ZONE_SPEED);
	Game:SetProperty("DANGER_ZONE_DELAY", DANGER_ZONE_DELAY);	

	LuaEvents.NewGameInitialized.Add(InitializeNewGame);
	GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted);
	GameEvents.CivRoyale_GetSafeZone.Add(CivRoyale_GetSafeZone);
	GameEvents.OnNuclearWeaponDetonated.Add(OnNuclearWeaponDetonated);
	GameEvents.OnWMDCountChanged.Add(OnWMDCountChanged);
	GameEvents.UnitInitialized.Add(OnUnitInitialized);
	GameEvents.OnUnitMoved.Add(OnUnitMoved);
end
print("Starting civ royale scenario script");
Initialize();