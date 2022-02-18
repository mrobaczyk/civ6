include "WorldBuilderResourceGen"

-- ===========================================================================
--	World Builder Placement
-- ===========================================================================

-- ===========================================================================
--	DATA MEMBERS
-- ===========================================================================
local m_SelectedPlot = nil;
local m_MouseOverPlot = nil;
local m_Mode = nil;
local m_TabButtons             : table = {};
local m_TerrainTypeEntries     : table = {};
local m_FeatureTypeEntries     : table = {};
local m_ContinentTypeEntries   : table = {};
local m_ResourceTypeEntries    : table = {};
local m_ImprovementTypeEntries : table = {};
local m_RouteTypeEntries       : table = {};
local m_DistrictTypeEntries    : table = {};
local m_BuildingTypeEntries    : table = {};
local m_PlayerEntries          : table = {};
local m_ScenarioPlayerEntries  : table = {}; -- Scenario players are players that don't have a random civ and can therefore have cities and units
local m_CityEntries            : table = {};
local m_UnitTypeEntries        : table = {};
local m_GoodyHutTypeEntries	   : table = {};
local m_BrushSize			   : number = 1;
local m_BrushEnabled		   : boolean = true;

-- Resource Regen variables
local NO_RESOURCE = -1;

-- 19-hex large brush assist table
local m_19HexTable			   : table = 
{
	{ Dir1=DirectionTypes.DIRECTION_NORTHWEST, Dir2=DirectionTypes.DIRECTION_NORTHEAST },
	{ Dir1=DirectionTypes.DIRECTION_NORTHEAST , Dir2=DirectionTypes.DIRECTION_EAST },
	{ Dir1=DirectionTypes.DIRECTION_EAST , Dir2=DirectionTypes.DIRECTION_SOUTHEAST },
	{ Dir1=DirectionTypes.DIRECTION_SOUTHEAST , Dir2=DirectionTypes.DIRECTION_SOUTHWEST },
	{ Dir1=DirectionTypes.DIRECTION_SOUTHWEST , Dir2=DirectionTypes.DIRECTION_WEST },
	{ Dir1=DirectionTypes.DIRECTION_WEST , Dir2=DirectionTypes.DIRECTION_NORTHWEST },
};

-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

-- ===========================================================================
function PlacementSetResults(bStatus: boolean, sStatus: table, name: string)
	local result : string;

	if bStatus then
		UI.PlaySound("UI_WB_Placement_Succeeded");
		result = Locale.Lookup(name) .. " " .. Locale.Lookup("LOC_WORLDBUILDER_BLANK_PLACEMENT_OK");
	else
		if sStatus.NeededDistrict ~= -1 then
			result = Locale.Lookup("LOC_WORLDBUILDER_PLACEMENT_NEEDED", m_DistrictTypeEntries[sStatus.NeededDistrict].Text);
		elseif sStatus.NeededPopulation > 0 then
			result = Locale.Lookup("LOC_WORLDBUILDER_DISTRICT_REQUIRES") .. " " .. sStatus.NeededPopulation .. " " .. Locale.Lookup("LOC_WORLDBUILDER_POPULATION");
		elseif sStatus.bInProgress then
			result=Locale.Lookup("LOC_WORLDBUILDER_IN_PROGRESS");
		elseif sStatus.AlreadyExists then
			result=Locale.Lookup("LOC_WORLDBUILDER_ALREADY_EXISTS");
		elseif sStatus.IsOccupied then
			result=Locale.Lookup("LOC_WORLDBUILDER_OCCUPIED_BY_ENEMY");
		elseif sStatus.DistrictIsPillaged then
			result=Locale.Lookup("LOC_WORLDBUILDER_IS_PILLAGED");
		elseif sStatus.LocationIsContaminated then
			result=Locale.Lookup("LOC_WORLDBUILDER_IS_CONTAMINATED");
		else
			result=Locale.Lookup("LOC_WORLDBUILDER_FAILURE_UNKNOWN");
		end
		UI.PlaySound("UI_WB_Placement_Failed");
	end

	LuaEvents.WorldBuilder_SetPlacementStatus(result);
end

-- ===========================================================================
function PlacementValid(plotID, mode)

	if mode == nil then
		return false;
	elseif mode.PlacementValid ~= nil then
		return mode.PlacementValid(plotID)
	else
		return true;
	end
end

-- ===========================================================================
function UpdateMouseOverHighlight(plotID, mode, on)

	if not mode.NoMouseOverHighlight then
		local highlight;
		if PlacementValid(plotID, mode) then
			highlight = PlotHighlightTypes.MOVEMENT;
		else
			highlight = PlotHighlightTypes.ATTACK;
		end
		UI.HighlightPlots(highlight, on, { plotID } );

		if m_BrushEnabled and m_BrushSize == 7 then
			local kPlot : table = Map.GetPlotByIndex(plotID);
			local adjPlots : table = Map.GetAdjacentPlots(kPlot:GetX(), kPlot:GetY());

			for i = 1, 6, 1 do
				if adjPlots[i] ~= nil then
					if PlacementValid(adjPlots[i]:GetIndex(), mode) then
						highlight = PlotHighlightTypes.MOVEMENT;
					else
						highlight = PlotHighlightTypes.ATTACK;
					end
					UI.HighlightPlots(highlight, on, { adjPlots[i]:GetIndex() } );
				end
			end
		elseif m_BrushEnabled and m_BrushSize == 19 then
			local kPlot : table = Map.GetPlotByIndex(plotID);
			local adjPlots : table = Map.GetAdjacentPlots(kPlot:GetX(), kPlot:GetY());
			
			for _,direction in pairs(DirectionTypes) do
				if adjPlots[direction] ~= nil then
					local adjPlot1 :table = Map.GetAdjacentPlot(adjPlots[direction]:GetX(), adjPlots[direction]:GetY(), m_19HexTable[direction].Dir1);
					local adjPlot2 :table = Map.GetAdjacentPlot(adjPlots[direction]:GetX(), adjPlots[direction]:GetY(), m_19HexTable[direction].Dir2);

					if adjPlot1 ~= nil then
						table.insert(adjPlots, adjPlot1);
					end
					if adjPlot2 ~= nil then
						table.insert(adjPlots, adjPlot2);
					end
				end
			end

			for i = 1, 19, 1 do
				if adjPlots[i] ~= nil then
					if PlacementValid(adjPlots[i]:GetIndex(), mode) then
						highlight = PlotHighlightTypes.MOVEMENT;
					else
						highlight = PlotHighlightTypes.ATTACK;
					end
					UI.HighlightPlots(highlight, on, { adjPlots[i]:GetIndex() } );
				end
			end
		end
	end
