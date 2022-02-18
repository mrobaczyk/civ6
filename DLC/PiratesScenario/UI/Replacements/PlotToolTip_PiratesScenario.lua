-- Copyright 2020, Firaxis Games
include "PlotTooltip";
include "PiratesScenario_Shared_Script";

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_FetchData = FetchData;
BASE_GetDetails = GetDetails;

local m_eBuriedTreasureImprovement : number = GameInfo.Improvements["IMPROVEMENT_BURIED_TREASURE"].Index;
local m_eFloatingTreasureImprovement : number = GameInfo.Improvements["IMPROVEMENT_FLOATING_TREASURE"].Index;

-- ===========================================================================
-- OVERRIDE BASE FUNCTIONS
-- ===========================================================================
function FetchData(pPlot : object)
	local kData : table = BASE_FetchData(pPlot);

	local localPlayerID : number = Game.GetLocalPlayer();
	local pLocalPlayer :object = Players[localPlayerID];
	if(pLocalPlayer == nil)then
		return kData;
	end

	--Check if pPlot is in a treasure map search area
	local treasureMaps :table = pLocalPlayer:GetProperty(g_playerPropertyKeys.TreasureMaps);
	local pPlotIndex : number = pPlot:GetIndex();
	if(treasureMaps ~= nil) then
		for loop, curTreasureMap in ipairs(treasureMaps) do
			if(pPlotIndex == curTreasureMap.SearchCenterIndex or Map.GetPlotDistance(pPlotIndex, curTreasureMap.SearchCenterIndex) <= PIRATE_TREASURE_SEARCH_ZONE_SIZE)then
				kData.TreasureSearchTooltip = Locale.Lookup("LOC_PIRATES_PLOT_TOOLTIP_TREASURE_MAP");
				return kData;
			end
		end
	end

	--Check if pPlot is a buried treasure plot
	local improvementType : number = pPlot:GetImprovementType();
	if(improvementType == m_eBuriedTreasureImprovement or improvementType == m_eFloatingTreasureImprovement)then
		local treasureOwnerID : number = pPlot:GetImprovementOwner();
		if(treasureOwnerID == -1)then
			local ownerName : string = pPlot:GetProperty(g_plotPropertyKeys.TreasureOwnerName);
			kData.TreasureOwnerTooltip = Locale.Lookup("LOC_PIRATES_PLOT_TOOLTIP_TREASURE_OWNER", ownerName);
			return kData;
		end
		local playerConfig : table = PlayerConfigurations[treasureOwnerID];
		local playerName : string = playerConfig:GetPlayerName();
		kData.TreasureOwnerTooltip = Locale.Lookup("LOC_PIRATES_PLOT_TOOLTIP_TREASURE_OWNER", playerName);
	end

	----Check if pPlot is in an infamous pirate search area
	local searchZones : table = Game:GetProperty(g_gamePropertyKeys.InfamousPirateSearchZones);
	if(searchZones ~= nil)then
		for k, searchZone in ipairs(searchZones) do
			if(searchZone.CenterPlotIndex == pPlotIndex)then
				kData.InfamousPirateTooltip = Locale.Lookup("LOC_PIRATES_PLOT_TOOLTIP_INFAMOUS_PIRATE");
				return kData;
			end
			local kSearchZoneCenter : object = Map.GetPlotByIndex(searchZone.CenterPlotIndex);
			local searchZonePlots : table = Map.GetNeighborPlots(kSearchZoneCenter:GetX(), kSearchZoneCenter:GetY(), PIRATE_TREASURE_SEARCH_ZONE_SIZE)
			for i, searchZonePlot in ipairs(searchZonePlots)do
				if(pPlotIndex == searchZonePlot:GetIndex())then
					kData.InfamousPirateTooltip = Locale.Lookup("LOC_PIRATES_PLOT_TOOLTIP_INFAMOUS_PIRATE");
					return kData;
				end
			end
		end
	end

	--Check if pPlot is in a treasure fleet route
	local treasureFleetPathProp :number = pPlot:GetProperty(g_plotPropertyKeys.TreasureFleetPath);
	if(treasureFleetPathProp ~= nil and treasureFleetPathProp > 0) then
		kData.TreasureFleetTooltip = Locale.Lookup("LOC_PIRATES_PLOT_TOOLTIP_TREASURE_FLEET");
	end

	return kData;
end

function GetDetails(kData : table)
	local kDetails : table = BASE_GetDetails(kData);

	if(kData.TreasureSearchTooltip ~= nil) then
		table.insert(kDetails, kData.TreasureSearchTooltip);
	end

	if(kData.InfamousPirateTooltip ~= nil) then
		table.insert(kDetails, kData.InfamousPirateTooltip);
	end

	if(kData.TreasureFleetTooltip ~= nil) then
		table.insert(kDetails, kData.TreasureFleetTooltip);
	end

	if(kData.TreasureOwnerTooltip ~= nil)then
		table.insert(kDetails, kData.TreasureOwnerTooltip);
	end

	return kDetails;
end