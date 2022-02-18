-- ===========================================================================
--	Unit Panel Replacement/Extension
--	CivRoyale Scenario
-- ===========================================================================

include "UnitPanel"
include "CivRoyaleScenario_PropKeys"
include "CivRoyaleScenario_UnitCommandDefs"

-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_GetUnitActionsTable			= GetUnitActionsTable;
BASE_FilterUnitStatsFromUnitData	= FilterUnitStatsFromUnitData;
BASE_ShowSubjectUnitStats			= ShowSubjectUnitStats;
BASE_LateInitialize					= LateInitialize;
BASE_ShowCombatAssessment			= ShowCombatAssessment;
BASE_ReadTargetData_Unit			= ReadTargetData_Unit;
BASE_ReadUnitData					= ReadUnitData;
BASE_AddActionToTable				= AddActionToTable;
BASE_AddActionButton				= AddActionButton;
BASE_AddTargetUnitStat				= AddTargetUnitStat;


-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local NO_PLAYER						:number = -1;
local m_kSubjectData				:table	= {};
local m_kLinkedSubjectData			:table	= {};
local m_kCombatResults				:table	= {};
local m_kLinkedSubjectStatStackIM	:table	= InstanceManager:new( "LinkedStatInstance", "StatGrid", Controls.LinkedStatStack );


local g_ActivateReason_ZOMBIE_SPAWN = DB.MakeHash("ZOMBIE_SPAWN");

function InitLinkedData()
	m_kLinkedSubjectData = 
	{
		Name						= "",
		Combat						= 0,
		RangedCombat				= 0,
		BombardCombat				= 0,
		ReligiousCombat				= 0,
		Range						= 0,
		Damage						= 0,
		MaxDamage					= 0,
		PotentialDamage				= 0,
		WallDamage					= 0,
		MaxWallDamage				= 0,
		PotentialWallDamage			= 0,
		BuildCharges				= 0,
		DisasterCharges				= 0,
		ActionCharges				= 0,	-- req by base lua
		SpreadCharges				= 0,
		HealCharges					= 0,
		ReligiousStrength			= 0,
		GreatPersonActionCharges	= 0,
		Moves						= 0,
		MaxMoves					= 0,
		InterceptorName				= "",
		InterceptorCombat			= 0,
		InterceptorDamage			= 0,
		InterceptorMaxDamage		= 0,
		InterceptorPotentialDamage	= 0,
		AntiAirName					= "",
		AntiAirCombat				= 0,
		StatData					= nil,
		UnitType                    = -1,
		UnitID						= 0,
		HasDefenses					= false, --Tells is whether we need to display combat data
		HasImprovementOrDistrict	= false, -- Only used if the tile does not have defenses
		PrimaryColor				= 0xdeadbeef,
		SecondaryColor				= 0xbaadf00d;
	};
end

-- ===========================================================================
function ReadLinkedData_Unit( pkLinked:table )
	-- Build target data for a unit
	local unitGreatPerson = pkLinked:GetGreatPerson();
	local iconName, iconNamePrefixOnly, iconNameEraOnly, fallbackIconName = GetUnitPortraitIconNames( pkLinked );

	m_kLinkedSubjectData.Name						= Locale.Lookup( pkLinked:GetName() );
	m_kLinkedSubjectData.IconName					= iconName;
	m_kLinkedSubjectData.PrefixOnlyIconName			= iconNamePrefixOnly;
	m_kLinkedSubjectData.EraOnlyIconName			= iconNameEraOnly;
	m_kLinkedSubjectData.FallbackIconName			= fallbackIconName;
	m_kLinkedSubjectData.Combat						= pkLinked:GetCombat();
	m_kLinkedSubjectData.RangedCombat				= pkLinked:GetRangedCombat();
	m_kLinkedSubjectData.BombardCombat				= pkLinked:GetBombardCombat();
	m_kLinkedSubjectData.AntiAirCombat				= pkLinked:GetAntiAirCombat();
	m_kLinkedSubjectData.ReligiousCombat			= pkLinked:GetReligiousStrength();
	m_kLinkedSubjectData.Range						= pkLinked:GetRange();
	m_kLinkedSubjectData.Damage						= pkLinked:GetDamage();
	m_kLinkedSubjectData.MaxDamage					= pkLinked:GetMaxDamage();
	m_kLinkedSubjectData.BuildCharges				= pkLinked:GetBuildCharges();
	m_kLinkedSubjectData.DisasterCharges			= pkLinked:GetDisasterCharges();
	m_kLinkedSubjectData.ActionCharges				= 0;
	m_kLinkedSubjectData.SpreadCharges				= pkLinked:GetSpreadCharges();
	m_kLinkedSubjectData.HealCharges				= pkLinked:GetReligiousHealCharges();
	m_kLinkedSubjectData.ReligiousStrength			= pkLinked:GetReligiousStrength();
	m_kLinkedSubjectData.GreatPersonActionCharges	= unitGreatPerson:GetActionCharges();
	m_kLinkedSubjectData.Moves						= pkLinked:GetMovesRemaining();
	m_kLinkedSubjectData.MaxMoves					= pkLinked:GetMaxMoves();
	m_kLinkedSubjectData.UnitType					= pkLinked:GetUnitType();
	m_kLinkedSubjectData.UnitID						= pkLinked:GetID();
	m_kLinkedSubjectData.HasDefenses				= true;