end

-- ===========================================================================
function ClearMode()

	if m_Mode ~= nil then

		if m_MouseOverPlot ~= nil then
			UpdateMouseOverHighlight(m_MouseOverPlot, m_Mode, false);
		end
		
		if m_Mode.OnLeft ~= nil then
			m_Mode.OnLeft();
		end

		m_Mode = nil;
	end
end

-- ===========================================================================
function OnPlacementTypeSelected(mode)

	ClearMode();

	m_Mode = mode;
	Controls.TabControl:SelectTab( mode.Tab );

	if mode.ID == WorldBuilderModes.PLACE_TERRAIN or mode.ID == WorldBuilderModes.PLACE_CONTINENTS then
		Controls.BrushPullDown:SetDisabled(false);
		Controls.BrushPullDown:SetColor(1.0, 1.0, 1.0);
		m_BrushEnabled = true;
	else
		Controls.BrushPullDown:SetDisabled(true);
		Controls.BrushPullDown:SetColor(0.5, 0.5, 0.5);
		m_BrushEnabled = false;
	end
	
	if mode.ID == WorldBuilderModes.PLACE_RESOURCES then
		OnResourceTypeSelected(Controls.ResourcePullDown:GetSelectedEntry());
	end

	if m_MouseOverPlot ~= nil then
		UpdateMouseOverHighlight(m_MouseOverPlot, m_Mode, true);
	end

	if m_Mode.OnEntered ~= nil then
		m_Mode.OnEntered();
	end

	Controls.Root:CalculateSize();
end

-- ===========================================================================
function OnPlotSelected(plotID, edge, lbutton)
	
	if not ContextPtr:IsHidden() then
		local mode = Controls.PlacementPullDown:GetSelectedEntry();
		local kPlot : table = Map.GetPlotByIndex(plotID);
		mode.PlacementFunc( plotID, edge, lbutton );

		if m_BrushEnabled and m_BrushSize == 7 then
			local adjPlots : table = Map.GetAdjacentPlots(kPlot:GetX(), kPlot:GetY());

			for i = 1, 6, 1 do
				if adjPlots[i] ~= nil and PlacementValid(adjPlots[i]:GetIndex(), mode) then
					mode.PlacementFunc(adjPlots[i]:GetIndex(), edge, lbutton);
				end
			end
		elseif m_BrushEnabled and m_BrushSize == 19 then
			local adjPlots : table = Map.GetAdjacentPlots(kPlot:GetX(), kPlot:GetY());

			for _,direction in pairs(DirectionTypes) do
				if adjPlots[direction] ~= nil then
					local adjPlot1 :table = Map.GetAdjacentPlot(adjPlots[direction]:GetX(), adjPlots[direction]:GetY(), m_19HexTable[direction].Dir1);
					local adjPlot2 :table = Map.GetAdjacentPlot(adjPlots[direction]:GetX(), adjPlots[direction]:GetY(), m_19HexTable[direction].Dir2);

					if adjPlot1 ~= nil then
						table.insert(adjPlots, adjPlot1);
					end
					if adjPlot2 ~= nil then
						table.insert(adjPlots, adjPlot2);
					end
				end
			end

			for i = 1, 19, 1 do
				if adjPlots[i] ~= nil then
					mode.PlacementFunc(adjPlots[i]:GetIndex(), edge, lbutton);
				end
			end
		end
	end
end

-- ===========================================================================
function OnPlotMouseOver(plotID)

	if m_Mode ~= nil then
		if m_MouseOverPlot ~= nil then
			UpdateMouseOverHighlight(m_MouseOverPlot, m_Mode, false);
		end

		if plotID ~= nil then
			UpdateMouseOverHighlight(plotID, m_Mode, true);
		end
	end

	m_MouseOverPlot = plotID;
end

-- ===========================================================================
function OnShow()

	local mode = Controls.PlacementPullDown:GetSelectedEntry();
	OnPlacementTypeSelected( mode );

	if UI.GetInterfaceMode() ~= InterfaceModeTypes.WB_SELECT_PLOT then
		UI.SetInterfaceMode( InterfaceModeTypes.WB_SELECT_PLOT );
	end

	LuaEvents.WorldBuilderMapTools_SetTabHeader(Locale.Lookup("LOC_WORLDBUILDER_PLACEMENT_PLACE_PLOT"));
end

-- ===========================================================================
function OnHide()
	ClearMode();
end

-- ===========================================================================
function OnLoadGameViewStateDone()

	UpdatePlayerEntries();
	UpdateCityEntries();

	if not ContextPtr:IsHidden() then
		OnShow();
	end
end

-- ===========================================================================
function OnBrushSizeChanged(entry)
	if entry ~= nil then
		m_BrushSize = entry.HexSize;
	end
end

