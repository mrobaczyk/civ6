--[[
-- Copyright (c) 2017-2018 Firaxis Games
--]]
-- ===========================================================================
-- INCLUDE BASE FILE
-- ===========================================================================
include("WorldInput");
include("PiratesScenario_PropKeys");
include("PiratesScenario_Shared_Script");


-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_LateInitialize			= LateInitialize;


-- ===========================================================================
--	HELPER FUNCTIONS
-- ===========================================================================
-- Is plotID contained in g_targetPlots?
function IsTargetPlot(plotID :number)
	if(g_targetPlots == nil) then
		return false;
	end

	for _,targetPlotID in ipairs(g_targetPlots) do
		if(targetPlotID == plotID) then
			return true;
		end
	end

	return false;
end


------------------------------------------------------------------------------------------------
-- Generic Capturing Boat Style Input Action
------------------------------------------------------------------------------------------------
function OnMouseEnd_CaptureBoatTypeAction(pInputStruct :table, scriptExecuteName :string, commandSubTypeStr :string)
	-- If a drag was occurring, end it; otherwise raise event.
	if g_isMouseDragging then
		g_isMouseDragging = false;
	elseif IsSelectionAllowedAt( UI.GetCursorPlotID() ) then		
		DoCaptureBoatTypeAction(pInputStruct, scriptExecuteName, commandSubTypeStr);
	end
	EndDragMap();
	g_isMouseDownInWorld = false;
	return true;
end

function DoCaptureBoatTypeAction(pInputStruct :table, scriptExecuteName :string, commandSubTypeStr :string)
	local plotID :number = UI.GetCursorPlotID();
	if Map.IsPlot(plotID) and IsTargetPlot(plotID) then
		local plot :object = Map.GetPlotByIndex(plotID);
		local pSelectedUnit :object = UI.GetHeadSelectedUnit();
		
		if(pSelectedUnit ~= nil) then
			local tParameters = {};
			tParameters[UnitCommandTypes.PARAM_X] = plot:GetX();
			tParameters[UnitCommandTypes.PARAM_Y] = plot:GetY();
			tParameters[UnitCommandTypes.PARAM_NAME] = scriptExecuteName;
			tParameters.CommandSubType = commandSubTypeStr;
			UnitManager.RequestCommand(pSelectedUnit, UnitCommandTypes.EXECUTE_SCRIPT, tParameters);
			UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
		else
			print("ERROR: Missing head selected unit");
		end
	end
	return true;
end

function OnInterfaceModeChange_CaptureBoatTypeAction(eNewMode :number)
	UIManager:SetUICursor(CursorTypes.RANGE_ATTACK);
	g_targetPlots = {};
	local pSelectedUnit :object = UI.GetHeadSelectedUnit();
	if (pSelectedUnit == nil) then
		return;
	end

	local pUnitAdjPlots :table = Map.GetAdjacentPlots(pSelectedUnit:GetX(), pSelectedUnit:GetY());
	for i, pAdjPlot in ipairs(pUnitAdjPlots) do
		local captureResults :table = GetCaptureBoat(Game.GetLocalPlayer(), pAdjPlot);
		if(captureResults.Result == m_GetCaptureBoatResults.CAPTURABLE) then
			table.insert(g_targetPlots, pAdjPlot:GetIndex());
		end
	end 

	-- Highlight the plots available to attack
	if (table.count(g_targetPlots) ~= 0) then
		local eLocalPlayer :number = Game.GetLocalPlayer();
		UILens.ToggleLayerOn(g_HexColoringAttack);
		UILens.SetLayerHexesArea(g_HexColoringAttack, eLocalPlayer, g_targetPlots);
	end
end

function OnInterfaceModeLeave_CaptureBoatTypeAction(eNewMode :number)
	UIManager:SetUICursor(CursorTypes.NORMAL);
	UILens.ToggleLayerOff( g_HexColoringAttack );
	UILens.ClearLayerHexes( g_HexColoringAttack );
end


------------------------------------------------------------------------------------------------
-- Code related to the Capture Boat Ability
------------------------------------------------------------------------------------------------
function OnMouseEnd_CaptureBoat(pInputStruct :table)
	return OnMouseEnd_CaptureBoatTypeAction(pInputStruct, "ScenarioCommand_CaptureBoat", g_unitCommandSubTypeNames.CAPTURE_BOAT);
end


