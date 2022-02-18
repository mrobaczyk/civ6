include("CivRoyaleScenario_PropKeys");
include("CivRoyaleScenario_GameStateUtils");

--[[ =======================================================================

	Civ Royale Scenario Custom Unit Commands - Definitions

		Data and callbacks for enabling custom unit commands to appear and 
		work in the Unit Panel UI. These definitions mimic what appears in 
		data for common unit commands, and are used in the replacement 
		UnitPanel script.

-- =========================================================================]]
m_ScenarioUnitCommands = {};

local m_eCrippledGDR	:number = GameInfo.Units["UNIT_CRIPPLED_GDR"].Index;

InterfaceModeTypes.GRIEVING_GIFT	= 0x1D7FAB3F;				-- "INTERFACEMODE_GRIEVING_GIFT"


--[[ =======================================================================
	UNIT_SHIELD

	Useable by mad scientist faction to provide temp defensive shield to units.
-- =========================================================================]]
m_ScenarioUnitCommands.UNIT_SHIELD = {};

-- Study Command State Properties
m_ScenarioUnitCommands.UNIT_SHIELD.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.UNIT_SHIELD.EventName				= "ScenarioCommand_UnitShield";
m_ScenarioUnitCommands.UNIT_SHIELD.CategoryInUI				= "SPECIFIC";
m_ScenarioUnitCommands.UNIT_SHIELD.Icon						= "ICON_SCIENTIST_SHIELDING";
m_ScenarioUnitCommands.UNIT_SHIELD.ToolTipString			= "LOC_UNIT_SHIELD_TT";
m_ScenarioUnitCommands.UNIT_SHIELD.VisibleInUI				= true;

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_SHIELD.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.MadScientists) then
		return true;
	end
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_SHIELD.IsVisible(pUnit : object)
	return pUnit ~= nil;
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_SHIELD.IsDisabled(pUnit : object)
	-- Is the ability active or recharging?
	local abilityTimerStatus = GetUnitAbilityTimerStatus(pUnit, g_unitStateKeys.ShieldTime, MAD_SCIENTIST_SHIELD_DURATION, MAD_SCIENTIST_SHIELD_DEBOUNCE);
	if(abilityTimerStatus.Status ~= AbilityTimerStatusTypes.Status_Ready) then
		return true;
	end
	return false;
end

function m_ScenarioUnitCommands.UNIT_SHIELD.GetDisabledTTString(pUnit :object)
	local abilityTimerStatus = GetUnitAbilityTimerStatus(pUnit, g_unitStateKeys.ShieldTime, MAD_SCIENTIST_SHIELD_DURATION, MAD_SCIENTIST_SHIELD_DEBOUNCE);
	if(abilityTimerStatus.Status == AbilityTimerStatusTypes.Status_Active) then
		return Locale.Lookup("LOC_UNIT_SHIELD_ACTIVE_TT", abilityTimerStatus.TurnsRemaining);
	elseif(abilityTimerStatus.Status == AbilityTimerStatusTypes.Status_Recharging) then
		return Locale.Lookup("LOC_UNIT_SHIELD_RECHARGING_TT", abilityTimerStatus.TurnsRemaining);
	end
	return nil;
end

--[[ =======================================================================
	ROAD_VISION

	Useable by Wanderer faction to reveal all territory previously explored.
-- =========================================================================]]
m_ScenarioUnitCommands.ROAD_VISION = {};

-- Study Command State Properties
m_ScenarioUnitCommands.ROAD_VISION.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.ROAD_VISION.EventName				= "ScenarioCommand_RoadVision";
m_ScenarioUnitCommands.ROAD_VISION.CategoryInUI				= "SPECIFIC";
m_ScenarioUnitCommands.ROAD_VISION.Icon						= "ICON_WANDERERS_ROAD_VISION";
m_ScenarioUnitCommands.ROAD_VISION.ToolTipString			= "LOC_ROAD_VISION_TT";
m_ScenarioUnitCommands.ROAD_VISION.VisibleInUI				= true;
m_ScenarioUnitCommands.ROAD_VISION.Sound					= "RoadVision_Activate";

-- ===========================================================================
function m_ScenarioUnitCommands.ROAD_VISION.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Wanderers) then
		return true;
	end
end

-- ===========================================================================
function m_ScenarioUnitCommands.ROAD_VISION.IsVisible(pUnit : object)
	return pUnit ~= nil;
end

