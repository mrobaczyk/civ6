-- Copyright 2020, Firaxis Games
-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_Initialize = Initialize;
local BASE_OnImprovementAddedToMap = OnImprovementAddedToMap;
local BASE_OnImprovementRemovedFromMap = OnImprovementRemovedFromMap;
local BASE_OnRefreshBannerPositions = OnRefreshBannerPositions;
local BASE_CBInitialize = CityBanner.Initialize;

-- ===========================================================================
-- CONSTANTS
-- ===========================================================================
local BARBARIAN_CAMP_IMPROVEMENT_INDEX : number = GameInfo.Improvements["IMPROVEMENT_BARBARIAN_CAMP"].Index;

local PLOT_HIDDEN					:number	= 0;
local PLOT_REVEALED					:number	= 1;

local YOFFSET_2DVIEW				:number = 26;
local ZOFFSET_3DVIEW				:number = 36;


-- ===========================================================================
-- LOCALS
-- ===========================================================================
local m_BarbarianTribeBanners : table = {};
local m_BarbarianTribeBannerIM : table = InstanceManager:new( "TribeBanner", "Anchor", Controls.CityBanners );


-- ===========================================================================
function CreateBarbarianTribeBanner(pPlot : table, pBarbTribe : table)
	local uiTribeBanner : table = m_BarbarianTribeBannerIM:GetInstance();

	uiTribeBanner.TribeIcon:SetIcon("ICON_" .. pBarbTribe.TribeNameType);
	uiTribeBanner.TribeIcon:LocalizeAndSetToolTip(pBarbTribe.TribeDisplayName);
	uiTribeBanner.TribeBannerButton:RegisterCallback( Mouse.eLClick, function() OnTribeBannerButtonClicked(pPlot:GetIndex()); end );

	local backColor : number, _ = UI.GetPlayerColors( PlayerTypes.BARBARIAN );
	uiTribeBanner.Banner_Base:SetColor(backColor);

	local iActivePlayer : number = Game.GetLocalPlayer();
	if(iActivePlayer == -1) then
		-- No local player.
		return;
	end

	local tribeBannerEntry : table = 
	{	
		Plot = pPlot;
		BarbarianTribe = pBarbTribe;
		BannerInstance = uiTribeBanner;
	}

	table.insert(m_BarbarianTribeBanners, tribeBannerEntry)
	UpdateTribeBannerConversionBar(tribeBannerEntry);
	UpdateTribeBannerPositioning(pPlot, tribeBannerEntry.BannerInstance);

	local pLocalPlayerVis : table = PlayersVisibility[iActivePlayer];
	local plotVisibility : number = pLocalPlayerVis:GetState(pPlot:GetX(), pPlot:GetY());
	UpdateTribeBannerVisibility(tribeBannerEntry, plotVisibility);
end

-- ===========================================================================
function UpdateTribeBannerConversionBar(barbarianTribeEntry : table)
	local pBarbarianManager : table = Game.GetBarbarianManager();
	local tribeIndex : number = pBarbarianManager:GetTribeIndexAtLocation(barbarianTribeEntry.Plot:GetX(),barbarianTribeEntry.Plot:GetY());
	local iCurrentPoints : number = pBarbarianManager:GetTribeConversionPoints(tribeIndex);

	-- If pts negative, tribe is unable to convert: hide bar
	if (iCurrentPoints < 0) then
		barbarianTribeEntry.BannerInstance.ConversionBar:SetHide(true);
		return;
	else
		barbarianTribeEntry.BannerInstance.ConversionBar:SetHide(false);
	end

	if(not barbarianTribeEntry.BannerInstance.ConversionBar:IsHidden())then
		local conversionPercent : number = pBarbarianManager:GetTribeConversionPercent(tribeIndex);
		if(conversionPercent > 100)then conversionPercent = 100; end
		barbarianTribeEntry.BannerInstance.ConversionBar:SetPercent(conversionPercent/100);

		-- Conversion tip given only in chunky increments as a hint
		local iPointsToConvert : number = pBarbarianManager:GetTribeConversionPointsRequired(tribeIndex);
		local iPointsRemaining = iPointsToConvert - iCurrentPoints;

		local strConversionTip : string = "";
		if (iPointsRemaining >= 50) then
			strConversionTip = Locale.Lookup("LOC_TRIBE_BANNER_CONVERSION_TIP_TURNS", 50);
		elseif (iPointsRemaining >= 20) then
			strConversionTip = Locale.Lookup("LOC_TRIBE_BANNER_CONVERSION_TIP_TURNS", 20);
		elseif (iPointsRemaining >= 10) then
			strConversionTip = Locale.Lookup("LOC_TRIBE_BANNER_CONVERSION_TIP_TURNS", 10);
		else
			strConversionTip = Locale.Lookup("LOC_TRIBE_BANNER_CONVERSION_TIP_IMMINENT");
		end
		barbarianTribeEntry.BannerInstance.ConversionBar:SetToolTipString(strConversionTip);
	end
