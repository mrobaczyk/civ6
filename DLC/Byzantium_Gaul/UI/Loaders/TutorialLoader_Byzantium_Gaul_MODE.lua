
-- ===========================================================================
--
--	Tutorial items related to Byzantium/Gaul Dramatic Ages MODE DLC
--
-- ===========================================================================

-- Add to tutorial loaders referenced by TutorialUIRoot
local TutorialLoader = {};
table.insert(g_TutorialLoaders, TutorialLoader);

-- ===========================================================================
function TutorialLoader:Initialize(TutorialCheck:ifunction)	
	
	if (GameCapabilities.HasCapability("CAPABILITY_DRAMATICAGES")) then
		-- Register game core events
		local iPlayerID : number = Game.GetLocalPlayer();
		if (iPlayerID < 0) then
			return;
		end

		local pPlayer = Players[iPlayerID];
	
		Events.PlayerTurnActivated.Add(function( playerID:number, isFirstTimeThisTurn:boolean )
			local localPlayerID = Game.GetLocalPlayer();
			if (playerID == localPlayerID and isFirstTimeThisTurn) then
				TutorialCheck("DramaticAgesModeBegin");
			end

		end);

		Events.PlayerAgeChanged.Add(function( playerID )
			local localPlayerID = Game.GetLocalPlayer();
			if (playerID == localPlayerID) then
				local gameEras = Game.GetEras();
				local currentEra = Game.GetEras():GetCurrentEra();
				if currentEra > 0 then
					if (gameEras:HasGoldenAge(localPlayerID)) then
						TutorialCheck("DramaticAgesFirstGoldenAgeEvent");
					elseif (gameEras:HasDarkAge(localPlayerID)) then
						TutorialCheck("DramaticAgesFirstDarkAgeEvent");
					end
				end
			end
		end);
	end
end

-- ===========================================================================
function TutorialLoader:CreateTutorialItems(AddToListener:ifunction)

	-- ===========================================================================		
	local item = TutorialItem:new("DRMATIC_AGES_MODE_BEGIN");
	item:SetRaiseEvents("DramaticAgesModeBegin");
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
	item:SetAdvisorMessage("LOC_TUTORIAL_FIRST_TIME_DRAMATIC_AGES");
	item:SetAdvisorAudio("Play_ADVISOR_LINE_FTUE_GENERAL_1");
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_CONTINUE",
		function( advisorInfo )
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
			LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
		end );
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_TELL_ME_MORE",
		function(advisorInfo)
			--LuaEvents.OpenCivilopedia("CONCEPTS", "MEGADISASTERS")
			LuaEvents.AdvisorPopup_ClearActive(advisorInfo)
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
		end);
	item:SetIsDoneFunction(
		function()
			return false;
		end );
	AddToListener("DramaticAgesModeBegin", item);

	-- ===========================================================================	
	local item = TutorialItem:new("DRAMATIC_AGES_FIRST_GOLDEN_AGE");
	item:SetRaiseEvents("DramaticAgesFirstGoldenAgeEvent");		
	item:SetTutorialLevel(TutorialLevel.LEVEL_EXPERIENCED_PLAYER);
	item:SetIsEndOfChain(true);
	item:SetIsQueueable(true);
	item:SetShowPortrait(true);
	item:SetAdvisorMessage("LOC_TUTORIAL_DRAMATIC_AGES_FIRST_GOLDEN_AGE");
	item:SetAdvisorAudio("Play_ADVISOR_LINE_FTUE_GENERAL_1");
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_CONTINUE",
		function( advisorInfo )
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
			LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
		end );
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_TELL_ME_MORE",
		function(advisorInfo)
			--LuaEvents.OpenCivilopedia("CONCEPTS", "ENVIRONMENTAL_EFFECTS")
			LuaEvents.AdvisorPopup_ClearActive(advisorInfo)
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
		end);
	item:SetIsDoneFunction(
		function()
			return false;
		end );
	AddToListener("DramaticAgesFirstGoldenAgeEvent", item);

	-- ===========================================================================	
	local item = TutorialItem:new("DRAMATIC_AGES_FIRST_DARK_AGE");
	item:SetRaiseEvents("DramaticAgesFirstDarkAgeEvent");		
	item:SetTutorialLevel(TutorialLevel.LEVEL_EXPERIENCED_PLAYER);
	item:SetIsEndOfChain(true);
	item:SetIsQueueable(true);
	item:SetShowPortrait(true);
	item:SetAdvisorMessage("LOC_TUTORIAL_DRAMATIC_AGES_FIRST_DARK_AGE");
	item:SetAdvisorAudio("Play_ADVISOR_LINE_FTUE_GENERAL_1");
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_CONTINUE",
		function( advisorInfo )
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
			LuaEvents.AdvisorPopup_ClearActive( advisorInfo );
		end );
	item:AddAdvisorButton("LOC_ADVISOR_BUTTON_TELL_ME_MORE",
		function(advisorInfo)
			--LuaEvents.OpenCivilopedia("CONCEPTS", "ENVIRONMENTAL_EFFECTS")
			LuaEvents.AdvisorPopup_ClearActive(advisorInfo)
			UI.PlaySound("Stop_ADVISOR_LINE_FTUE_GENERAL_1");
		end);
	item:SetIsDoneFunction(
		function()
			return false;
		end );
	AddToListener("DramaticAgesFirstDarkAgeEvent", item);

end
