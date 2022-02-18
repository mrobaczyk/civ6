-- ===========================================================================
--	Unit Flag Manager (Pirates)
--	Manages all the 2d "flags" above units on the world map.
-- ===========================================================================

include( "UnitFlagManager" );

-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_UpdateIconStack = UpdateIconStack;
BASE_UpdateName = UnitFlag.UpdateName;

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function UpdateIconStack( plotX:number, plotY:number )
	BASE_UpdateIconStack(plotX, plotY);

	--Use the built in Army Marker to signify the strength of flagships and infamous pirates
	local unitList:table = Units.GetUnitsInPlotLayerID( plotX, plotY, MapLayers.ANY );
	if unitList ~= nil then
		for _, pUnit in ipairs(unitList) do
			--Only Infamous Pirate and Pirate leader flagships have more than 100 health
			local maxDamage : number = pUnit:GetMaxDamage();
			if(maxDamage > 100)then
				local unitID:number = pUnit:GetID();
				local unitOwner:number = pUnit:GetOwner();
				local flag = GetUnitFlag( unitOwner, unitID );
				if(flag ~= nil)then
					flag.m_Instance.ArmyMarker:SetHide(false);
				end
			end
		end
	end
end

function UnitFlag.UpdateName( self )
	BASE_UpdateName( self );

	local pUnit : table = self:GetUnit();
	if(pUnit ~= nil)then
		local pPlayerConfig = PlayerConfigurations[ self.m_Player:GetID() ];
		if(pPlayerConfig:GetCivilizationTypeName() == "CIVILIZATION_BARBARIAN")then
			self.m_Instance.UnitIcon:SetToolTipString(Locale.Lookup( "LOC_PIRATES_BUCCANEER_DESCRIPTION" ) .. " - " .. Locale.Lookup( pUnit:GetName() ));
		end
	end
end