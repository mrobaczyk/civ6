include( "UnitFlagManager" );

-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_Subscribe		= Subscribe;
local BASE_Unsubscribe		= Unsubscribe;
local BASE_UpdatePromotions	= UnitFlag.UpdatePromotions;
local BASE_UpdateName		= UnitFlag.UpdateName;

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local BRIBE_STATUS_ICON_NAME				: string = "Bribe22";
local INCITE_AGAINST_PLAYER_STATUS_ICON_NAME: string = "Incite22";
local INCITE_BY_PLAYER_STATUS_ICON_NAME		: string = "InciteByMe22";	--TODO: Asset requested

-- ===========================================================================
--	OVERRIDES
-- ===========================================================================
function UnitFlag.UpdatePromotions( self )
	local pUnit : table = self:GetUnit();

	local localPlayerID : number = Game.GetLocalPlayer();
	if (localPlayerID == -1) then
		return;
	end

	self.m_Instance.TribeStatusFlag:SetHide(true);

	if(pUnit ~= nil)then
		local tribeIndex : number = pUnit:GetBarbarianTribeIndex();
		if(tribeIndex >= 0)then

			local pBarbarianTribeManager : table = Game.GetBarbarianManager();
			local bribedTurnsRemaining : number = pBarbarianTribeManager:GetTribeBribeTurnsRemaining(tribeIndex, localPlayerID);
			self.m_Instance.Promotion_Flag:SetHide(true);

			--Show any Barbarian Tribe specific status icons (bribed, incited)
			if(bribedTurnsRemaining > 0)then
				--Show bribe icon w/ turns remaining tooltip
				self.m_Instance.TribeStatusFlag:SetHide(false);
				self.m_Instance.TribeStatusIcon:SetTexture(BRIBE_STATUS_ICON_NAME);
				return;
			else
				local inciteTargetID : number = pBarbarianTribeManager:GetTribeInciteTargetPlayer(tribeIndex);
				if (inciteTargetID >= 0) then
					if(inciteTargetID == localPlayerID)then
						--Show incited against us icon
						self.m_Instance.TribeStatusFlag:SetHide(false);
						self.m_Instance.TribeStatusIcon:SetTexture(INCITE_AGAINST_PLAYER_STATUS_ICON_NAME);
						return;
					else
						local inciteSourceID : number = pBarbarianTribeManager:GetTribeInciteSourcePlayer(tribeIndex);
						if(inciteSourceID == localPlayerID)then
							--Show we incited them icon
							self.m_Instance.TribeStatusFlag:SetHide(false);
							self.m_Instance.TribeStatusFlag:SetTexture(INCITE_BY_PLAYER_STATUS_ICON_NAME);
							return;
						end
					end
				end
			end
		end
	end
	BASE_UpdatePromotions(self);
end

-- ===========================================================================
function UnitFlag.UpdateName( self )
	BASE_UpdateName(self);

	local localPlayerID : number = Game.GetLocalPlayer();
	if (localPlayerID == -1) then
		return;
	end

	local pUnit : table = self:GetUnit();
	if(pUnit ~= nil)then
		local tribeIndex : number = pUnit:GetBarbarianTribeIndex();
		if(tribeIndex >= 0)then
			
			local pBarbarianTribeManager : table = Game.GetBarbarianManager();
			local bribedTurnsRemaining : number = pBarbarianTribeManager:GetTribeBribeTurnsRemaining(tribeIndex, localPlayerID);
			local nameString = self.m_Instance.UnitIcon:GetToolTipString();

			local barbType : number = pBarbarianTribeManager:GetTribeNameType(tribeIndex);
			if(barbType >= 0)then
				local pBarbTribe : table = GameInfo.BarbarianTribeNames[barbType];
				nameString = nameString .. "[NEWLINE]" .. Locale.Lookup(pBarbTribe.TribeDisplayName);

				--Add any Barbarian Tribe specific statuses (bribed, incited) to the unit tooltip
				if(bribedTurnsRemaining > 0)then
					--Add bribe turns remaining to the unit tooltip
					nameString = nameString .. "[NEWLINE]" .. Locale.Lookup("LOC_BARBARIAN_STATUS_BRIBED", bribedTurnsRemaining);
				else
					local inciteTargetID : number = pBarbarianTribeManager:GetTribeInciteTargetPlayer(tribeIndex);
					if (inciteTargetID >= 0) then
						if(inciteTargetID == localPlayerID)then
							--Add incited against us to the unit tooltip
							local inciteSourcePlayer : table = PlayerConfigurations[pBarbarianTribeManager:GetTribeInciteSourcePlayer(tribeIndex)];
							local inciteSourcePlayerName : string = inciteSourcePlayer:GetPlayerName();
							nameString = nameString .. "[NEWLINE]" .. Locale.Lookup("LOC_BARBARIAN_STATUS_INCITED_AGAINST_YOU", inciteSourcePlayerName);
						else
							local inciteSourceID : number = pBarbarianTribeManager:GetTribeInciteSourcePlayer(tribeIndex);
							if(inciteSourceID == localPlayerID)then
								--Add incited by us to the unit tooltip
								local inciteTargetPlayer : table = PlayerConfigurations[pBarbarianTribeManager:GetTribeInciteTargetPlayer(tribeIndex)];
								local inciteTargetPlayerName : string = inciteTargetPlayer:GetPlayerName();
								nameString = nameString .. "[NEWLINE]" .. Locale.Lookup("LOC_BARBARIAN_STATUS_INCITED_BY_YOU", inciteTargetPlayerName);
							end
						end
					end
				end

				self.m_Instance.UnitIcon:SetToolTipString( nameString );
			end
		end
	end
end

-- ===========================================================================
function OnPlayerOperationComplete(playerID : number, operation : number)
	--Update Barbarian UnitFlag tooltip and status icons in case we have Bribed or Incited them
	if(operation == PlayerOperations.BRIBE_CLAN or operation == PlayerOperations.INCITE_CLAN)then
		local pBarbarianPlayer = Players[PlayerTypes.BARBARIAN]
		local pBarbarianUnits:table = pBarbarianPlayer:GetUnits();
		for i, pUnit in pBarbarianUnits:Members() do
			local flag:table = GetUnitFlag(PlayerTypes.BARBARIAN, pUnit:GetID());
			flag:UpdateName();
			flag:UpdatePromotions();
		end
	end
end

-- ===========================================================================
function Subscribe()
	BASE_Subscribe();
	Events.PlayerOperationComplete.Add(OnPlayerOperationComplete);
end

-- ===========================================================================
function Unsubscribe()
	BASE_Unsubscribe();
	Events.PlayerOperationComplete.Remove(OnPlayerOperationComplete);
end