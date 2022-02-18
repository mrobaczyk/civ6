--	Copyright 2019, Firaxis Games

include( "InstanceManager" );
include( "SupportFunctions" ); 


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local DANGER_ZONE_INTERVAL	:number = -1;	-- Value set by game script
local DANGER_ZONE_SPEED		:number = -1;	-- Value set by game script
local DANGER_ZONE_DELAY		:number = -1;	-- Value set by game script
local MAX_PARTICLES			:number = 300;
local INVALID_TURNS			:number = -1;	-- This is the value used by "NextSafeZoneTurn" before initialization or when the safe zone will no longer shrink due to being at minimum size.


-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_kBracketIM :table = InstanceManager:new( "BracketInstance", "BracketTop", Controls.RingStack );
local m_kParticleIM :table = InstanceManager:new( "ParticleInstance", "ParticleTop", ContextPtr );
local m_kParticles	:table;


-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLocalPlayerChanged( playerID:number , prevLocalPlayerID:number )	
	RefreshAll();
end

-- ===========================================================================
function OnTurnBegin()
	-- Only want this update to occur when observing because it may run before
	-- the game has a chance to update it's values (may be 1 off).
	local localPlayerID :number = Game.GetLocalPlayer();
	if localPlayerID == PlayerTypes.OBSERVER  or localPlayerID == PlayerTypes.NONE then 
		RefreshAll();
	end
end

-- ===========================================================================
function OnMenu()
	LuaEvents.InGame_OpenInGameOptionsMenu();
end


-- ===========================================================================
function RefreshTime()
	local format = UserConfiguration.GetClockFormat();
	
	local strTime;
	
	if(format == 1) then
		strTime = os.date("%H:%M");
	else
		strTime = os.date("%I:%M %p");

		-- Remove the leading zero (if any) from 12-hour clock format
		if(string.sub(strTime, 1, 1) == "0") then
			strTime = string.sub(strTime, 2);
		end
	end

	Controls.Time:SetText( strTime );
	local d = Locale.Lookup("{1_Time : datetime full}", os.time());
	Controls.Time:SetToolTipString(d);
end


-- ===========================================================================
--	Use an animation control to occasionally (not per frame!) callback for
--	an update on the current time.
-- ===========================================================================
function OnRefreshTimeTick()
	RefreshTime();
	Controls.TimeCallback:SetToBeginning();
	Controls.TimeCallback:Play();
end

-- ===========================================================================
function RefreshTurnsRemaining()

	local endTurn = Game.GetGameEndTurn();		-- This EXCLUSIVE, i.e. the turn AFTER the last playable turn.
	local turn = Game.GetCurrentGameTurn();

	if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_NORMALIZED_TURN") then
		turn = (turn - GameConfiguration.GetStartTurn()) + 1; -- Keep turns starting at 1.
		if endTurn > 0 then
			endTurn = endTurn - GameConfiguration.GetStartTurn();
		end
	end

	if endTurn > 0 then
		-- We have a hard turn limit
		Controls.Turns:SetText(tostring(turn) .. "/" .. tostring(endTurn - 1));
	else
		Controls.Turns:SetText(tostring(turn));
	end

	local strDate = Calendar.MakeYearStr(turn);
	Controls.CurrentDate:SetText("30XX AD");
end

-- ===========================================================================
function RefreshRoyaleUnit()
	local localPlayerID :number = Game.GetLocalPlayer();
	if localPlayerID == PlayerTypes.OBSERVER  or localPlayerID == PlayerTypes.NONE then 
		return;
	end

	local pPlayer:table = Players[localPlayerID];
	local pPlayerUnits:table = pPlayer:GetUnits();
	local pFalloutManager:table = Game.GetFalloutManager();
	local isHidingFalloutWarning:boolean = true;

	for i, pUnit in pPlayerUnits:Members() do
		local unitTypeName = UnitManager.GetTypeName(pUnit)
		if (unitTypeName == "UNIT_SETTLER") then
			local iPlotIndex:number = Map.GetPlot(pUnit:GetX(),pUnit:GetY()):GetIndex();
			if (pFalloutManager:HasFallout(iPlotIndex)) then
				isHidingFalloutWarning = false;
				break;
			end
		end
	end

	Controls.RunningUnit:SetHide(isHidingFalloutWarning);
