--[[ =======================================================================

	Pirates Scenario GameCore Scripts

	Contains GameCore side scripting related to the game state that is used
	from multiple locations.  These scripts can only be used from GameCore
	lua contexts.
-- =========================================================================]]


-- ===========================================================================
--	Defines
-- ===========================================================================
local NO_PLAYER :number = -1;
local INVALID_COORD :number = -9999;

-- ===========================================================================
--	Misc Helper Functions
-- ===========================================================================
function GrantGoldPlot(iPlayerID :number, plotX :number, plotY :number, amount :number, reason :string)
	local pPlayer :object = Players[iPlayerID];
	if(pPlayer == nil or plotX == nil or plotY == nil or amount == nil) then
		print("data missing");
		return;
	end

	print("Granting Gold=" .. tostring(iPlayerID) .. ", Player=" .. tostring(amount) .. ", Reason=" .. tostring(reason));
	local worldViewData : table = {
	MessageType = 0;
		MessageText = Locale.Lookup("LOC_PIRATES_GRANT_GOLD_WORLD_TEXT", amount);
		PlotX = plotX;
		PlotY = plotY;
		Visibility = RevealedState.VISIBLE;
		TargetID = iPlayerID;
	}
	Game.AddWorldViewText(worldViewData);
	pPlayer:GetTreasury():ChangeGoldBalance(amount);
end

-- Returns the amount of Treasure Points a given player gets for burying a treasure.
function GetBuryTreasureScore(iPlayerID :number)
	local pPlayerConfig :object = PlayerConfigurations[iPlayerID];
	local buryScore :number = BURY_TREASURE_SCORE;

	-- Check Hoarder bonus.
	if(pPlayerConfig ~= nil and pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Hoarder) then
		buryScore = buryScore + HOARDER_BURY_TREASURE_BONUS;
	end

	return buryScore;
end

-- Note: The killer might be a unit or a district. We use the killer's position because the dead unit frequently has an invalid plot at this point.
function CheckKillRewards(deadUnit :object, killerUnit :object, killerDistrict :object)
	if(deadUnit == nil) then
		print("deadUnit missing!");
		return;
	end

	-- Determine killer playerID and killer location
	local killerID :number = NO_PLAYER;
	local killerX :number = INVALID_COORD;
	local killerY :number = INVALID_COORD;
	if(killerUnit ~= nil) then
		killerID = killerUnit:GetOwner();
		killerX = killerUnit:GetX();
		killerY = killerUnit:GetY();
	elseif(killerDistrict ~= nil) then
		killerID = killerDistrict:GetOwner();
		killerX = killerDistrict:GetX();
		killerY = killerDistrict:GetY();
	end

	-- Handle KillInfamyPoints
	local infamyPoints = deadUnit:GetProperty(g_unitPropertyKeys.KillInfamyPoints);
	if(infamyPoints ~= nil and infamyPoints > 0) then
		ChangeScore(killerID, g_scoreTypes.InfamousPirate, infamyPoints, killerX, killerY);
		if(killerUnit ~= nil) then
			UnitManager.ReportActivation(killerUnit, "INFAMOUS_SUNK");	
		end

		SendInfamousPirateDefeatedNotification(deadUnit, killerX, killerY);
	else
		-- Hand out Infamy based on match up.
		if(IsPiratePlayer(killerID)) then
			if(IsColonyPlayer(deadUnit:GetOwner())) then
				-- dead colonial unit
				ChangeScore(killerID, g_scoreTypes.Fighting, INFAMY_PIRATE_KILL_COLONY_UNIT, killerX, killerY);
			elseif(IsPiratePlayer(deadUnit:GetOwner())) then
				-- dead pirate
				ChangeScore(killerID, g_scoreTypes.Fighting, INFAMY_PIRATE_KILL_PIRATE_UNIT, killerX, killerY);
			else
				-- dead barb.
				ChangeScore(killerID, g_scoreTypes.Fighting, INFAMY_PIRATE_KILL_BARB_UNIT, killerX, killerY);
			end
		end	
	end

	local treasureGoldShip = deadUnit:GetProperty(g_unitPropertyKeys.TreasureFleetGoldShip);
	if(treasureGoldShip ~= nil and treasureGoldShip > 0) then
		if(IsPiratePlayer(killerID)) then
			if(killerUnit ~= nil) then
				UnitManager.ReportActivation(killerUnit, "SUNK_GOLD_SHIP");	
			end
			ChangeScore(killerID, g_scoreTypes.Treasure, TREASURE_POINTS_TREASURE_GOLD_BOAT, killerX, killerY);
			local killerPlayer :object = Players[killerID];
			killerPlayer:GetTreasury():ChangeGoldBalance(GOLD_TREASURE_FLEET_GOLD_BOAT_SUNK);
			RelicDropRoll(killerID, RELIC_DROP_TREASURE_GOLD_SHIP, "Sunk Treasure Fleet Gold Ship");
		end
	end

	-- Remove Infamous Pirate Search Zones for dead Infamous Pirates.
	if(IsInfamousPirate(deadUnit:GetOwner(), deadUnit:GetID()) == true) then
		RemoveDeadInfamousPirateSearchZone(deadUnit:GetID());
	end
end

function RemoveDeadInfamousPirateSearchZone(deadUnitID :number)
	local oldSearchZones :table = Game:GetProperty(g_gamePropertyKeys.InfamousPirateSearchZones);
	local newSearchZones :table = {};
	local zonesChanged :boolean = false;
	if(oldSearchZones ~= nil and #oldSearchZones > 0) then
		for index, currentZone in ipairs(oldSearchZones) do
			if(currentZone.PirateUnitID ~= deadUnitID) then
				table.insert(newSearchZones, currentZone);
			end
		end

		Game:SetProperty(g_gamePropertyKeys.InfamousPirateSearchZones, newSearchZones);
	end
end

function SendInfamousPirateDefeatedNotification(infamousUnit: object, deathX :number, deathY :number)
	local deadPlot :object = Map.GetPlot(deathX, deathY);
	local pirateName :string = infamousUnit:GetExperience():GetVeteranName();
	local msgString :string = Locale.Lookup(g_NotificationsData.InfamousPirateDefeated.Message, pirateName);
	local summaryString :string = Locale.Lookup(g_NotificationsData.InfamousPirateDefeated.Summary, pirateName);
	local notifyProperties = {};
	notifyProperties[g_notificationKeys.InfamousPirateID] = infamousUnit:GetID();
	SendNotification_PlotExtra(g_NotificationsData.InfamousPirateDefeated.Type, msgString, summaryString, deadPlot, nil, notifyProperties);
end



