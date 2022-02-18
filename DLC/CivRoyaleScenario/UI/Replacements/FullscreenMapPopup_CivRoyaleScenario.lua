--[[
-- Created by Arthur Gould, June 26, 2019
-- Copyright (c) Firaxis Games
--]]
-- ===========================================================================
-- Base File
-- ===========================================================================
include("FullscreenMapPopup");


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local SAFE_ZONE_RING_PROP:string = "SafeZoneRing";
local m_eSupplyDropImprovement 		: number = GameInfo.Improvements["IMPROVEMENT_SUPPLY_DROP"].Index;
local m_eGoodyHutImprovement 		: number = GameInfo.Improvements["IMPROVEMENT_GOODY_HUT"].Index;
local m_eBarbarianCampImprovement 	: number = GameInfo.Improvements["IMPROVEMENT_BARBARIAN_CAMP"].Index;

-- ===========================================================================
--	Scenario Minimap Tooltips
-- ===========================================================================
function ShowMinimapTooltips(inputX:number, inputY:number)
	local ePlayer : number = Game.GetLocalPlayer(); 
	local pPlayerVis:table = PlayersVisibility[ePlayer];

	local minix, miniy = GetMinimapMouseCoords( inputX, inputY );
	if (pPlayerVis ~= nil) then
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
				Controls.MapProxy:SetToolTipString(pTooltipString);
			else
				local pTooltipString = Locale.Lookup("LOC_MINIMAP_FOG_OF_WAR_TOOLTIP");
				Controls.MapProxy:SetToolTipString(pTooltipString);
			end
			
			if (pFalloutManager:HasFallout(plotID)) then
				local pTooltipString = Locale.Lookup("LOC_MINIMAP_RED_DEATH_TOOLTIP");
				Controls.MapProxy:SetToolTipString(pTooltipString);		
			elseif safeZoneFlag ~= nil and safeZoneFlag > 0 then
				local pTooltipString = Locale.Lookup("LOC_MINIMAP_SAFE_ZONE_TOOLTIP");
				Controls.MapProxy:SetToolTipString(pTooltipString);				
			end
				
			if pPlayerVis:IsRevealed(plotID) then
				if (pPlot:GetImprovementType() == m_eGoodyHutImprovement) then	
					local pTooltipString = Locale.Lookup("LOC_CIV_ROYALE_IMPROVEMENT_GOODY_HUT_NAME");
					Controls.MapProxy:SetToolTipString(pTooltipString);
				elseif (pPlot:GetImprovementType() == m_eBarbarianCampImprovement) then	
					local pTooltipString = Locale.Lookup("LOC_IMPROVEMENT_BARBARIAN_CAMP_NAME");
					Controls.MapProxy:SetToolTipString(pTooltipString);			
				elseif (pPlot:GetImprovementType() == m_eSupplyDropImprovement) then
					local pTooltipString = Locale.Lookup("LOC_IMPROVEMENT_SUPPLY_DROP_NAME");
					Controls.MapProxy:SetToolTipString(pTooltipString);		
				end	
			end
		end
	end
end