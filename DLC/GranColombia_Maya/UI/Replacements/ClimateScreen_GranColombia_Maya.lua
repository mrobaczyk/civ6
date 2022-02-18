--	Copyright 2019, Firaxis Games
 
-- ===========================================================================
include("ClimateScreen");

BASE_TabSelectOverview = TabSelectOverview;

function TabSelectOverview()
	BASE_TabSelectOverview();

	local forestFireChance : number = GameClimate.GetFirePercentChance();
	local forestFireIncrease : number = GameClimate.GetFireClimateIncreasedChance();


	Controls.ForestFireActivityChanceNum:SetText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", forestFireChance));
	Controls.ForestFireChanceFromClimateChange:SetText( Locale.Lookup("LOC_CLIMATE_AMOUNT_FROM_CLIMATE_CHANGE", forestFireIncrease)  );	
end