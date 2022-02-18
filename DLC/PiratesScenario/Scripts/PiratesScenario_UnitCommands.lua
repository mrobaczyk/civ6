--[[ =======================================================================

	Pirates Scenario Custom Unit Commands - Logic

	Receivers for custom unit command events are defined here. They handle
	EXECUTE_SCRIPT commands triggered in the replacement Unit Panel UI script.
-- =========================================================================]]
include("PiratesScenario_PropKeys");
include("PiratesScenario_Shared_Script");
include("PiratesScenario_GameCore_Script");


-- ===========================================================================
--	Defines
-- ===========================================================================
local NO_PLAYER :number = -1;


-- ===========================================================================
--	Lua Context Functions
-- ===========================================================================
-- ===========================================================================
--	VISIT_TAVERN
-- ===========================================================================
function OnScenarioCommand_VisitTavern(eOwner : number, iUnitID : number)
	local pPlayer = Players[eOwner];
	if (pPlayer == nil) then
		return false;
	end

	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		return false;
	end

	local sLog = "Executing VISIT_TAVERN Command for " .. pUnit:GetName();
	print(sLog);

	SelectNewQuest(eOwner);

	RevealNearestPort(eOwner, pUnit:GetX(), pUnit:GetY());

	RelicDropRoll(eOwner, RELIC_DROP_VISIT_TAVERN, "Visit Tavern");

	local newCrew : number = 0;
	local crewProp : number = pUnit:GetProperty(g_unitPropertyKeys.Crew);
	if(crewProp ~= nil) then
		newCrew = crewProp;
	end
	newCrew = newCrew + 1;
	pUnit:SetProperty(g_unitPropertyKeys.Crew, newCrew);
	local crewMessageData : table = {
		MessageType = 0;
		MessageText = Locale.Lookup("LOC_VISIT_TAVERN_WORLDTEXT");
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(crewMessageData);
	UnitManager.ReportActivation(pUnit, "VISIT_TAVERN");

	local pCity :object = FindAdjacentCity(pUnit);
	if(pCity == nil) then
		print("ERROR: Missing city for VISIT_TAVERN Command");
	else
		-- Update unique tavern visits property.
		local lastTavernTurnKey :string = GetPlayerSpecificPropKey(g_cityPlayerSpecificKeys.LastTavernTurn, eOwner);
		local lastTavernProp :number = pCity:GetProperty(lastTavernTurnKey);
		if(lastTavernProp == nil) then
			local tavernVisitCount :number = pPlayer:GetProperty(g_playerPropertyKeys.TavernsVisited);
			if(tavernVisitCount == nil) then
				tavernVisitCount = 0;
			end
			tavernVisitCount = tavernVisitCount + 1;
			pPlayer:SetProperty(g_playerPropertyKeys.TavernsVisited, tavernVisitCount);
		end

		StartPropertyTimer(pCity, g_cityPlayerSpecificKeys.LastTavernTurn, eOwner);
	end

	return true;
end


-- ===========================================================================
--	CAREENING
-- ===========================================================================
function OnScenarioCommand_Careening(eOwner : number, iUnitID : number)
	local pPlayer = Players[eOwner];
	if (pPlayer == nil) then
		return;
	end

	local pUnit = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		return;
	end

	local sLog = "Executing CAREENING Command for " .. pUnit:GetName();
	print(sLog);

	local careeningStatus = GetCareeningStatus(pUnit);
	if(careeningStatus.Result ~= g_GetCareeningResults.VALID) then
		print("Careening Status Failed. Result=" .. tostring(careeningStatus.Result));
		return;
	end

	-- Flyover text
	local message:string  = Locale.Lookup("LOC_CAREENING_WORLDTEXT");
	local messageData : table = {
		MessageType = 0;
		MessageText = message;
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);

	local maxMoves = pUnit:GetMaxMoves();
	if(maxMoves > 0) then
		local healAmount = -CAREENING_HEAL * pUnit:GetMovesRemaining() / maxMoves;
		pUnit:ChangeDamage(healAmount);
		UnitManager.ReportActivation(pUnit, "CAREENING");
		UnitManager.FinishMoves(pUnit);
	end
	
	return true;
end


-- ===========================================================================
--	CAPTURE_BOAT
-- ===========================================================================
function OnScenarioCommand_CaptureBoat(eOwner :number, iUnitID :number, parameters :table)
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

	local sLog = "Executing CAPTURE BOAT Command for " .. pUnit:GetName();
	print(sLog);

	-- Check crew count.
	local curCrewCount = 0;
	local curCrewProp = pUnit:GetProperty(g_unitPropertyKeys.Crew);
	if(curCrewProp ~= nil) then
		curCrewCount = curCrewProp;
	end
	if(curCrewCount < 1) then
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

	local captureResults :table = GetCaptureBoat(eOwner, targetPlot);
	if(captureResults.Result ~= m_GetCaptureBoatResults.CAPTURABLE or captureResults.CaptureUnit == nil) then
		print("ERROR: No valid capture boats here! " .. tostring(targetPlot:GetX()) .. "," .. tostring(targetPlot:GetY()));
		return false;
	end

	local pCaptureBoat = captureResults.CaptureUnit;
	print("Player " .. tostring(eOwner) .. " capturing " .. tostring(pCaptureBoat:GetName()) .. " from player " .. tostring(pCaptureBoat:GetOwner()) .. " at " .. tostring(targetPlot:GetX()) .. "," .. tostring(targetPlot:GetY()) )
	local captureUnitData :object = GameInfo.Units[pCaptureBoat:GetType()];
	local captureDamage :number = pCaptureBoat:GetDamage();
	local pCapturedPlayer = Players[pCaptureBoat:GetOwner()];
	local pCapturedUnits = pCapturedPlayer:GetUnits();

	-- Capturing a ship gives the attacker the kill rewards.
	CheckKillRewards(pCaptureBoat, pUnit, nil);

	pCaptureBoat:SetProperty(g_unitPropertyKeys.CapturePlayerID, eOwner);
	pCaptureBoat:SetProperty(g_unitPropertyKeys.CaptureUnitID, iUnitID);
	pCapturedUnits:Destroy(pCaptureBoat);

	local pPlayerUnits : object = pPlayer:GetUnits();
	if(captureUnitData ~= nil) then
		local newPirateUnit = pPlayerUnits:Create(captureUnitData.Index, targetPlot:GetX(), targetPlot:GetY());
		if(newPirateUnit ~= nil) then
			newPirateUnit:ChangeDamage(captureDamage);
			UnitManager.FinishMoves(newPirateUnit);
			UnitManager.FinishMoves(pUnit);
			UnitManager.ReportActivation(newPirateUnit, "CAPTURED");
			
			local messageData : table = {
				MessageType = 0;
				MessageText = Locale.Lookup("LOC_CAPTURE_BOAT_WORLDTEXT");
				PlotX = newPirateUnit:GetX();
				PlotY = newPirateUnit:GetY();
				Visibility = RevealedState.VISIBLE;
			}
			Game.AddWorldViewText(messageData);
		end
	end

	-- Reduce crew on capturing boat
	local newCrewCount = curCrewCount - 1;
	pUnit:SetProperty(g_unitPropertyKeys.Crew, newCrewCount);

	return true;
end

-- ===========================================================================
--	SHORE_PARTY
-- ===========================================================================
function OnScenarioCommand_ShoreParty(eOwner :number, iUnitID :number, parameters :table)
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

	local sLog = "Executing SHORE PARTY Command for " .. pUnit:GetName();
	print(sLog);

	-- Check crew count.
	local curCrewCount = 0;
	local curCrewProp = pUnit:GetProperty(g_unitPropertyKeys.Crew);
	if(curCrewProp ~= nil) then
		curCrewCount = curCrewProp;
	end
	if(curCrewCount < 1) then
		return false;
	end

	local shorePartyResult = GetShorePartyStatusForUnit(pUnit);
	if(shorePartyResult.Result ~= m_GetShorePartyResults.VALID) then
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

	print("Player " .. tostring(eOwner) .. " deploying shore party at " .. tostring(targetPlot:GetX()) .. "," .. tostring(targetPlot:GetY()) )
	local shorePartyUnitData :object = GameInfo.Units["UNIT_PIRATES"];
	local pPlayerUnits : object = pPlayer:GetUnits();
	if(shorePartyUnitData ~= nil) then
		local newPirateUnit :object = pPlayerUnits:Create(shorePartyUnitData.Index, targetPlot:GetX(), targetPlot:GetY());
		if(newPirateUnit ~= nil) then
			newPirateUnit:GetExperience():SetExperienceLocked(true);

			local messageData : table = {
				MessageType = 0;
				MessageText = Locale.Lookup("LOC_SHORE_PARTY_WORLDTEXT");
				PlotX = newPirateUnit:GetX();
				PlotY = newPirateUnit:GetY();
				Visibility = RevealedState.VISIBLE;
			}
			Game.AddWorldViewText(messageData);
			UnitManager.ReportActivation(newPirateUnit, "DISEMBARK");			
		end
	end

	-- Reduce crew on source boat
	local newCrewCount = curCrewCount - 1;
	pUnit:SetProperty(g_unitPropertyKeys.Crew, newCrewCount);

	pUnit:ChangeMovesRemaining(-SHORE_PARTY_MOVE_COST);

	return true;
end


-- ===========================================================================
--	SHORE_PARTY_EMBARK
-- ===========================================================================
function OnScenarioCommand_ShorePartyEmbark(eOwner :number, iUnitID :number, parameters :table)
	local pPlayer :object = Players[eOwner];
	if (pPlayer == nil) then
		print("ERROR: Missing player object");
		return false;
	end

	local pUnit :object = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		print("ERROR: Missing unit object");
		return false;
	end

	local sLog = "Executing SHORE PARTY EMBARK Command for " .. pUnit:GetName();
	print(sLog);

	if(parameters[UnitCommandTypes.PARAM_X] == nil or parameters[UnitCommandTypes.PARAM_Y] == nil) then
		print("ERROR: Missing target plot x/y");
		return false;
	end

	local targetPlot :object = Map.GetPlot(parameters[UnitCommandTypes.PARAM_X], parameters[UnitCommandTypes.PARAM_Y]);
	if(targetPlot == nil) then
		print("ERROR: Missing target plot");
		return false;
	end

	local embarkResults :table = GetShorePartyEmbarkStatusForPlot(pUnit:GetOwner(), targetPlot);
	if(embarkResults.Result ~= m_GetShorePartyEmbarkResults.VALID 
		or embarkResults.EmbarkShip == nil) then
		print("ERROR: missing embark ship in target plot");
			return false;
	end

	print("Player " .. tostring(eOwner) .. " embarking shore party at " .. tostring(targetPlot:GetX()) .. "," .. tostring(targetPlot:GetY()) )
	local pPlayerUnits : object = pPlayer:GetUnits();
	pPlayerUnits:Destroy(pUnit);

	-- Increase crew on embark boat
	local newEmbarkCrew = 1;
	local curEmbarkCrew = embarkResults.EmbarkShip:GetProperty(g_unitPropertyKeys.Crew);
	if(curEmbarkCrew ~= nil and curEmbarkCrew > 0) then
		newEmbarkCrew = curEmbarkCrew + 1;
	end
	embarkResults.EmbarkShip:SetProperty(g_unitPropertyKeys.Crew, newEmbarkCrew);

	local messageData : table = {
		MessageType = 0;
		MessageText = Locale.Lookup("LOC_SHORE_PARTY_EMBARK_WORLDTEXT");
		PlotX = targetPlot:GetX();
		PlotY = targetPlot:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);

	return true;
end


-- ===========================================================================
--	BURY_TREASURE
-- ===========================================================================
function OnScenarioCommand_BuryTreasure(eOwner :number, iUnitID :number, parameters :table)
	local pPlayer :object = Players[eOwner];
	if (pPlayer == nil) then
		print("ERROR: Missing player object");
		return false;
	end

	local pUnit :object = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		print("ERROR: Missing unit object");
		return false;
	end

	local sLog :string = "Executing BURY TREASURE Command for " .. pUnit:GetName();
	print(sLog);

	local pUnitPlot :object = Map.GetPlot(pUnit:GetX(), pUnit:GetY());
	if(pUnitPlot == nil) then
		print("ERROR: Missing unit plot object");
		return false;
	end		

	local pPlayerTreasury: object = pPlayer:GetTreasury();
	if(pPlayerTreasury:GetGoldBalance() < BURY_TREASURE_GOLD_COST) then
		return false;
	end

	local treasureImproData :object = GameInfo.Improvements[BURY_TREASURE_IMPROVEMENT];
	if(treasureImproData == nil) then
		print("ERROR: Missing improvement data for buried treasure " .. tostring(BURY_TREASURE_IMPROVEMENT));
		return false;
	end		

	if(not ImprovementBuilder.CanHaveImprovement(pUnitPlot, treasureImproData.Index, pPlayer:GetTeam())) then
		return false;
	end

	local messageData : table = {
		MessageType = 0;
		MessageText = Locale.Lookup("LOC_BURY_TREASURE_WORLDTEXT");
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);

	-- Able to Place Buried Treasure Here
	ImprovementBuilder.SetImprovementType(pUnitPlot, treasureImproData.Index, pPlayer:GetTeam());

	pUnit:ChangeMovesRemaining(-1);

	local buryScore :number = GetBuryTreasureScore(pUnit:GetOwner());
	ChangeScore(pUnit:GetOwner(), g_scoreTypes.Treasure, buryScore, pUnit:GetX(), pUnit:GetY());

	pPlayerTreasury:ChangeGoldBalance(-BURY_TREASURE_GOLD_COST);

	return true;
end


-- ===========================================================================
--	DREAD_PIRATE_ACTIVE
-- ===========================================================================
function OnScenarioCommand_DreadPirateActive(eOwner :number, iUnitID :number, parameters :table)
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

	local sLog = "Executing DREAD_PIRATE_ACTIVE Command for " .. pUnit:GetName();
	print(sLog);

	if(parameters[UnitCommandTypes.PARAM_X] == nil or parameters[UnitCommandTypes.PARAM_Y] == nil) then
		print("ERROR: Missing target plot x/y");
		return false;
	end

	local targetPlot = Map.GetPlot(parameters[UnitCommandTypes.PARAM_X], parameters[UnitCommandTypes.PARAM_Y]);
	if(targetPlot == nil) then
		print("ERROR: Missing target plot");
		return false;
	end

	local captureResults :table = GetCaptureBoat(eOwner, targetPlot);
	if(captureResults.Result ~= m_GetCaptureBoatResults.CAPTURABLE or captureResults.CaptureUnit == nil) then
		print("ERROR: No valid capture boats here! " .. tostring(targetPlot:GetX()) .. "," .. tostring(targetPlot:GetY()));
		return false;
	end

	local pCaptureBoat = captureResults.CaptureUnit;
	UnitManager.ReportActivation(pCaptureBoat, "WALK_THE_PLANK_TARGET");
	print("Player " .. tostring(eOwner) .. " is making " .. tostring(pCaptureBoat:GetName()) .. " from player " .. tostring(pCaptureBoat:GetOwner()) .. " walk the plank at " .. tostring(targetPlot:GetX()) .. "," .. tostring(targetPlot:GetY()) )
	local captureUnitData :object = GameInfo.Units[pCaptureBoat:GetType()];
	local captureDamage :number = pCaptureBoat:GetDamage();
	local pCapturedPlayer = Players[pCaptureBoat:GetOwner()];
	local pCapturedUnits = pCapturedPlayer:GetUnits();

	-- Walk the Plank gives the attacker the kill rewards.
	CheckKillRewards(pCaptureBoat, pUnit, nil);

	pCaptureBoat:SetProperty(g_unitPropertyKeys.CapturePlayerID, eOwner);
	pCaptureBoat:SetProperty(g_unitPropertyKeys.CaptureUnitID, iUnitID);
	pCapturedUnits:Destroy(pCaptureBoat);

	local messageData : table = {
		MessageType = 0;
		MessageText = Locale.Lookup("LOC_DREAD_PIRATE_ACTIVE_ACTIVATED_WORLDTEXT");
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);
	
	local pUnitAbility = pUnit:GetAbility();
	pUnitAbility:ChangeAbilityCount("ABILITY_DREAD_PIRATE_UNIT_ACTIVE", 1);

	pUnit:SetProperty(g_unitPropertyKeys.LastDreadPirateActive, Game.GetCurrentGameTurn());
	UnitManager.ReportActivation(pUnit, "WALK_THE_PLANK");

	return true;
end


-- ===========================================================================
--	PRIVATEER_ACTIVE
-- ===========================================================================
function OnScenarioCommand_PrivateerActive(eOwner :number, iUnitID :number, parameters :table)
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

	local sLog = "Executing PRIVATEER_ACTIVE Command for " .. pUnit:GetName();
	print(sLog);

	if(parameters[UnitCommandTypes.PARAM_X] == nil or parameters[UnitCommandTypes.PARAM_Y] == nil) then
		print("ERROR: Missing target plot x/y");
		return false;
	end

	local targetPlot = Map.GetPlot(parameters[UnitCommandTypes.PARAM_X], parameters[UnitCommandTypes.PARAM_Y]);
	if(targetPlot == nil) then
		print("ERROR: Missing target plot");
		return false;
	end

	local captureResults :table = GetCaptureBoat(eOwner, targetPlot);
	if(captureResults.Result ~= m_GetCaptureBoatResults.CAPTURABLE or captureResults.CaptureUnit == nil) then
		print("ERROR: No valid capture boats here! " .. tostring(targetPlot:GetX()) .. "," .. tostring(targetPlot:GetY()));
		return false;
	end

	local pCaptureBoat = captureResults.CaptureUnit;
	UnitManager.ReportActivation(pCaptureBoat, "BRING_HER_HOME_TARGET");
	print("Player " .. tostring(eOwner) .. " is privateer capturing " .. tostring(pCaptureBoat:GetName()) .. " from player " .. tostring(pCaptureBoat:GetOwner()) .. " at " .. tostring(targetPlot:GetX()) .. "," .. tostring(targetPlot:GetY()) )
	local captureUnitData :object = GameInfo.Units[pCaptureBoat:GetType()];
	local captureDamage :number = pCaptureBoat:GetDamage();
	local pCapturedPlayer = Players[pCaptureBoat:GetOwner()];
	local pCapturedUnits = pCapturedPlayer:GetUnits();

	-- Bring her Home gives the attacker the kill rewards.
	CheckKillRewards(pCaptureBoat, pUnit, nil);

	pCaptureBoat:SetProperty(g_unitPropertyKeys.CapturePlayerID, eOwner);
	pCaptureBoat:SetProperty(g_unitPropertyKeys.CaptureUnitID, iUnitID);
	pCapturedUnits:Destroy(pCaptureBoat);

	local patronID :number = pPlayer:GetProperty(g_playerPropertyKeys.PrivateerPatron);
	if(patronID ~= nil) then
		local pPatronPlayer :object = Players[patronID];
		local pPatronUnits : object = pPatronPlayer:GetUnits();
		if(captureUnitData ~= nil) then
			local newPirateUnit = pPatronUnits:Create(captureUnitData.Index, targetPlot:GetX(), targetPlot:GetY());
			if(newPirateUnit == nil) then
				-- patrons might not spawn due to differing territory rules, try to find a better location and spawn there.
				local altSpawnLocation = FindAlternatePatronSpawn(patronID, captureUnitData, targetPlot:GetX(), targetPlot:GetY());
				if(altSpawnLocation ~= nil and altSpawnLocation.X ~= nil and altSpawnLocation.Y) then
					newPirateUnit = pPatronUnits:Create(captureUnitData.Index, altSpawnLocation.X, altSpawnLocation.Y);
				end
			end
			if(newPirateUnit ~= nil) then
				newPirateUnit:ChangeDamage(captureDamage);
				UnitManager.FinishMoves(newPirateUnit);
				UnitManager.FinishMoves(pUnit);

				local messageData : table = {
					MessageType = 0;
					MessageText = Locale.Lookup("LOC_PRIVATEER_ACTIVE_ACTIVATED_WORLDTEXT");
					PlotX = pUnit:GetX();
					PlotY = pUnit:GetY();
					Visibility = RevealedState.VISIBLE;
				}
				Game.AddWorldViewText(messageData);
			end
		end
	end

	GrantGoldPlot(eOwner, pUnit:GetX(), pUnit:GetY(), PRIVATEER_ACTIVE_GOLD_BONUS, "Privateer Active Unit Ability");

	ChangeScore(eOwner, g_scoreTypes.InfamousPirate, IPP_PRIVATEER_ACTIVE, pUnit:GetX(), pUnit:GetY());

	pUnit:SetProperty(g_unitPropertyKeys.LastPrivateerActive, Game.GetCurrentGameTurn());
	UnitManager.ReportActivation(pUnit, "BRING_HER_HOME");
	
	return true;
end

function FindAlternatePatronSpawn(iPlayerID :number, captureUnitData :object, targetX :number, targetY :number)
	local altLocation = {};

	local pPlayer : object = Players[iPlayerID];
	if(pPlayer == nil) then
		print("pPlayer missing!");
		return nil;
	end

	local pPlayerDiplo :object = pPlayer:GetDiplomacy();
	if(pPlayerDiplo == nil) then
		print("pPlayerDiplo missing!");
		return nil;		
	end

	local neighborPlots :table = Map.GetNeighborPlots(targetX,targetY, 5);
	for _, curPlot in ipairs(neighborPlots) do
		if(not curPlot:IsImpassable()
			and curPlot:GetDistrictType() ~= NO_DISTRICT
			and (curPlot:IsWater() or captureUnitData.Domain ~= "DOMAIN_SEA") -- Domain matches unit's
			and (not curPlot:IsOwned() or curPlot:GetOwner() == iPlayerID or pPlayerDiplo:IsAtWarWith(curPlot:GetOwner())) ) then
			local plotUnits :table = Map.GetUnitsAt(pTargetPlot);
			if(plotUnits == nil or plotUnits:GetCount() <= 0) then
				altLocation.X = curPlot:GetX();
				altLocation.Y = curPlot:GetY();
				return altLocation;
			end
		end
	end

	return nil;
end


-- ===========================================================================
--	SWASHBUCKLER_ACTIVE
-- ===========================================================================
function OnScenarioCommand_SwashbucklerActive(eOwner :number, iUnitID :number, parameters :table)
	local pPlayer :object = Players[eOwner];
	if (pPlayer == nil) then
		print("ERROR: Missing player object");
		return false;
	end

	local pUnit :object = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		print("ERROR: Missing unit object");
		return false;
	end

		-- Land Units can't use Tack into the Wind
	if(GameInfo.Units[pUnit:GetType()].Domain ~= "DOMAIN_SEA") then
		return false;
	end

	local sLog :string = "Executing SWASHBUCKLER_ACTIVE Command for " .. pUnit:GetName();
	print(sLog);

	local timerStatus = GetPropertyTimerStatus(pUnit, g_unitPropertyKeys.LastSwashbuckerActive, NO_PLAYER, SWASHBUCKLER_ACTIVE_DURATION, SWASHBUCKLER_ACTIVE_DEBOUNCE);
	if(timerStatus.Status ~= g_PropertyTimerStatusTypes.Status_Ready) then
		print("SWASHBUCKLER_ACTIVE Command failed, timerStatus=" .. tostring(timerStatus.Status));
		return false;
	end

	local message:string  = Locale.Lookup("LOC_SWASHBUCKLER_ACTIVE_ACTIVATED_WORLDTEXT");
	local messageData : table = {
		MessageType = 0;
		MessageText = message;
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);

	local pUnitAbility = pUnit:GetAbility();
	pUnitAbility:ChangeAbilityCount("ABILITY_SWASHBUCKLER_UNIT_ACTIVE", 1);

	-- Add movement for the current turn.
	local maxMoves :number = pUnit:GetMaxMoves();
	pUnit:ChangeMovesRemaining(maxMoves);
	UnitManager.ReportActivation(pUnit, "TACK_INTO_WIND");
	
	pUnit:SetProperty(g_unitPropertyKeys.LastSwashbuckerActive, Game.GetCurrentGameTurn());

	return true;
end


-- ===========================================================================
--	HOARDER_ACTIVE
-- ===========================================================================
function OnScenarioCommand_HoarderActive(eOwner :number, iUnitID :number, parameters :table)
	local pPlayer :object = Players[eOwner];
	if (pPlayer == nil) then
		print("ERROR: Missing player object");
		return false;
	end

	local pUnit :object = pPlayer:GetUnits():FindID(iUnitID);
	if (pUnit == nil) then
		print("ERROR: Missing unit object");
		return false;
	end

	-- Land Units can't use chain shot.
	if(GameInfo.Units[pUnit:GetType()].Domain ~= "DOMAIN_SEA") then
		return false;
	end

	local sLog :string = "Executing HOARDER_ACTIVE Command for " .. pUnit:GetName();
	print(sLog);

	
	if(parameters[UnitCommandTypes.PARAM_X] == nil or parameters[UnitCommandTypes.PARAM_Y] == nil) then
		print("ERROR: Missing target plot x/y");
		return false;
	end

	local targetPlot :object = Map.GetPlot(parameters[UnitCommandTypes.PARAM_X], parameters[UnitCommandTypes.PARAM_Y]);
	if(targetPlot == nil) then
		print("ERROR: Missing target plot");
		return false;
	end

	local timerStatus = GetPropertyTimerStatus(pUnit, g_unitPropertyKeys.LastHoarderActive, NO_PLAYER, HOARDER_ACTIVE_DURATION, HOARDER_ACTIVE_DEBOUNCE);
	if(timerStatus.Status ~= g_PropertyTimerStatusTypes.Status_Ready) then
		print("HOARDER_ACTIVE Command failed, timerStatus=" .. tostring(timerStatus.Status));
		return false;
	end

	local message:string  = Locale.Lookup("LOC_HOARDER_ACTIVE_ACTIVATED_WORLDTEXT");
	local messageData : table = {
		MessageType = 0;
		MessageText = message;
		PlotX = pUnit:GetX();
		PlotY = pUnit:GetY();
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);
	UnitManager.ReportActivation(pUnit, "CHAIN_SHOT");
	
	local targetUnit :object = GetTargetChainShotUnitForPlot(pUnit, targetPlot);
	if(targetUnit == nil) then
		print("targetUnit missing!");
		return false;
	end

	local targetAbility = targetUnit:GetAbility();
	if(targetAbility == nil) then
		print("targetAbility");
		return false;
	end
	targetAbility:ChangeAbilityCount("ABILITY_CHAINSHOT_MOVE_LOCKED", 1);

	-- Remove movement for this turn.
	local curMoves :number = targetUnit:GetMovesRemaining();
	targetUnit:ChangeMovesRemaining(-curMoves);
	targetUnit:SetProperty(g_unitPropertyKeys.LastChainShotHit, Game.GetCurrentGameTurn());
	UnitManager.ReportActivation(targetUnit, "CHAIN_SHOT_TARGET");
	
	pUnit:SetProperty(g_unitPropertyKeys.LastHoarderActive, Game.GetCurrentGameTurn());

	return true;
end


-- ===========================================================================
--	Lua Context Functions
-- ===========================================================================
function Initialize()
	GameEvents.ScenarioCommand_VisitTavern.Add(OnScenarioCommand_VisitTavern);
	GameEvents.ScenarioCommand_Careening.Add(OnScenarioCommand_Careening);
	GameEvents.ScenarioCommand_CaptureBoat.Add(OnScenarioCommand_CaptureBoat);
	GameEvents.ScenarioCommand_ShoreParty.Add(OnScenarioCommand_ShoreParty);
	GameEvents.ScenarioCommand_ShorePartyEmbark.Add(OnScenarioCommand_ShorePartyEmbark);
	GameEvents.ScenarioCommand_BuryTreasure.Add(OnScenarioCommand_BuryTreasure);
	GameEvents.ScenarioCommand_DreadPirateActive.Add(OnScenarioCommand_DreadPirateActive);
	GameEvents.ScenarioCommand_PrivateerActive.Add(OnScenarioCommand_PrivateerActive);
	GameEvents.ScenarioCommand_SwashbucklerActive.Add(OnScenarioCommand_SwashbucklerActive);
	GameEvents.ScenarioCommand_HoarderActive.Add(OnScenarioCommand_HoarderActive);
	
end
Initialize();


