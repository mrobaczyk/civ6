-- Copyright 2020, Firaxis Games

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================

local kJoinedImages:table = {};
kJoinedImages["SECRETSOCIETY_OWLS_OF_MINERVA"]	= "GovernorSelectedSTK_OwlsOfMinerva";
kJoinedImages["SECRETSOCIETY_HERMETIC_ORDER"]	= "GovernorSelectedSTK_HermeticOrder";
kJoinedImages["SECRETSOCIETY_VOIDSINGERS"]		= "GovernorSelectedSTK_VoidSingers";
kJoinedImages["SECRETSOCIETY_SANGUINE_PACT"]	= "GovernorSelectedSTK_SanguinePact";

-- ===========================================================================
function OnContinueButton()
	Close();
end

-- ===========================================================================
function OnOpenGovernorsButton()
	Close();
	LuaEvents.GovernorPanel_Open();
end

-- ===========================================================================
function Open()
	UIManager:QueuePopup(ContextPtr, PopupPriority.Low);
end

-- ===========================================================================
function Close()
	UIManager:DequeuePopup(ContextPtr);
end

-- ===========================================================================
function OnInputHandler( pInputStruct:table )
	local uiMsg :number = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp and pInputStruct:GetKey() == Keys.VK_ESCAPE then
		Close();
		return true;
	end
	return false;
end

-- ===========================================================================
function OnInit(isReload:boolean)
	LateInitialize();
end

-- ===========================================================================
function OnSecretSocietyDiscovered( pNotification:table )
	if pNotification == nil then
		return;
	end

	local eType:number = pNotification:GetType();
	if eType ~= NotificationTypes.SECRETSOCIETY_DISCOVERED then
		return;
	end

	local ePlayer:number = pNotification:GetValue( "PARAM_DATA0" );
	local eSociety:number = pNotification:GetValue( "PARAM_DATA1" );

	if ePlayer ~= Game.GetLocalPlayer() then
		return;
	end
	local kPlayer:table = Players[ePlayer];
	if kPlayer == nil then
		return;
	end
	local kPlayerGovernors:table = kPlayer:GetGovernors();
	if kPlayerGovernors == nil then
		return;
	end
	local kSocietyDef:table = GameInfo.SecretSocieties[eSociety];
	if kSocietyDef == nil then
		return;
	end

	Controls.EventTitle:SetText(Locale.ToUpper("LOC_DISCOVERED_SOCIETY"));
	Controls.EventDescription:SetText(Locale.Lookup("LOC_DISCOVERED_SOCIETY_DESC", kSocietyDef.Name));
	
	Controls.SocietyImage:SetTexture("SecretSocieties_EventsFG_Discover");
	local memberSocietyHash = kPlayerGovernors:GetSecretSociety();
	local kMemberSocietyDef:table = GameInfo.SecretSocieties[memberSocietyHash];
	if (kMemberSocietyDef ~= nil) then
		Controls.SocietyDescription:SetText(Locale.Lookup("LOC_DISCOVERED_SOCIETY_WHILE_MEMBER_OF_ANOTHER", kSocietyDef.Name, kMemberSocietyDef.Name));		
	else
		Controls.SocietyDescription:SetText(Locale.Lookup(kSocietyDef.DiscoveryText));
	end

	Open();
end

-- ===========================================================================
function OnSecretSocietyJoined( pNotification:table )
	if pNotification == nil then
		return;
	end

	local eType:number = pNotification:GetType();
	if eType ~= NotificationTypes.SECRETSOCIETY_JOINED then
		return;
	end

	local ePlayer:number = pNotification:GetValue( "PARAM_DATA0" );
	local eSociety:number = pNotification:GetValue( "PARAM_DATA1" );

	if ePlayer ~= Game.GetLocalPlayer() then
		return;
	end

	local kSocietyDef:table = GameInfo.SecretSocieties[eSociety];
	if kSocietyDef == nil then
		return;
	end

	Controls.EventTitle:SetText(Locale.ToUpper("LOC_JOINED_SOCIETY"));
	Controls.EventDescription:SetText(Locale.Lookup("LOC_JOINED_SOCIETY_DESC", kSocietyDef.Name));
	
	Controls.SocietyImage:SetTexture(kJoinedImages[kSocietyDef.SecretSocietyType]);
	Controls.SocietyDescription:SetText(Locale.Lookup(kSocietyDef.MembershipText));

	Open();
end

-- ===========================================================================
function Subscribe()
	LuaEvents.NotificationPanel_SecretSocietyDiscovered.Add( OnSecretSocietyDiscovered );
	LuaEvents.NotificationPanel_SecretSocietyJoined.Add( OnSecretSocietyJoined );
end

-- ===========================================================================
function Unsubscribe()
	LuaEvents.NotificationPanel_SecretSocietyDiscovered.Remove( OnSecretSocietyDiscovered );
	LuaEvents.NotificationPanel_SecretSocietyJoined.Remove( OnSecretSocietyJoined );
end

-- ===========================================================================
function OnShutdown()
	Unsubscribe();
end

-- ===========================================================================
function LateInitialize()
	Subscribe();
end

-- ===========================================================================
function Initialize()
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetInputHandler( OnInputHandler, true );
	ContextPtr:SetShutdown( OnShutdown );

	Controls.OpenGovernorsButton:RegisterCallback( Mouse.eLClick, OnOpenGovernorsButton );
	Controls.ContinueButton:RegisterCallback( Mouse.eLClick, OnContinueButton );
end
Initialize();