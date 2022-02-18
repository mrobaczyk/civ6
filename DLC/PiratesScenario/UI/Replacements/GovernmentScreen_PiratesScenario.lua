-- Copyright 2020, Firaxis Games
include("GovernmentScreen");

--Cache Base Functions
BASE_LateInitialize = LateInitialize;
BASE_OnOpenGovernmentScreen = OnOpenGovernmentScreen;
BASE_RealizeTabs = RealizeTabs;
BASE_RealizeActivePoliciesRows = RealizeActivePoliciesRows;
BASE_Resize = Resize;
BASE_Close = Close;

local SIZE_RELIC_CARD_X	:number = 157;
local SIZE_MAX_POLICY_CATALOG_X : number = 680;

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function OnOpenGovernmentScreen()
	EffectsManager:PauseAllEffects();
	LuaEvents.RelicScreen_RelicScreenOpened();

	--Open directly to the policy tab
	BASE_OnOpenGovernmentScreen(3);
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function RealizeTabs()
	BASE_RealizeTabs();
	if(not Controls.ButtonMyGovernment:IsHidden())then
		Controls.ButtonMyGovernment:SetHide(true);
	end

	Controls.ButtonPolicies:LocalizeAndSetText("LOC_RELIC_SCREEN_CHOOSE_RELIC");
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function GetPolicyCardSizeX()
	return SIZE_RELIC_CARD_X;
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function IsAbleToChangePolicies()
	local localPlayerID : number = Game.GetLocalPlayer();
	if(localPlayerID == -1)then
		return false;
	end

	local kPlayer		:table = Players[localPlayerID];
	local kPlayerCulture:table = kPlayer:GetCulture();

	--Players can only change relic loadout once per turn
	if (kPlayerCulture:PolicyChangeMade() == false) then
		return true;
	end 
	return false;
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function RealizePolicyCard( cardInstance:table, policyType:string )
	local kPolicy :table = GetPolicyFromCatalog(policyType);
	cardInstance.Title:SetText( kPolicy.Name );
	
	 -- Offset to below the card title, sans the shadow padding
	local nMinOffsetY : number = cardInstance.TitleContainer:GetSizeY() - 5;

	 -- Remaining space, with a -15 to account for the fact that the card image is alpha bordered by ~5 pixels, and that we want some offset from the card bottom.
	cardInstance.DescriptionContainer:SetSizeY(cardInstance.Background:GetSizeY() - nMinOffsetY - 15);
	cardInstance.DescriptionContainer:SetOffsetY(nMinOffsetY);
	cardInstance.Description:SetText(kPolicy.Description);
	cardInstance.Draggable:SetToolTipString(kPolicy.Name .. "[NEWLINE][NEWLINE]" .. kPolicy.Description);

	if IsAbleToChangePolicies() then
		cardInstance.Button:RegisterMouseEnterCallback(function() cardInstance.Background:SetOffsetY(-5); end);
		cardInstance.Button:RegisterMouseExitCallback(function() cardInstance.Background:SetOffsetY(0); end);
	else
		cardInstance.Button:ClearMouseEnterCallback();
		cardInstance.Button:ClearMouseExitCallback();
	end
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function RealizeActivePoliciesRows()
	BASE_RealizeActivePoliciesRows();
	if(Game.GetLocalPlayer() ~= PlayerTypes.NONE)then
		Controls.ConfirmPolicies:SetHide(false);
		if(GetHavePoliciesChanged())then
			Controls.ConfirmPolicies:SetDisabled(false);
			Controls.ConfirmPolicies:SetText(GetConfirmPoliciesText());
		else
			if(not Controls.UnlockPolicies:IsHidden())then
				Controls.UnlockPolicies:SetHide(true);
			end
			Controls.ConfirmPolicies:SetDisabled(true);
			Controls.ConfirmPolicies:SetText(GetAssignAllPoliciesText());
		end
	end
	Controls.WildcardLabelRight:SetHide(true);
	Controls.WildcardCounter:SetHide(true);
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function Resize()
	BASE_Resize();
	local screenWidth : number, _ = UIManager:GetScreenSizeVal();
	local sizeX : number = math.min( SIZE_MAX_POLICY_CATALOG_X, (screenWidth/2));

	Controls.PoliciesContainer:SetSizeX(sizeX);
	Controls.PoliciesContainer:SetOffsetX(sizeX/2);

	Controls.PolicyRows:SetSizeX(sizeX);
	Controls.PolicyRows:SetOffsetX(-sizeX/2);
end

function Close()
	EffectsManager:ResumeAllEffects();
	BASE_Close();
end

-- ===========================================================================
-- OVERRIDE
-- Since we aren't switching tabs, we don't want this changing our offsets
-- ===========================================================================
function OnRowAnimCallback()
	RealizeActivePolicyRowSize();
end

-- ===========================================================================
-- OVERRIDE
-- Since changing relics is free, we don't need the confirm dialogue to popup
-- ===========================================================================
function ShouldConfirmChanges()
	return false;
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function GetAssignAllPoliciesText()
	return Locale.Lookup("LOC_RELIC_SCREEN_ASSIGN_ALL_RELICS");
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function GetConfirmPoliciesText()
	return Locale.Lookup("LOC_RELIC_SCREEN_CONFIRM_RELICS");
end

function GetEmptyPolicySlotTexture(typeIndex : number)
	return "Relics_EmptyCard";
end

-- ===========================================================================
-- OVERRIDE
-- We only have the one type of relic slot, so no need for any tabs
-- ===========================================================================
function RealizeFilterTabs()
	
end

function LateInitialize()
	BASE_LateInitialize();

	Controls.ModalScreenTitle:SetText(Locale.ToUpper("LOC_RELIC_SCREEN_TITLE"));
	Controls.LabelWildcard:SetText(Locale.ToUpper("LOC_RELIC_SCREEN_ACTIVE_RELICS"));

	Controls.RowAnim:RegisterAnimCallback(OnRowAnimCallback);
end