-- resource: https://learn.microsoft.com/en-us/sql/t-sql/statements/set-statements-transact-sql?view=sql-server-ver17
-- resource: https://learn.microsoft.com/en-us/sql/relational-databases/tables/unique-constraints-and-check-constraints?view=sql-server-ver17
-- UQ -> unique, CK -> check, DF -> default, LKUP -> lookup

IF DB_ID(N'RetroPlanet') IS NULL CREATE DATABASE RetroPlanet;

GO

USE RetroPlanet;

GO

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON; -- filtered uq indexes

GO

CREATE TABLE LKUP_ClassificationKind (
  id VARCHAR(30) NOT NULL CONSTRAINT PK_LKUP_ClassificationKind PRIMARY KEY, -- unique code
  name NVARCHAR(100) NOT NULL
);

CREATE TABLE LKUP_AllowedParentKind (
  parentKindId VARCHAR(30) NOT NULL CONSTRAINT FK_LKUP_AllowedParentKind_Parent REFERENCES LKUP_ClassificationKind (id), -- must be a real kind
  childKindId VARCHAR(30) NOT NULL CONSTRAINT FK_LKUP_AllowedParentKind_Child REFERENCES LKUP_ClassificationKind (id), -- must be a real kind
  CONSTRAINT PK_LKUP_AllowedParentKind PRIMARY KEY (parentKindId, childKindId) -- each parent/child pair once
);

CREATE TABLE LKUP_GradeScale (id VARCHAR(20) NOT NULL CONSTRAINT PK_LKUP_GradeScale PRIMARY KEY, name NVARCHAR(100) NOT NULL); -- unique code
CREATE TABLE LKUP_EventKind (id VARCHAR(30) NOT NULL CONSTRAINT PK_LKUP_EventKind PRIMARY KEY, name NVARCHAR(100) NOT NULL); -- unique code
CREATE TABLE LKUP_MediaKind (id VARCHAR(30) NOT NULL CONSTRAINT PK_LKUP_MediaKind PRIMARY KEY, name NVARCHAR(100) NOT NULL); -- unique code
CREATE TABLE LKUP_EmbeddingModel (
  id VARCHAR(100) NOT NULL CONSTRAINT PK_LKUP_EmbeddingModel PRIMARY KEY, -- unique model name
  dimensions INT NOT NULL CONSTRAINT CK_LKUP_EmbeddingModel_Dimensions CHECK (dimensions > 0) -- vector length above 0
);

CREATE TABLE Collector (
  collectorId INT IDENTITY NOT NULL CONSTRAINT PK_Collector PRIMARY KEY, -- unique id
  email NVARCHAR(254) NOT NULL CONSTRAINT UQ_Collector_Email UNIQUE, -- one account per email
  displayName NVARCHAR(100) NOT NULL,
  passwordHash VARBINARY(256) NOT NULL,
  createdAt DATETIME2(0) NOT NULL CONSTRAINT DF_Collector_CreatedAt DEFAULT SYSUTCDATETIME() -- defaults to now (utc)
);

CREATE TABLE Collection (
  collectionId INT IDENTITY NOT NULL CONSTRAINT PK_Collection PRIMARY KEY, -- unique id
  collectorId INT NOT NULL CONSTRAINT FK_Collection_Collector REFERENCES Collector (collectorId) ON DELETE CASCADE, -- owner must exist; deleted with owner
  name NVARCHAR(100) NOT NULL,
  description NVARCHAR(1000) NULL,
  createdAt DATETIME2(0) NOT NULL CONSTRAINT DF_Collection_CreatedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  CONSTRAINT UQ_Collection_Name UNIQUE (collectorId, name) -- names unique per collector
);

CREATE TABLE Classification (
  classificationId INT IDENTITY NOT NULL CONSTRAINT PK_Classification PRIMARY KEY, -- unique id
  kindId VARCHAR(30) NOT NULL CONSTRAINT FK_Classification_Kind REFERENCES LKUP_ClassificationKind (id), -- must be a valid kind
  parentId INT NULL CONSTRAINT FK_Classification_Parent REFERENCES Classification (classificationId), -- parent must exist
  name NVARCHAR(150) NOT NULL,
  CONSTRAINT UQ_Classification_IdKind UNIQUE (classificationId, kindId), -- lets ProductClassification check the kind
  CONSTRAINT UQ_Classification_Name UNIQUE (parentId, kindId, name), -- no duplicate siblings
  CONSTRAINT CK_Classification_NotOwnParent CHECK (parentId <> classificationId) -- can't be its own parent
);

CREATE TABLE Product (
  productId INT IDENTITY NOT NULL CONSTRAINT PK_Product PRIMARY KEY, -- unique id
  name NVARCHAR(200) NOT NULL,
  releaseYear SMALLINT NULL CONSTRAINT CK_Product_ReleaseYear CHECK (releaseYear BETWEEN 1900 AND 2100), -- year between 1900 and 2100
  description NVARCHAR(2000) NULL
);

