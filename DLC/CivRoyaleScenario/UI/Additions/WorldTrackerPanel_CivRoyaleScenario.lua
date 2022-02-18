--	Copyright 2019, Firaxis Games

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local DANGER_ZONE_INTERVAL:number = -1;	-- Value set by game script
local DANGER_ZONE_SPEED:number = -1;	-- Value set by game script
local DANGER_ZONE_DELAY:number = -1;	-- Value set by game script

-- ===========================================================================
function Realize()
	local turn		:number = Game.GetCurrentGameTurn();
	local turnsLeft	:number = Game:GetProperty("NextSafeZoneTurn");
	local turnsStart:number	= Game:GetProperty("StartSafeZoneTurn");
	local safeZonePhase:number = Game:GetProperty("SafeZonePhase");
	Controls.BoundryValue:SetText( turnsLeft - turn);
	Controls.CountdownMeter:SetPercent( 1 - ((turnsLeft - turn) / turnsStart) );

	local pFalloutManager = Game.GetFalloutManager();
	local falloutDamage :number = pFalloutManager:GetFalloutDamageOverride();
	if(falloutDamage == FalloutDamages.USE_FALLOUT_DEFAULT or falloutDamage == nil) then 
		falloutDamage = 0;
	end
	Controls.StormStrengthLabel:LocalizeAndSetText("LOC_CIV_ROYALE_HUD_STORM_STRENGTH", safeZonePhase, falloutDamage);
end

-- ===========================================================================
function OnLocalPlayerTurnBegin()
	Realize();
end

-- ===========================================================================
function OnShutdown()
	Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin);
end

-- ===========================================================================
function OnInit()
	-- Read values set by game script.
	DANGER_ZONE_INTERVAL = Game:GetProperty("DANGER_ZONE_INTERVAL");
	DANGER_ZONE_SPEED = Game:GetProperty("DANGER_ZONE_SPEED");
	DANGER_ZONE_DELAY = Game:GetProperty("DANGER_ZONE_DELAY");		

	Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin);

	Realize();	
end

-- ===========================================================================
function Initialize()
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetShutdown( OnShutdown );
	ContextPtr:SetAutoSize(true);
end
Initialize();