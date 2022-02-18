-- Copyright 2020, Firaxis Games

include("NaturalDisasterPopup");

BASE_ShowPopup = ShowPopup;

-- ===========================================================================
function ShowPopup( kData:table )
	BASE_ShowPopup(kData);
	if(kData.EffectOperatorType == "COMET_STRIKE")then
		Controls.PlotDamagedLabel:SetText(kData.FertilityAdded);
		Controls.PlotDamagedContainer:SetHide(false);
		Controls.PlotFertileContainer:SetHide(true);
	end
end