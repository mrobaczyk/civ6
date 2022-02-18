-- ===========================================================================
--	CreateCorporationPopup for Monopolies & Corporations
-- ===========================================================================

include("PopupManager");


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local debugTest:boolean = false;		-- (false) when true run test on hotload
local RELOAD_CACHE_ID	:string = "CreateCorporationPopup";


-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_kPopupMgr			:table	 = ExclusivePopupManager:new("CreateCorporationPopupBase");
local m_lastShownEraIndex	:number = -1;
local m_isClosing			:boolean = false;
local m_eCurResourceType 	:number = -1;
local m_curResourceName		:string = nil;

-- ===========================================================================
--	Game Engine EVENT
-- ===========================================================================
function OnCorporationAdded( ePlayer:number, eResource:number, plotX:number, plotY:number )
	m_eCurResourceType = eResource;

	do
		for row in GameInfo.Resources() do
			if row.Index == eResource then
				resName = row.ResourceType;
				break;
			end
		end
	end

	m_curResourceName = resName;

	if resName ~= nil then
		Controls.ResIcon:SetIcon("ICON_MONOPOLIES_AND_CORPS_"..resName);
	end

	OnGenerate();

	-- we generate the name for all players, but don't show the popup for AI
	if ePlayer == Game.GetLocalPlayer() then
		StartCorporationShow();
	else
		-- don't want to do this for humans in multiplayer
		local pPlayer:table = Players[ePlayer];
		if pPlayer ~= nil and pPlayer:IsAI() then
			local corpName:string = Controls.NameEdit:GetText();
			local tParameters:table = {};

			tParameters[PlayerOperations.PARAM_PLAYER_ONE] = ePlayer;
			tParameters[PlayerOperations.PARAM_RESOURCE_TYPE] = eResource;
			tParameters[PlayerOperations.PARAM_CORPORATION_CUSTOM_NAME] = corpName;
			UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.NAME_CORPORATION, tParameters);
		end
	end
end

-- ===========================================================================
function StartCorporationShow()
	m_kPopupMgr:Lock( ContextPtr, PopupPriority.High );	
	m_isClosing = false;
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnShow()
end

-- ===========================================================================
function Resize()
	local screenX, screenY:number = UIManager:GetScreenSizeVal()
end

-- ===========================================================================
function Close()
	if not m_isClosing then
		m_isClosing = true;
		m_kPopupMgr:Unlock();
	end
end

-- ===========================================================================
function OnClose()
	Close();
end

-- ===========================================================================
function OnGenerate()
	local prefixes:table = {};
	local suffixes:table = {};

	if GameInfo.CorporationNames then
		do
			for row in GameInfo.CorporationNames() do
				if row.NameType == "PREFIX_ALL" then
					table.insert(prefixes, row.TextKey);
				else
					table.insert(suffixes, row.TextKey);
				end
			end
		end

		-- the name doesn't impact any gameplay, so it's OK to use math.random here
		local ourPrefix:string = prefixes[math.random(#prefixes)];
		local ourSuffix:string = suffixes[math.random(#suffixes)];
		if ourPrefix ~= nil and ourSuffix ~= nil and m_curResourceName ~= nil then
			Controls.NameEdit:SetText(Locale.Lookup(ourPrefix).." "..Locale.Lookup("LOC_"..resName.."_NAME").." "..Locale.Lookup(ourSuffix));
		end
	end
end

-- ===========================================================================
function OnConfirm()
	local corpName:string = Controls.NameEdit:GetText();
	local tParameters:table = {};

	tParameters[PlayerOperations.PARAM_PLAYER_ONE] = Game.GetLocalPlayer();	-- we can't be here if this isn't the local player
	tParameters[PlayerOperations.PARAM_RESOURCE_TYPE] = m_eCurResourceType;
	tParameters[PlayerOperations.PARAM_CORPORATION_CUSTOM_NAME] = corpName;
	UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.NAME_CORPORATION, tParameters);

	OnClose();
end

-- ===========================================================================
--	Input
--	UI Event Handler
-- ===========================================================================
function KeyHandler( key:number )
	if key == Keys.VK_ESCAPE then
		Close();
		return true;
	end
	return false;
end

function OnInputHandler( pInputStruct:table )
	local uiMsg = pInputStruct:GetMessageType();
	if (uiMsg == KeyEvents.KeyUp) then return KeyHandler( pInputStruct:GetKey() ); end;
	return false;
end 

-- ===========================================================================
--	Resize Handler
-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string )
  if type == SystemUpdateUI.ScreenResize then
	Resize();
  end
end

-- ===========================================================================
--	LUA Event
--	Set cached values back after a hotload.
-- ===========================================================================
function OnGameDebugReturn( context:string, contextTable:table )
	if context ~= RELOAD_CACHE_ID then
		return;
	end
	
	m_lastShownEraIndex = contextTable["m_lastShownEraIndex"];
	m_kPopupMgr.FromTable( contextTable["m_kPopupMgr"], ContextPtr );
	if (contextTable["isHidden"]==false) then
		StartCorporationShow()
	end
end


-- ===========================================================================
--	UI Event Handler
-- ===========================================================================
function OnInit( isReload:boolean )
	if isReload or debugTest then
		LuaEvents.GameDebug_GetValues(RELOAD_CACHE_ID);				
	end
end

-- ===========================================================================
--	UI Event Handler
-- ===========================================================================
function OnShutdown()
	if m_kPopupMgr:IsLocked() then								
		m_kPopupMgr:Unlock();
	end
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isHidden", ContextPtr:IsHidden() );
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "m_lastShownEraIndex", m_lastShownEraIndex );
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "m_kPopupMgr", m_kPopupMgr.ToTable() );	
end

-- ===========================================================================
function Initialize()
	ContextPtr:SetInputHandler( OnInputHandler, true );
	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetShutdown( OnShutdown );

	LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);

	Controls.CorpConfirmButton:RegisterCallback( Mouse.eLClick, OnConfirm );
	Controls.CorpConfirmButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.CorpGenerateButton:RegisterCallback( Mouse.eLClick, OnGenerate );
	Controls.CorpGenerateButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.NameEdit:RegisterCommitCallback( OnConfirm );

	Events.SystemUpdateUI.Add( OnUpdateUI );	
	Events.CorporationAdded.Add( OnCorporationAdded );
end
Initialize();