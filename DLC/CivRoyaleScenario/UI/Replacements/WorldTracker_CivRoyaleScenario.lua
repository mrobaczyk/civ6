-- Copyright 2019, Firaxis Games

include("WorldTracker");

--	CACHE BASE FUNCTIONS
BASE_LateInitialize = LateInitialize;


-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function LateInitialize()
	BASE_LateInitialize();
	if GameConfiguration.IsHotseat() or GameConfiguration.IsPlayByCloud() then
		ContextPtr:SetHide( true );
	end
end
