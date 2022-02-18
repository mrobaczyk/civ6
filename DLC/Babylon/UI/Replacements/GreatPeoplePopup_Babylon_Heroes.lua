--	Copyright 2020 (c) Firaxis Games

-- This file is being included into the base GreatPeoplePopup file using the wildcard include setup in GreatPeoplePopup.lua
-- Refer to the bottom of GreatPeoplePopup.lua to see how that's happening
-- DO NOT include any GreatPeoplePopup files here or it will cause problems
-- include("GreatPeoplePopup");

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
local BASE_AddCustomTabs = AddCustomTabs;
local BASE_ResetGreatPeopleInstances = ResetGreatPeopleInstances;
local BASE_LateInitialize = LateInitialize;

-- ===========================================================================
--	MEMBERS
-- ===========================================================================

local m_pGreatPeopleHeroPanelContext = ContextPtr:LoadNewContext("GreatPeopleHeroPanel", Controls.PeopleScroller);

local m_HeroStackSizeX:number = 0;

local m_uiHeroesTabInst:table = nil;

-- =======================================================================================
function AddCustomTabs()
	BASE_AddCustomTabs();
	m_uiHeroesTabInst = AddTabInstance("LOC_GREAT_PEOPLE_TAB_HEROES", OnHeroesClick);
end

-- ===========================================================================
function ResetGreatPeopleInstances()
	BASE_ResetGreatPeopleInstances();
	LuaEvents.GreatPeoplePopup_ClearHeroes();
end

-- ===========================================================================
function OnHeroesClick( uiSelectedButton:table )
	ResetTabButtons();
	SetTabButtonsSelected(uiSelectedButton);

	ResetGreatPeopleInstances();	
	Controls.PeopleScroller:SetHide(false);
	Controls.RecruitedArea:SetHide(true);

	Refresh(RefreshHeroesPanel);
end

-- ===========================================================================
function RefreshHeroesPanel()
	LuaEvents.GreatPeoplePopup_RefreshHeroes();
	ResizeHeroPaneling();
end

-- =======================================================================================
function ResizeHeroPaneling( heroStackSizeX )
	-- Ignore if size is zero
	-- This means it's been cleared and another tab is opening which will handle the resizing
	if m_HeroStackSizeX <= 0 then
		return;
	end

	Controls.PeopleScroller:CalculateSize();

	local screenWidth = math.max(m_HeroStackSizeX, 1024);
	Controls.WoodPaneling:SetSizeX( screenWidth );

	-- Clamp overall popup size to not be larger than contents (overspills in 4k and eyefinitiy rigs.)
	local screenX,_			:number = UIManager:GetScreenSizeVal();
	if screenWidth > screenX then	
		screenWidth = screenX;
	end	
	
	Controls.PopupContainer:SetSizeX( screenWidth );
	Controls.ModalFrame:SetSizeX( screenWidth );	
end

-- =======================================================================================
function OnGreatPeopleHeroPanel_SizeChanged( heroStackSizeX:number )
	m_HeroStackSizeX = heroStackSizeX;
	ResizeHeroPaneling();
end

-- =======================================================================================
function OnGreatPeopleHeroPanel_Close()
	OnClose();
end

-- =======================================================================================
function OnGreatPeopleHeroPanel_Show()
	Open();
	SelectTab(m_uiHeroesTabInst.Button);
end

-- =======================================================================================
function LateInitialize()
	BASE_LateInitialize();

	LuaEvents.GreatPeopleHeroPanel_Close.Add(OnGreatPeopleHeroPanel_Close);
	LuaEvents.GreatPeopleHeroPanel_SizeChanged.Add(OnGreatPeopleHeroPanel_SizeChanged);
	LuaEvents.GreatPeopleHeroPanel_Show.Add(OnGreatPeopleHeroPanel_Show);
end