-- ===========================================================================
--	City Banner Manager overrides for Monopolies & Corporations
-- ===========================================================================

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
BANNERTYPE_INDUSTRY			= UIManager:GetHash("BANNERTYPE_INDUSTRY");
BANNERTYPE_CORPORATION		= UIManager:GetHash("BANNERTYPE_CORPORATION");

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_IndustryBannerIM	:table	= InstanceManager:new( "IndustryBanner",	"Anchor", Controls.CityBanners );
local m_CorporationBannerIM	:table	= InstanceManager:new( "CorporationBanner",	"Anchor", Controls.CityBanners );
local m_ResourceTypeMap    	:table  = {};

-- base function overrides
local BASE_CityBannerInitializeOtherBannerTypes = CityBanner.InitializeOtherBannerTypes;
local BASE_UpdateColorOtherBannerTypes = CityBanner.UpdateColorOtherBannerTypes;
local BASE_UpdateOtherImprovementBannerTypes = CityBanner.UpdateOtherImprovementBannerTypes;
local BASE_OnImprovementAddedToMap = OnImprovementAddedToMap;
local BASE_Initialize = Initialize;
local BASE_LateInitialize = LateInitialize;

-- ===========================================================================
function CityBanner:CreateIndustryBanner()
	-- Set the appropriate instance factory (mini banner one) for this flag...
	self.m_InstanceManager = m_IndustryBannerIM;
	self.m_Instance = self.m_InstanceManager:GetInstance();

	self.m_PlotX, self.m_PlotY = Map.GetPlotLocation(self.m_DistrictID);

	local plot:table = Map.GetPlot( self.m_PlotX, self.m_PlotY );
	local resName:string = m_ResourceTypeMap[plot:GetResourceType()];
	if resName ~= nil then
		self.m_Instance.Icon:SetIcon("ICON_MONOPOLIES_AND_CORPS_"..resName);

		self.m_IsImprovementBanner = true;

		local effectStr:string = nil;
		for row in GameInfo.ResourceIndustries() do
			if row.PrimaryKey == resName then
				effectStr = row.ResourceEffectTExt;
				break;
			end
		end

		if effectStr ~= nil then
			local toolTipStr:string = Locale.Lookup("LOC_IMPROVEMENT_INDUSTRY_TYPE_NAME", Locale.Lookup("LOC_"..resName.."_NAME")).."[NEWLINE]"..Locale.Lookup(effectStr);

			self.m_Instance.Icon:SetToolTipString(Locale.Lookup(toolTipStr));
		end
	end
end

-- ===========================================================================
function CityBanner:UpdateIndustryBanner()
	local pLocalPlayerVis:table = PlayersVisibility[Game.GetLocalPlayer()];
	local bHidden:boolean = true;
	if (pLocalPlayerVis ~= nil) then
		if pLocalPlayerVis:IsVisible(self.m_PlotX, self.m_PlotY) then
			self.m_FogState = PLOT_VISIBLE;
			bHidden = false;
		elseif pLocalPlayerVis:IsRevealed(self.m_PlotX, self.m_PlotY) then
			self.m_FogState = PLOT_REVEALED;
		else
			self.m_FogState = PLOT_HIDDEN;
		end
	end

	self:SetFogState( self.m_FogState );
	self.m_Instance.Banner_Base:SetHide(bHidden);
	self.m_Instance.Icon:SetHide(bHidden);
end

