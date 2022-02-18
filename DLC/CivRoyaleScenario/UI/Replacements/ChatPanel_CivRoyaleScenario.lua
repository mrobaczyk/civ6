----------------------------------------------------------------  
-- Ingame Chat Panel
----------------------------------------------------------------  
include( "SupportFunctions"  );		--TruncateString
include( "PlayerTargetLogic" );
include( "ChatLogic" );
include( "NetConnectionIconLogic" );
include( "NetworkUtilities" );
include( "InstanceManager" );
include( "ChatPanel" );

-- ===========================================================================
--OVERRIDES
-- ===========================================================================
BASE_OnShutdown = OnShutdown;
BASE_Initialize = Initialize;

local m_ChatInstances : table = {};

-- ===========================================================================
function OnChat( fromPlayer, toPlayer, text, eTargetType, playSounds :boolean )
	
	if(GetIsChatPanelFilled() and Controls.ChatEntryStack:GetSizeY() < Controls.ChatLogPanel:GetSizeY())then
		SetIsChatPanelFilled(false);
	end
	
	local pLocalPlayerConfig :table	= PlayerConfigurations[Game.GetLocalPlayer()];
	local pFromPlayerConfig :table = PlayerConfigurations[fromPlayer];

	local fromPlayerName	:string = Locale.Lookup(pFromPlayerConfig:GetPlayerName()); 

	if(pFromPlayerConfig:GetSlotStatus() == SlotStatus.SS_OBSERVER)then
		if(pLocalPlayerConfig:IsAlive())then
			return;
		else
			fromPlayerName = fromPlayerName .. " " .. Locale.Lookup("LOC_ACTION_PANEL_OBSERVING");
		end
	end
	
	-- Selecting chat text color based on eTargetType	
	local chatColor :string = "[color:ChatMessage_Global]";
	if(eTargetType == ChatTargetTypes.CHATTARGET_TEAM) then
		chatColor = "[color:ChatMessage_Team]";
	elseif(eTargetType == ChatTargetTypes.CHATTARGET_PLAYER) then
		chatColor = "[color:ChatMessage_Whisper]";  
	end
	
	local chatString	:string = "[color:ChatPlayerName]" .. fromPlayerName;

	-- When whispering, include the whisperee's name as well.
	if(eTargetType == ChatTargetTypes.CHATTARGET_PLAYER) then
		local pTargetConfig :table	= PlayerConfigurations[toPlayer];
		if(pTargetConfig ~= nil) then
			local targetName = Locale.Lookup(pTargetConfig:GetPlayerName());
			chatString = chatString .. " [" .. targetName .. "]";
		end
	end

	-- When a map pin is sent, parse and build button
	if(string.find(text, "%[pin:%d+,%d+%]")) then
		-- parse the string
		local pinStr = string.sub(text, string.find(text, "%[pin:%d+,%d+%]"));
		local pinPlayerIDStr = string.sub(pinStr, string.find(pinStr, "%d+"));
		local comma = string.find(pinStr, ",");
		local pinIDStr = string.sub(pinStr, string.find(pinStr, "%d+", comma));
		
		local pinPlayerID = tonumber(pinPlayerIDStr);
		local pinID = tonumber(pinIDStr);

		-- Only build button if valid pin
		-- TODO: player can only send own/team pins. ??PEP
		if(GetMapPinConfig(pinPlayerID, pinID) ~= nil) then
			chatString = chatString .. ": [ENDCOLOR]";
			AddMapPinChatEntry(pinPlayerID, pinID, chatString, Controls.ChatEntryStack, m_ChatInstances, Controls.ChatLogPanel);
			return;
		end
	end

	-- Ensure text parsed properly
	text = ParseChatText(text);

		-- Add a space before the [ENDCOLOR] tag to prevent the user from accidentally escaping it
	chatString			= chatString .. ": [ENDCOLOR]" .. chatColor .. text .. " [ENDCOLOR]";

	AddChatEntry( chatString, Controls.ChatEntryStack, m_ChatInstances, Controls.ChatLogPanel);

	if(playSounds and fromPlayer ~= Network.GetLocalPlayerID()) then
		UI.PlaySound("Play_MP_Chat_Message_Received");
	end

	if fromPlayer ~= Network.GetLocalPlayerID() then
		local isHidden
		LuaEvents.ChatPanel_OnChatReceived(fromPlayer, ContextPtr:GetParent():IsHidden());
	end

	--Ensure the chat panels begin to auto scroll when they are first filled

	if( not GetIsChatPanelFilled() )then
		if(Controls.ChatEntryStack:GetSizeY() > Controls.ChatLogPanel:GetSizeY())then
			GetIsChatPanelFilled(true);
			Controls.ChatLogPanel:SetScrollValue(1);
		end
	end
end

