----------------------------------------------------------------  
-- Pirates Shared Property Keys and defines
----------------------------------------------------------------  
----------------------------------------------------------------  
-- Property Keys
---------------------------------------------------------------- 
g_CivTypeNames = {
	DreadPirate		= "CIVILIZATION_PIRATES_SCENARIO_DREAD_PIRATE",
	Privateer		= "CIVILIZATION_PIRATES_SCENARIO_PRIVATEER",
	Swashbuckler	= "CIVILIZATION_PIRATES_SCENARIO_SWASHBUCKLER",
	Hoarder			= "CIVILIZATION_PIRATES_SCENARIO_HOARDER",
	Spain			= "CIVILIZATION_PIRATES_SCENARIO_SPAIN",
	England			= "CIVILIZATION_PIRATES_SCENARIO_ENGLAND",
	Netherlands		= "CIVILIZATION_PIRATES_SCENARIO_NETHERLANDS",
	France			= "CIVILIZATION_PIRATES_SCENARIO_FRANCE",
};

g_gamePropertyKeys = {
	TreasureFleetPlotIndex			= "TreasureFleetPlotIndex",		-- Plot Index for treasure fleet exit hex.  Treasure fleets head to this location to exit the map towards Europe.
	NextTreasureFleetTurn			= "NextTreasureFleetTurn",		-- The turn on which the next treasure fleet will be created.
	NextTreasureFleetID				= "NextTreasureFleetID",		-- The ID for the next treasure fleet.
	InfamousPirateSearchZones		= "InfamousPirateSearchZones",	-- Table of infamous pirate search zones. The data is shared because the infamous pirate information is global knowledge.
	NextInfamousPirateZoneID		= "NextInfamousPirateZoneID",	-- The ZoneID for the next search zone to be added to InfamousPirateSearchZones.
	TreasureFleetPaths				= "TreasureFleetPaths"			-- Table of cached pathfinding data for treasure fleets used to update the treasure fleet path tagging.
}

-- Player Dynamic Property Keys 
g_playerPropertyKeys = {
	LastHadGoldTurn					= "LastHadGoldTurn",			-- The last turn the player had a positive gold reserve.
	TreasureMaps					= "TreasureMaps",				-- Treasure Map data.
	LastExploredHexes				= "LastExploredHexes",			-- Used by the Hoarder Pirate King to track how many hexes they have revealed.
	PrivateerPatron					= "PrivateerPatron",			-- The playerId of a Privateer's colonial patron.
	TavernsVisited					= "TavernsVisited",				-- The number of unique taverns this player has visited.
}

-- Unit Dynamic Property Keys
g_unitPropertyKeys = {
	KillInfamyPoints				= "KillInfamyPoints",		-- Infamy points that get rewarded to the pirate player kills this unit.
	Crew							= "Crew",					-- Number of crew currently on ship.
	MaxHitPoints					= "MaxHitPoints",			-- Maximum number of hit points for a given unit.  Note: This is defined internally by GameCore.  Do not change the key name.
	TreasureFleetGoldShip			= "TreasureFleetGoldShip",	-- Is this a gold ship for a treasure fleet?
	TreasureFleetGuardShip			= "TreasureFleetGuardShip",	-- Is this a guard ship for a treasure fleet?
	TreasureFleetID					= "TreasureFleetID",			-- The ID of the treasure fleet this unit is a member of.
	ExtraMovement					= "ExtraMovement",			-- Used to cache extra or reduced movement to the next game turn.
	LastDreadPirateActive			= "LastDreadPirateActive",	-- Last turn the Dread Pirate unit ability was used.
	LastPrivateerActive				= "LastPrivateerActive",	-- Last turn the Privateer unit ability was used.
	LastSwashbuckerActive			= "LastSwashbuckerActive",	-- Last turn the Swashbuckler unit ability was used.
	LastHoarderActive				= "LastHoarderActive",		-- Last turn the Hoarder unit ability was used.
	LastChainShotHit				= "LastChainShotHit",		-- Last turn this unit was hit by the chain shot ability.
	CapturePlayerID					= "CapturePlayerID",		-- If set, indicates the playerID of the player that captured this unit (before it gets deleted)
	CaptureUnitID					= "CaptureUnitID",			-- If set, indicates the unitID of the unit that captured this unit (before it gets deleted)
}

