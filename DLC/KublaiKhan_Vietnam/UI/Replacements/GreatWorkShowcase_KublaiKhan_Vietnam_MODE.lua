-- Copyright 2020, Firaxis Games

-- This file is being included into the base GreatWorkShowcase file using the wildcard include setup in GreatWorkShowcase.lua
-- Refer to the bottom of GreatWorkShowcase.lua to see how that's happening
-- DO NOT include any GreatWorkShowcase files here or it will cause problems

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_HandleCustomGreatWorkTypes = HandleCustomGreatWorkTypes;
local BASE_Initialize = Initialize;

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local PADDING_BANNER:number = 120;
local SIZE_BANNER_MIN:number = 506;

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_ResourceTypeMap    	:table  = {};

-- ===========================================================================
function HandleCustomGreatWorkTypes( greatWorkType:string, greatWorkIndex:number )

	local kGreatWorkInfo:table = GameInfo.GreatWorks[greatWorkType];
	local greatWorkType:string = kGreatWorkInfo.GreatWorkType;
	local greatWorkObjectType:string = kGreatWorkInfo.GreatWorkObjectType;

	-- Only Product great work objects should be by this override
	if greatWorkObjectType ~= "GREATWORKOBJECT_PRODUCT" then
		return BASE_HandleCustomGreatWorkTypes(greatWorkType);
	end

	greatWorkType = greatWorkType:gsub("GREATWORK_PRODUCT_", "");
	local greatWorkTrunc:string = greatWorkType:sub(1, #greatWorkType - 2);	-- remove the _1/_2/_3/_4/_5 from the end

	local icon:string = "ICON_MONOPOLIES_AND_CORPS_RESOURCE_" .. greatWorkTrunc;
	Controls.GreatWorkImage:SetOffsetY(0);
	Controls.GreatWorkImage:SetIcon(icon, 256);

	Controls.GreatWorkName:SetText(Locale.ToUpper(kGreatWorkInfo.Name));
	local nameSize:number = Controls.GreatWorkName:GetSizeX() + PADDING_BANNER;
	local bannerSize:number = math.max(nameSize, SIZE_BANNER_MIN);
	Controls.GreatWorkBanner:SetSizeX(bannerSize);
	Controls.GreatWorkBanner:SetHide(false);

	local resName:string = "RESOURCE_"..greatWorkTrunc;
	local corpName:string = nil;
	for num,txt in ipairs(m_ResourceTypeMap) do
		if txt == resName then
			corpName = Game.GetEconomicManager():GetCorporationName(Game.GetLocalPlayer(), num);
			break;
		end
	end

	if corpName ~= nil then
		if corpName == "" then
			corpName = Locale.Lookup("LOC_IMPROVEMENT_CORPORATION_TYPE_NAME", Locale.Lookup("LOC_"..resName.."_NAME"));
		end
	else
		corpName = Locale.Lookup("LOC_IMPROVEMENT_CORPORATION_TYPE_NAME", Locale.Lookup("LOC_"..resName.."_NAME"));
	end
	Controls.CreatedBy:SetText(Locale.Lookup("LOC_GREAT_WORKS_CREATED_BY", corpName));

	return true;
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

