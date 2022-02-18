-- Copyright 2020, Firaxis Games

-- This file is being included into the base GreatWorkShowcase file using the wildcard include setup in GreatWorkShowcase.lua
-- Refer to the bottom of GreatWorkShowcase.lua to see how that's happening
-- DO NOT include any GreatWorkShowcase files here or it will cause problems

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_HandleCustomGreatWorkTypes = HandleCustomGreatWorkTypes;

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================

local GREAT_WORK_HERO_TYPE:string = "GREATWORKOBJECT_HERO";

local PADDING_BANNER:number = 120;
local SIZE_BANNER_MIN:number = 506;

-- ===========================================================================
function HandleCustomGreatWorkTypes( greatWorkType:string )

	local kGreatWorkInfo:table = GameInfo.GreatWorks[greatWorkType];
	local greatWorkType:string = kGreatWorkInfo.GreatWorkType;
	local greatWorkObjectType:string = kGreatWorkInfo.GreatWorkObjectType;

	-- Only Hero great work objects should be by this override
	if greatWorkObjectType ~= GREAT_WORK_HERO_TYPE then
		return BASE_HandleCustomGreatWorkTypes(greatWorkType);
	end

	local icon:string = "ICON_" .. greatWorkType;
	Controls.GreatWorkImage:SetOffsetY(0);
	Controls.GreatWorkImage:SetIcon(icon, 256);

	Controls.GreatWorkName:SetText(Locale.ToUpper(kGreatWorkInfo.Name));
	local nameSize:number = Controls.GreatWorkName:GetSizeX() + PADDING_BANNER;
	local bannerSize:number = math.max(nameSize, SIZE_BANNER_MIN);
	Controls.GreatWorkBanner:SetSizeX(bannerSize);
	Controls.GreatWorkBanner:SetHide(false);

	return true;
end