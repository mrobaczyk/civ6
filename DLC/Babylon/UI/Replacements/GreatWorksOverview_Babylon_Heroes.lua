-- Copyright 2020, Firaxis Games

-- This file is being included into the base GreatWorksOverview file using the wildcard include setup in GreatWorksOverview.lua
-- Refer to the bottom of GreatWorksOverview.lua to see how that's happening
-- DO NOT include any GreatWorksOverview files here or it will cause problems
-- include("GreatWorksOverview");

g_DEFAULT_GREAT_WORKS_ICONS["GREATWORKSLOT_HERO"] = "ICON_GREATWORKOBJECT_HERO";

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_GetGreatWorkTooltip = GetGreatWorkTooltip;

-- ===========================================================================
function GetGreatWorkTooltip(pCityBldgs:table, greatWorkIndex:number, greatWorkType:number, pBuildingInfo:table)
	local kGreatWorkInfo:table = GameInfo.GreatWorks[greatWorkType];

	-- Return the basic tooltip for Hero relics because the theming code in the base game can cause errors with them
	if kGreatWorkInfo.GreatWorkObjectType == "GREATWORKOBJECT_HERO" then
		return GreatWorksSupport_GetBasicTooltip( greatWorkIndex, false );
	end

	return BASE_GetGreatWorkTooltip(pCityBldgs, greatWorkIndex, greatWorkType, pBuildingInfo);
end