------------------------------------------------------------------------------------------------
-- Code related to the Shore Party Ability
------------------------------------------------------------------------------------------------
function OnMouseEnd_ShoreParty(pInputStruct :table)
	-- If a drag was occurring, end it; otherwise raise event.
	if g_isMouseDragging then
		g_isMouseDragging = false;
	elseif IsSelectionAllowedAt( UI.GetCursorPlotID() ) then		
		DoShoreParty(pInputStruct);
	end
	EndDragMap();
	g_isMouseDownInWorld = false;
	return true;
end
------------------------------------------------------------------------------------------------
function DoShoreParty(pInputStruct :table)
	local plotID :number = UI.GetCursorPlotID();
	if Map.IsPlot(plotID) and IsTargetPlot(plotID) then
		local plot :object = Map.GetPlotByIndex(plotID);
		local pSelectedUnit :object = UI.GetHeadSelectedUnit();
		
		if(pSelectedUnit ~= nil) then
			local tParameters = {};
			tParameters[UnitCommandTypes.PARAM_X] = plot:GetX();
			tParameters[UnitCommandTypes.PARAM_Y] = plot:GetY();
			tParameters[UnitCommandTypes.PARAM_NAME] = "ScenarioCommand_ShoreParty";
			tParameters.CommandSubType = g_unitCommandSubTypeNames.SHORE_PARTY;
			UnitManager.RequestCommand(pSelectedUnit, UnitCommandTypes.EXECUTE_SCRIPT, tParameters);
			UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
		else
			print("ERROR: Missing head selected unit");
		end
	end
	return true;
end
------------------------------------------------------------------------------------------------
function OnInterfaceModeChange_ShoreParty(eNewMode :number)
	UIManager:SetUICursor(CursorTypes.RANGE_ATTACK);
	g_targetPlots = {};
	local pSelectedUnit :object = UI.GetHeadSelectedUnit();
	if (pSelectedUnit == nil) then
		return;
	end

	local pUnitAdjPlots :table = Map.GetAdjacentPlots(pSelectedUnit:GetX(), pSelectedUnit:GetY());
	for i, pAdjPlot in ipairs(pUnitAdjPlots) do
		local shorePartyResult :object = GetShorePartyStatusForPlot(Game.GetLocalPlayer(), pAdjPlot);
		if(shorePartyResult.Result == m_GetShorePartyResults.VALID) then
			table.insert(g_targetPlots, pAdjPlot:GetIndex());
		end
	end 

	-- Highlight the plots available to attack
	if (table.count(g_targetPlots) ~= 0) then
		local eLocalPlayer :number = Game.GetLocalPlayer();
		UILens.ToggleLayerOn(g_HexColoringAttack);
		UILens.SetLayerHexesArea(g_HexColoringAttack, eLocalPlayer, g_targetPlots);
	end
end
--------------------------------------------------------------------------------------------------
function OnInterfaceModeLeave_ShoreParty(eNewMode :number)
	UIManager:SetUICursor(CursorTypes.NORMAL);
	UILens.ToggleLayerOff( g_HexColoringAttack );
	UILens.ClearLayerHexes( g_HexColoringAttack );
end


------------------------------------------------------------------------------------------------
-- Code related to the Shore Party Embark Ability
------------------------------------------------------------------------------------------------
function OnMouseEnd_ShorePartyEmbark(pInputStruct :table)
	-- If a drag was occurring, end it; otherwise raise event.
	if g_isMouseDragging then
		g_isMouseDragging = false;
	elseif IsSelectionAllowedAt( UI.GetCursorPlotID() ) then		
		DoShorePartyEmbark(pInputStruct);
	end
	EndDragMap();
	g_isMouseDownInWorld = false;
	return true;
end
------------------------------------------------------------------------------------------------
function DoShorePartyEmbark(pInputStruct :table)
	local plotID :number = UI.GetCursorPlotID();
	if Map.IsPlot(plotID) and IsTargetPlot(plotID) then
		local plot :object = Map.GetPlotByIndex(plotID);
		local pSelectedUnit :object = UI.GetHeadSelectedUnit();
		
		if(pSelectedUnit ~= nil) then
			local tParameters = {};
			tParameters[UnitCommandTypes.PARAM_X] = plot:GetX();
			tParameters[UnitCommandTypes.PARAM_Y] = plot:GetY();
			tParameters[UnitCommandTypes.PARAM_NAME] = "ScenarioCommand_ShorePartyEmbark";
			tParameters.CommandSubType = g_unitCommandSubTypeNames.SHORE_PARTY_EMBARK;
			UnitManager.RequestCommand(pSelectedUnit, UnitCommandTypes.EXECUTE_SCRIPT, tParameters);
			UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
			--UI.PlaySound("Unit_Airlift");
		else
			print("ERROR: Missing head selected unit");
		end
	end
	return true;
