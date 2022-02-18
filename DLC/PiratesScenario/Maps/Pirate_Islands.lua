------------------------------------------------------------------------------
--	FILE:	 Pirate_Islands.lua
--	PURPOSE: Arrr, there be gold buried in the salty shores of these islands.
------------------------------------------------------------------------------
--	Copyright (c) 2020 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include "MapEnums"
include "MapUtilities"
include "MountainsCliffs"
include "RiversLakes"
include "FeatureGenerator"
include "TerrainGenerator"
include "NaturalWonderGenerator"
include "ResourceGenerator"
include "AssignStartingPlots"

local g_iW, g_iH;
local g_iFlags = {};
local g_continentsFrac = nil;

-------------------------------------------------------------------------------
function GenerateMap()

	print("Generating Pirate Islands Map");
	local pPlot;

	-- Set globals
	g_iW, g_iH = Map.GetGridSize();
	g_iFlags = TerrainBuilder.GetFractalFlags();
	local temperature = MapConfiguration.GetValue("temperature"); -- Default setting is Temperate.
	if temperature == 4 then
		temperature  =  1 + TerrainBuilder.GetRandomNumber(3, "Random Temperature- Lua");
	end
	
	bonus_cold_shift = 20 -- Removes snow and tundra via TerrainGenerator
	
	plotTypes = GeneratePlotTypes();
	terrainTypes = GenerateTerrainTypes(plotTypes, g_iW, g_iH, g_iFlags, false, temperature, false);


	for i = 0, (g_iW * g_iH) - 1, 1 do
		pPlot = Map.GetPlotByIndex(i);
		if (plotTypes[i] == g_PLOT_TYPE_HILLS) then
			terrainTypes[i] = terrainTypes[i] + 1;
		end
		TerrainBuilder.SetTerrainType(pPlot, terrainTypes[i]);
	end
	
	-- Temp
	AreaBuilder.Recalculate();
	local biggest_area = Areas.FindBiggestArea(false);
	print("After Adding Hills: ", biggest_area:GetPlotCount());

	-- River generation is affected by plot types, originating from highlands and preferring to traverse lowlands.
	AddRivers();
	AddFeatures();
	

	AreaBuilder.Recalculate();
	TerrainBuilder.AnalyzeChokepoints();
	TerrainBuilder.StampContinents();

--	for i = 0, (g_iW * g_iH) - 1, 1 do
--		pPlot = Map.GetPlotByIndex(i);
--		print ("i: plotType, terrainType, featureType: " .. tostring(i) .. ": " .. tostring(plotTypes[i]) .. ", " .. tostring(terrainTypes[i]) .. ", " .. tostring(pPlot:GetFeatureType(i)));
--	end

	
	-- START_MIN_Y and START_MAX_Y is the percent of the map ignored for major civs' starting positions.
	local args = {
		MIN_MAJOR_CIV_FERTILITY = 85,
		MIN_MINOR_CIV_FERTILITY = 5, 
		MIN_BARBARIAN_FERTILITY = 1,
		START_MIN_Y = 0,
		START_MAX_Y = 0,
		WATER = true,
		START_CONFIG = startConfig,
	};
	local start_plot_database = AssignStartingPlots.Create(args);

	local GoodyGen = AddGoodies(g_iW, g_iH);
end

