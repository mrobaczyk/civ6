-- Copyright 2021, Firaxis Games

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
BARBARIANS_FetchData = FetchData;
BARBARIANS_GetPlotSearchTerms = GetPlotSearchTerms;

-- ===========================================================================
-- OVERRIDE BASE FUNCTIONS
-- ===========================================================================
function GetPlotSearchTerms(data)
	-- Get the original search terms
	local pSearchTerms : table = BARBARIANS_GetPlotSearchTerms(data);

	if(data.TribeName ~= "")then
		table.insert(pSearchTerms, Locale.Lookup("LOC_"..data.TribeName));
	end

	return pSearchTerms;
end

-- ===========================================================================
function FetchData(plot)
	-- Get the original plot data
	local data = BARBARIANS_FetchData(plot);
	data.TribeName = "";

	local pBarbarianManager : table = Game.GetBarbarianManager();
	local tribeIndex : number = pBarbarianManager:GetTribeIndexAtLocation(plot:GetX(),plot:GetY());
	if(tribeIndex >= 0)then
		local barbType : number = pBarbarianManager:GetTribeNameType(tribeIndex);
		local pBarbTribe : table = GameInfo.BarbarianTribeNames[barbType];
		data.TribeName = pBarbTribe.TribeNameType;
	end

	return data;
end
