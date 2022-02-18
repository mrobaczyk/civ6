--	Copyright 2020, Firaxis Games

include("TopPanel");

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_RefreshTurnsRemaining = RefreshTurnsRemaining;

local startYear : number = 1620;

-- ===========================================================================
function RefreshTurnsRemaining()

	BASE_RefreshTurnsRemaining();

	local startTurn : number = GameConfiguration.GetStartTurn();
	local currentYear : number = Game.GetCurrentGameTurn() + startYear - startTurn + 1;
	Controls.CurrentDate:SetText(tostring(currentYear) .. " AD");
end