-- ===========================================================================
function m_ScenarioUnitCommands.ROAD_VISION.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	-- Check to see if road vision is still active or debouncing.
	local abilityTimerStatus = GetPlayerAbilityTimerStatus(pUnit:GetOwner(), g_playerPropertyKeys.RoadVisionTurn, WANDERER_ROAD_VISION_DURATION, WANDERER_ROAD_VISION_DEBOUNCE);
	if(abilityTimerStatus.Status ~= AbilityTimerStatusTypes.Status_Ready) then
		return true;
	end
	return false;
end

function m_ScenarioUnitCommands.ROAD_VISION.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local abilityTimerStatus = GetPlayerAbilityTimerStatus(pUnit:GetOwner(), g_playerPropertyKeys.RoadVisionTurn, WANDERER_ROAD_VISION_DURATION, WANDERER_ROAD_VISION_DEBOUNCE);
	if(abilityTimerStatus.Status == AbilityTimerStatusTypes.Status_Active) then
		return Locale.Lookup("LOC_ROAD_VISION_ACTIVE_TT", abilityTimerStatus.TurnsRemaining);
	elseif(abilityTimerStatus.Status == AbilityTimerStatusTypes.Status_Recharging) then
		return Locale.Lookup("LOC_ROAD_VISION_RECHARGING_TT", abilityTimerStatus.TurnsRemaining);
	end
	return nil;
end

--[[ =======================================================================
	PLACE_TRAP

	Useable by Prepper faction to build the Improvised Trap improvement at the current unit location.
-- =========================================================================]]
m_ScenarioUnitCommands.PLACE_TRAP = {};

-- Study Command State Properties
m_ScenarioUnitCommands.PLACE_TRAP.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.PLACE_TRAP.EventName			= "ScenarioCommand_PlaceTrap";
m_ScenarioUnitCommands.PLACE_TRAP.CategoryInUI		= "SPECIFIC";
m_ScenarioUnitCommands.PLACE_TRAP.Icon				= "ICON_PREPPERS_IMPROVISED_TRAP";
m_ScenarioUnitCommands.PLACE_TRAP.ToolTipString		= "LOC_PLACE_TRAP_TT";
m_ScenarioUnitCommands.PLACE_TRAP.VisibleInUI		= true;

-- ===========================================================================
function m_ScenarioUnitCommands.PLACE_TRAP.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Preppers) then
		return true;
	end
end

-- ===========================================================================
function m_ScenarioUnitCommands.PLACE_TRAP.IsVisible(pUnit : object)
	return pUnit ~= nil and pUnit:GetMovesRemaining() > 0;
end

-- ===========================================================================
function m_ScenarioUnitCommands.PLACE_TRAP.IsDisabled(pUnit : object)
	if (pUnit == nil or pUnit:GetMovesRemaining() == 0) then
		return true;
	end

	local pOwner :object = Players[pUnit:GetOwner()];
	if(pOwner == nil) then
		return true;
	end

	local trapCountProp :number = pOwner:GetProperty(g_playerPropertyKeys.ImprovisedTrapCount);
	if(trapCountProp == nil or trapCountProp <= 0) then
		return true;
	end
end

function m_ScenarioUnitCommands.PLACE_TRAP.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local pOwner :object = Players[pUnit:GetOwner()];
	if(pOwner == nil) then
		return nil;
	end

	local trapCountProp :number = pOwner:GetProperty(g_playerPropertyKeys.ImprovisedTrapCount);
	if(trapCountProp == nil or trapCountProp <= 0) then
		return "LOC_PLACE_TRAP_OUT_OF_TRAPS_TT";
	end

	return nil;
end


--[[ =======================================================================
	GRIEVING_GIFT

	Useable by EdgeLords faction to drop fake supply drops on the following turn.
-- =========================================================================]]
m_ScenarioUnitCommands.GRIEVING_GIFT = {};

-- Study Command State Properties
m_ScenarioUnitCommands.GRIEVING_GIFT.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.GRIEVING_GIFT.EventName			= nil;
m_ScenarioUnitCommands.GRIEVING_GIFT.CategoryInUI		= "SPECIFIC";
m_ScenarioUnitCommands.GRIEVING_GIFT.Icon				= "ICON_BORDERLORDS_GRIEVING_GIFT";
m_ScenarioUnitCommands.GRIEVING_GIFT.VisibleInUI		= true;
m_ScenarioUnitCommands.GRIEVING_GIFT.InterfaceMode		= InterfaceModeTypes.GRIEVING_GIFT;


