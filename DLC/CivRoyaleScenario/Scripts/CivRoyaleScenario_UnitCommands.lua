include("CivRoyaleScenario_PropKeys");
include("CivRoyaleScenario_GameStateUtils");

--[[ =======================================================================

	Civ Royale Scenario Custom Unit Commands - Logic

	Receivers for custom unit command events are defined here. They handle
	EXECUTE_SCRIPT commands triggered in the replacement Unit Panel UI script.
-- =========================================================================]]

--	Initial State Data for units that use these commands




-- ===========================================================================
--	UNIT SHIELD
-- ===========================================================================
function OnScenarioCommand_UnitShield(eOwner : number, iUnitID : number)
	local pPlayer = Players[eOwner];
	if (pPlayer == nil) then
		return false;
	end

	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		return false;
	end

	-- Ability duration check.  We have to do this because the AI just spams the ability without knowing about the timer status.
	-- We also do not log this because of the AI spam.
	local abilityTimerStatus :table = GetUnitAbilityTimerStatus(pUnit, g_unitStateKeys.ShieldTime, MAD_SCIENTIST_SHIELD_DURATION, MAD_SCIENTIST_SHIELD_DEBOUNCE);
	if(abilityTimerStatus.Status ~= AbilityTimerStatusTypes.Status_Ready) then
		return false;
	end

	local sLog = "Executing UNIT SHIELD Command for " .. pUnit:GetName();
	print(sLog);

	-- Flyover text
	local message:string  = Locale.Lookup("LOC_UNIT_SHIELD_ACTIVE_WORLDTEXT");

	local messageData : table = {
		MessageType = 0;
		MessageText = message;
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);

	local pUnitAbility = pUnit:GetAbility();
	pUnitAbility:ChangeAbilityCount("ABILITY_MAD_SCIENTISTS_UNIT_SHIELD", 1);

	-- Set ShieldTime to current turn.
	pUnit:SetProperty(g_unitStateKeys.ShieldTime, Game.GetCurrentGameTurn());

	return true;
end


-- ===========================================================================
--	ROAD VISION
-- ===========================================================================
function OnScenarioCommand_RoadVision(eOwner : number, iUnitID : number)
	local pPlayer = Players[eOwner];
	if (pPlayer == nil) then
		return false;
	end

	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		return false;
	end

	-- Ability duration check.  We have to do this because the AI just spams the ability without knowing about the timer status.
	-- We also do not log this because of the AI spam.
	local abilityTimerStatus = GetPlayerAbilityTimerStatus(pUnit:GetOwner(), g_playerPropertyKeys.RoadVisionTurn, WANDERER_ROAD_VISION_DURATION, WANDERER_ROAD_VISION_DEBOUNCE);
	if(abilityTimerStatus.Status ~= AbilityTimerStatusTypes.Status_Ready) then
		return false;
	end

	local sLog = "Executing ROAD VISION Command for " .. pUnit:GetName();
	print(sLog);

	-- Flyover text
	local message:string  = Locale.Lookup("LOC_ROAD_VISION_ACTIVE_WORLDTEXT");

	local messageData : table = {
		MessageType = 0;
		MessageText = message;
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);

	local pCurPlayerVisibility = PlayersVisibility[pPlayer:GetID()];
	if(pCurPlayerVisibility == nil) then
		print("ERROR: Missing pCurPlayerVisibility!");
		return false;
	end

	local plotRoadActiveKey :string = GetPlayerSpecificPropKey(g_plotPlayerSpecificKeys.RoadVisionActive, eOwner);
	for iPlotIndex = 0, Map.GetPlotCount()-1, 1 do		
		local curPlot :object = Map.GetPlotByIndex(iPlotIndex);
		if(curPlot ~= nil and pCurPlayerVisibility:IsRevealed(curPlot:GetX(), curPlot:GetY())) then
			pCurPlayerVisibility:ChangeVisibilityCount(curPlot:GetIndex(), 1);
			curPlot:SetProperty(plotRoadActiveKey, 1);
		end
	end

	pPlayer:SetProperty(g_playerPropertyKeys.RoadVisionTurn, Game.GetCurrentGameTurn());
	pPlayer:SetProperty(g_playerPropertyKeys.RoadVisionActive, 1);

	return true;
end