-- Plot Dynamic Property Keys
g_plotPropertyKeys = {
	TreasureOwnerName				= "TreasureOwnerName",		-- Player name of the owner of the treasure on this plot. Only applies to randomly generated treasure plots.
	TreasureFleetPath				= "TreasureFleetPath",		-- Is this plot a part of an existing treasure fleet path?
}

-- City Dynamic Property Keys (not keyed to specific players)
g_cityPropertyKeys = {
	NextTradeRouteTurn		= "NextTradeRouteTurn",				-- The turn at which the next trade route (if possible) should spawn for this city.
	LastSackedTurn			= "LastSackedTurn",					-- The turn at which the city was last sacked.
};

-- city Property Keys data for specific players. 
-- NOTE: Use GetPlayerSpecificPropKey to get actual player specific key.
g_cityPlayerSpecificKeys = {
	LastTavernTurn					= "LastTavernTurn",		-- The last game turn on which this player visited the tavern in this city.
}

g_NotificationsData = {
	NewBuriedTreasure		= { Type = NotificationTypes.USER_DEFINED_1,	Message = "LOC_NOTIFICATION_NEW_BURIED_TREASURE_MESSAGE",		Summary = "LOC_NOTIFICATION_NEW_BURIED_TREASURE_SUMMARY" },
	BuriedTreasureLocated	= { Type = NotificationTypes.USER_DEFINED_2,	Message = "LOC_NOTIFICATION_TREASURE_LOCATED_MESSAGE",			Summary = "LOC_NOTIFICATION_TREASURE_LOCATED_SUMMARY" },
	NewInfamousPirate		= { Type = NotificationTypes.USER_DEFINED_3,	Message = "LOC_NOTIFICATION_NEW_INFAMOUS_PIRATE_MESSAGE",		Summary = "LOC_NOTIFICATION_NEW_INFAMOUS_PIRATE_SUMMARY" },
	NewTreasureFleet		= { Type = NotificationTypes.USER_DEFINED_4,	Message = "LOC_NOTIFICATION_NEW_TREASURE_FLEET_MESSAGE",		Summary = "LOC_NOTIFICATION_NEW_TREASURE_FLEET_SUMMARY" },		
	BuriedTreasurePillaged	= { Type = NotificationTypes.USER_DEFINED_5,	Message = "LOC_NOTIFICATION_TREASURE_MAP_PILLAGED_MESSAGE",		Summary = "LOC_NOTIFICATION_TREASURE_MAP_PILLAGED_SUMMARY" },
	LetterofMarque			= { Type = NotificationTypes.USER_DEFINED_6,	Message = "LOC_NOTIFICATION_LETTER_OF_MARQUE_MESSAGE",			Summary = "LOC_NOTIFICATION_LETTER_OF_MARQUE_SUMMARY" },
	InfamousPirateDefeated	= { Type = NotificationTypes.USER_DEFINED_7,	Message = "LOC_NOTIFICATION_INFAMOUS_PIRATE_DEFEATED_MESSAGE",	Summary = "LOC_NOTIFICATION_INFAMOUS_PIRATE_DEFEATED_SUMMARY" },
	YourTreasurePlundered	= { Type = NotificationTypes.USER_DEFINED_8,	Message = "LOC_NOTIFICATION_YOUR_TREASURE_PILLAGED_MESSAGE",	Summary = "LOC_NOTIFICATION_YOUR_TREASURE_PILLAGED_SUMMARY" },
};

