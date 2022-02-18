-- Copyright 2020, Firaxis Games

-- This file is being included into the base NotificationPanel file using the wildcard include setup in NotificationPanel.lua
-- Refer to the bottom of NotificationPanel.lua to see how that's happening
-- DO NOT include any NotificationPanel files here or it will cause problems

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_RegisterHandlers = RegisterHandlers;

-- ===========================================================================
function RegisterHandlers()

	BASE_RegisterHandlers();

	g_notificationHandlers[NotificationTypes.CLAN_CONVERTED_TO_CITY_STATE]	= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.CLAN_HIRED]					= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.CLAN_RANSOM_PAID]				= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.CLAN_BRIBED]					= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.CLAN_BRIBE_EXPIRED]			= MakeDefaultHandlers();
	g_notificationHandlers[NotificationTypes.CLAN_INCITED]					= MakeDefaultHandlers();

	g_notificationHandlers[NotificationTypes.CLAN_CONVERTED_TO_CITY_STATE].AddSound	= "ALERT_POSITIVE";
	g_notificationHandlers[NotificationTypes.CLAN_HIRED].AddSound					= "ALERT_NEUTRAL";
	g_notificationHandlers[NotificationTypes.CLAN_RANSOM_PAID].AddSound				= "ALERT_NEUTRAL";
	g_notificationHandlers[NotificationTypes.CLAN_BRIBED].AddSound					= "ALERT_POSITIVE";
	g_notificationHandlers[NotificationTypes.CLAN_BRIBE_EXPIRED].AddSound			= "ALERT_NEGATIVE";
	g_notificationHandlers[NotificationTypes.CLAN_INCITED].AddSound					= "ALERT_NEGATIVE";
end