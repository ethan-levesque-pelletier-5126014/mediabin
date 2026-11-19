-- resource: https://learn.microsoft.com/en-us/sql/t-sql/statements/set-statements-transact-sql?view=sql-server-ver17
-- resource: https://learn.microsoft.com/en-us/sql/relational-databases/tables/unique-constraints-and-check-constraints?view=sql-server-ver17
-- resource: https://learn.microsoft.com/en-us/sql/relational-databases/tables/create-foreign-key-relationships?view=sql-server-ver17 
--           |-> I was already familiar with this concept but reviewed this source again anyway
-- UQ -> unique, CK -> check, DF -> default, LKUP -> lookup

IF DB_ID(N'GAPRN') IS NULL CREATE DATABASE GAPRN;

GO

USE GAPRN;

GO

SET ANSI_NULLS ON;

SET QUOTED_IDENTIFIER ON; -- filtered uq indexes

GO

CREATE TABLE LKUP_Category (
  id VARCHAR(30) NOT NULL CONSTRAINT PK_LKUP_Category PRIMARY KEY, -- unique code
  name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_Category_name UNIQUE, -- unique name
  parentId VARCHAR(30) NULL CONSTRAINT FK_LKUP_Category_parent REFERENCES LKUP_Category (id) -- parent category must exist
);

CREATE TABLE LKUP_LocationKind (id VARCHAR(20) NOT NULL CONSTRAINT PK_LKUP_LocationKind PRIMARY KEY, name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_LocationKind_name UNIQUE); -- unique code and unique name
CREATE TABLE LKUP_CaseStatus (id VARCHAR(20) NOT NULL CONSTRAINT PK_LKUP_CaseStatus PRIMARY KEY, name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_CaseStatus_name UNIQUE); -- unique code and unique name
CREATE TABLE LKUP_OutcomeKind (id VARCHAR(20) NOT NULL CONSTRAINT PK_LKUP_OutcomeKind PRIMARY KEY, name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_OutcomeKind_name UNIQUE); -- unique code and unique name

CREATE TABLE LKUP_TheoryKind (
  id VARCHAR(30) NOT NULL CONSTRAINT PK_LKUP_TheoryKind PRIMARY KEY, -- unique code
  name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_TheoryKind_name UNIQUE, -- unique name
  parentId VARCHAR(30) NULL CONSTRAINT FK_LKUP_TheoryKind_parent REFERENCES LKUP_TheoryKind (id) -- parent kind must exist
);

CREATE TABLE LKUP_EvidenceKind (id VARCHAR(20) NOT NULL CONSTRAINT PK_LKUP_EvidenceKind PRIMARY KEY, name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_EvidenceKind_name UNIQUE); -- unique code and unique name
CREATE TABLE LKUP_ReviewMethod (id VARCHAR(30) NOT NULL CONSTRAINT PK_LKUP_ReviewMethod PRIMARY KEY, name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_ReviewMethod_name UNIQUE); -- unique code and unique name
CREATE TABLE LKUP_HandoverKind (id VARCHAR(20) NOT NULL CONSTRAINT PK_LKUP_HandoverKind PRIMARY KEY, name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_HandoverKind_name UNIQUE); -- unique code and unique name
CREATE TABLE LKUP_EquipmentKind (id VARCHAR(30) NOT NULL CONSTRAINT PK_LKUP_EquipmentKind PRIMARY KEY, name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_EquipmentKind_name UNIQUE); -- unique code and unique name
CREATE TABLE LKUP_ProjectKind (id VARCHAR(30) NOT NULL CONSTRAINT PK_LKUP_ProjectKind PRIMARY KEY, name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_ProjectKind_name UNIQUE); -- unique code and unique name

CREATE TABLE LKUP_Reliability (
  id VARCHAR(10) NOT NULL CONSTRAINT PK_LKUP_Reliability PRIMARY KEY, -- unique code
  name NVARCHAR(60) NOT NULL CONSTRAINT UQ_LKUP_Reliability_name UNIQUE, -- unique name
  score TINYINT NOT NULL CONSTRAINT UQ_LKUP_Reliability_score UNIQUE CONSTRAINT CK_LKUP_Reliability_score CHECK (score BETWEEN 0 AND 100) -- scores unique and 0 to 100
);

