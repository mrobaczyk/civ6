
-- ===========================================================================
--
--	Tutorial items related to GranColombia_Maya DLC
--
-- ===========================================================================

-- Add to tutorial loaders referenced by TutorialUIRoot
local TutorialLoader = {};
table.insert(g_TutorialLoaders, TutorialLoader);

local CLIMATE_CHANGE_LEVEL_THRESHOLD = 8;

-- ===========================================================================
function TutorialLoader:Initialize(TutorialCheck:ifunction)	

	
	if (GameCapabilities.HasCapability("CAPABILITY_MEGADISASTERS")) then
		-- Register game core events
		local iPlayerID : number = Game.GetLocalPlayer();
		if (iPlayerID < 0) then
			return;
		end

		local pPlayer = Players[iPlayerID];
	
		Events.PlayerTurnActivated.Add(function( playerID:number, isFirstTimeThisTurn:boolean )
			local localPlayerID = Game.GetLocalPlayer();
			if (playerID == localPlayerID and isFirstTimeThisTurn) then
				TutorialCheck("MegadisasterModeBegin");
			end

			local getClimateChangeLevel = GameClimate and GameClimate.GetClimateChangeLevel;
			if (localPlayerID ~= nil) then
				if(getClimateChangeLevel and getClimateChangeLevel() >= 8) then
					TutorialCheck("ApocalypseBegin");
				end
			end

		end);

		Events.RandomEventOccurred.Add(function (eEventType:number, eSeverity:number, locX:number, locY:number)
			local localPlayerID = Game.GetLocalPlayer();
			if (player == localPlayerID) then
				local tmpEvent = GameInfo.RandomEvents["RANDOM_EVENT_FOREST_FIRE"];
				if tmpEvent ~= nil and eEventType == tmpEvent.Index then
					TutorialCheck("ForestFireEvent");
				end

				local tmpEvent = GameInfo.RandomEvents["RANDOM_EVENT_JUNGLE_FIRE"];
				if tmpEvent ~= nil and eEventType == tmpEvent.Index then
					TutorialCheck("ForestFireEvent");
				end

				local tmpEvent = GameInfo.RandomEvents["RANDOM_EVENT_METEOR_SHOWER"];
				if tmpEvent ~= nil and eEventType == tmpEvent.Index then
					TutorialCheck("MeteorShowerEvent");
				end

				local tmpEvent = GameInfo.RandomEvents["RANDOM_EVENT_COMET_STRIKE"];
				if tmpEvent ~= nil and eEventType == tmpEvent.Index then
					TutorialCheck("CometStrikeEvent");
				end

				local tmpEvent = GameInfo.RandomEvents["RANDOM_EVENT_SOLAR_FLARE"];
				if tmpEvent ~= nil and eEventType == tmpEvent.Index then
					TutorialCheck("SolarFlareEvent");
				end
			end
		end);

		Events.FaithChanged.Add(function (player:number, faithYield:number, faithBalance:number)
			local soothsayerInfo = GameInfo.Units["UNIT_SOOTHSAYER"];
			if (soothsayerInfo ~= nil) then
				local localPlayerID = Game.GetLocalPlayer();
				if (player == localPlayerID) then
					local pCapital = pPlayer:GetCities():GetCapitalCity();
					local cost = pCapital:GetGold():GetPurchaseCost(FAITH_YIELD_TYPE, soothsayerInfo.Hash)
					if (faithBalance >= cost) then
						TutorialCheck("SoothsayerAvailable");
					end
				end
			end
		end);
	end
end

