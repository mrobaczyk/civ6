-- ===========================================================================
--	Unit Panel Replacement/Extension
--	Pirates Scenario
-- ===========================================================================
include "UnitPanel"
include "PiratesScenario_PropKeys"
include "PiratesScenario_UnitCommandDefs"
include "PiratesScenario_Shared_Script"

local m_ActivateReason_BRING_HER_HOME 			= DB.MakeHash("BRING_HER_HOME");
local m_ActivateReason_BRING_HER_HOME_TARGET	= DB.MakeHash("BRING_HER_HOME_TARGET");
local m_ActivateReason_CAPTURED 				= DB.MakeHash("CAPTURED");
local m_ActivateReason_CAREENING 				= DB.MakeHash("CAREENING");
local m_ActivateReason_CHAIN_SHOT	 			= DB.MakeHash("CHAIN_SHOT");
local m_ActivateReason_CHAIN_SHOT_TARGET		= DB.MakeHash("CHAIN_SHOT_TARGET");
local m_ActivateReason_DISEMBARK 				= DB.MakeHash("DISEMBARK");
local m_ActivateReason_INFAMOUS_SUNK 			= DB.MakeHash("INFAMOUS_SUNK");
local m_ActivateReason_SUNK_GOLD_SHIP 			= DB.MakeHash("SUNK_GOLD_SHIP");
local m_ActivateReason_TACK_INTO_WIND 			= DB.MakeHash("TACK_INTO_WIND");
local m_ActivateReason_VISIT_TAVERN 			= DB.MakeHash("VISIT_TAVERN");
local m_ActivateReason_WALK_THE_PLANK 			= DB.MakeHash("WALK_THE_PLANK");
local m_ActivateReason_WALK_THE_PLANK_TARGET 	= DB.MakeHash("WALK_THE_PLANK_TARGET");

-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_AddActionButton = AddActionButton;
BASE_FilterUnitStatsFromUnitData = FilterUnitStatsFromUnitData;
BASE_GetCombatModifierList = GetCombatModifierList;
BASE_GetUnitActionsTable = GetUnitActionsTable;
BASE_LateInitialize	= LateInitialize;
BASE_OnShowCombat = OnShowCombat;
BASE_ShowSubjectUnitStats = ShowSubjectUnitStats;