-- ===========================================================================
function m_ScenarioUnitCommands.GRIEVING_GIFT.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.EdgeLords) then
		return true;
	end
end

-- ===========================================================================
function m_ScenarioUnitCommands.GRIEVING_GIFT.IsVisible(pUnit : object)
	return pUnit ~= nil;
end

-- ===========================================================================
function m_ScenarioUnitCommands.GRIEVING_GIFT.GetToolTipString(pUnit :object)
	local tooltipString :string = Locale.Lookup("LOC_GRIEVING_GIFT_TT");

	if (pUnit ~= nil) then
		local pOwner :object = Players[pUnit:GetOwner()];
		if(pOwner ~= nil) then
			local giftCountProp :number = pOwner:GetProperty(g_playerPropertyKeys.GrievingGiftCount);
			if(giftCountProp ~= nil and giftCountProp > 0) then
				tooltipString = tooltipString .. "[NEWLINE][NEWLINE]" .. Locale.Lookup("LOC_GRIEVING_GIFT_COUNT_TT", giftCountProp);
			end		
		end
	end

	return tooltipString;
end

-- ===========================================================================
function m_ScenarioUnitCommands.GRIEVING_GIFT.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	local pOwner :object = Players[pUnit:GetOwner()];
	if(pOwner == nil) then
		return nil;
	end

	-- Check to see if the player has a Grieving Gift to deploy.
	local giftCountProp :number = pOwner:GetProperty(g_playerPropertyKeys.GrievingGiftCount);
	if(giftCountProp == nil or giftCountProp <= 0) then
		return true;
	end

	return false;
end

function m_ScenarioUnitCommands.GRIEVING_GIFT.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local pOwner :object = Players[pUnit:GetOwner()];
	if(pOwner == nil) then
		return nil;
	end

	local giftCountProp :number = pOwner:GetProperty(g_playerPropertyKeys.GrievingGiftCount);
	if(giftCountProp == nil or giftCountProp <= 0) then
		local currentTurn = Game.GetCurrentGameTurn();
		local giftTurnProp :number = pOwner:GetProperty(g_playerPropertyKeys.GrievingGiftTurn);
		if(giftTurnProp ~= nil and currentTurn < (giftTurnProp + EDGELORDS_GRIEVING_GIFT_DEBOUNCE)) then
			local turnsRemaining = giftTurnProp + EDGELORDS_GRIEVING_GIFT_DEBOUNCE - currentTurn;
			return Locale.Lookup("LOC_GRIEVING_GIFT_RECHARGING_TT", turnsRemaining);
		else
			return Locale.Lookup("LOC_GRIEVING_GIFT_EMPTY_TT");
		end
	end

	return nil;
end

--[[ =======================================================================
	UNIT_CLOAK

	Useable by Aliens faction to make themselves mostly invisible.
-- =========================================================================]]
m_ScenarioUnitCommands.UNIT_CLOAK = {};

-- Study Command State Properties
m_ScenarioUnitCommands.UNIT_CLOAK.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.UNIT_CLOAK.EventName				= "ScenarioCommand_UnitCloak";
m_ScenarioUnitCommands.UNIT_CLOAK.CategoryInUI			= "SPECIFIC";
m_ScenarioUnitCommands.UNIT_CLOAK.Icon					= "ICON_ALIEN_XENO_CAMO";
m_ScenarioUnitCommands.UNIT_CLOAK.ToolTipString			= "LOC_UNIT_CLOAK_TT";
m_ScenarioUnitCommands.UNIT_CLOAK.VisibleInUI			= true;

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_CLOAK.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Aliens) then
		return true;
	end
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_CLOAK.IsVisible(pUnit : object)
	return pUnit ~= nil;
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_CLOAK.IsDisabled(pUnit : object)
	local abilityTimerStatus = GetUnitAbilityTimerStatus(pUnit, g_unitStateKeys.CloakTime, ALIEN_CLOAK_DURATION, ALIEN_CLOAK_DEBOUNCE);
	if(abilityTimerStatus.Status ~= AbilityTimerStatusTypes.Status_Ready) then
		return true;
	end
	return false;
end

