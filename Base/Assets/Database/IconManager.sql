
PRAGMA user_version = 1;
 
CREATE TABLE 'IconAtlases'(
	'Name' TEXT NOT NULL,
	PRIMARY KEY('Name')
);

CREATE TABLE 'IconAtlasTextures'(
	'Name' TEXT NOT NULL, 
	'IconSize' INTEGER NOT NULL, 
	'IconsPerRow' INTEGER NOT NULL,
	'IconsPerColumn' INTEGER NOT NULL, 
	'FileName' TEXT NOT NULL, 
	'OffsetH' INTEGER NOT NULL DEFAULT 0, 
	'OffsetV' INTEGER NOT NULL DEFAULT 0, 
	PRIMARY KEY ('Name', 'IconSize'),
	FOREIGN KEY('Name') REFERENCES IconAtlases('Name') ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE 'Icons' (
	'Name' TEXT NOT NULL,
	PRIMARY KEY('Name')
);

CREATE TABLE 'AtlasIcons'(
	'Name' TEXT NOT NULL,
	'Atlas' TEXT NOT NULL,
	'Index' INTEGER NOT NULL,
	PRIMARY KEY('Name', 'Atlas'),
	FOREIGN KEY('Name') REFERENCES Icons('Name') ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY('Atlas') REFERENCES IconAtlases('Name') ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE 'IconAliases'(
	'Name' TEXT NOT NULL,
	'OtherName' TEXT NOT NULL,
	PRIMARY KEY('Name'),
	FOREIGN KEY('Name') REFERENCES Icons('Name') ON DELETE CASCADE ON UPDATE CASCADE
	FOREIGN KEY('OtherName') REFERENCES Icons('Name') ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE VIEW 'IconDefinitions'('Name','Atlas','Index') AS SELECT 'Name', 'Atlas', 'Index' FROM AtlasIcons;
CREATE TRIGGER 'IconDefinitions_Insert' INSTEAD OF INSERT ON IconDefinitions
BEGIN
	INSERT OR IGNORE INTO Icons VALUES (NEW.'Name');
	INSERT INTO AtlasIcons('Name', 'Atlas', 'Index') 
		VALUES (NEW.'Name', NEW.'Atlas', NEW.'Index');
END;

CREATE VIEW 'IconTextureAtlases'('Name', 'IconSize', 'IconsPerRow', 'IconsPerColumn', 'Filename') 
	AS SELECT 'Name', 'IconSize', 'IconsPerRow', 'IconsPerColumn', 'FileName' FROM IconAtlasTextures;
CREATE TRIGGER 'IconTextureAtlases_Insert' INSTEAD OF INSERT ON IconTextureAtlases
BEGIN
	INSERT OR IGNORE INTO IconAtlases VALUES (NEW.Name);
	INSERT INTO IconAtlasTextures('Name', 'IconSize', 'IconsPerRow', 'IconsPerColumn', 'Filename', 'OffsetH', 'OffsetV') 
		VALUES (NEW.'Name', NEW.'IconSize', NEW.'IconsPerRow', NEW.'IconsPerColumn', NEW.'Filename', 0, 0);
END;