CREATE TABLE Staff (
  staffId INT IDENTITY NOT NULL CONSTRAINT PK_Staff PRIMARY KEY, -- unique id
  email NVARCHAR(254) NOT NULL CONSTRAINT UQ_Staff_email UNIQUE, -- one account per email
  fullName NVARCHAR(150) NOT NULL,
  leftOn DATE NULL
);

CREATE TABLE Role (roleId VARCHAR(30) NOT NULL CONSTRAINT PK_Role PRIMARY KEY, name NVARCHAR(60) NOT NULL CONSTRAINT UQ_Role_name UNIQUE); -- unique code and unique name

CREATE TABLE StaffRole (
  staffId INT NOT NULL CONSTRAINT FK_StaffRole_Staff REFERENCES Staff (staffId), -- staff must exist
  roleId VARCHAR(30) NOT NULL CONSTRAINT FK_StaffRole_Role REFERENCES Role (roleId), -- role must exist
  grantedOn DATE NOT NULL CONSTRAINT DF_StaffRole_grantedOn DEFAULT CAST(GETDATE() AS DATE), -- defaults to today
  revokedOn DATE NULL,
  CONSTRAINT PK_StaffRole PRIMARY KEY (staffId, roleId), -- each role once per person
  CONSTRAINT CK_StaffRole_dates CHECK (revokedOn >= grantedOn) -- revoked on/after granted
);

CREATE TABLE StaffQualification (
  staffId INT NOT NULL CONSTRAINT FK_StaffQualification_Staff REFERENCES Staff (staffId), -- staff must exist
  methodId VARCHAR(30) NOT NULL CONSTRAINT FK_StaffQualification_Method REFERENCES LKUP_ReviewMethod (id), -- must be a valid method
  qualifiedOn DATE NOT NULL CONSTRAINT DF_StaffQualification_qualifiedOn DEFAULT CAST(GETDATE() AS DATE), -- defaults to today
  revokedOn DATE NULL,
  CONSTRAINT PK_StaffQualification PRIMARY KEY (staffId, methodId), -- each method once per person
  CONSTRAINT CK_StaffQualification_dates CHECK (revokedOn >= qualifiedOn) -- revoked on/after qualified
);

CREATE TABLE Witness (
  witnessId INT IDENTITY NOT NULL CONSTRAINT PK_Witness PRIMARY KEY, -- unique id
  fullName NVARCHAR(150) NULL,
  email NVARCHAR(254) NULL,
  phone VARCHAR(20) NULL,
  isAnonymous BIT NOT NULL CONSTRAINT DF_Witness_isAnonymous DEFAULT 0 -- not anonymous by default
);

CREATE TABLE Location (
  locationId INT IDENTITY NOT NULL CONSTRAINT PK_Location PRIMARY KEY, -- unique id
  parentId INT NULL CONSTRAINT FK_Location_parent REFERENCES Location (locationId), -- parent place must exist
  kindId VARCHAR(20) NOT NULL CONSTRAINT FK_Location_kind REFERENCES LKUP_LocationKind (id), -- must be a valid kind
  name NVARCHAR(150) NOT NULL,
  latitude DECIMAL(9, 6) NOT NULL CONSTRAINT CK_Location_latitude CHECK (latitude BETWEEN -90 AND 90), -- -90 to 90
  longitude DECIMAL(9, 6) NOT NULL CONSTRAINT CK_Location_longitude CHECK (longitude BETWEEN -180 AND 180), -- -180 to 180
  CONSTRAINT UQ_Location_parent_name UNIQUE (parentId, name) -- no duplicate names under one parent
);

CREATE TABLE CaseFile (
  caseId INT IDENTITY NOT NULL CONSTRAINT PK_CaseFile PRIMARY KEY, -- unique id
  caseNo VARCHAR(20) NOT NULL CONSTRAINT UQ_CaseFile_caseNo UNIQUE, -- case numbers unique
  title NVARCHAR(200) NOT NULL,
  categoryId VARCHAR(30) NOT NULL CONSTRAINT FK_CaseFile_Category REFERENCES LKUP_Category (id), -- must be a valid category
  locationId INT NOT NULL CONSTRAINT FK_CaseFile_Location REFERENCES Location (locationId), -- location must exist
  occurredAt DATETIME2(0) NULL,
  reportedAt DATETIME2(0) NOT NULL CONSTRAINT DF_CaseFile_reportedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  summary NVARCHAR(MAX) NULL
);