function m_ScenarioUnitCommands.UNIT_CLOAK.GetDisabledTTString(pUnit :object)
	local abilityTimerStatus = GetUnitAbilityTimerStatus(pUnit, g_unitStateKeys.CloakTime, ALIEN_CLOAK_DURATION, ALIEN_CLOAK_DEBOUNCE);
	if(abilityTimerStatus.Status == AbilityTimerStatusTypes.Status_Active) then
		return Locale.Lookup("LOC_UNIT_CLOAK_ACTIVE_TT", abilityTimerStatus.TurnsRemaining);
	elseif(abilityTimerStatus.Status == AbilityTimerStatusTypes.Status_Recharging) then
		return Locale.Lookup("LOC_UNIT_CLOAK_RECHARGING_TT", abilityTimerStatus.TurnsRemaining);
	end
	return nil;
end

--[[ =======================================================================
	BURN_TREASURE_MAP

	Useable by Pirate faction to reset their Treasure Map Location.
-- =========================================================================]]
m_ScenarioUnitCommands.BURN_TREASURE_MAP = {};

-- Study Command State Properties
m_ScenarioUnitCommands.BURN_TREASURE_MAP.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.BURN_TREASURE_MAP.EventName				= "ScenarioCommand_BurnTreasureMap";
m_ScenarioUnitCommands.BURN_TREASURE_MAP.CategoryInUI			= "SPECIFIC";
m_ScenarioUnitCommands.BURN_TREASURE_MAP.Icon					= "ICON_PIRATES_BURN_TREASURE_MAP";
m_ScenarioUnitCommands.BURN_TREASURE_MAP.ToolTipString			= "LOC_BURN_TREASURE_MAP_TT";
m_ScenarioUnitCommands.BURN_TREASURE_MAP.VisibleInUI			= true;
m_ScenarioUnitCommands.BURN_TREASURE_MAP.Sound					= "TreasureMapBurn";

-- ===========================================================================
function m_ScenarioUnitCommands.BURN_TREASURE_MAP.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Pirates) then
		return true;
	end
end

-- ===========================================================================
function m_ScenarioUnitCommands.BURN_TREASURE_MAP.IsVisible(pUnit : object)
	return pUnit ~= nil;
end

-- ===========================================================================
function m_ScenarioUnitCommands.BURN_TREASURE_MAP.IsDisabled(pUnit : object)
	if (pUnit == nil) then
		return true;
	end

	-- Is the ability active or recharging?
	local abilityTimerStatus = GetPlayerAbilityTimerStatus(pUnit:GetOwner(), g_playerPropertyKeys.BurnTreasureTurn, 0, PIRATES_BURN_TREASURE_MAP_DEBOUNCE);
	if(abilityTimerStatus.Status ~= AbilityTimerStatusTypes.Status_Ready) then
		return true;
	end
	return false;
end

function m_ScenarioUnitCommands.BURN_TREASURE_MAP.GetDisabledTTString(pUnit :object)
	if (pUnit == nil) then
		return nil;
	end

	local abilityTimerStatus = GetPlayerAbilityTimerStatus(pUnit:GetOwner(), g_playerPropertyKeys.BurnTreasureTurn, 0, PIRATES_BURN_TREASURE_MAP_DEBOUNCE);
	if(abilityTimerStatus.Status == AbilityTimerStatusTypes.Status_Recharging) then
		return Locale.Lookup("LOC_BURN_TREASURE_MAP_RECHARGING_TT", abilityTimerStatus.TurnsRemaining);
	end

	return nil;
end


--[[ =======================================================================
	UNIT_SACRIFICE

	Useable by cultist faction to level up their Undying Eye GDR.
-- =========================================================================]]
m_ScenarioUnitCommands.UNIT_SACRIFICE = {};

