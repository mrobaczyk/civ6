-- Copyright 2020, Firaxis Games
-- Helper functions for Heroes Mode UI
include( "UnitSupport" );

local _HeroClassAbilitiesTable = {};
_HeroClassAbilitiesTable["HEROCLASS_ANANSI"] = {
	"ABILITY_HERO_IGNORE_FOREST_TERRAIN_COST",
};
_HeroClassAbilitiesTable["HEROCLASS_BEOWULF"] = {
	"ABILITY_HERO_IGNORE_HILLS_TERRAIN_COST",
};
_HeroClassAbilitiesTable["HEROCLASS_HERCULES"] = {
	"ABILITY_HERO_IGNORE_HILLS_TERRAIN_COST",
};
_HeroClassAbilitiesTable["HEROCLASS_HIMIKO"] = {
	"ABILITY_HERO_COMBAT_STRENGTH_AOE",
	"ABILITY_HERO_IGNORE_ALL_TERRAIN_COST",
};
_HeroClassAbilitiesTable["HEROCLASS_HIPPOLYTA"] = {
	"ABILITY_HIPPOLYTA_HEAL_PER_TURN",
	"ABILITY_HERO_IGNORE_HILLS_TERRAIN_COST",
};
_HeroClassAbilitiesTable["HEROCLASS_HUNAHPU"] = {
	"ABILITY_HUNAHPU_RESURRECT_KILL",
	"ABILITY_HERO_IGNORE_FOREST_TERRAIN_COST",
};
_HeroClassAbilitiesTable["HEROCLASS_OYA"] = {
	"ABILITY_HERO_IGNORE_ALL_TERRAIN_COST",
};
_HeroClassAbilitiesTable["HEROCLASS_MAUI"] = {
	"ABILITY_HERO_IGNORE_FOREST_TERRAIN_COST",
};
_HeroClassAbilitiesTable["HEROCLASS_MULAN"] = {
	"ABILITY_MULAN_STRENGTH_PER_TURN",
	"ABILITY_MULAN_FORTIFY",
};
_HeroClassAbilitiesTable["HEROCLASS_SINBAD"] = {
	"ABILITY_SINBAD_GOLD_FOR_DISCOVERY",
	"ABILITY_SINBAD_OCEAN_VALID_TERRAIN",
};
_HeroClassAbilitiesTable["HEROCLASS_WUKONG"] = {
	"ABILITY_WUKONG_STEALTH",
	"ABILITY_WUKONG_LIFESPAN",
	"ABILITY_HERO_IGNORE_ALL_TERRAIN_COST",
};