end

-- ===========================================================================
--	OVERRIDE BASE FUNCTIONS 
-- ===========================================================================
function GetUnitActionsTable(pUnit : object)
	local pBaseActionsTable : table = BASE_GetUnitActionsTable(pUnit);

	-- Scenario Unit Commands
	--	Test all custom commands in table defined in "BlackDeathScenario_UnitCommands" to add
	--	to the selected unit's table.
	for sCommandKey, pCommandTable in pairs(m_ScenarioUnitCommands) do
		local bVisible : boolean = true;
		local bGlobal : boolean = false;
		if(pCommandTable.IsGlobal ~= nil and pCommandTable.IsGlobal)then
			--Global abilities (Grieving Gift, Road Vision, etc.) should not be shown in the unit panel
			bGlobal = true;
		end
		if (pCommandTable.IsVisible ~= nil) then
			bVisible = pCommandTable.IsVisible(pUnit);
		end
		if (bVisible and not bGlobal) then

			if (pCommandTable.CanUse ~= nil and pCommandTable.CanUse(pUnit) == true) then

				local bIsDisabled : boolean = false;
				if (pCommandTable.IsDisabled ~= nil) then
					bIsDisabled = pCommandTable.IsDisabled(pUnit);
				end
			
				local sToolTipString : string;
				if(pCommandTable.GetToolTipString ~= nil) then
					sToolTipString = pCommandTable.GetToolTipString(pUnit);
				else
					sToolTipString = pCommandTable.ToolTipString or "Undefined Unit Command";
				end 
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
						UnitManager.RequestCommand(pSelectedUnit, UnitCommandTypes.EXECUTE_SCRIPT, tParameters);
					elseif(pCommandTable.InterfaceMode ~= nil) then
						-- InterfaceMode is the InterfaceModeTypes that should be triggered for this unit action
						UI.SetInterfaceMode(pCommandTable.InterfaceMode);

						-- WorldInput handles things from here.
					end
				end

				local overrideIcon :string = nil;
				if(pCommandTable.GetIcon ~= nil) then
					overrideIcon = pCommandTable.GetIcon(pUnit);
				end

				if (bIsDisabled and pCommandTable.GetDisabledTTString ~= nil) then
					local disabledToolTip :string = pCommandTable.GetDisabledTTString(pUnit);
					if(disabledToolTip ~= nil) then
						disabledToolTip = Locale.Lookup(disabledToolTip);
						sToolTipString = sToolTipString .. "[NEWLINE][NEWLINE]" .. "[COLOR:Red]" .. disabledToolTip .. "[ENDCOLOR]";
					end
				end
				if(pCommandTable.IsActive ~= nil)then
					local unitID : number = pUnit:GetID();
					local ownerID : number = pUnit:GetOwner();
					AddRedDeathActionToTable(pBaseActionsTable, pCommandTable, bIsDisabled, sToolTipString, UnitCommandTypes.EXECUTE_SCRIPT, pCallback, ownerID, unitID, overrideIcon);
				else
					BASE_AddActionToTable(pBaseActionsTable, pCommandTable, bIsDisabled, sToolTipString, UnitCommandTypes.EXECUTE_SCRIPT, pCallback, nil, nil, overrideIcon);
				end
			end
		end
	end

	return pBaseActionsTable;
end

