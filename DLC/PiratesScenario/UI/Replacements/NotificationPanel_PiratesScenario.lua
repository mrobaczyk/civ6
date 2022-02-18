-- Copyright 2017-2018, Firaxis Games

-- This file is being included into the base NotificationPanel file using the wildcard include setup in NotificationPanel.lua
-- Refer to the bottom of NotificationPanel.lua to see how that's happening
-- DO NOT include any NotificationPanel files here or it will cause problems
--include("NotificationPanel");

include("PiratesScenario_PropKeys");

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_RegisterHandlers = RegisterHandlers;
local BASE_LateInitialize = LateInitialize;
local BASE_OnDefaultAddNotification = OnDefaultAddNotification;


-- ===========================================================================
-- DEFINES
-- ===========================================================================
local ms_BuriedTreasureImprov : number = GameInfo.Improvements[BURY_TREASURE_IMPROVEMENT].Index;
local ms_FloatingTreasureImprov :number = GameInfo.Improvements["IMPROVEMENT_FLOATING_TREASURE"].Index;


-- ===========================================================================
-- VARIABLES
-- ===========================================================================
-- Additional notification handlers for events not defined as part of the g_notificationHandlers object.
-- Has to be an additional table due to g_notificationHandlers being an already defined havok structure.
-- Indexed by notification type hash. 
local m_customNotifyHandlers :table = {};

-- ===========================================================================
function OnDefaultAddNotification(pNotification:table)
	BASE_OnDefaultAddNotification(pNotification);

	local notificationID	:number				= pNotification:GetID();
	local playerID			:number				= Game.GetLocalPlayer();
	local notificationEntry	:NotificationType	= GetNotificationEntry( playerID, notificationID );
	local turnNumber		:number				= Game.GetCurrentGameTurn()

	--Skip the war declaration notification spam at start of game
	if(notificationEntry.m_TypeName == "NOTIFICATION_DECLARE_WAR" and turnNumber == GameConfiguration.GetStartTurn())then
		NotificationManager.Dismiss( pNotification:GetPlayerID(), notificationID );
		return;
	end

	if(notificationEntry.m_Instance ~= nil)then
		if(notificationEntry.m_TypeName == "NOTIFICATION_TREASURY_BANKRUPT")then
			notificationEntry.m_Instance.Icon:SetIcon("ICON_NOTIFICATION_PIRATES_TREASURY_BANKRUPT");
		elseif(notificationEntry.m_TypeName == "NOTIFICATION_CIVIC_DISCOVERED")then
			notificationEntry.m_Instance.Icon:SetIcon("ICON_NOTIFICATION_PIRATES_RELIC_FOUND");
			notificationEntry.m_kHandlers.Activate(notificationEntry, notificationID); -- Immediately activate the notification so it appears on triggering event.
		elseif(notificationEntry.m_TypeName == "NOTIFICATION_DISCOVER_GOODY_HUT")then
			notificationEntry.m_Instance.Icon:SetIcon("ICON_NOTIFICATION_NEW_BARBARIAN_CAMP");
		end
	end
end

-- ===========================================================================
-- HELPER FUNCTIONS
-- ===========================================================================
function DismissAll(playerID :number, notificationType :number)
	local notifyIDList :table = NotificationManager.GetList(playerID);
	if(notifyIDList ~= nil) then
		for _, loopNotifyID in pairs(notifyIDList) do
			local pNotification = NotificationManager.Find(playerID, loopNotifyID);
			if(pNotification ~= nil and pNotification:GetType() == notificationType) then	
				NotificationManager.Dismiss( playerID, loopNotifyID );
			end
		end	
	end
end

function DismissByProperty(playerID :number, notificationType :number, propertyName :string, propertyValue)
	local notifyIDList :table = NotificationManager.GetList(playerID);
	if(notifyIDList ~= nil) then
		for _, loopNotifyID in pairs(notifyIDList) do
			local pNotification = NotificationManager.Find(playerID, loopNotifyID);
			if(pNotification ~= nil and pNotification:GetType() == notificationType) then
				local notifyPropValue = pNotification:GetValue(propertyName);
				if(notifyPropValue ~= nil and notifyPropValue == propertyValue) then
					NotificationManager.Dismiss( playerID, loopNotifyID );
				end
			end
		end	
	end
end


-- ===========================================================================
-- NEW NOTIFICATION HANDLERS
-- ===========================================================================
function OnPhaseBegin_TreasureLocated( playerID :number, notificationID :number )
	local pPlayer = Players[playerID];
	if(pPlayer == nil) then
		print("Missing Player");
		return;
	end

	local pNotification = NotificationManager.Find(playerID, notificationID);
	if(pNotification == nil) then
		print("Added notification missing.");
		return;
	end

	local deleteNotification = false;

	-- Dismiss notification if the treasure is no longer on the plot or has been pillaged.
	if pNotification:IsLocationValid() then			
		local x, y = pNotification:GetLocation();	-- Look at it.
		local treasurePlot :object = Map.GetPlot(x, y);
		if(treasurePlot == nil 
			or (treasurePlot:GetImprovementType() ~= ms_BuriedTreasureImprov and treasurePlot:GetImprovementType() ~= ms_FloatingTreasureImprov) -- not a treasure improvement anymore.
			or treasurePlot:IsImprovementPillaged()) then
			deleteNotification = true;
		end
	end

	if(deleteNotification == true) then
		NotificationManager.Dismiss( playerID, notificationID );
	end
