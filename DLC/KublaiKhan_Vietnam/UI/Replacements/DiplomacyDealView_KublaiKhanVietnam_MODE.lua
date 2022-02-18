local KUBLAIKHANVIETNAM_MODE_GetGreatWorkIcon = GetGreatWorkIcon;

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