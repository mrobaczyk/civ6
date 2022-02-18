-- Copyright 2017-2018, Firaxis Games

-- This file is being included into the base NotificationPanel file using the wildcard include setup in NotificationPanel.lua
-- Refer to the bottom of NotificationPanel.lua to see how that's happening
-- DO NOT include any NotificationPanel files here or it will cause problems
--include("NotificationPanel");

include("CivRoyaleScenario_PropKeys");

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_RegisterHandlers = RegisterHandlers;
local BASE_LateInitialize = LateInitialize;


-- ===========================================================================
-- NEW DEFINES
-- ===========================================================================
local SUPPLY_CRATE_IMPROVEMENT_INDEX : number	= GameInfo.Improvements["IMPROVEMENT_SUPPLY_DROP"].Index;
local GIFT_IMPROVEMENT_INDEX :number			= GameInfo.Improvements[EDGELORDS_GRIEVING_GIFT_IMPROVEMENT].Index;

-- Additional notification handlers for events not defined as part of the g_notificationHandlers object.
-- Has to be an additional table due to g_notificationHandlers being an already defined havok structure.
-- Indexed by notification type hash. 
local m_customNotifyHandlers :table = {};


-- ===========================================================================
-- NEW NOTIFICATION HELPERS
-- ===========================================================================
function ValidateAllNewBuriedTreasureNotifications(playerID :number)
	local notifyIDList :table = NotificationManager.GetList(playerID);
	if(notifyIDList ~= nil) then
		for _, loopNotifyID in pairs(notifyIDList) do
			local pNotification :object = NotificationManager.Find(playerID, loopNotifyID);
			if(pNotification ~= nil and pNotification:GetType() == g_NotificationsData.NewBuriedTreasure.Type) then	
				Validate_NewBuriedTreasure(playerID, pNotification);
			end
		end
	end
end

function Validate_NewBuriedTreasure(playerID :number, pNotification :object)
	if pNotification == nil then
		return;
	end

	local validateFailed :boolean = false;
	local pPlayer :object = Players[playerID];
	if(pPlayer == nil) then
		return;
	end

	local treasurePlotIndex :number = pPlayer:GetProperty(g_playerPropertyKeys.TreasurePlotIndex);
	if(treasurePlotIndex == nil) then
		-- No treasure location.  Dismiss!
		validateFailed = true;
	else
		-- Is the treasure location the same as the target plot for this notification?
		if(pNotification:IsLocationValid()) then
			local x, y = pNotification:GetLocation();
			local treasurePlot = Map.GetPlotByIndex(treasurePlotIndex);
			if(treasurePlot ~= nil and (x ~= treasurePlot:GetX() or y ~= treasurePlot:GetY())) then
				-- treasure locations are different, dismiss!
				validateFailed = true;
			end
		end
	end

	if(validateFailed == true) then
		print("NewBuriedTreasure failed validation. Dismissing notification. PlayerID: " .. tostring(playerID) .. ", NotificationID: " .. tostring(pNotification:GetID()));
		NotificationManager.Dismiss( playerID, pNotification:GetID() );
	end
end


-- ===========================================================================
-- NEW NOTIFICATION HANDLERS (for m_customNotifyHandlers)
-- ===========================================================================
function UserDefined1_OnImprovementRemovedFromMap(playerID :number, notificationID :number)
	-- Dismiss self if associated supply drop has been removed from the map.
	local pNotification :table = NotificationManager.Find( playerID, notificationID );
	if pNotification ~= nil and pNotification:IsLocationValid() then	
		local x, y = pNotification:GetLocation();	-- Look at it.
		local supplyDropPlot :object = Map.GetPlot(x, y);
		if(supplyDropPlot ~= nil 
			and supplyDropPlot:GetImprovementType() ~= SUPPLY_CRATE_IMPROVEMENT_INDEX
			-- This might actually be a Grieving Gift but the user doesn't know that. ;)
			and supplyDropPlot:GetImprovementType() ~= GIFT_IMPROVEMENT_INDEX) then
			NotificationManager.Dismiss( playerID, notificationID );
		end
	end
end


-- ===========================================================================
-- NEW EVENT HANDLERS
-- ===========================================================================
function OnImprovementRemovedFromMap( locX :number, locY :number, eOwner :number )	
	local localPlayerID :number = Game.GetLocalPlayer();
	local notifyIDList :table = NotificationManager.GetList(localPlayerID);
	if(notifyIDList ~= nil) then
		for _, notificationID in pairs(notifyIDList) do
			local pNotification = NotificationManager.Find(localPlayerID, notificationID);
			if(pNotification ~= nil) then
				local typeHash :number = pNotification:GetType();
				if(m_customNotifyHandlers[typeHash] ~= nil and m_customNotifyHandlers[typeHash].OnImprovementRemovedFromMap ~= nil) then
					m_customNotifyHandlers[typeHash].OnImprovementRemovedFromMap(localPlayerID, notificationID);
				end
			end
		end
	end
end

function OnNotificationAdded_CivRoyale( playerID:number, notificationID:number )
	local pAddNotification = NotificationManager.Find(playerID, notificationID);
	if(pAddNotification == nil) then
		print("Added notification missing.");
		return;
	end

	-- A new buried treasure notification means the treasure location changed.  Expire old NewBuriedTreasure that are now invalid.
	if(pAddNotification:GetType() == g_NotificationsData.NewBuriedTreasure.Type) then
		ValidateAllNewBuriedTreasureNotifications(playerID);
	end
end


-- ===========================================================================
-- BASE FUNCTION REPLACEMENTS
-- ===========================================================================
function RegisterHandlers()
	
	BASE_RegisterHandlers();

	-- Sound to play when added
	g_notificationHandlers[NotificationTypes.USER_DEFINED_2].AddSound			        = "UI_Royale_Ring_Warning";	 -- Safe Zone Changed
	g_notificationHandlers[NotificationTypes.USER_DEFINED_3].AddSound			        = "UI_Royale_Ring_Warning";	 -- Safe Zone Appeared
end

function LateInitialize()
	BASE_LateInitialize();

	m_customNotifyHandlers[NotificationTypes.USER_DEFINED_1] = {};
	m_customNotifyHandlers[NotificationTypes.USER_DEFINED_1].OnImprovementRemovedFromMap	= UserDefined1_OnImprovementRemovedFromMap;

	Events.ImprovementRemovedFromMap.Add(OnImprovementRemovedFromMap);
	Events.NotificationAdded.Add( OnNotificationAdded_CivRoyale ); -- Additional and separate from the base NotificationPanel implementation.
end

