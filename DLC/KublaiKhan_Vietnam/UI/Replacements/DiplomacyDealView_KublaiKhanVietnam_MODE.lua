local KUBLAIKHANVIETNAM_MODE_GetGreatWorkIcon = GetGreatWorkIcon;
local KUBLAIKHANVIETNAM_MODE_GetGreatWorkTooltip = GetGreatWorkTooltip;
local KUBLAIKHANVIETNAM_MODE_Initialize = Initialize;

local m_ResourceTypeMap    	:table  = {};

-- ===========================================================================
function GetGreatWorkIcon( kGreatWorkDesc : table)
	-- we only handle products here
	if kGreatWorkDesc.GreatWorkObjectType ~= "GREATWORKOBJECT_PRODUCT" then
		return KUBLAIKHANVIETNAM_MODE_GetGreatWorkIcon(kGreatWorkDesc);
	end

	local greatWorkType:string = kGreatWorkDesc.GreatWorkType:gsub("GREATWORK_PRODUCT_", "");
	local greatWorkTrunc:string = greatWorkType:sub(1, #greatWorkType - 2);	-- remove the _1/_2/_3/_4/_5 from the end

	return "ICON_MONOPOLIES_AND_CORPS_RESOURCE_" .. greatWorkTrunc;
end

-- ===========================================================================
function GetGreatWorkTooltip(kGreatWorkDesc : table, defaultToolTip : string)
	-- we only handle products here
	if kGreatWorkDesc.GreatWorkObjectType ~= "GREATWORKOBJECT_PRODUCT" then
		return KUBLAIKHANVIETNAM_MODE_GetGreatWorkTooltip(GreatWorkDesc, defaultToolTip);
	end

	local greatWorkType:string = kGreatWorkDesc.GreatWorkType:gsub("GREATWORK_PRODUCT_", "");
	local resName:string = "RESOURCE_" .. greatWorkType:sub(1, #greatWorkType - 2);	-- remove the _1/_2/_3/_4/_5 from the end
	local effectStr:string = nil;
	for row in GameInfo.ResourceIndustries() do
		if row.PrimaryKey == resName then
			effectStr = row.ResourceEffectTExt;
			break;
		end
	end

	if effectStr ~= nil then
		return defaultToolTip.."[NEWLINE]"..Locale.Lookup(effectStr);
	end

	return defaultToolTip;
end

-- ===========================================================================
function Initialize()
	KUBLAIKHANVIETNAM_MODE_Initialize();

	m_ResourceTypeMap = {};
	do
		for row in GameInfo.Resources() do
			m_ResourceTypeMap[row.Index] = row.ResourceType;
		end
	end
end