-- ===========================================================================
-- Determine the color to use (primary or secondary) for the 
-- Player name in the tool tip. 
-- ===========================================================================
function GetColorForPlayerNameInPlayerEntry(primary:number, secondary:number)
	local r,g,b,a = UI.GetColorChannels(primary);
	local r1,g1,b1,a1 = UI.GetColorChannels(secondary);
	local h, s, v = RBGtoHSV( r, g, b);
	local h1, s1, v1 = RBGtoHSV( r1, g1, b1);
	if (s == 0 and s1 == 0) then
		-- Choose black over white.
		if (v1 > v and v1 < .95) then
			return r1, g1, b1, a1;
		end
	end
	if( s > .4 and v > .3) then
		-- Base colors will work. Use these when possile b/c they are more associable with the player team color.
		return r,g,b,a;
	end
	if( v == 1 or s == 1) then
		return r,g,b,a;
	end
	if( v1 == 1 or s1 == 1) then
		return r1,g1,b1,a1;
	end
	if(s > s1) then
		return r,g,b,a;
	end
	if(s < s1 ) then
		return r1,g1,b1,a1;
	end
	if (s == 0 and s1 == 0) then
		-- make sure it doesn't default to white
		if(v < v1 ) then
			return r,g,b,a;
		else
			return r1,g1,b1,a1;
		end
	end
	return r,g,b,a;
end

-- ===========================================================================
function UpdatePlayerEntry(iPlayerID :number)
	local playerEntry :table = GetPlayerListEntry(iPlayerID);
	local pPlayerConfig :table = PlayerConfigurations[iPlayerID];
	local entryChanged :boolean = false;
	if(pPlayerConfig ~= nil and (pPlayerConfig:IsAlive() or (GameConfiguration.IsNetworkMultiplayer() and Network.IsPlayerConnected(iPlayerID) and pPlayerConfig:GetSlotStatus() == 4))) then

		-- Create playerEntry if it does not exist.
		if(playerEntry == nil) then
			playerEntry = {};
			ContextPtr:BuildInstanceForControl( "PlayerListEntry", playerEntry, Controls.PlayerListStack);
			SetPlayerListEntry(iPlayerID, playerEntry);
			entryChanged = true;
		end
		local primaryColor, secondaryColor = UI.GetPlayerColors( iPlayerID );
		local r,g,b,a = GetColorForPlayerNameInPlayerEntry(primaryColor, secondaryColor);
		playerEntry.PlayerName:SetText("[COLOR:" .. r .. "," .. g .. "," .. b .. "," .. a .. "]" .. Locale.Lookup(pPlayerConfig:GetSlotName()) .. "[ENDCOLOR]"); 
		playerEntry.FactionName:SetText("[COLOR:" .. r .. "," .. g .. "," .. b .. "," .. a .. "]" .. Locale.Lookup(pPlayerConfig:GetLeaderName()) .. "[ENDCOLOR]");
		UpdateNetConnectionIcon(iPlayerID, playerEntry.ConnectionIcon);
		UpdateNetConnectionLabel(iPlayerID, playerEntry.ConnectionLabel);
		local numEntries:number = PopulatePlayerPull(iPlayerID, playerEntry.PlayerListPull, GetPlayerListPullData);
		playerEntry.PlayerListPull:SetDisabled(numEntries == 0 or iPlayerID == Game.GetLocalPlayer());
		playerEntry.ConnectionLabel:SetText("");
		if iPlayerID == Network.GetGameHostPlayerID() then
			local connectionText:string = "[ICON_Host]";
			playerEntry.ConnectionLabel:SetText(connectionText);
		end
	else
		-- playerEntry should not exist for this player.  Delete it if it exists.
		if(playerEntry ~= nil) then
			Controls.PlayerListStack:DestroyChild(playerEntry);
			SetPlayerListEntry(iPlayerID, nil);
			playerEntry = nil;
			entryChanged = true;
		end
	end

	if(playerEntry ~= nil)then
		playerEntry.FactionName:SetHide(false);
	end

	if(entryChanged == true) then
		Controls.PlayerListStack:CalculateSize();
	end
end

-- ===========================================================================
function OnStartObserverMode()
	ClearKickVoteInstances();
end

-- ===========================================================================
function OnShutdown()
	BASE_OnShutdown();
	Events.KickVoteStarted.Remove(OnKickVoteStarted);
	Events.KickVoteComplete.Remove(OnKickVoteComplete);

	LuaEvents.EndGameMenu_StartObserverMode.Remove( OnStartObserverMode );
end

-- ===========================================================================
function Initialize()
	BASE_Initialize();
	Events.KickVoteStarted.Add(OnKickVoteStarted);
	Events.KickVoteComplete.Add(OnKickVoteComplete);

	LuaEvents.EndGameMenu_StartObserverMode.Add( OnStartObserverMode );
end