CREATE TABLE Statement (
  caseId INT NOT NULL CONSTRAINT FK_Statement_CaseFile REFERENCES CaseFile (caseId), -- case must exist
  witnessId INT NOT NULL CONSTRAINT FK_Statement_Witness REFERENCES Witness (witnessId), -- witness must exist
  takenAt DATETIME2(0) NOT NULL CONSTRAINT DF_Statement_takenAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  account NVARCHAR(MAX) NOT NULL,
  reliabilityId VARCHAR(10) NULL CONSTRAINT FK_Statement_Reliability REFERENCES LKUP_Reliability (id), -- must be a valid rating
  CONSTRAINT PK_Statement PRIMARY KEY (caseId, witnessId) -- one statement per witness per case
);

CREATE TABLE Assignment (
  caseId INT NOT NULL CONSTRAINT FK_Assignment_CaseFile REFERENCES CaseFile (caseId), -- case must exist
  staffId INT NOT NULL CONSTRAINT FK_Assignment_Staff REFERENCES Staff (staffId), -- staff must exist
  assignedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Assignment_assignedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  releasedAt DATETIME2(0) NULL,
  isLead BIT NOT NULL CONSTRAINT DF_Assignment_isLead DEFAULT 0, -- not lead by default
  CONSTRAINT PK_Assignment PRIMARY KEY (caseId, staffId, assignedAt), -- start time lets people be reassigned
  CONSTRAINT CK_Assignment_dates CHECK (releasedAt >= assignedAt) -- released on/after assigned
);

CREATE UNIQUE
INDEX UX_Assignment_openLead ON Assignment (caseId) -- one open lead per case
WHERE isLead = 1 AND releasedAt IS NULL;

CREATE UNIQUE
INDEX UX_Assignment_openPerStaff ON Assignment (caseId, staffId) -- no double assignment
WHERE releasedAt IS NULL;

CREATE TABLE Theory (
  theoryId INT IDENTITY NOT NULL CONSTRAINT PK_Theory PRIMARY KEY, -- unique id
  kindId VARCHAR(30) NOT NULL CONSTRAINT FK_Theory_Kind REFERENCES LKUP_TheoryKind (id), -- must be a valid kind
  name NVARCHAR(150) NOT NULL CONSTRAINT UQ_Theory_name UNIQUE, -- names unique
  description NVARCHAR(MAX) NULL
);

CREATE TABLE CaseTheory (
  caseId INT NOT NULL CONSTRAINT FK_CaseTheory_CaseFile REFERENCES CaseFile (caseId), -- case must exist
  theoryId INT NOT NULL CONSTRAINT FK_CaseTheory_Theory REFERENCES Theory (theoryId), -- theory must exist
  proposedBy INT NOT NULL CONSTRAINT FK_CaseTheory_proposedBy REFERENCES Staff (staffId), -- proposer must be staff
  proposedAt DATETIME2(0) NOT NULL CONSTRAINT DF_CaseTheory_proposedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  CONSTRAINT PK_CaseTheory PRIMARY KEY (caseId, theoryId) -- each theory once per case
);

CREATE TABLE Outcome (
  caseId INT NOT NULL CONSTRAINT FK_Outcome_CaseFile REFERENCES CaseFile (caseId), -- case must exist
  outcomeNo INT NOT NULL CONSTRAINT CK_Outcome_outcomeNo CHECK (outcomeNo > 0), -- starts at 1
  kindId VARCHAR(20) NOT NULL CONSTRAINT FK_Outcome_Kind REFERENCES LKUP_OutcomeKind (id), -- must be a valid outcome kind
  theoryId INT NULL,
  reason NVARCHAR(MAX) NOT NULL,
  proposedBy INT NOT NULL CONSTRAINT FK_Outcome_proposedBy REFERENCES Staff (staffId), -- proposer must be staff
  proposedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Outcome_proposedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  approvedBy INT NULL CONSTRAINT FK_Outcome_approvedBy REFERENCES Staff (staffId), -- approver must be staff
  approvedAt DATETIME2(0) NULL,
  CONSTRAINT PK_Outcome PRIMARY KEY (caseId, outcomeNo), -- outcome number within its case
  CONSTRAINT FK_Outcome_CaseTheory FOREIGN KEY (caseId, theoryId) REFERENCES CaseTheory (caseId, theoryId), -- theory must be one of the case's candidates
  CONSTRAINT CK_Outcome_theory CHECK ( -- only identified/hoax name a theory
    (
      kindId IN ('identified', 'hoax')
      AND theoryId IS NOT NULL
    )
    OR (
      kindId NOT IN ('identified', 'hoax')
      AND theoryId IS NULL
    )
  ),
  CONSTRAINT CK_Outcome_twoPeople CHECK (approvedBy <> proposedBy), -- approver isn't the proposer
  CONSTRAINT CK_Outcome_approval CHECK ( -- approver and date set together, after the proposal
    (
      approvedBy IS NULL
      AND approvedAt IS NULL
    )
    OR (
      approvedBy IS NOT NULL
      AND approvedAt IS NOT NULL
      AND approvedAt >= proposedAt
    )
  )
);

