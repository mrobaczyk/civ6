
CREATE TABLE 'Queries' (
	'QueryId' TEXT NOT NULL,
	'SQL' TEXT NOT NULL,
 	PRIMARY KEY('QueryId')
);

CREATE TABLE 'QueryParameters'(
	'QueryId' TEXT NOT NULL,
	'Index' INTEGER NOT NULL,
	'ConfigurationGroup' TEXT NOT NULL,
	'ConfigurationId' TEXT NOT NULL,
	PRIMARY KEY('QueryId', 'Index'),
	FOREIGN KEY('QueryId') REFERENCES 'Queries'('QueryId')
);

CREATE TABLE 'ParameterQueries'(
	'ParameterQueryId' TEXT NOT NULL,
	'QueryId' TEXT NOT NULL,
	'ParameterIdField' TEXT NOT NULL DEFAULT 'ParameterId',
	'NameField' TEXT NOT NULL DEFAULT 'Name',
	'DescriptionField' TEXT NOT NULL DEFAULT 'Description',
	'DomainField' TEXT NOT NULL DEFAULT 'Domain',
	'HashField' TEXT NOT NULL DEFAULT 'Hash',
	'DefaultValueField' TEXT NOT NULL DEFAULT 'DefaultValue',
	'ConfigurationGroupField' TEXT NOT NULL DEFAULT 'ConfigurationGroup',
	'ConfigurationIdField' TEXT NOT NULL DEFAULT 'ConfigurationId',
	'DomainConfigurationIdField' TEXT NOT NULL DEFAULT 'DomainConfigurationId',
	'DomainValuesConfigurationIdField' TEXT NOT NULL DEFAULT 'DomainValuesConfigurationId',
	'ValueNameConfigurationIdField' TEXT NOT NULL DEFAULT 'ValueNameConfigurationId',
	'ValueDomainConfigurationIdField' TEXT NOT NULL DEFAULT 'ValueDomainConfigurationId',
	'GroupField' TEXT NOT NULL DEFAULT 'GroupId',
	'VisibleField' TEXT NOT NULL DEFAULT 'Visible',
	'ReadOnlyField' TEXT NOT NULL DEFAULT 'ReadOnly',
	'SupportsSinglePlayerField' TEXT NOT NULL DEFAULT 'SupportsSinglePlayer',
	'SupportsLANMultiplayerField' TEXT NOT NULL DEFAULT 'SupportsLANMultiplayer',
	'SupportsInternetMultiplayerField' TEXT NOT NULL DEFAULT 'SupportsInternetMultiplayer',
	'SupportsHotSeatField' TEXT NOT NULL DEFAULT 'SupportsHotSeat',
	'ChangeableAfterGameStartField' TEXT NOT NULL DEFAULT 'ChangeableAfterGameStart',
	'SortIndexField' TEXT NOT NULL DEFAULT 'SortIndex',
	PRIMARY KEY('ParameterQueryId'),
	FOREIGN KEY('QueryId') REFERENCES 'Queries'('QueryId')
);

CREATE TABLE 'ParameterQueryCriteria'(
	'ParameterQueryId' TEXT NOT NULL,
	'ConfigurationGroup' TEXT NOT NULL,
	'ConfigurationId' TEXT NOT NULL,
	'Operator' TEXT NOT NULL DEFAULT 'Equals',
	'ConfigurationValue'
);

CREATE TABLE 'ParameterQueryDependencies'(
	'ParameterQueryId' TEXT NOT NULL,
	'ConfigurationGroup' TEXT NOT NULL,
	'ConfigurationId' TEXT NOT NULL,
	'Operator' TEXT NOT NULL DEFAULT 'Equals',
	'ConfigurationValue'
);