-- ===========================================================================
function OnVisibilityPlayerChanged(entry)
	
	if m_Mode ~= nil and m_Mode.Tab == Controls.PlaceVisibility then
		if entry ~= nil then
			WorldBuilder.SetVisibilityPreviewPlayer(entry.PlayerIndex);
		else
			WorldBuilder.ClearVisibilityPreviewPlayer();
		end
	end 
end

-- ===========================================================================
function OnVisibilityPlayerRevealAll()
	
	local entry = Controls.VisibilityPullDown:GetSelectedEntry();
	if entry ~= nil then
		WorldBuilder.MapManager():SetAllRevealed(true, entry.PlayerIndex);
	end

end

-- ===========================================================================
function UpdatePlayerEntries()

	m_PlayerEntries = {};
	m_ScenarioPlayerEntries = {};
	
	for i = 0, GameDefines.MAX_PLAYERS-1 do 

		local eStatus = WorldBuilder.PlayerManager():GetSlotStatus(i); 
		if eStatus ~= SlotStatus.SS_CLOSED then
			local playerConfig = WorldBuilder.PlayerManager():GetPlayerConfig(i);
			if playerConfig.IsBarbarian == false then	-- Skipping the Barbarian player
				table.insert(m_PlayerEntries, { Text=playerConfig.Name, PlayerIndex=i });
				if playerConfig.Civ ~= nil then
					table.insert(m_ScenarioPlayerEntries, { Text=playerConfig.Name, PlayerIndex=i });
				end
			end
		end
	end
	
	local hasPlayers = m_PlayerEntries[1] ~= nil;
	local hasScenarioPlayers = m_ScenarioPlayerEntries[1] ~= nil;

	Controls.StartPosPlayerPulldown:SetEntries( m_PlayerEntries, hasPlayers and 1 or 0 );
	Controls.CityOwnerPullDown:SetEntries( m_ScenarioPlayerEntries, hasScenarioPlayers and 1 or 0 );
	Controls.UnitOwnerPullDown:SetEntries( m_ScenarioPlayerEntries, hasScenarioPlayers and 1 or 0 );
	Controls.VisibilityPullDown:SetEntries( m_ScenarioPlayerEntries, hasScenarioPlayers and 1 or 0 );

	if WorldBuilder.GetWBAdvancedMode() then
		m_TabButtons[Controls.PlaceUnit]:SetDisabled( not hasScenarioPlayers );
		m_TabButtons[Controls.PlaceBuilding]:SetDisabled( not hasScenarioPlayers );
		m_TabButtons[Controls.PlaceStartPos]:SetDisabled( not hasPlayers );
		m_TabButtons[Controls.PlaceDistrict]:SetDisabled( not hasScenarioPlayers );
		m_TabButtons[Controls.PlaceVisibility]:SetDisabled( not hasScenarioPlayers );
		m_TabButtons[Controls.PlaceCity]:SetDisabled( not hasScenarioPlayers );
	end

	OnVisibilityPlayerChanged(Controls.VisibilityPullDown:GetSelectedEntry());
end

-- ===========================================================================
function UpdateCityEntries()

	m_CityEntries = {};

	for iPlayer = 0, GameDefines.MAX_PLAYERS-1 do
		local player = Players[iPlayer];
		local cities = player:GetCities();
		if cities ~= nil then
			for iCity, city in cities:Members() do
				table.insert(m_CityEntries, { Text=city:GetName(), PlayerIndex=iPlayer, ID=city:GetID() });
			end
		end
	end

	local hasCities = m_CityEntries[1] ~= nil;
	Controls.OwnerPullDown:SetEntries( m_CityEntries, hasCities and 1 or 0 );
	Controls.DistrictCityPullDown:SetEntries( m_CityEntries, hasCities and 1 or 0 );
	Controls.BuildingCityPullDown:SetEntries( m_CityEntries, hasCities and 1 or 0 );
end

-- ===========================================================================
function PlaceTerrain(plot, edge, bAdd)

	if bAdd then
		local entry = Controls.TerrainPullDown:GetSelectedEntry();
		local pkPlot = Map.GetPlotByIndex( plot );
		local resType :number = nil; 
		local featureType :number = nil;

		if (pkPlot:GetResourceType() > 1) then
			resType = m_ResourceTypeEntries[pkPlot:GetResourceType()+1].Type.Index; 
		end
		if (pkPlot:GetFeatureType() >= 0) then
			featureType = m_FeatureTypeEntries[pkPlot:GetFeatureType()+1].Type.Index;
		end

		WorldBuilder.MapManager():SetTerrainType( plot, entry.Type.Index );

		-- will the existing resource work with the new terrain?
		if resType ~= nil and not WorldBuilder.MapManager():CanPlaceResource( plot, resType, true ) then
			WorldBuilder.MapManager():SetResourceType( plot, -1 );
		end

		-- how about the existing feature?
		if featureType ~= nil and not WorldBuilder.MapManager():CanPlaceFeature( plot, featureType, true ) then
			WorldBuilder.MapManager():SetFeatureType( plot, -1 );
		end
	end
end

-- ===========================================================================
function PlaceFeature_Valid(plot)
	local entry = Controls.FeaturePullDown:GetSelectedEntry();
	return WorldBuilder.MapManager():CanPlaceFeature( plot, entry.Type.Index );
end

-- ===========================================================================
function PlaceContinent(plot, edge, bAdd)

	if bAdd then
		local entry = Controls.ContinentPullDown:GetSelectedEntry();
		WorldBuilder.MapManager():SetContinentType( plot, entry.Type.Index );
	end
end

-- ===========================================================================
function PlaceContinent_Valid(plot)
	local pPlot = Map.GetPlotByIndex(plot);
	return pPlot ~= nil and not pPlot:IsWater();
end

