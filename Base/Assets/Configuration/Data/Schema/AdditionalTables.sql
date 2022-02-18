-- Additional Configuration Tables.
-- These are tables that are not directly used by the configuration logic
-- But are referenced in queries.
-- These tables are intended to make it easier to supply additional values or
-- restrict domains without significant SQL work.
CREATE TABLE 'Defeats'(
	'Domain' TEXT NOT NULL DEFAULT 'StandardDefeats',
	'DefeatType' TEXT NOT NULL,
	'Name' TEXT NOT NULL,
	'Description' TEXT NOT NULL,
	'Visible' BOOLEAN NOT NULL DEFAULT 1,
	'ReadOnly' TEXT NOT NULL DEFAULT 0
);

CREATE TABLE 'Difficulties' (
	'Domain' TEXT NOT NULL DEFAULT 'StandardDifficulties',
	'DifficultyType' TEXT NOT NULL,
	'Name' TEXT NOT NULL,
	'SortIndex' INTEGER NOT NULL,
	PRIMARY KEY('Domain', 'DifficultyType')
);

CREATE TABLE 'Eras' (
	'Domain' TEXT NOT NULL DEFAULT 'StandardEras',
	'EraType' TEXT NOT NULL,
	'Name' TEXT NOT NULL,
	'Description' TEXT NOT NULL,
	'SortIndex' INTEGER NOT NULL,
	PRIMARY KEY('Domain', 'EraType')
);

CREATE TABLE 'GameSpeeds' (
	'Domain' TEXT NOT NULL DEFAULT 'StandardGameSpeeds',
	'GameSpeedType' TEXT NOT NULL,
	'Name' TEXT,
	'Description' TEXT,
	'SortIndex' INTEGER NOT NULL,
	PRIMARY KEY('Domain', 'GameSpeedType')
);

CREATE TABLE 'Maps' (
	'Domain' TEXT NOT NULL DEFAULT 'StandardMaps',
	'PackageId' TEXT,
	'File' TEXT NOT NULL,
	'Name' TEXT NOT NULL,
	'Description' TEXT,
	'WorldBuilderOnly' BOOLEAN NOT NULL DEFAULT 0,
	'SortIndex' INTEGER NOT NULL DEFAULT 10,
	PRIMARY KEY ('Domain', 'PackageId', 'File')
);

CREATE TABLE 'MapSizes' (
	'Domain' TEXT NOT NULL DEFAULT 'StandardMapSizes',
	'MapSizeType' TEXT NOT NULL,
	'Name' TEXT NOT NULL,
	'Description' TEXT,
	'MinPlayers' INTEGER NOT NULL DEFAULT 2,
	'MaxPlayers' INTEGER NOT NULL DEFAULT 2,
	'DefaultPlayers' INTEGER NOT NULL DEFAULT 2,
	'MinCityStates' INTEGER NOT NULL DEFAULT 0,
	'MaxCityStates' INTEGER NOT NULL DEFAULT 0,
	'DefaultCityStates' INTEGER NOT NULL DEFAULT 0,
	'SortIndex' INTEGER NOT NULL,
	PRIMARY KEY('Domain','MapSizeType')
);

CREATE TABLE 'Rulesets' (
	'RulesetType' TEXT NOT NULL,
 	'Name' TEXT NOT NULL,
	'Description' TEXT,
	'DefeatDomain' TEXT NOT NULL DEFAULT 'StandardDefeats',
	'VictoryDomain' TEXT NOT NULL DEFAULT 'StandardVictories',
	'MaxTurns' INTEGER,
	'SupportsSinglePlayer' BOOLEAN NOT NULL DEFAULT 1,
	'SupportsMultiPlayer' BOOLEAN NOT NULL DEFAULT 1,
	PRIMARY KEY('RulesetType')
);