-------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Generating Plot Types");
	local plotTypes = {};
	local world_age_new = 3;
	local world_age_normal = 2;
	local world_age_old = 1;

	for x = 0, g_iW - 1 do
		for y = 0, g_iH - 1 do
			local index = (y * g_iW) + x + 1; -- Lua Array starts at 1
			plotTypes[index] = g_PLOT_TYPE_OCEAN;
		end
	end

	
	local water_percent_modifier = 0; 

	--	local sea_level
    local sea_level = MapConfiguration.GetValue("sea_level");
	if sea_level == 1 then -- Low Sea Level
		water_percent_modifier = -4
	elseif sea_level == 2 then -- Normal Sea Level
		water_percent_modifier = 0;
	elseif sea_level == 3 then -- High Sea Level
		water_percent_modifier = 4;
	else
		water_percent_modifier = TerrainBuilder.GetRandomNumber(9, "Random Sea Level - Lua") - 4;
	end

	--	local world_age
	local world_age = MapConfiguration.GetValue("world_age");
	if (world_age == 1) then
		world_age = world_age_new;
	elseif (world_age == 2) then
		world_age = world_age_normal;
	elseif (world_age == 3) then
		world_age = world_age_old;
	else
		world_age = 1 + TerrainBuilder.GetRandomNumber(3, "Random World Age - Lua");
	end






	-- Generate Large Islands		
	local args = {};
	args.iWaterPercent = 85;
	args.iRegionWidth = math.ceil(8*g_iW/9);
	args.iRegionHeight = math.ceil(g_iH);
	args.iRegionWestX = math.floor(g_iW/9);
	args.iRegionSouthY = math.floor(0);
	args.iRegionGrain = 3;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = g_iFlags;
	args.iRegionFracXExp = 7;
	args.iRegionFracYExp = 6;
	plotTypes = GenerateFractalLayerWithoutHills(args, plotTypes);
	

	-- Generate Tiny Islands by laying over just a bit more land
	local args = {};
	args.iWaterPercent = 95;
	args.iRegionWidth = math.ceil(8*g_iW/9);
	args.iRegionHeight = math.ceil(g_iH);
	args.iRegionWestX = math.floor(g_iW/9);
	args.iRegionSouthY = math.floor(0);
	args.iRegionGrain = 4;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = g_iFlags;
	args.iRegionFracXExp = 7;
	args.iRegionFracYExp = 6;
    plotTypes = GenerateFractalLayerWithoutHills(args, plotTypes);

	


	-- Cut into this by adding some bays and other water cutouts
	local args = {};
	args.iWaterPercent = 98;
	args.iRegionWidth = math.ceil(g_iW);
	args.iRegionHeight = math.ceil(g_iH);
	args.iRegionWestX = math.floor(g_iW/9);
	args.iRegionSouthY = math.floor(0);
	args.iRegionGrain = 4;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = g_iFlags;
	args.iRegionFracXExp = 7;
	args.iRegionFracYExp = 6;
	args.iRiftGrain = -1;
	plotTypes = GenerateWaterLayer(args, plotTypes);


	-- To Europe Waterway
	local args = {};
	args.iWaterPercent = 100;
	args.iRegionWidth = math.ceil(g_iW/10);
	args.iRegionHeight = math.ceil(g_iH/10);
	args.iRegionWestX = math.floor(9*g_iW/10);
	args.iRegionSouthY = math.floor(9*g_iH/10);
	args.iRegionGrain = 4;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = g_iFlags;
	args.iRegionFracXExp = 0;
	args.iRegionFracYExp = 0;
	plotTypes = GenerateWaterLayer(args, plotTypes);




	--New World Continent
	local args = {};
	args.iWaterPercent = 44; 
	args.iRegionWidth = math.ceil(4);
	args.iRegionHeight = math.ceil(g_iH);
	args.iRegionWestX = math.floor(0);
	args.iRegionSouthY = math.floor(0);
	args.iRegionGrain = 4;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = g_iFlags;
	args.iRegionFracXExp = 5; 
	args.iRegionFracYExp = 5;
	args.bShift = false;
	plotTypes = GenerateFractalLayerWithoutHills(args, plotTypes);
	plotTypes = AddBorderWall(plotTypes);



	local args = {};
	args.iW = g_iW;
	args.iH = g_iH
	args.iFlags = g_iFlags;
	args.blendRidge = 5;
	args.blendFract = 5;
	mountainRatio = 1;
	plotTypes = ApplyTectonics(args, plotTypes);
	plotTypes = AddLonelyMountains(plotTypes, mountainRatio);

	return  plotTypes;
end

-------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features");

	-- Get Rainfall setting input by user.
	local rainfall = MapConfiguration.GetValue("rainfall");
	if rainfall == 4 then
		rainfall = 1 + TerrainBuilder.GetRandomNumber(3, "Random Rainfall - Lua");
	end
	
	iForestPercent = 5;  -- "Few Woods" 
	iJunglePercent = 90; -- "Lots of Rainforest"

	local args = {rainfall = rainfall, iForestPercent = iForestPercent, iJunglePercent = iJunglePercent}
	local featuregen = FeatureGenerator.Create(args);

	featuregen:AddFeatures();
end

-------------------------------------------------------------------------------
function AddBorderWall(plotTypes)
-- Adds land to the first few columns of grid to block boats

	for y = 0, g_iH-1, 1 do
		for x = 0, 0, 1 do
			local i = y * g_iW + x
			plotTypes[i] = g_PLOT_TYPE_LAND;
		end
	end
	return plotTypes;