-- ===========================================================================
function PlaceFeature(plot, edge, bAdd)

	if bAdd then
		local entry = Controls.FeaturePullDown:GetSelectedEntry();
		if WorldBuilder.MapManager():CanPlaceFeature( plot, entry.Type.Index ) then
			WorldBuilder.MapManager():SetFeatureType( plot, entry.Type.Index );
			LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup(entry.Text) .. " " .. Locale.Lookup("LOC_WORLDBUILDER_BLANK_PLACEMENT_OK"));
			UI.PlaySound("UI_WB_Placement_Succeeded");
		else
			LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_FAILURE_FEATURE"));
			UI.PlaySound("UI_WB_Placement_Failed");
		end
	else
		WorldBuilder.MapManager():SetFeatureType( plot, -1 );
	end
end

-- ===========================================================================
function PlaceRiver(plot, edge, bAdd)
	WorldBuilder.MapManager():EditRiver(plot, edge, bAdd);
end

-- ===========================================================================
function PlaceCliff(plot, edge, bAdd)
	WorldBuilder.MapManager():EditCliff(plot, edge, bAdd);
end

-- ===========================================================================
function PlaceResource_Valid(plot)
	local entry = Controls.ResourcePullDown:GetSelectedEntry();
	return WorldBuilder.MapManager():CanPlaceResource( plot, entry.Type.Index );
end

-- ===========================================================================
function PlaceResource(plot, edge, bAdd)

	if bAdd then
		local entry = Controls.ResourcePullDown:GetSelectedEntry();
		if WorldBuilder.MapManager():CanPlaceResource( plot, entry.Type.Index ) then
			if entry.Class == "RESOURCECLASS_STRATEGIC" then
				WorldBuilder.MapManager():SetResourceType( plot, entry.Type.Index, Controls.ResourceAmount:GetText() );
			else
				WorldBuilder.MapManager():SetResourceType( plot, entry.Type.Index, "1" );
			end
		end
	else
		WorldBuilder.MapManager():SetResourceType( plot, -1 );
	end
end

-- ===========================================================================
function PlaceCity(plot, edge, bAdd)

	if bAdd then
		local playerEntry = Controls.CityOwnerPullDown:GetSelectedEntry();
		if playerEntry ~= nil then
			WorldBuilder.CityManager():Create(playerEntry.PlayerIndex, plot);
			LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_PLACEMENT_OK"));
			UI.PlaySound("UI_WB_Placement_Succeeded");
		end
	else
		WorldBuilder.CityManager():RemoveAt(plot);
	end
end

-- ===========================================================================
function PlaceDistrict(plot, edge, bAdd)
	local bStatus : boolean;
	local sStatus : table;

	if bAdd then
		local cityEntry = Controls.DistrictCityPullDown:GetSelectedEntry();
		if cityEntry ~= nil then
			local city = CityManager.GetCity(cityEntry.PlayerIndex, cityEntry.ID);
			if city ~= nil then
				local districtEntry = Controls.DistrictPullDown:GetSelectedEntry();
				bStatus, sStatus = WorldBuilder.CityManager():CreateDistrict(city, districtEntry.Type.DistrictType, 100, plot);
				PlacementSetResults(bStatus, sStatus, districtEntry.Text);
			end

		end
	else
		-- Get the district at the plot
		local pDistrict = CityManager.GetDistrictAt(plot);
		if (pDistrict ~= nil) then
			WorldBuilder.CityManager():RemoveDistrict(pDistrict);
		end
	end
end

-- ===========================================================================
function PlaceBuilding(plot, edge, bAdd)
	local bStatus : boolean;
	local sStatus : table;

	if bAdd then
		local cityEntry = Controls.BuildingCityPullDown:GetSelectedEntry();
		if cityEntry ~= nil then
			local city = CityManager.GetCity(cityEntry.PlayerIndex, cityEntry.ID);
			if city ~= nil then
				local buildingEntry = Controls.BuildingPullDown:GetSelectedEntry();
				if buildingEntry ~= nil then
					bStatus, sStatus = WorldBuilder.CityManager():CreateBuilding(city, buildingEntry.Type.BuildingType, 100, plot);
					PlacementSetResults(bStatus, sStatus, buildingEntry.Text);
				end
			end

		end
	else
		-- Get the district at the plot
		local pDistrict = CityManager.GetDistrictAt(plot);
		if (pDistrict ~= nil) then
			-- Then its city
			local pCity = pDistrict:GetCity();
			if pCity ~= nil then
				-- Remove the building from the city
				local buildingEntry = Controls.BuildingPullDown:GetSelectedEntry();
				if buildingEntry ~= nil then
					WorldBuilder.CityManager():RemoveBuilding(pCity, buildingEntry.Type.BuildingType);
				end
			end
		end
	end
end

-- ===========================================================================
function PlaceUnit(plot, edge, bAdd)

	if bAdd then
		local playerEntry = Controls.UnitOwnerPullDown:GetSelectedEntry();
		local unitEntry = Controls.UnitPullDown:GetSelectedEntry();
		if playerEntry ~= nil and unitEntry ~= nil then
			WorldBuilder.UnitManager():Create(unitEntry.Type.Index, playerEntry.PlayerIndex, plot);
			LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_UNIT_PLACED"));
			UI.PlaySound("UI_WB_Placement_Succeeded");
		end
	else
		WorldBuilder.UnitManager():RemoveAt(plot);
	end
end

-- ===========================================================================
function PlaceImprovement(plot, edge, bAdd)

	if bAdd then
		local entry = Controls.ImprovementPullDown:GetSelectedEntry();
		WorldBuilder.MapManager():SetImprovementType( plot, entry.Type.Index, Map.GetPlotByIndex( m_SelectedPlot ):GetOwner() );
		LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup(entry.Text) .. " " .. Locale.Lookup("LOC_WORLDBUILDER_BLANK_PLACEMENT_OK"));
		UI.PlaySound("UI_WB_Placement_Succeeded");
	else
		WorldBuilder.MapManager():SetImprovementType( plot, -1 );
	end