CREATE TABLE 'Players' (
	'Domain' TEXT DEFAULT 'StandardPlayers',
	'CivilizationType' TEXT NOT NULL,
	'LeaderType' TEXT NOT NULL,
	'LeaderName' TEXT NOT NULL,
	'LeaderIcon' TEXT NOT NULL,
	'CivilizationName' TEXT NOT NULL,
	'CivilizationIcon' TEXT NOT NULL,
	'LeaderAbilityName' TEXT NOT NULL,
	'LeaderAbilityDescription' TEXT NOT NULL,
	'LeaderAbilityIcon' TEXT NOT NULL,
	'CivilizationAbilityName' TEXT NOT NULL,
	'CivilizationAbilityDescription' TEXT NOT NULL,
	'CivilizationAbilityIcon' TEXT NOT NULL,
	'PackageId' TEXT,
	PRIMARY KEY('Domain', 'CivilizationType', 'LeaderType')
);

CREATE TABLE 'PlayerItems' (
	'Domain' TEXT DEFAULT 'StandardPlayers',
	'CivilizationType' TEXT NOT NULL,
	'LeaderType' TEXT NOT NULL,
	'Type' TEXT NOT NULL,
	'Name' TEXT NOT NULL,
	'Description' TEXT NOT NULL,
	'Icon' TEXT NOT NULL,
	'SortIndex' INTEGER DEFAULT 0,
	PRIMARY KEY('Domain', 'CivilizationType', 'LeaderType', 'Type')
);

CREATE TABLE 'TurnTimers' (
	'Domain' TEXT NOT NULL DEFAULT 'StandardTurnTimers',
	'TurnTimerType' TEXT NOT NULL,
	'Name' TEXT NOT NULL,
	'Description' TEXT NOT NULL,
	'SortIndex' INTEGER NOT NULL DEFAULT 100
);

CREATE TABLE 'TurnPhases' (
	'Domain' TEXT NOT NULL DEFAULT 'StandardTurnPhases',
	'TurnPhaseType' TEXT NOT NULL,
	'Name' TEXT NOT NULL,
	'Description' TEXT NOT NULL,
	'SortIndex' INTEGER NOT NULL DEFAULT 100
);

CREATE TABLE 'Victories'(
	'Domain' TEXT NOT NULL DEFAULT 'StandardVictories',
	'VictoryType' TEXT NOT NULL,
	'Name' TEXT NOT NULL,
	'Description' TEXT NOT NULL,
	'Visible' BOOLEAN NOT NULL DEFAULT 1,
	'ReadOnly' BOOLEAN NOT NULL DEFAULT 0
);

-- Rulesets are pretty much the only thing which replaces domains.
CREATE TABLE 'RulesetDomainOverrides'(
	'Ruleset' TEXT NOT NULL,			-- The ruleset type.
	'ParameterId' TEXT NOT NULL,	-- The parameterId to replace the domain.
	'Domain' TEXT NOT NULL,				-- The new domain.  This is a REPLACEMENT not a Union.
	PRIMARY KEY('Ruleset', 'ParameterId')
);

-- These tables are meant to restrict domains, rather than replace them.
-- Restriction is done via set intersecting.
-- Restrict parameter values based on what map is selected.
CREATE TABLE 'MapSupportedValues'(
	'Map' TEXT NOT NULL,					-- The primary key of Maps.
	'PlayerId' INTEGER,						-- Optional: The player slot.
	'Domain' TEXT NOT NULL,				-- The domain of the value.
	'Value' TEXT NOT NULL					-- The domain value to intersect with.
);

CREATE TABLE 'RulesetSupportedValues'(
	'Ruleset' TEXT NOT NULL,			-- The primary key of Maps.
	'PlayerId' INTEGER,						-- Optional: The player slot.
	'Domain' TEXT NOT NULL,				-- The domain of the value.
	'Value' TEXT NOT NULL					-- The domain value to intersect with.
);

CREATE TABLE 'RulesetUnSupportedValues'(
	'Ruleset' TEXT NOT NULL,			-- The primary key of Maps.
	'PlayerId' INTEGER,						-- Optional: The player slot.
	'Domain' TEXT NOT NULL,				-- The domain of the value.
	'Value' TEXT NOT NULL					-- The domain value to intersect with.
);