-- Notification Dynamic Properties.
g_notificationKeys = {
	TreasurePlotIndex		= "TreasurePlotIndex",		-- Plot index of the actual treasure location for BuriedTreasureLocated notifications.
	InfamousPirateID		= "InfamousPirateID",		-- unit index of the Infamous Pirate unit associated with the notification.
														-- NOTE: This uses the index number directly so the notification system can compare values when deciding to dismiss notifications for dead infamous pirates.
	InfamousSearchZoneID	= "InfamousSearchZoneID",	-- The infamous search zone index for the search zone associated with an New Infamous Pirate notification. Indexes into g_gamePropertyKeys.InfamousPirateSearchZones.
};

g_unitCommandSubTypeNames = {
	VISIT_TAVERN		= "VISIT_TAVERN",	
	CAREENING			= "CAREENING",	
	CAPTURE_BOAT		= "CAPTURE_BOAT",
	SHORE_PARTY			= "SHORE_PARTY",
	SHORE_PARTY_EMBARK	= "SHORE_PARTY_EMBARK" ,
	BURY_TREASURE		= "BURY_TREASURE",
	DREAD_PIRATE_ACTIVE	= "DREAD_PIRATE_ACTIVE",
	PRIVATEER_ACTIVE	= "PRIVATEER_ACTIVE",
	SWASHBUCKLER_ACTIVE	= "SWASHBUCKLER_ACTIVE",
	HOARDER_ACTIVE		= "HOARDER_ACTIVE",
};


----------------------------------------------------------------  
-- Unit Action Defines
---------------------------------------------------------------- 
BURY_TREASURE_IMPROVEMENT			= "IMPROVEMENT_BURIED_TREASURE";
BURY_TREASURE_SCORE					= 30;		-- Treasure Score awarded for performing the buried treasure unit action.
BURY_TREASURE_GOLD_COST				= 600;		-- Gold required for bury treasure unit action.
BURY_TREASURE_PILLAGE_GOLD			= 200;		-- Gold players get from pillaging a buried treasure.

DREAD_PIRATE_ACTIVE_DEBOUNCE		= 0;		
DREAD_PIRATE_ACTIVE_DURATION		= 5;	

PRIVATEER_ACTIVE_DEBOUNCE			= 5;		
PRIVATEER_ACTIVE_DURATION			= 0;	

SWASHBUCKLER_ACTIVE_DEBOUNCE		= 6;		
SWASHBUCKLER_ACTIVE_DURATION		= 2;	

HOARDER_ACTIVE_DEBOUNCE				= 5;		
HOARDER_ACTIVE_DURATION				= 0;	
HOARDER_ACTIVE_RANGE				= 3;
HOARDER_ACTIVE_LOCK_DURATION		= 1;		-- How many turns does the chain shot lock effect last?


----------------------------------------------------------------  
-- Quest Defines
---------------------------------------------------------------- 
TREASURE_MAP_NEW_TREASURE_CHANCE	= 50;		-- Precent chance that a treasure map points to a new treasure.
TREASURE_MAP_FLOATING				= 75;		-- Percent chance that a new randomly generated treasure will be floating in the water.


----------------------------------------------------------------  
-- Pirate King Defines
----------------------------------------------------------------
DREAD_PIRATE_PASSIVE_COMBAT_GOLD	= 10;		-- The amount of gold Dread Pirates get from combat.

SWASHBUCKLER_HEX_EXPLORED_DELTA		= 50;		-- How many hexes must the Swashbuckler explore before getting score?
SWASHBUCKLER_HEX_EXPLORED_POINTS	= 1;		-- How many Infamous Pirate Points does the Swashbuckler get for exploring SWASHBUCKLER_HEX_EXPLORED_DELTA hexes?