-- ===========================================================================
function CityBanner:CreateCorporationBanner()
	-- Set the appropriate instance factory (mini banner one) for this flag...
	self.m_InstanceManager = m_CorporationBannerIM;
	self.m_Instance = self.m_InstanceManager:GetInstance();

	self.m_PlotX, self.m_PlotY = Map.GetPlotLocation(self.m_DistrictID);

	local plot:table = Map.GetPlot( self.m_PlotX, self.m_PlotY );
	local resName:string = m_ResourceTypeMap[plot:GetResourceType()];
	if resName ~= nil then
		self.m_Instance.Icon:SetIcon("ICON_MONOPOLIES_AND_CORPS_"..resName);

		self.m_IsImprovementBanner = true;

		local corpEffectStr:string = nil;
		for row in GameInfo.ResourceCorporations() do
			if row.PrimaryKey == resName then
				corpEffectStr = row.ResourceEffectTExt;
				break;
			end
		end

		local corpName:string = Game.GetEconomicManager():GetCorporationName(Game.GetLocalPlayer(), plot:GetResourceType());
		local toolTipStr:string;
		if corpName ~= nil and corpName ~= "" then
			toolTipStr = corpName.."[NEWLINE]"..Locale.Lookup("LOC_IMPROVEMENT_CORPORATION_TYPE_NAME", Locale.Lookup("LOC_"..resName.."_NAME"));
		else
			toolTipStr = Locale.Lookup("LOC_IMPROVEMENT_CORPORATION_TYPE_NAME", Locale.Lookup("LOC_"..resName.."_NAME"));
		end

		if corpEffectStr ~= nil then
			toolTipStr = toolTipStr.."[NEWLINE]"..Locale.Lookup(corpEffectStr);
		end

		self.m_Instance.Icon:SetToolTipString(Locale.Lookup(toolTipStr));
	end
end

-- ===========================================================================
function CityBanner:UpdateCorporationBanner()
	local pLocalPlayerVis:table = PlayersVisibility[Game.GetLocalPlayer()];
	local bHidden:boolean = true;
	if (pLocalPlayerVis ~= nil) then
		if pLocalPlayerVis:IsVisible(self.m_PlotX, self.m_PlotY) then
			self.m_FogState = PLOT_VISIBLE;
			bHidden = false;
		elseif pLocalPlayerVis:IsRevealed(self.m_PlotX, self.m_PlotY) then
			self.m_FogState = PLOT_REVEALED;
		else
			self.m_FogState = PLOT_HIDDEN;
		end
	end

	self:SetFogState( self.m_FogState );

	self.m_Instance.Banner_Base:SetHide(bHidden);
	self.m_Instance.Icon:SetHide(bHidden);
	self.m_Instance.CorporationRing:SetHide(bHidden);
end

-- ===========================================================================
-- if this is one of our banners, create it now
function CityBanner:InitializeOtherBannerTypes(bannerType : number)
	if (bannerType == BANNERTYPE_INDUSTRY) then
		self:CreateIndustryBanner();
		self:UpdateIndustryBanner();
	elseif (bannerType == BANNERTYPE_CORPORATION) then
		self:CreateCorporationBanner();
		self:UpdateCorporationBanner();
	else	-- not ours, continue the chain
		BASE_CityBannerInitializeOtherBannerTypes(bannerType);
	end
end

-- ===========================================================================
-- Handle color updates for our banner types
function CityBanner:UpdateColorOtherBannerTypes(backColor : number)
	if (self.m_Type == BANNERTYPE_INDUSTRY) then
		if self.m_Instance.Banner_Base ~= nil then
			self.m_Instance.Banner_Base:SetColor( backColor );
		end
	elseif (self.m_Type == BANNERTYPE_CORPORATION) then
		if self.m_Instance.Banner_Base ~= nil then
			self.m_Instance.Banner_Base:SetColor( backColor );
		end
	else
		BASE_UpdateColorOtherBannerTypes();
	end
end

-- ===========================================================================
-- Handle updates for our banner types
function CityBanner:UpdateOtherImprovementBannerTypes()
	if (self.m_Type == BANNERTYPE_INDUSTRY) then
		self:UpdateIndustryBanner();
	elseif (self.m_Type == BANNERTYPE_CORPORATION) then
		self:UpdateCorporationBanner();
	else
		BASE_UpdateOtherImprovementBannerTypes();
	end
end