CREATE TABLE StatusChange (
  caseId INT NOT NULL CONSTRAINT FK_StatusChange_CaseFile REFERENCES CaseFile (caseId), -- case must exist
  seq INT NOT NULL,
  statusId VARCHAR(20) NOT NULL CONSTRAINT FK_StatusChange_Status REFERENCES LKUP_CaseStatus (id), -- must be a valid status
  changedAt DATETIME2(0) NOT NULL CONSTRAINT DF_StatusChange_changedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  recordedBy INT NOT NULL CONSTRAINT FK_StatusChange_recordedBy REFERENCES Staff (staffId), -- recorder must be staff
  outcomeNo INT NULL,
  note NVARCHAR(1000) NULL,
  CONSTRAINT PK_StatusChange PRIMARY KEY (caseId, seq), -- row number within its case
  CONSTRAINT FK_StatusChange_Outcome FOREIGN KEY (caseId, outcomeNo) REFERENCES Outcome (caseId, outcomeNo), -- must be one of the case's outcomes
  CONSTRAINT CK_StatusChange_closed CHECK ( -- closed rows name an outcome
    (
      statusId = 'closed'
      AND outcomeNo IS NOT NULL
    )
    OR (
      statusId <> 'closed'
      AND outcomeNo IS NULL
    )
  ),
  CONSTRAINT CK_StatusChange_first CHECK ( -- starts as submitted, only once
    (
      seq = 1
      AND statusId = 'submitted'
    )
    OR (
      seq > 1
      AND statusId <> 'submitted'
    )
  )
);

CREATE UNIQUE
INDEX UX_StatusChange_outcomeOnce ON StatusChange (caseId, outcomeNo) -- an outcome closes a case once
WHERE outcomeNo IS NOT NULL;

CREATE TABLE Evidence (
  caseId INT NOT NULL CONSTRAINT FK_Evidence_CaseFile REFERENCES CaseFile (caseId), -- case must exist
  itemNo INT NOT NULL CONSTRAINT CK_Evidence_itemNo CHECK (itemNo > 0), -- starts at 1
  kindId VARCHAR(20) NOT NULL CONSTRAINT FK_Evidence_Kind REFERENCES LKUP_EvidenceKind (id), -- must be a valid evidence kind
  description NVARCHAR(1000) NOT NULL,
  quantity INT NOT NULL CONSTRAINT DF_Evidence_quantity DEFAULT 1 CONSTRAINT CK_Evidence_quantity CHECK (quantity > 0), -- defaults to 1 and above 0
  fileUri NVARCHAR(400) NULL,
  capturedAt DATETIME2(0) NULL,
  CONSTRAINT PK_Evidence PRIMARY KEY (caseId, itemNo) -- item number within its case
);

CREATE TABLE EvidenceHandover (
  caseId INT NOT NULL,
  itemNo INT NOT NULL,
  seq INT NOT NULL,
  kindId VARCHAR(20) NOT NULL CONSTRAINT FK_EvidenceHandover_Kind REFERENCES LKUP_HandoverKind (id), -- must be a valid handover kind
  holderId INT NOT NULL CONSTRAINT FK_EvidenceHandover_holder REFERENCES Staff (staffId), -- holder must be staff
  handedAt DATETIME2(0) NOT NULL CONSTRAINT DF_EvidenceHandover_handedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  locationId INT NOT NULL CONSTRAINT FK_EvidenceHandover_Location REFERENCES Location (locationId), -- place must exist
  comment NVARCHAR(500) NULL,
  CONSTRAINT PK_EvidenceHandover PRIMARY KEY (caseId, itemNo, seq), -- row number within its item
  CONSTRAINT FK_EvidenceHandover_Evidence FOREIGN KEY (caseId, itemNo) REFERENCES Evidence (caseId, itemNo), -- item must exist
  CONSTRAINT CK_EvidenceHandover_first CHECK ( -- starts as collected, only once
    (
      seq = 1
      AND kindId = 'collected'
    )
    OR (
      seq > 1
      AND kindId <> 'collected'
    )
  )
);

