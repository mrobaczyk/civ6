-- Copyright 2020, Firaxis Games

-- ===========================================================================
--	Popups when a Pirate Relic is found
-- ===========================================================================
include("TechCivicCompletedPopup");

local m_unlockIM : table = InstanceManager:new( "UnlockInstance", "Top", Controls.UnlockStack );

local MAX_RELIC_INFO_SIZE : number = 75;
local MIN_RELIC_INFO_SIZE : number = 30;
local MAX_RELIC_QUOTE_SIZE : number = 150;
local MIN_RELIC_QUOTE_SIZE : number = 100;
local QUOTE_PADDING : number = 30;

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function ShowCivicCompletedPopup(player:number, civic:number, quote:string, audio:string)
	local civicInfo:table = GameInfo.Civics[civic];
	if civicInfo == nil then
		UI.DataError("Cannot show civic popup because GameInfo.Civics["..tostring(civic).."] doesn't have data.");
		return;
	end
		
	local civicType = civicInfo.CivicType;
	Controls.ResearchIcon:SetTexture("ICON_" .. civicType);
	Controls.ResearchName:SetText(Locale.ToUpper(Locale.Lookup(civicInfo.Name)));

	--Fill in the relic effect and flavor text
	local unlockableTypes = GetUnlockablesForCivic(civicType, player);
	if(unlockableTypes ~= nil and #unlockableTypes > 0)then
		local relicEffect : string = "LOC_"..unlockableTypes[1][1].."_DESCRIPTION";
		Controls.RelicInfoLabel:LocalizeAndSetText(relicEffect);

		local flavorText : string = GameInfo.Civics[civic].Description;
		Controls.QuoteLabel:LocalizeAndSetText(flavorText);
	end

	UI.PlaySound("Notification_New_Relic");
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function RefreshSize()
	local quoteHeight : number = math.min(MAX_RELIC_QUOTE_SIZE, Controls.QuoteLabel:GetSizeY() + QUOTE_PADDING);
	quoteHeight = math.max(MIN_RELIC_QUOTE_SIZE, quoteHeight);
	Controls.QuoteButton:SetSizeY(quoteHeight);

	local relicInfoHeight : number = math.min(MAX_RELIC_INFO_SIZE, Controls.RelicInfoLabel:GetSizeY());
	relicInfoHeight = math.max(MIN_RELIC_INFO_SIZE, relicInfoHeight);
	Controls.RelicInfoPanel:SetSizeY(relicInfoHeight);

	Controls.PopupBackgroundImage:DoAutoSize();
	Controls.PopupDrowShadowGrid:DoAutoSize();
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function LateInitialize()
	Controls.ChangeGovernmentButton:RegisterCallback( Mouse.eLClick, OnChangePolicy );
	Controls.ChangeGovernmentButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
end