-- ===========================================================================
--	PLACE TRAP
-- ===========================================================================
function OnScenarioCommand_PlaceTrap(eOwner : number, iUnitID : number)
	local pPlayer :object = Players[eOwner];
	if (pPlayer == nil) then
		print("ERROR: Missing player object");
		return false;
	end

	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		print("ERROR: Missing unit object");
		return false;
	end
	
	local trapCountProp :number = pPlayer:GetProperty(g_playerPropertyKeys.ImprovisedTrapCount);
	if(trapCountProp == nil or trapCountProp <= 0) then
		return false;
	end

	local sLog = "Executing PLACE TRAP Command for " .. pUnit:GetName();
	print(sLog);

	local pUnitPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY());
	if(pUnitPlot == nil) then
		print("ERROR: Missing unit plot object");
		return false;
	end		

	local trapImproData = GameInfo.Improvements[PREPPER_TRAP_IMPROVEMENT];
	if(trapImproData == nil) then
		print("ERROR: Missing improvement data for trap " .. tostring(PREPPER_TRAP_IMPROVEMENT));
		return false;
	end		

	if(not ImprovementBuilder.CanHaveImprovement(pUnitPlot, trapImproData.Index, pPlayer:GetTeam())) then
		local message:string  = Locale.Lookup("LOC_PLACE_TRAP_FAILED_WORLDTEXT");

		local messageData : table = {
			MessageType = 0;
			MessageText = message;
			PlotX = pUnit:GetX();
			PlotY = pUnit:GetY();
			Visibility = RevealedState.VISIBLE;
		}

		Game.AddWorldViewText(messageData);
		return false;
	end

	-- Able to Place Trap Here
	ImprovementBuilder.SetImprovementType(pUnitPlot, trapImproData.Index, pPlayer:GetTeam());

	pUnit:ChangeMovesRemaining(-1);

	-- Reduce trap count.
	local newtrapCount :number = trapCountProp ~= nil and (trapCountProp - 1) or 0;
	pPlayer:SetProperty(g_playerPropertyKeys.ImprovisedTrapCount, newtrapCount);

	return true;
end


-- ===========================================================================
--	GRIEVING GIFT
-- ===========================================================================
function OnScenarioCommand_GrievingGift(eOwner :number, iUnitID :number, parameters :table)
	local pPlayer = Players[eOwner];
	if (pPlayer == nil) then
		print("ERROR: Missing player object");
		return false;
	end

	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		print("ERROR: Missing unit object");
		return false;
	end
	
	-- Check to see if the player has a Grieving Gift to deploy.
	local giftCountProp :number = pPlayer:GetProperty(g_playerPropertyKeys.GrievingGiftCount);
	if(giftCountProp == nil or giftCountProp <= 0) then
		return false;
	end

	local sLog = "Executing GRIEVING GIFT Command for " .. pUnit:GetName();
	print(sLog);

	--local message:string  = "Gift Sent!";
	--Game.AddWorldViewText(0, message, pUnit:GetX(), pUnit:GetY());

	local pUnitPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY());
	if(pUnitPlot == nil) then
		print("ERROR: Missing unit plot object");
		return false;
	end		

	local trapImproData = GameInfo.Improvements[EDGELORDS_GRIEVING_GIFT_IMPROVEMENT];
	if(trapImproData == nil) then
		print("ERROR: Missing improvement data for grieving gift " .. tostring(PREPPER_TRAP_IMPROVEMENT));
		return false;
	end		

	if(parameters[UnitCommandTypes.PARAM_X] == nil or parameters[UnitCommandTypes.PARAM_Y] == nil) then
		print("ERROR: Missing target plot x/y");
		return false;
	end

	local targetPlot = Map.GetPlot(parameters[UnitCommandTypes.PARAM_X], parameters[UnitCommandTypes.PARAM_Y]);
	if(targetPlot == nil) then
		print("ERROR: Missing target plot");
		return false;
	end

	if(not ImprovementBuilder.CanHaveImprovement(targetPlot, trapImproData.Index, pPlayer:GetTeam())) then
		local message:string  = Locale.Lookup("LOC_GRIEVING_GIFT_ACTIVE_WORLDTEXT");
		local messageData : table = {
			MessageType = 0;
			MessageText = message;
			PlotX = targetPlot:GetX();
			PlotY = targetPlot:GetY();
			Visibility = RevealedState.VISIBLE;
			TargetID = pUnit:GetOwner();
		}
		Game.AddWorldViewText(messageData);
		return false;
	end

	-- Set DeferredGiftOwner on target plot so it will appear during the next turn.
	targetPlot:SetProperty(g_plotStateKeys.DeferredGiftOwner, eOwner);

	-- Reduce gift count.
	local newtrapCount :number = giftCountProp ~= nil and (giftCountProp - 1) or 0;
	pPlayer:SetProperty(g_playerPropertyKeys.GrievingGiftCount, newtrapCount);

	-- Reset recharge time if the player was originally at maximum gift count. 
	if(giftCountProp == nil or giftCountProp == EDGELORDS_GRIEVING_GIFT_MAX_COUNT) then
		pPlayer:SetProperty(g_playerPropertyKeys.GrievingGiftTurn, Game.GetCurrentGameTurn());
	end

	return true;
end


-- ===========================================================================
--	ALIEN CLOAK
-- ===========================================================================
function OnScenarioCommand_UnitCloak(eOwner : number, iUnitID : number)
	local pPlayer = Players[eOwner];
	if (pPlayer == nil) then
		return false;
	end

	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		return false;
	end

	local abilityTimerStatus :table = GetUnitAbilityTimerStatus(pUnit, g_unitStateKeys.CloakTime, ALIEN_CLOAK_DURATION, ALIEN_CLOAK_DEBOUNCE);
	if(abilityTimerStatus.Status ~= AbilityTimerStatusTypes.Status_Ready) then
		return true;
	end

	local sLog = "Executing UNIT CLOAK Command for " .. pUnit:GetName();
	print(sLog);

	local pUnitAbility = pUnit:GetAbility();
	pUnitAbility:ChangeAbilityCount("ABILITY_ALIENS_CLOAK", 1);

	-- Set ShieldTime to current turn.
	pUnit:SetProperty(g_unitStateKeys.CloakTime, Game.GetCurrentGameTurn());

	return true;
