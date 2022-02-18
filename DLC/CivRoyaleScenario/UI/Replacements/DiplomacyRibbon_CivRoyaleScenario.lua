-- Copyright 2018-2019, Firaxis Games.

include("DiplomacyRibbon.lua");
include("Civ6Common.lua");


-- ===========================================================================
BASE_AddLeader = AddLeader;


-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function AddLeader(iconName : string, playerID : number, kProps: table)
	local leaderIcon, uiLeader = BASE_AddLeader(iconName, playerID, kProps );

	local pPlayerConfig :table	= PlayerConfigurations[playerID];
	local civType		:string = pPlayerConfig:GetCivilizationTypeName();
	local CivUniqueAbilities, _, _ = GetCivilizationUniqueTraits( civType );

	local tt:string = "";
	for _, item in ipairs(CivUniqueAbilities) do
		if (item.Name ~= nil and item.Name ~= "NONE") then
			tt = tt..tostring( Locale.Lookup( item.Description ) );
		end
	end
	if tt ~= "" then tt = "[NEWLINE]"..tt; end	-- If info is added, add an extra line.

	leaderIcon:AppendTooltip( tt );
end