end

-- ===========================================================================
function PlaceGoodyHut(plot, edge, bAdd)

	if bAdd then
		local entry = Controls.GoodyHutPullDown:GetSelectedEntry();
		WorldBuilder.MapManager():SetImprovementType( plot, entry.Type.Index, Map.GetPlotByIndex( m_SelectedPlot ):GetOwner() );
		LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup(entry.Text) .. " " .. Locale.Lookup("LOC_WORLDBUILDER_BLANK_PLACEMENT_OK"));
		UI.PlaySound("UI_WB_Placement_Succeeded");
	else
		WorldBuilder.MapManager():SetImprovementType( plot, -1 );
	end
end

-- ===========================================================================
function PlaceRoute(plot, edge, bAdd)

	if bAdd then
		local entry = Controls.RoutePullDown:GetSelectedEntry();
		WorldBuilder.MapManager():SetRouteType( plot, entry.Type.Index, Controls.RoutePillagedCheck:IsChecked() );
		LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup(entry.Text) .. " " .. Locale.Lookup("LOC_WORLDBUILDER_BLANK_PLACEMENT_OK"));
		UI.PlaySound("UI_WB_Placement_Succeeded");
	else
		WorldBuilder.MapManager():SetRouteType( plot, RouteTypes.NONE );
	end
end

-- ===========================================================================
function PlaceStartPos(plot, edge, bAdd)

	if bAdd then
		local entry = Controls.StartPosPlayerPulldown:GetSelectedEntry();
		if entry ~= nil then
			WorldBuilder.PlayerManager():SetPlayerStartingPosition( entry.PlayerIndex, plot );
			LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_START_POS_SET"));
			UI.PlaySound("UI_WB_Placement_Succeeded");
		end
	else
		local prevStartPosPlayer = WorldBuilder.PlayerManager():GetStartPositionPlayer( plot );
		if prevStartPosPlayer ~= -1 then
			WorldBuilder.PlayerManager():ClearPlayerStartingPosition( prevStartPosPlayer );
		end
	end
end

-- ===========================================================================
function PlaceOwnership(iPlot, edge, bAdd)

	local plot = Map.GetPlotByIndex( iPlot );
	if bAdd then
		local entry = Controls.OwnerPullDown:GetSelectedEntry();
		if entry ~= nil then
			WorldBuilder.CityManager():SetPlotOwner( plot:GetX(), plot:GetY(), entry.PlayerIndex, entry.ID );
			LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_OWNERSHIP_SET"));
			UI.PlaySound("UI_WB_Placement_Succeeded");
		end
	else
		WorldBuilder.CityManager():SetPlotOwner( plot:GetX(), plot:GetY(), false );
	end
end

-- ===========================================================================
function OnVisibilityToolEntered()
	
	local entry = Controls.VisibilityPullDown:GetSelectedEntry();
	if entry ~= nil then
		WorldBuilder.SetVisibilityPreviewPlayer(entry.PlayerIndex);
	end 
end

-- ===========================================================================
function OnVisibilityToolLeft()
	WorldBuilder.ClearVisibilityPreviewPlayer();
end

-- ===========================================================================
function PlaceVisibility(plot, edge, bAdd)

	local entry = Controls.VisibilityPullDown:GetSelectedEntry();
	if entry ~= nil then
		WorldBuilder.MapManager():SetRevealed(plot, bAdd, entry.PlayerIndex);
	end
end

-- ===========================================================================
local m_ContinentPlots : table = {};

-- ===========================================================================
function OnContinentToolEntered()

	local continentType = Controls.ContinentPullDown:GetSelectedEntry().Type.Index;
	m_ContinentPlots = WorldBuilder.MapManager():GetContinentPlots(continentType);
	UI.HighlightPlots(PlotHighlightTypes.PLACEMENT, true, m_ContinentPlots);
	LuaEvents.WorldBuilder_ContinentTypeEdited.Add(OnContinentTypeEdited);
end

-- ===========================================================================
function OnContinentToolLeft()
	LuaEvents.WorldBuilder_ContinentTypeEdited.Remove(OnContinentTypeEdited);
	UI.HighlightPlots(PlotHighlightTypes.PLACEMENT, false);
end

-- ===========================================================================
function OnContinentTypeSelected( entry )

	if m_Mode ~= nil and m_Mode.Tab == Controls.PlaceContinent then
		UI.HighlightPlots(PlotHighlightTypes.PLACEMENT, false);
		m_ContinentPlots = WorldBuilder.MapManager():GetContinentPlots(entry.Type.Index);
		UI.HighlightPlots(PlotHighlightTypes.PLACEMENT, true, m_ContinentPlots);
	end
end

-- ===========================================================================
function OnContinentTypeEdited( plotID, continentType )

	if continentType == Controls.ContinentPullDown:GetSelectedEntry().Type.Index then
		table.insert(m_ContinentPlots, plotID);
		UI.HighlightPlots(PlotHighlightTypes.PLACEMENT, true, { plotID } );
	else
		for i, v in ipairs(m_ContinentPlots) do
			if v == plotID then
				table.remove(m_ContinentPlots, i);
				UI.HighlightPlots(PlotHighlightTypes.PLACEMENT, false);
				UI.HighlightPlots(PlotHighlightTypes.PLACEMENT, true, m_ContinentPlots);
				break;
			end
		end
	end
end

-- ===========================================================================
function OnResourceTypeSelected( entry )
	if entry.Class == "RESOURCECLASS_STRATEGIC" then
		Controls.ResourceAmount:SetHide(false);
	else
		Controls.ResourceAmount:SetHide(true);
	end