-- ===========================================================================
--	Add a toggleable unit action (i.e. Mutant Radiation Spread)
-- ===========================================================================
function AddRedDeathActionToTable( actionsTable:table, action:table, disabled:boolean, toolTipString:string, actionHash:number, callbackFunc:ifunction, ownerID:number, unitID:number, overrideIcon:string)
	local actionsCategoryTable:table;
	if ( actionsTable[action.CategoryInUI] ~= nil ) then
		actionsCategoryTable = actionsTable[action.CategoryInUI];
	else
		UI.DataError("Operation is in unsupported action category '" .. tostring(action.CategoryInUI) .. "'.");
		actionsCategoryTable = actionsTable["SPECIFIC"];
	end

	-- Wrap every callback function with a call that guarantees the interface 
	-- mode is reset.  It prevents issues such as selecting range attack and
	-- then instead of attacking, choosing another action, which would leave
	-- up the range attack lens layer.
	local wrappedCallback:ifunction = 
		function(void1,void2)			
			local currentMode :number = UI.GetInterfaceMode();
			if currentMode ~= InterfaceModeTypes.SELECTION then
				UI.SetInterfaceMode( InterfaceModeTypes.SELECTION );
			end
			callbackFunc(void1, void2, currentMode);
		end;	

	table.insert( actionsCategoryTable, {
		IconId				= (overrideIcon and overrideIcon) or action.Icon,
		Disabled			= disabled,
		helpString			= toolTipString,
		userTag				= actionHash,
		CallbackFunc		= wrappedCallback,
		IsActive			= action.IsActive,
		OwnerID				= ownerID,
		UnitID				= unitID,
		ActiveSound			= action.ActiveSound,
		NotActiveSound		= action.NotActiveSound
		});
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function AddActionButton( instance:table, action:table )
	instance.UnitActionButton:SetSelected(false);
	BASE_AddActionButton(instance, action);
	if(action.IsActive ~= nil)then
		instance.UnitActionButton:RegisterCallback( Mouse.eLClick, 
				function(void1,void2)
					if action.Sound ~= nil and action.Sound ~= "" then
						UI.PlaySound(action.Sound);
					end
					action.CallbackFunc(void1,void2);
					if action.IsActive(action.OwnerID, action.UnitID) then
						if action.ActiveSound ~= nil and action.ActiveSound ~= "" then
							UI.PlaySound(action.ActiveSound);
						end
					else
						if action.NotActiveSound ~= nil and action.NotActiveSound ~= "" then
							UI.PlaySound(action.NotActiveSound);
						end
					end
				end
			);
		instance.UnitActionButton:SetSelected(action.IsActive(action.OwnerID, action.UnitID));
	end
	local pPlayerConfig : table = PlayerConfigurations[Game.GetLocalPlayer()];
	if(pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Jocks)then
		if(action.IconId == "ICON_UNITOPERATION_WMD_STRIKE" and action.Disabled)then
			local lastHailMaryTurn : number = Players[Game.GetLocalPlayer()]:GetProperty("HailMaryTurn");
			if(lastHailMaryTurn == nil)then return; end
			local currentTurn : number = Game.GetCurrentGameTurn();
			local turnsRemaining : number = 6 - (currentTurn - lastHailMaryTurn);
			local toolTipString : string = instance.UnitActionButton:GetToolTipString() .. " " .. Locale.Lookup("LOC_WMD_HAIL_MARY_DISABLED_COOLDOWN", turnsRemaining);
			instance.UnitActionButton:SetToolTipString(toolTipString);
		end
	end
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function ShowCombatAssessment()
	BASE_ShowCombatAssessment();
	m_kCombatResults = GetCombatPreviewResults();
	
	local defender = m_kCombatResults[CombatResultParameters.DEFENDER];
	local damageToDefender = defender[CombatResultParameters.DAMAGE_TO];
	local defenderID = defender[CombatResultParameters.ID];
	
	LuaEvents.UnitPanel_CivRoyaleScenarioShowUnitFlagCombatPreview( damageToDefender, defenderID.player, defenderID.id );
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function ReadTargetData_Unit( pkDefender:table )
	BASE_ReadTargetData_Unit( pkDefender );
	g_targetData.IconName = g_targetData.FallbackIconName .. "_" .. PlayerConfigurations[pkDefender:GetOwner()]:GetCivilizationTypeName();
end


