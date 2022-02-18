-- Modding Framework Schema
-- 
-- Revision History
-- Version 13:
-- * Added UpdateARX component type.
-- Version 12: 
-- * Removed SettingComponents table.
-- * Modified stored procedures to order by priority in descending order.
-- Version 11:
-- * Added UpdateAudio component type.
-- Version 10:
-- * Added LocalizedText setting and component types.
-- Version 9:
-- * Added GameplayScripts, ImportFiles, and UserInterface component types.
-- Version 8:
-- * Removed Component and Setting type constraints.
-- Version 7:
-- * Add ModArt Component type.
-- Version 6:
-- * ComponentTypes and SettingTypes now use hashed identifiers instead of enumerations.
-- Version 5:
-- * Renamed Settings.SettingsId to Settings.SettingId.
-- * Added StoredProcedures table with many procedures used by the game.
-- Version 4:
-- * Brought Version back (integer for now, SemVer 2.0 in a future update).
-- * Removed BuildId.
-- * Removed SteamWorkshop tables (this info is stored in-memory now)."
-- Version 3:
-- * Removed CRC32 from ModFiles."
-- * Removed Version from Mods."
-- * Added BuildId in Mods."
-- Version 2:
--	* Added SettingComponents 
--	* Fixed order of dropped tables during cleanup.
-- Version 1:
--	* First pass

-- Wipe Database
DROP TABLE IF EXISTS SteamWorkshopMods;
DROP TABLE IF EXISTS SteamWorkshopTemporarySubscriptions;
DROP TABLE IF EXISTS SteamWorkshopDetails;
DROP TABLE IF EXISTS SteamWorkshopSubscriptions;
DROP TABLE IF EXISTS LocalizedText;
DROP TABLE IF EXISTS ComponentRelationships;
DROP TABLE IF EXISTS ModRelationships;
DROP TABLE IF EXISTS SettingProperties;
DROP TABLE IF EXISTS ComponentProperties;
DROP TABLE IF EXISTS ModProperties;
DROP TABLE IF EXISTS SettingFiles;
DROP TABLE IF EXISTS ComponentFiles;
DROP TABLE IF EXISTS ModFiles;
DROP TABLE IF EXISTS SettingComponents;
DROP TABLE IF EXISTS Settings;
DROP TABLE IF EXISTS Components;
DROP TABLE IF EXISTS Mods;
DROP TABLE IF EXISTS ComponentTypes;
DROP TABLE IF EXISTS ExclusivityTypes;
DROP TABLE IF EXISTS RelationshipTypes;
DROP TABLE IF EXISTS SettingTypes;
DROP TABLE IF EXISTS SystemSettings;
DROP TABLE IF EXISTS ScannedFiles;
DROP TABLE IF EXISTS StoredProcedures;

-- Generate Schema
-- This table represents the enumerated values of mod exclusivity.
CREATE TABLE ExclusivityTypes(
	'Name' TEXT PRIMARY KEY NOT NULL, 
	'Value' INTEGER NOT NULL
);

-- This table represents the enumerated values of relationship types.
CREATE TABLE RelationshipTypes(
	'Name' TEXT PRIMARY KEY NOT NULL, 
	'Value' INTEGER NOT NULL
);

-- This table represents the enumerated values of component types.
CREATE TABLE ComponentTypes(
	'Name' TEXT PRIMARY KEY NOT NULL,
	'Value' INTEGER UNIQUE
);

-- This table represents the enumerated values of settings types.
CREATE TABLE SettingTypes(
	'Name' TEXT PRIMARY KEY NOT NULL,
	'Value' INTEGER UNIQUE
);

-- Name/Value pairs representing framework settings.
CREATE TABLE SystemSettings(
	'Name' TEXT PRIMARY KEY NOT NULL, 
	'Value' TEXT
);

-- A table containing all of the files 'discovered' by the modding framework.
-- A locally unique identifier representing the file.
-- @ScannedFileRowId is the locally unique identifier to the file.
-- @Path is the path to the file.
-- @LastWriteTime represents the time stamp the file was written.  Used to invalidate mods and other data.
CREATE TABLE ScannedFiles(
	'ScannedFileRowId' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL ,
	'Path' TEXT UNIQUE, 
	'LastWriteTime' INTEGER NOT NULL
);

