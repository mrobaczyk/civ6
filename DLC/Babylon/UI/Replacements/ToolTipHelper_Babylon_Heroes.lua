-------------------------------------------------------------------------------
-- ToolTipHelper
-------------------------------------------------------------------------------
include("HeroesSupport")

local BASE_GetUnitToolTip = ToolTipHelper.GetUnitToolTip;


	

-- Get the tooltip for a given unit.  Formation and build queue are both required if you want to get
-- the formation version of the tooltip.
ToolTipHelper.GetUnitToolTip = function(unitType, formationType, pBuildQueue)

	
	-- ToolTip Format
	-- <Name>
	-- <Promotion Class>
	-- <Combat>
	-- <Ranged Combat / Range>
	-- <Bombard Combat / Range>
	-- <Moves>
	-- <Static Description>
	local unitReference = GameInfo.Units[unitType];
	local promotionClassReference = GameInfo.UnitPromotionClasses[unitReference.PromotionClass];

	local nameLoc = Locale.ToUpper(unitReference.Name); --TODO: Replace with GameCore Query since Units can have custom names.
	local promotionClass = "";
	if (promotionClassReference ~= nil) then
		promotionClass = promotionClassReference.Name;
	end
	local baseCombat = unitReference.Combat;
	local baseRangedCombat = unitReference.RangedCombat;
	local baseRange = unitReference.Range;
	local baseBombard = unitReference.Bombard;
	local baseMoves = unitReference.BaseMoves;
	local description = unitReference.Description;
	local cost = unitReference.Cost or 0;
	local baseLifespan = UnitManager.GetUnitTypeBaseLifespan(unitReference.Index);

	-- HEROES stat overrides
	local eHeroClass:number = -1;
	local baseCharges = 0;
	--local pHeroClassInfo = {};
	local pGameHeroes:object = Game.GetHeroesManager();
	if (pGameHeroes ~= nil) then
		eHeroClass = pGameHeroes:GetUnitHeroClass(unitReference.Index);
		--pHeroClassInfo = GameInfo.HeroClasses[eHeroClass];
	end
	if (eHeroClass ~= -1) then
		local tHeroStats:table = GetHeroUnitStats(eHeroClass);
		baseCombat = tHeroStats.Combat or 0;
		baseRangedCombat = tHeroStats.RangedCombat or 0;
		baseCharges = tHeroStats.Charges or 0;
	end

	--If this is a specific military formation we need build queue to get correct production costs.
	--The rest of this logic is copied from Unit_Instance:GetCombat functions because it is not exposed to the lua. 
	if( formationType ~= nil and pBuildQueue ~= nil ) then

		local strengthMod = 0;
		if formationType == MilitaryFormationTypes.CORPS_MILITARY_FORMATION then
			strengthMod = GlobalParameters.COMBAT_CORPS_STRENGTH_MODIFIER; 
			
			if unitReference.Domain == "DOMAIN_SEA" then
				nameLoc = nameLoc .. " " .. Locale.Lookup("LOC_UNITFLAG_FLEET_SUFFIX");
			else
				nameLoc = nameLoc .. " " .. Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX");
			end
		elseif formationType == MilitaryFormationTypes.ARMY_MILITARY_FORMATION then
			strengthMod = GlobalParameters.COMBAT_ARMY_STRENGTH_MODIFIER;
			
			if unitReference.Domain == "DOMAIN_SEA" then
				nameLoc = nameLoc .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMADA_SUFFIX");
			else
				nameLoc = nameLoc .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMY_SUFFIX");
			end
		end
		
		if baseCombat > 0 then
			baseCombat = baseCombat + strengthMod;
		end
		if baseRangedCombat > 0 then
			baseRangedCombat = baseRangedCombat + strengthMod;
		end
		if baseBombard > 0 then
			baseBombard = baseBombard + strengthMod;
		end
	end
	
	-- Build ze tip!
	-- Build the tool tip line by line.
	local toolTipLines = {};
	table.insert(toolTipLines, nameLoc);

	local replaces_unit;
	local replaces = GameInfo.UnitReplaces[unitType];
	if(replaces) then
		replaces_unit = GameInfo.Units[replaces.ReplacesUnitType];
	end

	if(replaces_unit) then
		table.insert(toolTipLines, Locale.Lookup("LOC_UNIT_NAME_REPLACES", replaces_unit.Name));
	else
		table.insert(toolTipLines, Locale.Lookup("LOC_UNIT_NAME"));
	end

	if(not Locale.IsNilOrWhitespace(promotionClass)) then
		if (unitReference.UnitType == nil or string.find(unitReference.UnitType, "UNIT_HERO") == nil) then
			table.insert(toolTipLines, Locale.Lookup("LOC_UNIT_PROMOTION_CLASS", promotionClass));
		end
	end
	
	if(not Locale.IsNilOrWhitespace(description)) then
		description = "[NEWLINE]" .. Locale.Lookup(description);
		table.insert(toolTipLines, description);
	end

	local statLines = {};

	if(baseCombat ~= nil and baseCombat > 0) then
		table.insert(statLines, Locale.Lookup("LOC_UNIT_COMBAT_STRENGTH", baseCombat));
	end
	if(baseRangedCombat ~= nil and baseRangedCombat > 0 and baseRange ~= nil and baseRange > 0) then
		table.insert(statLines, Locale.Lookup("LOC_UNIT_RANGED_STRENGTH", baseRangedCombat, baseRange));
	end
	if(baseBombard ~= nil and baseBombard > 0 and baseRange ~= nil and baseRange > 0) then
		table.insert(statLines, Locale.Lookup("LOC_UNIT_BOMBARD_STRENGTH", baseBombard, baseRange));
	end

	if(baseLifespan ~= nil and baseLifespan > 0) then
		table.insert(statLines, Locale.Lookup("LOC_UNIT_LIFESPAN", baseLifespan));
	end

	if(baseCharges ~= nil and baseCharges > 0) then
		table.insert(statLines, Locale.Lookup("LOC_UNIT_ACTION_CHARGES", baseCharges));
	end

	if(baseMoves ~= nil and baseMoves > 0) then
		if (not unitReference.IgnoreMoves or unitReference.Domain == "DOMAIN_AIR") then
			table.insert(statLines, Locale.Lookup("LOC_UNIT_MOVEMENT", baseMoves));
		end
	end

	local airSlots = unitReference.AirSlots or 0;
	if(airSlots ~= 0) then
		table.insert(statLines, Locale.Lookup("LOC_TYPE_TRAIT_AIRSLOTS", airSlots));
	end

	if(#statLines > 0) then
		local firstLine = statLines[1];
		statLines[1] = "[NEWLINE]" .. firstLine;

		for i, v in ipairs(statLines) do
			table.insert(toolTipLines, v);
		end
	end

	local costLines= {};
	--If formation type or buildqueue is supplied, show the in-game values, otherwise just display the base values
	if( formationType ~= nil and pBuildQueue ~= nil ) then
		local nProductionCost		:number = pBuildQueue:GetUnitCost( unitReference.Index );
		if (formationType == MilitaryFormationTypes.CORPS_MILITARY_FORMATION) then
			nProductionCost	= pBuildQueue:GetUnitCorpsCost( unitReference.Index );
		elseif (formationType == MilitaryFormationTypes.ARMY_MILITARY_FORMATION) then
			nProductionCost	= pBuildQueue:GetUnitArmyCost( unitReference.Index );
		end
		
		if (nProductionCost ~= 0) then
			local costString		:string = tostring(nProductionCost);
			local nProductionProgress	:number = pBuildQueue:GetUnitProgress( unitReference.Index );
			if (nProductionProgress > 0) then -- Only show fraction if build progress has been made.
				costString = tostring(nProductionProgress) .. "/" .. costString;
			end
			local prodCosts = Locale.Lookup("LOC_HUD_PRODUCTION_COST") .. ": " .. costString .. " [ICON_Production] " .. Locale.Lookup("LOC_HUD_PRODUCTION");
			if(not Locale.IsNilOrWhitespace(prodCosts)) then
				table.insert(costLines, prodCosts);
			end
		end
		
		local strategicCosts = AddUnitStrategicResourceTooltip(unitReference, formationType, pBuildQueue);
		if(not Locale.IsNilOrWhitespace(strategicCosts)) then
			table.insert(costLines, strategicCosts);
		end

		local nMaintenanceCost		:number = UnitManager.GetUnitMaintenance(unitReference.Hash) or 0;
		if (nMaintenanceCost ~= nil and nMaintenanceCost > 0) then
			local yield = GameInfo.Yields["YIELD_GOLD"];
			if(yield) then
				table.insert(costLines, Locale.Lookup("LOC_TOOLTIP_MAINTENANCE", nMaintenanceCost, yield.IconString, yield.Name));
			end
		end

		local resourceMaintenance = AddUnitResourceMaintenanceTooltip(unitReference, formationType);
		if(not Locale.IsNilOrWhitespace(resourceMaintenance)) then
			table.insert(costLines, resourceMaintenance);
		end

	else
		if(cost ~= 0 and unitReference.MustPurchase == false and unitReference.CanTrain) then
			local yield = GameInfo.Yields["YIELD_PRODUCTION"];
			if(yield) then
				table.insert(costLines, Locale.Lookup("LOC_TOOLTIP_BASE_COST", cost, yield.IconString, yield.Name));
			end
		end

		if(unitReference.StrategicResource) then
			-- the base version of AddUnitStrategicResourceTooltip takes a table reference and inserts two lines and returns nil.
			-- the XP2 version doesn't take the table reference and returns a string to insert.
			-- this papers over the differences.
			local strategicResourceTooltip : string = AddUnitStrategicResourceTooltip(unitReference, formationType, pBuildQueue, costLines);
			if(not Locale.IsNilOrWhitespace(strategicResourceTooltip)) then
				table.insert(costLines, strategicResourceTooltip);
			end
		end

		local maintenance = unitReference.Maintenance or 0;
		if(maintenance ~= 0) then
			local yield = GameInfo.Yields["YIELD_GOLD"];
			if(yield) then
				table.insert(costLines, Locale.Lookup("LOC_TOOLTIP_MAINTENANCE", maintenance, yield.IconString, yield.Name));
			end
		end

		local resourceMaintenance = AddUnitResourceMaintenanceTooltip(unitReference, formationType);
		if(not Locale.IsNilOrWhitespace(resourceMaintenance)) then
			table.insert(costLines, resourceMaintenance);
		end;
	end

	if(#costLines > 0) then
		local firstEntry = costLines[1];
		costLines[1] = "[NEWLINE]" .. firstEntry;

		for i, v in ipairs(costLines) do
			table.insert(toolTipLines, v);
		end
	end
	
	-- return the composite tooltip
	return table.concat(toolTipLines, "[NEWLINE]");
end