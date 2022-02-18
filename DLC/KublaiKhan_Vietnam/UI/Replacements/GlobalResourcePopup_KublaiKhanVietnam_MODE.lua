--	Copyright 2020, Firaxis Games
-- ===========================================================================
include("GlobalResourcePopup.lua");

-- ===========================================================================
--	LOCALS
-- ===========================================================================
local m_bMercantailismUnlocked:boolean = false;

-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--	Determines data to be displayed.
-- ===========================================================================
function PopulateData()	

	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then
		return nil;
	end

	local pDiplomacy:table =  Players[localPlayerID]:GetDiplomacy();
	if pDiplomacy == nil then
		UI.DataError("GlobalResourcePopup is unable to obtain the diplomacy object for player #'"..tostring(localPlayerID).."'");
		return;
	end
	
	-- find out if Mercantilism is unlocked
	local kPlayer		:table	= Players[localPlayerID];
	local playerCulture	:table	= kPlayer:GetCulture();

	m_bMercantailismUnlocked = false;
	for row in GameInfo.Civics() do
		if row.CivicType == "CIVIC_MERCANTILISM" then
			if playerCulture:HasCivic(row.Index) then
				m_bMercantilismUnlocked = true;
			end
		end
	end

	-- Build list
	local kResourceReport	:table = {};
	local pAllPlayerIDs		:table = PlayerManager.GetAliveIDs();	
	local pGameEconomic     :table = Game.GetEconomicManager();
	local kMapResources :table = pGameEconomic:GetMapResources();
	for _,iPlayerID in ipairs(pAllPlayerIDs) do
		local pPlayer	:table = Players[iPlayerID];
		if ShouldPlayerBeAdded(pPlayer) then			
			local isMet		:boolean = pDiplomacy:HasMet(iPlayerID);
			local isSelf	:boolean = (iPlayerID == localPlayerID);
			local kResources:table = GetResourcesForTrade( localPlayerID, iPlayerID );
			for _,kInfo in ipairs(kResources) do
				local kPlayerEntry :table = {
					playerID= iPlayerID,
					amount	= kInfo.Amount,
					isMet	= isMet,
					isSelf	= isSelf
				};

				local type:string = kInfo.Type;
				local kResourceInfo :table = GameInfo.Resources[type];
				-- First time resource seen?  Add an entry.
				if kResourceReport[type] == nil then
					
					kResourceReport[type]	= {
						name		= kResourceInfo.Name,				-- Unlocalized name
						type		= type,								-- resource type
						class		= kResourceInfo.ResourceClassType,	-- classification of resource
						kOwnerList	= {},								-- List of owners
						isPossessed = false,							-- Any met own this resource?
						total		= kMapResources[kResourceInfo.Index],	-- Total known amount
						index		= kResourceInfo.Index				-- resource ID
					};
				end

				-- Mark if this resource is considered possessed by any known players (and therefor visible in the report.)
				if kPlayerEntry.isMet or kPlayerEntry.isSelf then
					kResourceReport[type].isPossessed = true;					
				end

				if (kResourceReport[type].class == "RESOURCECLASS_LUXURY" and kResourceReport[type].total > 0) then
					kResourceReport[type].total = pGameEconomic:GetNumControlledResources(kPlayerEntry.playerID, kResourceReport[type].index);
					kPlayerEntry.amount = kResourceReport[type].total;
				else
					kResourceReport[type].total = kResourceReport[type].total + kPlayerEntry.amount;
				end
				table.insert(kResourceReport[type].kOwnerList, kPlayerEntry);
			end
		end
	end

	-- Convert to table without key (for later sorting).
	local kData :table = {};
	for k,v in pairs(kResourceReport) do
		table.insert(kData, v);
	end

	return kData;
end



