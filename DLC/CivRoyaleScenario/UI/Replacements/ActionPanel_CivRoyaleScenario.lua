-- Copyright 2020, Firaxis Games

include( "ActionPanel" );

BASE_OnRefresh = OnRefresh;
BASE_LateInitialize = LateInitialize;

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function OnRefresh()
	local pPlayerConfig : table = PlayerConfigurations[Game.GetLocalPlayer()];
	ContextPtr:ClearRequestRefresh();
	if(pPlayerConfig ~= nil and not pPlayerConfig:IsAlive())then
		LuaEvents.ActionPanel_ObserverModeTurnBegin();
	else
		BASE_OnRefresh();
	end
end

function LateInitialize()
	BASE_LateInitialize();
	ContextPtr:SetRefreshHandler( OnRefresh );	
end