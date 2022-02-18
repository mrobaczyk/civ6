----------------------------------------------------------------  
-- Scripting to give random names to the Alien Faction's helicopter/UFO units.
----------------------------------------------------------------  
include "SupportFunctions" -- RandRange


----------------------------------------------------------------  
-- Variables
----------------------------------------------------------------  
local m_eHelicopterTypeHash	:number = GameInfo.Units["UNIT_HELICOPTER"].Hash;
local m_ufoNames =
{
	"LOC_UFO_UNIT_NAME1",
	"LOC_UFO_UNIT_NAME2",
	"LOC_UFO_UNIT_NAME3",
	"LOC_UFO_UNIT_NAME4",
	"LOC_UFO_UNIT_NAME5",
	"LOC_UFO_UNIT_NAME6",
}


----------------------------------------------------------------  
-- Event Handlers
----------------------------------------------------------------  
function UFONames_OnUnitInitialized(iPlayerID : number, iUnitID : number)
	local pUnit :object = UnitManager.GetUnit(iPlayerID, iUnitID);
	if (pUnit == nil) then
		return;
	end

	if(pUnit:GetTypeHash() ~= m_eHelicopterTypeHash) then
		return;
	end

	local pPlayerConfig : table = PlayerConfigurations[iPlayerID];
	if (pPlayerConfig == nil or pPlayerConfig:GetCivilizationTypeName() ~= g_CivTypeNames.Aliens) then
		return;
	end

	
	local ufoRand :number = RandRange(1, #m_ufoNames, "Selecting UFO Name");
	pUnit:GetExperience():SetVeteranName(Locale.Lookup(m_ufoNames[ufoRand]));
end


----------------------------------------------------------------  
-- Script Initialization
---------------------------------------------------------------- 
function Initialize()
	print("Civ Royale UFO Unit Names initializing");		
	GameEvents.UnitInitialized.Add(UFONames_OnUnitInitialized);
end
Initialize();