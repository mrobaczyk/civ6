----------------------------------------------------------------  
-- Includes
----------------------------------------------------------------  
include "SupportFunctions" -- RandRange
include "CivRoyaleScenario_PropKeys"
include "CivRoyaleScenario_UnitCommands"	-- Game Side handler for custom unit commands.
include "CivRoyaleScenario_GameStateUtils"
include "CivRoyaleScenario_UFOUnitNames"

----------------------------------------------------------------  
-- Defines
----------------------------------------------------------------  
local FALLOUT_DURATION = 9999;
local INVALID_COORD = -9999;
local INVALID_PLOT_DISTANCE = -1;
local INVALID_TURN :number = -1;
local NO_TEAM :number = -1;
local NO_PLAYER :number = -1;

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

-- Define the expected number of supply drops per safe zone phase.  This number controls the random chance of a supply drop occurring on a given turn.
-- The actual number of drops will vary based on chance.
-- Supply Drops are additional goody huts that appear around the edge of the safe zone.  
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

local SUPPLY_DROP_MIN_DIST_CRATES :number = 10;	-- [Hex Distance] The minimum distance a new supply crate must be from other supply crates.
local SUPPLY_DROP_MIN_DIST_UNITS  :number = 6;	-- [Hex Distance] The minimum distance a new supply crate must be from player units.

local SUPPLY_CRATE_IMPROVEMENT_INDEX : number = GameInfo.Improvements["IMPROVEMENT_SUPPLY_DROP"].Index;

local EDGELORD_COMBAT_BONUS_SAFEZONE_MARGIN_SIZE :number 	= 3; -- In plot distance, how close to the safe zone border do Edgelords have to be to get their combat bonus.
local EDGELORD_GIFT_IMPROVEMENT_INDEX :number 				= GameInfo.Improvements[EDGELORDS_GRIEVING_GIFT_IMPROVEMENT].Index;

local MUTANT_RAD_CHARGES_PER_FALLOUT_TURN :number = 8;	-- The number of radiation charges a mutant unit gets for being in the fallout for a turn.
local MUTANT_RAD_CHARGE_DURATION :number = 5;			-- How long does radiation dropped by mutant units last?

local CULTISTS_GDR_STARTING_DAMAGE :number = 50;		-- How much damage should the Cultist's GDR start with?

local m_PirateTreasureDrops =
{
	{ Unit = "UNIT_INFANTRY",		WorldText="LOC_TREASURE_UNIT_INFANTRY_RECRUITED",		VeteranName="LOC_UNIT_PIRATE_TREASURE_INFANTRY_NAME",		Weight = 35 },
	{ Unit = "UNIT_TANK",			WorldText="LOC_TREASURE_UNIT_TANK_RECRUITED",			VeteranName="LOC_UNIT_PIRATE_TREASURE_TANK_NAME",			Weight = 60 },
	{ Unit = "UNIT_CRIPPLED_GDR",	WorldText="LOC_TREASURE_UNIT_CRIPPLED_GDR_RECRUITED",	VeteranName="LOC_UNIT_PIRATE_TREASURE_CRIPPLED_GDR_NAME",	Weight = 5 },
};

