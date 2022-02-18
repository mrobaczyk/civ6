-- ===========================================================================
--	Announcer Logic
--
--  App-side LUA Context that triggers announcer sound lines.
--	CivRoyale Scenario
-- ===========================================================================
include "CivRoyaleScenario_PropKeys"


-- Announcer Non-Local Player Defeated Sound Events (keyed by civilization names)
local m_defeatSoundEvents = {};
m_defeatSoundEvents[g_CivTypeNames.Aliens] = "RedDeath_Aliens_Eliminated";
m_defeatSoundEvents[g_CivTypeNames.Cultists] = "RedDeath_Cultists_Eliminated";
m_defeatSoundEvents[g_CivTypeNames.EdgeLords] = "RedDeath_BorderLords_Eliminated";
m_defeatSoundEvents[g_CivTypeNames.Jocks] = "RedDeath_Jocks_Eliminated";
m_defeatSoundEvents[g_CivTypeNames.Mutants] = "RedDeath_Mutants_Eliminated";
m_defeatSoundEvents[g_CivTypeNames.MadScientists] = "RedDeath_MadSci_Eliminated";
m_defeatSoundEvents[g_CivTypeNames.Pirates] = "RedDeath_Pirates_Eliminated";
m_defeatSoundEvents[g_CivTypeNames.Preppers] = "RedDeath_Prep_Eliminated";
m_defeatSoundEvents[g_CivTypeNames.Wanderers] = "RedDeath_Wander_Eliminated";
m_defeatSoundEvents[g_CivTypeNames.Zombies] = "RedDeath_Zombie_Eliminated";

local m_RandomQuoteChance :number	= 4; 	-- Percent chance (0-100) of the announcer saying a random quote per game turn.
local m_RandomQuoteMinTurns :number = 5;	-- Minimum number of turns between random quotes by the announcer.
local NO_TURN :number				= -1;

local m_RandomQuoteLastTurn :number = NO_TURN;	-- The last turn we played a random announcer quote.

---------------------------------------------------------------- 
-- Announcer Logic
----------------------------------------------------------------
function PlayAnnouncerSound(soundEventName :string)
	print("Playing announcer sound " .. tostring(soundEventName));
	UI.PlaySound(soundEventName);
end


---------------------------------------------------------------- 
-- Event Handlers
---------------------------------------------------------------- 
function OnPlayerDefeat( player, defeat, eventID)
	local localPlayer = Game.GetLocalPlayer();
	if (localPlayer == player) then
		PlayAnnouncerSound("RedDeath_LocalPlayerLoss_Quote");
	else
		-- Do not announce player defeat when this was the last elimination.  Everyone is getting their win/lose quote instead.
		if(PlayerManager.GetAliveMinorsCount() <= 1) then
			return;
		end

		local pPlayerConfig : table = PlayerConfigurations[player];
		if (pPlayerConfig ~= nil) then
			local defeatSound :string = m_defeatSoundEvents[pPlayerConfig:GetCivilizationTypeName()];
			if(defeatSound ~= nil) then
				PlayAnnouncerSound(defeatSound);
			end
		end
	end
end

function OnTurnEnd()
	local currentTurn :number = Game.GetCurrentGameTurn();

	-- m_RandomQuoteMinTurns test
	if(m_RandomQuoteLastTurn ~= NO_TURN and currentTurn <= m_RandomQuoteLastTurn + m_RandomQuoteMinTurns) then
		return;
	end

	-- Announcer VO is not gameplay related so we intentionally do not use the GameCore RNG.
	local randRoll :number = math.random(0, 100, "Announcer Random Quote Chance");
	print("Random Announcer VO for Game Turn randRoll=" .. tostring(randRoll) .. ", m_RandomQuoteChance=" .. tostring(m_RandomQuoteChance));
	if(randRoll < m_RandomQuoteChance) then
		PlayAnnouncerSound("RedDeath_Random_Quote");
		m_RandomQuoteLastTurn = currentTurn;
	end
end

function OnPhaseBegin()
	local currentTurn :number = Game.GetCurrentGameTurn();
	local safeZoneTurn :number = Game:GetProperty(g_ObjectStateKeys.LastSafeZoneTurn);
	local safeZonePhase :number = Game:GetProperty(g_ObjectStateKeys.SafeZonePhase);
	if(safeZoneTurn ~= nil and currentTurn == safeZoneTurn) then
		if(safeZonePhase ~= nil and safeZonePhase == 1) then
			-- Safe Zone Appears
			PlayAnnouncerSound("RedDeath_SafeZoneApp_Quote");
		else
			-- Safe Zone Shrunk
			PlayAnnouncerSound("RedDeath_SafeZoneShrunk_Quote");
		end
	end
end

function OnWMDDetonated(x :number, y :number, iPlayerID :number, eWMD :number)
	PlayAnnouncerSound("RedDeath_WMDLaunch_Quote");
end

function OnTeamVictory( teamID :number, victoryType :number, eventID :number)
	local localPlayerID :number = Game.GetLocalPlayer();
	if(localPlayerID == nil or localPlayerID == PlayerTypes.NONE or localPlayerID == PlayerTypes.OBSERVER) then
		return;
	end

	local pLocalPlayer :object = Players[localPlayerID];
	if(pLocalPlayer:GetTeam() == teamID) then
		PlayAnnouncerSound("RedDeath_LocalPlayerWin_Quote");
	end
end

function OnUnitKilledByFallout(playerID :number, unitID :number, eUnitType :number)
	local localPlayerID :number = Game.GetLocalPlayer();
	if(playerID ~= localPlayerID) then
		return;
	end

	if(eUnitType == GameInfo.Units["UNIT_SETTLER"].Index) then
		-- One of your civilians just died in the red death
		PlayAnnouncerSound("RedDeath_CiveLostToRed_Quote");
	end
end


---------------------------------------------------------------- 
-- Script Initialization
---------------------------------------------------------------- 
function Initialize()
	print("Civ Royale Scenario Announcer initializing");

	Events.PlayerDefeat.Add( OnPlayerDefeat );	
	Events.TurnEnd.Add( OnTurnEnd );
	Events.PhaseBegin.Add( OnPhaseBegin );
	Events.WMDDetonated.Add( OnWMDDetonated );
	Events.TeamVictory.Add( OnTeamVictory );
	Events.UnitKilledByFallout.Add ( OnUnitKilledByFallout );
end
Initialize();