end

function TryDismiss_TreasureLocated( notificationEntry : NotificationType )
	if (notificationEntry ~= nil and notificationEntry.m_PlayerID == Game.GetLocalPlayer()) then
		local pNotification :table = GetActiveNotificationFromEntry(notificationEntry);
		if (pNotification ~= nil) then
			local x : number, y: number = pNotification:GetLocation();
			local treasurePlot : object = Map.GetPlot(x, y);
			if(treasurePlot == nil 
			or (treasurePlot:GetImprovementType() ~= ms_BuriedTreasureImprov and treasurePlot:GetImprovementType() ~= ms_FloatingTreasureImprov)
			or treasurePlot:IsImprovementPillaged())then
				NotificationManager.Dismiss( pNotification:GetPlayerID(), pNotification:GetID() );
				UI.PlaySound("Play_UI_Click");
			end
		end
	end
end

function OnNewInfamousPirateActivate( notificationEntry : NotificationType )
	if (notificationEntry ~= nil and notificationEntry.m_PlayerID == Game.GetLocalPlayer()) then
		local pNotification :table = GetActiveNotificationFromEntry(notificationEntry, notificationID);
		if pNotification ~= nil then
			local searchZoneID :number = pNotification:GetValue(g_notificationKeys.InfamousSearchZoneID);
			if(searchZoneID ~= nil) then
				local searchZones :table = Game:GetProperty(g_gamePropertyKeys.InfamousPirateSearchZones);
				if(searchZones ~= nil) then
					for loop, curZone in ipairs(searchZones) do
						if(curZone.ZoneID == searchZoneID and curZone.CenterPlotIndex ~= nil) then
							local zoneCenterPlot :object = Map.GetPlotByIndex(curZone.CenterPlotIndex);
							if(zoneCenterPlot ~= nil) then
								UI.LookAtPlot(zoneCenterPlot:GetX(), zoneCenterPlot:GetY());
							end
						end
					end
				end
			end
		end
	end
end


-- ===========================================================================
-- NEW EVENT HANDLERS
-- ===========================================================================
function OnNotificationAdded_Pirates( playerID:number, notificationID:number )
	local pAddNotification = NotificationManager.Find(playerID, notificationID);
	if(pAddNotification == nil) then
		print("Added notification missing.");
		return;
	end

	-- Locating a treasure replaces the corresponding NewBuriedTreasure notification.
	if(pAddNotification:GetType() == g_NotificationsData.BuriedTreasureLocated.Type 
		or pAddNotification:GetType() == g_NotificationsData.BuriedTreasurePillaged.Type ) then
		local x, y = pAddNotification:GetLocation();
		local treasurePlot :object = Map.GetPlot(x, y);
		if(treasurePlot ~= nil) then
			DismissByProperty(playerID, g_NotificationsData.NewBuriedTreasure.Type, g_notificationKeys.TreasurePlotIndex, treasurePlot:GetIndex());
		end
	elseif(pAddNotification:GetType() == g_NotificationsData.InfamousPirateDefeated.Type) then
		local pirateID :number = pAddNotification:GetValue(g_notificationKeys.InfamousPirateID);
		if(pirateID ~= nil) then
			DismissByProperty(playerID, g_NotificationsData.NewInfamousPirate.Type, g_notificationKeys.InfamousPirateID, pirateID);
		end
	end
end

-- ===========================================================================
-- BASE FUNCTION REPLACEMENTS
-- ===========================================================================
function RegisterHandlers()
	BASE_RegisterHandlers();

	g_notificationHandlers[g_NotificationsData.BuriedTreasureLocated.Type].AddSound		= "ALERT_POSITIVE";	
	g_notificationHandlers[g_NotificationsData.NewBuriedTreasure.Type].AddSound			= "ALERT_POSITIVE";	

	g_notificationHandlers[g_NotificationsData.BuriedTreasureLocated.Type].OnPhaseBegin	= OnPhaseBegin_TreasureLocated;
	g_notificationHandlers[g_NotificationsData.BuriedTreasureLocated.Type].TryDismiss	= TryDismiss_TreasureLocated;

	g_notificationHandlers[g_NotificationsData.NewInfamousPirate.Type].Activate	= OnNewInfamousPirateActivate;
end

function LateInitialize()
	BASE_LateInitialize();


	Events.NotificationAdded.Add( OnNotificationAdded_Pirates ); -- Additional and separate from the base NotificationPanel implementation.
end