end

-------------------------------------------------------------------------------
function GenerateFractalLayerWithoutHills (args, plotTypes)
	--[[ This function is intended to be paired with ApplyTectonics. If all the hills and
	mountains plots are going to be overwritten by the tectonics results, then why waste
	calculations generating them? ]]--
	local args = args or {};
	local plotTypes2 = {};

	-- Handle args or assign defaults.
	local iWaterPercent = args.iWaterPercent or 55;
	local iRegionWidth = args.iRegionWidth; -- Mandatory Parameter, no default
	local iRegionHeight = args.iRegionHeight; -- Mandatory Parameter, no default
	local iRegionWestX = args.iRegionWestX; -- Mandatory Parameter, no default
	local iRegionSouthY = args.iRegionSouthY; -- Mandatory Parameter, no default
	local iRegionGrain = args.iRegionGrain or 1;
	local iRegionPlotFlags = args.iRegionPlotFlags or g_iFlags;
	local iRegionTerrainFlags = g_iFlags; -- Removed from args list.
	local iRegionFracXExp = args.iRegionFracXExp or 6;
	local iRegionFracYExp = args.iRegionFracYExp or 5;
	local iRiftGrain = args.iRiftGrain or -1;
	local bShift = args.bShift or true;
	
	--print("Received Region Data");
	--print(iRegionWidth, iRegionHeight, iRegionWestX, iRegionSouthY, iRegionGrain);
	--print("- - -");
	
	--print("Filled regional table.");
	-- Loop through the region's plots
	for x = 0, iRegionWidth - 1, 1 do
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1; -- Lua arrays start at 1.
			plotTypes2[i] =g_PLOT_TYPE_OCEAN;
		end
	end

	-- Init the land/water fractal
	local regionContinentsFrac;
	if(iRiftGrain > 0 and iRiftGrain < 4) then
		local riftsFrac = Fractal.Create(g_iW, g_iH, rift_grain, {}, iRegionFracXExp, iRegionFracYExp);
		regionContinentsFrac = Fractal.CreateRifts(g_iW, g_iH, iRegionGrain, iRegionPlotFlags, riftsFrac, iRegionFracXExp, iRegionFracYExp);
	else
		regionContinentsFrac = Fractal.Create(g_iW, g_iH, iRegionGrain, iRegionPlotFlags, iRegionFracXExp, iRegionFracYExp);	
	end
	--print("Initialized main fractal");
	local iWaterThreshold = regionContinentsFrac:GetHeight(iWaterPercent);

	-- Loop through the region's plots
	for x = 0, iRegionWidth - 1, 1 do
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1; -- Lua arrays start at 1.
			local val = regionContinentsFrac:GetHeight(x,y);
			if val <= iWaterThreshold then
				--do nothing
			else
				plotTypes2[i] = g_PLOT_TYPE_LAND;
			end
		end
	end

	if bShift then -- Shift plots to obtain a more natural shape.
		ShiftPlotTypes(plotTypes);
	end

	print("Shifted Plots - Width: ", iRegionWidth, "Height: ", iRegionHeight);

	-- Apply the region's plots to the global plot array.
	for x = 0, iRegionWidth - 1, 1 do
		local wholeworldX = x + iRegionWestX;
		for y = 0, iRegionHeight - 1, 1 do
			local index = y * iRegionWidth + x + 1
			if plotTypes2[index] ~= g_PLOT_TYPE_OCEAN then
				local wholeworldY = y + iRegionSouthY;
				local i = wholeworldY * g_iW + wholeworldX + 1
				plotTypes[i] = plotTypes2[index];
			end
		end
	end
	--print("Generated Plot Types");

	return plotTypes;
end