end

-- ===========================================================================
function UpdateTribeBannerPositioning(pPlot : table, uiBannerInstance : table)
	local yOffset : number = 0;	--offset for 2D strategic view
	local zOffset : number = 0;	--offset for 3D world view
	
	if (UI.GetWorldRenderView() == WorldRenderView.VIEW_2D) then
		yOffset = YOFFSET_2DVIEW;
	else
		zOffset = ZOFFSET_3DVIEW;
	end
	
	local worldX;
	local worldY;
	local worldZ;

	worldX, worldY, worldZ = UI.GridToWorld( pPlot:GetX(), pPlot:GetY() );
	uiBannerInstance.Anchor:SetWorldPositionVal( worldX, worldY+yOffset, worldZ + zOffset );
end

-- ===========================================================================
function UpdateTribeBannerVisibility(tribeBannerEntry : table, eVisibility : number)
	--Banner can be interacted with as long as plot is not hidden
	if(eVisibility == PLOT_HIDDEN)then
		tribeBannerEntry.BannerInstance.Anchor:SetHide(true);
		tribeBannerEntry.BannerInstance.TribeBannerButton:LocalizeAndSetToolTip("");
		tribeBannerEntry.BannerInstance.TribeBannerButton:SetDisabled(true);
	else
		tribeBannerEntry.BannerInstance.Anchor:SetHide(false);
		tribeBannerEntry.BannerInstance.TribeBannerButton:LocalizeAndSetToolTip("LOC_TRIBE_BANNER_TREAT_WITH_TRIBE_TT", tribeBannerEntry.BarbarianTribe.TribeDisplayName);
		tribeBannerEntry.BannerInstance.TribeBannerButton:SetDisabled(false);
	end
end

-- ===========================================================================
function OnTribeBannerButtonClicked(plotIndex : number)
	LuaEvents.CityBannerManager_OpenTreatWithTribePopup(plotIndex);
end

-- ===========================================================================
function OnRefreshBannerPositions()
	BASE_OnRefreshBannerPositions()
	for k, v in ipairs(m_BarbarianTribeBanners) do
		UpdateTribeBannerPositioning(v.Plot, v.BannerInstance);
	end
end

-- ===========================================================================
function OnImprovementAddedToMap(locX : number, locY : number, eImprovementType : number, eOwner : number)
	BASE_OnImprovementAddedToMap(locX, locY, eImprovementType, eOwner);

	if(eImprovementType ~= BARBARIAN_CAMP_IMPROVEMENT_INDEX)then return; end

	local pBarbarianManager : table = Game.GetBarbarianManager();

	local tribeIndex : number = pBarbarianManager:GetTribeIndexAtLocation(locX,locY);
	local barbType : number = pBarbarianManager:GetTribeNameType(tribeIndex);
	local pBarbTribe : table = GameInfo.BarbarianTribeNames[barbType];
	if(pBarbTribe ~= nil)then
		local pPlot : table = Map.GetPlot(locX, locY);
		CreateBarbarianTribeBanner(pPlot, pBarbTribe);
	end
end

-- ===========================================================================
function OnImprovementRemovedFromMap( locX :number, locY :number, eOwner :number )
	BASE_OnImprovementRemovedFromMap(locX, locY, eOwner);
	if(eOwner == PlayerTypes.BARBARIAN)then
		local pPlot : table = Map.GetPlot(locX, locY);
		for k,v in ipairs(m_BarbarianTribeBanners) do
			if(pPlot == v.Plot)then
				m_BarbarianTribeBannerIM:ReleaseInstance(v.BannerInstance);
				table.remove(m_BarbarianTribeBanners, k);
				return;
			end
		end
	end
