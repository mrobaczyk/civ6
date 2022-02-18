-- ===========================================================================
--	Unit Flag Manager (CivRoyale)
--	Manages all the 2d "flags" above units on the world map.
-- ===========================================================================

include( "UnitFlagManager" );


-- ===========================================================================
--	OVERRIDES
-- ===========================================================================
local BASE_Subscribe				= Subscribe;
local BASE_Unsubscribe				= Unsubscribe;
local BASE_OnUnitSelectionChanged	= OnUnitSelectionChanged;


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
COLOR_WHITE	= UI.GetColorValue("COLOR_WHITE");	


-- ===========================================================================
--	VARIABLES
-- ===========================================================================

-- Holds the flags that are currently showing a1 combat preview.
local m_kCombatPreviewFlags	:table	= {};


-- ===========================================================================
--	Update and show the combat preview on the unit flag.
-- ===========================================================================
function OnShowUnitFlagCombatPreview( damageToDefender:number, playerID:number, unitID:number )
	local kFlag:table = GetUnitFlag( playerID, unitID );
	if (kFlag == nil) then
		UI.DataError("Attempt to obtain a1 unit flags for combat preview but no flag for player: "..tostring(playerID)..", unit: "..tostring(unitID));
		return;
	end
	local uiFlag:table = kFlag.m_Instance;
	if (uiFlag == nil) then
		UI.DataError("No UI instance attached to flag for player: "..tostring(playerID)..", unit: "..tostring(unitID));
		return;
	end

	table.insert(m_kCombatPreviewFlags, kFlag);		-- Add to visible combat preview flags.

	local pUnit			:table = kFlag:GetUnit();
	local healthPercent :number = 1.0;
	local maxDamage		:number = pUnit:GetMaxDamage();

	if (maxDamage > 0) then		
		healthPercent = math.max( math.min( (maxDamage - pUnit:GetDamage()) / maxDamage, 1 ), 0 );
	end
	local damage					:number = damageToDefender/100;
	local resultingHealthPercent	:number = healthPercent - damage;

	uiFlag.CombatBarBG:SetHide( false );	
	uiFlag.CombatBar:SetPercent( resultingHealthPercent );
	uiFlag.CombatBar:SetShadowPercent( healthPercent );
	uiFlag.FlashingCombatBar:SetPercent( healthPercent );
		
	if ( healthPercent >= HEALTH_PERCENT_GOOD ) then
		uiFlag.FlashingCombatBar:SetColor( COLOR_GREEN );
		uiFlag.CombatBar:SetColor( COLOR_GREEN );
		uiFlag.CombatBar:SetShadowColor( COLOR_RED );
	elseif( healthPercent >= HEALTH_PERCENT_BAD ) then
		uiFlag.FlashingCombatBar:SetColor( COLOR_YELLOW );
		uiFlag.CombatBar:SetColor( COLOR_YELLOW );
		uiFlag.CombatBar:SetShadowColor( COLOR_RED );
	else
		uiFlag.FlashingCombatBar:SetColor(COLOR_WHITE);
		uiFlag.CombatBar:SetColor( COLOR_RED );
		uiFlag.CombatBar:SetShadowColor( COLOR_RED );		
	end
end


-- ===========================================================================
--	Determine color to use (primary or secondary) for the player's1 name in a1 
--	tooltip with a1 whitebackground.
-- ===========================================================================
function GetColorForPlayerNameInToolTip( primary:number, secondary:number)
	local r1:number, g1:number, b1:number, a1:number= UI.GetColorChannels(primary);
	local r2:number, g2:number, b2:number, a2:number= UI.GetColorChannels(secondary);
	local h1:number, s1:number, v1:number			= RBGtoHSV( r1, g1, b1);
	local h2:number, s2:number, v2:number			= RBGtoHSV( r2, g2, b2);


	local isPrimaryDarker:boolean = v1 < v2;
	if isPrimaryDarker then
		return r1,g1,b1,a1;
	else
		return r2,g2,b2,a2;
	end

	--[[ ??TRON - Re-evaluate (light colors showing up on white)
	if (s1 == 0 and s2 == 0) then
		-- Choose black over white.
		if (v2 > v1 and v2 < .95) then
			return r2, g2, b2, a2;
		end
	end
	if( s1 > .4 and v1 > .3) then
		-- Base colors will work. Use these when possile b1/c they are more associable with the player team color.
		return r1,g1,b1,a1;
	end
	if( v1 == 1 or s1 == 1) then
		return r1,g1,b1,a1;
	end
	if( v2 == 1 or s2 == 1) then
		return r2,g2,b2,a2;
	end
	if(s1 > s2) then
		return r1,g1,b1,a1;
	end
	if(s1 < s2 ) then
		return r2,g2,b2,a2;
	end
	if (s1 == 0 and s2 == 0) then
		-- make sure it doesn't default to white
		if(v1 < v2 ) then
			return r1,g1,b1,a1;
		else
			return r2,g2,b2,a2;
		end
	end
	return r1,g1,b1,a1;
	]]