-- ===========================================================================
function TutorialLoader:CreateTutorialItems(AddToListener:ifunction)

	-- ===========================================================================		
	local item = TutorialItem:new("MEGADISASTER_MODE_BEGIN");
	item:SetRaiseEvents("MegadisasterModeBegin");
	item:SetRaiseFunction(
		function()
			-- If first turn and starting at an XP2 feature, let normal intro play first.
			local tutorialLevel :number = UserConfiguration.TutorialLevel() ;
			local hasChosenTutorialLevel :number = Options.GetUserOption("Tutorial", "HasChosenTutorialLevel");
			if ((tutorialLevel == 0 or tutorialLevel == 1) and hasChosenTutorialLevel == 0) then
				local isCompleted = TutorialItemCompleted("FIRST_GREETING");
				if isCompleted==false then
					AddItemToQueue( item );	-- Force queue for after intro.
				end
				return isCompleted;
			end
			return true;
		end);			
	item:SetTutorialLevel(TutorialLevel.LEVEL_EXPERIENCED_PLAYER);
	item:SetIsEndOfChain(true);
	item:SetIsQueueable(true);
	item:SetShowPortrait(true);
	item:SetAdvisorMessage("LOC_TUTORIAL_FIRST_TIME_MEGADISASTERS");
	item:SetAdvisorAudio("Play_ADVISOR_LINE_FTUE_GENERAL_1");
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_CONTINUE",
		function( advisorInfo )
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
			LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
		end );
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_TELL_ME_MORE",
		function(advisorInfo)
			LuaEvents.OpenCivilopedia("CONCEPTS", "MEGADISASTERS")
			LuaEvents.AdvisorPopup_ClearActive(advisorInfo)
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
		end);
	item:SetIsDoneFunction(
		function()
			return false;
		end );
	AddToListener("MegadisasterModeBegin", item);

	-- ===========================================================================	
	local item = TutorialItem:new("FOREST_FIRE_EVENT");
	item:SetRaiseEvents("ForestFireEvent");		
	item:SetTutorialLevel(TutorialLevel.LEVEL_EXPERIENCED_PLAYER);
	item:SetIsEndOfChain(true);
	item:SetIsQueueable(true);
	item:SetShowPortrait(true);
	item:SetAdvisorMessage("LOC_TUTORIAL_FOREST_FIRES");
	item:SetAdvisorAudio("Play_ADVISOR_LINE_FTUE_GENERAL_1");
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_CONTINUE",
		function( advisorInfo )
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
			LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
		end );
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_TELL_ME_MORE",
		function(advisorInfo)
			LuaEvents.OpenCivilopedia("CONCEPTS", "ENVIRONMENTAL_EFFECTS")
			LuaEvents.AdvisorPopup_ClearActive(advisorInfo)
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
		end);
	item:SetIsDoneFunction(
		function()
			return false;
		end );
	AddToListener("ForestFireEvent", item);

	-- ===========================================================================		
	local item = TutorialItem:new("METEOR_SHOWER_EVENT");
	item:SetRaiseEvents("MeteorShowerEvent");			
	item:SetTutorialLevel(TutorialLevel.LEVEL_EXPERIENCED_PLAYER);
	item:SetIsEndOfChain(true);
	item:SetIsQueueable(true);
	item:SetShowPortrait(true);
	item:SetAdvisorMessage("LOC_TUTORIAL_METEOR_SHOWERS");
	item:SetAdvisorAudio("Play_ADVISOR_LINE_FTUE_GENERAL_1");
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_CONTINUE",
		function( advisorInfo )
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
			LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
		end );
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_TELL_ME_MORE",
		function(advisorInfo)
			LuaEvents.OpenCivilopedia("CONCEPTS", "ENVIRONMENTAL_EFFECTS")
			LuaEvents.AdvisorPopup_ClearActive(advisorInfo)
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
		end);
	item:SetIsDoneFunction(
		function()
			return false;
		end );
	AddToListener("MeteorShowerEvent", item);

	-- ===========================================================================		
	local item = TutorialItem:new("COMET_STRIKE_EVENT");
	item:SetRaiseEvents("CometStrikeEvent");			
	item:SetTutorialLevel(TutorialLevel.LEVEL_EXPERIENCED_PLAYER);
	item:SetIsEndOfChain(true);
	item:SetIsQueueable(true);
	item:SetShowPortrait(true);
	item:SetAdvisorMessage("LOC_TUTORIAL_COMET_IMPACT");
	item:SetAdvisorAudio("Play_ADVISOR_LINE_FTUE_GENERAL_1");
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_CONTINUE",
		function( advisorInfo )
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
			LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
		end );
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_TELL_ME_MORE",
		function(advisorInfo)
			LuaEvents.OpenCivilopedia("CONCEPTS", "ENVIRONMENTAL_EFFECTS")
			LuaEvents.AdvisorPopup_ClearActive(advisorInfo)
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
		end);
	item:SetIsDoneFunction(
		function()
			return false;
		end );
	AddToListener("CometStrikeEvent", item);

	-- ===========================================================================		
	local item = TutorialItem:new("SOLAR_FLARE_EVENT");
	item:SetRaiseEvents("SolarFlareEvent");			
	item:SetTutorialLevel(TutorialLevel.LEVEL_EXPERIENCED_PLAYER);
	item:SetIsEndOfChain(true);
	item:SetIsQueueable(true);
	item:SetShowPortrait(true);
	item:SetAdvisorMessage("LOC_TUTORIAL_SOLAR_FLARES");
	item:SetAdvisorAudio("Play_ADVISOR_LINE_FTUE_GENERAL_1");
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_CONTINUE",
		function( advisorInfo )
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
			LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
		end );
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_TELL_ME_MORE",
		function(advisorInfo)
			LuaEvents.OpenCivilopedia("CONCEPTS", "ENVIRONMENTAL_EFFECTS")
			LuaEvents.AdvisorPopup_ClearActive(advisorInfo)
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
		end);
	item:SetIsDoneFunction(
		function()
			return false;
		end );
	AddToListener("SolarFlareEvent", item);

	-- ===========================================================================		
	local item = TutorialItem:new("SOOTHSAYER_AVAILABLE");
	item:SetRaiseEvents("SoothsayerAvailable");			
	item:SetTutorialLevel(TutorialLevel.LEVEL_EXPERIENCED_PLAYER);
	item:SetIsEndOfChain(true);
	item:SetIsQueueable(true);
	item:SetShowPortrait(true);
	item:SetAdvisorMessage("LOC_TUTORIAL_SOOTHSAYERS");
	item:SetAdvisorAudio("Play_ADVISOR_LINE_FTUE_GENERAL_1");
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_CONTINUE",
		function( advisorInfo )
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
			LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
		end );
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_TELL_ME_MORE",
		function(advisorInfo)
			LuaEvents.OpenCivilopedia("UNITS", "UNIT_SOOTHSAYER")
			LuaEvents.AdvisorPopup_ClearActive(advisorInfo)
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
		end);
	item:SetIsDoneFunction(
		function()
			return false;
		end );
	AddToListener("SoothsayerAvailable", item);

	-- ===========================================================================		
	local item = TutorialItem:new("APOCALYPSE_BEGIN");
	item:SetRaiseEvents("ApocalypseBegin");			
	item:SetTutorialLevel(TutorialLevel.LEVEL_EXPERIENCED_PLAYER);
	item:SetIsEndOfChain(true);
	item:SetIsQueueable(true);
	item:SetShowPortrait(true);
	item:SetAdvisorMessage("LOC_TUTORIAL_APOCALYPSE");
	item:SetAdvisorAudio("Play_ADVISOR_LINE_FTUE_GENERAL_1");
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_CONTINUE",
		function( advisorInfo )
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
			LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
		end );
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_TELL_ME_MORE",
		function(advisorInfo)
			LuaEvents.OpenCivilopedia("CONCEPTS", "MEGADISASTERS")
			LuaEvents.AdvisorPopup_ClearActive(advisorInfo)
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
		end);
	item:SetIsDoneFunction(
		function()
			return false;
		end );
	AddToListener("ApocalypseBegin", item);

end