PRIVATEER_PLUNDER_TRADE_ROUTE_BONUS = 100;		-- How much additional gold does the Privateer get for plundering trade routes?
PRIVATEER_ACTIVE_GOLD_BONUS			= 100;		-- How much additional gold does the Privateer capturing units for their patron?

HOARDER_BURY_TREASURE_BONUS			= 10;		-- How many additional Treasure Points do hoarders get for burying treasure?


----------------------------------------------------------------  
-- Relic Defines
----------------------------------------------------------------
-- Pirate Relic Drop Chances
RELIC_DROP_VISIT_TAVERN				= 25;		-- Percent chance of relic dropping on visit tavern action.
RELIC_DROP_PILLAGE_TREASURE			= 75;		-- Percent chance of relic dropping when pillaging a treasure chest.
RELIC_DROP_TREASURE_GOLD_SHIP		= 100;		-- Percent chance of relic dropping when sinking a treasure fleet's gold ship.

-- Relic Specific Defines
RELIC_KIDD_JOURNAL_MAP_CHANCE		= 50;		-- Percent chance of Captain Kidd Journal relic dropping an additional treasure map when visiting a tavern.
RELIC_BLACKBEARD_FUSE_MOVE_DAMAGE	= -2;		-- The amount of movement deduced from an attack from a naval ship under the effect of Blackbeard's Short Fuse.
RELIC_JOLLY_ROGERS_TRADE_ROUTE_GOLD = 50;		-- The amount of gold that the Jolly Rogers relic gives for plundering trade routes.
RELIC_DOWSING_ROD_RANGE				= 20;		-- Max range of the Dowsing Rod's treasure sense.
RELIC_ENGLISH_POINTER_RANGE			= 20;		-- Max range of the English Pointer's unseeen ship sense.


----------------------------------------------------------------  
-- Infamous Pirate Defines
----------------------------------------------------------------
INFAMOUS_PIRATES_PLAYERID					= 63;	-- Using barbarians.
INFAMOUS_PIRATES_MIN_PLAYER_UNIT_DISTANCE	= 5;	-- [Hex Distance] The minimum distance a infamous pirate must spawn from pirate players.  This is ignored if this condition can't be met.
INFAMOUS_PIRATE_SEARCH_ZONE_SIZE			= 2;	-- [Hex Distance] The size of the infamous pirate search zone. 

g_InfamousPirates = {
	{Name="LOC_PIRATE_HENRY_MORGAN",	UnitType="UNIT_BRIGANTINE",	KillInfamyPoints=50,	MaxHitPoints=300},
	{Name="LOC_PIRATE_BLACKBEARD",		UnitType="UNIT_GALLEON",	KillInfamyPoints=40,	MaxHitPoints=300},
	{Name="LOC_PIRATE_CAPTAIN_KIDD",	UnitType="UNIT_SLOOP",		KillInfamyPoints=30,	MaxHitPoints=275},
	{Name="LOC_PIRATE_JEAN_LAFITTE",	UnitType="UNIT_SLOOP",		KillInfamyPoints=30,	MaxHitPoints=275},
	{Name="LOC_PIRATE_STEDE_BONNET",	UnitType="UNIT_SLOOP",		KillInfamyPoints=30,	MaxHitPoints=250},
	{Name="LOC_PIRATE_LOLONNAIS",		UnitType="UNIT_SLOOP",		KillInfamyPoints=30,	MaxHitPoints=225},
	{Name="LOC_PIRATE_ROC_BRASILIANO",	UnitType="UNIT_SLOOP",		KillInfamyPoints=20,	MaxHitPoints=200},
	{Name="LOC_PIRATE_BART_ROBERTS",	UnitType="UNIT_SLOOP",		KillInfamyPoints=20,	MaxHitPoints=175},
	{Name="LOC_PIRATE_JACK_RACKHAM",	UnitType="UNIT_SLOOP",		KillInfamyPoints=20,	MaxHitPoints=150},
};