CREATE TABLE ProductClassification (
  productId INT NOT NULL CONSTRAINT FK_ProductClassification_Product REFERENCES Product (productId) ON DELETE CASCADE, -- product must exist; deleted with product
  classificationId INT NOT NULL,
  kindId VARCHAR(30) NOT NULL,
CONSTRAINT PK_ProductClassification PRIMARY KEY (productId, classificationId), -- each product/classification pair once
  CONSTRAINT FK_ProductClassification_Classification FOREIGN KEY (classificationId, kindId) REFERENCES Classification (classificationId, kindId) ON UPDATE CASCADE -- classification and its kind must match
);

CREATE UNIQUE
INDEX UX_ProductClassification_OneManufacturerFranchise ON ProductClassification (productId, kindId) -- max one manufacturer and one franchise per product
WHERE kindId IN ('manufacturer', 'franchise');

CREATE TABLE Character (
  characterId INT IDENTITY NOT NULL CONSTRAINT PK_Character PRIMARY KEY, -- unique id
  name NVARCHAR(150) NOT NULL CONSTRAINT UQ_Character_Name UNIQUE, -- names unique
  description NVARCHAR(2000) NULL
);

CREATE TABLE ProductCharacter (
  productId INT NOT NULL CONSTRAINT FK_ProductCharacter_Product REFERENCES Product (productId) ON DELETE CASCADE, -- product must exist; deleted with product
  characterId INT NOT NULL CONSTRAINT FK_ProductCharacter_Character REFERENCES Character (characterId) ON DELETE CASCADE, -- character must exist; deleted with character
  CONSTRAINT PK_ProductCharacter PRIMARY KEY (productId, characterId) -- each product/character pair once
);

CREATE TABLE Variant (
  productId INT NOT NULL CONSTRAINT FK_Variant_Product REFERENCES Product (productId) ON DELETE CASCADE, -- product must exist; deleted with product
  variantNo SMALLINT NOT NULL,
  name NVARCHAR(150) NOT NULL,
  isBase BIT NOT NULL CONSTRAINT DF_Variant_IsBase DEFAULT 0, -- not the base version by default
  description NVARCHAR(2000) NULL,
  CONSTRAINT PK_Variant PRIMARY KEY (productId, variantNo), -- variant number within its product
  CONSTRAINT UQ_Variant_Name UNIQUE (productId, name) -- names unique per product
);

CREATE UNIQUE
INDEX UX_Variant_OneBase ON Variant (productId) -- one base variant per product
WHERE isBase = 1;

CREATE TABLE Accessory (
  productId INT NOT NULL,
  variantNo SMALLINT NOT NULL,
  accessoryNo SMALLINT NOT NULL,
  name NVARCHAR(150) NOT NULL,
  description NVARCHAR(1000) NULL,
  CONSTRAINT PK_Accessory PRIMARY KEY (productId, variantNo, accessoryNo), -- accessory number within its variant
  CONSTRAINT FK_Accessory_Variant FOREIGN KEY (productId, variantNo) REFERENCES Variant (productId, variantNo) ON DELETE CASCADE -- variant must exist; deleted with variant
);

CREATE TABLE Embedding (
  productId INT NOT NULL CONSTRAINT FK_Embedding_Product REFERENCES Product (productId) ON DELETE CASCADE, -- product must exist; deleted with product
  modelId VARCHAR(100) NOT NULL CONSTRAINT FK_Embedding_Model REFERENCES LKUP_EmbeddingModel (id), -- must be a known model
  vector NVARCHAR(MAX) NOT NULL,
  createdAt DATETIME2(0) NOT NULL CONSTRAINT DF_Embedding_CreatedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  CONSTRAINT PK_Embedding PRIMARY KEY (productId, modelId), -- one vector per product per model
  CONSTRAINT CK_Embedding_JsonArray CHECK ( -- vector must be a json array
    ISJSON(vector) = 1
    AND LEFT(LTRIM(vector), 1) = '['
  )
);

CREATE TABLE Grade (
  gradeId INT IDENTITY NOT NULL CONSTRAINT PK_Grade PRIMARY KEY, -- unique id
  scaleId VARCHAR(20) NOT NULL CONSTRAINT FK_Grade_Scale REFERENCES LKUP_GradeScale (id), -- must be a valid scale
  code VARCHAR(20) NOT NULL,
  gradeRank SMALLINT NOT NULL,
  description NVARCHAR(200) NULL,
  CONSTRAINT UQ_Grade_Code UNIQUE (scaleId, code), -- codes unique per scale
  CONSTRAINT UQ_Grade_Rank UNIQUE (scaleId, gradeRank) -- ranks unique per scale
);