end

-- ===========================================================================
function RefreshAll()
	RefreshRoyaleRing();
	RefreshTurnsRemaining();
	RefreshTime();		
	RefreshRoyaleUnit();
	RealizeNukes();
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLocalPlayerTurnBegin()	
	RefreshAll();
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string)
	if type == SystemUpdateUI.ScreenResize then
	end
end

-- ===========================================================================
function OnRefresh()
	ContextPtr:ClearRequestRefresh();
end



-- ===========================================================================
--	Game Engine Event
--	Wait until the game engine is done loading before the initial refresh,
--	otherwise there is a chance the load of the LUA threads (UI & core) will 
--  clash and then we'll all have a bad time. :(
-- ===========================================================================
function OnLoadGameViewStateDone()
	RefreshAll();
end


-- ===========================================================================
function lerp(a:number, b:number, t:number)
	return a * (1-t) + (b*t);
end

-- ===========================================================================
function RefreshRoyaleRing()
	
	local turn		:number = Game.GetCurrentGameTurn();
	local turnsLeft	:number = Game:GetProperty("NextSafeZoneTurn");
	local turnsStart:number	= Game:GetProperty("StartSafeZoneTurn");
	local safeZonePhase:number = Game:GetProperty("SafeZonePhase");

	local pFalloutManager = Game.GetFalloutManager();
	local falloutDamage :number = pFalloutManager:GetFalloutDamageOverride();

	if(falloutDamage == FalloutDamages.USE_FALLOUT_DEFAULT or falloutDamage == nil) then 
		falloutDamage = 0;
	end
	-- This drives the visual intensity of the fallout particle VFX
	WorldView.SetVFXImport("FalloutDamage", falloutDamage);
	
	if(turnsLeft == INVALID_TURNS) then
		Controls.RingTurns:SetHide(true);
		Controls.RingTurnsLabel:SetHide(true);
	else
		Controls.RingTurns:SetHide(false);
		Controls.RingTurnsLabel:SetHide(false);
		Controls.RingTurns:SetText( turnsLeft - turn);
		Controls.RingTurnsLabel:SetText( Locale.ToUpper( Locale.Lookup("LOC_CIV_ROYALE_HUD_TURNS",turnsLeft-turn)));
	end
	
	local tt:string = Locale.Lookup("LOC_CIV_ROYALE_HUD_CATEGORY_TOOLTIP",falloutDamage,safeZonePhase);
	Controls.RingIcon:SetToolTipString(tt);
	Controls.RingDamage:SetToolTipString(tt);
	Controls.RingDamage:SetText( tostring(falloutDamage) );
	
	--Reset instances and get animation progress with a temporary instance
	m_kBracketIM:ResetInstances();
	local uiBracket:table = m_kBracketIM:GetInstance();
	local progress :number = uiBracket.Flasher:GetProgress();
	m_kBracketIM:ReleaseInstance(uiBracket); 

	if(turnsLeft == INVALID_TURNS) then
		-- Safe Zone is not shrinking anymore.  Just flash and spark like crazy!
		local num		:number = turnsStart;
		for i=1,num,1 do
			uiBracket = m_kBracketIM:GetInstance();
			uiBracket.Flasher:SetToBeginning();
			uiBracket.Flasher:SetProgress(progress);
			uiBracket.Flasher:Play();
		end

		Controls.RightFlasher:SetToBeginning();
		Controls.RightFlasher:SetProgress(uiBracket.Flasher:GetProgress());
		Controls.RightFlasher:Play();

		Spark();
	else
		-- Safe Zone will continue to shrink.
		local MIN_FLASH_SPEED:number = 0.4;
		local MAX_FLASH_SPEED:number = 5;								-- Fastest flashing
		local num		:number = turnsStart;
		local percent	:number = 1 - ((turnsLeft - turn) / turnsStart);	-- % to 0 turns left	218,210,10 / 218,209,10 ... 228,219,10
		local speed		:number = lerp(MIN_FLASH_SPEED, MAX_FLASH_SPEED, percent); 
	
		for i=1,num,1 do
			uiBracket = m_kBracketIM:GetInstance();
			if (i >= (turnsLeft - turn)) then
				uiBracket.Flasher:SetToBeginning();
				uiBracket.Flasher:SetProgress(progress);
				uiBracket.Flasher:Play();
			else
				uiBracket.Flasher:SetToBeginning();
				uiBracket.Flasher:Stop();
			end
		
			uiBracket.Flasher:SetToolTipString( tostring(i) );
		end
		if((turnsLeft - turn) == 1) then
			Controls.RightFlasher:SetToBeginning();
			Controls.RightFlasher:SetProgress(uiBracket.Flasher:GetProgress());
			Controls.RightFlasher:Play();
		else
			Controls.RightFlasher:SetToBeginning();
			Controls.RightFlasher:Stop();
		end	

		if( turnsStart - (turnsLeft - turn) == 0) then
			Spark();
		end
	end