-- ===========================================================================
--	OVERRIDE BASE FUNCTIONS
-- ===========================================================================
function GetUnitActionsTable(pUnit : object)
	local pBaseActionsTable : table = BASE_GetUnitActionsTable(pUnit);

	--Disable plunder action if treasure has the same owner as unit
	for k,v in ipairs(pBaseActionsTable["ATTACK"])do
		if(v.IconId == "ICON_UNITOPERATION_PILLAGE")then
			local pPlot : object = Map.GetPlotByIndex(pUnit:GetPlotId());
			if(pUnit:GetOwner() == pPlot:GetImprovementOwner())then
				v.Disabled = true;
				v.helpString = Locale.Lookup("LOC_UNITOPERATION_PILLAGE_DESCRIPTION") .. "[NEWLINE][NEWLINE]" .. Locale.Lookup("LOC_UNITOPERATION_PILLAGE_DISABLED_TT_OWN_TREASURE");
			end
		end
	end

	-- Scenario Unit Commands
	--	Test all custom commands in table defined in m_ScenarioUnitCommands to add
	--	to the selected unit's table.
	for sCommandKey, pCommandTable in pairs(m_ScenarioUnitCommands) do
		local bVisible : boolean = true;
		if (pCommandTable.IsVisible ~= nil) then
			bVisible = pCommandTable.IsVisible(pUnit);
		end
		if (bVisible) then

			if (pCommandTable.CanUse ~= nil and pCommandTable.CanUse(pUnit) == true) then

				local bIsDisabled : boolean = false;
				if (pCommandTable.IsDisabled ~= nil) then
					bIsDisabled = pCommandTable.IsDisabled(pUnit);
				end
			
				local sToolTipString : string = pCommandTable.ToolTipString or "Undefined Unit Command";
				sToolTipString = Locale.Lookup(sToolTipString);

				local pCallback : ifunction = function()
					local pSelectedUnit = UI.GetHeadSelectedUnit();
					if (pSelectedUnit == nil) then
						return;
					end

					if(pCommandTable.EventName ~= nil) then
						-- EventName is the name of the GameCore lua script event that should be triggered to start this unit action.
						local tParameters = {};
						tParameters[UnitCommandTypes.PARAM_NAME] = pCommandTable.EventName or "";
						tParameters.CommandSubType = pCommandTable.CommandSubType;
						UnitManager.RequestCommand(pSelectedUnit, UnitCommandTypes.EXECUTE_SCRIPT, tParameters);
					elseif(pCommandTable.InterfaceMode ~= nil) then
						-- InterfaceMode is the InterfaceModeTypes that should be triggered for this unit action
						UI.SetInterfaceMode(pCommandTable.InterfaceMode);

						-- WorldInput handles things from here.
					end
				end

				if (bIsDisabled and pCommandTable.GetDisabledTTString ~= nil) then
					local disabledToolTip :string = pCommandTable.GetDisabledTTString(pUnit);
					if(disabledToolTip ~= nil) then
						disabledToolTip = Locale.Lookup(disabledToolTip);
						sToolTipString = sToolTipString .. "[NEWLINE][NEWLINE]" .. disabledToolTip;
					end
				end

				AddActionToTable(pBaseActionsTable, pCommandTable, bIsDisabled, sToolTipString, UnitCommandTypes.EXECUTE_SCRIPT, pCallback);
			end
		end
	end

	return pBaseActionsTable;
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function FilterUnitStatsFromUnitData(unitData : table, ignoreStatType : number)
	local pBaseData : table = BASE_FilterUnitStatsFromUnitData(unitData, ignoreStatType);

	local pUnitStats = {};
	local pUnit : object = UnitManager.GetUnit(unitData.Owner, unitData.UnitID);
	if (pUnit ~= nil) then
		-- Display Crew
		local iCrewProp : number = pUnit:GetProperty(g_unitPropertyKeys.Crew);
		if (iCrewProp ~= nil) then
			table.insert(pUnitStats, {
				Value = iCrewProp,	
				Type = "SpreadCharges", 
				Label = "LOC_HUD_UNIT_PANEL_CREW",				
				FontIcon ="[ICON_Charges_Large]",	
				IconName ="ICON_PIRATES_CREW"
			});
		end
	end

	-- Place the base unit stats after the scenario ones.
	for __, pBaseUnitStat in ipairs(pBaseData) do
		table.insert(pUnitStats, pBaseUnitStat);
	end

	return pUnitStats;
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function ShowSubjectUnitStats(showCombat:boolean)

	local subjectData : table = GetSubjectData();
	local ownerID : number = subjectData.Owner;
	if(IsPiratePlayer(ownerID))then

		ResetSubjectStatStack();
		local isCivilian	:boolean = GameInfo.Units[subjectData.UnitType].FormationClass == "FORMATION_CLASS_CIVILIAN";

		if(not showCombat)then
			subjectData.StatData = FilterUnitStatsFromUnitData(subjectData);

			--Early out for any units that aren't ships with crew
			if(#subjectData.StatData <= 4)then 
				BASE_ShowSubjectUnitStats(showCombat);
			else
				if(#subjectData.CurrentPromotions > 0)then
					Controls.UnitPanelBaseContainer:SetSizeY(188);
					Controls.HealthMeterContainer:SetOffsetY(151);
					Controls.UnitIcon:SetOffsetY(50);
					Controls.SelectionPanelUnitPortrait:SetOffsetY(43);
				else
					Controls.UnitPanelBaseContainer:SetSizeY(170);
					Controls.HealthMeterContainer:SetOffsetY(133);
					Controls.UnitIcon:SetOffsetY(32);
					Controls.SelectionPanelUnitPortrait:SetOffsetY(25);
				end
				Controls.SubjectStatContainer:SetOffsetVal(86,56);
				Controls.SubjectStatContainer:SetParentRelativeSizeX(-105);
				AddUnitStat(1, subjectData.StatData[1], subjectData, 0, true);
				AddUnitStat(2, subjectData.StatData[2], subjectData, -10, true);
				AddUnitStat(3, subjectData.StatData[3], subjectData, -12, true);
				AddUnitStat(4, subjectData.StatData[4], subjectData, -8, true);
				AddUnitStat(5, subjectData.StatData[5], subjectData, 0, true);
			end
		else
			subjectData.StatData = GetCombatStats();

			--Early out for any units that aren't ships with crew
			if(#subjectData.StatData <= 3) then
				BASE_ShowSubjectUnitStats(showCombat);
			else
				if(#subjectData.CurrentPromotions > 0) then
					Controls.HealthMeterContainer:SetOffsetY(133);
					Controls.UnitIcon:SetOffsetY(32);
					Controls.SelectionPanelUnitPortrait:SetOffsetY(25);
				end
				Controls.SubjectStatContainer:SetOffsetVal(86,112);
				Controls.SubjectStatContainer:SetSizeX(72);
				AddUnitStat(2, subjectData.StatData[2], subjectData, -12, false);
				AddUnitStat(3, subjectData.StatData[3], subjectData, -12, false);
				AddUnitStat(4, subjectData.StatData[4], subjectData, 0, false);
			end
		end
	else
		BASE_ShowSubjectUnitStats(showCombat);
	end
end

-- ===========================================================================
-- OVERRIDE 
-- Hide the Rest and Repair operation for naval units
-- ===========================================================================
function AddActionButton( instance:table, action:table )
	if(action.IconId == "ICON_UNITOPERATION_HEAL")then
		local pUnit : table = UI.GetHeadSelectedUnit();
		local unitInfo : table = GameInfo.Units[pUnit:GetUnitType()];
		if(unitInfo.Domain == "DOMAIN_SEA")then
			instance.UnitActionButton:SetHide(true);
			return;
		end
	end
	BASE_AddActionButton(instance, action);
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function OnShowCombat( showCombat )
	BASE_OnShowCombat(showCombat);
	Controls.PromotionBanner:SetHide(true);
end

-- ===========================================================================
-- OVERRIDE
-- ===========================================================================
function GetCombatModifierList(combatantHash:number)
	local kModifierList : table, modifierListSize : number = BASE_GetCombatModifierList(combatantHash);
	local lastModifierText : string = "";
	for k,v in ipairs(kModifierList)do
		--Remove duplicate modifier text (seemingly caused by Colonial Power dummy abilities needed elsewhere)
		if(v.text == lastModifierText)then
			table.remove(kModifierList, k);
		end
		lastModifierText = v.text;
	end

	return kModifierList, modifierListSize;
end

-- ===========================================================================
-- Unit Activate
-- ===========================================================================
function OnUnitActivate(owner : number, unitID : number, x : number, y : number, eReason : number, bVisibleToLocalPlayer : boolean)		
	if bVisibleToLocalPlayer then
		local pUnit = UnitManager.GetUnit(owner, unitID);
		if pUnit ~= nil then
			--Trigger custom animations based on the Activate event.
			if eReason == m_ActivateReason_CAREENING then
				SimUnitSystem.SetAnimationState(pUnit, "ATTACK_4", "IDLE");				
			end
			if eReason == m_ActivateReason_DISEMBARK then
				SimUnitSystem.SetAnimationState(pUnit, "SPAWN", "IDLE");
			end
			if eReason == m_ActivateReason_TACK_INTO_WIND then
				SimUnitSystem.SetAnimationState(pUnit, "SPAWN", "IDLE");
			end
			if eReason == m_ActivateReason_CAPTURED then
				SimUnitSystem.SetAnimationState(pUnit, "ATTACK_3", "IDLE");
			end
			if eReason == m_ActivateReason_INFAMOUS_SUNK then
				SimUnitSystem.SetAnimationState(pUnit, "ATTACK_2", "IDLE");
			end
			if eReason == m_ActivateReason_VISIT_TAVERN then
				SimUnitSystem.SetAnimationState(pUnit, "ATTACK_1", "IDLE");				
			end
			if eReason == m_ActivateReason_SUNK_GOLD_SHIP then
				WorldView.PlayEffectAtXY("PIRATE_GOLD_SHIP_SUNK", pUnit:GetX(), pUnit:GetY());				
			end
			if eReason == m_ActivateReason_BRING_HER_HOME then				
				WorldView.PlayEffectAtXY("BRING_HER_HOME", pUnit:GetX(), pUnit:GetY());				
			end
			if eReason == m_ActivateReason_WALK_THE_PLANK then
				WorldView.PlayEffectAtXY("WALK_THE_PLANK", pUnit:GetX(), pUnit:GetY());				
			end
			if eReason == m_ActivateReason_BRING_HER_HOME_TARGET then
				WorldView.PlayEffectAtXY("BRING_HER_HOME_TARGET", pUnit:GetX(), pUnit:GetY());				
			end
			if eReason == m_ActivateReason_WALK_THE_PLANK_TARGET then
				SimUnitSystem.SetAnimationState(pUnit, "DEATH_A", "DEATH_A");			
				WorldView.PlayEffectAtXY("WALK_THE_PLANK_TARGET", pUnit:GetX(), pUnit:GetY());				
			end
			if eReason == m_ActivateReason_CHAIN_SHOT then
				SimUnitSystem.SetAnimationState(pUnit, "ATTACK_P", "IDLE");	
			end
			if eReason == m_ActivateReason_CHAIN_SHOT_TARGET then				
				WorldView.PlayEffectAtXY("CHAIN_SHOT_TARGET", pUnit:GetX(), pUnit:GetY());				
			end
		end
	end
end


-- ===========================================================================
function Subscribe()
	Events.UnitActivate.Add(OnUnitActivate);	
end

-- ===========================================================================
function LateInitialize()
	BASE_LateInitialize();	
	Subscribe();
end