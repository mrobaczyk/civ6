-- Copyright 2019, Firaxis Games

-- ===========================================================================
-- Base File
-- ===========================================================================
include("MinimapPanel");
include("SupportFunctions");


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local SAFE_ZONE_RING_PROP			:string = "SafeZoneRing";
local DANGER_ZONE_OVERLAY_NAME		:string = "DeathBorders";
local DANGER_ZONE_OVERLAY_FILL_NAME :string = "DeathZoneFill";
local SAFE_ZONE_OVERLAY_NAME		:string = "SafeBorders";
local SAFE_ZONE_OVERLAY_FILL_NAME	:string = "SafeZoneFill";
local SUPPLY_DROP_OVERLAY_NAME		:string = "SupplyDrop";
local SUPPLY_DROP_OVERLAY_FILL_NAME :string = "SupplyDropFill";
local GOODY_HUT_OVERLAY_NAME		:string = "GoodyHutBorder";
local BARB_CAMP_OVERLAY_NAME		:string = "BarbCampBorder";
local SAFE_ZONE_OVERLAY_CHANNEL 	:number = 0;
local DANGER_ZONE_OVERLAY_CHANNEL 	:number = 1;
local SUPPLY_DROP_OVERLAY_CHANNEL 	:number = 2;
local GOODY_HUT_OVERLAY_CHANNEL 	:number = 3;
local BARB_CAMP_OVERLAY_CHANNEL 	:number = 4;
local COLOR_CLEAR					:number = UI.GetColorValueFromHexLiteral(0x00000000);
local COLOR_WHITE					:number = UI.GetColorValueFromHexLiteral(0xFFFFFF88);
local COLOR_GREEN					:number = UI.GetColorValueFromHexLiteral(0x2800FF00);
local COLOR_SUPPLY					:number = UI.GetColorValueFromHexLiteral(0xFFCC6600);
local COLOR_SUPPLY_FILL				:number = UI.GetColorValueFromHexLiteral(0x22CC6600);
local COLOR_RED						:number = UI.GetColorValueFromHexLiteral(0xFF0000FF);
local COLOR_GOODY					:number = UI.GetColorValueFromHexLiteral(0xFF00FF66);
local COLOR_GOODY_FILL				:number = UI.GetColorValueFromHexLiteral(0x2200FF66);
local COLOR_BARB					:number = UI.GetColorValueFromHexLiteral(0xFF0066FF);
local COLOR_BARB_FILL				:number = UI.GetColorValueFromHexLiteral(0x110066FF);
local m_eSupplyDropImprovement 		:number = GameInfo.Improvements["IMPROVEMENT_SUPPLY_DROP"].Index;
local m_eGoodyHutImprovement 		:number = GameInfo.Improvements["IMPROVEMENT_GOODY_HUT"].Index;
local m_eBarbarianCampImprovement 	:number = GameInfo.Improvements["IMPROVEMENT_BARBARIAN_CAMP"].Index;
local m_SupplyDropsHash				:number = UILens.CreateLensLayerHash("SupplyDrops");
local m_Districts					:number = UILens.CreateLensLayerHash("Districts");
local m_Selection					:number = UILens.CreateLensLayerHash("Selection");
local m_overlayDataDirty			:boolean = false; -- Has the data we are overlaying been changed and needs to be refreshed?


-- ===========================================================================
-- Cached Base Functions
-- NOTE:	Expansions name the cached function based on where they are
--			expected to be defined.  Since this is a MOD and its not clear
--			what function this may be saving off, it prefixes functions with
--			a MOD specific "CIVROYALE_" rather than "BASE_" or "XP2_", etc...
-- ===========================================================================
CIVROYALE_LateInitialize	 = LateInitialize;