end


-- ===========================================================================
--	OVERRIDE
--	Update the unit name / tooltip
-- ===========================================================================
function UnitFlag.UpdateName( self )
	local pUnit : table = self:GetUnit();
	local primaryColor, secondaryColor = UI.GetPlayerColors( self.m_Player:GetID() );
	
	if pUnit ~= nil then
		local unitName = pUnit:GetName();
		local pPlayerCfg = PlayerConfigurations[ self.m_Player:GetID() ];
		local nameString : string;
		local leaderDesc : string = pPlayerCfg:GetLeaderName();
		if(GameConfiguration.IsAnyMultiplayer() and pPlayerCfg:IsHuman()) then
			local r,g1,b1,a1 = GetColorForPlayerNameInToolTip(primaryColor, secondaryColor);
			nameString = Locale.Lookup( pPlayerCfg:GetCivilizationShortDescription() ) .. " - " .. Locale.Lookup( unitName ) .. "[NEWLINE]" .. Locale.Lookup("LOC_CIV_ROYALE_HUD_PLAYER_NAME_LABEL") .. " " .. "[COLOR:" .. r .. "," .. g1 .. "," .. b1 .. "," .. a1 .. "]" .. Locale.Lookup(pPlayerCfg:GetPlayerName()) .. "[ENDCOLOR]";
		else
			nameString = Locale.Lookup( pPlayerCfg:GetCivilizationShortDescription() ) .. " - " .. Locale.Lookup( unitName );
		end
	
		local pUnitDef = GameInfo.Units[pUnit:GetUnitType()];
		if pUnitDef then
			local unitTypeName:string = pUnitDef.Name;
			if unitName ~= unitTypeName then
				nameString = nameString .. " " .. Locale.Lookup("LOC_UNIT_UNIT_TYPE_NAME_SUFFIX", unitTypeName);
			end
		end

		-- display military formation indicator(s1)
		local militaryFormation = pUnit:GetMilitaryFormation();
		if self.m_Style == FLAGSTYLE_NAVAL then
			if (militaryFormation == MilitaryFormationTypes.CORPS_FORMATION) then
				nameString = nameString .. TXT_UNITFLAG_FLEET_SUFFIX;
			elseif (militaryFormation == MilitaryFormationTypes.ARMY_FORMATION) then
				nameString = nameString .. TXT_UNITFLAG_ARMADA_SUFFIX;
			end	
		else
			if (militaryFormation == MilitaryFormationTypes.CORPS_FORMATION) then
				nameString = nameString .. TXT_UNITFLAG_CORPS_SUFFIX;
			elseif (militaryFormation == MilitaryFormationTypes.ARMY_FORMATION) then
				nameString = nameString .. TXT_UNITFLAG_ARMY_SUFFIX;
			end
		end

		-- display archaeology info
		local idArchaeologyHomeCity = pUnit:GetArchaeologyHomeCity();
		if (idArchaeologyHomeCity ~= 0) then
			local pCity = self.m_Player:GetCities():FindID(idArchaeologyHomeCity);
			if (pCity ~= nil) then
				nameString = nameString .. "[NEWLINE]" .. Locale.Lookup("LOC_UNITFLAG_ARCHAEOLOGY_HOME_CITY", pCity:GetName());
				local iGreatWorkIndex = pUnit:GetGreatWorkIndex();
				if (iGreatWorkIndex >= 0) then
					local eGWType = Game.GetGreatWorkType(iGreatWorkIndex);
					local eGWPlayer = Game.GetGreatWorkPlayer(iGreatWorkIndex);
					nameString = nameString .. "[NEWLINE]" .. Locale.Lookup("LOC_UNITFLAG_ARCHAEOLOGY_ARTIFACT", GameInfo.GreatWorks[eGWType].Name, PlayerConfigurations[eGWPlayer]:GetPlayerName());
				end
			end
		end

		-- display religion info
		if (pUnit:GetReligiousStrength() > 0) then
			local eReligion = pUnit:GetReligionType();
			if (eReligion > 0) then
				nameString = nameString .. " (" .. Game.GetReligion():GetName(eReligion) .. ")";
			end
		end

		-- display levy status
		local iLevyTurnsRemaining = GetLevyTurnsRemaining(pUnit);
		if (iLevyTurnsRemaining >= 0 and PlayerConfigurations[pUnit:GetOriginalOwner()] ~= nil) then
			nameString = nameString .. "[NEWLINE]" .. Locale.Lookup("LOC_UNITFLAG_LEVY_ACTIVE", PlayerConfigurations[pUnit:GetOriginalOwner()]:GetPlayerName(), iLevyTurnsRemaining);
		end

		self.m_Instance.UnitIcon:SetToolTipString( Locale.Lookup(nameString) );
	end