end
------------------------------------------------------------------------------------------------
function OnInterfaceModeChange_ShorePartyEmbark(eNewMode :number)
	UIManager:SetUICursor(CursorTypes.RANGE_ATTACK);
	g_targetPlots = {};
	local pSelectedUnit :object = UI.GetHeadSelectedUnit();
	if (pSelectedUnit == nil) then
		return;
	end

	local pUnitAdjPlots :table = Map.GetAdjacentPlots(pSelectedUnit:GetX(), pSelectedUnit:GetY());
	for i, pAdjPlot in ipairs(pUnitAdjPlots) do
		local embarkResult :table = GetShorePartyEmbarkStatusForPlot(pSelectedUnit:GetOwner(), pAdjPlot);
		if(embarkResult.Result == m_GetShorePartyEmbarkResults.VALID) then
			table.insert(g_targetPlots, pAdjPlot:GetIndex());
		end
	end 

	-- Highlight the plots available to attack
	if (table.count(g_targetPlots) ~= 0) then
		local eLocalPlayer :number = Game.GetLocalPlayer();
		UILens.ToggleLayerOn(g_HexColoringAttack);
		UILens.SetLayerHexesArea(g_HexColoringAttack, eLocalPlayer, g_targetPlots);
	end
end
--------------------------------------------------------------------------------------------------
function OnInterfaceModeLeave_ShorePartyEmbark(eNewMode :number)
	UIManager:SetUICursor(CursorTypes.NORMAL);
	UILens.ToggleLayerOff( g_HexColoringAttack );
	UILens.ClearLayerHexes( g_HexColoringAttack );
end


------------------------------------------------------------------------------------------------
-- Code related to the Dread Pirate Ability
------------------------------------------------------------------------------------------------
function OnMouseEnd_DreadPirateActive(pInputStruct :table)
	return OnMouseEnd_CaptureBoatTypeAction(pInputStruct, "ScenarioCommand_DreadPirateActive", g_unitCommandSubTypeNames.DREAD_PIRATE_ACTIVE);
end


------------------------------------------------------------------------------------------------
-- Code related to the Privateer Ability
------------------------------------------------------------------------------------------------
function OnMouseEnd_PrivateerActive(pInputStruct :table)
	return OnMouseEnd_CaptureBoatTypeAction(pInputStruct, "ScenarioCommand_PrivateerActive", g_unitCommandSubTypeNames.PRIVATEER_ACTIVE);
end


------------------------------------------------------------------------------------------------
-- Code related to the Hoarder Ability (Chain Shot)
------------------------------------------------------------------------------------------------
function OnInterfaceModeChange_HoarderActive(eNewMode :number)
	UIManager:SetUICursor(CursorTypes.RANGE_ATTACK);
	g_targetPlots = {};
	local pSelectedUnit :object = UI.GetHeadSelectedUnit();
	if (pSelectedUnit == nil) then
		return;
	end

	g_targetPlots = GetChainShotTargetPlots(pSelectedUnit);

	-- Highlight the plots available to attack
	if (table.count(g_targetPlots) ~= 0) then
		local eLocalPlayer :number = Game.GetLocalPlayer();
		UILens.ToggleLayerOn(g_HexColoringAttack);
		UILens.SetLayerHexesArea(g_HexColoringAttack, eLocalPlayer, g_targetPlots);
	end
end

function OnMouseEnd_HoarderActive(pInputStruct :table)
	return OnMouseEnd_CaptureBoatTypeAction(pInputStruct, "ScenarioCommand_HoarderActive", g_unitCommandSubTypeNames.HOARDER_ACTIVE);
end