-- Primary table of all discovered mods
-- @ModRowId is a locally unique identifier representing a discovered mod.
-- @FileId is a reference to the .modinfo file discovered in ScannedFiles.
-- @ModId is a globally unique identifier representing the mod.
-- @Version is an integer value > 0.  Values of 0 or less are considered invalid.
-- @Exclusivity represents the mod's exclusivity.
-- @Enabled determines whether the mod will be used to update the configuration database.
-- @LastRetrieved is a times tamp for when the mod was discovered.
CREATE TABLE Mods(
	'ModRowId' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	'ScannedFileRowId' INTEGER NOT NULL, 
	'ModId' TEXT NOT NULL,
   'Version' INTEGER NOT NULL,
	'Exclusivity' TEXT NOT NULL DEFAULT 'Nonexclusive', 
	'Enabled' INTEGER DEFAULT 0, 
	FOREIGN KEY(ScannedFileRowId) REFERENCES ScannedFiles(ScannedFileRowId) ON DELETE CASCADE ON UPDATE CASCADE, 
	FOREIGN KEY(Exclusivity) REFERENCES ExclusivityTypes(Name) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- All components in a mod.
-- @ModRowId is the mod containing the component.
-- @ComponentRowId is the locally unique id of the component.
-- @ComponentId is the globally unique id of the component.
-- @ComponentType is the type of the component.
CREATE TABLE Components(
	'ComponentRowId' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	'ModRowId' INTEGER NOT NULL,
	'ComponentId' TEXT,
	'ComponentType' TEXT NOT NULL,
	FOREIGN KEY('ModRowId') REFERENCES Mods('ModRowId') ON DELETE CASCADE ON UPDATE CASCADE
);	

-- All settings in a mod.
-- @ModRowId is the mod containing the setting.
-- @SettingRowId is the locally unique id of the setting.
-- @SettingId is the globally unique id of the setting.
-- @SettingType is the type of the setting.
CREATE Table Settings(
	'SettingRowId' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
	'ModRowId' INTEGER NOT NULL,
	'SettingId' TEXT,
	'SettingType' TEXT NOT NULL,
	FOREIGN KEY('ModRowId') REFERENCES Mods('ModRowId') ON DELETE CASCADE ON UPDATE CASCADE
);
	
-- A manifest of all files contained in a mod.
-- @FileRowId represents a locally unique identifier to the specific file.
-- @ModRowId represents the specific mod instance this file is a member of.
-- @Path represents the relative path to the file from the .modinfo
-- @Relative represents the relative path to the modinfo file.
CREATE TABLE ModFiles(
	'FileRowId' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	'ModRowId' INTEGER NOT NULL, 
	'Path' TEXT NOT NULL, 
	FOREIGN KEY ('ModRowId') REFERENCES Mods('ModRowId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- This table contains all custom settings.
-- @ComponentRowId is the locally unique identifier referring to the mod setting.
-- @FileRowId is the locally unique identifier to the mod file.
-- @Priority is the order in which the files should be executed.
CREATE TABLE ComponentFiles(
	'ComponentRowId' INTEGER NOT NULL,
	'FileRowId' INTEGER NOT NULL,
	'Priority' INTEGER NOT NULL,
	PRIMARY KEY('ComponentRowId', 'FileRowId'),
	FOREIGN KEY('ComponentRowId') REFERENCES Components('ComponentRowId') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY('FileRowId') REFERENCES ModFiles('FileRowId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- This table contains all file references in settings.
-- @SettingRowId is the locally unique identifier referring to the mod setting.
-- @FileRowId is the locally unique identifier to the mod file.
-- @Priority is the order in which the files should be executed.
CREATE TABLE SettingFiles(
	'SettingRowId' INTEGER NOT NULL,
	'FileRowId' INTEGER NOT NULL,
	'Priority' INTEGER NOT NULL,
	PRIMARY KEY('SettingRowId', 'FileRowId'),
	FOREIGN KEY('SettingRowId') REFERENCES Settings('SettingRowId') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY('FileRowId') REFERENCES ModFiles('FileRowId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Name/Value pair representing properties of a mod.
-- @ModRowId represents the specific mod instance this file is a member of.
-- @Name is the name of the property.
-- @Value is the value of the property.
CREATE TABLE ModProperties(
	'ModRowId' INTEGER NOT NULL, 
	'Name' TEXT NOT NULL, 
	'Value' TEXT, 
	PRIMARY KEY ('ModRowId', 'Name'), 
	FOREIGN KEY ('ModRowId') REFERENCES Mods('ModRowId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Name/Value pair representing properties of a component.
-- @ComponentRowId represents the specific component instance this file is a member of.
-- @Name is the name of the property.
-- @Value is the value of the property.
CREATE TABLE ComponentProperties(
	'ComponentRowId' INTEGER NOT NULL,
	'Name' TEXT NOT NULL,
	'Value' TEXT,
	PRIMARY KEY ('ComponentRowId', 'Name'),
	FOREIGN KEY ('ComponentRowId') REFERENCES Components('ComponentRowId') ON DELETE CASCADE ON UPDATE CASCADE
);
	
-- Name/Value pair representing properties of a setting.
-- @SettingRowId represents the specific setting instance this file is a member of.
-- @Name is the name of the property.
-- @Value is the value of the property.
CREATE TABLE SettingProperties(
	'SettingRowId' INTEGER NOT NULL,
	'Name' TEXT NOT NULL,
	'Value' TEXT,
	PRIMARY KEY ('SettingRowId', 'Name'),
	FOREIGN KEY ('SettingRowId') REFERENCES Settings('SettingRowId') ON DELETE CASCADE ON UPDATE CASCADE
);
	
-- A table describing the relationship of one mod package to another.
-- @ModRowId represents the mod instance initiating the relationship
-- @OtherModId represents the other mod (note that this is the ModId and not ModRowId)
-- @Relationship represents the kind of relationship (see ModRelationshipTypes).
-- @OtherModTitle represents the name of the other mod (used for situations where the mod does not exist).
CREATE TABLE ModRelationships(
	'ModRowId' INTEGER NOT NULL, 
	'OtherModId' TEXT NOT NULL, 
	'Relationship' TEXT NOT NULL, 
	'OtherModTitle' TEXT, 
	FOREIGN KEY('ModRowId') REFERENCES Mods('ModRowId') ON DELETE CASCADE ON UPDATE CASCADE, 
	FOREIGN KEY('Relationship') REFERENCES RelationshipTypes('Name') ON DELETE RESTRICT ON UPDATE CASCADE
);
	
-- A table describing the relationship of one mod component to another.
-- @ComponentRowId represents the mod instance initiating the relationship
-- @OtherModId represents the other mod (note that this is the ModId and not ModRowId)
-- @Relationship represents the kind of relationship (see ModRelationshipTypes).
-- @OtherModTitle represents the name of the other mod (used for situations where the mod does not exist).
CREATE TABLE ComponentRelationships(
	'ComponentRowId' INTEGER NOT NULL, 
	'OtherModId' TEXT NOT NULL,
	'OtherComponentId' TEXT NOT NULL,
	'Relationship' TEXT NOT NULL,
	'OtherComponentTitle' TEXT, 
	FOREIGN KEY('ComponentRowId') REFERENCES Components('ComponentRowId') ON DELETE CASCADE ON UPDATE CASCADE, 
	FOREIGN KEY('Relationship') REFERENCES RelationshipTypes('Name') ON DELETE RESTRICT ON UPDATE CASCADE
);

-- This table contains localized versions of descriptive strings used by the modinfo
-- @ModRowId is mod instance that owns the string.
-- @Tag is the key that is used to reference the string.
-- @Locale represents what locale the text is localized for.
-- @Text is the actual text.
CREATE TABLE LocalizedText(
	'ModRowId' INTEGER NOT NULL,
	'Tag' TEXT NOT NULL,
	'Locale' TEXT NOT NULL,
	'Text' TEXT NOT NULL,
	PRIMARY KEY('ModRowId', 'Tag', 'Locale'),
	FOREIGN KEY('ModRowId') REFERENCES Mods('ModRowId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- This table contains various stored procedures used by native code to access the database.
-- @Name is the name of the stored procedure
-- @Context is a shared group of procedures
-- @SQL is the SQL text to be used.
CREATE TABLE StoredProcedures(
	'Name' TEXT NOT NULL,
	'Context' TEXT,
	'SQL' TEXT NOT NULL,
	PRIMARY KEY('Name', 'Context')
);

-- Triggers
CREATE TRIGGER OnComponentTypeInsert AFTER INSERT ON ComponentTypes BEGIN UPDATE ComponentTypes SET Value = Make_Hash(Name) WHERE Name = New.Name; END;
CREATE TRIGGER OnSettingTypeInsert AFTER INSERT ON SettingTypes BEGIN UPDATE SettingTypes SET Value = Make_Hash(Name) WHERE Name = New.Name; END;


-- Static Data
INSERT INTO ExclusivityTypes('Name', 'Value') VALUES ('Nonexclusive', 0);
INSERT INTO ExclusivityTypes('Name', 'Value') VALUES ('PartiallyExclusive', 1);
INSERT INTO ExclusivityTypes('Name', 'Value') VALUES ('Exclusive', 2);

INSERT INTO RelationshipTypes('Name', 'Value') VALUES ('Blocks', -1);
INSERT INTO RelationshipTypes('Name', 'Value') VALUES ('References', 1);
INSERT INTO RelationshipTypes('Name', 'Value') VALUES ('Depends',  2);

INSERT INTO ComponentTypes('Name') VALUES ('UpdateDatabase');
INSERT INTO ComponentTypes('Name') VALUES ('UpdateAudio');
INSERT INTO ComponentTypes('Name') VALUES ('UpdateARX');
INSERT INTO ComponentTypes('Name') VALUES ('ModArt');
INSERT INTO ComponentTypes('Name') VALUES ('UserInterface');
INSERT INTO ComponentTypes('Name') VALUES ('LocalizedText');
INSERT INTO ComponentTypes('Name') VALUES ('GameplayScripts');
INSERT INTO ComponentTypes('Name') VALUES ('ImportFiles');

-- INSERT INTO ComponentTypes('Name') VALUES ('ImportFile');
-- INSERT INTO ComponentTypes('Name') VALUES ('Leader');
-- INSERT INTO ComponentTypes('Name') VALUES ('Unit');
-- INSERT INTO ComponentTypes('Name') VALUES ('Building');
-- INSERT INTO ComponentTypes('Name') VALUES ('Technology');
-- INSERT INTO ComponentTypes('Name') VALUES ('Religion');
-- INSERT INTO ComponentTypes('Name') VALUES ('Belief');

INSERT INTO SettingTypes('Name') VALUES('Custom');
INSERT INTO SettingTypes('Name') VALUES('LocalizedText');
INSERT INTO SettingTypes('Name') VALUES('Map');
INSERT INTO SettingTypes('Name') VALUES('WorldBuilder');
-- INSERT INTO SettingTypes('Name') VALUES('RuleSet');
-- INSERT INTO SettingTypes('Name') VALUES('PlayerEntry');
-- INSERT INTO SettingTypes('Name') VALUES('GameOption');
-- INSERT INTO SettingTypes('Name') VALUES('MapScript');
-- INSERT INTO SettingTypes('Name') VALUES('Map');
-- INSERT INTO SettingTypes('Name') VALUES('Victory');

-- Stored procedures used by framework
-- Some rough naming conventions.
-- Prefix with "Get" if query is read-only and expected to return 1 and only 1 row.
-- Prefix with "List" if query is read-only and expected to return 0 or many rows.
-- Prefix with verb if query is intended modify database and be executed.
-- If the table is required to distinguish between different procedures include a "From<TableName>"
-- If a procedure takes any arguments,  use "By<ArgumentName>([And|Or]<ArgumentName>)*
-- An exception to this pattern is if the procedure is a predicate against some argument.  e.g GetModIdExists or GetModEnabled.
-- In this case, the argument is inferred by what you're testing.

-- Framework Procedures
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'EnableModByModRowId', 'UPDATE MODS SET Enabled = 1 WHERE ModRowId = ?');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'DisableModByModRowId', 'UPDATE MODS SET Enabled = 0 WHERE ModRowId = ?');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModIdExists', 'SELECT 1 FROM Mods WHERE ModId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModRowIdExists', 'SELECT 1 FROM Mods WHERE ModRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModIdEnabled', 'SELECT 1 FROM Mods WHERE Enabled = 1 AND ModId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModRowIdEnabled', 'SELECT 1 FROM Mods WHERE Enabled = 1 AND ModRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetFirstModRowIdByModId', 'SELECT ModRowId FROM Mods WHERE ModId = ? ORDER BY ModRowId LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModIdByModRowId', 'SELECT ModId FROM Mods WHERE ModRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetVersionByModRowId', 'SELECT Version FROM Mods WHERE ModRowId = ? LIMIT 1');

INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListModRowIds', 'SELECT ModRowId FROM Mods ORDER BY ModRowId');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListDistinctModIds', 'SELECT distinct ModId FROM Mods ORDER BY ModId');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListEnabledMods', 'SELECT ModRowId FROM Mods WHERE Enabled = 1 ORDER BY ModRowId');

INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListSettingsByModRowId', 'SELECT SettingRowId FROM Settings WHERE ModRowId = ? ORDER BY SettingRowId');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetSettingIdBySettingRowId', 'SELECT SettingId FROM Settings WHERE SettingRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModRowIdBySettingRowId', 'SELECT ModRowId FROM Settings WHERE SettingRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetSettingTypeValueBySettingRowId', 'SELECT SettingTypes.Value FROM Settings INNER JOIN SettingTypes ON Settings.SettingType = SettingTypes.Name WHERE Settings.SettingRowId = ? LIMIT 1');

INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListComponentsByModRowId', 'SELECT ComponentRowId FROM Components WHERE ModRowId = ? ORDER BY ComponentRowId');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetComponentIdByComponentRowId', 'SELECT ComponentId FROM Components WHERE ComponentRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModRowIdByComponentRowId', 'SELECT ModRowId FROM Components WHERE ComponentRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetComponentTypeValueByComponentRowId', 'SELECT ComponentTypes.Value FROM Components INNER JOIN ComponentTypes ON Components.ComponentType = ComponentTypes.Name WHERE Components.ComponentRowId = ? LIMIT 1');

-- Discovery Service Procedures
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListScannedFiles', 'SELECT Path, LastWriteTime FROM ScannedFiles');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'DeleteScannedFile', 'DELETE FROM ScannedFiles WHERE Path = ?');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'AddScannedFile', 'INSERT INTO ScannedFiles(Path, LastWriteTime) VALUES(?,?)');

-- File Service Procedures
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListPathsByComponentRowId', 'SELECT Path from ModFiles a inner join ComponentFiles b on a.FileRowId = b.FileRowId where b.ComponentRowId = ? ORDER BY b.Priority DESC');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListPathsByModRowId', 'SELECT Path FROM ModFiles WHERE ModRowId = ? ORDER BY Path');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListPathsBySettingRowId', 'SELECT Path from ModFiles a inner join SettingFiles b on a.FileRowId = b.FileRowId where b.SettingRowId = ? ORDER BY b.Priority DESC');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'PathExistsByModRowId', 'SELECT 1 FROM ModFiles WHERE ModRowId = ? AND Path = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetPathByModRowId', 'SELECT Path FROM ScannedFiles INNER JOIN Mods ON ScannedFiles.ScannedFileRowId = Mods.ScannedFileRowId WHERE ModRowId = ? LIMIT 1');

-- Property Service Procedures
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModPropertyByModRowIdAndName', 'SELECT Value FROM ModProperties WHERE ModRowId = ? AND Name = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetComponentPropertyByComponentRowIdAndName', 'SELECT Value FROM ComponentProperties WHERE ComponentRowId = ? AND Name = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetSettingPropertyBySettingRowIdAndName', 'SELECT Value FROM SettingProperties WHERE SettingRowId = ? AND Name = ? LIMIT 1');

INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddModRelation', 'INSERT INTO ModRelationships(ModRowID, OtherModID, Relationship, OtherModTitle) VALUES(?,?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddFile', 'INSERT INTO ModFiles(ModRowId, Path) VALUES(?, ?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddMod', 'INSERT INTO Mods(ScannedFileRowId, ModId, Version) VALUES(?, ?, ?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddProperty', 'INSERT INTO ModProperties(ModRowId, Name, Value) VALUES(?, ?, ?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddLocalizedText', 'INSERT INTO LocalizedText(ModRowId, Tag, Locale, Text) VALUES(?, ?, ?, ?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'GetFileId', 'SELECT FileRowId from ModFiles WHERE ModRowId = ? and Path = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'GetComponentId', 'SELECT ComponentRowId from Components WHERE ModRowId = ? and ComponentId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddSetting', 'INSERT INTO Settings(ModRowId, SettingId, SettingType) VALUES(?, ?, ?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddSettingFile', 'INSERT INTO SettingFiles(SettingRowId, FileRowId, Priority) VALUES (?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddSettingProperty', 'INSERT INTO SettingProperties(SettingRowId, Name, Value) VALUES(?, ?, ?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddComponent', 'INSERT INTO Components(ModRowId, ComponentId, ComponentType) VALUES(?, ?, ?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddComponentFile', 'INSERT INTO ComponentFiles(ComponentRowId, FileRowId, Priority) VALUES (?, ?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddComponentProperty', 'INSERT INTO ComponentProperties(ComponentRowId, Name, Value) VALUES(?, ?, ?)');

-- User version is written at the end.
PRAGMA user_version(13);