end


-- ===========================================================================
--	BURN_TREASURE_MAP
-- ===========================================================================
function OnScenarioCommand_BurnTreasureMap(eOwner : number, iUnitID : number)
	local pPlayer :object = Players[eOwner];
	if (pPlayer == nil) then
		return false;
	end

	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		return false;
	end

	local abilityTimerStatus = GetPlayerAbilityTimerStatus(pUnit:GetOwner(), g_playerPropertyKeys.BurnTreasureTurn, 0, PIRATES_BURN_TREASURE_MAP_DEBOUNCE);
	if(abilityTimerStatus.Status ~= AbilityTimerStatusTypes.Status_Ready) then
		return false;
	end

	local sLog : string = "Executing BURN TREASURE MAP Command for " .. pUnit:GetName();
	print(sLog);

	-- Flyover text
	local message:string  = Locale.Lookup("LOC_BURN_TREASURE_MAP_ACTIVE_WORLDTEXT");
	local messageData : table = {
		MessageType = 0;
		MessageText = message;
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);

	SelectNewPirateTreasureLocation(eOwner);

	pPlayer:SetProperty(g_playerPropertyKeys.BurnTreasureTurn, Game.GetCurrentGameTurn());

	return true;
end


-- ===========================================================================
--	UNIT SACRIFICE
-- ===========================================================================
function OnScenarioCommand_UnitSacrifice(eOwner : number, iUnitID : number)
	local pPlayer :object = Players[eOwner];
	if (pPlayer == nil) then
		return false;
	end

	local pUnit :object = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		return false;
	end

	local sLog :string = "Executing UNIT SACRIFICE Command for " .. pUnit:GetName();
	print(sLog);

	local pSacrificeTarget :object = GetSacrificeTarget(pUnit);
	if(pSacrificeTarget == nil) then
		print("No Sacrifice target.  Aborting...");
		return false;
	end

	-- Flyover text
	local message :string  = Locale.Lookup("LOC_UNIT_SACRIFICE_WORLDTEXT");

	local messageData :table = {
		MessageType = 0;
		MessageText = message;
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);

	-- grant a promotion to the sacrifice target.
	local pSacrificeExp :object = pSacrificeTarget:GetExperience();

	if(pSacrificeExp:CanPromote()) then
		-- Have promotion ready, add a stored promotion so we don't lose the experience.
		pSacrificeExp:ChangeStoredPromotions(1);	
	else
		-- grant the experience for the next level.
		local nextLevelExperience :number = pSacrificeExp:GetExperienceForNextLevel();
		pSacrificeExp:SetExperienceLocked(false);
		pSacrificeExp:ChangeExperience(nextLevelExperience);
	end
	
	local pPlayerUnits :object = pPlayer:GetUnits();
	pPlayerUnits:Destroy(pUnit);

	-- Next step is in OnPostUnitPromotionEarned after the user selects a promotion.
	return true;
end


-- ===========================================================================
--	UNIT_RAD_SPREAD
-- ===========================================================================
function OnScenarioCommand_UnitRadSpread(eOwner : number, iUnitID : number)
	local pPlayer :object = Players[eOwner];
	if (pPlayer == nil) then
		return false;
	end

	local pUnit :object = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		return false;
	end

	local sLog :string = "Executing UNIT RAD TOGGLE Command for " .. pUnit:GetName();
	print(sLog);

	local radToggleProp :number = pUnit:GetProperty(g_unitStateKeys.RadiationSpread);
	local newRadSpread :number = 0;
	if(radToggleProp ~= nil and radToggleProp == 0) then
		newRadSpread = 1;
	end
	pUnit:SetProperty(g_unitStateKeys.RadiationSpread, newRadSpread);

	return true;
end


-- ===========================================================================
--	Lua Context Functions
-- ===========================================================================
function Initialize()
	GameEvents.ScenarioCommand_UnitShield.Add(OnScenarioCommand_UnitShield);
	GameEvents.ScenarioCommand_RoadVision.Add(OnScenarioCommand_RoadVision);
	GameEvents.ScenarioCommand_PlaceTrap.Add(OnScenarioCommand_PlaceTrap);
	GameEvents.ScenarioCommand_GrievingGift.Add(OnScenarioCommand_GrievingGift);
	GameEvents.ScenarioCommand_UnitCloak.Add(OnScenarioCommand_UnitCloak);
	GameEvents.ScenarioCommand_BurnTreasureMap.Add(OnScenarioCommand_BurnTreasureMap);
	GameEvents.ScenarioCommand_UnitSacrifice.Add(OnScenarioCommand_UnitSacrifice);
	GameEvents.ScenarioCommand_UnitRadSpread.Add(OnScenarioCommand_UnitRadSpread);
end
Initialize();


