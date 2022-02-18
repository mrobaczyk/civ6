----------------------------------------------------------------  
-- CivRoyale Shared Property Keys and defines
----------------------------------------------------------------  

----------------------------------------------------------------  
-- Additional Data Property Keys
---------------------------------------------------------------- 
g_CivTypeNames = {
	Aliens						= "CIVILIZATION_CIVROYALE_SCENARIO_ALIENS",
	Cultists					= "CIVILIZATION_CIVROYALE_SCENARIO_CULTISTS",
	EdgeLords					= "CIVILIZATION_CIVROYALE_SCENARIO_EDGELORDS",
	Jocks						= "CIVILIZATION_CIVROYALE_SCENARIO_JOCKS",
	Mutants						= "CIVILIZATION_CIVROYALE_SCENARIO_MUTANTS",
	MadScientists				= "CIVILIZATION_CIVROYALE_SCENARIO_SCIENTISTS",
	Pirates						= "CIVILIZATION_CIVROYALE_SCENARIO_PIRATES",	
	Preppers					= "CIVILIZATION_CIVROYALE_SCENARIO_PREPPERS",
	Wanderers					= "CIVILIZATION_CIVROYALE_SCENARIO_WANDERERS",	
	Zombies						= "CIVILIZATION_CIVROYALE_SCENARIO_ZOMBIES",
};

g_plotStateKeys = {
	SafeZoneRing				= "SafeZoneRing",
	EdgeLordZone				= "EdgeLordZone",			-- Defines plots where EdgeLords get a combat bonus.	
	DamageDelayTime				= "DELAYED_DAMAGE_TURN",	-- (Defined by GameCore) Used for blocking initial fallout damage for plots hit by nukes.
	MutantDropped				= "MutantDropped",			-- Fallout on this plot was dropped by a mutant unit.
	DeferredGiftOwner			= "DeferredGiftOwner",		-- Owner of the deferred Grieving Gift on this hex.
};

g_unitStateKeys = {
	RadiationCharges			= "RadiationCharges",		-- The number of radiation charges held on the current unit.  Used by mutants for their special radiation cloud ability.
	RadiationSpread				= "RadiationSpread",		-- Should this mutant unit spread radiation?  (Defaults to true if not set)
	ShieldTime					= "ShieldTime",				-- The last turn the Mad Scientist unit ability was triggered.
	CloakTime					= "CloakTime",				-- The last turn the Alien Cloak unit ability was triggered.
	UncloakAttackTime			= "UncloakAttackTime",		-- The last turn an Alien unit uncloaked due to attacking.
};

-- Player Dynamic Property Keys 
g_playerPropertyKeys = {
	RoadVisionTurn					= "RoadVisionTurn",
	RoadVisionActive				= "RoadVisionActive",
	TreasurePlotIndex				= "TreasurePlotIndex",
	BurnTreasureTurn				= "BurnTreasureTurn",		-- Last time the pirate player burned a treasure map.
	HailMaryTurn					= "HailMaryTurn",
	ImprovisedTrapCount				= "ImprovisedTrapCount",
	GrievingGiftCount				= "GrievingGiftCount",		-- Current number of Grieving Gifts available
	GrievingGiftTurn				= "GrievingGiftTurn",		-- Last time player started recharging the Grieving Gift ability. nil == not currently recharging.
};

-- Plot Property keys data for specific players.
-- NOTE: Use GetPlayerSpecificPropKey to get actual player specific key.
g_plotPlayerSpecificKeys = {
	RoadVisionActive				= "RoadVisionActive",
}

