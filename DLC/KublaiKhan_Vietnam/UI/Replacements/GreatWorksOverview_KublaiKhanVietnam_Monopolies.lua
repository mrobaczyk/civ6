-- Copyright 2020, Firaxis Games

-- This file is being included into the base GreatWorksOverview file using the wildcard include setup in GreatWorksOverview.lua
-- Refer to the bottom of GreatWorksOverview.lua to see how that's happening
-- DO NOT include any GreatWorksOverview files here or it will cause problems
-- include("GreatWorksOverview");

g_DEFAULT_GREAT_WORKS_ICONS["GREATWORKSLOT_PRODUCT"] = "ICON_GREATWORKOBJECT_PRODUCT";

local SIZE_GREAT_WORK_ICON:number = 64;

local YIELD_FONT_ICONS:table = {
	YIELD_FOOD				= "[ICON_FoodLarge]",
	YIELD_PRODUCTION		= "[ICON_ProductionLarge]",
	YIELD_GOLD				= "[ICON_GoldLarge]",
	YIELD_SCIENCE			= "[ICON_ScienceLarge]",
	YIELD_CULTURE			= "[ICON_CultureLarge]",
	YIELD_FAITH				= "[ICON_FaithLarge]",
};

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_ResourceTypeMap    	:table  = {};

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_GetGreatWorkIcon = GetGreatWorkIcon;
local BASE_GetGreatWorkTooltip = GetGreatWorkTooltip;
local BASE_Initialize = Initialize;

-- ===========================================================================
function GetGreatWorkIcon(greatWorkInfo:table)

	local greatWorkIcon:string;

	if greatWorkInfo.GreatWorkObjectType == "GREATWORKOBJECT_PRODUCT" then
		local greatWorkType:string = greatWorkInfo.GreatWorkType;
		greatWorkType = greatWorkType:gsub("GREATWORK_PRODUCT_", "");
		local greatWorkTrunc:string = greatWorkType:sub(1, #greatWorkType - 2);	-- remove the _1/_2/_3/_4/_5 from the end
		greatWorkIcon = "ICON_MONOPOLIES_AND_CORPS_RESOURCE_" .. greatWorkTrunc;

		local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(greatWorkIcon, SIZE_GREAT_WORK_ICON);
		if(textureSheet == nil or textureSheet == "") then
			UI.DataError("Could not find slot type icon in GetGreatWorkIcon: icon=\""..greatWorkIcon.."\", iconSize="..tostring(SIZE_GREAT_WORK_ICON));
		end

		return textureOffsetX, textureOffsetY, textureSheet;
	end

	return BASE_GetGreatWorkIcon(greatWorkInfo);
end

function GetGreatWorkTooltip(pCityBldgs:table, greatWorkIndex:number, greatWorkType:number, pBuildingInfo:table)
	local greatWorkTypeName:string;
	local greatWorkInfo:table = GameInfo.GreatWorks[greatWorkType];

	if greatWorkInfo.GreatWorkObjectType == "GREATWORKOBJECT_PRODUCT" then
		local greatWorkType:string = greatWorkInfo.GreatWorkType;
		greatWorkType = greatWorkType:gsub("GREATWORK_PRODUCT_", "");
		local greatWorkTrunc:string = greatWorkType:sub(1, #greatWorkType - 2);	-- remove the _1/_2/_3/_4/_5 from the end
		local resName:string = "RESOURCE_"..greatWorkTrunc;
		local corpName:string = nil;
		for num,txt in ipairs(m_ResourceTypeMap) do
			if txt == resName then
				corpName = Game.GetEconomicManager():GetCorporationName(Game.GetLocalPlayer(), num);
				break;
			end
		end

		if corpName == nil then
			corpName = Locale.Lookup("LOC_IMPROVEMENT_CORPORATION_NAME", Locale.Lookup("LOC_"..resName.."_NAME"));
		end

		if corpName == "" then
			corpName = Locale.Lookup("LOC_IMPROVEMENT_CORPORATION_NAME", Locale.Lookup("LOC_"..resName.."_NAME"));
		end

		local tInstInfo:table = Game.GetGreatWorkDataFromIndex(greatWorkIndex);
		local tStaticInfo:table = GameInfo.GreatWorks[tInstInfo.GreatWorkType];
		local strName:string = Locale.Lookup(tStaticInfo.Name);
		local strDateCreated:string = Calendar.MakeDateStr(tInstInfo.TurnCreated, GameConfiguration.GetCalendarType(), GameConfiguration.GetGameSpeedType(), false);

		local strYields :string = tostring(tStaticInfo.Tourism) .. " [ICON_TourismLarge] " .. Locale.Lookup("LOC_PEDIA_CONCEPTS_PAGEGROUP_TOURISM_NAME");
		for row in GameInfo.GreatWork_YieldChanges() do
			if(row.GreatWorkType == tStaticInfo.GreatWorkType) then
				strYields = tostring(row.YieldChange) .. " " .. YIELD_FONT_ICONS[row.YieldType] ..  " " .. Locale.Lookup("LOC_"..row.YieldType.."_NAME")..", "..strYields;
				break;
			end
		end

		if tStaticInfo.EraType ~= nil then
			strTypeName = Locale.Lookup("LOC_" .. tStaticInfo.GreatWorkObjectType .. "_" .. tStaticInfo.EraType);
		else
			strTypeName = Locale.Lookup("LOC_" .. tStaticInfo.GreatWorkObjectType);
		end

		local bIsArtifact :boolean = tStaticInfo.GreatWorkObjectType == "GREATWORKOBJECT_ARTIFACT";

		-- Tooltip localization key structure: LOC_GREAT_WORKS[_ARTIFACT]_TOOLTIP[_THEMABLE]
		local strLocKeyArtifact :string = bIsArtifact and "_ARTIFACT" or "";
		local strLocKeyThemable :string = bIsThemeable and "_THEMABLE" or "";
		local strTooltipLocKey	:string = "LOC_GREAT_WORKS" .. strLocKeyArtifact .. "_TOOLTIP" .. strLocKeyThemable;
		local strFinalTooltip   :string = Locale.Lookup(strTooltipLocKey, strName, strTypeName, corpName, strDateCreated, strYields);

		local corpEffectStr:string = nil;
		for row in GameInfo.ResourceIndustries() do
			if row.PrimaryKey == resName then
				strFinalTooltip = strFinalTooltip..Locale.Lookup(row.ResourceEffectTExt);
				break;
			end
		end

		return strFinalTooltip;
	else
		return BASE_GetGreatWorkTooltip(pCityBldgs, greatWorkIndex, greatWorkType, pBuildingInfo);
	end
end

function Initialize()
	BASE_Initialize();

	m_ResourceTypeMap = {};
	do
		for row in GameInfo.Resources() do
			m_ResourceTypeMap[row.Index] = row.ResourceType;
		end
	end
end

