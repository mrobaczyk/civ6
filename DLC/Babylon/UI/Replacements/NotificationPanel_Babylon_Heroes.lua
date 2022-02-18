-- Copyright 2020, Firaxis Games

-- This file is being included into the base NotificationPanel file using the wildcard include setup in NotificationPanel.lua
-- Refer to the bottom of NotificationPanel.lua to see how that's happening
-- DO NOT include any NotificationPanel files here or it will cause problems

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_RegisterHandlers = RegisterHandlers;

-- ===========================================================================
function OnActivateHeroDiscovered( notificationEntry, notificationID:number, activatedByUser:boolean )
	if (notificationEntry ~= nil and notificationEntry.m_PlayerID == Game.GetLocalPlayer()) then

		local pNotification :table = GetActiveNotificationFromEntry(notificationEntry, notificationID);
		if pNotification ~= nil then
			LuaEvents.NotificationPanel_HeroDiscovered(pNotification);
		end
	end
end

-- ===========================================================================
function RegisterHandlers()

	BASE_RegisterHandlers();

	g_notificationHandlers[NotificationTypes.HERO_DISCOVERED]						= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.HERO_CREATED]							= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.HERO_KILLED]							= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.HERO_RECALLED]							= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.HERO_EXPIRED]							= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.HERO_LOW_LIFESPAN]						= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.HERO_CAN_PURCHASE_WITH_FAITH]			= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.HERO_CLAIM_FAILED]						= MakeDefaultHandlers();

	g_notificationHandlers[NotificationTypes.HERO_DISCOVERED].Activate				= OnActivateHeroDiscovered;

	g_notificationHandlers[NotificationTypes.HERO_DISCOVERED].AddSound				= "ALERT_POSITIVE";
	g_notificationHandlers[NotificationTypes.HERO_CREATED].AddSound					= "ALERT_NEUTRAL";
	g_notificationHandlers[NotificationTypes.HERO_RECALLED].AddSound				= "ALERT_NEUTRAL";
	g_notificationHandlers[NotificationTypes.HERO_KILLED].AddSound					= "ALERT_NEGATIVE";
	g_notificationHandlers[NotificationTypes.HERO_EXPIRED].AddSound					= "ALERT_NEGATIVE";
	g_notificationHandlers[NotificationTypes.HERO_LOW_LIFESPAN].AddSound			= "ALERT_NEUTRAL";
	g_notificationHandlers[NotificationTypes.HERO_CAN_PURCHASE_WITH_FAITH].AddSound	= "ALERT_POSITIVE";
	g_notificationHandlers[NotificationTypes.HERO_CLAIM_FAILED].AddSound			= "ALERT_NEGATIVE";
end