-- ===========================================================================
--	Stats
-- ===========================================================================
function GetHeroUnitStats( eHeroClass:number )

	if eHeroClass == -1 then
		return {};
	end
	
	local pHeroInfo:table = GameInfo.HeroClasses[eHeroClass];
	if (pHeroInfo == nil) then
		return {};
	end

	local pUnitInfo:table = GameInfo.Units[pHeroInfo.UnitType];
	if (pUnitInfo == nil) then
		UI.DataError("HeroesSupport could not find UnitType info for HeroClass: '"..tostring(eHeroClass));
		return {};
	end

	local eCurrentEra:number = Support_GetCurrentEra();
	local pEraInfo:table = GameInfo.Eras[eCurrentEra];
	if (pEraInfo == nil) then
		UI.DataError("HeroesSupport could not find current Era info: '"..tostring(eCurrentEra));
		return {};
	end

	-- Base stats
	local tStats:table = {};
	tStats.Combat = pUnitInfo.Combat;
	tStats.RangedCombat = pUnitInfo.RangedCombat;
	tStats.Range = pUnitInfo.Range;
	tStats.BaseMoves = pUnitInfo.BaseMoves;
	tStats.Lifespan = UnitManager.GetUnitTypeBaseLifespan(pUnitInfo.Index);

	-- Progressive stats: select these by era
	local tProgressionResults:table = DB.Query("SELECT * FROM HeroClassProgressions WHERE HeroClassType = '".. pHeroInfo.HeroClassType .. "' and EraType = '" .. pEraInfo.EraType .. "' LIMIT 1");
	if (tProgressionResults ~= nil and #tProgressionResults > 0) then
		tStats.Combat = tProgressionResults[1].CombatStrength;
		tStats.RangedCombat = tProgressionResults[1].RangedCombatStrength;
	end

	local pGameHeroes:object = Game.GetHeroesManager();
	if pGameHeroes then
		tStats.Charges = pGameHeroes:GetHeroClassBaseCharges(eHeroClass);
	end

	return tStats;
end

-- ===========================================================================
--	Abilities and Commands
-- ===========================================================================
function FormatHeroClassAbilitiesAndCommands( eHeroClass:number )

	local pAbilities:table = GetHeroClassUnitAbilities(eHeroClass);
	local pCommands:table = GetHeroClassUnitCommands(eHeroClass);

	if (#pAbilities == 0 and #pCommands == 0) then
		return "";
	end

	local sResultString:string = "";

	for i,row in ipairs(pAbilities) do
		local sRowString:string = Locale.Lookup(row.Name) .. ": " .. Locale.Lookup(row.Description);
		if (sResultString ~= "") then 
			sRowString = "[NEWLINE]" .. sRowString 
		end;
		sResultString = sResultString .. sRowString;
	end

	for i,row in ipairs(pCommands) do
		local sRowString:string = Locale.Lookup(row.Name) .. ": " .. Locale.Lookup(row.Description);
		if (sResultString ~= "") then 
			sRowString = "[NEWLINE]" .. sRowString 
		end;
		sResultString = sResultString .. sRowString;
	end

	return sResultString;
end

-- ===========================================================================
function GetHeroClassUnitAbilities( eHeroClass:number )

	if eHeroClass == -1 then
		return {};
	end
	local pHeroInfo:table = GameInfo.HeroClasses[eHeroClass];
	if (pHeroInfo == nil) then
		return {};
	end

	local pResultAbilities:table = {};

	local pClassAbilityTypes:table = _HeroClassAbilitiesTable[pHeroInfo.HeroClassType];
	if (pClassAbilityTypes ~= nil) then
		for _,sAbilityType in ipairs(pClassAbilityTypes) do
			
			local pAbility = GameInfo.UnitAbilities[sAbilityType];
			if (pAbility ~= nil) then

				local pAbilityData:table = {};
				pAbilityData.Icon = ""; -- TODO
				pAbilityData.Name = pAbility.Name;

				local sDesc:string = GetUnitAbilityDescription(pAbility.Index);
				if (sDesc ~= nil and sDesc ~= "") then
					pAbilityData.Description = sDesc;
				end

				table.insert(pResultAbilities, pAbilityData);
			end
		end
	end

	return pResultAbilities;
end

-- ===========================================================================
function GetHeroClassUnitCommands( eHeroClass:number )

	if eHeroClass == -1 then
		return {};
	end
	local pHeroInfo:table = GameInfo.HeroClasses[eHeroClass];
	if (pHeroInfo == nil) then
		return {};
	end

	local pResultCommands:table = {};
	for row in GameInfo.HeroClassUnitCommands() do
		if (row.HeroClassType == pHeroInfo.HeroClassType) then

			local pUnitCommand:table = GameInfo.UnitCommands[row.UnitCommandType];
			if (pUnitCommand ~= nil) then

				local pCommandData:table = {};
				pCommandData.Icon = pUnitCommand.Icon;
				pCommandData.Name = pUnitCommand.Description;
				pCommandData.Description = UnitManager.GetCommandHelpText(pUnitCommand.Hash, Game.GetLocalPlayer());
				table.insert(pResultCommands, pCommandData);
			end
		end
	end

	return pResultCommands;
end

-- ===========================================================================
--	Helpers
-- ===========================================================================
function Support_GetCurrentEra()
	-- Era system changed between BASE and XP1
	-- XP1+...
	if (Game.GetEras ~= nil) then
		return Game.GetEras():GetCurrentEra();
	end

	-- BASE
	local pPlayer = Players[Game.GetLocalPlayer()];
	if (pPlayer ~= nil) then
		return pPlayer:GetEra();
	end

	-- FAILSAFE
	return EraTypes.ERA_ANCIENT;
end