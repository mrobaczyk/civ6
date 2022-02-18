-- Copyright 2017-2019, Firaxis Games
include("TeamSupport");
include("DiplomacyRibbonSupport");


BASE_GetToolTipString = GetToolTipString;

------------------------------------------------------------------
--Override
------------------------------------------------------------------
function LeaderIcon:GetToolTipString(playerID:number)

	local result:string = "";
	local pPlayerConfig:table = PlayerConfigurations[playerID];

	if pPlayerConfig and pPlayerConfig:GetLeaderTypeName() then
		local isHuman		:boolean = pPlayerConfig:IsHuman();
		local leaderDesc	:string = pPlayerConfig:GetLeaderName();
		local civDesc		:string = pPlayerConfig:GetCivilizationDescription();
		local localPlayerID	:number = Game.GetLocalPlayer();
		
		if localPlayerID==PlayerTypes.NONE or localPlayerID==PlayerTypes.OBSERVER  then
			return "";
		end		

		if GameConfiguration.IsAnyMultiplayer() and isHuman then
			if(playerID ~= localPlayerID) then
				result = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER") .. "[NEWLINE]" .. "[NEWLINE]" .. Locale.Lookup("LOC_CIV_ROYALE_HUD_PLAYER_NAME_LABEL") .. " " .. pPlayerConfig:GetPlayerName();
			end
			if(playerID ~= localPlayerID and not Players[localPlayerID]:GetDiplomacy():HasMet(playerID)) then
				result = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER") .. "[NEWLINE]" .. "[NEWLINE]" .. Locale.Lookup("LOC_CIV_ROYALE_HUD_PLAYER_NAME_LABEL") .. " " .. pPlayerConfig:GetPlayerName();
			else
				local primaryColor, secondaryColor = UI.GetPlayerColors( playerID );
				local r,g,b,a = GetColorForPlayerNameInToolTip(primaryColor, secondaryColor);
				result = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", leaderDesc, civDesc) .. "[NEWLINE]" .. "[NEWLINE]" .. Locale.Lookup("LOC_CIV_ROYALE_HUD_PLAYER_NAME_LABEL") .. " " .. "[COLOR:" .. r .. "," .. g .. "," .. b .. "," .. a .. "]" .. pPlayerConfig:GetPlayerName() .. "[ENDCOLOR]";
			end
		else
			if(playerID ~= localPlayerID and not Players[localPlayerID]:GetDiplomacy():HasMet(playerID)) then
				result = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER");
			else
				result = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", leaderDesc, civDesc);
			end
		end
	end

	return result;
end

------------------------------------------------------------------
-- Determine the color to use (primary or secondary) for the 
-- Player name in the tool tip. 
------------------------------------------------------------------
function GetColorForPlayerNameInToolTip(primary:number, secondary:number)
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

------------------------------------------------------------------