-------------------------------------------------------------------------------
function GenerateWaterLayer (args, plotTypes)
	-- This function is intended to allow adding seas to specific areas of large continents.
	local args = args or {};
	
	-- Handle args or assign defaults.
	local iWaterPercent = args.iWaterPercent or 55;
	local iRegionWidth = args.iRegionWidth; -- Mandatory Parameter, no default
	local iRegionHeight = args.iRegionHeight; -- Mandatory Parameter, no default
	local iRegionWestX = args.iRegionWestX; -- Mandatory Parameter, no default
	local iRegionSouthY = args.iRegionSouthY; -- Mandatory Parameter, no default
	local iRegionGrain = args.iRegionGrain or 1;
	local iRegionPlotFlags = args.iRegionPlotFlags or g_iFlags;
	local iRegionFracXExp = args.iRegionFracXExp or 6;
	local iRegionFracYExp = args.iRegionFracYExp or 5;
	local iRiftGrain = args.iRiftGrain or -1;
	local bShift = args.bShift or true;

	-- Init the plot types array for this region's plot data. Redone for each new layer.
	-- Compare to self.wholeworldPlotTypes, which contains the sum of all layers.
	plotTypes2 = {};
	-- Loop through the region's plots
	for x = 0, iRegionWidth - 1, 1 do
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1; -- Lua arrays start at 1.
			plotTypes2[i] = g_PLOT_TYPE_OCEAN;
		end
	end

	-- Init the land/water fractal
	local regionContinentsFrac;
	if (iRiftGrain > 0) and (iRiftGrain < 4) then
		local riftsFrac = Fractal.Create(iRegionWidth, iRegionHeight, iRiftGrain, {}, iRegionFracXExp, iRegionFracYExp);
		regionContinentsFrac = Fractal.CreateRifts(iRegionWidth, iRegionHeight, iRegionGrain, iRegionPlotFlags, riftsFrac, iRegionFracXExp, iRegionFracYExp);
	else
		regionContinentsFrac = Fractal.Create(iRegionWidth, iRegionHeight, iRegionGrain, iRegionPlotFlags, iRegionFracXExp, iRegionFracYExp);	
	end
	
	-- Using the fractal matrices we just created, determine fractal-height values for sea level.
	local iWaterThreshold = regionContinentsFrac:GetHeight(iWaterPercent);

	-- Loop through the region's plots
	for x = 0, iRegionWidth - 1, 1 do
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1; -- Lua arrays start at 1.
			local val = regionContinentsFrac:GetHeight(x,y);
			if val <= iWaterThreshold then
				--do nothing
			else
				plotTypes2[i] = g_PLOT_TYPE_LAND;
			end
		end
	end

	if bShift then -- Shift plots to obtain a more natural shape.
		ShiftPlotTypes(plotTypes);
	end

	-- Apply the region's plots to the global plot array.
	for x = 0, iRegionWidth - 1, 1 do
		local wholeworldX = x + iRegionWestX;
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1;
			if plotTypes2[i] ~= g_PLOT_TYPE_OCEAN then
				local wholeworldY = y + iRegionSouthY;
				local index = wholeworldY * g_iW + wholeworldX + 1
				plotTypes[index] = g_PLOT_TYPE_OCEAN;
			end
		end
	end

	-- This region is done.
	return plotTypes;
end

-------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY)
	return
end

-------------------------------------------------------------------------------
function FeatureGenerator:AddJunglesAtPlot(plot, iX, iY)
	--Jungle Check. First see if it can place the feature.
	
	if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_JUNGLE)) then
		if(math.ceil(self.iJungleCount * 100 / self.iNumLandPlots) <= self.iJungleMaxPercent) then
				--Weight based on adjacent plots if it has more than 3 start subtracting
				local iScore = 300;
				local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_JUNGLE);

				if(iAdjacent == 0 ) then
					iScore = iScore;
				elseif(iAdjacent == 1) then
					iScore = iScore + 50;
				elseif (iAdjacent == 2 or iAdjacent == 3) then
					iScore = iScore + 150;
				elseif (iAdjacent == 4) then
					iScore = iScore - 50;
				else
					iScore = iScore - 200;
				end

				if(TerrainBuilder.GetRandomNumber(300, "Resource Placement Score Adjust") <= iScore) then
					TerrainBuilder.SetFeatureType(plot, g_FEATURE_JUNGLE);
					local terrainType = plot:GetTerrainType();

					if(terrainType == g_TERRAIN_TYPE_PLAINS_HILLS or terrainType == g_TERRAIN_TYPE_GRASS_HILLS) then
						TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_PLAINS_HILLS);
					else
						TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_PLAINS);
					end

					self.iJungleCount = self.iJungleCount + 1;
					return true;
				end
		end
	end

	return false
end

-------------------------------------------------------------------------------
function GetMapInitData(MapSize)
	local WrapX = false;
	return {WrapX = WrapX,}
end