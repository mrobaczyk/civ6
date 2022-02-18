-- Modding Framework Schema
-- 
-- Revision History
-- Version 20:
-- * Added 'Any' attribute to criteria for whether to match any of the criterion rather than all.
-- * Moved 'Inverse' from Criteria to individual Criterion.
-- Version 19:
-- * Added support for migrating data during an upgrade.
-- * Added 'Inverse' to Criteria.
-- Version 18:
-- * Removed stored procedures for listing paths.  These are now handled internally.
-- Version 17:
-- * Component associations to Criteria is many to many instead of many to 1.
-- * Components may now contain a list of Uris as well as Files.
-- * Updated ComponentRelationships to remove title (not needed) and add override which infers ignoring their criteria.
-- * Added ReverseDependency relationship type.
-- * Removed Components.CriteriaRowId
-- * Added ComponentCriteria
-- * Added ComponentReferences
-- Version 16:
-- * Removed Component and Setting type tables.
-- * Removed reliance on Make_Hash function.
-- * Added criteria structures.
-- * Added mod group structures.
-- Version 15:
-- * Added Icons setting and component types.
-- Version 14:
-- * Added ModArt setting type.
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

-- Generate Schema
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
-- @LastRetrieved is a times tamp for when the mod was discovered.
CREATE TABLE Mods(
	'ModRowId' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	'ScannedFileRowId' INTEGER NOT NULL, 
	'ModId' TEXT NOT NULL,
	'Version' INTEGER NOT NULL,
	'Exclusivity' TEXT, 
	FOREIGN KEY(ScannedFileRowId) REFERENCES ScannedFiles(ScannedFileRowId) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Criteria
-- @CriteriaRowId is the unique id associated with the criteria.
-- @ModRowId is the specific mod associated with the criteria.
-- @CriteriaId is the user friendly identifier of the criteria.
CREATE TABLE Criteria(
	'CriteriaRowId' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	'ModRowId' INTEGER NOT NULL,
	'CriteriaId' INTEGER NOT NULL,
	'Any' BOOLEAN NOT NULL DEFAULT 0,
	FOREIGN KEY ('ModRowId') REFERENCES Mods('ModRowId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Individual criterion of criteria.
-- @CriterionRowId is the unique id associated with the criterion
-- @CriteriaRowId is the criteria which the criterion is associated with.
-- @CriteriaType is the type of criterion.
CREATE TABLE Criterion(
	'CriterionRowId' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	'CriteriaRowId' INTEGER NOT NULL,
	'CriterionType' TEXT NOT NULL,
	'Inverse' BOOLEAN NOT NULL DEFAULT 0,
	FOREIGN KEY ('CriteriaRowId') REFERENCES Criteria('CriteriaRowId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- Properties of a criterion
-- @CriteriaRowId is the criteria which the criterion is associated with
-- @Name is the name of the property.
-- @Value is the value of the property (as text).
CREATE TABLE CriterionProperties(
	'CriterionRowId' INTEGER NOT NULL, 
	'Name' TEXT NOT NULL, 
	'Value' TEXT NOT NULL, 
	PRIMARY KEY ('CriterionRowId', 'Name'), 
	FOREIGN KEY ('CriterionRowId') REFERENCES Criterion('CriterionRowId') ON DELETE CASCADE ON UPDATE CASCADE
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

-- This table contains all local file references of the component.
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

-- This table contains all universal references of the component.
-- @ComponentRowId is the locally unique identifier referring to the mod setting.
-- @URI is a mod resource identifier, used commonly to reference files and components in other mods.
-- @Priority is the order in which the files should be executed.
CREATE TABLE ComponentReferences(
	'ComponentRowId' INTEGER NOT NULL,
	'URI' TEXT NOT NULL,
	'Priority' INTEGER NOT NULL,
	PRIMARY KEY('ComponentRowId', 'URI'),
	FOREIGN KEY('ComponentRowId') REFERENCES Components('ComponentRowId') ON DELETE CASCADE ON UPDATE CASCADE
);

-- This table contains criteria that must be met for the component to be applied.
-- @ComponentRowId is the locally unique identifier referring to the component.
-- @CriteriaRowId is the locally unique identifier referring to the criteria.
CREATE TABLE ComponentCriteria(
	'ComponentRowId' INTEGER NOT NULL,
	'CriteriaRowId' TEXT NOT NULL,
	PRIMARY KEY('ComponentRowId', 'CriteriaRowId'),
	FOREIGN KEY('ComponentRowId') REFERENCES Components('ComponentRowId') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY('CriteriaRowId') REFERENCES Criteria('CriteriaRowId') ON DELETE CASCADE ON UPDATE CASCADE
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
	'Value' TEXT NOT NULL,
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
	'Value' TEXT NOT NULL,
	PRIMARY KEY ('SettingRowId', 'Name'),
	FOREIGN KEY ('SettingRowId') REFERENCES Settings('SettingRowId') ON DELETE CASCADE ON UPDATE CASCADE
);
	
-- A table describing the relationship of one mod package to another.
-- @ModRowId represents the mod instance initiating the relationship
-- @OtherModId represents the other mod (note that this is the ModId and not ModRowId)
-- @Relationship represents the kind of relationship.
-- @OtherModTitle represents the name of the other mod (used for situations where the mod does not exist).
CREATE TABLE ModRelationships(
	'ModRowId' INTEGER NOT NULL, 
	'OtherModId' TEXT NOT NULL, 
	'Relationship' TEXT NOT NULL, 
	'OtherModTitle' TEXT, 
	FOREIGN KEY('ModRowId') REFERENCES Mods('ModRowId') ON DELETE CASCADE ON UPDATE CASCADE
);
	
-- A table describing the relationship of one mod component to another.
-- @ComponentRowId represents the component instance initiating the relationship.
-- @OtherModId represents the other mod (note that this is the ModId and not ModRowId).
-- @OtherComponentId represents the other mod's component (note that this is ComponentId and not ComponentRowId).
-- @Relationship represents the kind of relationship.
CREATE TABLE ComponentRelationships(
	'ComponentRowId' INTEGER NOT NULL, 
	'OtherModId' TEXT NOT NULL,
	'OtherComponentId' TEXT NOT NULL,
	'Relationship' TEXT NOT NULL,
	FOREIGN KEY('ComponentRowId') REFERENCES Components('ComponentRowId') ON DELETE CASCADE ON UPDATE CASCADE
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

-- This table contains named groups of enabled mods.
-- @ModGroupRowId is the unique id associated with the group.
-- @Name is the user-provided name of the group.
-- @CanDelete is whether or not the load out can be deleted by UI.
-- @SortIndex is the sort index to use for the loadout.
CREATE TABLE ModGroups(
	'ModGroupRowId' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
	'Name' TEXT NOT NULL,
	'CanDelete' BOOLEAN DEFAULT 1,
	'Selected' BOOLEAN DEFAULT 0,
	'SortIndex' INTEGER DEFAULT 100
);

-- This table contains the mods which are enabled for a specific mod group.
-- @ModGroupRowId is the unique id associated with a mod group.
-- @ModRowId is the unique id associated with a mod.
CREATE TABLE ModGroupItems(
	'ModGroupRowId' INTEGER NOT NULL,
	'ModRowId' INTEGER NOT NULL,
	PRIMARY KEY ('ModGroupRowId', 'ModRowId'),	
	FOREIGN KEY ('ModGroupRowId') REFERENCES ModGroups('ModGroupRowId') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY ('ModRowId') REFERENCES Mods('ModRowId') ON DELETE CASCADE ON UPDATE CASCADE
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

-- This table contains statements to assist with migrating data during a database upgrade.
-- @SQL is the statement to run.
-- @MinVersion is the minimal old database version to run the SQL.
-- @MaxVersion is the maximum old database version to run the SQL.
-- @SortIndex is the column used to sort the statements.
CREATE TABLE Migrations(
	'SQL' TEXT NOT NULL,
	'MinVersion' INTEGER NOT NULL,
	'MaxVersion' INTEGER NOT NULL,
	'SortIndex' INTEGER NOT NULL
);

-- Static Data
INSERT INTO ModGroups('ModGroupRowId', 'Name', 'CanDelete', 'Selected', 'SortIndex') VALUES (1, 'LOC_MODS_GROUP_DEFAULT_NAME', 0, 1, 0);

-- Data Migrations.
-- Copy mod groups.
INSERT INTO Migrations('MinVersion', 'MaxVersion', 'SortIndex', 'SQL') VALUES(16,999,0,"INSERT INTO ModGroups SELECT * from old.ModGroups as omg where omg.CanDelete = 1");

-- Copy which mod group is selected.
INSERT INTO Migrations('MinVersion', 'MaxVersion', 'SortIndex', 'SQL') VALUES(16,999,1,"UPDATE ModGroups SET Selected = (SELECT Selected FROM old.ModGroups omg where omg.ModGroupRowId = ModGroups.ModGroupRowId LIMIT 1)");

-- Copy Scanned Files data (but set LastWriteTime to 0 to force rescan)
INSERT INTO Migrations('MinVersion', 'MaxVersion', 'SortIndex', 'SQL') VALUES(16,999,1,'INSERT INTO ScannedFiles(ScannedFileRowId,Path,LastWriteTime) SELECT ScannedFileRowId,Path,0 from old.ScannedFiles;');

-- Copy Mod data (the mod row ids are needed the most here)
INSERT INTO Migrations('MinVersion', 'MaxVersion', 'SortIndex', 'SQL') VALUES(16,999,1,"INSERT INTO Mods('ModRowId','ScannedFileRowId','ModId','Version','Exclusivity') SELECT ModRowId,ScannedFileRowId,ModId,Version,Exclusivity from old.Mods");

-- Copy Mod Group Item data
INSERT INTO Migrations('MinVersion', 'MaxVersion', 'SortIndex', 'SQL') VALUES(16,999,1,"INSERT INTO ModGroupItems('ModGroupRowId','ModRowId') SELECT ModGroupRowId,ModRowId from old.ModGroupItems");

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
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'EnableModByModRowId', 'INSERT OR IGNORE INTO ModGroupItems("ModGroupRowId", "ModRowId") SELECT ModGroupRowId, ? FROM ModGroups WHERE Selected = 1 LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'DisableModByModRowId', 'DELETE from ModGroupItems where ModGroupRowId IN (select ModGroupRowId from ModGroups where Selected = 1 LIMIT 1) and ModRowId = ?');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModIdExists', 'SELECT 1 FROM Mods WHERE ModId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModRowIdExists', 'SELECT 1 FROM Mods WHERE ModRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModIdEnabled', 'SELECT 1 from ModGroupItems INNER JOIN ModGroups ON ModGroupItems.ModGroupRowId = ModGroups.ModGroupRowId INNER JOIN Mods on ModGroupItems.ModRowId = Mods.ModRowId WHERE ModGroups.Selected = 1 AND Mods.ModId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModRowIdEnabled', 'SELECT 1 from ModGroupItems INNER JOIN ModGroups ON ModGroupItems.ModGroupRowId = ModGroups.ModGroupRowId WHERE ModGroups.Selected = 1 AND ModGroupItems.ModRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetFirstModRowIdByModId', 'SELECT ModRowId FROM Mods WHERE ModId = ? ORDER BY ModRowId LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModIdByModRowId', 'SELECT ModId FROM Mods WHERE ModRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetVersionByModRowId', 'SELECT Version FROM Mods WHERE ModRowId = ? LIMIT 1');

INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListModRowIds', 'SELECT ModRowId FROM Mods ORDER BY ModRowId');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListDistinctModIds', 'SELECT distinct ModId FROM Mods ORDER BY ModId');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListEnabledMods', 'SELECT ModGroupItems.ModRowId from ModGroupItems inner join ModGroups on ModGroupItems.ModGroupRowId = ModGroups.ModGroupRowId where ModGroups.Selected = 1 ORDER BY ModGroupItems.ModRowId');

INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListSettingsByModRowId', 'SELECT SettingRowId FROM Settings WHERE ModRowId = ? ORDER BY SettingRowId');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetSettingIdBySettingRowId', 'SELECT SettingId FROM Settings WHERE SettingRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModRowIdBySettingRowId', 'SELECT ModRowId FROM Settings WHERE SettingRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetSettingTypeBySettingRowId', 'SELECT SettingType FROM Settings WHERE SettingRowId = ? LIMIT 1');

INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListComponentsByModRowId', 'SELECT ComponentRowId FROM Components WHERE ModRowId = ? ORDER BY ComponentRowId');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetComponentIdByComponentRowId', 'SELECT ComponentId FROM Components WHERE ComponentRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModRowIdByComponentRowId', 'SELECT ModRowId FROM Components WHERE ComponentRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetComponentTypeByComponentRowId', 'SELECT ComponentType FROM Components WHERE ComponentRowId = ? LIMIT 1');

-- Discovery Service Procedures
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListScannedFiles', 'SELECT Path, LastWriteTime FROM ScannedFiles');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'DeleteScannedFile', 'DELETE FROM ScannedFiles WHERE Path = ?');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'AddScannedFile', 'INSERT INTO ScannedFiles(Path, LastWriteTime) VALUES(?,?)');

-- Property Service Procedures
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModPropertyByModRowIdAndName', 'SELECT Value FROM ModProperties WHERE ModRowId = ? AND Name = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetComponentPropertyByComponentRowIdAndName', 'SELECT Value FROM ComponentProperties WHERE ComponentRowId = ? AND Name = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetSettingPropertyBySettingRowIdAndName', 'SELECT Value FROM SettingProperties WHERE SettingRowId = ? AND Name = ? LIMIT 1');

-- Loader Service Procedures
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddModRelation', 'INSERT INTO ModRelationships(ModRowID, OtherModID, Relationship, OtherModTitle) VALUES(?,?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddFile', 'INSERT INTO ModFiles(ModRowId, Path) VALUES(?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddMod', 'INSERT INTO Mods(ScannedFileRowId, ModId, Version) VALUES(?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddProperty', 'INSERT INTO ModProperties(ModRowId, Name, Value) VALUES(?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddLocalizedText', 'INSERT INTO LocalizedText(ModRowId, Tag, Locale, Text) VALUES(?,?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'GetFileId', 'SELECT FileRowId from ModFiles WHERE ModRowId = ? and Path = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'GetComponentId', 'SELECT ComponentRowId from Components WHERE ModRowId = ? and ComponentId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddSetting', 'INSERT INTO Settings(ModRowId, SettingId, SettingType) VALUES(?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddSettingFile', 'INSERT INTO SettingFiles(SettingRowId, FileRowId, Priority) VALUES (?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddSettingProperty', 'INSERT INTO SettingProperties(SettingRowId, Name, Value) VALUES(?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddComponent', 'INSERT INTO Components(ModRowId, ComponentId, ComponentType) VALUES(?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddComponentCriteria', 'INSERT INTO ComponentCriteria(ComponentRowId, CriteriaRowId) VALUES (?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddComponentFile', 'INSERT INTO ComponentFiles(ComponentRowId, FileRowId, Priority) VALUES (?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddComponentReference', 'INSERT INTO ComponentReferences(ComponentRowId, Uri, Priority) VALUES (?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddComponentRelationship', 'INSERT INTO ComponentRelationships(ComponentRowId, OtherModId, OtherComponentId, Relationship) VALUES (?,?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddComponentProperty', 'INSERT INTO ComponentProperties(ComponentRowId, Name, Value) VALUES(?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddCriteria', 'INSERT INTO Criteria(ModRowId, CriteriaId, Any) VALUES (?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddCriterion', 'INSERT INTO Criterion(CriteriaRowId, CriterionType, Inverse) VALUES(?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'AddCriterionProperty', 'INSERT INTO CriterionProperties(CriterionRowId, Name, Value) VALUES(?,?,?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding_LoadMod', 'GetCriteriaId', 'SELECT CriteriaRowId from Criteria where ModRowId = ? and CriteriaId = ? LIMIT 1');

INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListModAssociations', 'SELECT OtherModId, OtherModTitle from ModRelationships where ModRowId = ? and Relationship = ?');

INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ListModGroups', 'SELECT ModGroupRowId from ModGroups ORDER BY ModGroupRowId');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetModGroupDetails', 'SELECT Name, CanDelete, SortIndex from ModGroups WHERE ModGroupRowId = ? LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'GetSelectedModGroup', 'SELECT ModGroupRowId from ModGroups where Selected = 1 LIMIT 1');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'ChangeSelectedModGroup', 'UPDATE ModGroups SET Selected = CASE WHEN ModGroupRowId = ? THEN 1 ELSE 0 END');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'CreateModGroup', 'INSERT INTO ModGroups(Name) VALUES(?)');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'CopyModGroup', 'INSERT INTO ModGroupItems(ModGroupRowId, ModRowId) SELECT ?, ModRowId from ModGroupItems where ModGroupRowId = ?');
INSERT INTO StoredProcedures('Context', 'Name', 'SQL') VALUES('Modding', 'DeleteModGroup', 'DELETE FROM ModGroups where ModGroupRowId = ? and CanDelete = 1');

-- User version is written at the end.
PRAGMA user_version(20);