-- ===========================================================================
-- Members
-- ===========================================================================
function ResetOverlays()
	local pOverlay:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_NAME);
	local pSafeOverlayFill:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pSafeOverlayFill == nil) then
		print("Error: missing SafeZone overlay");
		return;
	end
	
	pOverlay:ClearAll();
	pOverlay:SetVisible(true);
	pOverlay:ShowBorders(true);	
	pOverlay:SetBorderColors(SAFE_ZONE_OVERLAY_CHANNEL, COLOR_WHITE, COLOR_WHITE);
	
	pSafeOverlayFill:ClearAll();
	pSafeOverlayFill:SetVisible(true);
	pSafeOverlayFill:ShowBorders(false);
	pSafeOverlayFill:ShowHighlights(true);
	pSafeOverlayFill:SetHighlightColor(SAFE_ZONE_OVERLAY_CHANNEL, COLOR_WHITE);
		
	local pDangerOverlay:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_NAME);
	local pDangerOverlayFill:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_FILL_NAME);
	if(pDangerOverlay == nil or pDangerOverlayFill == nil) then
		print("Error: missing DangerZone overlay");
		return;
	end
	
	pDangerOverlay:ClearAll();
	pDangerOverlay:SetVisible(true);
	pDangerOverlay:ShowHighlights(false);
	pDangerOverlay:ShowBorders(true);
	pDangerOverlay:SetBorderColors(DANGER_ZONE_OVERLAY_CHANNEL, COLOR_RED, COLOR_RED);	
	
	pDangerOverlayFill:ClearAll();
	pDangerOverlayFill:SetVisible(true);
	pDangerOverlayFill:ShowBorders(false);
	pDangerOverlayFill:ShowHighlights(true);
	pDangerOverlayFill:SetHighlightColor(DANGER_ZONE_OVERLAY_CHANNEL, COLOR_RED);
	
	local pSupplyDropOverlay:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_NAME);
	local pSupplyDropFillOverlay:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_FILL_NAME);
	if(pSupplyDropOverlay == nil or pSupplyDropFillOverlay == nil) then
		print("Error: missing SupplyDrop overlay");
		return;
	end	
	
	pSupplyDropOverlay:ClearAll();
	pSupplyDropOverlay:SetVisible(true);
	pSupplyDropOverlay:ShowHighlights(false);
	pSupplyDropOverlay:ShowBorders(true);
	pSupplyDropOverlay:SetBorderColors(SUPPLY_DROP_OVERLAY_CHANNEL, COLOR_SUPPLY, COLOR_SUPPLY);	
	
	pSupplyDropFillOverlay:ClearAll();
	pSupplyDropFillOverlay:SetVisible(true);
	pSupplyDropFillOverlay:ShowBorders(false);
	pSupplyDropFillOverlay:ShowHighlights(true);
	pSupplyDropFillOverlay:SetHighlightColor(SUPPLY_DROP_OVERLAY_CHANNEL, COLOR_SUPPLY_FILL);

	local pBarbCampOverlay:object = UILens.GetOverlay(BARB_CAMP_OVERLAY_NAME);	
	if(pBarbCampOverlay == nil ) then
		print("Error: missing Barbarian Camp overlay");
		return;
	end	
	
	pBarbCampOverlay:ClearAll();
	pBarbCampOverlay:SetVisible(true);
	pBarbCampOverlay:ShowHighlights(true);
	pBarbCampOverlay:ShowBorders(true);
	pBarbCampOverlay:SetBorderColors(BARB_CAMP_OVERLAY_CHANNEL, COLOR_BARB, COLOR_BARB);	
	pBarbCampOverlay:SetHighlightColor(BARB_CAMP_OVERLAY_CHANNEL, COLOR_BARB_FILL);
	
	
	local pGoodyHutOverlay:object = UILens.GetOverlay(GOODY_HUT_OVERLAY_NAME);	
	if(pGoodyHutOverlay == nil ) then
		print("Error: missing Goody Hut overlay");
		return;
	end	
	
	pGoodyHutOverlay:ClearAll();
	pGoodyHutOverlay:SetVisible(true);
	pGoodyHutOverlay:ShowHighlights(true);
	pGoodyHutOverlay:ShowBorders(true);
	pGoodyHutOverlay:SetBorderColors(GOODY_HUT_OVERLAY_CHANNEL, COLOR_GOODY, COLOR_GOODY);	
	pGoodyHutOverlay:SetHighlightColor(GOODY_HUT_OVERLAY_CHANNEL, COLOR_GOODY_FILL);		
	
	
	ResetSafeZoneOverlay();
	ResetDangerZoneOverlay();
	ResetSupplyDropOverlay();
	ResetGoodyHutOverlay();
	ResetBarbarianCampOverlay();
