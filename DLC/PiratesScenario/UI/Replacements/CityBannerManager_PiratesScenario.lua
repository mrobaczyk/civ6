-- ===========================================================================
--	City Banner Manager Replacement
--	Pirates Scenario
-- ===========================================================================

include "PiratesScenario_Shared_Script"


-- ===========================================================================
--	Statics
-- ===========================================================================
-- Note: We cache the DB.MakeHash() result rather than manually defining the hash value 
--			because uint hashes in C++ end up looking like signed int32 values when pushed to lua.
local ms_visitTavernHash :number = DB.MakeHash(g_unitCommandSubTypeNames.VISIT_TAVERN);


-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_CityBannerUpdateStats = CityBanner.UpdateStats;
local BASE_LateInitialize = LateInitialize;


-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function CityBanner:UpdateStats()

	BASE_CityBannerUpdateStats(self);

	if self.m_Type == 0 then
		local localPlayerID : number = Game.GetLocalPlayer();
		if(localPlayerID ~= -1)then
			local pCity : object = self:GetCity();
			if(pCity:GetName() ~= "NONE")then
				local kTavernCooldown = GetPropertyTimerStatus(pCity, g_cityPlayerSpecificKeys.LastTavernTurn, localPlayerID, VISIT_TAVERN_DURATION, VISIT_TAVERN_DEBOUNCE)
				self.m_Instance.TavernIndicator:SetHide(false);
				if(kTavernCooldown.TurnsRemaining <= 0)then
					self.m_Instance.VisitTavernIcon:SetAlpha(1);
					self.m_Instance.VisitTavernIcon:SetToolTipString(Locale.Lookup("LOC_TAVERN_AVAILABLE"));
				else
					self.m_Instance.VisitTavernIcon:SetAlpha(0.3);
					self.m_Instance.VisitTavernIcon:SetToolTipString(Locale.Lookup("LOC_TAVERN_COOLDOWN", kTavernCooldown.TurnsRemaining));
				end

				self.m_Instance.SackedIndicator:SetHide(false);

				local pPlayerConfig : table = PlayerConfigurations[localPlayerID];
				if(pPlayerConfig:GetCivilizationTypeName() == g_CivTypeNames.Privateer)then
					local pCity	: table = self:GetCity();
					local ownerID : number = pCity:GetOwner();
					local pLocalPlayer : table = Players[localPlayerID]
					local patronID : number = pLocalPlayer:GetProperty(g_playerPropertyKeys.PrivateerPatron);
					if(ownerID == patronID)then
						self.m_Instance.SackedIndicator:SetHide(true);
						return;
					end
				end
				local lastSackedTurn :number = pCity:GetProperty(g_cityPropertyKeys.LastSackedTurn);
				if(lastSackedTurn ~= nil and Game.GetCurrentGameTurn() < (lastSackedTurn + CITY_SACKED_DEBOUNCE)) then
					self.m_Instance.SackedIcon:SetAlpha(0.3);
					self.m_Instance.SackedIcon:SetToolTipString(Locale.Lookup("LOC_PIRATES_CITY_SACKED", lastSackedTurn + CITY_SACKED_DEBOUNCE - Game.GetCurrentGameTurn()));
				else
					self.m_Instance.SackedIcon:SetAlpha(1);
					self.m_Instance.SackedIcon:SetToolTipString(Locale.Lookup("LOC_PIRATES_CITY_NOT_SACKED"));
				end
			end
		end
	end
end

-- ===========================================================================
--	Refresh the tavern visited icon
-- ===========================================================================
function OnUnitCommandStarted(player :number, unitId :number, hCommand :number, iData1 :number, hCommandSubType :number)
	if (hCommand == UnitCommandTypes.EXECUTE_SCRIPT
		and  hCommandSubType == ms_visitTavernHash
		and player == Game.GetLocalPlayer()) then
		local pUnit :object = UnitManager.GetUnit(player, unitId);
		if(pUnit == nil) then
			return;
		end

		local pCity :object = FindAdjacentCity(pUnit);
		if(pCity == nil) then
			return;
		end

		--Update the banner next frame so the visit tavern has time to update
		MarkCityForUpdate(pCity:GetOwner(), pCity:GetID());
	end
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function LateInitialize()
	BASE_LateInitialize();
	Events.UnitCommandStarted.Add(OnUnitCommandStarted);
end