-- ===========================================================================
--	Build a single row of resources to be realized in the UI.
-- ===========================================================================
function RealizeRow( kResourceData:table, backgroundTexture:string )	

	local kGameEconomic :table = Game.GetEconomicManager();
	local kMapResources :table = kGameEconomic:GetMapResources();
	local kOwnerList	:table = kResourceData.kOwnerList;	
	local uiResourceRow	:table = g_kResourceLineIM:GetInstance();
	uiResourceRow.ResourceIcon:SetIcon("ICON_" .. kResourceData.type);
	uiResourceRow.Top:SetTexture( backgroundTexture );
	uiResourceRow.ResourceName:SetText(Locale.Lookup(kResourceData.name));

	local kFullOwnerList:table = {};
	

	if g_isAddingSpaceForEmptyCivs then
		local safe	:number = 0;	--safety
		local lastID:number = -1;
		for i,kPlayer in ipairs(kOwnerList) do
			-- If there is more than a difference of one between ids add spacing.
			while (kPlayer.playerID - lastID) ~= 1 do
				lastID = lastID + 1;
				table.insert(kFullOwnerList, {			-- Create empty slot
					playerID = lastID, 
					isEmpty = true 
				});			
				safe = safe + 1;
				if (safe > 999) then UI.DataError("Infinite or extremely large amount of space being added between civs for report.!"); break; end
			end
			kPlayer.isEmpty  = (not kPlayer.isMet) and (not kPlayer.isSelf);
			table.insert( kFullOwnerList, kPlayer );	-- Copy real player
			lastID = kPlayer.playerID;		
		end
	else	
		-- Copy real player
		for i,kPlayer in ipairs(kOwnerList) do
			table.insert( kFullOwnerList, kPlayer );	
		end
	end

	-- Constants, including temporary instantion to figure out spacing.
	local USE_UNIQUE_LEADER_ICON_STYLE	:boolean = false;
	local uiLeaderInstance	:table = g_kLeaderInstanceIM:GetInstance(uiResourceRow.LeaderStack);
	local emptyWidth		:number= uiLeaderInstance.Top:GetSizeX();
	g_kLeaderInstanceIM:ReleaseInstance( uiLeaderInstance );

	for _,kPlayerEntry in pairs(kFullOwnerList) do
		if (kPlayerEntry.isEmpty and g_isAddingSpaceForEmptyCivs) then
			local uiSpaceInstance	:table = g_kSpaceIM:GetInstance(uiResourceRow.LeaderStack);
			uiSpaceInstance.Space:SetSizeX( emptyWidth );
		elseif kPlayerEntry.isMet or kPlayerEntry.isSelf then
			local uiLeaderInstance	:table = g_kLeaderInstanceIM:GetInstance(uiResourceRow.LeaderStack);
			local leaderName		:string = PlayerConfigurations[kPlayerEntry.playerID]:GetLeaderTypeName();
			local iconName			:string = "ICON_" .. leaderName;	
			local oLeaderIcon		:object	= LeaderIcon:AttachInstance(uiLeaderInstance.Icon);
			local monopolyID		:number = kGameEconomic:GetResourceMonopolyPlayer(kResourceData.index);
			oLeaderIcon:UpdateIcon(iconName, kPlayerEntry.playerID, USE_UNIQUE_LEADER_ICON_STYLE );
			oLeaderIcon.SelectButton:RegisterCallback(Mouse.eLClick, function() OnLeaderClicked(kPlayerEntry.playerID); end);

			local kResourceInfo :table = GameInfo.Resources[kResourceData.type];
			if kResourceData.class == "RESOURCECLASS_LUXURY" and kMapResources[kResourceData.index] > 0 and m_bMercantilismUnlocked == true then
				if monopolyID == kPlayerEntry.playerID then
					uiLeaderInstance.AmountLabel:SetText(kPlayerEntry.amount.." / "..tostring(kMapResources[kResourceData.index]).."[NEWLINE]"..Locale.Lookup("LOC_RESREPORT_MONOPOLY_NAME"));
				else
					local percent:number = kPlayerEntry.amount / kMapResources[kResourceData.index];
					uiLeaderInstance.AmountLabel:SetText(kPlayerEntry.amount.." / "..tostring(kMapResources[kResourceData.index]).."[NEWLINE]"..Locale.ToPercent(percent).." "..Locale.Lookup("LOC_RESREPORT_CONTROL"));
				end
			else
				uiLeaderInstance.AmountLabel:SetText(kPlayerEntry.amount);
			end
		end
	end
		
	uiResourceRow.LeaderStack:CalculateSize();
	uiResourceRow.MainStack:CalculateSize();
	uiResourceRow.DividerLine:SetSizeY( uiResourceRow.MainStack:GetSizeY() - 20 );
	uiResourceRow.DividerLine:SetColorByName( kResourceData.class );	-- Color name is same as class.
end