CREATE TABLE Equipment (
  equipmentId INT IDENTITY NOT NULL CONSTRAINT PK_Equipment PRIMARY KEY, -- unique id
  assetTag VARCHAR(20) NOT NULL CONSTRAINT UQ_Equipment_assetTag UNIQUE, -- asset tags unique
  kindId VARCHAR(30) NOT NULL CONSTRAINT FK_Equipment_Kind REFERENCES LKUP_EquipmentKind (id), -- must be a valid equipment kind
  model NVARCHAR(100) NOT NULL,
  serialNo NVARCHAR(50) NULL,
  retiredOn DATE NULL
);

CREATE TABLE EquipmentLoan (
  equipmentId INT NOT NULL CONSTRAINT FK_EquipmentLoan_Equipment REFERENCES Equipment (equipmentId), -- equipment must exist
  outAt DATETIME2(0) NOT NULL CONSTRAINT DF_EquipmentLoan_outAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
  staffId INT NOT NULL CONSTRAINT FK_EquipmentLoan_Staff REFERENCES Staff (staffId), -- borrower must be staff
  caseId INT NULL CONSTRAINT FK_EquipmentLoan_CaseFile REFERENCES CaseFile (caseId), -- case must exist (optional)
  returnedAt DATETIME2(0) NULL,
  CONSTRAINT PK_EquipmentLoan PRIMARY KEY (equipmentId, outAt), -- same item can be lent many times
  CONSTRAINT CK_EquipmentLoan_dates CHECK (returnedAt >= outAt) -- returned on/after out
);

CREATE UNIQUE
INDEX UX_EquipmentLoan_openPerItem ON EquipmentLoan (equipmentId) -- one open loan per item
WHERE returnedAt IS NULL;

CREATE TABLE Review (
    reviewId INT IDENTITY NOT NULL CONSTRAINT PK_Review PRIMARY KEY, -- unique id
    caseId INT NOT NULL,
    itemNo INT NOT NULL,
    staffId INT NOT NULL,
    methodId VARCHAR(30) NOT NULL,
    reviewedAt DATETIME2(0) NOT NULL CONSTRAINT DF_Review_reviewedAt DEFAULT SYSUTCDATETIME(), -- defaults to now (utc)
    reliability TINYINT NULL CONSTRAINT CK_Review_reliability CHECK (reliability BETWEEN 0 AND 100), -- 0 to 100
    finding NVARCHAR(MAX) NOT NULL,
    CONSTRAINT FK_Review_Evidence FOREIGN KEY (caseId, itemNo) REFERENCES Evidence (caseId, itemNo), -- item must exist
    CONSTRAINT FK_Review_Qualification FOREIGN KEY (staffId, methodId) REFERENCES StaffQualification (staffId, methodId) -- reviewer must be qualified in the method
  );

CREATE TABLE Project (
  projectId INT IDENTITY NOT NULL CONSTRAINT PK_Project PRIMARY KEY, -- unique id
  kindId VARCHAR(30) NOT NULL CONSTRAINT FK_Project_Kind REFERENCES LKUP_ProjectKind (id), -- must be a valid project kind
  title NVARCHAR(200) NOT NULL,
  leadId INT NOT NULL CONSTRAINT FK_Project_lead REFERENCES Staff (staffId), -- lead must be staff
  startedOn DATE NOT NULL,
  endedOn DATE NULL,
  CONSTRAINT CK_Project_dates CHECK (endedOn >= startedOn) -- ends on/after start
);

CREATE TABLE Publication (
  publicationId INT IDENTITY NOT NULL CONSTRAINT PK_Publication PRIMARY KEY, -- unique id
  projectId INT NULL CONSTRAINT FK_Publication_Project REFERENCES Project (projectId), -- project must exist (optional)
  title NVARCHAR(300) NOT NULL,
  publishedOn DATE NULL,
  uri NVARCHAR(400) NULL
);

GO