-- ===========================================================================
function OnImprovementAddedToMap(locX:number, locY:number, eImprovementType:number, eOwner:number)

	if eImprovementType == -1 then
		UI.DataError("Received -1 eImprovementType for ("..tostring(locX)..","..tostring(locY)..") and owner "..tostring(eOwner));
		return;
	end

	local improvementData:table = GameInfo.Improvements[eImprovementType];

	if improvementData == nil then
		UI.DataError("No database entry for eImprovementType #"..tostring(eImprovementType).." for ("..tostring(locX)..","..tostring(locY)..") and owner "..tostring(eOwner));
		return;
	end

	-- Check if the improvement is an Industry or Corporation
	local bIsIndustry:boolean = false;
	local bIsCorporation:boolean = false;
	local improvementDataMODE:table = GameInfo.Improvements_MODE[improvementData.Hash];
	if (improvementDataMODE ~= nil) then
		if (improvementDataMODE.Industry) then
			bIsIndustry = true;
		elseif (improvementDataMODE.Corporation) then
			bIsCorporation = true;
		end
	end

	-- we're only here for industries and corporations
	if ( not bIsIndustry and not bIsCorporation ) then
		BASE_OnImprovementAddedToMap(locX, locY, eImprovementType, eOwner);
		return;
	end

	local pPlayer:table = Players[eOwner];
	local localPlayerID:number = Game.GetLocalPlayer();
	if (pPlayer ~= nil) then
		local plotID = Map.GetPlotIndex(locX, locY);
		if (plotID ~= nil) then
			local miniBanner = GetMiniBanner( eOwner, plotID );
			if (miniBanner == nil) then
				if ( bIsIndustry ) then
					local ownerCity = Cities.GetPlotPurchaseCity(locX, locY);
					local cityID = ownerCity:GetID();
					-- we're passing the plotID as the districtID argument because we need the location of the improvement
					AddMiniBannerToMap( eOwner, cityID, plotID, BANNERTYPE_INDUSTRY );
				elseif ( bIsCorporation ) then
					local ownerCity = Cities.GetPlotPurchaseCity(locX, locY);
					local cityID = ownerCity:GetID();
					-- we're passing the plotID as the districtID argument because we need the location of the improvement
					AddMiniBannerToMap( eOwner, cityID, plotID, BANNERTYPE_CORPORATION );
				end
			end
		end
	end
end

-- ===========================================================================
function OnCorporationNameChanged(ePlayer:number, eResource:number, plotX:number, plotY:number )
	local plotID = Map.GetPlotIndex(plotX, plotY);

	if (plotID > 0) then
		-- as with other minibanners, we use the plotID as the district ID because it makes this easier
		local bannerInstance = GetMiniBanner( ePlayer, plotID );
		if (bannerInstance ~= nil) then
			local plot:table = Map.GetPlot(plotX, plotY);
			local resName:string = m_ResourceTypeMap[plot:GetResourceType()];
			local corpName:string = Game.GetEconomicManager():GetCorporationName(Game.GetLocalPlayer(), plot:GetResourceType());
			local toolTipStr:string;

			local corpEffectStr:string = nil;
			for row in GameInfo.ResourceCorporations() do
				if row.PrimaryKey == resName then
					corpEffectStr = row.ResourceEffectTExt;
					break;
				end
			end

			if corpName ~= nil and corpName ~= "" then
				toolTipStr = corpName.."[NEWLINE]"..Locale.Lookup("LOC_IMPROVEMENT_CORPORATION_TYPE_NAME", Locale.Lookup("LOC_"..resName.."_NAME"));
			else
				toolTipStr = Locale.Lookup("LOC_IMPROVEMENT_CORPORATION_TYPE_NAME", Locale.Lookup("LOC_"..resName.."_NAME"));
			end

			if corpEffectStr ~= nil then
				toolTipStr = toolTipStr.."[NEWLINE]"..Locale.Lookup(corpEffectStr);
			end
			bannerInstance.m_Instance.Icon:SetToolTipString(Locale.Lookup(toolTipStr));
		end
	end
end

-- ===========================================================================
function LateInitialize()
	BASE_LateInitialize();

	m_ResourceTypeMap = {};
	do
		for row in GameInfo.Resources() do
			m_ResourceTypeMap[row.Index] = row.ResourceType;
		end
	end
end

-- ===========================================================================
function Initialize()
	BASE_Initialize();

	Events.CorporationNameChanged.Add( OnCorporationNameChanged );
end
