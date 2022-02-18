
function Initialize()
	print("Global Thermonuclear War Scenario Start Script initializing");
	local fissionTech = GameInfo.Technologies["TECH_NUCLEAR_FISSION"];
	local advFlightTech = GameInfo.Technologies["TECH_ADVANCED_FLIGHT"];

	local aPlayers = PlayerManager.GetAliveMajors();
	for _, pPlayer in ipairs(aPlayers) do

		-- Give all major civs Nuclear Fission and Advanced Flight techs.
		local curPlayerTech = pPlayer:GetTechs();
		if(curPlayerTech ~= nil) then
			if (fissionTech ~= nil) then
				curPlayerTech:SetResearchProgress(fissionTech.Index, curPlayerTech:GetResearchCost(fissionTech.Index));
			end
			if(advFlightTech ~= nil) then
				curPlayerTech:SetResearchProgress(advFlightTech.Index, curPlayerTech:GetResearchCost(advFlightTech.Index));
			end
		end

		-- Reveal the map to all players.
		local pCurPlayerVisibility = PlayersVisibility[pPlayer:GetID()];
		if(pCurPlayerVisibility ~= nil) then
			pCurPlayerVisibility:RevealAllPlots();
		end
	end
end
Initialize();