CREATE TABLE 'Parameters'(
	'Key1' TEXT,
	'Key2' TEXT,
	'ParameterId' TEXT NOT NULL,								-- A semi-unique identifier of the parameter.  Semi-unique because it depends on Key1 and Key2.
	'Name' TEXT NOT NULL,										-- The name of the parameter.
	'Description' TEXT,											-- The description of the parameter (used for UI purposes, typically a tooltip).
	'Domain' TEXT NOT NULL,										-- The domain of values to use
	'Hash' BOOLEAN NOT NULL DEFAULT 0,							-- Whether or not to hash the value when writing to the config.  Only applies to the value, not other config entries.
	'DefaultValue',												-- The default value to use, null allowed.
	'ConfigurationGroup' TEXT NOT NULL,							-- The map used to write all of the configuration values (e.g Game, Map, Player[id])
	'ConfigurationId' TEXT NOT NULL,							-- The key used to write out the value of the parameter.
	'DomainConfigurationId' TEXT,								-- [Optional] Write out the parameter's domain to the configuration.
	'DomainValuesConfigurationId' TEXT,							-- [Optional] Write out a comma delimited list of all values (including original domain).  This only applies to name-value domains.					
	'ValueNameConfigurationId' TEXT,							-- [Optional] Write out the name of the value as a localization bundle.	This only applies to name-value domains.
	'ValueDomainConfigurationId' TEXT,							-- [Optional] Write out the original domain of the selected value. (This may not match the parameter's domain).
	'GroupId' TEXT NOT NULL,									-- Used by the UI to determine how to triage the parameter.
	'Visible' BOOLEAN NOT NULL DEFAULT 1,						-- Used by the UI to determine whether the parameter should be shown.  Parameter dependencies may override this.
	'ReadOnly' BOOLEAN NOT NULL DEFAULT 0,						-- Used by the UI to determine whether the parameter should be disabled. Parameter criteria may override this.
	'SupportsSinglePlayer' BOOLEAN NOT NULL DEFAULT 1,
	'SupportsLANMultiplayer' BOOLEAN NOT NULL DEFAULT 1,
	'SupportsInternetMultiplayer' BOOLEAN NOT NULL DEFAULT 1,
	'SupportsHotSeat' BOOLEAN NOT NULL DEFAULT 1,
	'ChangeableAfterGameStart' BOOLEAN NOT NULL DEFAULT 0,
	'SortIndex' INTEGER NOT NULL DEFAULT 100
);

CREATE TABLE 'ParameterCriteria'(
	'ParameterId' TEXT NOT NULL,
	'ConfigurationGroup' TEXT NOT NULL,
	'ConfigurationId' TEXT NOT NULL,
	'Operator' TEXT NOT NULL DEFAULT 'Equals',
	'ConfigurationValue'
);

CREATE TABLE 'ParameterDependencies'(
	'ParameterId' TEXT NOT NULL,
	'ConfigurationGroup' TEXT NOT NULL,
	'ConfigurationId' TEXT NOT NULL,
	'Operator' TEXT NOT NULL DEFAULT 'Equals',
	'ConfigurationValue'
);

CREATE TABLE 'DomainValueQueries'(
	'DomainValueQueryId' TEXT NOT NULL,
	'QueryId' TEXT NOT NULL,
	'DomainField' TEXT NOT NULL DEFAULT 'Domain',
	'ValueField' TEXT NOT NULL DEFAULT 'Value',
	'NameField' TEXT NOT NULL DEFAULT 'Name',
	'DescriptionField' TEXT NOT NULL DEFAULT 'Description',
	'SortIndexField' TEXT NOT NULL DEFAULT 'SortIndex',
	'Set' TEXT NOT NULL DEFAULT 'union'
);

CREATE TABLE 'DomainValues'(
	'Key1' TEXT,
	'Key2' TEXT,
	'Domain' TEXT NOT NULL,
	'Value' NOT NULL,
	'Name' TEXT NOT NULL,
	'Description' TEXT,
	'SortIndex' INTEGER NOT NULL DEFAULT 100,
	PRIMARY KEY('Key1','Key2','Domain','Value')
);

-- Indirect method of populating recursive configuration updates.
CREATE TABLE 'ConfigurationUpdateQueries'(
	'QueryId' TEXT NOT NULL,
	'SourceGroupField' TEXT NOT NULL DEFAULT 'SourceGroup',
	'SourceIdField' TEXT NOT NULL DEFAULT 'SourceId',
	'SourceValueField' TEXT NOT NULL DEFAULT 'SourceValue',
	'TargetGroupField' TEXT NOT NULL DEFAULT 'TargetGroup',
	'TargetIdField' TEXT NOT NULL DEFAULT 'TargetId',
	'TargetValueField' TEXT NOT NULL DEFAULT 'TargetValue',
	'HashField' TEXT NOT NULL DEFAULT 'Hash'
);

-- When a setup parameter writes to the configuration..
-- Recursively match to the source rows and write the target values.
CREATE TABLE 'ConfigurationUpdates'(
	'SourceGroup' TEXT NOT NULL,
	'SourceId' TEXT NOT NULL,
	'SourceValue' NOT NULL,
	'TargetGroup' TEXT NOT NULL,
	'TargetId' TEXT NOT NULL,
	'TargetValue',
	'Hash' BOOLEAN NOT NULL DEFAULT 0
);
