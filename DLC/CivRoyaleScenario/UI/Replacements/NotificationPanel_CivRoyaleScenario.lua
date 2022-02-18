-- Copyright 2017-2018, Firaxis Games

include("NotificationPanel");

BASE_RegisterHandlers = RegisterHandlers;


-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================


-- ===========================================================================
function RegisterHandlers()
	
	BASE_RegisterHandlers();

	-- Sound to play when added
	g_notificationHandlers[NotificationTypes.USER_DEFINED_2].AddSound			        = "UI_Royale_Ring_Warning";	 -- Safe Zone Changed
	g_notificationHandlers[NotificationTypes.USER_DEFINED_3].AddSound			        = "UI_Royale_Ring_Warning";	 -- Safe Zone Appeared
end


