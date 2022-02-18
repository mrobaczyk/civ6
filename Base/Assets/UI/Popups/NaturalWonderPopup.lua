-- ===========================================================================
--	Popups when a Natural Wonder has been discovered
-- ===========================================================================

-- ===========================================================================
--	CONSTANTS / MEMBERS
-- ===========================================================================
local m_isWaitingToShowPopup:boolean = false;
local m_kQueuedPopups		:table	 = {};
local m_eCurrentFeature		:number  = -1;
local m_kCurrentPopup		:table	 = nil;
local ms_eventID					 = 0;

-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--	Closes the immediate popup, will raise more if queued.
-- ===========================================================================
function Close()

	UI.ClearTemporaryPlotVisibility("NaturalWonder");
	
	-- Dequeue popup from UI mananger (will re-queue if another is about to show).
	ShowNaturalWonderLens(false);
	-- Release our hold on the event
	ReleaseGameCoreEvent( ms_eventID );
	ms_eventID = 0;
	UIManager:DequeuePopup( ContextPtr );
	UI.PlaySound("Stop_Speech_NaturalWonders");
	local isNewOneSet = false;
	
	-- Stop the camera animation if it hasn't finished already
	if (m_kCurrentPopup ~= nil) then
		Events.StopAllCameraAnimations();
	end

	-- Find first entry in table, display that, then remove it from the internal queue
	for i, entry in ipairs(m_kQueuedPopups) do
		ShowPopup(entry);
		table.remove(m_kQueuedPopups, i);
		isNewOneSet = true;
		break;
	end

	if not isNewOneSet then
		m_isWaitingToShowPopup = false;	
		m_eCurrentFeature = -1;
		m_kCurrentPopup = nil;
		LuaEvents.NaturalWonderPopup_Closed();	-- Signal other systems (e.g., bulk show UI)
	end
		
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnClose()
	Close();
end


function ShowNaturalWonderLens(isShowing: boolean)
	if isShowing then
		if(UI.GetInterfaceMode() ~= InterfaceModeTypes.NATURAL_WONDER) then
			UI.SetInterfaceMode(InterfaceModeTypes.NATURAL_WONDER);	-- Enter mode
		end
	else		
		UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);		
	end
end

-- ===========================================================================
function ShowPopup( kData:table )
	UIManager:QueuePopup( ContextPtr, PopupPriority.Medium );

	local pPlot = Map.GetPlot(kData.plotx, kData.ploty);
	if pPlot ~= nil then
		local aPlots = pPlot:GetFeature():GetPlots();
		-- Just in case the local player can't see all the plots, temporarily reveal them on the app side
		-- This includes even single plot NWs, as the NW can be completely in mid-fog, if just the underlying map was revealed to the player.
		-- This happens with city state captital reveals, etc.
		UI.AddTemporaryPlotVisibility("NaturalWonder", aPlots, RevealedState.VISIBLE);
	end

	ShowNaturalWonderLens(true);
	m_isWaitingToShowPopup = true;
	m_eCurrentFeature = kData.Feature;
	m_kCurrentPopup = kData;
	
	UI.OnNaturalWonderRevealed(kData.plotx, kData.ploty);

	if(kData.QuoteAudio) then
		UI.PlaySound(kData.QuoteAudio);
	end

	Controls.WonderName:SetText( kData.Name );
	Controls.WonderQuoteContainer:SetHide( kData.Quote == nil );
	Controls.WonderIcon:SetIcon( "ICON_".. kData.TypeName);
	if kData.Quote ~= nil then
		Controls.WonderQuote:SetText( kData.Quote );
	end
	if kData.Description ~= nil then
		Controls.WonderIcon:SetToolTipString( kData.Description );
	end
	Controls.QuoteContainer:DoAutoSize();
end

-- ===========================================================================
--
-- ===========================================================================
function OnNaturalWonderRevealed( plotx:number, ploty:number, eFeature:number, isFirstToFind:boolean )
	local localPlayer = Game.GetLocalPlayer();	
	if (localPlayer < 0) then
		return;	-- autoplay
	end

	-- No wonder popups in multiplayer games.
	if(GameConfiguration.IsAnyMultiplayer()) then
		return;
	end
	
	UILens.SetActive("Default");

	-- Only human players and NO hotseat
	if Players[localPlayer]:IsHuman() and not GameConfiguration.IsHotseat() then
		local info:table = GameInfo.Features[eFeature];
		if info ~= nil then

			local quote :string = nil;
			if info.Quote ~= nil then
				quote = Locale.Lookup(info.Quote);
			end

			local description :string = nil;
			if info.Description ~= nil then
				description = Locale.Lookup(info.Description);
			end
			
			local kData:table = { 
				Feature		= eFeature,
				Name		= Locale.ToUpper(Locale.Lookup(info.Name)),
				Quote		= quote,
				QuoteAudio	= info.QuoteAudio,
				Description	= description,
				TypeName	= info.FeatureType,
				plotx		= plotx,
				ploty		= ploty
			}

			-- Add to queue if already showing a popup
			if not m_isWaitingToShowPopup then				
				ms_eventID = ReferenceCurrentGameCoreEvent();
				ShowPopup( kData );
				LuaEvents.NaturalWonderPopup_Shown();	-- Signal other systems (e.g., bulk hide UI)
			else		
			
				-- Prevent DUPES when bulk showing; only happen during force reveal?
				for _,kExistingData in ipairs(m_kQueuedPopups) do
					if kExistingData.Feature == eFeature then
						return;		-- Already have a popup for this feature queued then just leave.
					end
				end
				if m_eCurrentFeature ~= eFeature then
					table.insert(m_kQueuedPopups, kData);	
				end
			end
			
		end
	end
end

-- ===========================================================================
function OnLocalPlayerTurnEnd()
	if (not ContextPtr:IsHidden()) and GameConfiguration.IsHotseat() then
		OnClose();
	end
end

-- ===========================================================================
function OnCameraAnimationStopped(name : string)
	if (m_kCurrentPopup ~= nil) then
		UI.LookAtPlot(m_kCurrentPopup.plotx, m_kCurrentPopup.ploty, 0.0, 0.0, true);
	end
end

-- ===========================================================================
function OnCameraAnimationNotFound()
	if (m_kCurrentPopup ~= nil) then
		-- this will play if the animation doesnt exist
		UI.LookAtPlot(m_kCurrentPopup.plotx, m_kCurrentPopup.ploty);
	end
end

-- ===========================================================================
--	Native Input / ESC support
-- ===========================================================================
function KeyHandler( key:number )
    if key == Keys.VK_ESCAPE then
		Close();
		return true;
    end
    return false;
end
function OnInputHander( pInputStruct:table )
	local uiMsg :number = pInputStruct:GetMessageType();
	if (uiMsg == KeyEvents.KeyUp) then return KeyHandler( pInputStruct:GetKey() ); end;
	return false;
end

-- ===========================================================================
--	Initialize the context
-- ===========================================================================
function Initialize()

	ContextPtr:SetInputHandler( OnInputHander, true );

	Controls.Close:RegisterCallback(Mouse.eLClick, OnClose);
	Controls.WonderRevealedHeader:SetText( Locale.ToUpper( Locale.Lookup("LOC_UI_FEATURE_NATURAL_WONDER_DISCOVERY")) )
	
	Events.NaturalWonderRevealed.Add(OnNaturalWonderRevealed);
	Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );	

	Events.CameraAnimationStopped.Add( OnCameraAnimationStopped );
	Events.CameraAnimationNotFound.Add( OnCameraAnimationNotFound );
end
Initialize();