CREATE TABLE PriceGuide (
  productId INT NOT NULL,
  variantNo SMALLINT NOT NULL,
  gradeId INT NOT NULL CONSTRAINT FK_PriceGuide_Grade REFERENCES Grade (gradeId), -- grade must exist
  marketValue DECIMAL(12, 2) NOT NULL CONSTRAINT CK_PriceGuide_MarketValue CHECK (marketValue >= 0), -- value can't be negative
  updatedOn DATE NOT NULL CONSTRAINT DF_PriceGuide_UpdatedOn DEFAULT CAST(GETDATE() AS DATE), -- defaults to today
  CONSTRAINT PK_PriceGuide PRIMARY KEY (productId, variantNo, gradeId), -- one price per variant per grade
  CONSTRAINT FK_PriceGuide_Variant FOREIGN KEY (productId, variantNo) REFERENCES Variant (productId, variantNo) ON DELETE CASCADE -- variant must exist; deleted with variant
);

CREATE TABLE Collectible (
  collectibleId INT IDENTITY NOT NULL CONSTRAINT PK_Collectible PRIMARY KEY, -- unique id
  collectionId INT NOT NULL CONSTRAINT FK_Collectible_Collection REFERENCES Collection (collectionId) ON DELETE CASCADE, -- collection must exist; deleted with collection
  productId INT NOT NULL,
  variantNo SMALLINT NOT NULL,
  notes NVARCHAR(2000) NULL,
  CONSTRAINT FK_Collectible_Variant FOREIGN KEY (productId, variantNo) REFERENCES Variant (productId, variantNo), -- variant must exist
  CONSTRAINT UQ_Collectible_Variant UNIQUE (collectibleId, productId, variantNo) -- lets CollectibleAccessory match the variant
);

CREATE TABLE CollectibleAccessory (
  collectibleId INT NOT NULL,
  productId INT NOT NULL,
  variantNo SMALLINT NOT NULL,
  accessoryNo SMALLINT NOT NULL,
  CONSTRAINT PK_CollectibleAccessory PRIMARY KEY (collectibleId, accessoryNo), -- each accessory once per collectible
  CONSTRAINT FK_CollectibleAccessory_Collectible FOREIGN KEY (collectibleId, productId, variantNo) REFERENCES Collectible (collectibleId, productId, variantNo) ON DELETE CASCADE, -- collectible must exist; deleted with it
  CONSTRAINT FK_CollectibleAccessory_Accessory FOREIGN KEY (productId, variantNo, accessoryNo) REFERENCES Accessory (productId, variantNo, accessoryNo) -- accessory must belong to the same variant
);

CREATE SEQUENCE EventSequence AS INT START
WITH
  1;

CREATE TABLE Event (
  collectibleId INT NOT NULL CONSTRAINT FK_Event_Collectible REFERENCES Collectible (collectibleId) ON DELETE CASCADE, -- collectible must exist and deleted with the collectible its attached to
  seq INT NOT NULL CONSTRAINT DF_Event_Seq DEFAULT (NEXT VALUE FOR EventSequence), -- next number from EventSequence
  kindId VARCHAR(30) NOT NULL CONSTRAINT FK_Event_Kind REFERENCES LKUP_EventKind (id), -- must be a valid event kind
  occurredOn DATE NOT NULL,
  gradeId INT NULL CONSTRAINT FK_Event_Grade REFERENCES Grade (gradeId), -- grade must exist
  amount DECIMAL(12, 2) NULL,
  counterparty NVARCHAR(200) NULL,
  notes NVARCHAR(2000) NULL,
  recordedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Event_RecordedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  CONSTRAINT PK_Event PRIMARY KEY (collectibleId, seq), -- event number within its collectible
  CONSTRAINT CK_Event_NotFuture CHECK (occurredOn <= CAST(GETDATE() AS DATE)), -- can't be in the future
  CONSTRAINT CK_Event_GradeOnlyWhenGraded CHECK ( -- grade only on graded events
    (
      kindId = 'graded'
      AND gradeId IS NOT NULL
    )
    OR (
      kindId <> 'graded'
      AND gradeId IS NULL
    )
  ),
  CONSTRAINT CK_Event_AppraisalHasAmount CHECK ( -- appraisals need an amount
    kindId <> 'appraised'
    OR amount IS NOT NULL
  ),
  CONSTRAINT CK_Event_AmountNotNegative CHECK (amount >= 0) -- amount can't be negative
);

CREATE UNIQUE
INDEX UX_Event_OneAcquisition ON Event (collectibleId) -- one acquisition per collectible
WHERE kindId = 'acquired';

CREATE TABLE Media (
  mediaId INT IDENTITY NOT NULL CONSTRAINT PK_Media PRIMARY KEY, -- unique id
  collectibleId INT NOT NULL CONSTRAINT FK_Media_Collectible REFERENCES Collectible (collectibleId) ON DELETE CASCADE, -- collectible must exist; deleted with it
  eventSeq INT NULL,
  kindId VARCHAR(30) NOT NULL CONSTRAINT FK_Media_Kind REFERENCES LKUP_MediaKind (id), -- must be a valid media kind
  uri NVARCHAR(1000) NOT NULL,
  caption NVARCHAR(500) NULL,
  createdAt DATETIME2(0) NOT NULL CONSTRAINT DF_Media_CreatedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  CONSTRAINT FK_Media_Event FOREIGN KEY (collectibleId, eventSeq) REFERENCES Event (collectibleId, seq) -- event must belong to the same collectible
);

GO