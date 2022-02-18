-- Copyright 2020, Firaxis Games 

include("WorldTracker.lua");
include("PiratesScenario_PropKeys");
include("ToolTipHelper_PlayerYields");

--	CACHE BASE FUNCTIONS
BASE_LateInitialize = LateInitialize;
BASE_OnLocalPlayerTurnBegin = OnLocalPlayerTurnBegin;
BASE_Refresh = Refresh;
BASE_Unsubscribe = Unsubscribe;

local MINIMAP_PADDING	: number = 120;
local GOLD_BACKING_START_OFFSET_X : number = -24;
local GOLD_BACKING_START_SIZE_X : number = 97;

local m_uiCrewMoraleInstance : table = {};

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function Refresh()
	ContextPtr:ClearRequestRefresh();
	BASE_Refresh();
	UpdateCrewMorale();
end

-- ===========================================================================
-- ===========================================================================
function UpdateCrewMorale()
	local localPlayer		:table = Players[Game.GetLocalPlayer()];
	local playerTreasury	:table	= localPlayer:GetTreasury();
	local goldPerTurn		:number = math.floor(playerTreasury:GetGoldYield() - playerTreasury:GetTotalMaintenance());
	local goldBalance		:number = math.floor(playerTreasury:GetGoldBalance());

	m_uiCrewMoraleInstance.GoldAmountLabel:SetText(Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_GOLD", goldBalance));
	m_uiCrewMoraleInstance.GoldUsageLabel:SetText(Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_GOLD_USAGE", goldPerTurn));
	m_uiCrewMoraleInstance.GoldBacking:SetToolTipString( GetGoldTooltip() );

	local currentTurn : number = Game.GetCurrentGameTurn();
	local lastHadGoldTurn :number = localPlayer:GetProperty(g_playerPropertyKeys.LastHadGoldTurn);
	if(lastHadGoldTurn == nil)then
		lasHadGoldTurn = currentTurn;
	end

	if(goldPerTurn > 0)then
		m_uiCrewMoraleInstance.MutinyTurnsLabel:SetText(Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_PROFIT"));
	elseif(goldPerTurn == 0)then
		m_uiCrewMoraleInstance.MutinyTurnsLabel:SetText(Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_STABLE"));
	elseif(goldBalance > 0)then
		local turnsUntilMutiny	:number = math.ceil(goldBalance/-goldPerTurn) + PIRATE_BANKRUPTCY_MUTINY_DELAY;

		m_uiCrewMoraleInstance.MutinyTurnsLabel:SetText(Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_MUTINY_TURNS", turnsUntilMutiny));
		if(turnsUntilMutiny > 5)then
			m_uiCrewMoraleInstance.CrewMoraleImage:SetIcon("ICON_CREW_MORALE_GOOD");
		else
			m_uiCrewMoraleInstance.CrewMoraleImage:SetIcon("ICON_CREW_MORALE_BAD");
		end
	--Mutiny begins after two turns of having no gold
	elseif(currentTurn < (lastHadGoldTurn + PIRATE_BANKRUPTCY_MUTINY_DELAY))then
		local turnsUntilMutiny	:number = (lastHadGoldTurn + PIRATE_BANKRUPTCY_MUTINY_DELAY) - currentTurn;
		m_uiCrewMoraleInstance.MutinyTurnsLabel:SetText(Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_MUTINY_TURNS", turnsUntilMutiny));
		m_uiCrewMoraleInstance.CrewMoraleImage:SetIcon("ICON_CREW_MORALE_MUTINY");
	else
		--Mutiny has begun
		m_uiCrewMoraleInstance.CrewMoraleImage:SetIcon("ICON_CREW_MORALE_MUTINY");
		local pPlayerUnits:table = localPlayer:GetUnits();
		local numUnits:number = pPlayerUnits:GetCount() - 1;	--Do not include the flagship in the unit count since that can not be lost to mutiny

		if(numUnits > 0)then
			m_uiCrewMoraleInstance.MutinyTurnsLabel:SetText(Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_TOTAL_MUTINY_TURNS"), numUnits);
		else
			m_uiCrewMoraleInstance.MutinyTurnsLabel:SetText(Locale.Lookup("LOC_PIRATES_MORALE_TRACKER_NO_MORE_UNITS"));
		end
	end

	local goldBackingSizeX : number = m_uiCrewMoraleInstance.GoldBacking:GetSizeX();
	if(goldBackingSizeX > GOLD_BACKING_START_SIZE_X)then
		local sizeDiff : number = goldBackingSizeX - GOLD_BACKING_START_SIZE_X;
		m_uiCrewMoraleInstance.GoldBacking:SetOffsetX(GOLD_BACKING_START_OFFSET_X + sizeDiff);
	else
		m_uiCrewMoraleInstance.GoldBacking:SetOffsetX(GOLD_BACKING_START_OFFSET_X);
	end

	EffectsManager:PlayEffect(m_uiCrewMoraleInstance.GoldIcon, "FireFX_PirateGoldSparkle", { PausedWhenHidden=true, Delay=0.3 } );
end

-- ===========================================================================
-- EVENTS
-- ===========================================================================
function OnTreasuryChanged()
	ContextPtr:RequestRefresh();
end

function OnUnitAddedToMap()
	ContextPtr:RequestRefresh();
end

function OnUnitRemovedFromMap()
	ContextPtr:RequestRefresh();
end

function OnPolicyChanged()
	ContextPtr:RequestRefresh();
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function OnLocalPlayerTurnBegin()
	BASE_OnLocalPlayerTurnBegin();
	ContextPtr:RequestRefresh();
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function GetMinimapPadding()
	return MINIMAP_PADDING;
end

-- ===========================================================================
function Unsubscribe()
	BASE_Unsubscribe();

	Events.GovernmentPolicyChanged.Add(OnPolicyChanged);
	Events.TreasuryChanged.Remove(OnTreasuryChanged);
	Events.UnitAddedToMap.Remove(OnUnitAddedToMap);
	Events.UnitRemovedFromMap.Remove(OnUnitRemovedFromMap);
	Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin);
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function LateInitialize()
	ContextPtr:SetRefreshHandler( Refresh );
	ContextPtr:BuildInstanceForControl( "CrewMoraleInstance", m_uiCrewMoraleInstance, Controls.CrewMoraleStack );
	m_uiCrewMoraleInstance.GoldAmountLabel:SetColorByName("ResGoldLabelCS");
	m_uiCrewMoraleInstance.GoldUsageLabel:SetColorByName("ResGoldLabelCS");	
	m_uiCrewMoraleInstance.GoldBacking:SetColorByName("ResGoldLabelCS");
	m_uiCrewMoraleInstance.CrewMoraleImage:SetIcon("ICON_CREW_MORALE_GOOD");

	BASE_LateInitialize();

	Events.GovernmentPolicyChanged.Add(OnPolicyChanged);
	Events.TreasuryChanged.Add(OnTreasuryChanged);
	Events.UnitAddedToMap.Add(OnUnitAddedToMap);
	Events.UnitRemovedFromMap.Add(OnUnitRemovedFromMap);
	Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin);

	Refresh();
end