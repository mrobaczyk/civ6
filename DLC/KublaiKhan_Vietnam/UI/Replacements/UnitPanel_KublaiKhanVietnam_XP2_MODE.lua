-- ===========================================================================
--	Unit Panel overrides for Monopolies & Corporations XP2
-- ===========================================================================
include( "UnitPanel_Expansion2.lua" )

-- ===========================================================================
--	OVERRIDES
-- ===========================================================================
BASE_LateInitialize = LateInitialize;
BASE_BuildActionModHook = BuildActionModHook;

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_ResourceTypeMap    	:table  = {};

-- we intercept this to change the tooltip for building an industry
function BuildActionModHook( instance:table, action:table )
	-- is this the "build improvement" action, and is it for an industry?
	if action.userTag == UnitOperationTypes.BUILD_IMPROVEMENT and action.IconId == "ICON_IMPROVEMENT_INDUSTRY" then
		-- do we have a selected player and unit?
		if(g_selectedPlayerId ~= nil and g_selectedPlayerId ~= -1 and g_UnitId ~= nil and g_UnitId ~= -1) then
			local units = Players[g_selectedPlayerId]:GetUnits();
			local unit = units:FindID(g_UnitId);
			if (unit ~= nil) then
				local unitPos:number = unit:GetPlotId();
				if (Map.IsPlot(unitPos)) then
					local plot:table = Map.GetPlotByIndex(unitPos);
					if plot ~= nil then
						local resName:string = m_ResourceTypeMap[plot:GetResourceType()];

						-- use the resource name to look up the effect text
						if resName ~= nil then
							local effectStr:string = nil;
							for row in GameInfo.ResourceIndustries() do
								if row.PrimaryKey == resName then
									effectStr = row.ResourceEffectTExt;
									break;
								end
							end
							-- if we have a valid effect string after all of that, append it to the existing tooltip text
							if effectStr ~= nil then
								action.helpString = action.helpString.."[NEWLINE]"..Locale.Lookup(effectStr);
							end
						end
					end
				end
			end
		end
	end

	BASE_BuildActionModHook(instance, action);
end

function LateInitialize()
	m_ResourceTypeMap = {};
	do
		for row in GameInfo.Resources() do
			m_ResourceTypeMap[row.Index] = row.ResourceType;
		end
	end
	BASE_LateInitialize();
end