-- Study Command State Properties
m_ScenarioUnitCommands.UNIT_SACRIFICE.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.UNIT_SACRIFICE.EventName				= "ScenarioCommand_UnitSacrifice";
m_ScenarioUnitCommands.UNIT_SACRIFICE.CategoryInUI			= "SPECIFIC";
m_ScenarioUnitCommands.UNIT_SACRIFICE.VisibleInUI			= true;
m_ScenarioUnitCommands.UNIT_SACRIFICE.Sound					= "UndyingEye_Activate";

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_SACRIFICE.GetIcon(pUnit : object)
	if (pUnit ~= nil) then
		local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
		if(pOwnerConfig ~= nil and pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Pirates) then
			return "ICON_PIRATES_UNIT_SACRIFICE";
		end
	end

	return "ICON_CULTIST_UNIT_SACRIFICE";
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_SACRIFICE.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pUnit:GetType() == m_eCrippledGDR) then
		return false;
	end

	if(not HaveGDR(pUnit:GetOwner())) then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_SACRIFICE.IsVisible(pUnit : object)
	return pUnit ~= nil;
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_SACRIFICE.GetToolTipString(pUnit :object)
	if (pUnit ~= nil) then
		local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
		if(pOwnerConfig ~= nil and pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Pirates) then
			return "LOC_UNIT_SACRIFICE_TT_C";
		end
	end

	return "LOC_UNIT_SACRIFICE_TT";
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_SACRIFICE.IsDisabled(pUnit : object)
	local pScarificeTarget :object = GetSacrificeTarget(pUnit);
	if(pScarificeTarget == nil) then
		return true;
	end

	if(pScarificeTarget:GetExperience():GetLevel() > GDR_NUM_PROMOTIONS) then
		return true;
	end

	return false;
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_SACRIFICE.GetDisabledTTString(pUnit :object)
	local piratesFaction :boolean = false;
	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig ~= nil and pOwnerConfig:GetCivilizationTypeName() == g_CivTypeNames.Pirates) then
		piratesFaction = true;
	end

	local pScarificeTarget :object = GetSacrificeTarget(pUnit);
	if(pScarificeTarget == nil) then
		if(piratesFaction) then
			return "LOC_UNIT_SACRIFICE_NOT_ADJACENT_TT_C";
		end
		return "LOC_UNIT_SACRIFICE_NOT_ADJACENT_TT";
	end

	if(pScarificeTarget:GetExperience():GetLevel() > GDR_NUM_PROMOTIONS) then
		if(piratesFaction) then
			return "LOC_UNIT_SACRIFICE_MAX_PROMOTIONS_TT_C";
		end
		return "LOC_UNIT_SACRIFICE_MAX_PROMOTIONS_TT";
	end

	return nil;
end


--[[ =======================================================================
	UNIT_RAD_SPREAD

	Used to toggle the radiation spread ability of the mutants.
-- =========================================================================]]
m_ScenarioUnitCommands.UNIT_RAD_SPREAD = {};

-- Study Command State Properties
m_ScenarioUnitCommands.UNIT_RAD_SPREAD.Properties = {};

-- Study Command UI Data
m_ScenarioUnitCommands.UNIT_RAD_SPREAD.EventName			= "ScenarioCommand_UnitRadSpread";
m_ScenarioUnitCommands.UNIT_RAD_SPREAD.CategoryInUI			= "SPECIFIC";
m_ScenarioUnitCommands.UNIT_RAD_SPREAD.Icon					= "ICON_CULTIST_UNIT_RAD_SPREAD";
m_ScenarioUnitCommands.UNIT_RAD_SPREAD.ToolTipString		= "LOC_UNIT_RAD_SPREAD_TT";
m_ScenarioUnitCommands.UNIT_RAD_SPREAD.VisibleInUI			= true;
m_ScenarioUnitCommands.UNIT_RAD_SPREAD.ActiveSound			= "RadiationSpread_Activate";
m_ScenarioUnitCommands.UNIT_RAD_SPREAD.NotActiveSound	   	= "RadiationSpread_Deactivate";

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_RAD_SPREAD.CanUse(pUnit : object)
	if (pUnit == nil) then
		return false;
	end

	local pOwnerConfig = PlayerConfigurations[pUnit:GetOwner()];
	if(pOwnerConfig == nil) then
		print("Error: No Owner PlayerConfig!");
		return false;
	end

	if(pOwnerConfig:GetCivilizationTypeName() ~= g_CivTypeNames.Mutants) then
		return false;
	end

	return true;
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_RAD_SPREAD.IsActive(ownerID : number, unitID : number)
	local pUnit :object = UnitManager.GetUnit(ownerID, unitID);
	if (pUnit == nil) then
		return false;
	end

	local radSpread = pUnit:GetProperty(g_unitStateKeys.RadiationSpread);
	if(radSpread == nil or radSpread > 0) then
		return true;
	end

	return false;
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_RAD_SPREAD.IsVisible(pUnit : object)
	return pUnit ~= nil;
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_RAD_SPREAD.IsDisabled(pUnit : object)
	return false;
end

-- ===========================================================================
function m_ScenarioUnitCommands.UNIT_RAD_SPREAD.GetDisabledTTString(pUnit :object)
	return nil;
end




