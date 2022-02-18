-- Copyright 2020-2021, Firaxis Games
include "PlotTooltip";

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================

-- ===========================================================================
-- OVERRIDE BASE FUNCTIONS
-- ===========================================================================
function GetDetails(data)
	local details = {};

	if(data.Owner ~= nil) then

		local szOwnerString;

		local pPlayerConfig = PlayerConfigurations[data.Owner];
		if (pPlayerConfig ~= nil) then
			szOwnerString = Locale.Lookup(pPlayerConfig:GetCivilizationShortDescription());
		end

		if (szOwnerString == nil or string.len(szOwnerString) == 0) then
			szOwnerString = Locale.Lookup("LOC_TOOLTIP_PLAYER_ID", data.Owner);
		end

		local pPlayer = Players[data.Owner];
		if(GameConfiguration:IsAnyMultiplayer() and pPlayer:IsHuman()) then
			szOwnerString = szOwnerString .. " (" .. Locale.Lookup(pPlayerConfig:GetPlayerName()) .. ")";
		end

		table.insert(details, Locale.Lookup("LOC_TOOLTIP_CITY_OWNER",szOwnerString, data.OwningCityName));
	end

	if(data.FeatureType ~= nil) then
		local szFeatureString = Locale.Lookup(GameInfo.Features[data.FeatureType].Name);
		local localPlayer = Players[Game.GetLocalPlayer()];
		local addCivicName = GameInfo.Features[data.FeatureType].AddCivic;
		if (localPlayer ~= nil and addCivicName ~= nil) then
			local civicIndex = GameInfo.Civics[addCivicName].Index;
			if (localPlayer:GetCulture():HasCivic(civicIndex)) then
			    local szAdditionalString;
				if (not data.FeatureAdded) then
					szAdditionalString = Locale.Lookup("LOC_TOOLTIP_PLOT_WOODS_OLD_GROWTH");
				else
					szAdditionalString = Locale.Lookup("LOC_TOOLTIP_PLOT_WOODS_SECONDARY");
				end
				szFeatureString = szFeatureString .. " " .. szAdditionalString;
			end
		end
		table.insert(details, szFeatureString);
	end
	if(data.NationalPark ~= "") then
		table.insert(details, data.NationalPark);
	end

	if(data.ResourceType ~= nil) then
		--if it's a resource that requires a tech to improve, let the player know that in the tooltip
		local resourceType = data.ResourceType;
		local resource = GameInfo.Resources[resourceType];
		local resourceHash = GameInfo.Resources[resourceType].Hash;

		local resourceString = Locale.Lookup(resource.Name);
		local resourceTechType;

		local terrainType = data.TerrainType;
		local featureType = data.FeatureType;

		local valid_feature = false;
		local valid_terrain = false;
		local valid_resources = false;

		-- Are there any improvements that specifically require this resource?
		for row in GameInfo.Improvement_ValidResources() do
			if (row.ResourceType == resourceType) then
				-- Found one!  Now.  Can it be constructed on this terrain/feature
				local improvementType = row.ImprovementType;
				local has_feature = false;
				for inner_row in GameInfo.Improvement_ValidFeatures() do
					if(inner_row.ImprovementType == improvementType) then
						has_feature = true;
						if(inner_row.FeatureType == featureType) then
							valid_feature = true;
						end
					end
				end
				valid_feature = not has_feature or valid_feature;

				local has_terrain = false;
				for inner_row in GameInfo.Improvement_ValidTerrains() do
					if(inner_row.ImprovementType == improvementType) then
						has_terrain = true;
						if(inner_row.TerrainType == terrainType) then
							valid_terrain = true;
						end
					end
				end
				valid_terrain = not has_terrain or valid_terrain;
				
				-- if we match the resource in Improvement_ValidResources it's a get-out-of-jail-free card for feature and terrain checks
				for inner_row in GameInfo.Improvement_ValidResources() do
					if(inner_row.ImprovementType == improvementType) then
						if(inner_row.ResourceType == resourceType) then
							valid_resources = true;
							break;
						end
					end
				end

				if( terrainType ~= nil and GameInfo.Terrains[terrainType].TerrainType  == "TERRAIN_COAST") then
					if ("DOMAIN_SEA" == GameInfo.Improvements[improvementType].Domain) then
						valid_terrain = true;
					elseif ("DOMAIN_LAND" == GameInfo.Improvements[improvementType].Domain) then
						valid_terrain = false;
					end
				else
					if ("DOMAIN_SEA" == GameInfo.Improvements[improvementType].Domain) then
						valid_terrain = false;
					elseif ("DOMAIN_LAND" == GameInfo.Improvements[improvementType].Domain) then
						valid_terrain = true;
					end
				end

				if ((valid_feature == true and valid_terrain == true) or valid_resources == true) then
					resourceTechType = GameInfo.Improvements[improvementType].PrereqTech;
					break;
				end
			end
		end
		local localPlayer = Players[Game.GetLocalPlayer()];
		if (localPlayer ~= nil) then
			local playerResources = localPlayer:GetResources();
			if(playerResources:IsResourceVisible(resourceHash)) then
				if (resourceTechType ~= nil and ((valid_feature == true and valid_terrain == true) or valid_resources == true)) then
					local playerTechs	= localPlayer:GetTechs();
					local techType = GameInfo.Technologies[resourceTechType];
					if (techType ~= nil and not playerTechs:HasTech(techType.Index)) then
						resourceString = resourceString .. "[COLOR:Civ6Red]  ( " .. Locale.Lookup("LOC_TOOLTIP_REQUIRES") .. " " .. Locale.Lookup(techType.Name) .. ")[ENDCOLOR]";
					end
				end

				table.insert(details, resourceString);
			end
		elseif m_isWorldBuilder then
			if (resourceTechType ~= nil and ((valid_feature == true and valid_terrain == true) or valid_resources == true)) then
				local techType = GameInfo.Technologies[resourceTechType];
				if (techType ~= nil) then
					resourceString = resourceString .. "( " .. Locale.Lookup("LOC_TOOLTIP_REQUIRES") .. " " .. Locale.Lookup(techType.Name) .. ")[ENDCOLOR]";
				end
			end
			table.insert(details, resourceString);
		end
	end
	
	if (data.IsRiver == true) then
		table.insert(details, Locale.Lookup("LOC_TOOLTIP_RIVER"));
	end

	if (data.IsNWOfCliff or data.IsWOfCliff or data.IsNEOfCliff) then
		table.insert(details, Locale.Lookup("LOC_TOOLTIP_CLIFF"));
	end

	-- Movement cost
	if (not data.Impassable and data.MovementCost > 0) then
		table.insert(details, Locale.Lookup("LOC_TOOLTIP_MOVEMENT_COST", data.MovementCost));
	end

	-- ROUTE TILE
	if (data.IsRoute) then
		local routeInfo = GameInfo.Routes[data.RouteType];
		if (routeInfo ~= nil and routeInfo.MovementCost ~= nil and routeInfo.Name ~= nil) then
			
			local str;
			if(data.RoutePillaged) then
				str = Locale.Lookup("LOC_TOOLTIP_ROUTE_MOVEMENT_PILLAGED", routeInfo.MovementCost, routeInfo.Name);
			else
				str = Locale.Lookup("LOC_TOOLTIP_ROUTE_MOVEMENT", routeInfo.MovementCost, routeInfo.Name);
			end

			table.insert(details, str);
		end		
	end

	-- Defense modifier
	if (data.DefenseModifier ~= 0) then
		table.insert(details, Locale.Lookup("LOC_TOOLTIP_DEFENSE_MODIFIER", data.DefenseModifier));
	end

	-- Appeal
	local feature = nil;
	if (data.FeatureType ~= nil) then
	    feature = GameInfo.Features[data.FeatureType];
	end
		
	if GameCapabilities.HasCapability("CAPABILITY_LENS_APPEAL") then
		if ((data.FeatureType ~= nil and feature.NaturalWonder) or not data.IsWater) then
			local strAppealDescriptor;
			for row in GameInfo.AppealHousingChanges() do
				local iMinimumValue = row.MinimumValue;
				local szDescription = row.Description;
				if (data.Appeal >= iMinimumValue) then
					strAppealDescriptor = Locale.Lookup(szDescription);
					break;
				end
			end
			if(strAppealDescriptor) then
				table.insert(details, Locale.Lookup("LOC_TOOLTIP_APPEAL", strAppealDescriptor, data.Appeal));
			end
		end
	end

	-- Do not include ('none') continent line unless continent plot. #35955
	if (data.Continent ~= nil) then
		table.insert(details, Locale.Lookup("LOC_TOOLTIP_CONTINENT", GameInfo.Continents[data.Continent].Description));
	end

	-- Conditional display based on tile type

	-- WONDER TILE
	if(data.WonderType ~= nil) then
		
		table.insert(details, "------------------");
		
		if (data.WonderComplete == true) then
			table.insert(details, Locale.Lookup(GameInfo.Buildings[data.WonderType].Name));

		else

			table.insert(details, Locale.Lookup(GameInfo.Buildings[data.WonderType].Name) .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT"));
		end
	end

	-- CITY TILE
	if(data.IsCity == true and data.DistrictType ~= nil) then
		
		table.insert(details, "------------------");
		
		table.insert(details, Locale.Lookup(GameInfo.Districts[data.DistrictType].Name))

		for yieldType, v in pairs(data.Yields) do
			local yield = GameInfo.Yields[yieldType].Name;
			local yieldicon = GameInfo.Yields[yieldType].IconString;
			local str = tostring(v) .. Locale.Lookup(yieldicon) .. Locale.Lookup(yield);
			table.insert(details, str);
		end

	-- DISTRICT TILE
	elseif(data.DistrictID ~= -1 and data.DistrictType ~= nil) then
		if (not GameInfo.Districts[data.DistrictType].InternalOnly) then	--Ignore 'Wonder' districts
			-- Plot yields (ie. from Specialists)
			if (data.Yields ~= nil) then
				if (table.count(data.Yields) > 0) then
					table.insert(details, "------------------");
					table.insert(details, Locale.Lookup("LOC_PEDIA_CONCEPTS_PAGE_CITIES_9_CHAPTER_CONTENT_TITLE")); -- "Specialists", text lock :'()
				end
				for yieldType, v in pairs(data.Yields) do
					local yield = GameInfo.Yields[yieldType].Name;
					local yieldicon = GameInfo.Yields[yieldType].IconString;
					local str = tostring(v) .. Locale.Lookup(yieldicon) .. Locale.Lookup(yield);
					table.insert(details, str);
				end
			end

			-- Inherent district yields
			local sDistrictName :string = Locale.Lookup(Locale.Lookup(GameInfo.Districts[data.DistrictType].Name));
			if (data.DistrictPillaged) then
				sDistrictName = sDistrictName .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT");
			elseif (not data.DistrictComplete) then
				sDistrictName = sDistrictName .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT");
			end
			table.insert(details, "------------------");
			table.insert(details, sDistrictName);
			if (data.DistrictYields ~= nil) then
				for yieldType, v in pairs(data.DistrictYields) do
					local yield = GameInfo.Yields[yieldType].Name;
					local yieldicon = GameInfo.Yields[yieldType].IconString;
					local str = tostring(v) .. Locale.Lookup(yieldicon) .. Locale.Lookup(yield);
					table.insert(details, str);
				end
			end
		end
				
	-- IMPASSABLE TILE
	elseif(data.Impassable == true) then
		table.insert(details, Locale.Lookup("LOC_TOOLTIP_PLOT_IMPASSABLE_TEXT"));

	-- OTHER TILE
	else
		table.insert(details, "------------------");
		if(data.ImprovementType ~= nil) then
			local improvementStr = Locale.Lookup(GameInfo.Improvements[data.ImprovementType].Name);
			if (data.ImprovementPillaged) then
				improvementStr = improvementStr .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT");
			end
			table.insert(details, improvementStr)

				-- Barbarian Clan Info
			if (data.ImprovementType == "IMPROVEMENT_BARBARIAN_CAMP") then
				local pBarbManager = Game.GetBarbarianManager();
				local iTribeIndex = pBarbManager:GetTribeIndexAtLocation(data.X, data.Y);
				if (iTribeIndex >= 0) then
					local eTribeName = pBarbManager:GetTribeNameType(iTribeIndex);
					if (GameInfo.BarbarianTribeNames[eTribeName] ~= nil) then
						local tribeNameStr = Locale.Lookup("LOC_TOOLTIP_BARBARIAN_CLAN_NAME", GameInfo.BarbarianTribeNames[eTribeName].TribeDisplayName);
						table.insert(details, tribeNameStr);
					end
				end
			end
		end
		
		for yieldType, v in pairs(data.Yields) do
			local yield = GameInfo.Yields[yieldType].Name;
			local yieldicon = GameInfo.Yields[yieldType].IconString;
			local str = tostring(v) .. Locale.Lookup(yieldicon) .. Locale.Lookup(yield);
			table.insert(details, str);
		end
	end

	-- NATURAL WONDER TILE
	if(data.FeatureType ~= nil) then
		if(feature.NaturalWonder) then
			table.insert(details, "------------------");
			table.insert(details, Locale.Lookup(feature.Description));
		end
	end
	
	-- For districts, city center show all building info including Great Works
	-- For wonders, just show Great Work info
	if (data.IsCity or data.WonderType ~= nil or data.DistrictID ~= -1) then
		if(data.BuildingNames ~= nil and table.count(data.BuildingNames) > 0) then
			local cityBuildings = data.OwnerCity:GetBuildings();
			if (data.WonderType == nil) then
				table.insert(details, Locale.Lookup("LOC_TOOLTIP_PLOT_BUILDINGS_TEXT"));
			end
			local greatWorksSection: table = {};
			for i, v in ipairs(data.BuildingNames) do 
			    if (data.WonderType == nil) then
					if (data.BuildingsPillaged[i]) then
						table.insert(details, "- " .. Locale.Lookup(v) .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT"));
					else
						table.insert(details, "- " .. Locale.Lookup(v));
					end
				end
				local iSlots = cityBuildings:GetNumGreatWorkSlots(data.BuildingTypes[i]);
				for j = 0, iSlots - 1, 1 do
					local greatWorkIndex:number = cityBuildings:GetGreatWorkInSlot(data.BuildingTypes[i], j);
					if (greatWorkIndex ~= -1) then
						local greatWorkType:number = cityBuildings:GetGreatWorkTypeFromIndex(greatWorkIndex)
						table.insert(greatWorksSection, "- " .. Locale.Lookup(GameInfo.GreatWorks[greatWorkType].Name));
					end
				end
			end
			if #greatWorksSection > 0 then
				table.insert(details, Locale.Lookup("LOC_GREAT_WORKS") .. ":");
				for i, v in ipairs(greatWorksSection) do
					table.insert(details, v);
				end
			end
		end
	end

	-- Show number of civilians working here
	if (data.Owner == Game.GetLocalPlayer() and data.Workers > 0) then
		table.insert(details, Locale.Lookup("LOC_TOOLTIP_PLOT_WORKED_TEXT", data.Workers));
	end

	if (data.Fallout > 0) then
		table.insert(details, Locale.Lookup("LOC_TOOLTIP_PLOT_CONTAMINATED_TEXT", data.Fallout));
	end

	return details;
end