local g_MutantUniqueAbilityEnabled = true;
local m_eCrippledGDRTypeHash	:number = GameInfo.Units["UNIT_CRIPPLED_GDR"].Hash;
local m_eZombieTypeHash			:number = GameInfo.Units[ZOMBIES_ZOMBIE_COMBAT_UNIT].Hash;

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
		local safeZoneCenterPlots :table = {};
		local mapWidth, mapHeight = Map.GetGridSize();
		local marginWidth :number = GetMargin(mapWidth, Map.IsWrapX());
		local marginHeight :number = GetMargin(mapHeight, Map.IsWrapY());
		for x = 0 + marginWidth, mapWidth-1-marginWidth, 1 do
			for y = 0 + marginHeight, mapHeight-1-marginHeight, 1 do
				local centerPlot :object = Map.GetPlot(x, y);
				if(centerPlot ~= nil) then
					table.insert(safeZoneCenterPlots, centerPlot);
				end
			end
		end

		-- Filter based on safe zone center plot rules
		safeZoneCenterPlots = FilterSafeZoneCenterPlots(safeZoneCenterPlots);

		local centerRand :number = RandRange(1, #safeZoneCenterPlots, "Selecting Initial Safe Zone Center");
		local safeCenterPlot :object = safeZoneCenterPlots[centerRand];

		print("Initial Safe Zone=" .. tostring(safeCenterPlot:GetX()) .. ", " .. tostring(safeCenterPlot:GetY()) .. " Margins=" .. tostring(marginWidth) .. ", " .. tostring(marginHeight) .. " mapSize=" .. tostring(mapWidth) .. "," .. tostring(mapHeight));

		Game:SetProperty(g_ObjectStateKeys.NextSafeZoneX, safeCenterPlot:GetX());
		Game:SetProperty(g_ObjectStateKeys.NextSafeZoneY, safeCenterPlot:GetY());
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

	NewGameCultists();
	NewGameEdgeLords();
	NewGamePreppers();
	NewGamePirates();
	NewGameZombies();
	UpdateJocksUniqueAbility(); -- Initial update will give the first hail mary to all Jocks.
end

function NewGameCultists()
	-- Grant GDR to cultists
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	local pGDRInfo = GameInfo.Units["UNIT_CRIPPLED_GDR"];
	local pCivilianInfo = GameInfo.Units["UNIT_SETTLER"];
	if(pGDRInfo == nil or pCivilianInfo == nil) then
		print("ERROR: Missing data!");
		return
	end

	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		if (pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Cultists) then
			local pPlayer = Players[iPlayerID];
			if(pPlayer ~= nil) then
				local pPlayerUnits : object = pPlayer:GetUnits();
				for i, pUnit in pPlayerUnits:Members() do
					if(pUnit:GetTypeHash() == pCivilianInfo.Hash) then
						local pGDRUnit = pPlayerUnits:Create(pGDRInfo.Index, pUnit:GetX(), pUnit:GetY());
						if(pGDRUnit ~= nil) then
							pGDRUnit:SetDamage(CULTISTS_GDR_STARTING_DAMAGE);
							pGDRUnit:GetExperience():SetVeteranName(Locale.Lookup( "LOC_UNIT_UNDYING_EYE_NAME" ));
							pGDRUnit:GetExperience():SetExperienceLocked(true);
						end
						break;
					end
				end
			end
		end
	end
end

function NewGameEdgeLords()
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		if (pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.EdgeLords) then	
			print("Granting initial gifts (" .. tostring(EDGELORDS_GRIEVING_GIFT_START_COUNT) .. ") to EdgeLord Player " .. tostring(iPlayerID));
			local pPlayer :object = Players[iPlayerID];	
			if(pPlayer ~= nil) then
				pPlayer:SetProperty(g_playerPropertyKeys.GrievingGiftCount, EDGELORDS_GRIEVING_GIFT_START_COUNT);
			end
		end
	end	
end

function NewGamePreppers()
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		if (pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Preppers) then	
			print("Granting initial traps (" .. tostring(PREPPER_TRAP_START_COUNT) .. ") to Prepper Player " .. tostring(iPlayerID));
			local pPlayer :object = Players[iPlayerID];
			if(pPlayer ~= nil) then
				pPlayer:SetProperty(g_playerPropertyKeys.ImprovisedTrapCount, PREPPER_TRAP_START_COUNT);
			end
		end
	end
end

function NewGameZombies()
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		if (pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Zombies) then
			print("Replacing initial combat units with zombies for Zombie Player=" .. tostring(iPlayerID));
			ReplaceCombatUnitsWithZombies(iPlayerID, 1);

			if(ZOMBIES_ADDITIONAL_START_ZOMBIES > 0) then
				print("Adding additional starting zombie hordes for Zombie Player=" .. tostring(iPlayerID));
				local pZombieInfo = GameInfo.Units[ZOMBIES_ZOMBIE_COMBAT_UNIT];
				local pPlayer = Players[iPlayerID];
				local pPlayerUnits : object = pPlayer:GetUnits();
				local startingPosition = pPlayerConfig:GetStartingPosition();
				for newZombieCount = 1, ZOMBIES_ADDITIONAL_START_ZOMBIES, 1 do	
					local pZombieUnit = pPlayerUnits:Create(pZombieInfo.Index, startingPosition.x, startingPosition.y);
				end
			end
		end
	end
end

-- Replaces all this player's combat units with zombies.
function ReplaceCombatUnitsWithZombies(iPlayerID :number, zombiePerCombat :number)
	local pPlayer = Players[iPlayerID];
	local pCivilianInfo = GameInfo.Units["UNIT_SETTLER"];
	local pZombieInfo = GameInfo.Units[ZOMBIES_ZOMBIE_COMBAT_UNIT];
	if(pPlayer ~= nil) then
		local pPlayerUnits : object = pPlayer:GetUnits();
		for i, pUnit in pPlayerUnits:Members() do
			if(pUnit:GetTypeHash() ~= pCivilianInfo.Hash
				and pUnit:GetTypeHash() ~= pZombieInfo.Hash) then
				print("Replacing combat unit type=" .. tostring(pUnit:GetType()) .. " with " .. tostring(zombiePerCombat) .. " zombies at " .. tostring(pUnit:GetX()) .. "," .. tostring(pUnit:GetY()) .. ".");
				for newZombieCount = 0, zombiePerCombat-1, 1 do	
					local pZombieUnit = pPlayerUnits:Create(pZombieInfo.Index, pUnit:GetX(), pUnit:GetY());
					UnitManager.ReportActivation(pZombieUnit, "ZOMBIE_SPAWN");
				end
				pPlayerUnits:Destroy(pUnit);
			end
		end
	end
end

function OnGameTurnStarted( turn:number )
	print ("Civ Royale Scenario TURN STARTING: " .. turn);

	UpdateSafeZone(turn);
	UpdateDangerZone(turn);
	UpdateSupplyDrops(turn);
	UpdateGrievingGifts(turn);

	-- Civ Unique Ability Updates
	UpdateAliensUniqueAbility(turn);
	UpdateEdgeLordsUniqueAbility(turn);
	UpdateJocksUniqueAbility();
	UpdateMutantUniqueAbility(turn);
	UpdateMadScientistsUniqueAbility(turn);
	UpdateWanderersUniqueAbility(turn);
	UpdateZombiesUniqueAbility(turn);
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

	-- Remove the previous safe zone flags
	local oldMaxSafeZoneRange :number = safeZoneDistance + EDGELORD_COMBAT_BONUS_SAFEZONE_MARGIN_SIZE;
	for dx = -oldMaxSafeZoneRange, oldMaxSafeZoneRange, 1 do
		for dy = -oldMaxSafeZoneRange, oldMaxSafeZoneRange, 1 do
			local scanPlot :object = Map.GetPlotXYWithRangeCheck(safeZoneX, safeZoneY, dx, dy, oldMaxSafeZoneRange);
			if(scanPlot ~= nil) then
				scanPlot:SetProperty(g_plotStateKeys.SafeZoneRing, 0);
				scanPlot:SetProperty(g_plotStateKeys.EdgeLordZone, 0);
			end
		end
	end

	-- Add flags for new safe zone.
	local newMaxSafeZoneRange :number = nextZoneDistance + EDGELORD_COMBAT_BONUS_SAFEZONE_MARGIN_SIZE;
	for dx = -newMaxSafeZoneRange, newMaxSafeZoneRange, 1 do
		for dy = -newMaxSafeZoneRange, newMaxSafeZoneRange, 1 do
			local curPlot :object = Map.GetPlotXYWithRangeCheck(nextZoneX, nextZoneY, dx, dy, newMaxSafeZoneRange);
			if(curPlot ~= nil) then
				local toNextSafeDist :number = Map.GetPlotDistance(curPlot:GetIndex(), nextSafeCenterIndex);
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

	SendNotification_Plot((safeZonePhase == 0 and g_NotificationsData.SafeZoneAppeared or g_NotificationsData.SafeZoneChanged), nextSafeCenterPlot);
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
	local safePlots :table = FilterSafeZoneCenterPlots(safeDeltaPlots);
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

-- Filter input table of potential safe zone center plots based on safe zone center plot rules.  This function will fallback to the entire input table if no qualified plots are found.
function FilterSafeZoneCenterPlots(safeZoneCenterPlots :table)
	local filteredSafeZoneCenterPlots = {};
	-- Try only center the safe zone on land masses of a certain size
	for loop, curCenterPlot in ipairs(safeZoneCenterPlots) do
		local deltaMapArea = curCenterPlot:GetArea();
		if(deltaMapArea ~= nil 
			and not deltaMapArea:IsWater()
			and deltaMapArea:GetPlotCount() > SAFE_ZONE_MIN_LANDMASS_SIZE) then
			table.insert(filteredSafeZoneCenterPlots, curCenterPlot);
		end
	end

	-- Fallback #1 - Any Land tiles
	if(#filteredSafeZoneCenterPlots <= 0) then
		print("Fallback #1 - Any Land tiles");
		for loop, curCenterPlot in ipairs(safeZoneCenterPlots) do
			local deltaMapArea = curCenterPlot:GetArea();
			if(deltaMapArea ~= nil 
				and not deltaMapArea:IsWater()) then
				table.insert(filteredSafeZoneCenterPlots, curCenterPlot);
			end
		end		
	end

	-- Fallback #2 - Any tile
	if(#filteredSafeZoneCenterPlots <= 0 and safeZoneCenterPlots ~= nil) then
		filteredSafeZoneCenterPlots = safeZoneCenterPlots;
	end

	return filteredSafeZoneCenterPlots;
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

	local minDangerDistance :number = safeZoneDistance+1;
	local newDangerDistance :number = minDangerDistance;  -- Default to surrounding the safe zone.
	if(DANGER_ZONE_SPEED > 0) then
		-- Advance at the given speed so player units have time to get out of the way.
		newDangerDistance = dangerDistance - DANGER_ZONE_SPEED;	
	elseif(nextSafeZoneTurn ~= INVALID_TURN and turn < nextSafeZoneTurn) then
		-- Linearly shrink to size of safety zone based on NextSafeZoneTurn.  Bare in mind that rounding error means this is not 100% smooth.
		newDangerDistance = math.floor(dangerDistance - (dangerDistance-minDangerDistance)/(nextSafeZoneTurn-turn));
	end	

	-- Clamp to minDangerDistance
	if(newDangerDistance < minDangerDistance) then
		newDangerDistance = minDangerDistance;
	end

	if(newDangerDistance ~= dangerDistance) then
		-- keep shrinking danger zone until it matches the safe zone.
		print("DANGER ZONE! newDangerDistance=" .. tostring(newDangerDistance));

		local aPlayers = PlayerManager.GetAliveMajors();
		for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do		
			local dangerPlot = Map.GetPlotByIndex(iPlotIndex);
			local toSafeDistance :number = Map.GetPlotDistance(iPlotIndex, safeCenterIndex);
			if(toSafeDistance >= newDangerDistance) then
				-- Danger Zone!
				if (pFalloutManager:HasFallout(iPlotIndex)) then
					-- Already has fallout, check to see if it is Mutant spread fallout that needs to be converted to propery Red Death fallout.
					local mutantDroppedProp = dangerPlot:GetProperty(g_plotStateKeys.MutantDropped);
					if(mutantDroppedProp ~= nil and mutantDroppedProp > 0) then
						-- Mutant Dropped, convert to proper Red Death.
						AddFalloutPlotIndex(iPlotIndex); -- maxes out fallout duration.
						dangerPlot:SetProperty(g_plotStateKeys.MutantDropped, nil);
					end
				else
					-- Fallout for all in the Danger Zone!
					--print("Adding fallout to plot=" .. tostring(iPlotIndex) .. ", X=" .. tostring(dangerPlot:GetX()) .. ", Y=" .. tostring(dangerPlot:GetY()) .. ", toSafeDistance=" .. tostring(toSafeDistance));
					AddFalloutPlotIndex(iPlotIndex);
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

	if ( targetInfo.PlotX > 0 ) then
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

function CivRoyale_SmallSafeZone(targetInfo)
	local safeZoneDistance = Game:GetProperty(g_ObjectStateKeys.CurrentSafeZoneDistance);
	if (safeZoneDistance <= 10 ) then
		targetInfo.Extra = 1;
	else
		targetInfo.Extra = 0;
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
	if(supplyCountMax <= 0) then
		-- No drops for this safe zone phase.
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
		local supplyDropPlots = {};
		local pFalloutManager = Game.GetFalloutManager();
		for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do	
			local toSafeDistance :number = Map.GetPlotDistance(iPlotIndex, safeCenterIndex);
			if(toSafeDistance <= maxDistance and toSafeDistance >= minDistance) then
				local curPlot = Map.GetPlotByIndex(iPlotIndex);
				if (not pFalloutManager:HasFallout(iPlotIndex)													-- Not in fallout
					and ImprovementBuilder.CanHaveImprovement(curPlot, SUPPLY_CRATE_IMPROVEMENT_INDEX, NO_TEAM)	-- Supports the supply crate improvement
					and not curPlot:IsUnit()) then																-- No units already on hex.
					table.insert(supplyDropPlots, curPlot);
				end
			end
		end

		local supplyCrateCount = GetSupplyCrateCount(safeZonePhase);
		local aPlayers = PlayerManager.GetAliveMajors();
		for dropCount = 0, supplyCrateCount-1, 1 do
			-- Filter drop plots that are too close to other supply drop crates or player units.
			supplyDropPlots = FilterAllAdjPlots(supplyDropPlots, SUPPLY_DROP_MIN_DIST_CRATES, FilterPlot_Crates, false);
			supplyDropPlots = FilterAllAdjPlots(supplyDropPlots, SUPPLY_DROP_MIN_DIST_UNITS, FilterPlot_NotMajorCivUnits, true);
		
			if(#supplyDropPlots > 0) then
				local dropPlotIndex :number = RandRange(1, #supplyDropPlots, "Supply Drop Plot Roll");
				local dropPlot = supplyDropPlots[dropPlotIndex];
				print("Adding Supply Drop to (" .. tostring(dropPlot:GetX()) .. "," .. tostring(dropPlot:GetY()) .. ")");
				ImprovementBuilder.SetImprovementType(dropPlot, SUPPLY_CRATE_IMPROVEMENT_INDEX, NO_TEAM);
				SendNotification_Plot(g_NotificationsData.SupplyDrop, dropPlot);

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

function UpdateGrievingGifts(turn :number)
	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do
		local curPlot = Map.GetPlotByIndex(iPlotIndex);
		if(curPlot ~= nil) then
			local giftOwnerProp = curPlot:GetProperty(g_plotStateKeys.DeferredGiftOwner);
			if(giftOwnerProp ~= nil) then
				print("Placing deferred Grieving Gift. owner=" .. tostring(giftOwnerProp) .. ", location=" .. tostring(curPlot:GetX()) .. "," .. tostring(curPlot:GetY()));
				ImprovementBuilder.SetImprovementType(curPlot, EDGELORD_GIFT_IMPROVEMENT_INDEX, giftOwnerProp);
				curPlot:SetProperty(g_plotStateKeys.DeferredGiftOwner, nil);

				-- Send Supply Drop notification to all non-owner players.
				local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
				for k, iPlayerID in ipairs(pAllPlayerIDs) do
					if(iPlayerID ~= giftOwnerProp) then
						SendNotification_Plot(g_NotificationsData.SupplyDrop, curPlot, iPlayerID);
					end
				end
			end
		end
	end
end

-- Returns true if plot does not contain supply crate.
function FilterPlot_Crates(curPlot :object) 
	return curPlot:GetImprovementType() ~= SUPPLY_CRATE_IMPROVEMENT_INDEX;
end

function UpdateAliensUniqueAbility(turn :number)
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		if (pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Aliens) then
			local pPlayer = Players[iPlayerID];
			if(pPlayer ~= nil) then
				local pPlayerUnits : object = pPlayer:GetUnits();
				for i, pUnit in pPlayerUnits:Members() do
					CheckUnitAbilityDepleted(pUnit, turn, g_unitStateKeys.CloakTime, "ABILITY_ALIENS_CLOAK", ALIEN_CLOAK_DURATION, nil);
				end
			end
		end
	end	
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
			}
			Game.AddWorldViewText(messageData);
		end

		pUnitAbility:ChangeAbilityCount(abilityName, -iCurrentCount);
	end
end

function UpdateEdgeLordsUniqueAbility(turn :number)
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		local pPlayer :object = Players[iPlayerID];
		if (pPlayer ~= nil 
			and pPlayerConfig ~= nil 
			and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.EdgeLords) then
			local giftCountProp :number = pPlayer:GetProperty(g_playerPropertyKeys.GrievingGiftCount);
			if(giftCountProp == nil or giftCountProp < EDGELORDS_GRIEVING_GIFT_MAX_COUNT) then
				local giftTurnProp :number = pPlayer:GetProperty(g_playerPropertyKeys.GrievingGiftTurn);
				if(giftTurnProp == nil or turn >= (giftTurnProp + EDGELORDS_GRIEVING_GIFT_DEBOUNCE)) then
					local newGiftCount = giftCountProp ~= nil and (giftCountProp+EDGELORDS_GRIEVING_GIFT_REGEN_RATE) or EDGELORDS_GRIEVING_GIFT_REGEN_RATE;
					newGiftCount = math.min(newGiftCount, EDGELORDS_GRIEVING_GIFT_MAX_COUNT);
					print("Recharging Grieving Gift for Player " .. tostring(iPlayerID) .. "New Count=" .. tostring(newGiftCount));
					pPlayer:SetProperty(g_playerPropertyKeys.GrievingGiftCount, newGiftCount);
					pPlayer:SetProperty(g_playerPropertyKeys.GrievingGiftTurn, turn);
				end
			end
		end
	end
end

function UpdateJocksUniqueAbility()
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		UpdateJocksHailMaryCount(iPlayerID);
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
		local unitRadSpreadProp :number = pUnit:GetProperty(g_unitStateKeys.RadiationSpread);
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
				end
			end
		else
			-- No fallout on this plot, should the unit drop fallout here?
			if(unitRadChargesProp ~= nil and unitRadChargesProp > 0 
				and (unitRadSpreadProp == nil or unitRadSpreadProp > 0)) then -- g_unitStateKeys.RadiationSpread is default true if nil
				AddFalloutPlot(pUnitPlot, MUTANT_RAD_CHARGE_DURATION);

				pUnitPlot:SetProperty(g_plotStateKeys.MutantDropped, 1);

				local nextRadCharges :number = unitRadChargesProp - 1;
				pUnit:SetProperty(g_unitStateKeys.RadiationCharges, nextRadCharges);
			end
		end
	end
end

-- Checks buried treasure for given pirate (assumed) unit.  Handles reward/next treasure location if needed.
function CheckPiratesUnitUniqueAbility(pUnit :object)
	if(pUnit == nil or pUnit:GetOwner() == NO_PLAYER) then
		return;
	end
	
	local pPlayer :object = Players[pUnit:GetOwner()];
	if(pPlayer == nil) then
		return;
	end

	local treasurePlotIndex :number = pPlayer:GetProperty(g_playerPropertyKeys.TreasurePlotIndex);
	if(treasurePlotIndex == nil) then
		return;
	end	
	
	local treasurePlot :object = Map.GetPlotByIndex(treasurePlotIndex);
	if(treasurePlot == nil) then
		return;
	end
	
	if(pUnit:GetX() ~= treasurePlot:GetX() or pUnit:GetY() ~= treasurePlot:GetY()) then
		return;
	end

	print("Treasure (" .. tostring(treasurePlot:GetX()) .. "," .. tostring(treasurePlot:GetY()) .. ") found by player " .. tostring(pUnit:GetOwner()));

	-- Reset treasurePlotIndex so spawning units can't accidently retrigger the treasure for this plot.
	pPlayer:SetProperty(g_playerPropertyKeys.TreasurePlotIndex, nil);

	local reward :table = RandWeight(m_PirateTreasureDrops, "Treasure reward roll");
	if(reward ~= nil) then
		if(reward.WorldText ~= nil) then
			local messageData : table = {
				MessageType = 0;
				MessageText = reward.WorldText;
				PlotX = pUnit:GetX();
				PlotY = pUnit:GetY();
				Visibility = RevealedState.VISIBLE;
			}
			Game.AddWorldViewText(messageData);
		end

		if(reward.Unit ~= nil) then
			local rewardUnitData = GameInfo.Units[reward.Unit];
			if(rewardUnitData ~= nil) then
				print("Spawning Treasure Unit (" .. tostring(reward.Unit) .. ") at (" .. tostring(pUnit:GetX()) .. "," .. tostring(pUnit:GetY()) .. ")");
				local pPlayerUnits = pPlayer:GetUnits();
				local pRewardUnit = pPlayerUnits:Create(rewardUnitData.Index, pUnit:GetX(), pUnit:GetY());

				if(reward.VeteranName ~= nil and pRewardUnit ~= nil) then
					pRewardUnit:GetExperience():SetVeteranName(Locale.Lookup(reward.VeteranName));
				end
			end
		end
	else
		print("ERROR: Missing reward table!");
		return;
	end

	SelectNewPirateTreasureLocation(pUnit:GetOwner());
end

function UpdateMadScientistsUniqueAbility(turn :number)
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		if (pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.MadScientists) then
			local pPlayer = Players[iPlayerID];
			if(pPlayer ~= nil) then
				local pPlayerUnits : object = pPlayer:GetUnits();
				for i, pUnit in pPlayerUnits:Members() do
					CheckUnitAbilityDepleted(pUnit, turn, g_unitStateKeys.ShieldTime, "ABILITY_MAD_SCIENTISTS_UNIT_SHIELD", MAD_SCIENTIST_SHIELD_DURATION, "LOC_SHIELDS_DEPLETED")
				end
			end
		end
	end	
end

function UpdateWanderersUniqueAbility(turn :number)
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	

	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		local pPlayer :object = Players[iPlayerID];
		if (pPlayer ~= nil 
			and pPlayerConfig ~= nil 
			and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Wanderers) then
			local roadTurnProp :number = pPlayer:GetProperty(g_playerPropertyKeys.RoadVisionTurn);
			local roadActiveProp :number = pPlayer:GetProperty(g_playerPropertyKeys.RoadVisionActive);
			if(roadTurnProp ~= nil 
				and roadActiveProp ~= nil
				and roadActiveProp > 0
				and turn > roadTurnProp + WANDERER_ROAD_VISION_DURATION) then
				DeactivateRoadVision(iPlayerID);
			end
		end
	end	
end

function UpdateZombiesUniqueAbility(turn :number)
	-- No decay on the first turn.
	if(turn == GameConfiguration.GetStartTurn()) then
		return;
	end

	local lessDecayPromotion = GameInfo.UnitPromotions["PROMOTION_ZOMBIE_LESS_DECAY"];
	local pZombieInfo = GameInfo.Units[ZOMBIES_ZOMBIE_COMBAT_UNIT];
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		if (pPlayerConfig ~= nil 
			-- Only Zombie players and barbarians can have zombies.
			and (pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Zombies or pPlayerConfig:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV) ) then
			local pPlayer = Players[iPlayerID];
			local pPlayerUnits : object = pPlayer:GetUnits();
			for i, pUnit in pPlayerUnits:Members() do
				if(pUnit:GetTypeHash() == pZombieInfo.Hash) then
					local pUnitExp :object = pUnit:GetExperience();
					local decayDamage :number = ZOMBIE_HORDE_DECAY;
					if(lessDecayPromotion ~= nil and pUnitExp:HasPromotion(lessDecayPromotion.Index)) then
						decayDamage = ZOMBIE_HORDE_LESS_DECAY;
					end

					if(decayDamage > 0) then
						print("Applying zombie decay damage=" .. tostring(decayDamage) .. " to player=" .. tostring(iPlayerID) .. ", unitID=" .. tostring(pUnit:GetID()));
						if(decayDamage + pUnit:GetDamage() >= pUnit:GetMaxDamage()) then
							local pUnitPlot : object = Map.GetPlot(pUnit:GetX(), pUnit:GetY());
							if(pUnitPlot ~= nil) then
								SendNotification_Plot(g_NotificationsData.ZombieDecayDeath, pUnitPlot, iPlayerID);
							end		
							UnitManager.Kill(pUnit);
						else
							pUnit:ChangeDamage(decayDamage);
						end
					end
				end
			end
		end
	end	
end

function DeactivateRoadVision(iPlayerID :number)
	local pPlayer :object = Players[iPlayerID];
	if(pPlayer == nil) then
		print("ERROR: missing player");
		return;
	end
	
	local pCurPlayerVisibility = PlayersVisibility[iPlayerID];
	if(pCurPlayerVisibility == nil) then
		print("ERROR: missing player visibility");
		return;
	end

	local plotRoadActiveKey = GetPlayerSpecificPropKey(g_plotPlayerSpecificKeys.RoadVisionActive, iPlayerID);
	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do		
		local curPlot :object = Map.GetPlotByIndex(iPlotIndex);
		if(curPlot ~= nil) then
			local roadActiveProp = curPlot:GetProperty(plotRoadActiveKey);
			if(roadActiveProp ~= nil and roadActiveProp > 0) then
				pCurPlayerVisibility:ChangeVisibilityCount(curPlot:GetIndex(), -1);
				curPlot:SetProperty(plotRoadActiveKey, nil);
			end
		end
	end

	pPlayer:SetProperty(g_playerPropertyKeys.RoadVisionActive, nil);
end

function UpdateJocksHailMaryCount(iPlayerID)
	local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
	if (pPlayerConfig == nil or pPlayerConfig:GetCivilizationTypeName() ~= g_CivTypeNames.Jocks) then
		return;
	end

	local pPlayer = Players[iPlayerID];
	if(pPlayer == nil) then
		print("ERROR: missing player!");
		return;
	end

	local playerWMDs = pPlayer:GetWMDs();
	if(playerWMDs == nil) then
		print("ERROR: missing player WMDS!");
		return;
	end

	-- Does the player already have a Hail Mary nuke?
	if(playerWMDs:GetWeaponCount(GameInfo.WMDs[JOCKS_HAIL_MARY_WMD].Index) > 0) then
		return;
	end

	local hailMaryTurnProp :number = pPlayer:GetProperty(g_playerPropertyKeys.HailMaryTurn);
	local curTurn = Game.GetCurrentGameTurn();
	if(hailMaryTurnProp ~= nil and curTurn <  (hailMaryTurnProp + JOCKS_HAIL_MARY_DEBOUNCE)) then
		return;
	end

	-- Take a Hail Mary and call me in the morning.
	local hailMaryWMD = GameInfo.WMDs[JOCKS_HAIL_MARY_WMD];
	if(hailMaryWMD == nil) then
		print("ERROR: Missing Hail Mary WMD define!");
		return;
	end

	print("Granting Hail Mary to Player " .. tostring(iPlayerID));

	playerWMDs:ChangeWeaponCount(hailMaryWMD.Index, 1);
	SendNotification(g_NotificationsData.HailMaryReady, iPlayerID);

	Game:SetProperty(hailMaryTurnKey, curTurn);
end

function NewGamePirates()
	local pAllPlayerIDs : table = PlayerManager.GetAliveIDs();	
	for k, iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
		if (pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Pirates) then
			SelectNewPirateTreasureLocation(iPlayerID);
		end
	end
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
	
	
	
	-- Reset Hail Mary recharge so players do not immediately get a new Hail Mary if they haven't recharged for a while.
	if(wmdType == GameInfo.WMDs[JOCKS_HAIL_MARY_WMD].Index) then
		if(iPlayerID == NO_PLAYER) then
			print("error: iPlayerID is NO_PLAYER.");
			return;
		end 
	
		local pPlayer :object = Players[iPlayerID];
		if(pPlayer == nil) then
			print("error: missing player.");
			return;
		end
	
		pPlayer:SetProperty(g_playerPropertyKeys.HailMaryTurn, Game.GetCurrentGameTurn());
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
	local grantWMDAbility :boolean = ShouldHaveWMDAbility(iPlayerID);
	print("Setting WMD Ability to " .. tostring(grantWMDAbility) .. " playerID: " .. tostring(iPlayerID));
	local pPlayerUnits : object = pPlayer:GetUnits();
    for i, pUnit in pPlayerUnits:Members() do
		RefreshUnitWMDAbility(pUnit);
	end
end

function RefreshUnitWMDAbility(pUnit :object)
	local pPlayer :object = Players[pUnit:GetOwner()];
	if(pPlayer == nil) then
		print("Error: No Player!");
		return;
	end

	-- Civilians can not launch WMDs
	local unitInfo :table = GameInfo.Units[pUnit:GetType()];
	if(unitInfo == nil or unitInfo.FormationClass == "FORMATION_CLASS_CIVILIAN") then
		return;
	end

	local playerWMDs :object = pPlayer:GetWMDs();
	local grantWMDAbility :boolean = ShouldHaveWMDAbility(pUnit:GetOwner());

	local pUnitAbility :object = pUnit:GetAbility();
	local iCurrentCount :number = pUnitAbility:GetAbilityCount("ABILITY_WMD_STRIKE");
	if(grantWMDAbility and iCurrentCount < 1) then
		print("Enabling WMD Ability playerID: " .. tostring(pPlayer:GetID()) .. ", unitID: " .. tostring(pUnit:GetID()));
		pUnitAbility:ChangeAbilityCount("ABILITY_WMD_STRIKE", -iCurrentCount+1);	
	elseif(not grantWMDAbility and iCurrentCount > 0) then
		print("Disabling WMD Ability playerID: " .. tostring(pPlayer:GetID()) .. ", unitID: " .. tostring(pUnit:GetID()));
		pUnitAbility:ChangeAbilityCount("ABILITY_WMD_STRIKE", -iCurrentCount);
	end	
end

function ShouldHaveWMDAbility(iPlayerID :number)
	local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
	if (pPlayerConfig ~= nil) then
		if(pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Jocks) then
			return true;
		end
	end

	local pPlayer = Players[iPlayerID];
	if(pPlayer ~= nil) then
		local playerWMDs = pPlayer:GetWMDs();
		if(playerWMDs ~= nil 
			and playerWMDs:GetWeaponCount(GameInfo.WMDs["WMD_THERMONUCLEAR_DEVICE"].Index) > 0) then
			return true;
		end
	end
end

function OnUnitInitialized(iPlayerID : number, iUnitID : number)
	NewUnitCreated(iPlayerID, iUnitID);
end

function OnUnitCreated(iPlayerID : number, iUnitID : number)
	NewUnitCreated(iPlayerID, iUnitID);
end

-- Setup scenario state information for a new unit.
-- This function can be called multiple times for the same unit 
function NewUnitCreated(iPlayerID : number, iUnitID : number)
	local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
	if (pUnit == nil) then
		return;
	end
	RefreshUnitWMDAbility(pUnit);

	-- Crippled GDRs only get promotions thru sacrificing units.
	if(pUnit:GetTypeHash() == m_eCrippledGDRTypeHash) then
		pUnit:GetExperience():SetExperienceLocked(true);
	end
end

function OnUnitMoved(iPlayerID : number, iUnitID : number)
	local pOwnerConfig : table = PlayerConfigurations[iPlayerID];
	if (pOwnerConfig ~= nil) then
		if(pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Mutants) then
			local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
			if (pUnit == nil) then
				print("Error! Unit not found.");
				return;
			end
			CheckMutantUnitUniqueAbility(pUnit, false);
		elseif(pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Pirates) then
			local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
			if (pUnit == nil) then
				print("Error! Unit not found.");
				return;
			end
			CheckPiratesUnitUniqueAbility(pUnit);
		end
	end
end

function OnUnitTriggerGoodyHut(iPlayerID :number, iUnitID :number, goodyHutType :number)
	-- Traps deduct a movement point from the triggering unit.
	if(IsTrapGoodyHutType(goodyHutType)) then
		print("Trap Improvement removing 1 movement point from iPlayerID=" .. tostring(iPlayerID) .. ", iUnitID=" .. tostring(iUnitID));
		local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
		if (pUnit ~= nil) then
			pUnit:ChangeMovesRemaining(-1);
		end
		return;
	end

	local pOwnerConfig : table = PlayerConfigurations[iPlayerID];
	local pOwner :object = Players[iPlayerID];

	-- Preppers get additional traps
	if(pOwner ~= nil
		and pOwnerConfig ~= nil 
		and pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Preppers) then	
		print("Prepper Player " .. tostring(iPlayerID) .. " gets " .. tostring(PREPPER_TRAP_PER_GOODY_HUT) .. " traps for popping a goody hut");
		local trapCountProp :number = pOwner:GetProperty(g_playerPropertyKeys.ImprovisedTrapCount);
		local newtrapCount = trapCountProp ~= nil and (trapCountProp + PREPPER_TRAP_PER_GOODY_HUT) or PREPPER_TRAP_PER_GOODY_HUT;
		pOwner:SetProperty(g_playerPropertyKeys.ImprovisedTrapCount, newtrapCount);
	-- Zombie Beastmaster replaces all earned units with Zombie Hordes.
	elseif (pOwnerConfig ~= nil and pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Zombies) then
		-- Non-damaging goody huts heal zombie units.
		if(not IsDamageGoodyHutType(goodyHutType)) then
			-- Heal all zombie units on the plot.  We do this because we want to ensure the combat unit in a formation gets the heal even if the triggering 
			-- unit is technically the civilian.
			local pTriggerUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
			if (pTriggerUnit == nil) then
				print("Error! Zombie Unit not found.");
			else
				local pTriggerUnitPlot :object = Map.GetPlot(pTriggerUnit:GetX(), pTriggerUnit:GetY());
				if(pTriggerUnitPlot == nil) then
					print("Error! Goody Trigger Unit missing plot.");
				else
					local pUnitList = Map.GetUnitsAt(pTriggerUnitPlot);
					if pUnitList ~= nil then
						for pUnit in pUnitList:Units() do
							pUnit:ChangeDamage(-ZOMBIES_ZOMBIES_GOODY_HEAL);
						end
					end
				end
			end
		end

		-- Replace any granted units with more zombie hordes
		ReplaceCombatUnitsWithZombies(iPlayerID, ZOMBIES_ZOMBIES_PER_GOODY_UNIT);
	end
end

function OnPostUnitPromotionEarned(iPlayerID :number, iUnitID :number, promotionType :number)
	-- Crippled GDRs need to relock their experience after selecting a promotion.  This is due to the experience lock normally being lifted upon selecting a promotion.
	local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
	if (pUnit == nil) then
		print("Error! Unit not found.");
		return;
	end
	if(pUnit:GetTypeHash() == m_eCrippledGDRTypeHash) then
		local pUnitExp = pUnit:GetExperience();
		if(pUnitExp == nil) then
			print("Error! Unit Experience not found.");
			return;
		end

		-- Crippled GDRs only get promotions thru sacrificing units.
		pUnitExp:SetExperienceLocked(true);
	end
end

function OnCombatOccurred(attackerPlayerID :number, attackerUnitID :number, defenderPlayerID :number, defenderUnitID :number)
	if(attackerPlayerID == NO_PLAYER 
		or attackerUnitID == NO_UNIT) then
		return;
	end

	local pAttackerPlayer :object = Players[attackerPlayerID];
	local pAttackingUnit :object = pAttackerPlayer:GetUnits():FindID(attackerUnitID);

	-- Cloaked units should decloak if they attacked in combat.
	-- This needs to happen before we try to fetch the defender information because a WMD attack by a cloaked unit 
	-- does not have a defender.
	if(pAttackingUnit ~= nil) then
		local pAttackAbility :object = pAttackingUnit:GetAbility();
		local cloakCount :number = pAttackAbility:GetAbilityCount("ABILITY_ALIENS_CLOAK");
		if(cloakCount > 0) then
			print("Decloaking player=" .. tostring(pAttackerPlayer:GetID()) .. ",unit=" .. tostring(pAttackingUnit:GetID()) .. " because it attacked.");
			pAttackAbility:ChangeAbilityCount("ABILITY_ALIENS_CLOAK", -cloakCount);

			-- Push the CloakTime into the past as if this ability naturally ended this turn.  This is easier than having to check unit ability count whenever checking ability timer status.
			local newCloakTime :number = Game.GetCurrentGameTurn() - ALIEN_CLOAK_DURATION;
			pAttackingUnit:SetProperty(g_unitStateKeys.CloakTime, newCloakTime);
			pAttackingUnit:SetProperty(g_unitStateKeys.UncloakAttackTime, Game.GetCurrentGameTurn());
		end
	end

	-- The remaining checks require a valid defender player/unit.
	if(defenderPlayerID == NO_PLAYER
		or defenderUnitID == NO_UNIT) then
		return;
	end

	local pDefenderPlayer = Players[defenderPlayerID];
	local pDefendingUnit = pDefenderPlayer:GetUnits():FindID(defenderUnitID);

	-- Zombie factions get additional Zombie Hordes when they kill a unit in combat.
	-- Non-Zombie Attacker died to Zombie Defender.
	if((pAttackingUnit:IsDead() or pAttackingUnit:IsDelayedDeath())
		and pAttackingUnit:GetTypeHash() ~= m_eZombieTypeHash
		and pDefendingUnit:GetTypeHash() == m_eZombieTypeHash) then
		GrantZombieCombatDeath(defenderPlayerID, pDefendingUnit);
	end

	-- Non-Zombie Defender died to Zombie Attacker
	if((pDefendingUnit:IsDead() or pDefendingUnit:IsDelayedDeath()) 
		and pDefendingUnit:GetTypeHash() ~= m_eZombieTypeHash
		and pAttackingUnit:GetTypeHash() == m_eZombieTypeHash) then
		GrantZombieCombatDeath(attackerPlayerID, pAttackingUnit);
	end
end

function GrantZombieCombatDeath(zombiePlayerID :number, pZombieUnit :object)
	if(zombiePlayerID == nil or zombiePlayerID == NO_PLAYER) then
		print("ERROR: bad zombiePlayerID=" .. tostring(zombiePlayerID));
		return;
	end

	if(pZombieUnit == nil) then
		print("ERROR: missing pZombieUnit");
		return;
	end

	local pZombiePlayer = Players[zombiePlayerID];
	if(pZombiePlayer == nil) then
		print("ERROR: zombie player=" .. tostring(zombiePlayerID) .. " missing");
		return;
	end

	local pZombieInfo = GameInfo.Units[ZOMBIES_ZOMBIE_COMBAT_UNIT];
	if(pZombieInfo == nil) then
		print("ERROR: bad zombie unit info");
		return;
	end

	print("Player=" .. tostring(zombiePlayerID) .. " Creating new zombies from enemy combat death. DeadUnitType=" .. tostring(pZombieUnit:GetName()) .. ", Location=" .. tostring(pZombieUnit:GetX()) .. "," ..  tostring(pZombieUnit:GetY()));
	local pZombieUnits : object = pZombiePlayer:GetUnits();
	for newZombieCount = 0, ZOMBIES_ZOMBIES_PER_COMBAT_DEATH-1, 1 do	
		local pZombieUnit = pZombieUnits:Create(pZombieInfo.Index, pZombieUnit:GetX(), pZombieUnit:GetY());
		if(pZombieUnit ~= nil) then
			UnitManager.FinishMoves(pZombieUnit);
			UnitManager.ReportActivation(pZombieUnit, "ZOMBIE_SPAWN");
		end
	end

	-- Heal the zombie unit
	pZombieUnit:ChangeDamage(-ZOMBIES_ZOMBIES_KILL_HEAL);
end

function IsTrapGoodyHutType(goodyHutType :number)
	local trapDamageData = GameInfo.GoodyHutSubTypes["TRAP_DAMAGE"];
	if(trapDamageData ~= nil and goodyHutType == trapDamageData.Index) then
		return true;
	end

	return false;
end

-- Is this a goody hut type where damage is dealt to the player?
function IsDamageGoodyHutType(goodyHutType :number)
	-- Is it a prepper trap?
	if(IsTrapGoodyHutType(goodyHutType)) then
		return true;
	end

	local giftDamageData = GameInfo.GoodyHutSubTypes["GIFT_DAMAGE"];
	if(giftDamageData ~= nil and goodyHutType == giftDamageData.Index) then
		return true;
	end
	return false;
end

function Initialize()
	print("Civ Royale Scenario Start Script initializing");		
	Game:SetProperty("DANGER_ZONE_INTERVAL", DANGER_ZONE_INTERVAL);
	Game:SetProperty("DANGER_ZONE_SPEED", DANGER_ZONE_SPEED);
	Game:SetProperty("DANGER_ZONE_DELAY", DANGER_ZONE_DELAY);	

	LuaEvents.NewGameInitialized.Add(InitializeNewGame);
	GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted);
	GameEvents.CivRoyale_GetSafeZone.Add(CivRoyale_GetSafeZone);
	GameEvents.CivRoyale_SmallSafeZone.Add(CivRoyale_SmallSafeZone);
	GameEvents.OnNuclearWeaponDetonated.Add(OnNuclearWeaponDetonated);
	GameEvents.OnWMDCountChanged.Add(OnWMDCountChanged);
	GameEvents.UnitInitialized.Add(OnUnitInitialized);
	GameEvents.UnitCreated.Add(OnUnitCreated);
	GameEvents.OnUnitMoved.Add(OnUnitMoved);
	GameEvents.UnitTriggerGoodyHut.Add(OnUnitTriggerGoodyHut);
	GameEvents.PostUnitPromotionEarned.Add(OnPostUnitPromotionEarned);
	GameEvents.OnCombatOccurred.Add(OnCombatOccurred);
end
print("Starting civ royale scenario script");
Initialize();