-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function LateInitialize()

	BASE_LateInitialize();

	InterfaceModeMessageHandler[INTERFACEMODE_CAPTURE_BOAT] = {};
	InterfaceModeMessageHandler[INTERFACEMODE_CAPTURE_BOAT][INTERFACEMODE_ENTER] = OnInterfaceModeChange_CaptureBoatTypeAction;
	InterfaceModeMessageHandler[INTERFACEMODE_CAPTURE_BOAT][INTERFACEMODE_LEAVE] = OnInterfaceModeLeave_CaptureBoatTypeAction;
	InterfaceModeMessageHandler[INTERFACEMODE_CAPTURE_BOAT][MouseEvents.LButtonUp] = OnMouseEnd_CaptureBoat;
	InterfaceModeMessageHandler[INTERFACEMODE_CAPTURE_BOAT][KeyEvents.KeyUp]		= OnPlacementKeyUp;

	InterfaceModeMessageHandler[INTERFACEMODE_SHORE_PARTY] = {};
	InterfaceModeMessageHandler[INTERFACEMODE_SHORE_PARTY][INTERFACEMODE_ENTER] = OnInterfaceModeChange_ShoreParty;
	InterfaceModeMessageHandler[INTERFACEMODE_SHORE_PARTY][INTERFACEMODE_LEAVE] = OnInterfaceModeLeave_ShoreParty;
	InterfaceModeMessageHandler[INTERFACEMODE_SHORE_PARTY][MouseEvents.LButtonUp] = OnMouseEnd_ShoreParty;
	InterfaceModeMessageHandler[INTERFACEMODE_SHORE_PARTY][KeyEvents.KeyUp]		= OnPlacementKeyUp;

	InterfaceModeMessageHandler[INTERFACEMODE_SHORE_PARTY_EMBARK] = {};
	InterfaceModeMessageHandler[INTERFACEMODE_SHORE_PARTY_EMBARK][INTERFACEMODE_ENTER] = OnInterfaceModeChange_ShorePartyEmbark;
	InterfaceModeMessageHandler[INTERFACEMODE_SHORE_PARTY_EMBARK][INTERFACEMODE_LEAVE] = OnInterfaceModeLeave_ShorePartyEmbark;
	InterfaceModeMessageHandler[INTERFACEMODE_SHORE_PARTY_EMBARK][MouseEvents.LButtonUp] = OnMouseEnd_ShorePartyEmbark;
	InterfaceModeMessageHandler[INTERFACEMODE_SHORE_PARTY_EMBARK][KeyEvents.KeyUp]		= OnPlacementKeyUp;

	InterfaceModeMessageHandler[INTERFACEMODE_DREAD_PIRATE_ACTIVE] = {};
	InterfaceModeMessageHandler[INTERFACEMODE_DREAD_PIRATE_ACTIVE][INTERFACEMODE_ENTER] = OnInterfaceModeChange_CaptureBoatTypeAction;
	InterfaceModeMessageHandler[INTERFACEMODE_DREAD_PIRATE_ACTIVE][INTERFACEMODE_LEAVE] = OnInterfaceModeLeave_CaptureBoatTypeAction;
	InterfaceModeMessageHandler[INTERFACEMODE_DREAD_PIRATE_ACTIVE][MouseEvents.LButtonUp] = OnMouseEnd_DreadPirateActive;
	InterfaceModeMessageHandler[INTERFACEMODE_DREAD_PIRATE_ACTIVE][KeyEvents.KeyUp]		= OnPlacementKeyUp;

	InterfaceModeMessageHandler[INTERFACEMODE_PRIVATEER_ACTIVE] = {};
	InterfaceModeMessageHandler[INTERFACEMODE_PRIVATEER_ACTIVE][INTERFACEMODE_ENTER] = OnInterfaceModeChange_CaptureBoatTypeAction;
	InterfaceModeMessageHandler[INTERFACEMODE_PRIVATEER_ACTIVE][INTERFACEMODE_LEAVE] = OnInterfaceModeLeave_CaptureBoatTypeAction;
	InterfaceModeMessageHandler[INTERFACEMODE_PRIVATEER_ACTIVE][MouseEvents.LButtonUp] = OnMouseEnd_PrivateerActive;
	InterfaceModeMessageHandler[INTERFACEMODE_PRIVATEER_ACTIVE][KeyEvents.KeyUp]		= OnPlacementKeyUp;

	InterfaceModeMessageHandler[INTERFACEMODE_HOARDER_ACTIVE] = {};
	InterfaceModeMessageHandler[INTERFACEMODE_HOARDER_ACTIVE][INTERFACEMODE_ENTER] = OnInterfaceModeChange_HoarderActive;
	InterfaceModeMessageHandler[INTERFACEMODE_HOARDER_ACTIVE][INTERFACEMODE_LEAVE] = OnInterfaceModeLeave_CaptureBoatTypeAction;
	InterfaceModeMessageHandler[INTERFACEMODE_HOARDER_ACTIVE][MouseEvents.LButtonUp] = OnMouseEnd_HoarderActive;
	InterfaceModeMessageHandler[INTERFACEMODE_HOARDER_ACTIVE][KeyEvents.KeyUp]		= OnPlacementKeyUp;
end
