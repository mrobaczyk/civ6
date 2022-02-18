--[[
-- Copyright (c) 2017-2018 Firaxis Games
--]]
-- ===========================================================================
-- INCLUDE BASE FILE
-- ===========================================================================
include("WorldInput");
include("CivRoyaleScenario_PropKeys");

InterfaceModeTypes.GRIEVING_GIFT	= 0x1D7FAB3F;				-- This is actually the hash value of "INTERFACEMODE_GRIEVING_GIFT" but standard lua exposures for interfacemodes drop the "INTERFACEMODE_"


-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_LateInitialize			= LateInitialize;


------------------------------------------------------------------------------------------------
-- Code related to the Grieving Gift Global Ability for BorderLords
------------------------------------------------------------------------------------------------
function OnMouseGrievingGiftEnd(pInputStruct)
	-- If a drag was occurring, end it; otherwise raise event.
	if g_isMouseDragging then
		g_isMouseDragging = false;
	elseif IsSelectionAllowedAt( UI.GetCursorPlotID() ) then		
		DropGrievingGift(pInputStruct);
	end
	EndDragMap();
	g_isMouseDownInWorld = false;
	return true;
end
------------------------------------------------------------------------------------------------
function DropGrievingGift(pInputStruct)
	local plotID = UI.GetCursorPlotID();
	if Map.IsPlot(plotID) then
		local plot = Map.GetPlotByIndex(plotID);
		local pSelectedUnit = UI.GetHeadSelectedUnit();
		
		if(pSelectedUnit ~= nil) then
			local tParameters = {};
			tParameters[UnitCommandTypes.PARAM_X] = plot:GetX();
			tParameters[UnitCommandTypes.PARAM_Y] = plot:GetY();
			tParameters[UnitCommandTypes.PARAM_NAME] = "ScenarioCommand_GrievingGift";
			UnitManager.RequestCommand(pSelectedUnit, UnitCommandTypes.EXECUTE_SCRIPT, tParameters);
			UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
			UI.PlaySound("Unit_Airlift");
		else
			print("ERROR: Missing head selected unit");
		end
	end
	return true;
end
------------------------------------------------------------------------------------------------
function OnInterfaceModeChange_GrievingGift(eNewMode)
	UIManager:SetUICursor(CursorTypes.RANGE_ATTACK);
end
--------------------------------------------------------------------------------------------------
function OnInterfaceModeLeave_GrievingGift(eNewMode:number)
	UIManager:SetUICursor(CursorTypes.NORMAL);
end


-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function LateInitialize()

	BASE_LateInitialize();

	InterfaceModeMessageHandler[InterfaceModeTypes.GRIEVING_GIFT] = {};
	InterfaceModeMessageHandler[InterfaceModeTypes.GRIEVING_GIFT][INTERFACEMODE_ENTER]= OnInterfaceModeChange_GrievingGift;
	InterfaceModeMessageHandler[InterfaceModeTypes.GRIEVING_GIFT][INTERFACEMODE_LEAVE] = OnInterfaceModeLeave_GrievingGift;
	InterfaceModeMessageHandler[InterfaceModeTypes.GRIEVING_GIFT][MouseEvents.LButtonUp] = OnMouseGrievingGiftEnd;
	InterfaceModeMessageHandler[InterfaceModeTypes.GRIEVING_GIFT][KeyEvents.KeyUp]		= OnPlacementKeyUp;
end