----------------------------------------------------------------  
-- Misc Defines
---------------------------------------------------------------- 
PIRATE_TREASURE_MIN_DIST_UNITS		= 10;		-- [Hex Distance] The minimum distance a buried treasure should be from the pirate's units.  This is ignored if this condition can't be met.
PIRATE_TREASURE_MAX_DIST_UNITS		= 15;		-- [Hex Distance] The maximum distance a buried treasure must be from the pirate's units.   This is ignored if this condition can't be met.
PIRATE_TREASURE_SEARCH_ZONE_SIZE	= 2;		-- [Hex Distance] The size of the treasure search zone.
PIRATE_BANKRUPTCY_MUTINY_DELAY		= 2;		-- How many turns of zero gold before crews start mutinying?

INFAMY_PIRATE_KILL_COLONY_UNIT		= 5;		-- The amount of Infamy gained by a pirate for killing colonial powers' units.
INFAMY_PIRATE_KILL_PIRATE_UNIT		= 10;		-- The amount of Infamy gained by a pirate killing pirate players' units.
INFAMY_PIRATE_KILL_BARB_UNIT		= 5;		-- The amount of Infamy gained by a pirate killing a barb unit.
INFAMY_PIRATE_COMBAT_SURVIVED		= 1;		-- The amount of Infamy gained by a pirate surviving combat without either unit getting killed.
INFAMY_GOODY_HUT					= 5;		-- The amount of Infamy gained by a pirate popping a goody hut.
INFAMY_CITY_SACKED					= 15;		-- The amount of Infamous Pirate Points gained by sacking a city.

FLAGSHIP_CREW						= 1;		-- Initial crew tokens for flagship.
FLAGSHIP_HITPOINTS					= 300;		
FLAGSHIP_ABILITY_NAME				="ABILITY_FLAGSHIP";	-- String name of unit ability that indicates a flagship.
FLAGSHIP_SPAWN_MIN_DISTANCE			= 10;		-- Try to spawn Pirate Players' Flagships at least this many hexes apart. This will be ignored if there is not enough space on the map.

-- Infamous Pirate Points
IPP_CLEAR_BARB_CAMP					= 5;		-- The amount of IPP gained by a pirate clearing a barb camp.
IPP_PRIVATEER_ACTIVE				= 5;		-- The amount of IPP gained for the privateer using the Bring Her Home unit ability.

COLONIES_MIN_DIST_UNITS				= 8;		-- [Hex Distance] The minimum distance a colony city must be from major civs' starting units.
COLONIES_WAR_CHANCE					= 5;		-- [0-100] percent chance per-turn an individual colony will declare war on another colony.
COLONIES_PEACE_CHANCE				= 25;		-- [0-100] percent chance per-turn an individual colony will make peace with another warring colony.

CAREENING_HEAL						= 100;		-- How much damage does Careening heal? (This is prorated based on the amount of movement points remaining in the turn).

CAPTURE_BOAT_DAMAGE_MIN				= 50;		-- Minimum unit damage required before boat can be captured.
CAPTURE_BOAT_CREW_COST				= 1;		-- Amount of crew required for capture boat unit action.

SHORE_PARTY_CREW_COST				= 1;		-- Amount of crew required for shore party unit action.
SHORE_PARTY_MOVE_COST				= 1;		-- Movement points required to deploy a shore party.

SHORE_PARTY_EMBARK_MOVE_COST		= 1;		-- How many movement points are required to embark a shore party back to a ship?

VISIT_TAVERN_DURATION				= 0;		-- How many turns does the visit tavern action take?
VISIT_TAVERN_DEBOUNCE				= 10;		-- Number of turns required between tavern visits in the same city.

REVEAL_CITY_RANGE					= 3;		-- The hex distance from city center that will be revealed when RevealNearestPort() is used.

GOLD_TREASURE_FLEET_GOLD_BOAT_SUNK	= 300;		-- The amount of gold received from sinking a treasure fleet gold boat.
GOLD_CITY_SACKED					= 500;		-- The amount of gold received for sacking a city.

