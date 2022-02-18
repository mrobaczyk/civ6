
-- Game Summary Schema
pragma user_version(5);

-- This table contains statements to assist with migrating data during a database upgrade.
-- @SQL is the statement to run.
-- @MinVersion is the minimal old database version to run the SQL.
-- @MaxVersion is the maximum old database version to run the SQL.
-- @SortIndex is the column used to sort the statements.
CREATE TABLE Migrations(
	'SQL' TEXT NOT NULL,
	'MinVersion' INTEGER NOT NULL,
	'MaxVersion' INTEGER NOT NULL,
	'SortIndex' INTEGER NOT NULL DEFAULT 0
);

-- Root table specifying rulesets.
CREATE TABLE 'Rulesets' (
	'Ruleset' TEXT NOT NULL PRIMARY KEY
);

-- List of types for a given ruleset.
CREATE TABLE 'RulesetTypes' (
	'Ruleset' TEXT NOT NULL,
	'Type' TEXT NOT NULL,
	'Kind' TEXT NOT NULL,
	'Name' TEXT NOT NULL,
	'Icon' TEXT,
	PRIMARY KEY('Ruleset','Type'),
	FOREIGN KEY('Ruleset') REFERENCES 'Rulesets'('Ruleset') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Root table specifying games.
CREATE TABLE 'Games' (
	'GameId'	INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
	'Ruleset'	TEXT NOT NULL,
	'GameMode'	INTEGER,
	'TurnCount'	INTEGER NOT NULL,
	'GameSpeedType'	TEXT NOT NULL,
	'MapSizeType'	TEXT NOT NULL,
	'Map'	TEXT NOT NULL,
	'StartEraType' TEXT NOT NULL,
	'StartTurn'	INTEGER NOT NULL DEFAULT 1,
	'VictorTeamId'	INTEGER,
	'VictoryType' TEXT,
	'LastPlayed'	INTEGER NOT NULL,
	FOREIGN KEY('Ruleset') REFERENCES 'Rulesets'('Ruleset') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Extended data for 'Player' game objects.
CREATE TABLE 'GamePlayers' (
	'PlayerObjectId'	INTEGER NOT NULL,
	'IsLocal'	BOOLEAN NOT NULL DEFAULT 0,
	'IsAI'	BOOLEAN NOT NULL DEFAULT 0,
	'IsMajor' BOOLEAN NOT NULL DEFAULT 1,
	'LeaderType'	TEXT NOT NULL,
	'LeaderName'	TEXT,
	'CivilizationType' TEXT,
	'CivilizationName'	TEXT,
	'DifficultyType'	TEXT,
	'Score'	NUMERIC NOT NULL DEFAULT 0,
	'PlayerId'	INTEGER NOT NULL,
	'TeamId' INTEGER NOT NULL,
	PRIMARY KEY('PlayerObjectId'),
	FOREIGN KEY('PlayerObjectId') REFERENCES 'GameObjects'('ObjectId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Referenced game objects.
-- Only the game id, kind, and name are required.
-- Everything else is used to define the object being referenced.
CREATE TABLE 'GameObjects' (
	'ObjectId'	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	'GameId'	INTEGER NOT NULL,
	'PlayerObjectId'	INTEGER,
	'Type'	TEXT NOT NULL,
	'Name'	TEXT,
	'PlotIndex'	INTEGER,
	'ExtraData' TEXT,
	'Icon'	TEXT,
	FOREIGN KEY('GameId') REFERENCES 'Games'('GameId') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY('PlayerObjectId') REFERENCES 'GamePlayers'('PlayerObjectId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Statistics indexed by ruleset rather than a specific game object.
CREATE TABLE 'RulesetDataPointValues' (
	'DataPoint'	TEXT NOT NULL,
	'Ruleset'	TEXT NOT NULL,
	'ValueObjectId'	INTEGER,
	'ValueType'	TEXT,
	'ValueString'	TEXT,
	'ValueNumeric'	NUMERIC,
	FOREIGN KEY('Ruleset') REFERENCES 'Rulesets'('Ruleset') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY('ValueObjectId') REFERENCES 'GameObjects'('ObjectId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Statistics indexed by specific games.
CREATE TABLE 'GameDataPointValues' (
	'DataPoint'	TEXT NOT NULL,
	'GameId'	INTEGER NOT NULL,
	'ValueObjectId'	INTEGER,
	'ValueType' TEXT,
	'ValueString'	TEXT,
	'ValueNumeric'	NUMERIC,
	FOREIGN KEY('GameId') REFERENCES 'Games'('GameId') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY('ValueObjectId') REFERENCES 'GameObjects'('ObjectId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Statistics indexed by specific game objects.
CREATE TABLE 'ObjectDataPointValues' (
	'DataPoint'	TEXT NOT NULL,
	'ObjectId'	INTEGER NOT NULL,
	'ValueObjectId'	INTEGER,
	'ValueType' TEXT,
	'ValueString'	TEXT,
	'ValueNumeric'	NUMERIC,	
	FOREIGN KEY('ObjectId') REFERENCES 'GameObjects'('ObjectId') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY('ValueObjectId') REFERENCES 'GameObjects'('ObjectId') ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE 'DataSets' (
	'DataSetId' INTEGER PRIMARY KEY AUTOINCREMENT,
	'DataSet'	TEXT NOT NULL,
	'Ruleset' TEXT,
	'GameId'	INTEGER,
	'ObjectId'	INTEGER,
	'Type' TEXT,
	FOREIGN KEY('Ruleset') REFERENCES 'Rulesets'('Ruleset') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY('GameId') REFERENCES 'Games'('GameId') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY('ObjectId') REFERENCES 'GameObjects'('ObjectId') ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE 'DataSetValues' (
	'DataSetId'	INTEGER NOT NULL,
	'X'	NUMERIC NOT NULL,
	'Y'	NUMERIC NOT NULL,
	PRIMARY KEY('DataSetId','X'),
	FOREIGN KEY('DataSetId') REFERENCES 'DataSets'('DataSetId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Additional Indices for Performance
CREATE INDEX GameDataPointValues_DataPointGameId on GameDataPointValues(DataPoint, GameId);
CREATE INDEX GameObjects_GameId on GameObjects(GameId);
CREATE INDEX ObjectDataPointValues_DataPointObjectId on ObjectDataPointValues(DataPoint, ObjectId);
CREATE INDEX RulesetDataPointValues_DataPointRuleset on RulesetDataPointValues(DataPoint, Ruleset);


-- Migrate Data from Version 3 to 5 (No changes, just copy)
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(3, 4, "INSERT INTO Rulesets SELECT * From old.Rulesets");
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(3, 4, "INSERT INTO RulesetTypes SELECT * From old.RulesetTypes");
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(3, 4, "INSERT INTO GamePlayers SELECT * From old.GamePlayers");
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(3, 4, "INSERT INTO GameObjects SELECT * From old.GameObjects");
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(3, 4, "INSERT INTO RulesetDataPointValues SELECT * From old.RulesetDataPointValues");
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(3, 4, "INSERT INTO GameDataPointValues SELECT * From old.GameDataPointValues");
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(3, 4, "INSERT INTO ObjectDataPointValues SELECT * From old.ObjectDataPointValues");
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(3, 4, "INSERT INTO DataSets SELECT * From old.DataSets");
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(3, 4, "INSERT INTO DataSetValues SELECT * From old.DataSetValues");

-- Migrate Data from Version 3 to 5 (Added Start Game Turn, Game Mode)
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(3, 3, "INSERT INTO Games(GameId, Ruleset, TurnCount, GameSpeedType, MapSizeType, Map, StartEraType, StartTurn, VictorTeamId, VictoryType, LastPlayed) SELECT GameId, Ruleset, TurnCount, GameSpeedType, MapSizeType, Map, StartEraType, -1, VictorTeamId, VictoryType, LastPlayed from old.Games");

-- Migrate Data from Version 4 to 5 (Added Game Mode)
INSERT INTO Migrations(MinVersion, MaxVersion, 'SQL') VALUES(4, 4, "INSERT INTO Games(GameId, Ruleset, TurnCount, GameSpeedType, MapSizeType, Map, StartEraType, StartTurn, VictorTeamId, VictoryType, LastPlayed) SELECT GameId, Ruleset, TurnCount, GameSpeedType, MapSizeType, Map, StartEraType, StartTurn, VictorTeamId, VictoryType, LastPlayed from old.Games");