end


-- ===========================================================================
--	Show # of nukes owned by the local player.
-- ===========================================================================
function RealizeNukes()
	local localPlayer	:number = Game.GetLocalPlayer();
	local pPlayer		:table = Players[localPlayer];
	local pPlayerWMDs	:table = pPlayer:GetWMDs();
	local numNuclear	:number = 0;
	local numThermo		:number = 0;

	-- Step 1 total
	for pEntry in GameInfo.WMDs() do
		local count :number = pPlayerWMDs:GetWeaponCount(pEntry.Index);
		if (pEntry.WeaponType == "WMD_NUCLEAR_DEVICE") then				
			if (count > 0) then
				numNuclear = numNuclear + count;
			end
		elseif (pEntry.WeaponType == "WMD_THERMONUCLEAR_DEVICE") then
			if (count > 0) then
				numThermo = numThermo + count;
			end
		end
	end

	-- Step 2 show/hide each depending on count
	if numNuclear > 0 then
		Controls.NuclearDeviceCount:SetText(numNuclear);
		if Controls.NuclearDevices:IsHidden() then
			Controls.NuclearDevices:SetHide( false );
		end
	else
		if Controls.NuclearDevices:IsVisible() then
			Controls.NuclearDevices:SetHide( true );
		end
	end

	if numThermo > 0 then		
		Controls.ThermoNuclearDeviceCount:SetText(numThermo);
		if Controls.ThermoNuclearDevices:IsHidden() then
			Controls.ThermoNuclearDevices:SetHide( false );
		end
	else
		if Controls.ThermoNuclearDevices:IsVisible() then
			Controls.ThermoNuclearDevices:SetHide( true );
		end
	end
end


-- ===========================================================================
--	Event
--	Change in nukes owned by a player.
-- ===========================================================================
function OnWMDUpdate( owner:number, WMDtype:number )
	local localPlayer :number = Game.GetLocalPlayer();
	if ( owner == localPlayer ) then
		RealizeNukes();
	end
end


-- ===========================================================================
--	In UI particle system... not super efficient!
-- ===========================================================================
function AllocateParticles()	
	m_kParticleIM:ResetInstances();
	m_kParticles = {}	
	local ui:table;
	for i=1,MAX_PARTICLES,1 do
		m_kParticles[i] = m_kParticleIM:GetInstance();
	end	 
end

-- ===========================================================================
function Spark()
	local startX	:number = 30;
	local width		:number = Controls.RingStack:GetSizeX() + 100;
	local height	:number = 30;		-- height to initially emit
	local pushup	:number = -45;		-- Most a particle will "push up" to the sky when emitted
	local minlife	:number = 40;		-- Shortest life of a particle
	local maxlife	:number = 90;		-- Longest life of a particle
	for i=1,MAX_PARTICLES,1 do
		local ui:table = m_kParticles[i];
		ui.Flash1:SetProgress( math.random()  );
		ui.Flash2:SetProgress( math.random()  );
		local size = 1 + (math.random() * 2);
		ui.Image1:SetSizeVal( size,size );
		ui.Image2:SetSizeVal( size,size );
		ui.x = startX + (math.random() * width);-- x position
		ui.y = math.random() * height;			-- y position
		ui.vx = (math.random() * 30) - 15;		-- velocity x
		ui.vy = math.random() * pushup;			-- velocity y
		ui.b = 0;								-- bounces (b=0 none, b=1 has hit top panel frame.)
		ui.l = minlife + (math.random() * maxlife);		-- life in frames
		ui.ParticleTop:SetOffsetVal( x, y );
		ui.ParticleTop:SetHide( false );
	end	 	

	-- WARNING: Expensive to wire up per-frame callbacks so only have active
	-- while the system is playing out.
	ContextPtr:SetUpdate( OnUpdate );				