-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function ReadUnitData( kUnit:table )
	kSubjectData = BASE_ReadUnitData( kUnit );
	kSubjectData.IconName = kSubjectData.FallbackIconName.. "_" .. PlayerConfigurations[Game.GetLocalPlayer()]:GetCivilizationTypeName();
	return kSubjectData;
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function ShowSubjectUnitStats(showCombat:boolean)
	local kSubjectData : table = GetSubjectData();
	if kSubjectData == nil then
		return;
	end

	kSubjectData.StatData = FilterUnitStatsFromUnitData(kSubjectData);
	local linkedUnitPanelOffsetY : number = 0;
	if(not showCombat and #kSubjectData.StatData > 4) then
		ResetSubjectStatStack();
		if(#kSubjectData.CurrentPromotions < 1)then
			Controls.UnitPanelBaseContainer:SetSizeY(182);
			Controls.SubjectStatContainer:SetOffsetVal(86,58);
			Controls.SubjectStatContainer:SetParentRelativeSizeX(-105);
			Controls.HealthMeterContainer:SetOffsetY(145);
			Controls.UnitIcon:SetOffsetY(43);
			Controls.SelectionPanelUnitPortrait:SetOffsetY(37);

			linkedUnitPanelOffsetY = 8;

			AddUnitStat(1, kSubjectData.StatData[1], kSubjectData, 0, true);
			AddUnitStat(2, kSubjectData.StatData[2], kSubjectData, -10, true);
			AddUnitStat(3, kSubjectData.StatData[3], kSubjectData, -12, true);
			AddUnitStat(4, kSubjectData.StatData[4], kSubjectData, -8, true);
			AddUnitStat(5, kSubjectData.StatData[5], kSubjectData, 0, true);

			Controls.XPArea:SetSizeY(20);
			Controls.PromotionBanner:SetOffsetY(10);
			Controls.XPLabel:SetFontSize(14);
		else
			Controls.UnitPanelBaseContainer:SetSizeY(192);
			Controls.SubjectStatContainer:SetOffsetVal(86,58);
			Controls.SubjectStatContainer:SetParentRelativeSizeX(-105);
			Controls.HealthMeterContainer:SetOffsetY(155);
			Controls.UnitIcon:SetOffsetY(53);
			Controls.SelectionPanelUnitPortrait:SetOffsetY(47);

			linkedUnitPanelOffsetY = 18;

			AddUnitStat(1, kSubjectData.StatData[1], kSubjectData, 0, true);
			AddUnitStat(2, kSubjectData.StatData[2], kSubjectData, -10, true);
			AddUnitStat(3, kSubjectData.StatData[3], kSubjectData, -12, true);
			AddUnitStat(4, kSubjectData.StatData[4], kSubjectData, -8, true);
			AddUnitStat(5, kSubjectData.StatData[5], kSubjectData, 0, true);

			Controls.XPArea:SetSizeY(10);
			Controls.PromotionBanner:SetOffsetY(0);
			Controls.XPLabel:SetFontSize(10);
			Controls.XPLabel:SetOffsetY(1);
		end
	elseif(showCombat) then
		BASE_ShowSubjectUnitStats(showCombat);
		Controls.HealthMeterContainer:SetOffsetY(133);
		Controls.UnitIcon:SetOffsetY(31);
		Controls.SelectionPanelUnitPortrait:SetOffsetY(25);
		Controls.XPArea:SetSizeY(10);
		Controls.PromotionBanner:SetOffsetY(0);
		Controls.XPLabel:SetFontSize(10);
		Controls.XPLabel:SetOffsetY(1);
	else
		if(#kSubjectData.CurrentPromotions < 1)then
			Controls.XPArea:SetSizeY(20);
			Controls.PromotionBanner:SetOffsetY(10);
			Controls.XPLabel:SetFontSize(14);
		else
			Controls.XPArea:SetSizeY(10);
			Controls.PromotionBanner:SetOffsetY(0);
			Controls.XPLabel:SetFontSize(10);
			Controls.XPLabel:SetOffsetY(1);
		end
		BASE_ShowSubjectUnitStats(showCombat);
		Controls.HealthMeterContainer:SetOffsetY(133);
		Controls.UnitIcon:SetOffsetY(31);
		Controls.SelectionPanelUnitPortrait:SetOffsetY(25);
	end
	Controls.LinkedUnitPanel:SetOffsetY(linkedUnitPanelOffsetY);
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function AddTargetUnitStat(statData:table, relativeSizeX:number)
	if(statData.Type == "SpreadCharges")then
		return;
	else
		BASE_AddTargetUnitStat(statData, relativeSizeX);
	end
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function AddUnitToUnitList(pUnit:table)
	-- Create entry
	local unitEntry:table = {};
	Controls.UnitListPopup:BuildEntry( "UnitListEntry", unitEntry );

	local formation = pUnit:GetMilitaryFormation();
	local suffix:string = "";
	local unitInfo:table = GameInfo.Units[pUnit:GetUnitType()];
	if (unitInfo.Domain == "DOMAIN_SEA") then
		if (formation == MilitaryFormationTypes.CORPS_FORMATION) then
			suffix = " " .. Locale.Lookup("LOC_HUD_UNIT_PANEL_FLEET_SUFFIX");
		elseif (formation == MilitaryFormationTypes.ARMY_FORMATION) then
			suffix = " " .. Locale.Lookup("LOC_HUD_UNIT_PANEL_ARMADA_SUFFIX");
		end
	else
		if (formation == MilitaryFormationTypes.CORPS_FORMATION) then
			suffix = " " .. Locale.Lookup("LOC_HUD_UNIT_PANEL_CORPS_SUFFIX");
		elseif (formation == MilitaryFormationTypes.ARMY_FORMATION) then
			suffix = " " .. Locale.Lookup("LOC_HUD_UNIT_PANEL_ARMY_SUFFIX");
		end
	end

	local name:string = pUnit:GetName();
	local uniqueName = Locale.Lookup( name ) .. suffix;

	local tooltip:string = "";
	local pUnitDef = GameInfo.Units[pUnit:GetUnitType()];
	if pUnitDef then
		local unitTypeName:string = pUnitDef.Name;
		if name ~= unitTypeName then
			tooltip = uniqueName .. " " .. Locale.Lookup("LOC_UNIT_UNIT_TYPE_NAME_SUFFIX", unitTypeName);
		end
	end
	unitEntry.Button:SetToolTipString(tooltip);

	unitEntry.Button:SetText( Locale.ToUpper(uniqueName) );
	unitEntry.Button:SetVoids(i, pUnit:GetID());

	-- Update unit icon
	local pUnitInfo : table = GameInfo.Units[pUnit:GetUnitType()];
	local unitIcon : string = "ICON_" .. pUnitInfo.UnitType;
	if(pUnitInfo.UnitType == "UNIT_WARRIOR")then
		unitEntry.UnitTypeIcon:SetTexture( 0, 0, "RedDeath_Zombies22.dds");
	else
		local iconInfo:table, iconShadowInfo:table = GetUnitIcon(pUnit, 22, true);
		if iconInfo.textureSheet then
				unitEntry.UnitTypeIcon:SetTexture( iconInfo.textureOffsetX, iconInfo.textureOffsetY, iconInfo.textureSheet );
		end
	end

	-- Update status icon
	local activityType:number = UnitManager.GetActivityType(pUnit);
	if activityType == ActivityTypes.ACTIVITY_SLEEP then
		SetUnitEntryStatusIcon(unitEntry, "ICON_STATS_SLEEP");
	elseif activityType == ActivityTypes.ACTIVITY_HOLD then
		SetUnitEntryStatusIcon(unitEntry, "ICON_STATS_SKIP");
	elseif activityType ~= ActivityTypes.ACTIVITY_AWAKE and pUnit:GetFortifyTurns() > 0 then
		SetUnitEntryStatusIcon(unitEntry, "ICON_DEFENSE");
	else
		unitEntry.UnitStatusIcon:SetHide(true);
	end

	-- Update entry color if unit cannot take any action
	if pUnit:IsReadyToMove() then
		unitEntry.Button:GetTextControl():SetColorByName("UnitPanelTextCS");
		unitEntry.UnitTypeIcon:SetColorByName("UnitPanelTextCS");
	else
		unitEntry.Button:GetTextControl():SetColorByName("UnitPanelTextDisabledCS");
		unitEntry.UnitTypeIcon:SetColorByName("UnitPanelTextDisabledCS");
	end
end

-- ===========================================================================
function PopulateLinkedUnitPanelStats(kUnit:table, unitList:table)
	for i, pUnit in ipairs(unitList) do
		if pUnit:GetName() ~= kUnit:GetName() and pUnit:GetFormationUnitCount() > 1 then
			ReadLinkedData_Unit( pUnit );
			Controls.LinkedUnitName:SetText( Locale.ToUpper( pUnit:GetName() ));
			m_kLinkedSubjectStatStackIM:ResetInstances();
			local percent:number = 1 - GetPercentFromDamage( m_kLinkedSubjectData.Damage, m_kLinkedSubjectData.MaxDamage );
			RealizeHealthMeter( Controls.LinkedHealthMeter, percent, Controls.LinkedHealthMeterShadow, percent );
			m_kLinkedSubjectData.IconName, m_kLinkedSubjectData.PrefixOnlyIconName, m_kLinkedSubjectData.EraOnlyIconName, m_kLinkedSubjectData.FallbackIconName = GetUnitPortraitIconNames( pUnit );
			local overrideIconName = m_kLinkedSubjectData.FallbackIconName.. "_" .. PlayerConfigurations[Game.GetLocalPlayer()]:GetCivilizationTypeName();
			if overrideIconName ~= nil and Controls.LinkedUnitIcon:TrySetIcon(overrideIconName) then
				break;
			elseif m_kLinkedSubjectData.IconName ~= nil and Controls.LinkedUnitIcon:TrySetIcon(m_kLinkedSubjectData.IconName) then
				break;
			elseif m_kLinkedSubjectData.PrefixOnlyIconName ~= nil and Controls.LinkedUnitIcon:TrySetIcon(m_kLinkedSubjectData.PrefixOnlyIconName) then
				break;
			elseif m_kLinkedSubjectData.EraOnlyIconName ~= nil and Controls.LinkedUnitIcon:TrySetIcon(m_kLinkedSubjectData.EraOnlyIconName) then
				break;
			elseif m_kLinkedSubjectData.FallbackIconName ~= nil and Controls.LinkedUnitIcon:TrySetIcon(m_kLinkedSubjectData.FallbackIconName) then
				break;
			end			
		end			
	end
	ShowLinkedSubjectUnitStats();
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function OnLinkedUnitAction_EnterFormation( kUnitInstance:table )
	if g_isOkayToProcess then
		local pSelectedUnit :object = UI.GetHeadSelectedUnit();
		if ( pSelectedUnit ~= nil and kUnitInstance ~= nil ) then
			local tParameters :table = {};
			tParameters[UnitCommandTypes.PARAM_UNIT_PLAYER] = kUnitInstance:GetOwner();
			tParameters[UnitCommandTypes.PARAM_UNIT_ID] = kUnitInstance:GetID();
			UnitManager.RequestCommand( pSelectedUnit, UnitCommandTypes.ENTER_FORMATION, tParameters );
		end
		PopulateLinkedUnitPanelStats( pSelectedUnit, kUnitInstance );
		if pSelectedUnit and pSelectedUnit:GetFormationUnitCount() > 1 then
			Controls.LinkedUnitPanel:SetHide(false);
		else
			Controls.LinkedUnitPanel:SetHide(true);
		end
		Controls.LinkedUnitName:SetText( Locale.ToUpper( m_kLinkedSubjectData.Name ));
	end
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function OnLinkedUnitSelectionChanged(player:number, unitId:number, locationX:number, locationY:number, locationZ:number, isSelected:boolean, isEditable:boolean)
	local unitList	:table	= Units.GetUnitsInPlotLayerID( locationX, locationY, MapLayers.ANY );
	local units		:table	= Players[player]:GetUnits(); 
	local unit		:table	= units:FindID(unitId);
	m_kLinkedSubjectStatStackIM:ResetInstances();
	if (unit and unit:GetFormationUnitCount() > 1 and table.count(unitList)>0 ) then
		Controls.LinkedUnitPanel:SetHide(false);
		Controls.LinkedUnitName:SetText( Locale.ToUpper( unit:GetName() ));		
		PopulateLinkedUnitPanelStats(unit, unitList);
	else
		Controls.LinkedUnitPanel:SetHide(true);
	end
end

-- ===========================================================================
function FilterUnitStatsFromUnitData(unitData : table, ignoreStatType : number)
	local pBaseData : table = BASE_FilterUnitStatsFromUnitData(unitData, ignoreStatType);

	local pUnit : object = UnitManager.GetUnit(unitData.Owner, unitData.UnitID);
	if (pUnit ~= nil) then
		-- Display Radiation Charges
		local iRadChargesProp : number = pUnit:GetProperty(g_unitStateKeys.RadiationCharges);
		if (iRadChargesProp ~= nil and iRadChargesProp > 0) then
			table.insert(pBaseData, {
				Value = iRadChargesProp,	
				Type = "SpreadCharges", 
				Label = "LOC_HUD_UNIT_PANEL_CHARGES",				
				FontIcon ="[ICON_Charges_Large]",	
				IconName ="ICON_STATS_SPREADCHARGES"
			});
		end

		-- Display Trap Charges
		if(pUnit:GetOwner() ~= NO_PLAYER) then
			local pOwner :object = Players[pUnit:GetOwner()];
			if(pOwner ~= nil) then
				local trapCountProp :number = pOwner:GetProperty(g_playerPropertyKeys.ImprovisedTrapCount);
				if(trapCountProp ~= nil and trapCountProp > 0) then
					table.insert(pBaseData, {
						Value = trapCountProp,	
						Type = "SpreadCharges", 
						Label = "LOC_UNIT_PANEL_TRAPS",				
						FontIcon ="[ICON_Charges_Large]",	
						IconName ="ICON_STATS_SPREADCHARGES"
					});
				end
			end
		end
	end

	return pBaseData;
end

-- ===========================================================================
function ShowLinkedSubjectUnitStats()
	m_kLinkedSubjectStatStackIM:ResetInstances();
	m_kLinkedSubjectData.StatData = FilterUnitStatsFromUnitData(m_kLinkedSubjectData);

	local currentStatIndex:number = 0;
	for i,entry in ipairs(m_kLinkedSubjectData.StatData) do
		if currentStatIndex == 0 then
			AddLinkedUnitStat(i, entry, m_kLinkedSubjectData, 0, false);
		elseif currentStatIndex == 1 then
			AddLinkedUnitStat(i, entry, m_kLinkedSubjectData, -12, false);
		elseif currentStatIndex == 2 then
			AddLinkedUnitStat(i, entry, m_kLinkedSubjectData, -12, false);
		elseif currentStatIndex == 3 then
			AddLinkedUnitStat(i, entry, m_kLinkedSubjectData, 0, false);
		elseif currentStatIndex == 4 then
			AddLinkedUnitStat(i, entry, m_kLinkedSubjectData, 0, false);
		end
		currentStatIndex = currentStatIndex + 1;
	end
	Controls.LinkedStatContainer:SetOffsetVal(20,49);
	Controls.LinkedStatContainer:SetParentRelativeSizeX(-115);
	Controls.LinkedStatStack:CalculateSize();
end

-- ===========================================================================
function AddLinkedUnitStat(statType:number, statData:table, unitData:table, relativeSizeX:number, showName:boolean)
	local statInstance:table = m_kLinkedSubjectStatStackIM:GetInstance();
	if not statInstance then
		return;
	end
	-- Set relative size x
	statInstance.StatGrid:SetParentRelativeSizeX(relativeSizeX);
	-- Update name
	TruncateStringWithTooltip(statInstance.StatNameLabel, MAX_BEFORE_TRUNC_STAT_NAME, Locale.ToUpper(statData.Label));
	m_kSubjectData = GetSubjectData();
	-- Update values
	if statData.Type ~= nil and statData.Type == "BaseMoves" then
		if(m_kSubjectData ~= nil and unitData.Moves < m_kSubjectData.Moves ) then
			statInstance.StatValueLabel:SetText(unitData.Moves);
			statInstance.StatValueLabel:SetString("[COLOR:Red]" .. unitData.Moves .. "[ENDCOLOR]");
		else
			statInstance.StatValueLabel:SetText(unitData.Moves);
		end
		statInstance.StatMaxValueLabel:SetText(statData.Value);
		statInstance.StatValueSlash:SetHide(false);
		statInstance.StatMaxValueLabel:SetHide(false);
		statInstance.StatValueStack:CalculateSize();
	else
		statInstance.StatValueLabel:SetText(statData.Value);
		statInstance.StatValueSlash:SetHide(true);
		statInstance.StatMaxValueLabel:SetHide(true);
	end
	-- Show/Hide stat name
	if showName then
		statInstance.StatNameLabel:SetHide(false);
	else
		statInstance.StatNameLabel:SetHide(true);
	end
	-- Update icon
	local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(statData.IconName,22);
	statInstance.StatCheckBox:SetCheckTexture(textureSheet);
	statInstance.StatCheckBox:SetUnCheckTexture(textureSheet)
	statInstance.StatCheckBox:SetCheckTextureOffsetVal(textureOffsetX,textureOffsetY);
	statInstance.StatCheckBox:SetUnCheckTextureOffsetVal(textureOffsetX,textureOffsetY);
end

-------------------------------------------------
-- Unit Formations
-------------------------------------------------
function OnEnterFormation(playerID1, unitID1, playerID2, unitID2)
	local pPlayer = Players[ playerID1 ];
	if (pPlayer ~= nil) then
		local pUnit = pPlayer:GetUnits():FindID(unitID1);
		if (pUnit ~= nil) then
			ReadLinkedData_Unit( pUnit );
			Controls.LinkedUnitName:SetText( Locale.ToUpper( pUnit:GetName() ));
			m_kLinkedSubjectStatStackIM:ResetInstances();
			local percent:number = 1 - GetPercentFromDamage( m_kLinkedSubjectData.Damage, m_kLinkedSubjectData.MaxDamage );
			RealizeHealthMeter( Controls.LinkedHealthMeter, percent, Controls.LinkedHealthMeterShadow, percent );
			m_kLinkedSubjectData.IconName, m_kLinkedSubjectData.PrefixOnlyIconName, m_kLinkedSubjectData.EraOnlyIconName, m_kLinkedSubjectData.FallbackIconName = GetUnitPortraitIconNames( pUnit );
			local isIconSet:boolean = false;
			if m_kLinkedSubjectData.IconName ~= nil and Controls.LinkedUnitIcon:TrySetIcon(m_kLinkedSubjectData.IconName) then
				isIconSet = true;
			elseif m_kLinkedSubjectData.PrefixOnlyIconName ~= nil and Controls.LinkedUnitIcon:TrySetIcon(m_kLinkedSubjectData.PrefixOnlyIconName) then
				isIconSet = true;
			elseif m_kLinkedSubjectData.EraOnlyIconName ~= nil and Controls.LinkedUnitIcon:TrySetIcon(m_kLinkedSubjectData.EraOnlyIconName) then
				isIconSet = true;
			elseif m_kLinkedSubjectData.FallbackIconName ~= nil and Controls.LinkedUnitIcon:TrySetIcon(m_kLinkedSubjectData.FallbackIconName)then
				isIconSet = true;
			end				
			if isIconSet then
				OnLinkedUnitAction_EnterFormation( pUnit );
				ShowLinkedSubjectUnitStats();
			end
		end
	end
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function IsActionLimited(actionType : string, pUnit : table)
	local localPlayerCivType = PlayerConfigurations[Game.GetLocalPlayer()]:GetCivilizationTypeName();
	if(actionType == "WMD_HAIL_MARY") then
		if(localPlayerCivType == g_CivTypeNames.Jocks)then
			return false;
		else
			return true;
		end
	elseif(actionType == "WMD_NUCLEAR_DEVICE" or actionType == "WMD_THERMONUCLEAR_DEVICE")then
		return true;
	elseif(actionType == "UNITOPERATION_HEAL")then
		if(localPlayerCivType == g_CivTypeNames.Zombies and pUnit:GetType() == GameInfo.Units["UNIT_WARRIOR"].Index)then
			return true;
		elseif(pUnit:GetType() == GameInfo.Units["UNIT_CRIPPLED_GDR"].Index)then
			local pUnitExp : table = pUnit:GetExperience();
			local requiredPromotion = GameInfo.UnitPromotions["PROMOTION_GDR_LIMITED_HEAL"];
			if(not pUnitExp:HasPromotion(requiredPromotion.Index))then
				return true;
			end
		end
	end
	return false;
end

-------------------------------------------------
-- Unit Activate
-------------------------------------------------
function OnUnitActivate(owner : number, unitID : number, x : number, y : number, eReason : number, bVisibleToLocalPlayer : boolean)
	if bVisibleToLocalPlayer then

		local pUnit = UnitManager.GetUnit(owner, unitID);
		if pUnit ~= nil then			
			-- Trigger custom animations based on the Activate event.
			if eReason == g_ActivateReason_ZOMBIE_SPAWN then
				SimUnitSystem.SetAnimationState(pUnit, "SPAWN", "IDLE");
			end
		end
	end
end

-- ===========================================================================
function OnShutdown()
	Unsubscribe();
end

-- ===========================================================================
function Unsubscribe()
	Events.UnitActivate.Remove(OnUnitActivate);
	Events.UnitEnterFormation.Remove( OnEnterFormation );
	Events.UnitExitFormation.Remove( OnLinkedUnitSelectionChanged );
	Events.UnitSelectionChanged.Remove( OnLinkedUnitSelectionChanged );
end

-- ===========================================================================
function Subscribe()
	Events.UnitActivate.Add(OnUnitActivate);
	Events.UnitEnterFormation.Add( OnEnterFormation );
	Events.UnitExitFormation.Add( OnLinkedUnitSelectionChanged );
	Events.UnitSelectionChanged.Add( OnLinkedUnitSelectionChanged );
end

-- ===========================================================================
function LateInitialize()
	BASE_LateInitialize();
	Controls.LinkedSelectionPanelUnitPortrait:RegisterCallback( Mouse.eLClick, OnPortraitClick );
	ContextPtr:SetShutdown( OnShutdown );
	Subscribe();
end