end

------------------------------------------------------------------
function UnitFlag.SetFlagUnitEmblem( self )
	local icon:string = nil;
	local pUnit:table = self:GetUnit();
	local individual:number = pUnit:GetGreatPerson():GetIndividual();
	if individual >= 0 then
		local individualType:string = GameInfo.GreatPersonIndividuals[individual].GreatPersonIndividualType;
		local iconModifier:table = GameInfo.GreatPersonIndividualIconModifiers[individualType];
		if iconModifier then
			icon = iconModifier.OverrideUnitIcon;
		end 
	end
	if not icon then
		icon = "ICON_"..GameInfo.Units[pUnit:GetUnitType()].UnitType;
	end
	self.m_Instance.UnitIcon:SetIcon(icon);
	icon = icon .. "_" .. PlayerConfigurations[pUnit:GetOwner()]:GetCivilizationTypeName();
	self.m_Instance.UnitIcon:TrySetIcon(icon);
end

------------------------------------------------------------------
function OnUnitSelectionChanged( playerID : number, unitID : number, hexI : number, hexJ : number, hexK : number, bSelected : boolean, bEditable : boolean )

	BASE_OnUnitSelectionChanged( playerID, unitID, hexI, hexJ, hexK, bSelected, bEditable );

	-- Clear out list of existing visible flags.
	for _,flag in ipairs(m_kCombatPreviewFlags) do
		if flag and flag.m_Instance then
			flag.m_Instance.CombatBarBG:SetHide( true );
		end
	end
	m_kCombatPreviewFlags = {};

	-- 

	local viewerID		:number = Game.GetLocalObserver();
	if viewerID == PlayerTypes.NONE then
		UI.DataError("Unit selection changed and observer is NONE?  Is this valid? (If so remove this assert check and just return.)");
		return;
	end

	local localPlayerID		:number = Game.GetLocalPlayer();
	local kPlayers			:table  = Game.GetPlayers();
	local pLocalPlayerVis	:object = PlayersVisibility[viewerID];
	for _, pPlayer:object in ipairs(kPlayers) do
		local playerID:number = pPlayer:GetID();
		if playerID ~= localPlayerID then
			--local kPlayerUnits	:table = kPlayers[playerID]:GetUnits(); 		
			local kPlayerUnits	:table = pPlayer:GetUnits();			
			for _, pUnit in kPlayerUnits:Members() do
				local unitID		:number = pUnit:GetID();
				local locX			:number = pUnit:GetX();
				local locY			:number = pUnit:GetY();
				local isCivilian	:boolean = GameInfo.Units[pUnit:GetType()].FormationClass == "FORMATION_CLASS_CIVILIAN";

				-- TODO: Refactor (using side effect?)				
				if pLocalPlayerVis:IsVisible(locX, locY) and (not isCivilian) then
					LuaEvents.UnitFlagManager_PointerEntered( playerID, unitID );
					LuaEvents.UnitFlagManager_PointerExited( playerID, unitID );
				end
			end
		end
	end
end


-- ===========================================================================
--	Remove event handlers
-- ===========================================================================
function Unsubscribe()
	LuaEvents.UnitPanel_CivRoyaleScenarioShowUnitFlagCombatPreview.Remove( OnShowUnitFlagCombatPreview );
	BASE_Unsubscribe();
end

-- ===========================================================================
--	Add event handlers
-- ===========================================================================
function Subscribe()
	BASE_Subscribe();

	-- Event remapping
	Events.UnitSelectionChanged.Remove( BASE_OnUnitSelectionChanged );
	Events.UnitSelectionChanged.Add( OnUnitSelectionChanged );

	-- New events
	LuaEvents.UnitPanel_CivRoyaleScenarioShowUnitFlagCombatPreview.Add( OnShowUnitFlagCombatPreview );
end