end

-- ===========================================================================
function UpdateParticles( delta:number )
	gravity = 40 * delta;
	local isDone:boolean = true;
	for i=1,MAX_PARTICLES,1 do
		local ui:table = m_kParticles[i];
		if ui.l > 0 then
			isDone = false;
			ui.l = ui.l - 1;						-- reduce life
			ui.vy = ui.vy + gravity;
			ui.x = ui.x + ui.vx * delta;
			ui.y = ui.y + ui.vy * delta;			
			if ui.b == 0 and ui.y > 30 then			-- bounce?
				ui.b = 1;
				ui.vy = -(ui.vy * 0.3);				-- flip velocity y
				ui.y = ui.y + ui.vy;
			end
			ui.ParticleTop:SetOffsetVal( ui.x, ui.y );		
		elseif ui.l ~= -1 then						-- dying
			ui.l = -1;								-- dead
			ui.ParticleTop:SetHide(true);
		end
	end
	if isDone then
		ContextPtr:ClearUpdate();
	end
end

-- ===========================================================================
function OnUpdate( delta )	
	UpdateParticles( delta );
end

-- ===========================================================================
function OnUnitMoveComplete(player, unitId, x, y)
	RefreshRoyaleUnit();
end

-- ===========================================================================
function OnShutdown()
	Events.LoadGameViewStateDone.Remove(OnLoadGameViewStateDone );	
	Events.LocalPlayerChanged.Remove(	OnLocalPlayerChanged );
	Events.LocalPlayerTurnBegin.Remove(	OnLocalPlayerTurnBegin );
	Events.SystemUpdateUI.Remove(		OnUpdateUI );
	Events.TurnBegin.Remove(			OnTurnBegin );
	Events.UnitMoveComplete.Remove(		OnUnitMoveComplete );
	Events.VisualStateRestored.Remove(	OnLocalPlayerTurnBegin );
	Events.WMDCountChanged.Remove(		OnWMDUpdate );	
end

-- ===========================================================================
function LateInitialize()	

	AllocateParticles();

	-- Read values set by game script.
	DANGER_ZONE_INTERVAL = Game:GetProperty("DANGER_ZONE_INTERVAL");
	DANGER_ZONE_SPEED = Game:GetProperty("DANGER_ZONE_SPEED");
	DANGER_ZONE_DELAY = Game:GetProperty("DANGER_ZONE_DELAY");		

	Controls.MenuButton:RegisterCallback( Mouse.eLClick, OnMenu );
	Controls.MenuButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.TimeCallback:RegisterEndCallback( OnRefreshTimeTick );

	-- Game Events
	Events.LoadGameViewStateDone.Add(	OnLoadGameViewStateDone );	
	Events.LocalPlayerChanged.Add(		OnLocalPlayerChanged );
	Events.LocalPlayerTurnBegin.Add(	OnLocalPlayerTurnBegin );
	Events.SystemUpdateUI.Add(			OnUpdateUI );
	Events.TurnBegin.Add(				OnTurnBegin );
	Events.UnitMoveComplete.Add(		OnUnitMoveComplete );
	Events.VisualStateRestored.Add(		OnLocalPlayerTurnBegin );
	Events.WMDCountChanged.Add(			OnWMDUpdate );	
	
	RefreshAll();
	Spark();			-- For fun, spark when screen first starts
end

-- ===========================================================================
function OnInit( isReload:boolean )
	LateInitialize();
end

-- ===========================================================================
function Initialize()	
	-- UI Callbacks	
	ContextPtr:SetInitHandler( OnInit );	
	ContextPtr:SetRefreshHandler( OnRefresh );	
	ContextPtr:SetShutdown( OnShutdown );	
end
Initialize();
