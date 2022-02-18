-- Copyright 2020, Firaxis Games

-- ===========================================================================
--	Filter out base items from the list that also contain a replacement,
--  or which are excluded entirely (with no replacement) by a player trait.
--  This method does NOT maintain ordering.
-- ===========================================================================
function RemoveReplacedUnlockables(kUnlockables:table, playerId:number) 
	local kHasTraitMap:table = GetTraitMapForPlayer(playerId);
	
	local kUnlockMap:table = {};
	for i,v in ipairs(kUnlockables) do
		kUnlockMap[v[2]] = v;
	end

	for row in GameInfo.BuildingReplaces() do
		-- Only show the original buildings in the tech tree instead of the secret society building replacements
		if(row.CivUniqueBuildingType == "BUILDING_ALCHEMICAL_SOCIETY") or (row.CivUniqueBuildingType == "BUILDING_GILDED_VAULT") then
			kUnlockMap[row.CivUniqueBuildingType] = nil;
		elseif(kUnlockMap[row.CivUniqueBuildingType]) then
			kUnlockMap[row.ReplacesBuildingType] = nil;
		end
	end

	for row in GameInfo.DistrictReplaces() do
		if(kUnlockMap[row.CivUniqueDistrictType]) then
			kUnlockMap[row.ReplacesDistrictType] = nil;
		end
	end

	for row in GameInfo.ExcludedDistricts() do
		if(kHasTraitMap[row.TraitType]) then
			kUnlockMap[row.DistrictType] = nil;
		end
	end

	for row in GameInfo.UnitReplaces() do
		if(kUnlockMap[row.CivUniqueUnitType]) then
			kUnlockMap[row.ReplacesUnitType] = nil;
		end
	end
	
	local kResults:table = {};
	for k,v in pairs(kUnlockables) do
		if(kUnlockMap[v[2]])then
			table.insert(kResults, v);
		end
	end

	return kResults;
end