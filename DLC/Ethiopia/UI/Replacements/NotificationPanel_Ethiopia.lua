-- Copyright 2018, Firaxis Games

-- This file is being included into the base NotificationPanel file using the wildcard include setup in NotificationPanel.lua
-- Refer to the bottom of NotificationPanel.lua to see how that's happening
-- DO NOT include any NotificationPanel files here or it will cause problems
--include("NotificationPanel_Expansion1");

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_RegisterHandlers = RegisterHandlers;

-- ===========================================================================
function OnActivateSecretSocietyDiscovered( notificationEntry )
	if (notificationEntry ~= nil and notificationEntry.m_PlayerID == Game.GetLocalPlayer()) then

		local pNotification :table = GetActiveNotificationFromEntry(notificationEntry);
		if pNotification ~= nil then
			LuaEvents.NotificationPanel_SecretSocietyDiscovered(pNotification);
		end
	end
end

-- ===========================================================================
function OnActivateSecretSocietyJoined( notificationEntry )
	if (notificationEntry ~= nil and notificationEntry.m_PlayerID == Game.GetLocalPlayer()) then

		local pNotification :table = GetActiveNotificationFromEntry(notificationEntry);
		if pNotification ~= nil then
			LuaEvents.NotificationPanel_SecretSocietyJoined(pNotification);
		end
	end
end

-- ===========================================================================
--	HELPER: Get seceret society name from notification.
function GetSocietyName(  pNotification:table )
	local eSociety:number = pNotification:GetValue( "PARAM_DATA1" );
	local kSocietyDef:table = GameInfo.SecretSocieties[eSociety];
	if kSocietyDef == nil then
		UI.DataError("Unknown secret society name (for notification) using enum: ",eSociety);
		return;
	end
	return kSocietyDef.Name;
end

-- ===========================================================================
--	Overrides to apply specific strings for secret society notifications.
-- ===========================================================================
function ApplyNotificationTextOverrides( notificationEntry:NotificationType, pNotification:table, messageName:string, summary:string )	
	if notificationEntry.m_TypeName == "NOTIFICATION_SECRETSOCIETY_DISCOVERED" then
		local societyName :string = GetSocietyName(pNotification);
		summary =  Locale.Lookup( "LOC_DISCOVERED_SOCIETY_DESC", societyName );
	end

	if notificationEntry.m_TypeName == "NOTIFICATION_SECRETSOCIETY_JOINED" then
		local societyName :string = GetSocietyName(pNotification);
		summary =  Locale.Lookup( "LOC_JOINED_SOCIETY_DESC", societyName );
	end
	
	return messageName, summary;
end


