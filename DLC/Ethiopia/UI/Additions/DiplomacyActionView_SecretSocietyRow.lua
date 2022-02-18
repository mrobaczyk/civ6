-- Copyright (c) Firaxis Games 2020

-- ===========================================================================
function Refresh(selectedPlayerID:number)

    local pSelectedPlayer:table = Players[selectedPlayerID];
    local pSelectedPlayerGovs:table = pSelectedPlayer:GetGovernors();

    local eSecretSociety:number = pSelectedPlayerGovs:GetSecretSociety();
    if eSecretSociety ~= -1 then
        local pLocalPlayer:table = Players[Game.GetLocalPlayer()];
        local pLocalPlayerGovs:table = pSelectedPlayer:GetGovernors();

        if pLocalPlayerGovs:IsAwareOfSecretSociety(eSecretSociety) then
            -- Known Secret Society
            local kSocietyDef:table = GameInfo.SecretSocieties[eSecretSociety];
			Controls.SecretSocietyIcon:SetText(kSocietyDef.IconString);
            Controls.SecretSocietyText:SetText(Locale.Lookup(kSocietyDef.Name));
            Controls.SecretSocietyText:SetToolTipString("");
        else
            -- Unknown Secret Society
			Controls.SecretSocietyIcon:SetText("");
            Controls.SecretSocietyText:SetText(Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_UNKNOWN_NAME"));
            Controls.SecretSocietyText:SetToolTipString(Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_UNKNOWN_DESCRIPTION"));
        end
    else
        -- No Secret Society
		Controls.SecretSocietyIcon:SetText("");
        Controls.SecretSocietyText:SetText(Locale.Lookup("LOC_SECRETSOCIETY_DIPLO_NONE_NAME"));
        Controls.SecretSocietyText:SetToolTipString("");
    end
end

-- ===========================================================================
function Initialize()
	-- Set this context to autosize
	ContextPtr:SetAutoSize(true);

	LuaEvents.DiploScene_RefreshOverviewRows.Add(Refresh);
end
Initialize();