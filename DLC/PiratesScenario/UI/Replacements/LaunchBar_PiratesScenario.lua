-- ===========================================================================
--	HUD's "Launch Bar"
--	Copyright (c) 2017-2019 Firaxis Games
--
--	Controls raising full-screen and "choosers" found in upper-left of HUD.
-- ===========================================================================
include( "LaunchBar" );

BASE_LateInitialize = LateInitialize;
BASE_OnCivicCompleted = OnCivicCompleted;
BASE_RefreshGovernment = RefreshGovernment;

local m_relicScreenShownSinceLastUnlock : boolean = false;

-- ===========================================================================
function RefreshGovernment()
	BASE_RefreshGovernment();

	local playerID:number = Game.GetLocalPlayer();
	if playerID == -1 then return; end

	local kCulture:table = Players[playerID]:GetCulture();

	ShowFreePolicyFlag( kCulture:GetCostToUnlockPolicies() == 0 and not kCulture:PolicyChangeMade() and not m_relicScreenShownSinceLastUnlock);
end

-- ===========================================================================
function OnRelicScreenOpened()
	m_relicScreenShownSinceLastUnlock = true;
	RefreshGovernment();
end

-- ===========================================================================
function OnCivicCompleted()
	BASE_OnCivicCompleted();
	m_relicScreenShownSinceLastUnlock = false;
end

-- ===========================================================================
function LateInitialize()
	BASE_LateInitialize();

	LuaEvents.RelicScreen_RelicScreenOpened.Add(function() OnRelicScreenOpened(); end);
end