-- ===========================================================================
--	Almost duplicate from the default "Add" except special logic for adding icons
--	TODO:	Remove this and return to using the default "Add" notification 
--			handler once the DB is updated to support "Icon" entries in the Notifications.
-- ===========================================================================
function OnSecretSocietyAddNotification( pNotification:table )
	local typeName				:string				= pNotification:GetTypeName();
	if typeName == nil then
		UI.DataError("NIL notification type name for notification ID:"..tostring(pNotification:GetID()));
		return;
	end

	local playerID				:number				= pNotification:GetPlayerID();
	local notificationID		:number				= pNotification:GetID();
 	local notificationGroupID	:number				= pNotification:GetGroup();
 	
	-- Explict ICON lookup based on type (only change from Add)
	local notificationPrimaryIconName:string		= "";
	if typeName == "NOTIFICATION_SECRETSOCIETY_DISCOVERED" then
		notificationPrimaryIconName = "ICON_NOTIFICATION_SECRETSOCIETY_CONTACT";
	elseif typeName == "NOTIFICATION_SECRETSOCIETY_JOINED" then
		notificationPrimaryIconName = "ICON_NOTIFICATION_SECRETSOCIETY_LEADER_JOINED";
	end

	local notificationEntry		:NotificationType	= AddNotificationEntry(playerID, typeName, notificationID, notificationGroupID, notificationPrimaryIconName);
	if (notificationEntry == nil) then
		return;	-- Didn't add it for some reason.  It was either filtered out or possibly already in the list.
	end
	local kHandlers				:NotificationHandler= GetHandler( pNotification:GetType() );

	notificationEntry.m_kHandlers = kHandlers;

	-- Only add a visual entry for this notification if:
	-- It is not a blocking type (otherwise assume the ActionPanel is displaying it)
	-- It is the first notification entry in a group
	-- The icon is displayable in the current mode.
	if ( table.count(notificationEntry.m_IDs)==1 
		and pNotification:GetEndTurnBlocking() == EndTurnBlockingTypes.NO_ENDTURN_BLOCKING
		and pNotification:IsIconDisplayable() ) then

		notificationEntry.m_Instance		= m_genericItemIM:GetInstance();
		notificationEntry.m_InstanceManager = m_genericItemIM;
		notificationEntry.m_Instance.m_MouseIn = false;	-- Manually track since 2 different, overlapping objects are tracking if a pointer is in/out

		if notificationEntry.m_Instance then
			-- Use the (collapse) button as the actual mouse-in area, but a larger rectangle will 
			-- track the mouse out, since the player may be interacting with the extended 
			-- information that flew out to the left of the notification.

			if pNotification:IsValidForPhase() then
				notificationEntry.m_Instance.MouseInArea:RegisterCallback( Mouse.eLClick, function() kHandlers.TryActivate(notificationEntry); end );
				notificationEntry.m_Instance.MouseInArea:RegisterCallback( Mouse.eRClick, function() kHandlers.TryDismiss(notificationEntry); end );
				notificationEntry.m_Instance.MouseOutArea:RegisterCallback( Mouse.eLClick, function() OnClickMouseOutArea(notificationEntry); end );
				notificationEntry.m_Instance.MouseOutArea:RegisterCallback( Mouse.eRClick, function() OnClickMouseOutArea(notificationEntry, true); end );
			else
				--A notification in the wrong phase can be dismissed but not activated.
				local messageName:string = Locale.Lookup(pNotification:GetMessage());
				notificationEntry.m_Instance.MouseInArea:RegisterCallback( Mouse.eLClick, OnDoNothing );
				notificationEntry.m_Instance.MouseInArea:RegisterCallback( Mouse.eRClick, function() kHandlers.TryDismiss(notificationEntry); end );
				notificationEntry.m_Instance.MouseOutArea:RegisterCallback( Mouse.eLClick, OnDoNothing );
				notificationEntry.m_Instance.MouseOutArea:RegisterCallback( Mouse.eRClick, function() kHandlers.TryDismiss(notificationEntry); end );
				local toolTip:string = messageName .. "[NEWLINE]" .. Locale.Lookup("LOC_NOTIFICATION_WRONG_PHASE_TT", messageName);
				notificationEntry.m_Instance.MouseInArea:SetToolTipString(toolTip);
			end
			notificationEntry.m_Instance.MouseInArea:RegisterMouseEnterCallback( function() OnMouseEnterNotification( notificationEntry.m_Instance ); end );
			notificationEntry.m_Instance.MouseOutArea:RegisterMouseExitCallback( function() OnMouseExitNotification( notificationEntry.m_Instance ); end );

			--Set the notification icon
			if (notificationEntry.m_IconName ~= nil) then
				local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(notificationEntry.m_IconName,40);
				if (textureOffsetX ~= nil) then
					notificationEntry.m_Instance.Icon:SetTexture( textureOffsetX, textureOffsetY, textureSheet );
				end
			else
				if(notificationEntry.m_TypeName ~= nil) then
					local iconName :string = DATA_ICON_PREFIX .. notificationEntry.m_TypeName;
					local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(iconName,40);
					if (textureOffsetX ~= nil) then
						notificationEntry.m_Instance.Icon:SetTexture( textureOffsetX, textureOffsetY, textureSheet );
					end
				end
			end

			-- If notification is auto generated, it will have an internal count.
			notificationEntry.m_isAuto = pNotification:IsAutoNotify();

			-- Sets current phase state.
			notificationEntry.m_kHandlers.OnPhaseBegin( playerID, notificationID );

			-- Reset animation control
			notificationEntry.m_Instance.NotificationSlide:Stop();
			notificationEntry.m_Instance.NotificationSlide:SetToBeginning();
		end
	end
	
	-- Update size of notification
	RealizeStandardNotification( playerID, notificationID );

end


-- ===========================================================================
--	TODO: Remove once "Icon" is honored in the XML, the purpose of this is to
--		  just add the default handlers but override "Add" so it can do some
--		  custom setting for the Secret Society icons (which need to exist
--		  for MP games.)
function MakeHandlersWithSecretSocietyAddOverride()
	local handlers = MakeDefaultHandlers();
	handlers.Add = OnSecretSocietyAddNotification;
	return handlers;
end

-- ===========================================================================
function RegisterHandlers()

	BASE_RegisterHandlers();

	g_notificationHandlers[NotificationTypes.SECRETSOCIETY_DISCOVERED]	= MakeHandlersWithSecretSocietyAddOverride();
	g_notificationHandlers[NotificationTypes.SECRETSOCIETY_JOINED]		= MakeHandlersWithSecretSocietyAddOverride();

	g_notificationHandlers[NotificationTypes.SECRETSOCIETY_DISCOVERED].Activate		= OnActivateSecretSocietyDiscovered;
	g_notificationHandlers[NotificationTypes.SECRETSOCIETY_JOINED].Activate			= OnActivateSecretSocietyJoined;

end