TREASURE_FLEET_MIN_TURNS			= 5;		-- Min number of turns between starting new treasure fleets.
TREASURE_FLEET_MAX_TURNS			= 10;		-- Max number of turns between starting new treasure fleets.
TREASURE_FLEET_GOLD_BOATS			= 2;		-- Number of gold ships per treasure fleet.
TREASURE_FLEET_GUARD_BOATS			= 3;		-- Number of guard ships (brigs) per treasure fleet.

TREASURE_POINTS_TREASURE_GOLD_BOAT	= 20;		-- Treasure Points rewarded for sinking a treasure fleet gold ship.
TREASURE_POINTS_PLUNDER_TREASURE	= 5;		-- Treasure Points rewarded for plundering a treasure chest.
TREASURE_POINTS_PLUNDER_IMPROVE		= 1;		-- Treasure Points rewarded for plundering improvements.
TREASURE_POINTS_PLUNDER_DISTRICT	= 2;		-- Treasure Points rewarded for plundering a city building or district.

CITY_SACKED_DEBOUNCE				= 10;		-- Debounce for granting rewards when sacking a city.

-- Interface Mode Defines
INTERFACEMODE_CAPTURE_BOAT			= DB.MakeHash("INTERFACEMODE_CAPTURE_BOAT");
INTERFACEMODE_SHORE_PARTY			= DB.MakeHash("INTERFACEMODE_SHORE_PARTY");
INTERFACEMODE_SHORE_PARTY_EMBARK	= DB.MakeHash("INTERFACEMODE_SHORE_PARTY_EMBARK");
INTERFACEMODE_DREAD_PIRATE_ACTIVE	= DB.MakeHash("INTERFACEMODE_DREAD_PIRATE_ACTIVE");
INTERFACEMODE_PRIVATEER_ACTIVE		= DB.MakeHash("INTERFACEMODE_PRIVATEER_ACTIVE");
INTERFACEMODE_HOARDER_ACTIVE		= DB.MakeHash("INTERFACEMODE_HOARDER_ACTIVE");

CITY_TRADE_ROUTE_MIN_TURNS = 3;
CITY_TRADE_ROUTE_MAX_TURNS = 8;

g_scoreTypes = {
	Treasure		= {Name = "Treasure", WorldText = "LOC_SCORE_CATEGORY_TREASURE_WORLDTEXT"},
	InfamousPirate	= {Name = "Infamous Pirate", WorldText = "LOC_SCORE_CATEGORY_INFAMOUS_PIRATES_WORLDTEXT"},
	Fighting		= {Name = "Fighting", WorldText = "LOC_SCORE_CATEGORY_FIGHTING_WORLDTEXT"},
}


----------------------------------------------------------------  
-- Helper Functions
---------------------------------------------------------------- 
function IsColonyPlayer(iPlayerID :number)
	local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
	if (pPlayerConfig ~= nil) then
		local civName :string = pPlayerConfig:GetCivilizationTypeName();
		if(civName == g_CivTypeNames.Spain 
			or civName == g_CivTypeNames.England
			or civName == g_CivTypeNames.Netherlands
			or civName == g_CivTypeNames.France) then
			return true;
		end
	end 
	return false;
end

function IsPiratePlayer(iPlayerID :number)
	local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
	if (pPlayerConfig ~= nil) then
		local civName :string = pPlayerConfig:GetCivilizationTypeName();
		if(civName == g_CivTypeNames.DreadPirate or civName == g_CivTypeNames.Privateer or civName == g_CivTypeNames.Swashbuckler or civName == g_CivTypeNames.Hoarder) then
			return true;
		end
	end 
	return false;
end

function GetPlayerSpecificPropKey(key :string, iPlayerID :number)
	return key .. "_" .. tostring(iPlayerID);
end