end

-- ===========================================================================
--	Placement Modes
-- ===========================================================================
local m_PlacementModes : table =
{
	{ ID=WorldBuilderModes.PLACE_TERRAIN,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_TERRAIN",         Tab=Controls.PlaceTerrain,      PlacementFunc=PlaceTerrain,     PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_FEATURES,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_FEATURES",        Tab=Controls.PlaceFeatures,     PlacementFunc=PlaceFeature,     PlacementValid=PlaceFeature_Valid    },
	{ ID=WorldBuilderModes.PLACE_CONTINENTS,	Text="LOC_WORLDBUILDER_PLACEMENT_MODE_CONTINENT",       Tab=Controls.PlaceContinent,    PlacementFunc=PlaceContinent,   PlacementValid=PlaceContinent_Valid, OnEntered=OnContinentToolEntered, OnLeft=OnContinentToolLeft, NoMouseOverHighlight=true },
	{ ID=WorldBuilderModes.PLACE_RIVERS,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_RIVERS",          Tab=Controls.PlaceRivers,       PlacementFunc=PlaceRiver,       PlacementValid=nil,                  NoMouseOverHighlight=true },
	{ ID=WorldBuilderModes.PLACE_CLIFFS,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_CLIFFS",          Tab=Controls.PlaceCliffs,       PlacementFunc=PlaceCliff,       PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_RESOURCES,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_RESOURCES",       Tab=Controls.PlaceResources,    PlacementFunc=PlaceResource,    PlacementValid=PlaceResource_Valid   },
	{ ID=WorldBuilderModes.PLACE_CITIES,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_CITIES",            Tab=Controls.PlaceCity,         PlacementFunc=PlaceCity,        PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_DISTRICTS,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_DISTRICTS",        Tab=Controls.PlaceDistrict,     PlacementFunc=PlaceDistrict,    PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_BUILDINGS,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_BUILDINGS",        Tab=Controls.PlaceBuilding,     PlacementFunc=PlaceBuilding,    PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_UNITS,			Text="LOC_WORLDBUILDER_PLACEMENT_MODE_UNITS",            Tab=Controls.PlaceUnit,         PlacementFunc=PlaceUnit,        PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_IMPROVEMENTS,	Text="LOC_WORLDBUILDER_PLACEMENT_MODE_IMPROVEMENTS",    Tab=Controls.PlaceImprovements, PlacementFunc=PlaceImprovement, PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_ROUTES,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_ROUTES",          Tab=Controls.PlaceRoutes,       PlacementFunc=PlaceRoute,       PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_START_POSITIONS, Text="LOC_WORLDBUILDER_PLACEMENT_MODE_START_POSITIONS",  Tab=Controls.PlaceStartPos,     PlacementFunc=PlaceStartPos,    PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_TERRAIN_OWNER,	Text="LOC_WORLDBUILDER_PLACEMENT_MODE_OWNER",           Tab=Controls.PlaceOwnership,    PlacementFunc=PlaceOwnership,   PlacementValid=nil                   },
	{ ID=WorldBuilderModes.SET_VISIBILITY,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_SET_VISIBILITY",	Tab=Controls.PlaceVisibility,   PlacementFunc=PlaceVisibility,  PlacementValid=nil,                  OnEntered=OnVisibilityToolEntered, OnLeft=OnVisibilityToolLeft },
};

local m_BasicPlacementModes : table =
{
	{ ID=WorldBuilderModes.PLACE_TERRAIN,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_TERRAIN",         Tab=Controls.PlaceTerrain,      PlacementFunc=PlaceTerrain,     PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_FEATURES,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_FEATURES",        Tab=Controls.PlaceFeatures,     PlacementFunc=PlaceFeature,     PlacementValid=PlaceFeature_Valid    },
	{ ID=WorldBuilderModes.PLACE_CONTINENTS,	Text="LOC_WORLDBUILDER_PLACEMENT_MODE_CONTINENT",       Tab=Controls.PlaceContinent,    PlacementFunc=PlaceContinent,   PlacementValid=PlaceContinent_Valid, OnEntered=OnContinentToolEntered, OnLeft=OnContinentToolLeft, NoMouseOverHighlight=true },
	{ ID=WorldBuilderModes.PLACE_RIVERS,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_RIVERS",          Tab=Controls.PlaceRivers,       PlacementFunc=PlaceRiver,       PlacementValid=nil,                  NoMouseOverHighlight=true },
	{ ID=WorldBuilderModes.PLACE_CLIFFS,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_CLIFFS",          Tab=Controls.PlaceCliffs,       PlacementFunc=PlaceCliff,       PlacementValid=nil                   },
	{ ID=WorldBuilderModes.PLACE_RESOURCES,		Text="LOC_WORLDBUILDER_PLACEMENT_MODE_RESOURCES",       Tab=Controls.PlaceResources,    PlacementFunc=PlaceResource,    PlacementValid=PlaceResource_Valid   },
	{ ID=WorldBuilderModes.PLACE_IMPROVEMENTS,	Text="LOC_WORLDBUILDER_PLACEMENT_MODE_GOODY_HUTS",		Tab=Controls.PlaceGoodyHuts,	PlacementFunc=PlaceGoodyHut,	PlacementValid=nil                   },
};

local m_BrushSizeEntries : table =
{
	{ ID=1,		Text="LOC_WORLDBUILDER_BRUSH_SMALL", HexSize=1 },
	{ ID=2,		Text="LOC_WORLDBUILDER_BRUSH_MEDIUM",  HexSize=7 },
	{ ID=3,		Text="LOC_WORLDBUILDER_BRUSH_LARGE",  HexSize=19 },
};

local m_PlacementModesByID = {};

-- ==========================================================================
function SelectPlacementTab()
	-- Make sure this tab is visibile
	if not ContextPtr:IsVisible() then
		-- Get our parent tab container.
		local pParent = ContextPtr:GetParentByType("TabControl");
		if pParent ~= nil then
			pParent:SelectTabByID(ContextPtr:GetID());
		end
	end
end

local ms_eNextMode = WorldBuilderModes.INVALID;
local ms_kNextModeParams = nil;

-- ===========================================================================
function OnWorldBuilderModeChangeRequest(eMode, kParams)

	-- Store the request, then send out an event to handle it.
	-- Doing this in a deferred way prevents any issue with changing modes at a 'bad' time, such as
	-- while handling a UI control callback.  However, it does mean that we must be careful
	-- because there will be time for anything to happen btween the time we send the event and it getting handled.

	ms_eNextMode = eMode;
	ms_kNextModeParams = kParams;

	Events.WorldBuilderSignal(WorldBuilderSignals.MODE_CHANGE);
end

-- ===========================================================================
function SelectMode(id)

	for i,entry in ipairs(m_PlacementModes) do
		if entry.ID == id then
			Controls.PlacementPullDown:SetSelectedIndex(i, true);
			break;
		end
	end

end

-- ===========================================================================
function SelectDistrictOwner(player, city)

	for i,entry in ipairs(m_CityEntries) do
		if entry.PlayerIndex == player and entry.ID == city then
			Controls.DistrictCityPullDown:SetSelectedIndex(i, true);
			break;
		end
	end

end

-- ===========================================================================
function SelectDistrictType(typeHash)

	for i,entry in ipairs(m_DistrictTypeEntries) do
		if entry.Type.Hash == typeHash then
			Controls.DistrictPullDown:SetSelectedIndex(i, true);
			break;
		end
	end

end

-- ===========================================================================
function SelectBuildingOwner(player, city)

	for i,entry in ipairs(m_CityEntries) do
		if entry.PlayerIndex == player and entry.ID == city then
			Controls.BuildingCityPullDown:SetSelectedIndex(i, true);
			break;
		end
	end

end

-- ===========================================================================
function SelectBuildingType(typeHash)

	for i,entry in ipairs(m_DistrictTypeEntries) do
		if entry.Type.Hash == typeHash then
			Controls.BuildingPullDown:SetSelectedIndex(i, true);
			break;
		end
	end

end

-- ===========================================================================
function SelectCityOwner(playerIndex)

	Controls.CityOwnerPullDown:SetSelectedIndex(playerIndex + 1, true);

end

-- ===========================================================================
function OnWorldBuilderSignal(eType)

	if (eType == WorldBuilderSignals.MODE_CHANGE) then

		local eMode = ms_eNextMode;
		local kParams = ms_kNextModeParams;

		-- Remove the reference now, in case the mode change triggers another mode change.
		ms_eNextMode = WorldBuilderModes.INVALID;
		ms_kNextModeParams = nil;

		-- Hide UI
		LuaEvents.WorldBuilder_ShowPlayerEditor( false );

		-- Make sure this tab is visible
		SelectPlacementTab();

		-- Switch
		if eMode == WorldBuilderModes.PLACE_DISTRICTS then
			-- Select the mode
			SelectMode(eMode);
			-- Select the mode's sub-items
			SelectDistrictOwner(kParams.PlayerID, kParams.CityID);
			SelectDistrictType(kParams.DistrictType);
		elseif eMode == WorldBuilderModes.PLACE_BUILDINGS then
			-- Select the mode
			SelectMode(eMode);
			-- Select the mode's sub-items
			SelectBuildingOwner(kParams.PlayerID, kParams.CityID);
			SelectBuildingType(kParams.BuildingType);
		elseif eMode == WorldBuilderModes.PLACE_CITIES then
			-- Select the mode
			SelectMode(eMode);
			-- Select the mode's sub-items
			SelectCityOwner(kParams.PlayerID);
		end

	end
		
end

-- ===========================================================================
function OnRegenResources()
	for plotIndex = 0, Map.GetPlotCount()-1, 1 do
		local plot = Map.GetPlotByIndex(plotIndex);
		WorldBuilder.MapManager():SetResourceType(plot, NO_RESOURCE);
	end
	LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_STATUS_RESOURCES_CLEARED"));
end

-- ===========================================================================
function OnGenResources()
	-- reuse OnRegenResources' clear function
	OnRegenResources();

	-- and run the generate
	local resourcesConfig = MapConfiguration.GetValue("resources");
    local args = {
        resources = resourcesConfig,
    };
    local resGen = WorldBuilderResourceGenerator.Create(args);
	LuaEvents.WorldBuilder_SetPlacementStatus(Locale.Lookup("LOC_WORLDBUILDER_STATUS_RESOURCES_SCATTERED"));
end

-- ===========================================================================
function OnAdvancedModeChanged()
	if not WorldBuilder.GetWBAdvancedMode() then
		Controls.PlacementPullDown:SetEntries( m_BasicPlacementModes, 1 );
		for i,tabEntry in ipairs(m_BasicPlacementModes) do
			m_TabButtons[tabEntry.Tab] = tabEntry.Button;
		end

		for i,entry in ipairs(m_BasicPlacementModes) do
			m_PlacementModesByID[entry.ID] = entry;
		end
	else
		Controls.PlacementPullDown:SetEntries( m_PlacementModes, 1 );
		for i,tabEntry in ipairs(m_PlacementModes) do
			m_TabButtons[tabEntry.Tab] = tabEntry.Button;
		end

		for i,entry in ipairs(m_PlacementModes) do
			m_PlacementModesByID[entry.ID] = entry;
		end
	end
	Controls.PlacementPullDown:SetEntrySelectedCallback( OnPlacementTypeSelected );

	UpdatePlayerEntries();
	UpdateCityEntries();
end

-- ===========================================================================
--	Init
-- ===========================================================================
function OnInit()

	-- PlacementPullDown
	if not WorldBuilder.GetWBAdvancedMode() then
		Controls.PlacementPullDown:SetEntries( m_BasicPlacementModes, 1 );
	else
		Controls.PlacementPullDown:SetEntries( m_PlacementModes, 1 );
	end
	Controls.PlacementPullDown:SetEntrySelectedCallback( OnPlacementTypeSelected );

	-- Track Tab Buttons
	for i,tabEntry in ipairs(m_PlacementModes) do
		m_TabButtons[tabEntry.Tab] = tabEntry.Button;
	end

	for i,entry in ipairs(m_PlacementModes) do
		m_PlacementModesByID[entry.ID] = entry;
	end

	-- TerrainPullDown
	for type in GameInfo.Terrains() do
		table.insert(m_TerrainTypeEntries, { Text=type.Name, Type=type });
	end
	Controls.TerrainPullDown:SetEntries( m_TerrainTypeEntries, 1 );

	-- FeaturePullDown
	for type in GameInfo.Features() do
		table.insert(m_FeatureTypeEntries, { Text=type.Name, Type=type });
	end
	Controls.FeaturePullDown:SetEntries( m_FeatureTypeEntries, 1 );

	-- ContinentPullDown
	for type in GameInfo.Continents() do
		table.insert(m_ContinentTypeEntries, { Text=type.Description, Type=type });
	end
	Controls.ContinentPullDown:SetEntries( m_ContinentTypeEntries, 1 );
	Controls.ContinentPullDown:SetEntrySelectedCallback( OnContinentTypeSelected );

	-- ResourcePullDown
	for type in GameInfo.Resources() do
		table.insert(m_ResourceTypeEntries, { Text=type.Name, Type=type, Class=type.ResourceClassType });
	end
	Controls.ResourcePullDown:SetEntries( m_ResourceTypeEntries, 1 );
	Controls.ResourcePullDown:SetEntrySelectedCallback( OnResourceTypeSelected );

	-- UnitPullDown
	for type in GameInfo.Units() do
		table.insert(m_UnitTypeEntries, { Text=type.Name, Type=type });
	end
	Controls.UnitPullDown:SetEntries( m_UnitTypeEntries, 1 );

	-- ImprovementPullDown and GoodyHutPullDown
	for type in GameInfo.Improvements() do
		table.insert(m_ImprovementTypeEntries, { Text=type.Name, Type=type });

		if type.ImprovementType == "IMPROVEMENT_GOODY_HUT" then
			table.insert(m_GoodyHutTypeEntries, { Text=type.Name, Type=type });
		end
	end
	Controls.ImprovementPullDown:SetEntries( m_ImprovementTypeEntries, 1 );
	Controls.GoodyHutPullDown:SetEntries( m_GoodyHutTypeEntries, 1 );

	-- RoutePullDown
	for type in GameInfo.Routes() do
		table.insert(m_RouteTypeEntries, { Text=type.Name, Type=type });
	end
	Controls.RoutePullDown:SetEntries( m_RouteTypeEntries, 1 );

	-- DistricPullDown
	for type in GameInfo.Districts() do
		if type.RequiresPlacement == true then
			table.insert(m_DistrictTypeEntries, { Text=type.Name, Type=type });
		end
	end
	Controls.DistrictPullDown:SetEntries( m_DistrictTypeEntries, 1 );

	-- BuildingPullDown
	for type in GameInfo.Buildings() do
		if type.RequiresPlacement ~= true then
			table.insert(m_BuildingTypeEntries, { Text=type.Name, Type=type });
		end
    end
	Controls.BuildingPullDown:SetEntries( m_BuildingTypeEntries, 1 );

	-- VisibilityPullDown
	Controls.VisibilityPullDown:SetEntrySelectedCallback( OnVisibilityPlayerChanged );
	Controls.VisibilityRevealAllButton:RegisterCallback( Mouse.eLClick, OnVisibilityPlayerRevealAll );

	-- Brush size
	Controls.BrushPullDown:SetEntries( m_BrushSizeEntries, 1 );
	Controls.BrushPullDown:SetEntrySelectedCallback( OnBrushSizeChanged );

	-- Clear and Generate Resources Buttons
	Controls.RegenResourcesButton:RegisterCallback(Mouse.eLClick, OnRegenResources);
	Controls.GenResourcesButton:RegisterCallback(Mouse.eLClick, OnGenResources);

	-- Register for events
	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetHideHandler( OnHide );
	Events.LoadGameViewStateDone.Add( OnLoadGameViewStateDone );
	LuaEvents.WorldInput_WBSelectPlot.Add( OnPlotSelected );
	LuaEvents.WorldInput_WBMouseOverPlot.Add( OnPlotMouseOver );

	Events.CityAddedToMap.Add( UpdateCityEntries );
	Events.CityRemovedFromMap.Add( UpdateCityEntries );

	Events.WorldBuilderSignal.Add( OnWorldBuilderSignal );
	LuaEvents.WorldBuilderModeChangeRequest.Add( OnWorldBuilderModeChangeRequest );

	LuaEvents.WorldBuilder_PlayerAdded.Add( UpdatePlayerEntries );
	LuaEvents.WorldBuilder_PlayerRemoved.Add( UpdatePlayerEntries );
	LuaEvents.WorldBuilder_PlayerEdited.Add( UpdatePlayerEntries );
	LuaEvents.WorldBuilder_ModeChanged.Add( OnAdvancedModeChanged );

end
ContextPtr:SetInitHandler( OnInit );