end

function ClearScenarioOverlays()
	local pOverlay:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil) then
		print("Error: missing SafeZone overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(SAFE_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(SAFE_ZONE_OVERLAY_CHANNEL);
	
	local pOverlay:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil) then
		print("Error: missing DangerZone overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(DANGER_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(DANGER_ZONE_OVERLAY_CHANNEL);
	
	local pOverlay:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil) then
		print("Error: missing SupplyDrop overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(SUPPLY_DROP_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(SUPPLY_DROP_OVERLAY_CHANNEL);
	
	local pOverlay:object = UILens.GetOverlay(GOODY_HUT_OVERLAY_NAME);	
	if(pOverlay == nil ) then
		print("Error: missing Goody Hut overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(GOODY_HUT_OVERLAY_CHANNEL);
	
	local pOverlay:object = UILens.GetOverlay(BARB_CAMP_OVERLAY_NAME);	
	if(pOverlay == nil ) then
		print("Error: missing Barbarian Camp overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(BARB_CAMP_OVERLAY_CHANNEL);
	
	local pOverlay:object = UILens.GetOverlay("BarbCampSprite");
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
	end
		
	local pOverlay:object = UILens.GetOverlay("SupplyDropSprite");
	if pOverlay ~= nil then
		pOverlay:ClearAll()
	end
		
	local pOverlay:object = UILens.GetOverlay("GoodyHutSprite");
	if pOverlay ~= nil then
		pOverlay:ClearAll()
	end
end


function ResetSafeZoneOverlay()
	local pOverlay:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(SAFE_ZONE_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil) then
		print("Error: missing SafeZone overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(SAFE_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(SAFE_ZONE_OVERLAY_CHANNEL);

	local safeZoneRingPlots = {};
	local mapCount:number = Map.GetPlotCount() - 1;
	for plotIndex = 0, mapCount, 1 do
		local pPlot:object = Map.GetPlotByIndex(plotIndex);
		local safeZoneFlag:number = pPlot:GetProperty(SAFE_ZONE_RING_PROP);
		if safeZoneFlag ~= nil and safeZoneFlag > 0 then
			table.insert(safeZoneRingPlots, plotIndex);
		end
	end
	pOverlay:SetPlotChannel(safeZoneRingPlots, SAFE_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:SetPlotChannel(safeZoneRingPlots, SAFE_ZONE_OVERLAY_CHANNEL);
end

function ResetDangerZoneOverlay()
	local pOverlay:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil) then
		print("Error: missing DangerZone overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(DANGER_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(DANGER_ZONE_OVERLAY_CHANNEL);
	
	local dangerPlots = {};
	local pFalloutManager = Game.GetFalloutManager();
	if(pFalloutManager == nil) then
		print("Error: missing fallout manager overlay");
		return;
	end
	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do		
		if (pFalloutManager:HasFallout(iPlotIndex)) then
			table.insert(dangerPlots, iPlotIndex);
		end
	end
	pOverlay:SetPlotChannel(dangerPlots, DANGER_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:SetPlotChannel(dangerPlots, DANGER_ZONE_OVERLAY_CHANNEL);
end

function ResetSupplyDropOverlay()
	local pOverlay:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(SUPPLY_DROP_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nil) then
		print("Error: missing SupplyDrop overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(SUPPLY_DROP_OVERLAY_CHANNEL);
	pOverlayFill:ClearPlotsByChannel(SUPPLY_DROP_OVERLAY_CHANNEL);
	
	local localPlayer = Game.GetLocalPlayer();
	local pPlayerVis;
	if (localPlayer and localPlayer >= 0) then
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil) then
		return;
	end

	local supplyDropPlots = {};
	local supplyDropSpritePlots = {};
	local mapCount:number = Map.GetPlotCount() - 1;
	for plotIndex = 0, mapCount, 1 do
		local pPlot:object = Map.GetPlotByIndex(plotIndex);		
		if (pPlot:GetImprovementType() == m_eSupplyDropImprovement) then
			table.insert(supplyDropPlots, plotIndex);
			if ( not pPlayerVis:IsVisible(plotIndex)) then
				table.insert(supplyDropSpritePlots, plotIndex);
			end
		end
	end
	pOverlay:SetPlotChannel(supplyDropPlots, SUPPLY_DROP_OVERLAY_CHANNEL);
	pOverlayFill:SetPlotChannel(supplyDropPlots, SUPPLY_DROP_OVERLAY_CHANNEL);
		
	
	-- sprite overlays
	local pOverlay:object = UILens.GetOverlay("SupplyDropSprite");
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( supplyDropSpritePlots, "SupplyDropOverlay", 0 );
	end
	
	local pOverlay:object = UILens.GetOverlay("SupplyDropSpriteMiniMap");
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( supplyDropPlots, "SupplyDropOverlayMiniMap", 0 );
	end
end

function ResetGoodyHutOverlay()
	local pOverlay:object = UILens.GetOverlay(GOODY_HUT_OVERLAY_NAME);
	
	if(pOverlay == nil ) then
		print("Error: missing Goody Hut overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(GOODY_HUT_OVERLAY_CHANNEL);
	
	
	local localPlayer = Game.GetLocalPlayer();
	local pPlayerVis;
	if (localPlayer and localPlayer >= 0) then
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil) then
		return;
	end

	local hutDropPlots = {};	
	local hutDropSpritePlots = {};
	local mapCount:number = Map.GetPlotCount() - 1;
	for plotIndex = 0, mapCount, 1 do
		local pPlot:object = Map.GetPlotByIndex(plotIndex);		
		if (pPlot:GetImprovementType() == m_eGoodyHutImprovement) then			
			if ( pPlayerVis:IsVisible(plotIndex) or pPlayerVis:IsRevealed(plotIndex)) then
				table.insert(hutDropPlots, plotIndex);
				if ( not pPlayerVis:IsVisible(plotIndex)) then
					table.insert(hutDropSpritePlots, plotIndex);
				end
			end
		end
	end
	pOverlay:SetPlotChannel(hutDropPlots, GOODY_HUT_OVERLAY_CHANNEL);		
	
	local pOverlay:object = UILens.GetOverlay("GoodyHutSprite");
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( hutDropSpritePlots, "GoodyHutOverlay", 0 );
	end
	
	local pOverlay:object = UILens.GetOverlay("GoodyHutSpriteMiniMap");
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( hutDropPlots, "GoodyHutOverlayMiniMap", 0 );
	end
end

function ResetBarbarianCampOverlay()
	local pOverlay:object = UILens.GetOverlay(BARB_CAMP_OVERLAY_NAME);
	
	if(pOverlay == nil ) then
		print("Error: missing Barbarian Camp overlay");
		return;
	end

	pOverlay:ClearPlotsByChannel(BARB_CAMP_OVERLAY_CHANNEL);
	
	
	local localPlayer = Game.GetLocalPlayer();
	local pPlayerVis;
	if (localPlayer and localPlayer >= 0) then
		pPlayerVis = PlayersVisibility[localPlayer];
	end
	if (pPlayerVis == nil) then
		return;
	end

	local campDropPlots = {};	
	local campDropSpritePlots = {};
	local mapCount:number = Map.GetPlotCount() - 1;
	for plotIndex = 0, mapCount, 1 do
		local pPlot:object = Map.GetPlotByIndex(plotIndex);		
		if (pPlot:GetImprovementType() == m_eBarbarianCampImprovement) then			
			if ( pPlayerVis:IsVisible(plotIndex) or pPlayerVis:IsRevealed(plotIndex)) then
				table.insert(campDropPlots, plotIndex);
				if ( not pPlayerVis:IsVisible(plotIndex)) then
					table.insert(campDropSpritePlots, plotIndex);
				end
			end
		end
	end
	pOverlay:SetPlotChannel(campDropPlots, BARB_CAMP_OVERLAY_CHANNEL);
		
	local pOverlay:object = UILens.GetOverlay("BarbCampSprite");
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( campDropSpritePlots, "BarbCampOverlay", 0 );
	end	
		
	local pOverlay:object = UILens.GetOverlay("BarbCampSpriteMiniMap");
	if pOverlay ~= nil then
		pOverlay:ClearAll()	
		pOverlay:CreateSprites( campDropPlots, "BarbCampOverlayMiniMap", 0 );
	end
end


function ReadCustomData( key:string )
	local pParameters	:table = UI.GetGameParameters():Get(key);
	local kReturn		:table = {};
	if pParameters ~= nil then
		local count:number = pParameters:GetCount();
		if count == 0 then
			return nil;
		end
		for i = 1, count, 1 do
			local value = pParameters:GetValueAt(i-1);
			table.insert(kReturn, value);
		end
	else
		return nil;
	end
	return unpack(kReturn);
end


-- ===========================================================================
--	Scenario Minimap Tooltips
-- ===========================================================================
function ShowMinimapTooltips(inputX:number, inputY:number)
	local ePlayer : number = Game.GetLocalPlayer(); 
	local pPlayerVis:table = PlayersVisibility[ePlayer];

	local minix, miniy = GetMinimapMouseCoords( inputX, inputY );
	if (pPlayerVis ~= nil and IsMouseInMinimap(minix, miniy)) then
		local wx, wy = TranslateMinimapToWorld(minix, miniy);
		local plotX, plotY = UI.GetPlotCoordFromWorld(wx, wy);
		local pPlot = Map.GetPlot(plotX, plotY);
		if (pPlot ~= nil) then
			local plotID = Map.GetPlotIndex(plotX, plotY);
			local pFalloutManager = Game.GetFalloutManager();			
			local safeZoneFlag:number = pPlot:GetProperty(SAFE_ZONE_RING_PROP);			
			
			if(pFalloutManager == nil) then
				print("Error: missing fallout manager");
				return;
			end
			
			if pPlayerVis:IsRevealed(plotID) then
				local pTooltipString = Locale.Lookup("LOC_CIVROYALE_TERRAIN_WASTELAND_NAME");
				Controls.MinimapImage:SetToolTipString(pTooltipString);	
			else
				local pTooltipString = Locale.Lookup("LOC_MINIMAP_FOG_OF_WAR_TOOLTIP");
				Controls.MinimapImage:SetToolTipString(pTooltipString);
			end
			
			if (pFalloutManager:HasFallout(plotID)) then
				local pTooltipString = Locale.Lookup("LOC_MINIMAP_RED_DEATH_TOOLTIP");
				Controls.MinimapImage:SetToolTipString(pTooltipString);				
			elseif safeZoneFlag ~= nil and safeZoneFlag > 0 then
				local pTooltipString = Locale.Lookup("LOC_MINIMAP_SAFE_ZONE_TOOLTIP");
				Controls.MinimapImage:SetToolTipString(pTooltipString);					
			end
				
			if pPlayerVis:IsRevealed(plotID) then
				if (pPlot:GetImprovementType() == m_eGoodyHutImprovement) then	
					local pTooltipString = Locale.Lookup("LOC_CIV_ROYALE_IMPROVEMENT_GOODY_HUT_NAME");
					Controls.MinimapImage:SetToolTipString(pTooltipString);
				elseif (pPlot:GetImprovementType() == m_eBarbarianCampImprovement) then	
					local pTooltipString = Locale.Lookup("LOC_IMPROVEMENT_BARBARIAN_CAMP_NAME");
					Controls.MinimapImage:SetToolTipString(pTooltipString);				
				elseif (pPlot:GetImprovementType() == m_eSupplyDropImprovement) then
					local pTooltipString = Locale.Lookup("LOC_IMPROVEMENT_SUPPLY_DROP_NAME");
					Controls.MinimapImage:SetToolTipString(pTooltipString);				
				end	
			end
		end
	end
end

-- ===========================================================================
--	Event 
-- ===========================================================================
function OnTurnBegin(turn :number)
	ResetSafeZoneOverlay();

	-- Read custom data from Game side.
	local NextSafeZoneTurn = ReadCustomData("NextSafeZoneTurn");
	local LastSafeZoneTurn = ReadCustomData("LastSafeZoneTurn");
	local DangerRingTurn = ReadCustomData("DangerRingTurn");

	local safeZoneDistance = Game:GetProperty("CurrentSafeZoneDistance");
	local nextZoneDistance = Game:GetProperty("NextSafeZoneDistance");
	
	print("Custom Data: ",nextZoneDistance,safeZoneDistance,NextSafeZoneTurn,LastSafeZoneTurn,DangerRingTurn);
	ResetDangerZoneOverlay();
end

function OnTeamVictory(team, victoryType)
	-- Probably need to do some more checks here for hotseat games
	local localPlayer = Game.GetLocalPlayer();
	
	-- This drives the visual intensity of the fallout particle VFX
	WorldView.SetVFXImport("GodRayDisable", 1);
	
	if (localPlayer and localPlayer >= 0) then		-- Check to see if there is any local player
		local player = Players[localPlayer];
		if(player:IsAlive()) then
			
			
			local playerUnits = player:GetUnits();
			
			-- Find the first settler we can and play the victory cinematic on it
			for i, unit in playerUnits:Members() do
				local unitTypeName = UnitManager.GetTypeName(unit);
				local settlerFound = false;
				if ("UNIT_SETTLER" == unitTypeName) then					
					
					SimUnitSystem.SetVisHexHeading(unit, -2);
					local plot = Map.GetPlot(unit:GetX(), unit:GetY());	
					UI.LookAtPlot(plot:GetX(), plot:GetY(), 0, 0, true);
					
					-- Deactivating overlays
					UILens.SetActive("Cinematic");
					UI.SetInterfaceMode(InterfaceModeTypes.CINEMATIC);
					UILens.HideOverlays("MovementPath");									
					ClearScenarioOverlays();	
					
					-- Make sure to select the settler, otherwise the lander animation will not play
					UI.SelectUnit(unit);	
					
					-- The look-at needs to be instantaneous otherwise the unit animation will not play if it's out of view
					Events.PlayCameraAnimationAtHex("Camera_Land_Anim", unit:GetX(), unit:GetY(), 0.0, true);			
					UI.LookAtPlot(plot:GetX(), plot:GetY(), 0, 0, true); -- Force the look-at one more time just in case
					SimUnitSystem.SetAnimationState(unit, "ACTION_1", "ACTION_1");	
					break
					
				end
			end
		end
	end
end

-- ===========================================================================
function OnPlayerDefeat( player, defeat, eventID)
	-- We might do a little something for a player when they lose?
	-- local localPlayer = Game.GetLocalPlayer();
	-- if (localPlayer and localPlayer >= 0) then		-- Check to see if there is any local player
		-- -- Was it the local player?
		-- if (localPlayer == player) then
			
		-- end
	-- end	
end

-- ===========================================================================
function OnImprovementAddedToMap(locX :number, locY :number, eImprovementType :number, eOwner :number)
	m_overlayDataDirty = true;  -- Next step is an refresh in OnGameCoreEventPlaybackComplete
end

-- ===========================================================================
function OnImprovementRemovedFromMap( locX :number, locY :number, eOwner :number )	
	m_overlayDataDirty = true;  -- Next step is an refresh in OnGameCoreEventPlaybackComplete
end

-- ===========================================================================
function OnImprovementVisibilityChanged( locX :number, locY :number, eImprovementType :number, eVisibility :number )
	m_overlayDataDirty = true;  -- Next step is an refresh in OnGameCoreEventPlaybackComplete
end

-- ===========================================================================
function OnLocalPlayerChanged()
	m_overlayDataDirty = true;  -- Next step is an refresh in OnGameCoreEventPlaybackComplete
end

-- ===========================================================================
--	EVENT
--	Gamecore is done processing events; this may fire multiple times as a
--	turn begins, as well as after player actions.
-- ===========================================================================
function OnGameCoreEventPlaybackComplete()	
	if m_overlayDataDirty then
		m_overlayDataDirty = false;
		ContextPtr:RequestRefresh();		
	end
end

-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnRefresh()
	ResetSupplyDropOverlay();
	ResetGoodyHutOverlay();
	ResetBarbarianCampOverlay();
end

-- ===========================================================================
function OnWMDFalloutChanged(plotX :number, plotY :number, hasFallout :number)
	local pPlot:object = Map.GetPlot(plotX, plotY);
	if(pPlot == nil) then
		print("No plot object for " .. tostring(plotX) .. "," .. tostring(plotY));
		return;
	end

	local pOverlay:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_NAME);
	local pOverlayFill:object = UILens.GetOverlay(DANGER_ZONE_OVERLAY_FILL_NAME);
	if(pOverlay == nil or pOverlayFill == nill) then
		print("Error: missing SafeZone overlay");
		return;
	end

	local dangerPlot = { pPlot:GetIndex() };
	pOverlay:SetPlotChannel(dangerPlot, DANGER_ZONE_OVERLAY_CHANNEL);
	pOverlayFill:SetPlotChannel(dangerPlot, DANGER_ZONE_OVERLAY_CHANNEL);
end

-- ===========================================================================
function OnLoadScreenClose()
	ResetOverlays();
end

-- ===========================================================================
function InitializeOverlays()
	-- This is to work around a crash that could happen if this game mode
	-- had been unloaded once, then reloaded again. The internal border
	-- styles might no longer be valid, this will be fixed in a future
	-- patch and this workaround function will no longer be necessary
	
	-- This should match the list of all BorderOverlay layers in Overlay.artdef
	local kBorderOverlays = {
		{ name = "BarbCampBorder", material = "BarbCampBorder"      },
		{ name = "DeathBorders",   material = "DeathBorderMaterial" },
		{ name = "DeathZoneFill",  material = "DeathFill"           },
		{ name = "GoodyHutBorder", material = "GoodyHutBorder"      },
		{ name = "SafeBorders",    material = "SafeBorderMaterial"  },
		{ name = "SafeZoneFill",   material = "SafeZoneFill"        },
		{ name = "SupplyDrop",     material = "SupplyDropMaterial"  },
		{ name = "SupplyDropFill", material = "SupplyDropFill"      },
	}
	
	for _,layer in pairs(kBorderOverlays) do
		local pOverlay = UILens.GetOverlay(layer.name);
		if (pOverlay == nil) then
			print("Error: missing overlay " .. layer.name);
		else
			local nMaterialHash = UILens.CreateLensLayerHash(layer.material);
			pOverlay:InitializeStyles(1, nMaterialHash);
		end
	end

end

-- ===========================================================================
-- OVERRIDE BASE
-- ===========================================================================
function ToggleMapOptionsList()	
    if Controls.MapOptionsPanel:IsHidden() then
        RefreshMinimapOptions();
    end
	Controls.MapOptionsPanel:SetHide( not Controls.MapOptionsPanel:IsHidden() );
	RealizeFlyouts(Controls.MapOptionsPanel);
	Controls.MapOptionsButton:SetSelected( not Controls.MapOptionsPanel:IsHidden() );
end

-- ===========================================================================
function LateInitialize( isReload:boolean )
	CIVROYALE_LateInitialize( isReload );

	-- Force off any lenses that may 
	local yieldIconLens : number = UILens.CreateLensLayerHash("Yield_Icons");
	UILens.ToggleLayerOff( yieldIconLens );

	ContextPtr:SetRefreshHandler( OnRefresh );

	Events.GameCoreEventPlaybackComplete.Add(OnGameCoreEventPlaybackComplete);	
	Events.ImprovementAddedToMap.Add( OnImprovementAddedToMap );
	Events.ImprovementRemovedFromMap.Add( OnImprovementRemovedFromMap );
	Events.ImprovementVisibilityChanged.Add( OnImprovementVisibilityChanged );
	Events.LoadScreenClose.Add(OnLoadScreenClose);
	Events.LocalPlayerChanged.Add( OnLocalPlayerChanged );
	Events.PlayerDefeat.Add( OnPlayerDefeat );
	Events.TeamVictory.Add( OnTeamVictory );
	Events.TurnBegin.Add( OnTurnBegin );
	Events.WMDFalloutChanged.Add( OnWMDFalloutChanged );
	Events.OverlaySystemInitialized.Add( InitializeOverlays );

	if isReload then
		ResetOverlays();
	end
end