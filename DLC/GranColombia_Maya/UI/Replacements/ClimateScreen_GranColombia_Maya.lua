--	Copyright 2019, Firaxis Games
 
-- ===========================================================================
include("ClimateScreen");

BASE_TabSelectOverview = TabSelectOverview;
BASE_RefreshCurrentEvent = RefreshCurrentEvent;

function TabSelectOverview()
	BASE_TabSelectOverview();

	local forestFireChance : number = GameClimate.GetFirePercentChance();
	local forestFireIncrease : number = GameClimate.GetFireClimateIncreasedChance();


	Controls.ForestFireActivityChanceNum:SetText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", forestFireChance));
	Controls.ForestFireChanceFromClimateChange:SetText( Locale.Lookup("LOC_CLIMATE_AMOUNT_FROM_CLIMATE_CHANGE", forestFireIncrease)  );	
end

function RefreshCurrentEvent()
	BASE_RefreshCurrentEvent();
	local kCurrentEvent:table = GameRandomEvents.GetCurrentTurnEvent();
	if kCurrentEvent ~= nil then 
		local kCurrentEventDef:table = GameInfo.RandomEvents[kCurrentEvent.RandomEvent];
		if kCurrentEventDef ~= nil then
			if(kCurrentEventDef.RandomEventType == "RANDOM_EVENT_COMET_STRIKE")then
				Controls.PlotDamagedLabel:SetText(kCurrentEvent.FertilityAdded);
				Controls.PlotDamagedContainer:SetHide(false);
				Controls.PlotFertileContainer:SetHide(true);
			end
		end
	end
end