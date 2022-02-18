----------------------------
-- Civ 6 Enumerated Types --
----------------------------
--
-- PLOT_TYPE
--
-- Civ 4 and 5 had separate types for Plots (water, hills, land, mountain) and Terrain (grassland, plains, tundra).  But once map generation was complete and the game
-- commenced there was no longer a need for the distinction between the two.  For Civ 6 we are going to still generate the map in these two passes.  However inside the
-- game we will store the data as a single type (Terrain).  We therefore need a new intermediate data type (PLOT_TYPE) just for map generation.  This data is stored using
-- the enumeration below

-- These are internal to the map generator code, it is ok they are hard-coded.
g_PLOT_TYPE_NONE		= -1;
g_PLOT_TYPE_MOUNTAIN	= 0;
g_PLOT_TYPE_HILLS		= 1;
g_PLOT_TYPE_LAND		= 2;
g_PLOT_TYPE_OCEAN		= 3;

-- These come from the database.  Get the runtime index values.
g_TERRAIN_TYPE_NONE					= -1;
g_TERRAIN_TYPE_GRASS				= GameInfo.Terrains["TERRAIN_GRASS"].Index;
g_TERRAIN_TYPE_GRASS_HILLS			= GameInfo.Terrains["TERRAIN_GRASS_HILLS"].Index;
g_TERRAIN_TYPE_GRASS_MOUNTAIN		= GameInfo.Terrains["TERRAIN_GRASS_MOUNTAIN"].Index;
g_TERRAIN_TYPE_PLAINS				= GameInfo.Terrains["TERRAIN_PLAINS"].Index;
g_TERRAIN_TYPE_PLAINS_HILLS			= GameInfo.Terrains["TERRAIN_PLAINS_HILLS"].Index;
g_TERRAIN_TYPE_PLAINS_MOUNTAIN		= GameInfo.Terrains["TERRAIN_PLAINS_MOUNTAIN"].Index;
g_TERRAIN_TYPE_DESERT				= GameInfo.Terrains["TERRAIN_DESERT"].Index;
g_TERRAIN_TYPE_DESERT_HILLS			= GameInfo.Terrains["TERRAIN_DESERT_HILLS"].Index;
g_TERRAIN_TYPE_DESERT_MOUNTAIN		= GameInfo.Terrains["TERRAIN_DESERT_MOUNTAIN"].Index;
g_TERRAIN_TYPE_TUNDRA				= GameInfo.Terrains["TERRAIN_TUNDRA"].Index;
g_TERRAIN_TYPE_TUNDRA_HILLS			= GameInfo.Terrains["TERRAIN_TUNDRA_HILLS"].Index;
g_TERRAIN_TYPE_TUNDRA_MOUNTAIN		= GameInfo.Terrains["TERRAIN_TUNDRA_MOUNTAIN"].Index;
g_TERRAIN_TYPE_SNOW					= GameInfo.Terrains["TERRAIN_SNOW"].Index;
g_TERRAIN_TYPE_SNOW_HILLS			= GameInfo.Terrains["TERRAIN_SNOW_HILLS"].Index;
g_TERRAIN_TYPE_SNOW_MOUNTAIN		= GameInfo.Terrains["TERRAIN_SNOW_MOUNTAIN"].Index;
g_TERRAIN_TYPE_COAST				= GameInfo.Terrains["TERRAIN_COAST"].Index;
g_TERRAIN_TYPE_OCEAN				= GameInfo.Terrains["TERRAIN_OCEAN"].Index;

-- We are stil going to make an assumption about the ordering if the TerrainTypes, relative to the 'base' type.  
-- This may change, probably to a lookup table to avoid database ordering dependencies.
g_TERRAIN_BASE_TO_HILLS_DELTA		= 1;
g_TERRAIN_BASE_TO_MOUNTAIN_DELTA	= 2;

g_FEATURE_NONE						= -1;
g_FEATURE_FLOODPLAINS				= GameInfo.Features["FEATURE_FLOODPLAINS"].Index;
g_FEATURE_ICE						= GameInfo.Features["FEATURE_ICE"].Index;
g_FEATURE_JUNGLE					= GameInfo.Features["FEATURE_JUNGLE"].Index;
g_FEATURE_FOREST					= GameInfo.Features["FEATURE_FOREST"].Index;
g_FEATURE_OASIS						= GameInfo.Features["FEATURE_OASIS"].Index;
g_FEATURE_MARSH						= GameInfo.Features["FEATURE_MARSH"].Index;

g_FEATURE_BARRIER_REEF				= GameInfo.Features["FEATURE_BARRIER_REEF"].Index;
g_FEATURE_CLIFFS_DOVER				= GameInfo.Features["FEATURE_CLIFFS_DOVER"].Index;
g_FEATURE_CRATER_LAKE				= GameInfo.Features["FEATURE_CRATER_LAKE"].Index;
g_FEATURE_DEAD_SEA					= GameInfo.Features["FEATURE_DEAD_SEA"].Index;
g_FEATURE_EVEREST					= GameInfo.Features["FEATURE_EVEREST"].Index;
g_FEATURE_GALAPAGOS					= GameInfo.Features["FEATURE_GALAPAGOS"].Index;
g_FEATURE_KILIMANJARO				= GameInfo.Features["FEATURE_KILIMANJARO"].Index;
g_FEATURE_PANTANAL					= GameInfo.Features["FEATURE_PANTANAL"].Index;
g_FEATURE_PIOPIOTAHI				= GameInfo.Features["FEATURE_PIOPIOTAHI"].Index;
g_FEATURE_TORRES_DEL_PAINE			= GameInfo.Features["FEATURE_TORRES_DEL_PAINE"].Index;
g_FEATURE_TSINGY					= GameInfo.Features["FEATURE_TSINGY"].Index;
g_FEATURE_YOSEMITE					= GameInfo.Features["FEATURE_YOSEMITE"].Index;

g_YIELD_FOOD						= GameInfo.Yields["YIELD_FOOD"].Index;
g_YIELD_PRODUCTION					= GameInfo.Yields["YIELD_PRODUCTION"].Index;
g_YIELD_GOLD						= GameInfo.Yields["YIELD_GOLD"].Index;
g_YIELD_SCIENCE						= GameInfo.Yields["YIELD_SCIENCE"].Index;
g_YIELD_CULTURE						= GameInfo.Yields["YIELD_CULTURE"].Index;
g_YIELD_FAITH						= GameInfo.Yields["YIELD_FAITH"].Index;

DirectionTypes = {
		DIRECTION_NORTHEAST = 0,
		DIRECTION_EAST = 1,
		DIRECTION_SOUTHEAST = 2,
		DIRECTION_SOUTHWEST = 3,
		DIRECTION_WEST= 4,
		DIRECTION_NORTHWEST = 5,
		NUM_DIRECTION_TYPES = 6,
};