end

-- ===========================================================================
function OnImprovementVisibilityChanged( locX :number, locY :number, eImprovementType :number, eVisibility :number )
	if ( eImprovementType == BARBARIAN_CAMP_IMPROVEMENT_INDEX ) then
		local pPlot : table = Map.GetPlot(locX, locY);
		for k, v in ipairs(m_BarbarianTribeBanners) do
			if(v.Plot == pPlot)then
				UpdateTribeBannerVisibility(v, eVisibility);
				return;
			end
		end
	end
end

-- ===========================================================================
function OnBarbarianClanConversionEnabled(tribeIndex : number, locX : number, locY : number)
	local pPlot : table = Map.GetPlot(locX, locY);
	for k, v in ipairs(m_BarbarianTribeBanners)do
		if(v.Plot == pPlot)then
			v.BannerInstance.ConversionBar:SetHide(false);
		end
	end
end

-- ===========================================================================
function OnBarbarianClanConversionDisabled(tribeIndex : number, locX : number, locY : number)
	local pPlot : table = Map.GetPlot(locX, locY);
	for k, v in ipairs(m_BarbarianTribeBanners)do
		if(v.Plot == pPlot)then
			v.BannerInstance.ConversionBar:SetHide(true);
		end
	end
end

-- ===========================================================================
function OnPlayerOperationComplete(playerID : number, operation : number)
	--Update encampment banners to show new conversion progress
	if(operation == PlayerOperations.BRIBE_CLAN or operation == PlayerOperations.INCITE_CLAN or operation == PlayerOperations.HIRE_CLAN or operation == PlayerOperations.RANSOM_CLAN)then
		for k,v in ipairs(m_BarbarianTribeBanners) do
			UpdateTribeBannerConversionBar(v);
		end
	end
end

-- ===========================================================================
function OnUnitCommandStarted(playerID : number, unitID : number, hCommand : number, iData1)
	--Update encampment banners to show new conversion progress
	if (hCommand == UnitCommandTypes.RAID_CLAN) then
		for k,v in ipairs(m_BarbarianTribeBanners) do
			UpdateTribeBannerConversionBar(v);
		end
	end
end

-- ===========================================================================
function CityBanner:Initialize( playerID: number, cityID : number, districtID : number, bannerType : number, bannerStyle : number)
	-- Colors are normally assigned during game loading/startup and cached.
	-- Adding a new city during gameplay requires invalidating and rebuilding that cache.
	-- This was also a problem with WorldBuilder Advanced Mode so these exposures already existed.
	UI.RefreshColorSet();
	UI.RebuildColorDB();

	BASE_CBInitialize(self, playerID, cityID, districtID, bannerType, bannerStyle);
end

-- ===========================================================================
function OnLocalPlayerTurnBegin()
	for k,v in ipairs(m_BarbarianTribeBanners) do
		UpdateTribeBannerConversionBar(v);
	end
end

-- ===========================================================================
function OnPlayerChangeClosed()
	local pLocalPlayerVis : table = PlayersVisibility[Game.GetLocalPlayer()];
	if(pLocalPlayerVis ~= nil)then
		for k, barbarianTribeEntry in ipairs(m_BarbarianTribeBanners) do
			local plotVisibility : number = pLocalPlayerVis:GetState(barbarianTribeEntry.Plot:GetX(), barbarianTribeEntry.Plot:GetY())
			UpdateTribeBannerVisibility(barbarianTribeEntry, plotVisibility);
		end
	end
end

-- ===========================================================================
function Initialize()
	BASE_Initialize();

	Events.BarbarianClanConversionEnabled.Add(OnBarbarianClanConversionEnabled);
	Events.BarbarianClanConversionDisabled.Add(OnBarbarianClanConversionDisabled);

	Events.PlayerOperationComplete.Add(OnPlayerOperationComplete);
	Events.UnitCommandStarted.Add(OnUnitCommandStarted);
	Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin);

	LuaEvents.PlayerChange_Close.Add(OnPlayerChangeClosed);
end