-- Game Property Keys
g_ObjectStateKeys = {
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

g_NotificationsData = {
	SupplyDrop			= { Type = NotificationTypes.USER_DEFINED_1,	Message = "LOC_CIVROYALE_NOTIFICATION_SUPPLY_DROP_MESSAGE", 		Summary = "LOC_CIVROYALE_NOTIFICATION_SUPPLY_DROP_SUMMARY" },
	SafeZoneChanged		= { Type = NotificationTypes.USER_DEFINED_2,	Message = "LOC_CIVROYALE_NOTIFICATION_SAFE_ZONE_CHANGED_MESSAGE", 	Summary = "LOC_CIVROYALE_NOTIFICATION_SAFE_ZONE_CHANGED_SUMMARY" },
	SafeZoneAppeared	= { Type = NotificationTypes.USER_DEFINED_3,	Message = "LOC_CIVROYALE_NOTIFICATION_SAFE_ZONE_APPEARED_MESSAGE", 	Summary = "LOC_CIVROYALE_NOTIFICATION_SAFE_ZONE_APPEARED_SUMMARY" },
	NewBuriedTreasure	= { Type = NotificationTypes.USER_DEFINED_4,	Message = "LOC_CIVROYALE_NOTIFICATION_NEW_TREASURE_MAP_MESSAGE", 	Summary = "LOC_CIVROYALE_NOTIFICATION_NEW_TREASURE_MAP_SUMMARY" },
	HailMaryReady		= { Type = NotificationTypes.USER_DEFINED_5,	Message = "LOC_CIVROYALE_NOTIFICATION_HAIL_MARY_READY_MESSAGE", 	Summary = "LOC_CIVROYALE_NOTIFICATION_HAIL_MARY_READY_SUMMARY" },	
	ZombieDecayDeath	= { Type = NotificationTypes.USER_DEFINED_6,	Message = "LOC_CIVROYALE_NOTIFICATION_ZOMBIE_DECAYED_MESSAGE", 		Summary = "LOC_CIVROYALE_NOTIFICATION_ZOMBIE_DECAYED_SUMMARY" },	
};


----------------------------------------------------------------  
-- Defines
---------------------------------------------------------------- 
ALIEN_CLOAK_DURATION				= 6;		-- How many turns does the Alien unit cloak last?
ALIEN_CLOAK_DEBOUNCE				= 6;		-- How many turns does the Alien unit cloak take to recharge?

EDGELORDS_GRIEVING_GIFT_START_COUNT	= 2;		-- How many traps do EdgeLords start the game with?
EDGELORDS_GRIEVING_GIFT_MAX_COUNT	= 2;		-- Max number of gifts an EdgeLord can stored up, ready to deploy.
EDGELORDS_GRIEVING_GIFT_DEBOUNCE	= 5;		-- How many turns before an EdgeLord gets another Grieving Gift?
EDGELORDS_GRIEVING_GIFT_REGEN_RATE	= 2;		-- How many Grieving Gifts recharge per EDGELORDS_GRIEVING_GIFT_DEBOUNCE?
EDGELORDS_GRIEVING_GIFT_IMPROVEMENT = "IMPROVEMENT_GRIEVING_GIFT";

MAD_SCIENTIST_SHIELD_DURATION		= 4;		-- How many turns does the Mad Scientist unit shield last?
MAD_SCIENTIST_SHIELD_DEBOUNCE		= 6;		-- How many turns does the Mad Scientist unit shield take to recharge?

PREPPER_TRAP_IMPROVEMENT			= "IMPROVEMENT_IMPROVISED_TRAP";
PREPPER_TRAP_START_COUNT			= 5;		-- How many traps do preppers start the game with?
PREPPER_TRAP_PER_GOODY_HUT			= 5;		-- How many traps do preppers get from popping goody huts?

PIRATES_BURN_TREASURE_MAP_DEBOUNCE	= 5;		-- How many turns does it take for the Burn Treasure Map ability to recharge?
PIRATE_TREASURE_MIN_DIST_UNITS		= 10;		-- [Hex Distance] The minimum distance a buried treasure should be from the pirate's units.  This is ignored if this condition can't be met.
PIRATE_TREASURE_MAX_DIST_UNITS		= 15;		-- [Hex Distance] The maximum distance a buried treasure must be from the pirate's units.   This is ignored if this condition can't be met.

WANDERER_ROAD_VISION_DURATION		= 1;
WANDERER_ROAD_VISION_DEBOUNCE		= 3;

JOCKS_HAIL_MARY_WMD					= "WMD_HAIL_MARY";			-- Name of WMD type used for the Hail Mary unique ability.
JOCKS_HAIL_MARY_DEBOUNCE			= 6;						-- How many turns does it take for the Jocks take to recharge their hail mary nuke ability?

ZOMBIES_ZOMBIE_COMBAT_UNIT			= "UNIT_WARRIOR";
ZOMBIES_ADDITIONAL_START_ZOMBIES	= 1;		-- How many additional Zombie Hordes should be spawned for a zombie player? (Does not count standard starting units that will also be converted to zombie hordes)
ZOMBIES_ZOMBIES_PER_COMBAT_DEATH	= 1;		-- How many Zombie Hordes are spawned when a zombie player kills a unit in combat?
ZOMBIES_ZOMBIES_PER_GOODY_UNIT		= 1;		-- How many Zombie Hordes are spawned from which unit granted from a goody hut?
ZOMBIES_ZOMBIES_KILL_HEAL			= 50;		-- How much damage does a zombie heal when it kills another unit in combat?
ZOMBIES_ZOMBIES_GOODY_HEAL			= 50;		-- How much damage does a zombie heal when pops a goody hut?
ZOMBIE_HORDE_DECAY					= 2;		-- Normal Damage per turn dealt to Zombie Horde units.
ZOMBIE_HORDE_LESS_DECAY				= 0;		-- Damage per turn dealt to Zombie Horde units with Less Decay promotions.

GDR_NUM_PROMOTIONS					= 6;		-- The number of promotions the GDR has.
----------------------------------------------------------------  
-- Helper Functions
---------------------------------------------------------------- 
function GetPlayerSpecificPropKey(key :string, iPlayerID :number)
	return key .. "_" .. tostring(iPlayerID);
end